`timescale 1ns / 1ps
`define Testdata_Depth 845		// Sample 845 inputs from exhaustive simulation
////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   20:54:04 07/25/2014
// Design Name:   Square_root_Reciprocal_Hung_DirectImplementation
// Module Name:   D:/Synchronous/Graduate Studies/Thesis/Summer2014/RecSqr4/RecSqr3/SourceCodes/Square_root/Square_rootl_Hung_tb.v
// Project Name:  RecSqr3
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: Square_root_Reciprocal_Hung_DirectImplementation
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module Square_rootl_Hung_tb;

	// parameters
	parameter WL = 24;			 // Word length of the inputs
	parameter LUT_bits = 27;	 // word length of the Look-up table
	parameter LUT_addWidth = 12; // address length of the Look-up table
	parameter dWL = 27;

	// Inputs
	reg CLK;
	reg nRST;
	reg CE;
	reg [WL-1:0] din;

	// Outputs
	wire [WL-1:0] dout, dout_pipe;

	// Memory 
	// used to store the testcases
	reg [WL-1:0] Testdata_vec_NR [`Testdata_Depth-1:0];
	// Matlab simulation result vector
	reg [WL-1:0] Simu_Result_Matlab [`Testdata_Depth-1:0];

	// Real number presentation
	real real_din, real_MATLAB_reuslt, real_Xilinx_result;
	real real_xh, real_xl, real_Sub, real_xl_s;
	real real_Mul, real_temp_result, real_mul1_net;
	real real_dout, real_dout_pipe;

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
	Square_root_Hung_DirectImplementation
	#(
		.WL(WL),								// Total word length of input
		.LUT_bits(LUT_bits),				// Look-up table bits
		.LUT_addWidth(LUT_addWidth),  // World length of the Look-up table
		.dWL(dWL)			// Signal symbols whether to use Iterating
    )
	Fang_Square_Root_Hung 
	(
		.CLK(CLK), 							// clock
		.nRST(nRST), 						// negative reset
		.CE(CE), 							// clock enable
		.din(din), 							// data input 
		.dout(dout)							// data output
	 );

	Square_root_pipe
	#(
		.WL(WL),								// Total word length of input
		.LUT_bits(LUT_bits),				// Look-up table bits
		.LUT_addWidth(LUT_addWidth),  // World length of the Look-up table
		.dWL(dWL)			// Signal symbols whether to use Iterating
    )
	Fang_Square_Root_Pipe 
	(
		.CLK(CLK), 							// clock
		.nRST(nRST), 						// negative reset
		.CE(CE), 							// clock enable
		.din(din), 							// data input 
		.dout(dout_pipe)							// data output
	 );

//===========================================  Inpulse =============================================//
	integer count;					// counter used for looping below
	real count_mismatched = 0; // counter to store the mismatched result number
	initial begin
	
		// initialize the input vector
		$readmemb("ini_input_binary_sqrt_Hung.txt", Testdata_vec_NR);		
	
		// initialize the Look-up Table
		$readmemb("LUT_sqt_Hung.txt", Square_rootl_Hung_tb.Fang_Square_Root_Hung.LUT);
		$readmemb("LUT_sqt_Hung.txt", Square_rootl_Hung_tb.Fang_Square_Root_Pipe.LUT);

		
		$readmemb("result_sqrt_Hung.txt", Simu_Result_Matlab);
		nRST = 0; CE = 0; 						// reset
		@(posedge CLK); nRST = 1; CE = 1; 	// start
		
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
/*
	// -- intermediate -- //
		// -- xh
	always @ Square_rootl_Hung_tb.Fang_Square_Root_Hung.xh 
			   real_xh = unsigned_fixedToFloat(Square_rootl_Hung_tb.Fang_Square_Root_Hung.xh, 1, WL-1);
      
		// -- xl
//	always @ Square_rootl_Hung_tb.Fang_Square_Root_Hung.xl 
//				real_xl = unsigned_fixedToFloat(Square_rootl_Hung_tb.Fang_Square_Root_Hung.xl, 1, WL-1);

		// -- xl_s
	always @ Square_rootl_Hung_tb.Fang_Square_Root_Hung.xl_s 
				real_xl_s = unsigned_fixedToFloat(Square_rootl_Hung_tb.Fang_Square_Root_Hung.xl_s, 1, WL-1);

		// -- Sub
	always @ Square_rootl_Hung_tb.Fang_Square_Root_Hung.Sub 
				real_Sub = unsigned_fixedToFloat(Square_rootl_Hung_tb.Fang_Square_Root_Hung.Sub, 1, WL-1);

		// -- mul1_net 
	always @ Square_rootl_Hung_tb.Fang_Square_Root_Hung.mul1_net 
				real_mul1_net = unsigned_fixedToFloat(Square_rootl_Hung_tb.Fang_Square_Root_Hung.mul1_net, 1, dWL-1);

		// -- Mul
	always @ Square_rootl_Hung_tb.Fang_Square_Root_Hung.Mul 
				real_Mul = unsigned_fixedToFloat(Square_rootl_Hung_tb.Fang_Square_Root_Hung.Mul, 1, dWL+LUT_bits-1);	
*/
	// -- output -- //	
	always @ dout real_Xilinx_result = unsigned_fixedToFloat(dout, 1, WL-1);
	
	always @ dout_pipe real_dout_pipe = unsigned_fixedToFloat(dout_pipe, 1, WL-1);
	always @ Simu_Result_Matlab[count] real_MATLAB_reuslt = unsigned_fixedToFloat(Simu_Result_Matlab[count], 1, WL-1);
		
endmodule

