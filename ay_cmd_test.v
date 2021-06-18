module ay_cmd_test;

// Одновременная эмуляция 4x вариантов подключения АУшки

// Имеем одну БК-0011M управляющую 4мя разными схемами для АУ

// входные и выходные контакты УП
wire [15:0] ipins, opins;

// сигналы на входах УП (для тестирования чтения)
assign ipins = ~16'habcd;

// доп. сигналы
wire isel2, strobe, dout, iwrbt, simulation_end;

// псевдо-сигналы (команды) для всех АУшек
wire ay_inact[0:3], ay_laddr[0:3], ay_wrpsg[0:3], ay_rdpsg[0:3];

// БК0011М + AY на УП

BK_0011M BK11 (
	.XT5_in_pin(ipins),
	.XT5_out_pin(opins),
	.nSEL2(isel2),
	.DOUT(dout),
	.nWRTBT(iwrbt),
	.STROBE(strobe),
	.END(simulation_end)
);

cmd_ay_orig AY0 (
	.strobe(strobe),
	.iwrbt(iwrbt),
	.dout(dout),
	.ay_inact(ay_inact[0]),
	.ay_laddr(ay_laddr[0]),
	.ay_wrpsg(ay_wrpsg[0]),
	.ay_rdpsg(ay_rdpsg[0])
);

cmd_ay_stas1 AY1 (
	.strobe(strobe),
	.iwrbt(iwrbt),
	.dout(dout),
	.ay_inact(ay_inact[1]),
	.ay_laddr(ay_laddr[1]),
	.ay_wrpsg(ay_wrpsg[1]),
	.ay_rdpsg(ay_rdpsg[1])
);

cmd_ay_stas2 AY2 (
	.strobe(strobe),
	.iwrbt(iwrbt),
	.dout(dout),
	.ay_inact(ay_inact[2]),
	.ay_laddr(ay_laddr[2]),
	.ay_wrpsg(ay_wrpsg[2]),
	.ay_rdpsg(ay_rdpsg[2])
);

cmd_ay_stas3 AY3 (
	.strobe(strobe),
	.iwrbt(iwrbt),
	.ay_inact(ay_inact[3]),
	.ay_laddr(ay_laddr[3]),
	.ay_wrpsg(ay_wrpsg[3]),
	.ay_rdpsg(ay_rdpsg[3])
);

wire wrbt = ~iwrbt;
wire sel = ~isel2;

`ifdef GTKWAVE_DUMP
initial
    begin
	$dumpfile("cpu_emulator.vcd");
	$dumpvars(0,ay_cmd_test);
	wait(simulation_end);
	$finish;
    end

`else
initial
    begin
    	$timeformat(3, 2, "us", 7);
    	#500
    	$display("                                      ,-----------------.-----------------.-----------------.-----------------.");
    	$display("                                      |       Novo      |      Stas1      !      Stas2      |      Stas3      |");
    	$display(",--------.----------------------------+-----------------+-----------------+-----------------+-----------------+");
    	$display("|  TIME  |   D7-D0    SEL STB WBT DOU | INA ADR WRR RDR | INA ADR WRR RDR | INA ADR WRR RDR | INA ADR WRR RDR |");
    	$display("+--------+----------------------------+-----------------+-----------------+-----------------+-----------------+");
	$monitor("|%t |  %b   %b   %b   %b   %b  |  %b   %b   %b   %b  |  %b   %b   %b   %b  |  %b   %b   %b   %b  |  %b   %b   %b   %b  |",
		$time, opins[7:0], sel, strobe, wrbt, dout,
		ay_inact[0], ay_laddr[0], ay_wrpsg[0], ay_rdpsg[0],
		ay_inact[1], ay_laddr[1], ay_wrpsg[1], ay_rdpsg[1],
		ay_inact[2], ay_laddr[2], ay_wrpsg[2], ay_rdpsg[2],
		ay_inact[3], ay_laddr[3], ay_wrpsg[3], ay_rdpsg[3]);
	wait(simulation_end);
	$display("'--------'----------------------------'-----------------'-----------------'-----------------'-----------------'");
	$finish;
    end
`endif

endmodule
