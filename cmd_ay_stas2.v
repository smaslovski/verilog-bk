// Вариант с логикой для БК0010/0011

module bk_ay_stas2(strobe, iwrbt, dout, bc1, bc2, bdir);

input strobe, iwrbt, dout;
output bc1, bc2, bdir;

parameter ln1_delay = 20; // задержка 555ЛН1
parameter li7_delay = 20; // задержка ЛИ7

assign bdir = 1;
wire #(ln1_delay) t1 = ~iwrbt;
wire #(li7_delay) t2 = strobe & dout;
assign #(ln1_delay) bc1 = ~t2;
assign #(li7_delay) bc2 = t1 & t2;

endmodule

module cmd_ay_stas2(strobe, iwrbt, dout, ay_inact, ay_laddr, ay_wrpsg, ay_rdpsg);

input strobe, iwrbt, dout;
output ay_inact, ay_laddr, ay_wrpsg, ay_rdpsg;

wire bc1, bc2, bdir;

bk_ay_stas2 bk_AY (
	.strobe(strobe),
	.iwrbt(iwrbt),
	.dout(dout),
	.bc1(bc1),
	.bc2(bc2),
	.bdir(bdir)
);

assign ay_inact = (~bdir & ~bc1) | (bdir & ~bc2 & bc1);
assign ay_laddr = (~bdir & ~bc2 & bc1) | (bdir & ((~bc2 & ~bc1) | (bc2 & bc1)));
assign ay_wrpsg = bdir & bc2 & ~bc1;
assign ay_rdpsg = ~bdir & bc2 & bc1;

endmodule
