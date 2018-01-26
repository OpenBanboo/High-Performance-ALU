`timescale 1ns / 1ps
`define Testdata_Depth 841		// Sample 80 inputs from exhaustive simulation
////////////////////////////////////////////////////////////////////////////////
// Company: 		VLSI Design and Test Laboratory (E-218) - SDSU
// Engineer:		Fang Lin
//
// Create Date:   15:37:07 06/29/2014
// Design Name:   Square_root_Reciprocal_NR_DirectImplementation
// Module Name:   D:/Synchronous/Graduate Studies/Thesis/Summer2014/RecSqr/SourceCodes/Square_root/Square_root_Reciprocal_Cascaded_tb.v
// Project Name:  RecSqr
// Target Device: Xilinx family 
// Tool versions: ISE 14.6
// Description: 
//
// Verilog Test Fixture created by ISE for module: Square_root_Reciprocal_NR_DirectImplementation
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module Square_root_Reciprocal_Cascaded_tb;

	// parameters
	parameter WL = 24;			 // Word length of the inputs
	parameter LUT_bits = 13;	 // word length of the Look-up table
	parameter LUT_addWidth = 6; // address length of the Look-up table
	parameter ITERATION = 1;	 // Whether use iteration to approach	

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

	// Real number presentation
	real real_din, real_MATLAB_reuslt, real_Xilinx_result;
	real real_mul_1, real_mul_2, real_mul_2_s;
	real real_out_0, real_out_1, real_mul_3, real_mul_3_s;
	real real_mul_4, real_mul_5, real_mul_5_s, real_mul_6, real_mul_6_s;
	real real_fpThree, real_fpThree_2;
	real real_sub_1, real_sub_2;

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


	// Instantiate the Unit Under Test (UUT)
	Square_root_Reciprocal_NR_DirectImplementation
	#(
		.WL(WL),								// Total word length of input
		.LUT_bits(LUT_bits),				// Look-up table bits
		.LUT_addWidth(LUT_addWidth),  // World length of the Look-up table
		.ITERATION(ITERATION)			// Signal symbols whether to use Iterating
    )
	Fang_Square_Root_Reciprocal_cascaded_NR 
	(
		.CLK(CLK), 							// clock
		.nRST(nRST), 						// negative reset
		.CE(CE), 							// clock enable
		.din(din), 							// data input 
		.dout(dout)							// data output
	 );
//==================================================================================================//

//===========================================  Inpulse =============================================//
	integer count;					// counter used for looping below
	real count_mismatched = 0; // counter to store the mismatched result number
	initial begin
	
		// initialize the input vector
		$readmemb("ini_input_binary_isqt_NR.txt", Testdata_vec_NR);		
	
		// initialize the Look-up Table
		$readmemb("LUT_isqt_NR_iter1.txt", Square_root_Reciprocal_Cascaded_tb.Fang_Square_Root_Reciprocal_cascaded_NR.LUT);
		$readmemb("result_binary_isqt_NR.txt", Simu_Result_Matlab);
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
	 
//===================================  Real Pesentation  ============================================// 
	// -- input -- //
	always @ din real_din = unsigned_fixedToFloat(din, 1, WL-1);
	
	// -- intermediate -- //
	// ** iteration 0 ** //
		// -- mul_1
	always @ Square_root_Reciprocal_Cascaded_tb.Fang_Square_Root_Reciprocal_cascaded_NR.mul_1 
			   real_mul_1 = unsigned_fixedToFloat(Square_root_Reciprocal_Cascaded_tb.Fang_Square_Root_Reciprocal_cascaded_NR.mul_1, 2, LUT_bits*2-2);
		// -- mul_2
	always @ Square_root_Reciprocal_Cascaded_tb.Fang_Square_Root_Reciprocal_cascaded_NR.mul_2 
				real_mul_2 = unsigned_fixedToFloat(Square_root_Reciprocal_Cascaded_tb.Fang_Square_Root_Reciprocal_cascaded_NR.mul_2, 3, WL+LUT_bits*2-3);
		// -- mul_2_r
	always @ Square_root_Reciprocal_Cascaded_tb.Fang_Square_Root_Reciprocal_cascaded_NR.mul_2_s 
				real_mul_2_s = unsigned_fixedToFloat(Square_root_Reciprocal_Cascaded_tb.Fang_Square_Root_Reciprocal_cascaded_NR.mul_2_s, 2, WL+LUT_bits*2-3);		
		// -- sub_1
	always @ Square_root_Reciprocal_Cascaded_tb.Fang_Square_Root_Reciprocal_cascaded_NR.sub_1 
				real_sub_1 = unsigned_fixedToFloat(Square_root_Reciprocal_Cascaded_tb.Fang_Square_Root_Reciprocal_cascaded_NR.sub_1, 2, WL+LUT_bits*2-3);		
		// -- fpThree
	always @ Square_root_Reciprocal_Cascaded_tb.Fang_Square_Root_Reciprocal_cascaded_NR.fpThree 
				real_fpThree = unsigned_fixedToFloat(Square_root_Reciprocal_Cascaded_tb.Fang_Square_Root_Reciprocal_cascaded_NR.fpThree, 2, WL+LUT_bits*2-3);		
		// -- mul_3
	always @ Square_root_Reciprocal_Cascaded_tb.Fang_Square_Root_Reciprocal_cascaded_NR.mul_3 
				real_mul_3 = unsigned_fixedToFloat(Square_root_Reciprocal_Cascaded_tb.Fang_Square_Root_Reciprocal_cascaded_NR.mul_3, 3, WL+LUT_bits*3-4);			
		// -- mul_3_s
	always @ Square_root_Reciprocal_Cascaded_tb.Fang_Square_Root_Reciprocal_cascaded_NR.mul_3_s
				real_mul_3_s = unsigned_fixedToFloat(Square_root_Reciprocal_Cascaded_tb.Fang_Square_Root_Reciprocal_cascaded_NR.mul_3_s, 1, WL+LUT_bits*3-3);			
		// -- out_0
	always @ Square_root_Reciprocal_Cascaded_tb.Fang_Square_Root_Reciprocal_cascaded_NR.out_0 
				real_out_0 = unsigned_fixedToFloat(Square_root_Reciprocal_Cascaded_tb.Fang_Square_Root_Reciprocal_cascaded_NR.out_0, 1, WL-1);		

		// -- mul_4
	always @ Square_root_Reciprocal_Cascaded_tb.Fang_Square_Root_Reciprocal_cascaded_NR.mul_4 
				real_mul_4 = unsigned_fixedToFloat(Square_root_Reciprocal_Cascaded_tb.Fang_Square_Root_Reciprocal_cascaded_NR.mul_4, 2, WL*2+LUT_bits*6-6);			
		// -- mul_5
	always @ Square_root_Reciprocal_Cascaded_tb.Fang_Square_Root_Reciprocal_cascaded_NR.mul_5
				real_mul_5 = unsigned_fixedToFloat(Square_root_Reciprocal_Cascaded_tb.Fang_Square_Root_Reciprocal_cascaded_NR.mul_5, 3, WL*3+LUT_bits*6-7);			
		// -- mul_5_s
	always @ Square_root_Reciprocal_Cascaded_tb.Fang_Square_Root_Reciprocal_cascaded_NR.mul_5_s
				real_mul_5_s = unsigned_fixedToFloat(Square_root_Reciprocal_Cascaded_tb.Fang_Square_Root_Reciprocal_cascaded_NR.mul_5_s, 2, WL*3+LUT_bits*6-7);			
		// -- fpThree_2
	always @ Square_root_Reciprocal_Cascaded_tb.Fang_Square_Root_Reciprocal_cascaded_NR.fpThree_2 
				real_fpThree_2 = unsigned_fixedToFloat(Square_root_Reciprocal_Cascaded_tb.Fang_Square_Root_Reciprocal_cascaded_NR.fpThree_2, 2, WL*3+LUT_bits*6-7);		
		// -- sub_2
	always @ Square_root_Reciprocal_Cascaded_tb.Fang_Square_Root_Reciprocal_cascaded_NR.sub_2
				real_sub_2 = unsigned_fixedToFloat(Square_root_Reciprocal_Cascaded_tb.Fang_Square_Root_Reciprocal_cascaded_NR.sub_2, 2, WL*3+LUT_bits*6-7);		
		// -- mul_6
	always @ Square_root_Reciprocal_Cascaded_tb.Fang_Square_Root_Reciprocal_cascaded_NR.mul_6
				real_mul_6 = unsigned_fixedToFloat(Square_root_Reciprocal_Cascaded_tb.Fang_Square_Root_Reciprocal_cascaded_NR.mul_6, 3, WL*4+LUT_bits*9-10);			
		// -- mul_6_s
	always @ Square_root_Reciprocal_Cascaded_tb.Fang_Square_Root_Reciprocal_cascaded_NR.mul_6_s
				real_mul_6_s = unsigned_fixedToFloat(Square_root_Reciprocal_Cascaded_tb.Fang_Square_Root_Reciprocal_cascaded_NR.mul_6_s, 1, WL*4+LUT_bits*9-9);			
		// -- out_1
	always @ Square_root_Reciprocal_Cascaded_tb.Fang_Square_Root_Reciprocal_cascaded_NR.out_1 
				real_out_1 = unsigned_fixedToFloat(Square_root_Reciprocal_Cascaded_tb.Fang_Square_Root_Reciprocal_cascaded_NR.out_1, 1, WL-1);		

	// -- output -- //	
	always @ dout real_Xilinx_result = unsigned_fixedToFloat(dout, 1, WL-1);
	always @ Simu_Result_Matlab[count] real_MATLAB_reuslt = unsigned_fixedToFloat(Simu_Result_Matlab[count], 1, WL-1);
	 
endmodule
