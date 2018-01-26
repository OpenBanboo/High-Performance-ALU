`timescale 1ns / 1ps
`define Testdata_Depth 841		// Sample 80 inputs from exhaustive simulation
////////////////////////////////////////////////////////////////////////////////
// Company: 		VLSI Design and Test Laboratory (E-218) - SDSU
// Engineer:		Fang Lin
//
// Create Date:   	20:50:01 08/01/2014
// Design Name:   	Reciprocal_NR_multicycle
// Module Name:   	D:/Synchronous/Graduate Studies/Thesis/Summer2014/RecSqr4/RecSqr3/SourceCodes/Reciprocal/Reciprocal_multiplexer_tb.v
// Project Name:  	RecSqr3
// Target Device: 	Xilinx family 
// Tool versions: 	ISE 14.6
// Description: 
//
// Verilog Test Fixture created by ISE for module: Reciprocal_NR_multicycle
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

//`define declare_Reciprocal_GS_multicycle_tb 		//This module is using the GS algorithm with multicycle iteration
//`define declare_Reciprocal_Jeong_multicycle_tb 	//This module is using the Jeong algorithm with multicycle iteration
`define declare_Reciprocal_NR_multicycle_tb 		//This module is using the NR algorithm with multicycle iteration


`ifdef declare_Reciprocal_GS_multicycle_tb 	//This module is using the Jeong algorithm with multicycle iteration
module Reciprocal_GS_multicycle_tb;

	// parameters for 0 iteration
	parameter WL = 24;			 // Word length of the inputs
	parameter LUT_bits = 15;	 // word length of the Look-up table
	parameter LUT_addWidth = 12;  // address length of the Look-up table
	parameter dWL = 27;
	parameter ITERATION = 0;

/*
	// parameters for 1 iteration
	parameter WL = 24;			 // Word length of the inputs
	parameter LUT_bits = 13;	 // word length of the Look-up table
	parameter LUT_addWidth = 6;  // address length of the Look-up table
	parameter dWL = 27;
	parameter ITERATION = 1;
*/
		// Inputs
	reg CLK;				//  clock
	reg nRST;				//	negative reset
	reg CE;					//  clock enable
	reg [WL-1:0] din;		//  input

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
	Reciprocal_GS_multicycle
	#(
		.WL(WL),								// Total word length of input
		.LUT_bits(LUT_bits),					// Look-up table bits
		.LUT_addWidth(LUT_addWidth),  			// World length of the Look-up table
		.dWL(dWL),								// Signal symbols whether to use Iterating
		.ITERATION(ITERATION)
	)
	Fang_Reciprocal_GS_multicycle (
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
		$readmemb("ini_input_binary_rec_GS_iter0.txt", Testdata_vec_NR);		
	
		// initialize the Look-up Table
		$readmemb("LUT_rec_GS_iter0.txt", Reciprocal_GS_multicycle_tb.Fang_Reciprocal_GS_multicycle.LUT);
		$readmemb("result_binary_rec_GS_iter0.txt", Simu_Result_Matlab);

		nRST = 0; CE = 0; 						// reset
		@(posedge CLK); CE = 1; 
		nRST = 1;  	// start
		
		if(ITERATION==0) begin
			for (count = 0; count <= `Testdata_Depth; count = count+1) begin		
				din = Testdata_vec_NR[count];
				$display("MATLAB: %f, Xilinx: %f", unsigned_fixedToFloat(Simu_Result_Matlab[count-2], 1, WL-1), unsigned_fixedToFloat(dout, 1, WL-1));
				if (unsigned_fixedToFloat(Simu_Result_Matlab[count-2], 1, WL-1)==unsigned_fixedToFloat(dout, 1, WL-1))

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
		end else if (ITERATION == 1) begin
			for (count = 0; count <= `Testdata_Depth; count = count+1) begin		
				din = Testdata_vec_NR[count];
				@(posedge CLK);
				$display("MATLAB: %f, Xilinx: %f", unsigned_fixedToFloat(Simu_Result_Matlab[count-1], 1, WL-1), unsigned_fixedToFloat(dout, 1, WL-1));
				if (unsigned_fixedToFloat(Simu_Result_Matlab[count-1], 1, WL-1)==unsigned_fixedToFloat(dout, 1, WL-1))

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

// --------------------------------- Test bench for Reciprocal of Jeong with multicycle iteration ------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
`ifdef declare_Reciprocal_Jeong_multicycle_tb 	//This module is using the Jeong algorithm with multicycle iteration
module Reciprocal_Jeong_multicycle_tb;
    // parameters for 0 iteration

	parameter WL = 24;			   // Word length of the inputs
	parameter LUT_bits = 14;	   // word length of the Look-up table
	parameter LUT_addWidth = 6;    // address length of the Look-up table
	parameter dWL = 26;
	parameter ITERATION = 0;

	// Inputs
	reg CLK;
	reg nRST;				// negative reset
	reg CE;
	reg [WL-1:0] din;		// input

	// Outputs
	wire [WL-1:0] dout;
	
	// Memory 
	// used to store the testcases
	reg [WL-1:0] Testdata_vec_NR [`Testdata_Depth-1:0];
	// Matlab simulation result vector
	reg [WL-1:0] Simu_Result_Matlab [`Testdata_Depth-1:0];
	
	// Real number presentation
	real real_din, real_MATLAB_reuslt, real_Xilinx_result, real_ini, real_ini2;
//	real real_mul1_net, real_mul2_net,real_iniValue, real_tmp_result_1, real_tmp_result_2;
	real real_mul_1_r, real_dout;	

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
	Reciprocal_Jeong_multicycle 
	#(
		.WL(WL),								   // Total word length of input
		.LUT_bits(LUT_bits),					// Look-up table bits
		.LUT_addWidth(LUT_addWidth),  	// World length of the Look-up table
		.dWL(dWL),								// Signal symbols whether to use Iterating
		.ITERATION(ITERATION)
    )
	Fang_Reciprocal_Jeong_multicycle 
	(
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
		$readmemb("ini_input_binary_rec_Jeong_2.txt", Testdata_vec_NR);		
	
		// initialize the Look-up Table
		$readmemb("LUT_rec_Jeong_2.txt", Reciprocal_Jeong_multicycle_tb.Fang_Reciprocal_Jeong_multicycle.LUT);
		$readmemb("result_rec_Jeong_2.txt", Simu_Result_Matlab);

		nRST = 0; CE = 0; 						// reset
		@(posedge CLK); CE = 1; 
		nRST = 1;  	// start
		
		if(ITERATION==0) begin
			for (count = 0; count <= `Testdata_Depth; count = count+1) begin		
				din = Testdata_vec_NR[count];
				$display("MATLAB: %f, Xilinx: %f", unsigned_fixedToFloat(Simu_Result_Matlab[count-1], 1, WL-1), unsigned_fixedToFloat(dout, 1, WL-1));
				if (unsigned_fixedToFloat(Simu_Result_Matlab[count-1], 1, WL-1)==unsigned_fixedToFloat(dout, 1, WL-1))

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
		end else if (ITERATION == 1) begin
			for (count = 0; count <= `Testdata_Depth; count = count+1) begin		
				din = Testdata_vec_NR[count];
				@(posedge CLK);
				$display("MATLAB: %f, Xilinx: %f", unsigned_fixedToFloat(Simu_Result_Matlab[count-1], 1, WL-1), unsigned_fixedToFloat(dout, 1, WL-1));
				if (unsigned_fixedToFloat(Simu_Result_Matlab[count-1], 1, WL-1)==unsigned_fixedToFloat(dout, 1, WL-1))

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
	
endmodule
`endif





`ifdef declare_Reciprocal_NR_multicycle_tb
module Reciprocal_NR_multicycle_tb;

	// parameters for 0 iteration


	parameter WL = 24;			   // Word length of the inputs
	parameter LUT_bits = 15;	   // word length of the Look-up table
	parameter LUT_addWidth = 12;  // address length of the Look-up table
	parameter dWL = 26;
	parameter ITERATION = 0;


/*
	// parameter for 1 iteration
	parameter WL = 24;			   // Word length of the inputs
	parameter LUT_bits = 10;	   // word length of the Look-up table
	parameter LUT_addWidth = 6;  // address length of the Look-up table
	parameter dWL = 26;
	parameter ITERATION = 1;
*/

	// Inputs
	reg CLK;
	reg nRST;				// negative reset
	reg CE;
	reg [WL-1:0] din;		// input

	// Outputs
	wire [WL-1:0] dout;
	
	// Memory 
	// used to store the testcases
	reg [WL-1:0] Testdata_vec_NR [`Testdata_Depth-1:0];
	// Matlab simulation result vector
	reg [WL-1:0] Simu_Result_Matlab [`Testdata_Depth-1:0];
	
	// Real number presentation
	real real_din, real_MATLAB_reuslt, real_Xilinx_result, real_ini, real_ini2;
	real real_mul1_net, real_mul2_net,real_iniValue, real_tmp_result_1, real_tmp_result_2;
	real real_mul_1_r, real_dout;

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
	Reciprocal_NR_multicycle 
	#(
		.WL(WL),								   // Total word length of input
		.LUT_bits(LUT_bits),					// Look-up table bits
		.LUT_addWidth(LUT_addWidth),  	// World length of the Look-up table
		.dWL(dWL),								// Signal symbols whether to use Iterating
		.ITERATION(ITERATION)
    )
	Fang_Reciprocal_NR_multicycle 
	(
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
		// once iteration
		// initialize the input vector
		$readmemb("ini_input_binary_rec_NR_720.txt", Testdata_vec_NR);		
	
		// initialize the Look-up Table
		$readmemb("LUT_rec_NR_iter1_720.txt", Reciprocal_NR_multicycle_tb.Fang_Reciprocal_NR_multicycle.LUT);
		$readmemb("result_rec_NR_720.txt", Simu_Result_Matlab);
*/	
	
	 	// Without iteration
		// initialize the input vector
		$readmemb("ini_input_binary_rec_NR_iter0.txt", Testdata_vec_NR);		
	
		// initialize the Look-up Table
		$readmemb("LUT_rec_NR_iter0.txt", Reciprocal_NR_multicycle_tb.Fang_Reciprocal_NR_multicycle.LUT);
		$readmemb("result_rec_NR_iter0.txt", Simu_Result_Matlab);
	
	 
	
		nRST = 0; CE = 0; 						// reset
		@(posedge CLK); CE = 1; 
		nRST = 1;  	// start
		
		if(ITERATION==0) begin
			for (count = 0; count <= `Testdata_Depth; count = count+1) begin		
				din = Testdata_vec_NR[count];
				$display("MATLAB: %f, Xilinx: %f", unsigned_fixedToFloat(Simu_Result_Matlab[count-2], 1, WL-1), unsigned_fixedToFloat(dout, 1, WL-1));
	//			if (unsigned_fixedToFloat(Simu_Result_Matlab[count-2], 1, WL-1)==unsigned_fixedToFloat(dout, 1, WL-1))
				if (unsigned_fixedToFloat(Simu_Result_Matlab[count-2], 1, WL-1) - unsigned_fixedToFloat(dout, 1, WL-1) <= 2^-23)
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
		end else if (ITERATION == 1) begin
			for (count = 0; count <= `Testdata_Depth; count = count+1) begin		
				din = Testdata_vec_NR[count];
				@(posedge CLK);
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
	end

//===================================  Real Pesentation  ============================================// 
	// -- input -- //
	always @ din real_din = unsigned_fixedToFloat(din, 1, WL-1);

		// -- ini
	always @ Reciprocal_NR_multicycle_tb.Fang_Reciprocal_NR_multicycle.ini 
				real_ini = unsigned_fixedToFloat(Reciprocal_NR_multicycle_tb.Fang_Reciprocal_NR_multicycle.ini, 1, LUT_bits-1);		
		// -- ini2
	always @ Reciprocal_NR_multicycle_tb.Fang_Reciprocal_NR_multicycle.ini2 
				real_ini2 = unsigned_fixedToFloat(Reciprocal_NR_multicycle_tb.Fang_Reciprocal_NR_multicycle.mul1_net, 1, WL-1);	
		// -- mul1_net
	always @ Reciprocal_NR_multicycle_tb.Fang_Reciprocal_NR_multicycle.mul1_net 
				real_mul1_net = unsigned_fixedToFloat(Reciprocal_NR_multicycle_tb.Fang_Reciprocal_NR_multicycle.mul1_net, 1, dWL-1);		
		// -- mul2_net
	always @ Reciprocal_NR_multicycle_tb.Fang_Reciprocal_NR_multicycle.mul2_net 
				real_mul1_net = unsigned_fixedToFloat(Reciprocal_NR_multicycle_tb.Fang_Reciprocal_NR_multicycle.mul2_net, 1, dWL*2-1);
		// -- mul_1_r
	always @ Reciprocal_NR_multicycle_tb.Fang_Reciprocal_NR_multicycle.mul_1_r 
				real_mul_1_r = unsigned_fixedToFloat(Reciprocal_NR_multicycle_tb.Fang_Reciprocal_NR_multicycle.mul_1_r, 1, dWL-1);
		// -- iniValue
	always @ Reciprocal_NR_multicycle_tb.Fang_Reciprocal_NR_multicycle.iniValue 
				real_iniValue = unsigned_fixedToFloat(Reciprocal_NR_multicycle_tb.Fang_Reciprocal_NR_multicycle.iniValue, 1, WL-1);	
		// -- tmp_result_1
	always @ Reciprocal_NR_multicycle_tb.Fang_Reciprocal_NR_multicycle.tmp_result_1 
				real_tmp_result_1 = unsigned_fixedToFloat(Reciprocal_NR_multicycle_tb.Fang_Reciprocal_NR_multicycle.tmp_result_1, 1, WL-1);
		// -- tmp_result_2
	always @ Reciprocal_NR_multicycle_tb.Fang_Reciprocal_NR_multicycle.tmp_result_2 
				real_tmp_result_2 = unsigned_fixedToFloat(Reciprocal_NR_multicycle_tb.Fang_Reciprocal_NR_multicycle.tmp_result_2, 1, WL-1);				

	// -- output -- //	
	always @ dout real_Xilinx_result = unsigned_fixedToFloat(dout, 1, WL-1);
	always @ Simu_Result_Matlab[count] real_MATLAB_reuslt = unsigned_fixedToFloat(Simu_Result_Matlab[count], 1, WL-1);
      
endmodule
`endif
