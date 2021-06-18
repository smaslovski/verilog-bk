// Альтернативный вариант с логикой для БК0010/0011
// Для БК0011М сигнал strobe снимается с D30, выв. 1
// Для БК0010 инвертированный сигнал strobe можно снять с D15, выв. 23
// Ниже код для БК0011М

module bk_ay_stas3(strobe, iwrbt, bc1, bc2, bdir);

input strobe, iwrbt;
output bc1, bc2, bdir;

parameter ln1_delay = 15; // задержка 555ЛН1
parameter le1_delay = 15; // задержка 555ЛЕ1

assign bdir = 1;
assign #(ln1_delay) bc1 = ~strobe;
assign #(le1_delay) bc2 = ~(iwrbt | bc1);

endmodule

module cmd_ay_stas3(strobe, iwrbt, ay_inact, ay_laddr, ay_wrpsg, ay_rdpsg);

input strobe, iwrbt;
output ay_inact, ay_laddr, ay_wrpsg, ay_rdpsg;

wire bc1, bc2, bdir;

bk_ay_stas3 bk_AY (
	.strobe(strobe),
	.iwrbt(iwrbt),
	.bc1(bc1),
	.bc2(bc2),
	.bdir(bdir)
);

assign ay_inact = (~bdir & ~bc1) | (bdir & ~bc2 & bc1);
assign ay_laddr = (~bdir & ~bc2 & bc1) | (bdir & ((~bc2 & ~bc1) | (bc2 & bc1)));
assign ay_wrpsg = bdir & bc2 & ~bc1;
assign ay_rdpsg = ~bdir & bc2 & bc1;

endmodule
