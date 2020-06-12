module BK_0011M(XT5_in_pin, XT5_out_pin, nSEL2, DOUT, nWRTBT, STROBE, END);

// контакты разъёма XT5 (вход/выход УП)
input [15:0] XT5_in_pin;
output [15:0] XT5_out_pin;
output nSEL2, STROBE, nWRTBT, DOUT, END;

parameter cycle = 250; // период тактовой частоты, нс
reg clk; // тактовый сигнал

integer cnt; // счетчик тактов

// регистры УП
reg [15:0] UP_out_reg, UP_in_reg;

// Шина адреса/данных
tri1 [15:0] nAD;

// Шина управления
tri1 nSYNC, nWTBT, nDIN, nDOUT;
wire nBSY, nRPLY, nSEL1, nSEL2;

assign XT5_out_pin = UP_out_reg;
assign nWRTBT = nWTBT;

// тактовый генератор
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

// ЦПУ
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

// комбинационная логика на плате БК0011М

assign DOUT = ~nDOUT; // D1, выв. 4

// формирователь строба записи в выходной регистр УП
parameter RC_delay = 200; // время заряда конденсатора RC цепочки, нс
wire #(0, RC_delay) ndout_delayed = nDOUT;
assign STROBE = ~(nSEL2 | ndout_delayed); // D30, выв. 1

// сигнал выборки входного регистра УП
wire nE0 = nDIN | nSEL2;

// данные из входного регистра УП
assign nAD = ~nE0 ? UP_in_reg : 16'bz;

// запись в выходной регистр УП
always @(posedge STROBE)
	UP_out_reg <= nAD;

// фиксирование состояния входных линий УП во входном регистре УП
// (в схеме БК-00011М это происходит при любом активном чтении на шине)
always @(negedge nDIN)
	UP_in_reg <= XT5_in_pin;

endmodule
