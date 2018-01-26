`timescale 1ns / 1ps
`define Testdata_Depth 814// Sample 841 inputs from exhaustive simulation
////////////////////////////////////////////////////////////////////////////////
// Company: 		VLSI Design and Test Laboratory (E-218) - SDSU
// Engineer:		Fang Lin
//
// Create Date:   	14:45:47 05/26/2014
// Design Name:   	Sqaure_Root_Reciprocal_multicycle
// Module Name:   	D:/Synchronous/Graduate Studies/Thesis/Summer2014/RecSqr/Reciprocal_Cascaded.v
// Project Name:  	RecSqr
// Target Device: 	Xilinx family 
// Tool versions: 	ISE 14.6
// Description: 
//
// Verilog Test Fixture created by ISE for module: 
//					1. Square_Root_Reciprocal_NR_multicycle
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

`define declare_Square_Root_Reciprocal_NR_multicycle_tb 		//This module is using the NR algorithm with multicycle iteration
//`define declare_Square_Root_Reciprocal_GS_multicycle_tb 		//This module is using the NR algorithm with multicycle iteration

`ifdef declare_Square_Root_Reciprocal_GS_multicycle_tb
module Square_Root_Reciprocal_GS_multicycle_tb;


	// parameters for zero iteration
	parameter WL = 24;			 // Word length of the inputs
	parameter LUT_bits = 15;	 // word length of the Look-up table
	parameter LUT_addWidth = 12;  // address length of the Look-up table
	parameter dWL = 26;
	parameter ITERATION = 0;


/*	
	// parameters for once iteration
	parameter WL = 24;			 // Word length of the inputs
	parameter LUT_bits = 11;	 // word length of the Look-up table
	parameter LUT_addWidth = 6;  // address length of the Look-up table
	parameter dWL = 26;
	parameter ITERATION = 1;
*/

		// Inputs
	reg CLK;
	reg nRST;
	reg CE;
	reg [WL-1:0] din;		// input

	// Outputs
	wire [WL-1:0] dout;	// output

	// Memory 
	// used to store the testcases
	reg [WL-1:0] Testdata_vec_NR [`Testdata_Depth-1:0];
	// Matlab simulation result vector
	reg [WL-1:0] Simu_Result_Matlab [`Testdata_Depth-1:0];
	
	// Real number presentation
	real real_din, real_MATLAB_reuslt, real_Xilinx_result;
	real real_dout;

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
	Square_Root_Reciprocal_GS_multicycle
	#(
		.WL(WL),								// Total word length of input
		.LUT_bits(LUT_bits),					// Look-up table bits
		.LUT_addWidth(LUT_addWidth),  			// World length of the Look-up table
		.ITERATION(ITERATION),
		.dWL(dWL)								// Signal symbols whether to use Iterating
	  )
	Fang_Square_Root_Reciprocal_GS_multicycle (
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

// once iteration	
/*
		// initialize the input vector
		$readmemb("ini_input_binary_isqt_GS_iter1.txt", Testdata_vec_NR);		
	
		// initialize the Look-up Table
		$readmemb("LUT_isqt_GS_iter1.txt", Square_Root_Reciprocal_GS_multicycle_tb.Fang_Square_Root_Reciprocal_GS_multicycle.LUT);
		$readmemb("result_binary_isqt_GS_iter1.txt", Simu_Result_Matlab);
*/

//	zero iteration

		// initialize the input vector
		$readmemb("ini_input_binary_isqt_GS_iter0.txt", Testdata_vec_NR);		
	
		// initialize the Look-up Table
		$readmemb("LUT_isqt_GS_iter0.txt", Square_Root_Reciprocal_GS_multicycle_tb.Fang_Square_Root_Reciprocal_GS_multicycle.LUT);
		$readmemb("result_binary_isqt_GS_iter0.txt", Simu_Result_Matlab);



		nRST = 0; CE = 0; 						// reset
		@(posedge CLK); CE = 1; 
		nRST = 1;  	// start
		
		if(ITERATION==0) begin
			for (count = 0; count <= `Testdata_Depth; count = count+1) begin		
				din = Testdata_vec_NR[count];
				$display("MATLAB: %f, Xilinx: %f", unsigned_fixedToFloat(Simu_Result_Matlab[count-2], 1, WL-1), unsigned_fixedToFloat(dout, 1, WL-1));
				if (unsigned_fixedToFloat(Simu_Result_Matlab[count-2], 1, WL-1)-unsigned_fixedToFloat(dout, 1, WL-1)<=2^-23)

					$display("MATCHED");
				else begin
					count_mismatched = count_mismatched + 1;
					$display("MISMATCHED HERE <================= !!! ");
					$display("The NO.%d result is not matched, MATLAB: %b, Xilinx: %b ", count, Simu_Result_Matlab[count-2], dout);
				end
				@(posedge CLK);
				if (count==`Testdata_Depth) begin
					$display("Mismatched proporbility: %f", count_mismatched/`Testdata_Depth);
					$finish;
				end
			end
		end else if (ITERATION == 1) begin
			for (count = 0; count <= `Testdata_Depth; count = count+1) begin		
				din = Testdata_vec_NR[count];
				@(posedge CLK);
				$display("MATLAB: %f, Xilinx: %f", unsigned_fixedToFloat(Simu_Result_Matlab[count-1], 1, WL-1), unsigned_fixedToFloat(dout, 1, WL-1));
				if (unsigned_fixedToFloat(Simu_Result_Matlab[count-1], 1, WL-1)-unsigned_fixedToFloat(dout, 1, WL-1)<=2^-23)

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
	always @ din real_din = unsigned_fixedToFloat(din, 1, WL-1);
	// -- output -- //	
	always @ dout real_Xilinx_result = unsigned_fixedToFloat(dout, 1, WL-1);
	always @ Simu_Result_Matlab[count] real_MATLAB_reuslt = unsigned_fixedToFloat(Simu_Result_Matlab[count], 1, WL-1);
	
endmodule
`endif


// testbench of the Square root reciprocal calculation of NR method

`ifdef declare_Square_Root_Reciprocal_NR_multicycle_tb
module Square_Root_Reciprocal_NR_multicycle_tb;


	// parameters for zero iteration
	parameter WL = 24;			 // Word length of the inputs
	parameter LUT_bits = 15;	 // word length of the Look-up table
	parameter LUT_addWidth = 11;  // address length of the Look-up table
	parameter dWL = 29;
	parameter ITERATION = 0;


/*	
	// parameters for once iteration
	parameter WL = 24;			 // Word length of the inputs
	parameter LUT_bits = 11;	 // word length of the Look-up table
	parameter LUT_addWidth = 6;  // address length of the Look-up table
	parameter dWL = 26;
	parameter ITERATION = 1;	
*/
	
		// Inputs
	reg CLK;
	reg nRST;
	reg CE;
	reg [WL-1:0] din;		// input

	// Outputs
	wire [WL-1:0] dout;	// output

	// Memory 
	// used to store the testcases
	reg [WL-1:0] Testdata_vec_NR [`Testdata_Depth-1:0];
	// Matlab simulation result vector
	reg [WL-1:0] Simu_Result_Matlab [`Testdata_Depth-1:0];
	
	// Real number presentation
	real real_din, real_MATLAB_reuslt, real_Xilinx_result;
	real real_mul1_net, real_mul2_net, real_mul3_net, real_iniValue;
	real real_tmp_result_1, real_tmp_result_2, real_sub_1, real_dout;
	
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
	Square_Root_Reciprocal_NR_multicycle
	#(
		.WL(WL),								// Total word length of input
		.LUT_bits(LUT_bits),					// Look-up table bits
		.LUT_addWidth(LUT_addWidth),  			// World length of the Look-up table
		.ITERATION(ITERATION),
		.dWL(dWL)								// Signal symbols whether to use Iterating
	  )
	Fang_Square_Root_Reciprocal_NR_multicycle (
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

/*	
		// initialize the input vector
		$readmemb("ini_input_binary_isqt_NR_iter1.txt", Testdata_vec_NR);		
	
		// initialize the Look-up Table
		$readmemb("LUT_isqt_NR_iter1.txt", Square_Root_Reciprocal_NR_multicycle_tb.Fang_Square_Root_Reciprocal_NR_multicycle.LUT);
		$readmemb("result_isqt_NR_iter1.txt", Simu_Result_Matlab);
*/
		// initialize the input vector
		$readmemb("ini_input_binary_isqt_NR_iter0.txt", Testdata_vec_NR);		
	
		// initialize the Look-up Table
		$readmemb("LUT_isqt_NR_iter0.txt", Square_Root_Reciprocal_NR_multicycle_tb.Fang_Square_Root_Reciprocal_NR_multicycle.LUT);
		$readmemb("result_isqt_NR_iter0.txt", Simu_Result_Matlab);

		nRST = 0; CE = 0; 						// reset
		@(posedge CLK); CE = 1; 
		nRST = 1;  	// start
		
		if(ITERATION==0) begin
			for (count = 0; count <= `Testdata_Depth; count = count+1) begin		
				din = Testdata_vec_NR[count];
				$display("MATLAB: %f, Xilinx: %f", unsigned_fixedToFloat(Simu_Result_Matlab[count-2], 1, WL-1), unsigned_fixedToFloat(dout, 1, WL-1));
				if (unsigned_fixedToFloat(Simu_Result_Matlab[count-2], 1, WL-1)-unsigned_fixedToFloat(dout, 1, WL-1)<=2^-23)
					$display("MATCHED");
				else begin
					count_mismatched = count_mismatched + 1;
					$display("MISMATCHED HERE <================= !!! ");
					$display("The NO.%d result is not matched, MATLAB: %b, Xilinx: %b ", count, Simu_Result_Matlab[count], dout);
				end
				@(posedge CLK);
				if (count==`Testdata_Depth) begin
					$display("Mismatched proporbility: %f", count_mismatched/`Testdata_Depth);
					$finish;
				end
			end
		end else if (ITERATION == 1) begin
			for (count = 0; count <= `Testdata_Depth; count = count+1) begin		
				din = Testdata_vec_NR[count];
				@(posedge CLK);
				$display("MATLAB: %f, Xilinx: %f", unsigned_fixedToFloat(Simu_Result_Matlab[count-1], 1, WL-1), unsigned_fixedToFloat(dout, 1, WL-1));
				if (unsigned_fixedToFloat(Simu_Result_Matlab[count-1], 1, WL-1)-unsigned_fixedToFloat(dout, 1, WL-1)<=2^-23)

					$display("MATCHED");
				else begin
					count_mismatched = count_mismatched + 1;
//					$display("MISMATCHED HERE <================= !!! ");
//					$display("The NO.%d result is not matched, MATLAB: %b, Xilinx: %b ", count, Simu_Result_Matlab[count-1], dout);
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
	always @ din real_din = unsigned_fixedToFloat(din, 1, WL-1);
	
		// -- mul1_net
	always @ Square_Root_Reciprocal_NR_multicycle_tb.Fang_Square_Root_Reciprocal_NR_multicycle.mul1_net 
				real_mul1_net = unsigned_fixedToFloat(Square_Root_Reciprocal_NR_multicycle_tb.Fang_Square_Root_Reciprocal_NR_multicycle.mul1_net, 2, dWL-2);		
		// -- mul2_net
	always @ Square_Root_Reciprocal_NR_multicycle_tb.Fang_Square_Root_Reciprocal_NR_multicycle.mul2_net 
				real_mul2_net = unsigned_fixedToFloat(Square_Root_Reciprocal_NR_multicycle_tb.Fang_Square_Root_Reciprocal_NR_multicycle.mul2_net, 2, dWL-2);
		// -- mul3_net
	always @ Square_Root_Reciprocal_NR_multicycle_tb.Fang_Square_Root_Reciprocal_NR_multicycle.mul3_net 
				real_mul3_net = unsigned_fixedToFloat(Square_Root_Reciprocal_NR_multicycle_tb.Fang_Square_Root_Reciprocal_NR_multicycle.mul3_net, 2, dWL+LUT_bits-2);
		// -- sub_1
	always @ Square_Root_Reciprocal_NR_multicycle_tb.Fang_Square_Root_Reciprocal_NR_multicycle.sub_1 
				real_sub_1 = unsigned_fixedToFloat(Square_Root_Reciprocal_NR_multicycle_tb.Fang_Square_Root_Reciprocal_NR_multicycle.sub_1, 2, dWL-2);
		// -- iniValue
	always @ Square_Root_Reciprocal_NR_multicycle_tb.Fang_Square_Root_Reciprocal_NR_multicycle.iniValue 
				real_iniValue = unsigned_fixedToFloat(Square_Root_Reciprocal_NR_multicycle_tb.Fang_Square_Root_Reciprocal_NR_multicycle.iniValue, 1, WL-1);		
		// -- tmp_result_1
	always @ Square_Root_Reciprocal_NR_multicycle_tb.Fang_Square_Root_Reciprocal_NR_multicycle.tmp_result_1 
				real_tmp_result_1 = unsigned_fixedToFloat(Square_Root_Reciprocal_NR_multicycle_tb.Fang_Square_Root_Reciprocal_NR_multicycle.tmp_result_1, 1, WL-1);
		// -- tmp_result_2
	always @ Square_Root_Reciprocal_NR_multicycle_tb.Fang_Square_Root_Reciprocal_NR_multicycle.tmp_result_2 
				real_tmp_result_2 = unsigned_fixedToFloat(Square_Root_Reciprocal_NR_multicycle_tb.Fang_Square_Root_Reciprocal_NR_multicycle.tmp_result_2, 1, WL-1);
	
	
	// -- output -- //	
	always @ dout real_Xilinx_result = unsigned_fixedToFloat(dout, 1, WL-1);
	always @ Simu_Result_Matlab[count] real_MATLAB_reuslt = unsigned_fixedToFloat(Simu_Result_Matlab[count], 1, WL-1);
      
endmodule
`endif