// Вариант по схеме новодела с АУ

module bk_ay_orig(strobe, iwrbt, bc1, bc2, bdir);

input strobe, iwrbt;
output bc1, bc2, bdir;

parameter li1_delay = 20; // задержка 555ЛИ1, нс

assign bc2 = 1;
assign bdir = strobe;
assign #(li1_delay) bc1 = (iwrbt & strobe);

endmodule

module cmd_ay_orig(strobe, iwrbt, dout, ay_inact, ay_laddr, ay_wrpsg, ay_rdpsg);

input strobe, iwrbt, dout;
output ay_inact, ay_laddr, ay_wrpsg, ay_rdpsg;

wire bc1, bc2, bdir;

bk_ay_orig bk_AY (
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
