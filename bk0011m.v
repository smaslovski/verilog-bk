module BK_0011M(XT5_in_pin, XT5_out_pin, nSEL2, DOUT, nWRTBT, STROBE, END);

// ���⠪�� ࠧ�� XT5 (�室/��室 ��)
input [15:0] XT5_in_pin;
output [15:0] XT5_out_pin;
output nSEL2, STROBE, nWRTBT, DOUT, END;

parameter cycle = 250; // ��ਮ� ⠪⮢�� �����, ��
reg clk; // ⠪⮢� ᨣ���

integer cnt; // ���稪 ⠪⮢

// ॣ����� ��
reg [15:0] UP_out_reg, UP_in_reg;

// ���� ����/������
tri1 [15:0] nAD;

// ���� �ࠢ�����
tri1 nSYNC, nWTBT, nDIN, nDOUT;
wire nBSY, nRPLY, nSEL1, nSEL2;

assign XT5_out_pin = UP_out_reg;
assign nWRTBT = nWTBT;

// ⠪⮢� �������
initial begin
    cnt = 0;
    clk <= 1;
    forever begin
	#(cycle/4)
	clk <= 0;
	#(cycle/2);
	clk <= 1;
	#(cycle/4);
	++cnt;
    end
end

// ���
// CLKp, nBSYp, nADp, nSYNCp, nWTBTp, nDINp, nDOUTp, nRPLYp, nSEL1p, nSEL2p
cpu_emulator #(.dT(cycle)) CPU1 (
	.CLKp(clk),
	.nBSYp(nBSY),
	.nADp(nAD),
	.nSYNCp(nSYNC),
	.nWTBTp(nWTBT),
	.nDINp(nDIN),
	.nDOUTp(nDOUT),
	.nRPLYp(nRPLY),
	.nSEL1p(nSEL1),
	.nSEL2p(nSEL2),
	.simulation_end(END)
);

// �������樮���� ������ �� ���� ��0011�

assign DOUT = ~nDOUT; // D1, ��. 4

// �ନ஢�⥫� ��஡� ����� � ��室��� ॣ���� ��
parameter RC_delay = 200; // �६� ���鸞 ��������� RC 楯�窨, ��
wire #(0, RC_delay) ndout_delayed = nDOUT;
assign STROBE = ~(nSEL2 | ndout_delayed); // D30, ��. 1

// ᨣ��� �롮ન �室���� ॣ���� ��
wire nE0 = nDIN | nSEL2;

// ����� �� �室���� ॣ���� ��
assign nAD = ~nE0 ? UP_in_reg : 16'bz;

// ������ � ��室��� ॣ���� ��
always @(posedge STROBE)
	UP_out_reg <= nAD;

// 䨪�஢���� ���ﭨ� �室��� ����� �� �� �室��� ॣ���� ��
// (� �奬� ��-00011� �� �ந�室�� �� �� ��⨢��� �⥭�� �� 設�)
always @(negedge nDIN)
	UP_in_reg <= XT5_in_pin;

endmodule
