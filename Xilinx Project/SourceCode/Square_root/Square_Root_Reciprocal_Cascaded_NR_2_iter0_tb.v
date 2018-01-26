`timescale 1ns / 1ps
`define Testdata_Depth 841		// Sample 80 inputs from exhaustive simulation
////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   12:18:55 08/02/2014
// Design Name:   Square_Root_Reciprocal_Cascaded_NR_2
// Module Name:   D:/Synchronous/Graduate Studies/Thesis/Summer2014/RecSqr4/RecSqr3/SourceCodes/Square_root/Square_Root_Reciprocal_Cascaded_NR_2_iter0_tb.v
// Project Name:  RecSqr3
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: Square_Root_Reciprocal_Cascaded_NR_2
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module Square_Root_Reciprocal_Cascaded_NR_2_iter0_tb;

	// parameters
	parameter WL = 24;			 // Word length of the inputs
	parameter LUT_bits = 15;	 // word length of the Look-up table
	parameter LUT_addWidth = 11;  // address length of the Look-up table
	parameter dWL = 24;

	// Inputs
	reg CLK;
	reg nRST;
	reg CE;
	reg [WL-1:0] din;		// input

	// Outputs
	wire [WL-1:0] dout;	// output
	wire [WL-1:0] dout_pipe;
	// Memory 
	// used to store the testcases
	reg [WL-1:0] Testdata_vec_NR [`Testdata_Depth-1:0];
	// Matlab simulation result vector
	reg [WL-1:0] Simu_Result_Matlab [`Testdata_Depth-1:0];
	
	// Real number presentation
	real real_din, real_MATLAB_reuslt, real_Xilinx_result;
	real real_mul1_net, real_mul2_net, real_mul3_net, real_iniValue;
	real real_tmp_result_1, real_sub_1, real_dout;
	
//=====================================  clock generator  ==========================================//
	parameter ClockPeriod = 2;	// Clock period
	initial 	 CLK = 0;
	always # (ClockPeriod/2) CLK = ~CLK;
//==================================================================================================//

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
	Reciprocal_Square_root_pipelined_NR
	#(
		.WL(WL),								// Total word length of input
		.LUT_bits(LUT_bits),					// Look-up table bits
		.LUT_addWidth(LUT_addWidth),  			// World length of the Look-up table
		.dWL(dWL)								// Signal symbols whether to use Iterating
	  )
	Fang_Square_Root_Reciprocal_pipe (
		.CLK(CLK), 
		.nRST(nRST), 
		.CE(CE), 
		.din(din), 
		.dout(dout_pipe)
	);


	// Instantiate the Unit Under Test (UUT)
	Square_Root_Reciprocal_Cascaded_NR_2
	#(
		.WL(WL),								// Total word length of input
		.LUT_bits(LUT_bits),					// Look-up table bits
		.LUT_addWidth(LUT_addWidth),  			// World length of the Look-up table
		.dWL(dWL)								// Signal symbols whether to use Iterating
	  )
	Fang_Square_Root_Reciprocal_Iter0 (
		.CLK(CLK), 
		.nRST(nRST), 
		.CE(CE), 
		.din(din), 
		.dout(dout)
	);


//===========================================  Inpulse =============================================//
	integer count;		// counter used for looping below
	real count_mismatched = 0; // counter to store the mismatched result number
	initial begin
	
		// initialize the input vector
		$readmemb("ini_input_binary_isqt_NR_iter0.txt", Testdata_vec_NR);		
	
		// initialize the Look-up Table
		$readmemb("LUT_isqt_NR_iter0.txt", Square_Root_Reciprocal_Cascaded_NR_2_iter0_tb.Fang_Square_Root_Reciprocal_Iter0.LUT);
		$readmemb("LUT_isqt_NR_iter0.txt", Square_Root_Reciprocal_Cascaded_NR_2_iter0_tb.Fang_Square_Root_Reciprocal_pipe.LUT);

		$readmemb("result_isqt_NR_iter0.txt", Simu_Result_Matlab);

		nRST = 0; CE = 0; 						// reset
		@(posedge CLK); CE = 1; 
		nRST = 1;  	// start
		
		for (count = 0; count <= `Testdata_Depth; count = count+1) begin		
			din = Testdata_vec_NR[count];
		   $display("MATLAB: %f, Xilinx: %f", unsigned_fixedToFloat(Simu_Result_Matlab[count-1], 1, WL-1), unsigned_fixedToFloat(dout, 1, WL-1));
			if (unsigned_fixedToFloat(Simu_Result_Matlab[count-1], 1, WL-1)-unsigned_fixedToFloat(dout, 1, WL-1)<=2^-23)
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

		// -- mul1_net
	always @ Square_Root_Reciprocal_Cascaded_NR_2_iter0_tb.Fang_Square_Root_Reciprocal_Iter0.mul1_net 
				real_mul1_net = unsigned_fixedToFloat(Square_Root_Reciprocal_Cascaded_NR_2_iter0_tb.Fang_Square_Root_Reciprocal_Iter0.mul1_net, 2, dWL-2);		
		// -- mul2_net
	always @ Square_Root_Reciprocal_Cascaded_NR_2_iter0_tb.Fang_Square_Root_Reciprocal_Iter0.mul2_net 
				real_mul2_net = unsigned_fixedToFloat(Square_Root_Reciprocal_Cascaded_NR_2_iter0_tb.Fang_Square_Root_Reciprocal_Iter0.mul2_net, 2, dWL-2);
		// -- mul3_net
	always @ Square_Root_Reciprocal_Cascaded_NR_2_iter0_tb.Fang_Square_Root_Reciprocal_Iter0.mul3_net 
				real_mul3_net = unsigned_fixedToFloat(Square_Root_Reciprocal_Cascaded_NR_2_iter0_tb.Fang_Square_Root_Reciprocal_Iter0.mul3_net, 2, dWL+LUT_bits-2);
		// -- sub_1
	always @ Square_Root_Reciprocal_Cascaded_NR_2_iter0_tb.Fang_Square_Root_Reciprocal_Iter0.sub_1 
				real_sub_1 = unsigned_fixedToFloat(Square_Root_Reciprocal_Cascaded_NR_2_iter0_tb.Fang_Square_Root_Reciprocal_Iter0.sub_1, 2, dWL-2);
		// -- iniValue
	always @ Square_Root_Reciprocal_Cascaded_NR_2_iter0_tb.Fang_Square_Root_Reciprocal_Iter0.iniValue 
				real_iniValue = unsigned_fixedToFloat(Square_Root_Reciprocal_Cascaded_NR_2_iter0_tb.Fang_Square_Root_Reciprocal_Iter0.iniValue, 1, LUT_bits-1);		
		// -- tmp_result_1
//	always @ Square_Root_Reciprocal_Cascaded_NR_2_iter0_tb.Fang_Square_Root_Reciprocal_Iter0.tmp_result_1 
//				real_tmp_result_1 = unsigned_fixedToFloat(Square_Root_Reciprocal_Cascaded_NR_2_iter0_tb.Fang_Square_Root_Reciprocal_Iter0.tmp_result_1, 1, WL-1);


	// -- output -- //	
	always @ dout real_Xilinx_result = unsigned_fixedToFloat(dout, 1, WL-1);
	always @ Simu_Result_Matlab[count] real_MATLAB_reuslt = unsigned_fixedToFloat(Simu_Result_Matlab[count], 1, WL-1);

//===================================  Real Pesentation  ============================================// 
      
endmodule

