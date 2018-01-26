`timescale 1ns / 1ps
`define Testdata_Depth 845		// Sample 80 inputs from exhaustive simulation
////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   18:26:55 11/01/2014
// Design Name:   Reciprocal_Pipelined_NR
// Module Name:   D:/Synchronous/Graduate Studies/Thesis/Summer2014/RecSqr5/SourceCodes/Reciprocal/Reciprocal_Pipelined_NR_tb.v
// Project Name:  RecSqr5
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: Reciprocal_Pipelined_NR
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module Reciprocal_Pipelined_NR_tb;

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
	real real_din, real_din_delay, real_MATLAB_reuslt, real_Xilinx_result;
	real real_mul1_net, real_mul2_net, real_iniValue, real_iniValue_delay;
	real real_mul_1_r, real_dout, real_iniValue_delay2;
	
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
	Reciprocal_Pipelined_NR
	#(
		.WL(WL),									// Total word length of input
		.LUT_bits(LUT_bits),					// Look-up table bits
		.LUT_addWidth(LUT_addWidth),  	// World length of the Look-up table
		.dWL(dWL)								// Signal symbols whether to use Iterating
    )
	Fang_Reciprocal_Pipelined_NR 
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
		$readmemb("ini_input_binary_rec_NR_iter0.txt", Testdata_vec_NR);		
	
		// initialize the Look-up Table
		$readmemb("LUT_rec_NR_iter0.txt", Reciprocal_Pipelined_NR_tb.Fang_Reciprocal_Pipelined_NR.LUT);
		$readmemb("result_rec_NR_iter0_pipelined.txt", Simu_Result_Matlab);

		nRST = 0; CE = 0; 						// reset
		@(posedge CLK); CE = 1; 
		nRST = 1;  	// start
		
		for (count = 0; count <= `Testdata_Depth; count = count+1) begin		
			din = Testdata_vec_NR[count];
		   $display("MATLAB: %f, Xilinx: %f", unsigned_fixedToFloat(Simu_Result_Matlab[count-1], 1, WL-1), unsigned_fixedToFloat(dout, 1, WL-1));
			if (unsigned_fixedToFloat(Simu_Result_Matlab[count-1], 1, WL-1)-unsigned_fixedToFloat(dout, 1, WL-1) <= 2^-23)
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
	always @ Reciprocal_Pipelined_NR_tb.Fang_Reciprocal_Pipelined_NR.din_delay 
				real_din_delay = unsigned_fixedToFloat(Reciprocal_Pipelined_NR_tb.Fang_Reciprocal_Pipelined_NR.din_delay, 1, WL-1);

		// -- mul1_net
	always @ Reciprocal_Pipelined_NR_tb.Fang_Reciprocal_Pipelined_NR.mul1_net 
				real_mul1_net = unsigned_fixedToFloat(Reciprocal_Pipelined_NR_tb.Fang_Reciprocal_Pipelined_NR.mul1_net, 1, dWL-1);		
		// -- mul2_net
	always @ Reciprocal_Pipelined_NR_tb.Fang_Reciprocal_Pipelined_NR.mul2_net 
				real_mul2_net = unsigned_fixedToFloat(Reciprocal_Pipelined_NR_tb.Fang_Reciprocal_Pipelined_NR.mul2_net, 1, dWL+LUT_bits-1);
		// -- mul_1_r
	always @ Reciprocal_Pipelined_NR_tb.Fang_Reciprocal_Pipelined_NR.mul_1_r 
				real_mul_1_r = unsigned_fixedToFloat(Reciprocal_Pipelined_NR_tb.Fang_Reciprocal_Pipelined_NR.mul_1_r, 1, dWL-1);
		// -- iniValue
	always @ Reciprocal_Pipelined_NR_tb.Fang_Reciprocal_Pipelined_NR.iniValue 
				real_iniValue = unsigned_fixedToFloat(Reciprocal_Pipelined_NR_tb.Fang_Reciprocal_Pipelined_NR.iniValue, 1, LUT_bits-1);		
		// -- iniValue_delay
	always @ Reciprocal_Pipelined_NR_tb.Fang_Reciprocal_Pipelined_NR.iniValue_delay 
				real_iniValue_delay = unsigned_fixedToFloat(Reciprocal_Pipelined_NR_tb.Fang_Reciprocal_Pipelined_NR.iniValue_delay, 1, LUT_bits-1);	
		// -- iniValue_delay2
	always @ Reciprocal_Pipelined_NR_tb.Fang_Reciprocal_Pipelined_NR.iniValue_delay2 
				real_iniValue_delay2 = unsigned_fixedToFloat(Reciprocal_Pipelined_NR_tb.Fang_Reciprocal_Pipelined_NR.iniValue_delay2, 1, LUT_bits-1);	

	// -- output -- //	
	always @ dout real_Xilinx_result = unsigned_fixedToFloat(dout, 1, WL-1);
	always @ Simu_Result_Matlab[count] real_MATLAB_reuslt = unsigned_fixedToFloat(Simu_Result_Matlab[count], 1, WL-1);
   
endmodule




module Reciprocal_Pipelined_GS_tb;
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
	Reciprocal_Pipelined_GS
	#(
		.WL(WL),								// Total word length of input
		.LUT_bits(LUT_bits),					// Look-up table bits
		.LUT_addWidth(LUT_addWidth),  			// World length of the Look-up table
		.dWL(dWL)								// Signal symbols whether to use Iterating
    )
	Fang_Reciprocal_Pipelined_GS (
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
		$readmemb("LUT_rec_GS_iter0.txt", Reciprocal_Pipelined_GS_tb.Fang_Reciprocal_Pipelined_GS.LUT);
		$readmemb("result_binary_rec_GS_iter0_pipeline.txt", Simu_Result_Matlab);

		nRST = 0; CE = 0; 						// reset
		@(posedge CLK); CE = 1; 
		nRST = 1;  	// start
		
		for (count = 0; count <= `Testdata_Depth; count = count+1) begin		
			din = Testdata_vec_NR[count];
		   $display("MATLAB: %f, Xilinx: %f", unsigned_fixedToFloat(Simu_Result_Matlab[count-1], 1, WL-1), unsigned_fixedToFloat(dout, 1, WL-1));
			if (unsigned_fixedToFloat(Simu_Result_Matlab[count-1], 1, WL-1)-unsigned_fixedToFloat(dout, 1, WL-1) <= 2^-23)
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





module Reciprocal_Pipelined_ItoNR_tb;

	// parameters
	parameter WL = 24;			 // Word length of the inputs
	parameter LUT_bits = 13;	 // word length of the Look-up table
	parameter LUT_addWidth = 6;  // address length of the Look-up table
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
	real real_B1_real, real_mul2_net_r, real_mul2_net, real_Mul;
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
	Reciprocal_Pipelined_ItoNR
	#(
		.WL(WL),								// Total word length of input
		.LUT_bits(LUT_bits),				// Look-up table bits
		.LUT_addWidth(LUT_addWidth)   // World length of the Look-up table
    )
	Fang_Reciprocal_Pipelined_ItoNR
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
		$readmemb("ini_input_binary_rec_Ito_3.txt", Testdata_vec_NR);		
	
		// initialize the Look-up Table
		$readmemb("LUT_rec_Ito_3.txt", Reciprocal_Pipelined_ItoNR_tb.Fang_Reciprocal_Pipelined_ItoNR.LUT);
		$readmemb("result_binary_rec_Ito_pipelined.txt", Simu_Result_Matlab);

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
	
	// -- intermediate -- //
		// -- xHat
	always @ Reciprocal_Pipelined_ItoNR_tb.Fang_Reciprocal_Pipelined_ItoNR.xHat
			   real_xHat = unsigned_fixedToFloat(Reciprocal_Pipelined_ItoNR_tb.Fang_Reciprocal_Pipelined_ItoNR.xHat, 1, WL-1);

		// -- B1
	always @ Reciprocal_Pipelined_ItoNR_tb.Fang_Reciprocal_Pipelined_ItoNR.B1 
			   real_B1 = unsigned_fixedToFloat(Reciprocal_Pipelined_ItoNR_tb.Fang_Reciprocal_Pipelined_ItoNR.B1, 0, LUT_bits);
		// -- B1_real
	always @ Reciprocal_Pipelined_ItoNR_tb.Fang_Reciprocal_Pipelined_ItoNR.B1_real 
			   real_B1_real = unsigned_fixedToFloat(Reciprocal_Pipelined_ItoNR_tb.Fang_Reciprocal_Pipelined_ItoNR.B1_real, 1, LUT_bits);
		// -- iniValue
	always @ Reciprocal_Pipelined_ItoNR_tb.Fang_Reciprocal_Pipelined_ItoNR.iniValue
			   real_iniValue = unsigned_fixedToFloat(Reciprocal_Pipelined_ItoNR_tb.Fang_Reciprocal_Pipelined_ItoNR.iniValue, 1, dWL-1);
		// -- mul2_net
	always @ Reciprocal_Pipelined_ItoNR_tb.Fang_Reciprocal_Pipelined_ItoNR.mul2_net 
				real_mul2_net = unsigned_fixedToFloat(Reciprocal_Pipelined_ItoNR_tb.Fang_Reciprocal_Pipelined_ItoNR.mul2_net, 1, dWL-1);
		// -- mul2_net_i
	always @ Reciprocal_Pipelined_ItoNR_tb.Fang_Reciprocal_Pipelined_ItoNR.mul2_net_r 
				real_mul2_net_r = unsigned_fixedToFloat(Reciprocal_Pipelined_ItoNR_tb.Fang_Reciprocal_Pipelined_ItoNR.mul2_net_r, 1, dWL-1);
		// -- Mul
	always @ Reciprocal_Pipelined_ItoNR_tb.Fang_Reciprocal_Pipelined_ItoNR.Mul 
				real_Mul = unsigned_fixedToFloat(Reciprocal_Pipelined_ItoNR_tb.Fang_Reciprocal_Pipelined_ItoNR.Mul, 1, dWL*2-1);						


	// -- output -- //	
	always @ dout real_Xilinx_result = unsigned_fixedToFloat(dout, 1, WL-1);
	always @ Simu_Result_Matlab[count] real_MATLAB_reuslt = unsigned_fixedToFloat(Simu_Result_Matlab[count], 1, WL-1);
	
endmodule





module Reciprocal_Pipelined_Hung_tb;

	// parameters
	parameter WL = 24;			 // Word length of the inputs
	parameter LUT_bits = 26;	 // word length of the Look-up table
	parameter LUT_addWidth = 12;  // address length of the Look-up table
	parameter ITERATION = 0;	 // Whether use iteration to approach	
	
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
	Reciprocal_Pipelined_Hung
	#(
		.WL(WL),								// Total word length of input
		.LUT_bits(LUT_bits),					// Look-up table bits
		.LUT_addWidth(LUT_addWidth),  			// World length of the Look-up table
		.ITERATION(ITERATION)					// Signal symbols whether to use Iterating
    )
	Fang_Reciprocal_Pipelined_Hung 
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
		$readmemb("LUT_rec_Hung.txt", Reciprocal_Pipelined_Hung_tb.Fang_Reciprocal_Pipelined_Hung.LUT);
		$readmemb("result_rec_Hung_pipelined.txt", Simu_Result_Matlab);

		nRST = 0; CE = 0; 						// reset
		@(posedge CLK); CE = 1; 
		nRST = 1;  	// start
		
		for (count = 0; count <= `Testdata_Depth; count = count+1) begin		
			din = Testdata_vec_NR[count];
		   $display("MATLAB: %f, Xilinx: %f", unsigned_fixedToFloat(Simu_Result_Matlab[count], 1, WL-1), unsigned_fixedToFloat(dout, 1, WL-1));
			if (unsigned_fixedToFloat(Simu_Result_Matlab[count-1], 1, WL-1)- unsigned_fixedToFloat(dout, 1, WL-1) <= 2^-23)
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
	always @ Reciprocal_Pipelined_Hung_tb.Fang_Reciprocal_Pipelined_Hung.xh 
			   real_xh = unsigned_fixedToFloat(Reciprocal_Pipelined_Hung_tb.Fang_Reciprocal_Pipelined_Hung.xh, 1, WL-1);
		// -- xl
	always @ Reciprocal_Pipelined_Hung_tb.Fang_Reciprocal_Pipelined_Hung.xl 
				real_xl = unsigned_fixedToFloat(Reciprocal_Pipelined_Hung_tb.Fang_Reciprocal_Pipelined_Hung.xl, 1, WL-1);
		// -- Sub
	always @ Reciprocal_Pipelined_Hung_tb.Fang_Reciprocal_Pipelined_Hung.Sub 
				real_Sub = unsigned_fixedToFloat(Reciprocal_Pipelined_Hung_tb.Fang_Reciprocal_Pipelined_Hung.Sub, 1, WL-1);
		// -- Mul
	always @ Reciprocal_Pipelined_Hung_tb.Fang_Reciprocal_Pipelined_Hung.Mul 
				real_Mul = unsigned_fixedToFloat(Reciprocal_Pipelined_Hung_tb.Fang_Reciprocal_Pipelined_Hung.Mul, 2, WL+LUT_bits-2);		
		// -- temp_result
	always @ Reciprocal_Pipelined_Hung_tb.Fang_Reciprocal_Pipelined_Hung.temp_result 
				real_temp_result = unsigned_fixedToFloat(Reciprocal_Pipelined_Hung_tb.Fang_Reciprocal_Pipelined_Hung.temp_result, 2, WL-1);		

	// -- output -- //	
	always @ dout real_Xilinx_result = unsigned_fixedToFloat(dout, 1, WL-1);
	always @ Simu_Result_Matlab[count] real_MATLAB_reuslt = unsigned_fixedToFloat(Simu_Result_Matlab[count], 1, WL-1);
	
endmodule

