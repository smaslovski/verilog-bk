//
// Copyright (c) 2013 by 1801BM1@gmail.com
// Modified by Stanislav Maslovski <stanislav.maslovski@gmail.com>
//______________________________________________________________________________
//


//______________________________________________________________________________
//

module tb_037 ();

// time unit: one period of BK's 12 MHz system clock generator
parameter  dT = 1;

// Simulation stops after this time (in 12 MHz clock periods)
parameter time_limit = 300000*dT;

// 1801VP1-037 pins
tri1  [15:0]   nAD;
reg   [15:0]   AD_in;
reg   [15:0]   AD_out;
reg            AD_oe;

reg            R;
reg            C;
reg            CLK;
reg            nDIN;
reg            nDOUT;
reg            nSYNC;
reg            nWTBT;
tri1           nRPLY;

wire  [6:0]    A;
wire  [1:0]    nCAS;
wire           nRAS;
wire           nWE;
wire           nE;
wire           nBS;
wire           WTI;
wire           WTD;
wire           nVSYNC;

reg            d28, d3;
wire           c28, nIRQ2;
//______________________________________________________________________________
//
assign nAD[15:0] = AD_oe ? AD_in[15:0] : 16'hZZZZ;

//_____________________________________________________________________________
//
// Clock generator (6MHz typical)
//
initial
begin
         CLK = 1'b0;
         forever #(dT) CLK = ~CLK;
end

//
// Simulation time limit
//
initial
begin
    #(time_limit) $finish;
end

//_____________________________________________________________________________
//
// IRQ2 selector (from HSYNC & VSYNC)
//
assign nIRQ2 = ~d3;
assign c28 = ~(d28 | nVSYNC);
initial d28 = 1'b0;

always @(negedge c28 or posedge (WTI & CLK))
begin
   if (WTI & CLK)
      d28 <= 1'b0;
   else
      d28 <= ~d28;
end

always @(posedge nVSYNC) d3 <= d28;


//_____________________________________________________________________________
//
// Simulate RAM output data
//

parameter RED = 16'b1111111111111111;
parameter GRE = 16'b0101010101010101;
parameter BLU = 16'b1010101010101010;

reg [15:0] color_word = BLU;

// switch colors every VSYNC
always @(negedge nVSYNC)
    case (color_word)
	RED:
	    color_word <= GRE;
	GRE:
	    color_word <= BLU;
	BLU:
	    color_word <= RED;
    endcase

// RAM output
wire [15:0] RAM_out;
assign RAM_out[7:0]  = ~nCAS[0] & nWE ? ~color_word[7:0]  : 8'bz;
assign RAM_out[15:8] = ~nCAS[1] & nWE ? ~color_word[15:8] : 8'bz;

//_____________________________________________________________________________
//
// Shift registers (D24 and D25)
//

wire nCLK = ~CLK;

// Connect even bits of the RAM output word to the inputs of D24, and odd bits to D25

genvar i;
wire [7:0] d24_D, d25_D;	// register inputs

generate
    for (i = 0; i < 8; i = i + 1)
    begin
	assign d24_D[i] = RAM_out[2*i];		// even bits
	assign d25_D[i] = RAM_out[2*i+1];	// odd bits
    end
endgenerate

reg [7:0] d24_Q, d25_Q;

always @(posedge nCLK)
begin
    if (WTI)	// parallel load
	begin
	    d24_Q[7:0] <= d24_D[7:0];
	    d25_Q[7:0] <= d25_D[7:0];
	end
    else	// shift
	begin
	    d24_Q[6:0] <= d24_Q[7:1];
	    d25_Q[6:0] <= d25_Q[7:1];
	    d24_Q[7] <= 1'b1;
	    d25_Q[7] <= 1'b1;
	end
end

// RGB signals
wire vR = ~( d24_Q[0] |  d25_Q[0]);
wire vG = ~(~d24_Q[0] |  d25_Q[0]);
wire vB = ~( d24_Q[0] | ~d25_Q[0]);

//_____________________________________________________________________________
//
initial
begin
	AD_in = 0;
	AD_oe = 0;
	nDOUT = 1;
	nDIN  = 1;
	nSYNC = 1;
	nWTBT = 1;
	C     = 0;
	R     = 1;				// resets the chip
#(dT*2);
	qbus_write(16'O177664, 16'O000000);
	R     = 0;
#(dT*2);
	qbus_write(16'O177664, 16'O001330);	// set screen roll register
#(dT*2);
forever	qbus_read(16'O000016);			// keep CPU bus busy
end

task qbus_write
(
   input [15:0]  addr,
   input [15:0]  data
);
begin
   nSYNC = 1;
   nDIN  = 1;
   nDOUT = 1;
   AD_oe = 1;
   AD_in = ~addr;
#(dT);

   nSYNC = 0;
#(dT);
   AD_in = ~data;
#(dT);
   nDOUT = 0;

@ (negedge nRPLY);
#(dT);
   nSYNC = 1;
   nDOUT = 1;
@ (posedge nRPLY);
#(dT);
   AD_oe = 0;
end
endtask

task qbus_read
(
   input [15:0]  addr
);
begin
   nSYNC = 1;
   nDIN  = 1;
   nDOUT = 1;
   AD_oe = 1;
   AD_in = ~addr;
#(dT);
   nSYNC = 0;
#(dT);
   AD_oe = 0;

   nDIN  = 0;
@ (negedge nRPLY);
#(dT);
   AD_out = ~nAD;
   nSYNC = 1;
   nDIN  = 1;
@ (posedge nRPLY);
#(dT);
end
endtask

//_____________________________________________________________________________
//
// Instantiation module under test
//
//
va_037 vp_037
(
   .PIN_CLK(CLK),
   .PIN_R(R),
   .PIN_C(C),
   .PIN_nAD(nAD),
   .PIN_nSYNC(nSYNC),
   .PIN_nDIN(nDIN),
   .PIN_nDOUT(nDOUT),
   .PIN_nWTBT(nWTBT),
   .PIN_nRPLY(nRPLY),
   .PIN_A(A),
   .PIN_nCAS(nCAS),
   .PIN_nRAS(nRAS),
   .PIN_nWE(nWE),
   .PIN_nE(nE),
   .PIN_nBS(nBS),
   .PIN_WTI(WTI),
   .PIN_WTD(WTD),
   .PIN_nVSYNC(nVSYNC)
);

// Dump signals
initial
begin
    $dumpfile("test37.lxt");
    $dumpvars(1, CLK, R, C, nAD, nSYNC, nDIN, nDOUT, nWTBT, nRPLY, A, nCAS, nRAS, nWE, nE, nBS, WTI, WTD, nVSYNC, nIRQ2, RAM_out, vR, vG, vB);
//#(100*dT);
//    $dumpoff;
//#(15000*dT);
//    $dumpon;
end

endmodule
