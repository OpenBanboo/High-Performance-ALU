`timescale 1ns / 1ps
`define Testdata_Depth 841		// Sample 80 inputs from exhaustive simulation
////////////////////////////////////////////////////////////////////////////////
// Company: 		VLSI Design and Test Laboratory (E-218) - SDSU
// Engineer:		Fang Lin
//
// Create Date:   	14:45:47 05/26/2014
// Design Name:   	Reciprocal_Cascaded_NR
// Module Name:   	D:/Synchronous/Graduate Studies/Thesis/Summer2014/RecSqr/Reciprocal_Cascaded.v
// Project Name:  	RecSqr
// Target Device: 	Xilinx family 
// Tool versions: 	ISE 14.6
// Description: 
//
// Verilog Test Fixture created by ISE for module: Reciprocal_Cascaded_NR
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
`define declare_Reciprocal_Cascaded_Jeong_tb
`define declare_Reciprocal_Cascaded_Hung_tb
`define declare_Reciprocal_Cascaded_NR_tb 	//This module is using the NR algorithm with 1 iteration
`define declare_Reciprocal_Cascaded_NR_2_tb 		//This module is using the NR algorithm with 0 iteration
`define declare_Reciprocal_Cascaded_ItoNR 	//This module is using the Ito_NR algorithm 
`define declare_Reciprocal_Cascaded_GS 			//This module is using the GS algorithm with 1 iteration
`define declare_Reciprocal_Cascaded_GS_2		 //This module is using the GS algorithm with 0 iteration

`ifdef declare_Reciprocal_Cascaded_GS_2
module Reciprocal_Cascaded_GS_2_tb;
	// parameters
	parameter WL = 24;			 // Word length of the inputs
	parameter LUT_bits = 15;	 // word length of the Look-up table
	parameter LUT_addWidth = 12;  // address length of the Look-up table
	parameter dWL = 27;

	// Inputs
	reg CLK;					// clock
	reg nRST;				//	negative reset
	reg CE;					// clock enable
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
	Reciprocal_Cascaded_GS_2
	#(
		.WL(WL),								// Total word length of input
		.LUT_bits(LUT_bits),					// Look-up table bits
		.LUT_addWidth(LUT_addWidth),  			// World length of the Look-up table
		.dWL(dWL)								// Signal symbols whether to use Iterating
    )
	Fang_Reciprocal_Cascaded_GS_2 (
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
		$readmemb("LUT_rec_GS_iter0.txt", Reciprocal_Cascaded_GS_2_tb.Fang_Reciprocal_Cascaded_GS_2.LUT);
		$readmemb("result_binary_rec_GS_iter0.txt", Simu_Result_Matlab);

		nRST <= 0; CE <= 0; 						// reset
		@(posedge CLK); CE <= 1; 
		nRST <= 1;  	// start
		
		for (count = 0; count <= `Testdata_Depth; count = count+1) begin		
			din <= Testdata_vec_NR[count];
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

	// -- output -- //	
	always @ dout real_Xilinx_result = unsigned_fixedToFloat(dout, 1, WL-1);
	always @ Simu_Result_Matlab[count] real_MATLAB_reuslt = unsigned_fixedToFloat(Simu_Result_Matlab[count], 1, WL-1);	
endmodule
`endif

//==================================================================================================================
// ---------------------------Testbench of Reciprocal for NR method with once iteration -------------------------- //
//==================================================================================================================
`ifdef declare_Reciprocal_Cascaded_NR_2_tb
module Reciprocal_Cascaded_NR_2_tb;

	// parameters
	parameter WL = 24;			 // Word length of the inputs
	parameter LUT_bits = 15;	 // word length of the Look-up table
	parameter LUT_addWidth = 12;  // address length of the Look-up table
	parameter dWL = 26;

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
	real real_mul1_net, real_mul2_net,real_iniValue;
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
	Reciprocal_Cascaded_NR_2
	#(
		.WL(WL),								// Total word length of input
		.LUT_bits(LUT_bits),					// Look-up table bits
		.LUT_addWidth(LUT_addWidth),  			// World length of the Look-up table
		.dWL(dWL)								// Signal symbols whether to use Iterating
    )
	Fang_Reciprocal_Cascaded_NR_2 (
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
		$readmemb("ini_input_binary_rec_NR_iter0.txt", Testdata_vec_NR);		
	
		// initialize the Look-up Table
		$readmemb("LUT_rec_NR_iter0.txt", Reciprocal_Cascaded_NR_2_tb.Fang_Reciprocal_Cascaded_NR_2.LUT);
		$readmemb("result_rec_NR_iter0.txt", Simu_Result_Matlab);

		nRST = 0; CE = 0; 						// reset
		@(posedge CLK); CE = 1; 
		nRST = 1;  	// start
		
		for (count = 0; count <= `Testdata_Depth; count = count+1) begin		
			din = Testdata_vec_NR[count];
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

//===================================  Real Pesentation  ============================================// 
	// -- input -- //
	always @ din real_din = unsigned_fixedToFloat(din, 1, WL-1);

		// -- mul1_net
	always @ Reciprocal_Cascaded_NR_2_tb.Fang_Reciprocal_Cascaded_NR_2.mul1_net 
				real_mul1_net = unsigned_fixedToFloat(Reciprocal_Cascaded_NR_2_tb.Fang_Reciprocal_Cascaded_NR_2.mul1_net, 1, dWL-1);		
		// -- mul2_net
	always @ Reciprocal_Cascaded_NR_2_tb.Fang_Reciprocal_Cascaded_NR_2.mul2_net 
				real_mul2_net = unsigned_fixedToFloat(Reciprocal_Cascaded_NR_2_tb.Fang_Reciprocal_Cascaded_NR_2.mul2_net, 1, dWL+LUT_bits-1);
		// -- mul_1_r
	always @ Reciprocal_Cascaded_NR_2_tb.Fang_Reciprocal_Cascaded_NR_2.mul_1_r 
				real_mul_1_r = unsigned_fixedToFloat(Reciprocal_Cascaded_NR_2_tb.Fang_Reciprocal_Cascaded_NR_2.mul_1_r, 1, dWL-1);
		// -- iniValue
	always @ Reciprocal_Cascaded_NR_2_tb.Fang_Reciprocal_Cascaded_NR_2.iniValue 
				real_iniValue = unsigned_fixedToFloat(Reciprocal_Cascaded_NR_2_tb.Fang_Reciprocal_Cascaded_NR_2.iniValue, 1, LUT_bits-1);		

	// -- output -- //	
	always @ Reciprocal_Cascaded_NR_2_tb.dout real_Xilinx_result = unsigned_fixedToFloat(dout, 1, WL-1);
	always @ Simu_Result_Matlab[count] real_MATLAB_reuslt = unsigned_fixedToFloat(Simu_Result_Matlab[count], 1, WL-1);

      
endmodule
`endif


//========================================================================================
// ---------------------------Testbench of Reciprocal for Jeong's method -------------------------- //
//========================================================================================
`ifdef declare_Reciprocal_Cascaded_Jeong_tb
module Reciprocal_Cascaded_Jeong_tb;

	// parameters
	parameter WL = 24;			 // Word length of the inputs
	parameter LUT_bits = 14;	 // word length of the Look-up table
	parameter LUT_addWidth = 6; // address length of the Look-up table
	parameter dWL = 26;
	
	// Inputs
	reg CLK;					// clock
	reg nRST;				// negative reset
	reg CE;					// clock enable
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
	real real_xh, real_xl, real_Sub, real_mul1_net, real_mul2_net, real_mul2_net_i ,real_iniValue, real_Mul;
	real real_temp_result, real_dout;
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
	Reciprocal_Cascaded_Jeong
	#(
		.WL(WL),								// Total word length of input
		.LUT_bits(LUT_bits),					// Look-up table bits
		.LUT_addWidth(LUT_addWidth),  			// World length of the Look-up table
		.dWL(dWL)					// Signal symbols whether to use Iterating
    )
	Fang_Reciprocal_cascaded_Jeong 
	(
		.CLK(CLK), 							// clock
		.nRST(nRST), 						// negative reset
		.CE(CE), 							// clock enable
		.din(din), 							// data input 
		.dout(dout)							// data output
	 );
//==================================================================================================//

//===========================================  Inpulse =============================================//
	integer count;		// counter used for looping below
	real count_mismatched = 0; // counter to store the mismatched result number
	initial begin
	
		// initialize the input vector
		$readmemb("ini_input_binary_rec_Jeong_2.txt", Testdata_vec_NR);		
	
		// initialize the Look-up Table
		$readmemb("LUT_rec_Jeong_2.txt", Reciprocal_Cascaded_Jeong_tb.Fang_Reciprocal_cascaded_Jeong.LUT);
		$readmemb("result_rec_Jeong_2.txt", Simu_Result_Matlab);

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
		// -- iniValue
	always @ Reciprocal_Cascaded_Jeong_tb.Fang_Reciprocal_cascaded_Jeong.iniValue
			   real_iniValue = unsigned_fixedToFloat(Reciprocal_Cascaded_Jeong_tb.Fang_Reciprocal_cascaded_Jeong.iniValue, 1, LUT_bits-1);

		// -- xh
	always @ Reciprocal_Cascaded_Jeong_tb.Fang_Reciprocal_cascaded_Jeong.xh 
			   real_xh = unsigned_fixedToFloat(Reciprocal_Cascaded_Jeong_tb.Fang_Reciprocal_cascaded_Jeong.xh, 1, WL-1);
		// -- xl
	always @ Reciprocal_Cascaded_Jeong_tb.Fang_Reciprocal_cascaded_Jeong.xl 
				real_xl = unsigned_fixedToFloat(Reciprocal_Cascaded_Jeong_tb.Fang_Reciprocal_cascaded_Jeong.xl, 1, WL-1);
		// -- Sub
	always @ Reciprocal_Cascaded_Jeong_tb.Fang_Reciprocal_cascaded_Jeong.Sub 
				real_Sub = unsigned_fixedToFloat(Reciprocal_Cascaded_Jeong_tb.Fang_Reciprocal_cascaded_Jeong.Sub, 1, WL-1);
		// -- mul1_net
	always @ Reciprocal_Cascaded_Jeong_tb.Fang_Reciprocal_cascaded_Jeong.mul1_net 
				real_mul1_net = unsigned_fixedToFloat(Reciprocal_Cascaded_Jeong_tb.Fang_Reciprocal_cascaded_Jeong.mul1_net, 1, dWL-1);		
		// -- mul2_net
	always @ Reciprocal_Cascaded_Jeong_tb.Fang_Reciprocal_cascaded_Jeong.mul2_net 
				real_mul1_net = unsigned_fixedToFloat(Reciprocal_Cascaded_Jeong_tb.Fang_Reciprocal_cascaded_Jeong.mul2_net, 1, dWL-1);
		// -- mul2_net_i
	always @ Reciprocal_Cascaded_Jeong_tb.Fang_Reciprocal_cascaded_Jeong.mul2_net_i 
				real_mul2_net_i = unsigned_fixedToFloat(Reciprocal_Cascaded_Jeong_tb.Fang_Reciprocal_cascaded_Jeong.mul2_net_i, 1, dWL-1);
		// -- Mul
	always @ Reciprocal_Cascaded_Jeong_tb.Fang_Reciprocal_cascaded_Jeong.Mul 
				real_Mul = unsigned_fixedToFloat(Reciprocal_Cascaded_Jeong_tb.Fang_Reciprocal_cascaded_Jeong.Mul, 1, dWL*2-1);		

	// -- output -- //	
	always @ dout real_Xilinx_result = unsigned_fixedToFloat(dout, 1, WL-1);
	always @ Simu_Result_Matlab[count] real_MATLAB_reuslt = unsigned_fixedToFloat(Simu_Result_Matlab[count], 1, WL-1);
	
endmodule
`endif



// =======================================================================================================================================
`ifdef declare_Reciprocal_Cascaded_Hung_tb
module Reciprocal_Cascaded_Hung_tb;

	// parameters
	parameter WL = 24;			 // Word length of the inputs
	parameter LUT_bits = 26;	 // word length of the Look-up table
	parameter LUT_addWidth = 12;  // address length of the Look-up table
	parameter ITERATION = 0;	 // Whether use iteration to approach	
	parameter WLO = 24;
	
	// Inputs
	reg CLK;					// clock
	reg nRST;				// negative reset
	reg CE;					// clock enable
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
	real real_xh, real_xl, real_Sub, real_Mul;
	real real_temp_result, real_dout;
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
	Reciprocal_Cascaded_Hung
	#(
		.WL(WL),								// Total word length of input
		.LUT_bits(LUT_bits),					// Look-up table bits
		.LUT_addWidth(LUT_addWidth),  			// World length of the Look-up table
		.ITERATION(ITERATION),					// Signal symbols whether to use Iterating
		.WLO(WLO)
    )
	Fang_Reciprocal_cascaded_Hung 
	(
		.CLK(CLK), 							// clock
		.nRST(nRST), 						// negative reset
		.CE(CE), 							// clock enable
		.din(din), 							// data input 
		.dout(dout)							// data output
	 );
//==================================================================================================//

//===========================================  Inpulse =============================================//
	integer count;		// counter used for looping below
	real count_mismatched = 0; // counter to store the mismatched result number
	initial begin
	
		// initialize the input vector
		$readmemb("ini_input_binary_rec_Hung.txt", Testdata_vec_NR);		
	
		// initialize the Look-up Table
		$readmemb("LUT_rec_Hung.txt", Reciprocal_Cascaded_Hung_tb.Fang_Reciprocal_cascaded_Hung.LUT);
		$readmemb("result_rec_Hung.txt", Simu_Result_Matlab);

		nRST = 0; CE = 0; 						// reset
		@(posedge CLK); CE = 1; 
		nRST = 1;  	// start
		
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
	end

//===================================  Real Pesentation  ============================================// 
	// -- input -- //
	always @ din real_din = unsigned_fixedToFloat(din, 1, WL-1);
	
	// -- intermediate -- //
		// -- xh
	always @ Reciprocal_Cascaded_Hung_tb.Fang_Reciprocal_cascaded_Hung.xh 
			   real_xh = unsigned_fixedToFloat(Reciprocal_Cascaded_Hung_tb.Fang_Reciprocal_cascaded_Hung.xh, 1, WL-1);
		// -- xl
	always @ Reciprocal_Cascaded_Hung_tb.Fang_Reciprocal_cascaded_Hung.xl 
				real_xl = unsigned_fixedToFloat(Reciprocal_Cascaded_Hung_tb.Fang_Reciprocal_cascaded_Hung.xl, 1, WL-1);
		// -- Sub
	always @ Reciprocal_Cascaded_Hung_tb.Fang_Reciprocal_cascaded_Hung.Sub 
				real_Sub = unsigned_fixedToFloat(Reciprocal_Cascaded_Hung_tb.Fang_Reciprocal_cascaded_Hung.Sub, 1, WL-1);
		// -- Mul
	always @ Reciprocal_Cascaded_Hung_tb.Fang_Reciprocal_cascaded_Hung.Mul 
				real_Mul = unsigned_fixedToFloat(Reciprocal_Cascaded_Hung_tb.Fang_Reciprocal_cascaded_Hung.Mul, 2, WL+LUT_bits-2);		
		// -- temp_result
	always @ Reciprocal_Cascaded_Hung_tb.Fang_Reciprocal_cascaded_Hung.temp_result 
				real_temp_result = unsigned_fixedToFloat(Reciprocal_Cascaded_Hung_tb.Fang_Reciprocal_cascaded_Hung.temp_result, 2, WL-1);		

	// -- output -- //	
	always @ dout real_Xilinx_result = unsigned_fixedToFloat(dout, 1, WL-1);
	always @ Simu_Result_Matlab[count] real_MATLAB_reuslt = unsigned_fixedToFloat(Simu_Result_Matlab[count], 1, WL-1);
	
endmodule
`endif


`ifdef declare_Reciprocal_Cascaded_GS
module tb_Division_GS_unsigned_rec_24bit;

	// parameters
	parameter WL = 24;			 	 // Word length of the inputs
	parameter LUT_bits = 13;	 	 // word length of the Look-up table
	parameter LUT_addWidth = 13;  	 // address length of the Look-up table
	parameter ITERATION = 1;	 	// Whether use iteration to approach	
	parameter dWL = 27;		
	parameter WLO2 = 24;
	parameter address_bits = 6;
	
	// Inputs
	reg CLK;					   // clock
	reg nRST;					// negative reset
	reg CE;						// clock enable
	reg [WL-1:0] din;			// input


	// Outputs
	wire [dWL-1:0] d1;
	wire [dWL-1:0] p2;
	wire [dWL-1:0] d2, d2_s;
	wire [dWL-1:0] p3;
	wire [dWL-1:0] r3;
	wire [dWL-1:0] r2,r2_s;
	wire [WL-1:0] dout;
	wire [address_bits-1:0] reg_cmp;
	
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
	Division_GS_unsigned_rec_24bit 
	#(
		.WL(WL),							// Total word length of input
		.WLO2(WLO2),
		.address_bits(address_bits),		// Look-up table bits
		.LUT_bits(LUT_bits),  				// World length of the Look-up table
		.dWL(dWL)							// datapath
	)
	Fang_Division_GS_rec 
	(
		.CLK(CLK), 
		.RST(nRST), 
		.CE(CE),
		.in(din), 
		.d1(d1), 
		.p2(p2), 
		.d2(d2),
		.d2_s(d2_s),
		.p3(p3), 
		.r3(r3), 
		.r2(r2), 
		.r2_s(r2_s),
		.result(dout), 
		.reg_cmp(reg_cmp)
	);

//=====================================  clock generator  ==========================================//
	parameter ClockPeriod = 2;	// Clock period
	initial 	 CLK = 0;
	always # (ClockPeriod/2) CLK = ~CLK;
//==================================================================================================//

	// Real number presentation
	real real_din, real_MATLAB_reuslt, real_Xilinx_result;
	real real_d1_net, real_p2, real_d2_net;
//===========================================  Inpulse =============================================//
	integer count;							// counter used for looping below
	real count_mismatched = 0; 				// counter to store the mismatched result number
	initial begin
		// initialize the input vector
		$readmemb("ini_input_binary_GS.txt", Testdata_vec_NR);		
	
		// initialize the Look-up Table
		$readmemb("LUT_rec_GS_iter1.txt", tb_Division_GS_unsigned_rec_24bit.Fang_Division_GS_rec.LUT);
		$readmemb("result_binary_GS.txt", Simu_Result_Matlab);

		nRST = 0; CE = 0; 					// reset
		@(posedge CLK); nRST = 1; CE = 1; 	// start
		
		for (count = 0; count <= `Testdata_Depth; count = count+1) begin		
			din = Testdata_vec_NR[count];
		   $display("MATLAB: %f, Xilinx: %f", unsigned_fixedToFloat(Simu_Result_Matlab[count-1], 1, WL-1), unsigned_fixedToFloat(dout, 1, WL-1));
			@(posedge CLK);
			if (count==`Testdata_Depth) begin
				$finish;
			end
		end
	end	

	// -- input -- //
	always @ din real_din = unsigned_fixedToFloat(din, 1, WL-1);

	// -- Intermediat -- //
	// -- d1_net
	always @ tb_Division_GS_unsigned_rec_24bit.Fang_Division_GS_rec.d1_net
			   real_d1_net = unsigned_fixedToFloat(tb_Division_GS_unsigned_rec_24bit.Fang_Division_GS_rec.d1_net, 2, dWL-2);
     
	// -- p2
	always @ tb_Division_GS_unsigned_rec_24bit.Fang_Division_GS_rec.p2
			   real_p2 = unsigned_fixedToFloat(tb_Division_GS_unsigned_rec_24bit.Fang_Division_GS_rec.p2, 1, dWL-1);

	// -- d2_net
	always @ tb_Division_GS_unsigned_rec_24bit.Fang_Division_GS_rec.d2_net
			   real_d2_net = unsigned_fixedToFloat(tb_Division_GS_unsigned_rec_24bit.Fang_Division_GS_rec.d2_net, 2, dWL-2);     
	  
	// -- output -- //	
	always @ dout real_Xilinx_result = unsigned_fixedToFloat(dout, 1, WL-1);
	always @ Simu_Result_Matlab[count] real_MATLAB_reuslt = unsigned_fixedToFloat(Simu_Result_Matlab[count], 1, WL-1);
	 
endmodule
`endif

`ifdef declare_Reciprocal_Cascaded_NR_tb
module Reciprocal_Cascaded_tb;

	// parameters
	parameter WL = 24;			 // Word length of the inputs
	parameter LUT_bits = 10;	 // word length of the Look-up table
	parameter LUT_addWidth = 6;  // address length of the Look-up table
	parameter ITERATION = 1;	 // Whether use iteration to approach	
	
	// Inputs
	reg CLK;					// clock
	reg nRST;				// negative reset
	reg CE;					// clock enable
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
	real real_mul_1, real_mul_1_r, real_mul_2, real_mul_2_s;
	real real_out_0, real_mul_3, real_mul_3_r, real_mul_3_s;
	real real_mul_4, real_mul_4_s;
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
	Reciprocal_Cascaded_NR
	#(
		.WL(WL),								// Total word length of input
		.LUT_bits(LUT_bits),					// Look-up table bits
		.LUT_addWidth(LUT_addWidth),  			// World length of the Look-up table
		.ITERATION(ITERATION)					// Signal symbols whether to use Iterating
    )
	Fang_Reciprocal_cascaded_NR 
	(
		.CLK(CLK), 							// clock
		.nRST(nRST), 						// negative reset
		.CE(CE), 							// clock enable
		.din(din), 							// data input 
		.dout(dout)							// data output
	 );
//==================================================================================================//

//===========================================  Inpulse =============================================//
	integer count;		// counter used for looping below
	real count_mismatched = 0; // counter to store the mismatched result number
	initial begin
	
		// initialize the input vector
		$readmemb("ini_input_binary_rec_NR_720.txt", Testdata_vec_NR);		
	
		// initialize the Look-up Table
		$readmemb("LUT_rec_NR_iter1_720.txt", Reciprocal_Cascaded_tb.Fang_Reciprocal_cascaded_NR.LUT);
		$readmemb("result_rec_NR_720.txt", Simu_Result_Matlab);

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
	
	/*
	// -- intermediate -- //
		// -- mul_1
	always @ Reciprocal_Cascaded_tb.Fang_Reciprocal_cascaded_NR.mul_1 
			   real_mul_1 = unsigned_fixedToFloat(Reciprocal_Cascaded_tb.Fang_Reciprocal_cascaded_NR.mul_1, 2, WL+LUT_bits-2);
		// -- mul_1_r
	always @ Reciprocal_Cascaded_tb.Fang_Reciprocal_cascaded_NR.mul_1_r 
				real_mul_1_r = unsigned_fixedToFloat(Reciprocal_Cascaded_tb.Fang_Reciprocal_cascaded_NR.mul_1_r, 1, WL+LUT_bits-2);
		// -- mul_2
	always @ Reciprocal_Cascaded_tb.Fang_Reciprocal_cascaded_NR.mul_2 
				real_mul_2 = unsigned_fixedToFloat(Reciprocal_Cascaded_tb.Fang_Reciprocal_cascaded_NR.mul_2, 2, WL+LUT_bits*2-3);
		// -- mul_2_r
	always @ Reciprocal_Cascaded_tb.Fang_Reciprocal_cascaded_NR.mul_2_s 
				real_mul_2_s = unsigned_fixedToFloat(Reciprocal_Cascaded_tb.Fang_Reciprocal_cascaded_NR.mul_2_s, 1, WL+LUT_bits*2-3);		
		// -- out_0
	always @ Reciprocal_Cascaded_tb.Fang_Reciprocal_cascaded_NR.out_0 
				real_out_0 = unsigned_fixedToFloat(Reciprocal_Cascaded_tb.Fang_Reciprocal_cascaded_NR.out_0, 1, WL-1);		
		// -- mul_3
	always @ Reciprocal_Cascaded_tb.Fang_Reciprocal_cascaded_NR.mul_3 
				real_mul_3 = unsigned_fixedToFloat(Reciprocal_Cascaded_tb.Fang_Reciprocal_cascaded_NR.mul_3, 2, WL*2-2);
	// -- mul_3_s
	always @ Reciprocal_Cascaded_tb.Fang_Reciprocal_cascaded_NR.mul_3_s 
				real_mul_3_s = unsigned_fixedToFloat(Reciprocal_Cascaded_tb.Fang_Reciprocal_cascaded_NR.mul_3_s, 1, WL*2-2);	
	// -- mul_3_r
	always @ Reciprocal_Cascaded_tb.Fang_Reciprocal_cascaded_NR.mul_3_r 
				real_mul_3_r = unsigned_fixedToFloat(Reciprocal_Cascaded_tb.Fang_Reciprocal_cascaded_NR.mul_3_r, 1, WL*2-2);
	// -- mul_4
	always @ Reciprocal_Cascaded_tb.Fang_Reciprocal_cascaded_NR.mul_4 
				real_mul_4 = unsigned_fixedToFloat(Reciprocal_Cascaded_tb.Fang_Reciprocal_cascaded_NR.mul_4, 2, WL*3-3);	
	// -- mul_4_s
	always @ Reciprocal_Cascaded_tb.Fang_Reciprocal_cascaded_NR.mul_4_s 
				real_mul_4_s = unsigned_fixedToFloat(Reciprocal_Cascaded_tb.Fang_Reciprocal_cascaded_NR.mul_4_s, 1, WL*3-3);

	*/

	// -- output -- //	
	always @ dout real_Xilinx_result = unsigned_fixedToFloat(dout, 1, WL-1);
	always @ Simu_Result_Matlab[count] real_MATLAB_reuslt = unsigned_fixedToFloat(Simu_Result_Matlab[count], 1, WL-1);
	
endmodule
`endif


`ifdef declare_Reciprocal_Cascaded_ItoNR
module Reciprocal_Cascaded_ItoNR_tb;

	// parameters
	parameter WL = 24;			 // Word length of the inputs
	parameter LUT_bits = 13;	 // word length of the Look-up table
	parameter LUT_addWidth = 6;  // address length of the Look-up table
	parameter dWL = 26;
	parameter WLO = 24;

	// Inputs
	reg CLK;					// clock
	reg nRST;				// negative reset
	reg CE;					// clock enable
	reg [WL-1:0] din;		// input

	// Outputs
	wire [WL-1:0] dout;	// output
	wire [WLO-1:0] dout_pipe;

	// Memory 
	// used to store the testcases
	reg [WL-1:0] Testdata_vec_NR [`Testdata_Depth-1:0];
	// Matlab simulation result vector
	reg [WL-1:0] Simu_Result_Matlab [`Testdata_Depth-1:0];
	
	// Real number presentation
	real real_din, real_MATLAB_reuslt, real_Xilinx_result;
	real real_B1_real, real_mul2_net_r, real_mul2_net, real_Mul, real_dout_pipe;
	real real_iniValue, real_B1,real_xHat ;
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
	Reciprocal_Cascaded_ItoNR
	#(
		.WL(WL),								// Total word length of input
		.LUT_bits(LUT_bits),				// Look-up table bits
		.LUT_addWidth(LUT_addWidth)   // World length of the Look-up table
    )
	Fang_Reciprocal_cascaded_ItoNR 
	(
		.CLK(CLK), 							// clock
		.nRST(nRST), 						// negative reset
		.CE(CE), 							// clock enable
		.din(din), 							// data input 
		.dout(dout)							// data output
	 );
	 
	// Instantiate the Unit Under Test (Fang_Reciprocal_cascaded_NR)
	Reciprocal_Pipelined_ItoNR
	#(
		.WL(WL),								// Total word length of input
		.LUT_bits(LUT_bits),				// Look-up table bits
		.LUT_addWidth(LUT_addWidth),   // World length of the Look-up table
		.WLO(WLO)
    )
	Fang_Reciprocal_ItoNR_pipe 
	(
		.CLK(CLK), 							// clock
		.nRST(nRST), 						// negative reset
		.CE(CE), 							// clock enable
		.din(din), 							// data input 
		.dout(dout_pipe)							// data output
	 );
	 
//==================================================================================================//

//===========================================  Inpulse =============================================//
	integer count;		// counter used for looping below
	real count_mismatched = 0; // counter to store the mismatched result number
	initial begin
	
		// initialize the input vector
		$readmemb("ini_input_binary_rec_Ito_3.txt", Testdata_vec_NR);		
	
		// initialize the Look-up Table
		$readmemb("LUT_rec_Ito_3.txt", Reciprocal_Cascaded_ItoNR_tb.Fang_Reciprocal_cascaded_ItoNR.LUT);
		$readmemb("LUT_rec_Ito_3.txt", Reciprocal_Cascaded_ItoNR_tb.Fang_Reciprocal_ItoNR_pipe.LUT);

		$readmemb("result_binary_rec_Ito_3.txt", Simu_Result_Matlab);

		nRST = 0; CE = 0; 						// reset
		@(posedge CLK); nRST = 1; CE = 1; 	// start
		
		for (count = 0; count <= `Testdata_Depth; count = count+1) begin		
			din = Testdata_vec_NR[count];
		   $display("MATLAB: %f, Xilinx: %f", unsigned_fixedToFloat(Simu_Result_Matlab[count-1], 1, WL-1), unsigned_fixedToFloat(dout, 1, WL-1));
			if (unsigned_fixedToFloat(Simu_Result_Matlab[count-1], 1, WL-1)-unsigned_fixedToFloat(dout, 1, WL-1) <= 2^-23)
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
	
	/*
	// -- intermediate -- //
		// -- xHat
	always @ Reciprocal_Cascaded_ItoNR_tb.Fang_Reciprocal_cascaded_ItoNR.xHat
			   real_xHat = unsigned_fixedToFloat(Reciprocal_Cascaded_ItoNR_tb.Fang_Reciprocal_cascaded_ItoNR.xHat, 1, WL-1);

		// -- B1
	always @ Reciprocal_Cascaded_ItoNR_tb.Fang_Reciprocal_cascaded_ItoNR.B1 
			   real_B1 = unsigned_fixedToFloat(Reciprocal_Cascaded_ItoNR_tb.Fang_Reciprocal_cascaded_ItoNR.B1, 0, LUT_bits);
		// -- B1_real
	always @ Reciprocal_Cascaded_ItoNR_tb.Fang_Reciprocal_cascaded_ItoNR.B1_real 
			   real_B1_real = unsigned_fixedToFloat(Reciprocal_Cascaded_ItoNR_tb.Fang_Reciprocal_cascaded_ItoNR.B1_real, 1, LUT_bits);
		// -- iniValue
	always @ Reciprocal_Cascaded_ItoNR_tb.Fang_Reciprocal_cascaded_ItoNR.iniValue
			   real_iniValue = unsigned_fixedToFloat(Reciprocal_Cascaded_ItoNR_tb.Fang_Reciprocal_cascaded_ItoNR.iniValue, 1, dWL-1);
		// -- mul2_net
	always @ Reciprocal_Cascaded_ItoNR_tb.Fang_Reciprocal_cascaded_ItoNR.mul2_net 
				real_mul2_net = unsigned_fixedToFloat(Reciprocal_Cascaded_ItoNR_tb.Fang_Reciprocal_cascaded_ItoNR.mul2_net, 1, dWL-1);
		// -- mul2_net_i
	always @ Reciprocal_Cascaded_ItoNR_tb.Fang_Reciprocal_cascaded_ItoNR.mul2_net_r 
				real_mul2_net_r = unsigned_fixedToFloat(Reciprocal_Cascaded_ItoNR_tb.Fang_Reciprocal_cascaded_ItoNR.mul2_net_r, 1, dWL-1);
		// -- Mul
	always @ Reciprocal_Cascaded_ItoNR_tb.Fang_Reciprocal_cascaded_ItoNR.Mul 
				real_Mul = unsigned_fixedToFloat(Reciprocal_Cascaded_ItoNR_tb.Fang_Reciprocal_cascaded_ItoNR.Mul, 1, dWL*2-1);						
	*/

	// -- output -- //	
	always @ dout real_Xilinx_result = unsigned_fixedToFloat(dout, 1, WL-1);
	always @ dout_pipe real_dout_pipe = unsigned_fixedToFloat(dout_pipe, 1, WL-1);
	always @ Simu_Result_Matlab[count] real_MATLAB_reuslt = unsigned_fixedToFloat(Simu_Result_Matlab[count], 1, WL-1);
	
endmodule
`endif
