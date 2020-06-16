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

reg [7:0] state_reg = 0;
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

// Автомат, реализующий машинные циклы чтения и записи

task bus_cycle(
		inout [7:0] state,
		input byte,
		input rd,
		input wr,
		inout run);
    begin
    	casez ( state )
	0, 8'b01000000:	// таймаут шины, рестарт
	    begin
		ctrl_en = 0;
		data_en = 0;
		addr_en = 0;
		nSYNC = 1'bz;
		if ( CLKp ) // по фронту CLK пропускаем полутакт для синхронизации (строго говоря, для шины это не требуется)
		    state = 1;
	    end
	2:		// захват шины и выдача адреса
	    begin
		nBSY  = 0;
		nWTBT = ~(wr & ~rd); // активен только в цикле записи
		nDIN  = 1;
		nDOUT = 1;
		nAD[15:0] = ~addr_reg;
		ctrl_en = 1;
		addr_en = 1;
	    end
	4:		// начало обмена
	    nSYNC = 0;
	5:		// окончание выдачи адреса
	    begin
		nWTBT = 1;
		nDIN = ~rd;
		if ( wr )
		    nAD[15:0] = 16'bx;  // мусор из внутреннего регистра данных, только при записи
		addr_en = 0;
		data_en = wr; // при чтении на AD третье состояние
		if ( rd )
		    state = 8; // при чтении переходим к ожиданию RPLY
	    end
	7:		// выдача дaнных при записи
		nAD[15:0] = ~data_reg;
	8:		// запись байта/слова
	    begin
		nWTBT = ~byte;
		nDOUT = 0;
	    end
	8'b00zzzzz1:	// ожидание ответа (1й такт)
	    if ( ~nRPLYp )
		state[6] = 1;
	8'b01zzzzz1:	// ожидание ответа (2й такт)
	    if ( ~nRPLYp )
		begin	// ответ получен
		    state = 8'b10000000;
		    nDIN  = 1;
		    nDOUT = 1;
		    if ( rd )	// чтение данных с шины
		    begin
			if ( byte )
			    begin
				data_reg[7:0]  = addr_reg[0] ? ~nADp[15:8] : ~nADp[7:0];
				data_reg[15:8] = 8'b0;
			    end
			else
			    data_reg = ~nADp[15:0];
			state = 8'b10000001; // переход к ожиданию окончания RPLY
		    end
		end
	    else
		state[6] = 0;
	8'b10000001:	// освобождение шины при записи
	    begin
		data_en = 0;
		nWTBT   = 1;
	    end
	8'b100zzzz0:	// ожидание окончания ответа (1й полутакт)
	    if ( nRPLYp )
		state[5] = 1;
	8'b101zzzz1:	// ожидание окончания ответа (2й полутакт)
	    if ( nRPLYp )
		begin
		    state[6] = 1;
		    state[5:0] = 0;
		    ctrl_en = 0;
		end
	    else
		state[5] = 0;
	8'b11000010:	// снятие nBSY и nSYNC
	    begin
		nBSY  = 1'bz;
		nSYNC = 1;
	    end
	8'b11000100:	// конец транзакции
	    begin
		nSYNC = 1'bz;
		run = 0;
	    end
	endcase
	if ( ~state[7] )
	    ++state[5:0];
	else
	    ++state[4:0];
    end
endtask

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
	simulation_end = 1;
end

// цикл записи байта
always @(CLKp)
	if (run_wb)
		bus_cycle(state_reg, 1, 0, 1, run_wb);

// цикл записи слова
always @(CLKp)
	if (run_ww)
		bus_cycle(state_reg, 0, 0, 1, run_ww);

// цикл чтения байта
always @(CLKp)
	if (run_rb)
		bus_cycle(state_reg, 1, 1, 0, run_rb);

// цикл чтения слова
always @(CLKp)
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
