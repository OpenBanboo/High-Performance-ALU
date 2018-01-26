`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   15:53:44 09/02/2015
// Design Name:   Div_Radix4
// Module Name:   D:/Synchronous/Graduate Studies/Thesis/Summer2014/RecSqr5/Div_Radix4_tb.v
// Project Name:  RecSqr9
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: Div_Radix4
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module Div_Radix4_tb;

	// parameters for 0 iteration
	parameter WL = 24;			 // Word length of the inputs
	parameter WF = 23;			 // Fraction length of the inputs
	parameter RADIX = 4;			 // Radix 4
	parameter N = 12; 			 // WL/cLog2(RADIX) 12,				// Iteration times
	parameter LUT_size = 8;	  	 // The size of the LUT table,
	parameter LUT_bits = 7;		 // the width of the LUT table
	parameter LUT_addWidth = RADIX;

	// Inputs
	reg CLK;							 // clock signal
	reg nRST;						 // negative resert signal
	reg CE;							 // clock enable signal
	reg [WL-1:0] din_x;			 // input structure should be 1.23 for 24 bits input: Dividend
	reg [WL-1:0] din_d;			 // divider

	// Outputs
	wire [WL-1:0] dout;			 // quotient (1.WF format)
	// Real number presentation
	real real_din_x, real_din_d, real_dout;
// ================================  Function Definition  =======================================//

	function integer log2;				// calculate log2(n)
		input integer n;					// always be used to calculate the minimal address bits of a signal array
		begin
			log2 = 0;
			while (2**log2<n) begin
				log2 = log2 + 1;
			end
		end
	endfunction
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	// Present the fixed point number into real number
	function real unsigned_fixedToFloat;
		input [2047:0] in;	//should cover every bit of the maximal value
		input integer WI;
		input integer WF;
		integer idx;
		real retVal;
		begin
			retVal = 0;
			for (idx = 0; idx < WI+WF; idx = idx + 1) begin
				if(in[idx] == 1'b1) begin
					retVal = retVal + (2.0**(idx-WF));
				end
			end
		unsigned_fixedToFloat = retVal;
		end
	endfunction
//==================================================================================================//

//=====================================  clock generator  ==========================================//
	parameter ClockPeriod = 2;	// Clock period
	initial 	 CLK = 0;
	always # (ClockPeriod/2) CLK = ~CLK;
//==================================================================================================//

	// Instantiate the Unit Under Test (UUT)
	Div_Radix4
	#(
		.WL(WL),											// Total word length of input
		.WF(WF),											// Look-up table bits
		.RADIX(RADIX),						  			// World length of the Look-up table
		.N(N),											// Signal symbols whether to use Iterating
		.LUT_size(LUT_size),
		.LUT_bits(LUT_bits),
		.LUT_addWidth(LUT_addWidth)
	)
	Fang_Div_Radix4
	(
		.CLK(CLK), 										// clock
		.nRST(nRST), 									// negative reset
		.CE(CE), 										// clock enable
		.din_x(din_x), 								
		.din_d(din_d), 								
		.dout(dout)
	);

	integer count;		// counter used for looping below

	initial begin

		$readmemb("LUT_Radix_4_m2.txt", Div_Radix4_tb.Fang_Div_Radix4.LUT_m2);
		$readmemb("LUT_Radix_4_m1.txt", Div_Radix4_tb.Fang_Div_Radix4.LUT_m1);
		$readmemb("LUT_Radix_4_m0.txt", Div_Radix4_tb.Fang_Div_Radix4.LUT_m0);
		$readmemb("LUT_Radix_4_mm1.txt", Div_Radix4_tb.Fang_Div_Radix4.LUT_mm1);
		
		// Initialize Inputs
		nRST = 0; @(posedge CLK);
		CE = 1; nRST = 1;
		din_x = 24'b0011_0011_0011_0011_0011_0011; // decimal: 0.4
		din_d = 24'b0101_1001_1001_1001_1001_1001; // decimal: 0.7 // expected result: 0.10010010010010010010000
		for (count = 0; count <= WL/log2(RADIX)-1; count = count+1) begin		
			@(posedge CLK);
		end
		din_x = 24'b0001_0011_0011_0011_0011_0011; // decimal: 0.15
		din_d = 24'b0101_1000_0101_0001_1110_1011; // decimal: 0.69 // 0.217391 expected result: 0.00110111101001101111000
		for (count = 0; count <= WL/log2(RADIX)-1; count = count+1) begin		
			@(posedge CLK);
		end
		din_x = 24'b0101_1110_1011_1000_0101_0001; // decimal: 0.74
		din_d = 24'b0111_1110_1011_1000_0101_0001; // decimal: 0.99 // 0.747475 expected result: 0.00110111101001101111000
		for (count = 0; count <= WL/log2(RADIX)-1; count = count+1) begin		
			@(posedge CLK);
		end
		// After 12 clocks
		@(posedge CLK); @(posedge CLK); @(posedge CLK); $finish; 
        
		// Add stimulus here

	end

	// -- input -- //	
	always @ din_x real_din_x = unsigned_fixedToFloat(din_x, 1, WL-1);
	always @ din_d real_din_d = unsigned_fixedToFloat(din_d, 1, WL-1);

	// -- output -- //	
	always @ dout real_dout = unsigned_fixedToFloat(dout, 1, WL-1);
      
endmodule

