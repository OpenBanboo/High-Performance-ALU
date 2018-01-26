`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   15:16:40 11/11/2014
// Design Name:   fp_sIsqrt
// Module Name:   D:/Synchronous/Graduate Studies/Thesis/Summer2014/RecSqr9/SourceCodes/Square_root/fp_sIsqrt_tb.v
// Project Name:  RecSqr9
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: fp_sIsqrt
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module fp_sIsqrt_tb;

	parameter 
				WI = 10,			 		// input integer size
				WF = 10,			 		// input fractional size
				WL = WI + WF,	 
				WIO = 10,   	 		// output integer size
				WFO = 10,
				LUT_bits = 15,
				LUT_addWidth = 12;   // output fractional size

	// Inputs
	reg CLK;
	reg nRST;
	reg CE;
	reg [WL-1:0] din;

	// Outputs
	wire [WL-1:0] dout;

	// Real number presentation
	real real_din;
//	real real_xh, real_xl, real_Sub, real_Mul;
	real real_dout;

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

	// Instantiate the Unit Under Test (UUT)
	fp_sIsqrt
	#
	(
		.WI(WI),
		.WF(WF),
		.WIO(WIO),
		.WFO(WFO),
		.LUT_bits(LUT_bits),
		.LUT_addWidth(LUT_addWidth)
	)
	Fang_fp_sIsqrt
	(
		.CLK(CLK), 
		.nRST(nRST), 
		.CE(CE), 
		.din(din), 
		.dout(dout)
	);

	initial begin
	
		// initialize the Look-up Table
		//$readmemb("LUT_Isqrt_WLbits_24bit.txt", fp_sIsqrt_tb.Fang_fp_sIsqrt.Fang_Root_Reciprocal_Cascaded_NR_2.LUT);
		$readmemb("LUT_Isqrt_WLbits_20bit.txt", fp_sIsqrt_tb.Fang_fp_sIsqrt.Fang_Root_Reciprocal_Cascaded_NR_2.LUT);
		
		// Initialize Inputs
		nRST = 0; CE = 0; 						// reset
		@(posedge CLK); CE = 1; 
		nRST = 1;  	// start

		// 20 bit 
		din = 20'b0000000001_1000000000; @(posedge CLK);	// input: 10.10 output: 10.10
		din = 20'b0000001100_1100000000; @(posedge CLK);   
		din = 20'b0000000000_0000011010; @(posedge CLK);
		din = 20'b0000000000_0000000001; @(posedge CLK);
		din = 20'b0111111111_1111111111; @(posedge CLK);
		
		// 24 bit 
		/*
		din = 24'b000000000001_100000000000; @(posedge CLK);	// input: 12.12 output: 12.12
		din = 24'b000000110000_110000000000; @(posedge CLK);   
		din = 24'b000000000000_000001101001; @(posedge CLK);
		din = 24'b000000000000_000000000001; @(posedge CLK);
		din = 24'b011111111111_111111111111; @(posedge CLK);
		*/
		
		// din = 24'b000001000101_111110011001; @(posedge CLK);  // input: 2.24 output: 8.16
		//Wait 100 ns for global reset to finish
		$finish;
        
		// Add stimulus here

	end

	// -- input -- //	
	always @ din real_din = fixedToFloat(din, WI, WF);

	// -- output -- //	
	always @ dout real_dout = fixedToFloat(dout, WIO, WFO);
      
endmodule

