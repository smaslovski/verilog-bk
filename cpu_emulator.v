module cpu_emulator(CLKp, nBSYp, nADp, nSYNCp, nWTBTp, nDINp, nDOUTp, nRPLYp, nSEL1p, nSEL2p, simulation_end);

// �ࠪ��� �६����� ���ࢠ� (��ਮ� CLK � �.�.), ��
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

// ��⮬�� ��設���� 横�� �����

task write_cycle(
		inout [7:0] state,
		input byte,
		inout run);
    begin
    	casez ( state )
	0:		// ⠩���� 設�, �����
	    begin
		ctrl_en = 0;
		data_en = 0;
		addr_en = 0;
		nSYNC = 1'bz;
	    end
	2:		// ��墠� 設� � �뤠� ����
	    begin
		nBSY  = 0;
		nWTBT = 0;
		nDIN  = 1;
		nDOUT = 1;
		nAD[15:0] = ~addr_reg;
		ctrl_en = 1;
		addr_en = 1;
	    end
	4:		// ��砫� ������
	    nSYNC = 0;
	5:		// ����砭�� �뤠� ����
	    begin
		nWTBT = 1;
		addr_en = 0;
	    end
	7:		// �뤠� �a����
	    begin
		data_en = 1;
		nAD[15:0] = ~data_reg;
	    end
	8:		// ������ ����/᫮��
	    begin
		nWTBT = byte;
		nDOUT = 0;
	    end
	8'b00zzzzz1:	// �������� �⢥� (1� ⠪�)
		if ( ~nRPLYp )
			state[6] = 1;
	8'b01zzzzz1:	// �������� �⢥� (2� ⠪�)
		if ( ~nRPLYp )
		    begin
			state = 8'b10000000;
			nDOUT = 1;
		    end
		else
			state[6] = 0;
	8'b10000001:	// �᢮�������� 設�
		begin
		    data_en = 0;
		    nWTBT   = 1;
		end
	8'b100zzzz0:	// �������� ����砭�� �⢥� (1� ����⠪�)
		if ( nRPLYp )
			state[5] = 1;
	8'b101zzzz1:	// �������� ����砭�� �⢥� (2� ����⠪�)
		if ( nRPLYp )
		    begin
			state[6] = 1;
			state[5:0] = 0;
			ctrl_en = 0;
		    end
		else
		    state[5] = 0;
	8'b11000010:	// ��⨥ nBSY � nSYNC
		begin
		    nBSY  = 1'bz;
		    nSYNC = 1;
		end
	8'b11000100:	// ����� �࠭���樨
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

// ����७��� �ନ஢�⥫� ᨣ����� nSEL1 and nSEL2
always @(negedge nSYNCp)
    begin
	nSEL1 <= ~(nADp == ~16'o177716);
	nSEL2 <= ~(nADp == ~16'o177714);
    end

// �� ���㬥��樨 �� �祭� ����⭮, �� �ந�室�� ��
// ��⨨ nSYNC, �� ��宦�, �� ������ ���� ⠪
always @(posedge nSYNCp)
    begin
    	nSEL1 <= 1;
    	nSEL2 <= 1;
    end

// ����७��� �ନ஢�⥫� ᨣ���� nRPLY
assign nRPLYp = nSEL1p | (nDIN & nDOUT);
assign nRPLYp = nSEL2p | (nDIN & nDOUT);

reg run_ww, run_wb;

// �ᨭ�஭��� �ணࠬ�� ��� ����� ���
initial begin
	run_ww = 0;
	run_wb = 0;
	#(50*dT)
	state_reg = 0;
	data_reg = ~16'h0055;
	run_wb = 1;
	#(100*dT)
	state_reg = 0;
	data_reg = ~16'h000f;
	run_ww = 1;
	#(100*dT)
	simulation_end = 1;
end

// 横� ����� ����
always @(CLKp)
	if (run_wb)
		write_cycle(state_reg, 0, run_wb);

// 横� ����� ᫮��
always @(CLKp)
	if (run_ww)
		write_cycle(state_reg, 1, run_ww);
integer mcd;

initial begin
	mcd = $fopen("cpu_bus.log");
	$fdisplay(mcd, "time\tstate\tCLKp\tnBSYp\tnADp\t\t\tnSYNCp\tnWTBTp\tnDINp\tnDOUTp\tnRPLYp\tnSEL1p\tnSEL2p");
end

always @(*)
	$fdisplay(mcd, "%5t\t%4x\t%b\t%b\t%b\t%b\t%b\t%b\t%b\t%b\t%b\t%b", $time, state_reg, CLKp, nBSYp, nADp, nSYNCp, nWTBTp, nDINp, nDOUTp, nRPLYp, nSEL1p, nSEL2p);

endmodule
