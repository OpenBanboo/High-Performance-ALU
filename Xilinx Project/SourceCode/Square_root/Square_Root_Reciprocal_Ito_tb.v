`timescale 1ns / 1ps
`define Testdata_Depth 841		// Sample 80 inputs from exhaustive simulation
////////////////////////////////////////////////////////////////////////////////
// Company: 		VLSI Design and Test Laboratory (E-218) - SDSU
// Engineer:		Fang Lin
//
// Create Date:   21:46:57 07/28/2014
// Design Name:   Square_Root_Reciprocal_Ito_Iter1
// Module Name:   D:/Synchronous/Graduate Studies/Thesis/Summer2014/RecSqr4/RecSqr3/SourceCodes/Square_root/Square_Root_Reciprocal_Ito_tb.v
// Project Name:  RecSqr3
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: Square_Root_Reciprocal_Ito_Iter1
//
// Dependencies:
//					The input of this module is fixed as 1.x sturcture as the same 
//					with the mantissa part of Single-Precision Floating-point format
//					This module can be used to explored into parametric Fixed-point
//					and Floating point stucture in the future.
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module Square_Root_Reciprocal_Ito_tb;

	// parameters
	parameter WL = 24;			 		 // Word length of the inputs
	parameter LUT_bits = 13;	 		 // word length of the Look-up table
	parameter LUT_addWidth = 6;  		 // address length of the Look-up table
	parameter m = LUT_addWidth + 1;	 // Whether use iteration to approach	
	parameter dWL = 28;
	parameter WLO = 24;

	// Inputs
	reg CLK;			
	reg nRST;
	reg CE;
	reg [WL-1:0] din;

	// Outputs
	wire [WLO-1:0] dout, dout_pipe;

	// Memory 
	// used to store the testcases
	reg [WL-1:0] Testdata_vec_NR [`Testdata_Depth-1:0];
	// Matlab simulation result vector
	reg [WL-1:0] Simu_Result_Matlab [`Testdata_Depth-1:0];
	
	// Real number presentation
	real real_din, real_MATLAB_reuslt, real_Xilinx_result, real_Xilinx_result_pipe, real_iniValue, real_xHat, real_Mul_s;
	real real_D1, real_iniValue2, real_iniValue3, real_iniValue4, real_Sub, real_Mul;

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
//==================================================================================================//
	
//=====================================  clock generator  ==========================================//
	parameter ClockPeriod = 2;	// Clock period
	initial 	 CLK = 0;
	always # (ClockPeriod/2) CLK = ~CLK;
//==================================================================================================//
	// Instantiate the Unit Under Test (Fang_Reciprocal_cascaded_NR)
	Square_Root_Reciprocal_Ito_Iter1
	#(
		.WL(WL),								// Total word length of input
		.LUT_bits(LUT_bits),				// Look-up table bits
		.LUT_addWidth(LUT_addWidth),  // World length of the Look-up table
		.dWL(dWL),
		.WLO(WLO)
    )
	Fang_Square_Root_Reciprocal_Ito 
	(
		.CLK(CLK), 							// clock
		.nRST(nRST), 						// negative reset
		.CE(CE), 							// clock enable
		.din(din), 							// data input 
		.dout(dout)							// data output
	 );
	 
	// Instantiate the Pipelined Unit Under Test (Fang_Reciprocal_cascaded_NR)
	Square_Root_Reciprocal_Ito_Iter1_Pipe
	#(
		.WL(WL),								// Total word length of input
		.LUT_bits(LUT_bits),				// Look-up table bits
		.LUT_addWidth(LUT_addWidth),  // World length of the Look-up table
		.dWL(dWL),
		.WLO(WLO)
    )
	Fang_Square_Root_Reciprocal_Ito_pipe
	(
		.CLK(CLK), 							// clock
		.nRST(nRST), 						// negative reset
		.CE(CE), 							// clock enable
		.din(din), 							// data input 
		.dout(dout_pipe)					// data output
	 );
	 
//==================================================================================================//

//===========================================  Inpulse =============================================//
	integer count;		// counter used for looping below
	real count_mismatched = 0; // counter to store the mismatched result number
	initial begin
	
		// initialize the input vector
		$readmemb("ini_input_binary_isqt_Ito.txt", Testdata_vec_NR);		
		$readmemb("result_isqt_Ito.txt", Simu_Result_Matlab);
		// initialize the Look-up Table
		$readmemb("LUT_isqt_Ito.txt", Square_Root_Reciprocal_Ito_tb.Fang_Square_Root_Reciprocal_Ito.LUT);
		$readmemb("LUT_isqt_Ito.txt", Square_Root_Reciprocal_Ito_tb.Fang_Square_Root_Reciprocal_Ito_pipe.LUT);

		nRST = 0; CE = 0; 						// reset
		@(posedge CLK); CE = 1; 
		nRST = 1;  	// start
		
		for (count = 0; count <= `Testdata_Depth; count = count+1) begin		
			din = Testdata_vec_NR[count];
		   $display("MATLAB: %f, Xilinx: %f", unsigned_fixedToFloat(Simu_Result_Matlab[count-1], 1, WL-1), unsigned_fixedToFloat(dout, 1, WL-1));
			if (unsigned_fixedToFloat(Simu_Result_Matlab[count-1], 1, WL-1)==unsigned_fixedToFloat(dout, 1, WL-1))
//		   $display("MATLAB: %b, Xilinx: %b", Simu_Result_Matlab[count], dout);
//			if (Simu_Result_Matlab[count] == dout)
				$display("MATCHED");
			else begin
				count_mismatched = count_mismatched + 1;
				$display("MISMATCHED HERE <================= !!! ");
				$display("The NO.%d result is not matched, MATLAB: %b, Xilinx: %b ", count, Simu_Result_Matlab[count-1], dout);
			end
			@(posedge CLK);
			if (count==`Testdata_Depth) begin
				$display("Mismatched proporbility: %f", count_mismatched/`Testdata_Depth);
				$finish;
			end
		end

	end

//===================================  Real Pesentation  ============================================// 
	// -- input -- //
	always @ din real_din = unsigned_fixedToFloat(din, 1, WL-1);
	
	// -- intermediate -- //
		// -- D1
	always @ Square_Root_Reciprocal_Ito_tb.Fang_Square_Root_Reciprocal_Ito.D1 
			   real_D1 = unsigned_fixedToFloat(Square_Root_Reciprocal_Ito_tb.Fang_Square_Root_Reciprocal_Ito.D1, 0, LUT_bits);
		// -- xHat
	always @ Square_Root_Reciprocal_Ito_tb.Fang_Square_Root_Reciprocal_Ito.xHat 
				real_xHat = unsigned_fixedToFloat(Square_Root_Reciprocal_Ito_tb.Fang_Square_Root_Reciprocal_Ito.xHat, 1, WL);
		// -- iniValue
	always @ Square_Root_Reciprocal_Ito_tb.Fang_Square_Root_Reciprocal_Ito.iniValue 
				real_iniValue = unsigned_fixedToFloat(Square_Root_Reciprocal_Ito_tb.Fang_Square_Root_Reciprocal_Ito.iniValue, 2, dWL-2);
		// -- iniValue2
	always @ Square_Root_Reciprocal_Ito_tb.Fang_Square_Root_Reciprocal_Ito.iniValue2 
				real_iniValue2 = unsigned_fixedToFloat(Square_Root_Reciprocal_Ito_tb.Fang_Square_Root_Reciprocal_Ito.iniValue2, 2, dWL-2);
		// -- iniValue3
	always @ Square_Root_Reciprocal_Ito_tb.Fang_Square_Root_Reciprocal_Ito.iniValue3 
				real_iniValue3 = unsigned_fixedToFloat(Square_Root_Reciprocal_Ito_tb.Fang_Square_Root_Reciprocal_Ito.iniValue3, 2, dWL-2);
		// -- Sub
	always @ Square_Root_Reciprocal_Ito_tb.Fang_Square_Root_Reciprocal_Ito.Sub 
				real_Sub = unsigned_fixedToFloat(Square_Root_Reciprocal_Ito_tb.Fang_Square_Root_Reciprocal_Ito.Sub, 2, dWL-2);
		// -- iniValue4
	always @ Square_Root_Reciprocal_Ito_tb.Fang_Square_Root_Reciprocal_Ito.iniValue4 
				real_iniValue4 = unsigned_fixedToFloat(Square_Root_Reciprocal_Ito_tb.Fang_Square_Root_Reciprocal_Ito.iniValue4, 2, dWL*2-2);
		// -- Mul
	always @ Square_Root_Reciprocal_Ito_tb.Fang_Square_Root_Reciprocal_Ito.Mul 
				real_Mul = unsigned_fixedToFloat(Square_Root_Reciprocal_Ito_tb.Fang_Square_Root_Reciprocal_Ito.Mul, 2, WL+1-2);		
		// -- Mul_s
	always @ Square_Root_Reciprocal_Ito_tb.Fang_Square_Root_Reciprocal_Ito.Mul_s 
				real_Mul_s = unsigned_fixedToFloat(Square_Root_Reciprocal_Ito_tb.Fang_Square_Root_Reciprocal_Ito.Mul_s, 2, WL+1-2);

	// -- output -- //	
	always @ dout real_Xilinx_result = unsigned_fixedToFloat(dout, 1,WLO-1);
	always @ dout_pipe real_Xilinx_result_pipe = unsigned_fixedToFloat(dout_pipe, 1, WLO-1);
	always @ Simu_Result_Matlab[count] real_MATLAB_reuslt = unsigned_fixedToFloat(Simu_Result_Matlab[count], 1, WL-1);

      
endmodule

