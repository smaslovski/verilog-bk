module cpu_emulator(CLKp, nBSYp, nADp, nSYNCp, nWTBTp, nDINp, nDOUTp, nRPLYp, nSEL1p, nSEL2p, simulation_end);

// характерный временной интервал (период CLK и т.п.), нс
parameter dT = 250;

input CLKp;

inout [15:0] nADp;
inout nSYNCp, nDINp, nDOUTp;
inout wand nRPLYp;

output nWTBTp, nSEL1p, nSEL2p;
output wand nBSYp;

output simulation_end;

reg [15:0] nAD;
reg nBSY = 1'bz, nSYNC = 1'bz, nWTBT = 1'bz, nDIN = 1'bz, nDOUT = 1'bz, nSEL1 = 1, nSEL2 = 1;

reg [3:0] state_reg = 0;
reg [15:0] addr_reg = 16'o177714, data_reg;
reg addr_en = 0, data_en = 0, ctrl_en = 0, simulation_end = 0;

assign nADp   = addr_en ? nAD : 16'bz;
assign nADp   = data_en ? nAD : 16'bz;
assign nWTBTp = ctrl_en ? nWTBT : 1'bz;
assign nDINp  = ctrl_en ? nDIN  : 1'bz;
assign nDOUTp = ctrl_en ? nDOUT : 1'bz;
assign nBSYp  = nBSY;
assign nSYNCp = nSYNC;
assign nSEL1p = nSEL1;
assign nSEL2p = nSEL2;

// Двухфазный автомат, реализующий машинные циклы чтения, записи и чтения-модификации-записи

// активируется по срезу CLK
task bus_cycle(	inout [3:0] state,
		input byte,
		input rd,
		input wr,
		inout run);
    begin
	bus_ctrl_phase_0(state, byte, rd, wr);
	bus_fsm_phase_0(state, rd, wr);
	@(posedge CLKp)
	bus_ctrl_phase_1(state, byte, rd, wr);
	bus_fsm_phase_1(state, rd, wr);
	case ( state )
	    11:
		run = 0;
	endcase
    end
endtask

// активируется по срезу CLK
task bus_ctrl_phase_0(
		inout [3:0] state,
		input byte,
		input rd,
		input wr);
    case ( state )
	0:	// таймаут шины, рестарт
	    begin
		ctrl_en <= 0;
		data_en <= 0;
		addr_en <= 0;
		rply_timer_en  <= 0;
		rply_timer_cnt <= 0;
		nSYNC <= 1'bz;
	    end
	1:	// захват шины и выдача адреса
	    begin
		nBSY  <= 0;
		nWTBT <= ~(wr & ~rd); // активен только в цикле записи
		nDIN  <= 1;
		nDOUT <= 1;
		nAD[15:0] <= ~addr_reg;
		ctrl_en <= 1;
		addr_en <= 1;
	    end
	2:	// начало обмена
	    nSYNC <= 0;
	4:	// запрос на запись байта/слова, начало ожидания RPLY
	    if (wr && ~rd)
		begin
		    nWTBT <= ~byte;
		    nDOUT <= 0;
		end
	6:	// освобождение шины AD и деактивация nWTBT
	    begin
		data_en <= 0;
		nWTBT   <= 1;
	    end
	7:	// окончание RPLY
	    if ( nRPLYp )
		ctrl_en <= 0;
	9:	// снятие nBSY и nSYNC
	    begin
		nBSY  <= 1'bz;
		nSYNC <= 1;
	    end
	10:	// конец транзакции
	    nSYNC <= 1'bz;
    endcase
endtask

// активируется по фронту CLK
task bus_ctrl_phase_1(
		inout [3:0] state,
		input byte,
		input rd,
		input wr);
    case ( state )
	2:	// окончание выдачи адреса
	    begin
		nWTBT <= 1;
		nDIN  <= ~rd;
		if ( wr )
		    nAD[15:0] <= 16'bx;  // мусор из внутреннего регистра данных, только при записи
		addr_en <= 0;
		data_en <= wr & ~rd; // при чтении на AD третье состояние
	    end
	3:	// выдача дaнных при записи (при чтении пропускается)
	    nAD[15:0] <= ~data_reg;
	5:	// завершение записи / чтения
	    if ( ~nRPLYp )
		begin
		    nDIN  <= 1;
		    nDOUT <= 1;
		    if ( rd )	// фиксация данных с шины AD
			begin
			    if ( byte )
				begin
				    data_reg[7:0]  <= addr_reg[0] ? ~nADp[15:8] : ~nADp[7:0];
				    data_reg[15:8] <= 8'b0;
				end
			    else
				data_reg <= ~nADp[15:0];
			end
		end
    endcase
endtask

// активируется по срезу CLK
task bus_fsm_phase_0(
		inout [3:0] state,
		input rd,
		input wr);
    case ( state )
	4:	// старт таймера RPLY
		rply_timer_en <= 1;
	7:	// ожидание окончания RPLY (2й полутакт)
	    if ( ~nRPLYp)
		state = state - 1;
    endcase
endtask

// активируется по фронту CLK
task bus_fsm_phase_1(
		inout [3:0] state,
		input rd,
		input wr);
    case ( state )
	2:	// при чтении переходим к ожиданию RPLY
	    if ( rd )
		state = 4;
	    else
		state = state + 1;
	4:	// ожидание RPLY (1й такт)
	    if ( ~nRPLYp )
		state = state + 1;
	    else
		if ( rply_timeout )
		    state = 0;
	5:	// ожидание RPLY (2й такт)
	    if ( ~nRPLYp )
		begin
		    // ответ получен, запрещаем и очищаем таймер
		    rply_timer_en  <= 0;
		    rply_timer_cnt <= 0;
		    state = state + 1;
		end
	    else
		state = state - 1;
	6:	// ожидание окончания RPLY (1й полутакт)
	    if ( nRPLYp )
		state = state + 1;
	default:
	    state = state + 1;
    endcase
endtask

// Делитель частоты СLK на 8 (используется в таймере RPLY)
reg [2:0] div_cnt = 0;
wire CLK_div_8 = div_cnt[2];
always @(posedge CLKp)
    div_cnt <= div_cnt + 1;

// RPLY таймер
reg rply_timer_en = 0;
reg [3:0] rply_timer_cnt = 0;
wire rply_timeout = rply_timer_cnt[3];
always @(negedge CLK_div_8)
    if ( rply_timer_en )
	rply_timer_cnt <= rply_timer_cnt + 1;

// внутренние формирователи сигналов nSEL1 and nSEL2
always @(negedge nSYNCp)
    begin
	nSEL1 <= ~(nADp == ~16'o177716);
	nSEL2 <= ~(nADp == ~16'o177714);
    end

// Из документации не очень понятно, что происходит при
// снятии nSYNC, но похоже, что должно быть так
always @(posedge nSYNCp)
    begin
    	nSEL1 <= 1;
    	nSEL2 <= 1;
    end

// внутренний формирователь сигнала nRPLY
assign nRPLYp = nSEL1p | (nDIN & nDOUT);
assign nRPLYp = nSEL2p | (nDIN & nDOUT);

reg run_ww, run_wb, run_rb, run_rw;

// асинхронная программа для эмулятора ЦПУ
initial begin
	run_ww = 0;
	run_wb = 0;
	run_rb = 0;
	run_rw = 0;
	#(5*dT)
	state_reg = 0;
	data_reg = ~16'h0055;
	run_wb = 1;
	#(30*dT)
	state_reg = 0;
	data_reg = ~16'h000f;
	run_ww = 1;
	#(30*dT)
	state_reg = 0;
	run_rb = 1;
	#(30*dT)
	state_reg = 0;
	run_rw = 1;
	#(30*dT)
	state_reg = 0;
	addr_reg = ~16'o123456;
	run_wb = 1;
	#(200*dT)
	simulation_end = 1;
end

// цикл записи байта
always @(negedge CLKp)
    if (run_wb)
	bus_cycle(state_reg, 1, 0, 1, run_wb);

// цикл записи слова
always @(negedge CLKp)
    if (run_ww)
	bus_cycle(state_reg, 0, 0, 1, run_ww);

// цикл чтения байта
always @(negedge CLKp)
    if (run_rb)
	bus_cycle(state_reg, 1, 1, 0, run_rb);

// цикл чтения слова
always @(negedge CLKp)
    if (run_rw)
	bus_cycle(state_reg, 0, 1, 0, run_rw);

integer mcd;

`ifdef GTKWAVE_DUMP
initial begin
	$dumpfile("cpu_emulator.vcd");
	$dumpvars(0,cpu_emulator);
end
`else
initial begin
	mcd = $fopen("cpu_bus.log");
	$fdisplay(mcd, "time\tCLKp\tnBSYp\tnADp\t\t\tnSYNCp\tnWTBTp\tnDINp\tnDOUTp\tnRPLYp\tnSEL1p\tnSEL2p\tstate\taddr\tdata");
end

always @(*)
	$fstrobe(mcd, "%6t\t%b\t%b\t%b\t%b\t%b\t%b\t%b\t%b\t%b\t%b\t%4x\t%4x\t%4x", $time, CLKp, nBSYp, nADp, nSYNCp, nWTBTp, nDINp, nDOUTp, nRPLYp, nSEL1p, nSEL2p, state_reg, addr_reg, data_reg);
`endif
endmodule
