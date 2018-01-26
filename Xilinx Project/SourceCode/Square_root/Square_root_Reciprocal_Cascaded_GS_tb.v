`timescale 1ns / 1ps
`define Testdata_Depth 853		// Sample 80 inputs from exhaustive simulation
////////////////////////////////////////////////////////////////////////////////
// Company: 		VLSI Design and Test Laboratory (E-218) - SDSU
// Engineer:		Fang Lin
//
// Create Date:   17:17:00 07/19/2014
// Design Name:   Square_root_Reciprocal_GS_DirectImplementation
// Module Name:   D:/Synchronous/Graduate Studies/Thesis/Summer2014/RecSqr4/RecSqr3/SourceCodes/Square_root/Square_root_Reciprocal_Cascaded_GS_tb.v
// Project Name:  	RecSqr
// Target Device: 	Xilinx family 
// Tool versions: 	ISE 14.6
// Description: 
//
// Verilog Test Fixture created by ISE for module: Square_root_Reciprocal_GS_DirectImplementation
//
// Dependencies:
//					The input of this module is fixed as 1.x sturcture as the same 
//					with the mantissa part of Single-Precision Floating-point format
//					This module can be used to explored into parametric Fixed-point
//					and Floating point stucture in the future.
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module Square_root_Reciprocal_Cascaded_GS_tb;

	// parameters
	parameter WL = 24;			 	 	// Word length of the inputs
	parameter LUT_bits = 9;	 	 		// word length of the Look-up table
	parameter LUT_addWidth = 9;  		// address length of the Look-up table
	parameter dWL = 26;		
	parameter WLO2 = 24;
	parameter address_bits = 6;
	
	// Inputs
	reg CLK;
	reg nRST;
	reg CE;
	reg [WL-1:0] din;

	// Outputs
	wire [WL-1:0] dout;

	// Memory 
	// used to store the testcases
	reg [WL-1:0] Testdata_vec_NR [`Testdata_Depth-1:0];
	// Matlab simulation result vector
	reg [WL-1:0] Simu_Result_Matlab [`Testdata_Depth-1:0];

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

	// Instantiate the Unit Under Test (UUT)
	Square_root_Reciprocal_GS_DirectImplementation
	#(
		.WL(WL),									// Total word length of input
		.address_bits(address_bits),		// Look-up table bits
		.LUT_bits(LUT_bits),  				// World length of the Look-up table
		.dWL(dWL)								// datapath
	)
	Fang_Square_root_Rec (
		.CLK(CLK), 
		.RST(nRST), 
		.CE(CE), 
		.in(din), 
		.result(dout)
	);


//=====================================  clock generator  ==========================================//
	parameter ClockPeriod = 2;	// Clock period
	initial 	 CLK = 0;
	always # (ClockPeriod/2) CLK = ~CLK;
//==================================================================================================//

//===========================================  Inpulse =============================================//
	integer count;									// counter used for looping below
	real count_mismatched = 0; 				// counter to store the mismatched result number
	initial begin
		// initialize the input vector
		$readmemb("ini_input_binary_isqt_GS.txt", Testdata_vec_NR);		
	
		// initialize the Look-up Table
		$readmemb("LUT_isqt_GS_iter1.txt", Square_root_Reciprocal_Cascaded_GS_tb.Fang_Square_root_Rec.LUT);
		$readmemb("result_binary_isqt_GS.txt", Simu_Result_Matlab);

		nRST = 0; CE = 0; 						// reset
		@(posedge CLK); nRST = 1; CE = 1; 	// start
		
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
// =============================================================================================
// Real number presentation
	real real_din, real_ini, real_p1, real_r1, real_d1, real_d2, real_d2_s;
	real real_MATLAB_reuslt, real_Xilinx_result;
	real real_d1_net, real_p2, real_d2_net, real_d3, real_d3_s, real_p3, real_r2, real_r3_net;
// =============================================================================================	
	

	// -- input -- //
	always @ din real_din = unsigned_fixedToFloat(din, 1, WL-1);

	// -- Intermediat -- //
	// -- ini
	always @ Square_root_Reciprocal_Cascaded_GS_tb.Fang_Square_root_Rec.ini
			   real_ini = unsigned_fixedToFloat(Square_root_Reciprocal_Cascaded_GS_tb.Fang_Square_root_Rec.ini, 1, LUT_bits-1);

	// -- p1
	always @ Square_root_Reciprocal_Cascaded_GS_tb.Fang_Square_root_Rec.p1
			   real_p1 = unsigned_fixedToFloat(Square_root_Reciprocal_Cascaded_GS_tb.Fang_Square_root_Rec.p1, 1, LUT_bits-1);
				
	// -- d1
	always @ Square_root_Reciprocal_Cascaded_GS_tb.Fang_Square_root_Rec.d1
			   real_d1 = unsigned_fixedToFloat(Square_root_Reciprocal_Cascaded_GS_tb.Fang_Square_root_Rec.d1, 1, WL-1);

	// -- d1_net
	always @ Square_root_Reciprocal_Cascaded_GS_tb.Fang_Square_root_Rec.d1_net
			   real_d1_net = unsigned_fixedToFloat(Square_root_Reciprocal_Cascaded_GS_tb.Fang_Square_root_Rec.d1_net, 1, dWL-1);
				
	// -- d2
	always @ Square_root_Reciprocal_Cascaded_GS_tb.Fang_Square_root_Rec.d2
			   real_d2 = unsigned_fixedToFloat(Square_root_Reciprocal_Cascaded_GS_tb.Fang_Square_root_Rec.d2, 1, dWL-1);
				
	// -- d2_s
	always @ Square_root_Reciprocal_Cascaded_GS_tb.Fang_Square_root_Rec.d2_s
			   real_d2_s = unsigned_fixedToFloat(Square_root_Reciprocal_Cascaded_GS_tb.Fang_Square_root_Rec.d2_s, 1, dWL-1);
				
	// -- p2
	always @ Square_root_Reciprocal_Cascaded_GS_tb.Fang_Square_root_Rec.p2
			   real_p2 = unsigned_fixedToFloat(Square_root_Reciprocal_Cascaded_GS_tb.Fang_Square_root_Rec.p2, 1, dWL-1);
				
	// -- d2_net
	always @ Square_root_Reciprocal_Cascaded_GS_tb.Fang_Square_root_Rec.d2_net
			   real_d2_net = unsigned_fixedToFloat(Square_root_Reciprocal_Cascaded_GS_tb.Fang_Square_root_Rec.d2_net, 1, dWL-1);

	// -- d3
	always @ Square_root_Reciprocal_Cascaded_GS_tb.Fang_Square_root_Rec.d3
			   real_d3 = unsigned_fixedToFloat(Square_root_Reciprocal_Cascaded_GS_tb.Fang_Square_root_Rec.d3, 1, dWL-1);
				
	// -- d3_s
	always @ Square_root_Reciprocal_Cascaded_GS_tb.Fang_Square_root_Rec.d3_s
			   real_d3_s = unsigned_fixedToFloat(Square_root_Reciprocal_Cascaded_GS_tb.Fang_Square_root_Rec.d3_s, 1, dWL-1);
				
	// -- p3
	always @ Square_root_Reciprocal_Cascaded_GS_tb.Fang_Square_root_Rec.p3
			   real_p3 = unsigned_fixedToFloat(Square_root_Reciprocal_Cascaded_GS_tb.Fang_Square_root_Rec.p3, 1, dWL-1);

	// -- r1
	always @ Square_root_Reciprocal_Cascaded_GS_tb.Fang_Square_root_Rec.r1
			   real_r1 = unsigned_fixedToFloat(Square_root_Reciprocal_Cascaded_GS_tb.Fang_Square_root_Rec.r1, 1, LUT_bits-1);
				
	// -- r2
	always @ Square_root_Reciprocal_Cascaded_GS_tb.Fang_Square_root_Rec.r2
			   real_r2 = unsigned_fixedToFloat(Square_root_Reciprocal_Cascaded_GS_tb.Fang_Square_root_Rec.r2, 1, dWL-1);
				
	// -- r3_net
	always @ Square_root_Reciprocal_Cascaded_GS_tb.Fang_Square_root_Rec.r3_net
			   real_r3_net = unsigned_fixedToFloat(Square_root_Reciprocal_Cascaded_GS_tb.Fang_Square_root_Rec.r3_net, 1, dWL-1);
  
	// -- output -- //	
	always @ dout real_Xilinx_result = unsigned_fixedToFloat(dout, 1, WL-1);
	always @ Simu_Result_Matlab[count] real_MATLAB_reuslt = unsigned_fixedToFloat(Simu_Result_Matlab[count], 1, WL-1);
	 
endmodule
      

