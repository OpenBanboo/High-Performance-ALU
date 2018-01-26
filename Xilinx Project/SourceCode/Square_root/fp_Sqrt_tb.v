`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   12:22:42 11/14/2014
// Design Name:   fp_Sqrt
// Module Name:   D:/Synchronous/Graduate Studies/Thesis/Summer2014/RecSqr9/SourceCodes/Square_root/fp_Sqrt_tb.v
// Project Name:  RecSqr9
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: fp_Sqrt
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module fp_Sqrt_tb;

	parameter 
				WI = 4,			 		// input integer size
				WF = 4,			 		// input fractional size
				WL = WI + WF,	 
				WIO = 4,   	 		// output integer size
				WFO = 4,
				LUT_bits = 10,
				LUT_addWidth = 4;   // output fractional size

	// Inputs
	reg CLK;
	reg nRST;
	reg CE;
	reg [WL-1:0] din;

	// Outputs
	wire [WL-1:0] dout;

// ================================  Function Definition  =======================================//
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
	
// ================================Function Definition==================================//
	function real fixedToFloat;
		input [2047:0] in;
		input integer WI;
		input integer WF;
		integer idx;
		real retVal;
		begin
			retVal = 0;
			for (idx = 0; idx < WI+WF-1; idx = idx + 1) begin
				if(in[idx] == 1'b1) begin
					retVal = retVal + (2.0**(idx-WF));
				end
			end
		fixedToFloat = retVal - (in[WI+WF-1] * (2.0**(WI-1)));
		end
	endfunction
// ======================================================================================//
//==================================================================================================//	
//=====================================  clock generator  ==========================================//
	parameter ClockPeriod = 2;	// Clock period
	initial 	 CLK = 0;
	always # (ClockPeriod/2) CLK = ~CLK;
//==================================================================================================//

	// Real number presentation
	real real_din;
	real real_dout;
	// Instantiate the Unit Under Test (UUT)
	fp_Sqrt
	#
	(
		.WI(WI),
		.WF(WF),
		.WIO(WIO),
		.WFO(WFO),
		.LUT_bits(LUT_bits),
		.LUT_addWidth(LUT_addWidth)
	)
	Fang_fp_Sqrt
	(
		.CLK(CLK), 
		.nRST(nRST), 
		.CE(CE), 
		.din(din), 
		.dout(dout)
	);

	initial begin
	
		// initialize the Look-up Table
		// 24 bit
		// $readmemb("LUT_Sqrt_WLbits.txt", fp_Sqrt_tb.Fang_fp_Sqrt.Fang_Square_Root_Hung.LUT);
		
		// 20 bit
		// $readmemb("LUT_sqrt_Hung_20bit.txt", fp_Sqrt_tb.Fang_fp_Sqrt.Fang_Square_Root_Hung.LUT);
	
		// 16 bit
		// $readmemb("LUT_sqrt_Hung_16bit.txt", fp_Sqrt_tb.Fang_fp_Sqrt.Fang_Square_Root_Hung.LUT);

		// 12 bit
		// $readmemb("LUT_sqrt_Hung_12bit.txt", fp_Sqrt_tb.Fang_fp_Sqrt.Fang_Square_Root_Hung.LUT);
		
		// 10 bit
		// $readmemb("LUT_sqrt_Hung_10bit.txt", fp_Sqrt_tb.Fang_fp_Sqrt.Fang_Square_Root_Hung.LUT);

		// 8 bit
		$readmemb("LUT_sqrt_Hung_8bit.txt", fp_Sqrt_tb.Fang_fp_Sqrt.Fang_Square_Root_Hung.LUT);
		
		// Initialize Inputs
		nRST = 0; CE = 0; 						// reset
		@(posedge CLK); CE = 1; 
		nRST = 1;  	// start


		// 8 bit
		din = 10'b0001_1000; @(posedge CLK);	// input: 12.12 output: 12.12
		din = 10'b0011_1100; @(posedge CLK);   
		din = 10'b0000_0011; @(posedge CLK);
		din = 10'b0000_0001; @(posedge CLK);
		din = 10'b0111_1111; @(posedge CLK);


		// 10 bit
		/*
		din = 10'b00001_10000; @(posedge CLK);	// input: 12.12 output: 12.12
		din = 10'b00011_11000; @(posedge CLK);   
		din = 10'b00000_00011; @(posedge CLK);
		din = 10'b00000_00001; @(posedge CLK);
		din = 10'b01111_11111; @(posedge CLK);
		*/


		// 12 bit
		/*
		din = 12'b000001_100000; @(posedge CLK);	// input: 12.12 output: 12.12
		din = 12'b000011_110000; @(posedge CLK);   
		din = 12'b000000_000110; @(posedge CLK);
		din = 12'b000000_000001; @(posedge CLK);
		din = 12'b011111_111111; @(posedge CLK);
		*/

		// 16 bit
		/*
		din = 16'b00000001_10000000; @(posedge CLK);	// input: 10.10 output: 10.10
		din = 16'b00000011_11000000; @(posedge CLK);   
		din = 16'b00000000_00011010; @(posedge CLK);
		din = 16'b00000000_00000001; @(posedge CLK);
		din = 16'b01111111_11111111; @(posedge CLK);
		*/
		/*
		// 20 bit
		din = 20'b0000000001_1000000000; @(posedge CLK);	// input: 10.10 output: 10.10
		din = 20'b0000001100_1100000000; @(posedge CLK);   
		din = 20'b0000000000_0001101001; @(posedge CLK);
		din = 20'b0000000000_0000000001; @(posedge CLK);
		din = 20'b0111111111_1111111111; @(posedge CLK);
		*/
		// 24 bit
	/*	
		din = 24'b000000000001_100000000000; @(posedge CLK);	// input: 12.12 output: 12.12
		din = 24'b000000110000_110000000000; @(posedge CLK);   
		din = 24'b000000000000_000001101001; @(posedge CLK);
		din = 24'b000000000000_000000000001; @(posedge CLK);
		din = 24'b011111111111_111111111111; @(posedge CLK);
	*/
		
		
		
		//din = 24'b00000000010000_1101000001; @(posedge CLK);  // input: 16.8 output: 4.20
		
		
		//din = 24'b000001000101_111110011001; @(posedge CLK);  // input: 2.24 output: 8.16
		//Wait 100 ns for global reset to finish
		$finish;
        
		// Add stimulus here

	end

	// -- input -- //	
	always @ din real_din = fixedToFloat(din, WI, WF);

	// -- output -- //	
	always @ dout real_dout = fixedToFloat(dout, WIO, WFO);
      
endmodule

