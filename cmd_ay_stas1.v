// Вариант с диодами Шоттки

module bk_ay_stas1(strobe, iwrbt, bc1, bc2, bdir);

input strobe, iwrbt;
output bc1, bc2, bdir;

parameter ln1_delay = 20; // задержка 555ЛН1
parameter ds_on  = 10;  // время отпирания диода
parameter ds_off = 10;  // время запирания диода

wire bdir = 1;
wire bc2 = strobe;

// первый инвертор
wire #(ln1_delay) t1 = ~iwrbt;

// элемент "И" на диодах (FIX ME)
wire d1, d2;
assign #(ds_off,ds_on) d1 = t1;
assign #(ds_off,ds_on) d2 = strobe;
tri1 t2 = d1 & d2;

// второй инвертор
wire #(ln1_delay) bc1 = ~t2;

endmodule

module cmd_ay_stas1(strobe, iwrbt, dout, ay_inact, ay_laddr, ay_wrpsg, ay_rdpsg);

input strobe, iwrbt, dout;
output ay_inact, ay_laddr, ay_wrpsg, ay_rdpsg;

wire bc1, bc2, bdir;

bk_ay_stas1 bk_AY (
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
