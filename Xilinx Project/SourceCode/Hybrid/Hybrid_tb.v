`timescale 1ns / 1ps
`define Testdata_Depth 836		// Sample 80 inputs from exhaustive simulation
////////////////////////////////////////////////////////////////////////////////
// Company: 		VLSI Design and Test Laboratory (E-218) - SDSU
// Engineer:		Fang Lin
//
// Create Date:   20:06:57 08/25/2014
// Design Name:   Hybrid
// Module Name:   D:/Synchronous/Graduate Studies/Thesis/Summer2014/RecSqr5/SourceCodes/Hybrid/Hybrid_tb.v
// Project Name:  RecSqr5
// Target Device: Xilinx Family 
// Tool versions: ISE 14.6
// Description: 
//
// Verilog Test Fixture created by ISE for module: Hybrid
//																	which is a combined datapath of rec, sqrt, isqrt
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

module Hybrid_tb;

	// parameters for p = 1 situation
	parameter WL = 25;			 	// Word length of the inputs
	parameter LUT_bits = 27;	 	// word length of the Look-up table
	parameter LUT_addWidth = 11;  // address length of the Look-up table
	parameter dWL = 30;
	parameter p = 1;

	// Inputs
	reg CLK;					// clock
	reg nRST;				//	negative reset
	reg CE;					// clock enable
	reg [WL-1:0] din;		// input
	reg [1:0] FUNCTION;	// Function choice, 0: reciprocal, 1: square root, 2: reciprocal square root
	
	// Outputs
	wire [WL-1:0] dout;	// output

	// Memory 
	// used to store the testcases
	reg [WL-1:0] Testdata_vec_NR [`Testdata_Depth-1:0];
	// Matlab simulation result vector
	reg [dWL-1:0] Simu_Result_Matlab [`Testdata_Depth-1:0];

	// Real number presentationd
	real real_din, real_MATLAB_reuslt, real_Xilinx_result;
	real real_iniValue, real_input_mul1, real_xo;
	real real_dout;

//=====================================  clock generator  ==========================================//
	parameter ClockPeriod = 2;	// Clock period
	initial 	 CLK = 0;
	always # (ClockPeriod/2) CLK = ~CLK;
//==================================================================================================//
	
// ====================================Function Definition==========================================//
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
//==================================================================================================//

	// Instantiate the Unit Under Test (UUT)
	Hybrid
	#(
		.WL(WL),											// Total word length of input
		.LUT_bits(LUT_bits),							// Look-up table bits
		.LUT_addWidth(LUT_addWidth),  			// World length of the Look-up table
		.dWL(dWL),										// Signal symbols whether to use Iterating
		.p(p)
	)
	Fang_rec_interpolat (
		.CLK(CLK), 
		.nRST(nRST), 
		.CE(CE), 
		.din(din),
		.FUNCTION(FUNCTION),		
		.dout(dout)
	);

//===========================================  Inpulse =============================================//
	integer count;		// counter used for looping below
	real count_mismatched = 0; // counter to store the mismatched result number
	initial begin


	// parameters for rec, p == 1
		// initialize the input vector
		$readmemb("ini_input_binary_rec_interpolat_hybrid_p1.txt", Testdata_vec_NR);		
		FUNCTION = 2'b00;
		// initialize the Look-up Table
		$readmemb("LUT_rec_Interpolat_hybrid_p1.txt", Hybrid_tb.Fang_rec_interpolat.LUT_rec);
		$readmemb("result_rec_interpolat_round_hybrid_p1.txt", Simu_Result_Matlab);

/*
	// parameters for sqrt, p == 1
		// initialize the input vector
		$readmemb("ini_input_binary_sqrt_interpolat_hybrid_p1.txt", Testdata_vec_NR);		
		FUNCTION = 2'b01;
		// initialize the Look-up Table
		$readmemb("LUT_sqrt_Interpolat_hybrid_p1.txt", Hybrid_tb.Fang_rec_interpolat.LUT_sqrt);
		$readmemb("result_sqrt_interpolat_round_hybrid_p1.txt", Simu_Result_Matlab);		
*/

/*
	// parameters for isqrt, p == 1
		// initialize the input vector
		$readmemb("ini_input_binary_isqt_interpolat_hybrid_p1.txt", Testdata_vec_NR);		
		FUNCTION = 2'b11;
		// initialize the Look-up Table
		$readmemb("LUT_isqt_Interpolat_hybrid_p1.txt", Hybrid_tb.Fang_rec_interpolat.LUT_isqt);
		$readmemb("result_isqt_interpolat_round_hybrid_p1.txt", Simu_Result_Matlab);
*/

		nRST = 0; CE = 0; 						// reset
		@(posedge CLK); CE = 1; 
		nRST = 1;  	// start

		
		if(p==1) begin
			for (count = 0; count <= `Testdata_Depth; count = count+1) begin		
				din = Testdata_vec_NR[count];
				@(posedge CLK);
				$display("MATLAB: %f, Xilinx: %f", fixedToFloat(Simu_Result_Matlab[count-1], 2, WL-2), fixedToFloat(dout, 2, WL-2));
				if (fixedToFloat(Simu_Result_Matlab[count-1], 2, WL-2)==fixedToFloat(dout, 2, WL-2)) begin
				//if (Simu_Result_Matlab[count-1][WL-1:1]==dout[WL-1:1]) begin
					$display("MATCHED");
					//$display("The NO.%d result is not matched, MATLAB: %b, Xilinx: %b ", count, Simu_Result_Matlab[count-1], dout);
				end else begin
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
		end else if (p == 2) begin
			for (count = 0; count <= `Testdata_Depth; count = count+1) begin		
				din = Testdata_vec_NR[count];
				@(posedge CLK);@(posedge CLK);
				$display("MATLAB: %f, Xilinx: %f", fixedToFloat(Simu_Result_Matlab[count-1], 1, WL-1), fixedToFloat(dout, 1, WL-1));
				if (fixedToFloat(Simu_Result_Matlab[count-1], 1, WL-1)==fixedToFloat(dout, 1, WL-1))

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
	end

//===================================  Real Pesentation  ============================================// 
	// -- input -- //
	always @ din real_din = fixedToFloat(din, 2, WL-2);

	// -- inter -- //
	always @ Hybrid_tb.Fang_rec_interpolat.iniValue real_iniValue = fixedToFloat(Hybrid_tb.Fang_rec_interpolat.iniValue, 2, LUT_bits-2);
	always @ Hybrid_tb.Fang_rec_interpolat.input_mul1 real_input_mul1 = fixedToFloat(Hybrid_tb.Fang_rec_interpolat.input_mul1, 2, dWL-2);
	always @ Hybrid_tb.Fang_rec_interpolat.xo real_xo = fixedToFloat(Hybrid_tb.Fang_rec_interpolat.xo, 2, WL-LUT_addWidth-2);

	// -- output -- //	
	always @ dout real_Xilinx_result = fixedToFloat(dout, 2, WL-2);
	always @ Simu_Result_Matlab[count] real_MATLAB_reuslt = fixedToFloat(Simu_Result_Matlab[count], 2, WL-2);	
endmodule

