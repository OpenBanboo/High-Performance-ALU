`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   16:56:35 09/21/2015
// Design Name:   flot_Divide
// Module Name:   C:/Users/User/Google Drive/2015/Thesis backup/RecSqr11/RecSqr11/SourceCodes/Division/flot_Divide_tb.v
// Project Name:  test
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: flot_Divide
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module flot_Divide_tb;

	// 16 bit
	/*
	parameter WIDTH = 16;					//parameters of the floating-point number
	parameter WIDTH_exp = 4;				//are defined here
	parameter WIDTH_mat = 11;
	parameter LUT_addWidth = 6;
	parameter LUT_bits = 13;
	*/

	// 24 bit
	/*
	parameter WIDTH = 24;					//parameters of the floating-point number
	parameter WIDTH_exp = 6;				//are defined here
	parameter WIDTH_mat = 17;
	parameter LUT_addWidth = 9;
	parameter LUT_bits = 19;
	*/
	
	// 32 bit
	parameter WIDTH = 32;					//parameters of the floating-point number
	parameter WIDTH_exp = 8;				//are defined here
	parameter WIDTH_mat = 23;
	parameter LUT_addWidth = 12;
	parameter LUT_bits_Hung = 24;
	parameter LUT_bits = 15;
	parameter LUT_bits_Ito = 13;
	parameter LUT_addWidth_Ito = 6;
	parameter LUT_bits_Ito_unfold = 9;
	parameter LUT_addWidth_Ito_unfold = 3;


	// Inputs
	reg CLK;
	reg nRST;
	reg [WIDTH-1:0] OP1;
	reg [WIDTH-1:0] OP2;
	reg CE;
	reg exce_in;

	// Outputs
	wire exce_out, exce_out_pipe, exce_out_pipe_Ito, exce_out_pipe_Ito_unfold;
	wire [WIDTH-1:0] result, result_pipe, result_pipe_Ito, result_pipe_Ito_unfold;

// ================================  Function Definition  =======================================//

// Present the floating format binary number into real
function real floatToReal;
	input [2047:0] in;
	input integer WE;							//exponent width
	input integer WM;							//mantissa width
	integer	idx;								//index for looping
	integer idx2;								//index for looping
	real retVal;								//variable to store mantissa
	real exVal;									//variable to store exponent
	begin
		retVal = 0;								//reset to 0
		exVal  = 0;
// == ------------------Mantissa Calculation----------------------------- == //
		for(idx = 0; idx < WM; idx = idx + 1) begin
			if(in[idx]==1'b1) begin
				retVal = retVal + (2.0**(idx-WM));
			end
		end
		retVal = retVal + 1;
// == ------------------Exponent Calculation------------------ == //		
		for(idx2 = 0; idx2 < WE; idx2 = idx2 + 1) begin
			if(in[idx2+WM]==1'b1) begin
				exVal = exVal + (2.0**idx2);
			end
		end
// == ------------------Exponent Calculation------------------ == //		
		if (in == 0)
			floatToReal = 0;
		else if (in[WE+WM]==1'b1) 
			floatToReal = -retVal*(2.0**(exVal-((2.0**(WE-1))-1)));
		else 
			floatToReal = retVal*(2.0**(exVal-((2.0**(WE-1))-1)));
	end
endfunction

// ===============================================================================//

//=====================================  clock generator  =======================================//
	parameter ClockPeriod = 10;
	initial 	 CLK = 1;
	always # (ClockPeriod/2) CLK = ~CLK;
//===============================================================================================//

	// Instantiate the Unit Under Test (UUT)
	flot_Divide 
	  #(
		.WIDTH(WIDTH),	
		.WIDTH_exp(WIDTH_exp),
		.WIDTH_mat(WIDTH_mat),
		.LUT_bits(LUT_bits_Hung),
		.LUT_addWidth(LUT_addWidth)
		)
	Fang_Divider 
	(
		.CLK(CLK), 
		.nRST(nRST), 
		.OP1(OP1), 
		.OP2(OP2), 
		.CE(CE), 
		.exce_in(exce_in), 
		.exce_out(exce_out), 
		.result(result)
	);
	
	flot_Divide_pipe
	  #(
		.WIDTH(WIDTH),	
		.WIDTH_exp(WIDTH_exp),
		.WIDTH_mat(WIDTH_mat),
		.LUT_bits(LUT_bits),
		.LUT_addWidth(LUT_addWidth)
		)
	Fang_Divider_Pipe
	(
		.CLK(CLK), 
		.nRST(nRST), 
		.OP1(OP1), 
		.OP2(OP2), 
		.CE(CE), 
		.exce_in(exce_in), 
		.exce_out(exce_out_pipe), 
		.result(result_pipe)
	);

	flot_Divide_pipe_Ito
	  #(
		.WIDTH(WIDTH),	
		.WIDTH_exp(WIDTH_exp),
		.WIDTH_mat(WIDTH_mat),
		.LUT_bits(LUT_bits_Ito),
		.LUT_addWidth(LUT_addWidth_Ito)
		)
	Fang_Divider_Pipe_Ito
	(
		.CLK(CLK), 
		.nRST(nRST), 
		.OP1(OP1), 
		.OP2(OP2), 
		.CE(CE), 
		.exce_in(exce_in), 
		.exce_out(exce_out_pipe_Ito), 
		.result(result_pipe_Ito)
	);

	flot_Divide_pipe_Ito_unfold
	  #(
		.WIDTH(WIDTH),	
		.WIDTH_exp(WIDTH_exp),
		.WIDTH_mat(WIDTH_mat),
		.LUT_bits(LUT_bits_Ito_unfold),
		.LUT_addWidth(LUT_addWidth_Ito_unfold)
		)
	Fang_Divider_Pipe_Ito_unfold
	(
		.CLK(CLK), 
		.nRST(nRST), 
		.OP1(OP1), 
		.OP2(OP2), 
		.CE(CE), 
		.exce_in(exce_in), 
		.exce_out(exce_out_pipe_Ito_unfold), 
		.result(result_pipe_Ito_unfold)
	);

	initial begin
		
		// using minimal LUT bits for LUT
		$readmemb("LUT_rec_Hung_24bit.txt", flot_Divide_tb.Fang_Divider.Fang_flo_Rec_Hung.Fang_Reciprocal_Hung.LUT); 
		$readmemb("LUT_rec_NR_iter0.txt", flot_Divide_tb.Fang_Divider_Pipe.Fang_flo_Rec_pipe.Fang_Reciprocal_Pipe.LUT);
		$readmemb("LUT_rec_Ito_3.txt", flot_Divide_tb.Fang_Divider_Pipe_Ito.Fang_flo_Rec_Ito.Fang_Reciprocal_Ito_Pipe.LUT);
		$readmemb("LUT_rec_Ito_unfold_24bits.txt", flot_Divide_tb.Fang_Divider_Pipe_Ito_unfold.Fang_flo_Rec_Ito_unfold.Fang_Reciprocal_Ito_Pipe_unfold.LUT);

		
		// LUT for 32bits
		//$readmemb("LUT_rec_Hung_24bit.txt", flot_Divide_tb.Fang_Divider.Fang_flo_Rec_Hung.Fang_Reciprocal_Hung.LUT); 

		// LUT for 24bits
		// $readmemb("LUT_rec_Hung_18bits.txt", flot_Rec_Hung_tb.Fang_flo_Rec_Hung.Fang_Reciprocal_Hung.LUT); 

		// LUT for 16bits
		// $readmemb("LUT_rec_Hung_12bits.txt", flot_Rec_Hung_tb.Fang_flo_Rec_Hung.Fang_Reciprocal_Hung.LUT); 		
		
		// Initialize Inputs
		CLK = 0;
		nRST = 0;
		OP1 = 0; OP2 = 0; @(posedge CLK);
		nRST = 1; CE = 1; exce_in = 0;

		//32 bit
		OP1 = 32'b0_01111111_11000000000000000000000; OP2 = 32'b0_01111111_11001111000000000000000; @(posedge CLK); // 1.75 		 0.571428
		OP1 = 32'b0_01111110_11000000000000000000000; OP2 = 32'b0_01111110_11001111000000000000000; @(posedge CLK); // 0.875,      1.142857
		OP1 = 32'b0_01111100_11100000000000000000000; OP2 = 32'b0_01111111_11100110000000000000000; @(posedge CLK); // 0.9375	    1.066667
		OP1 = 32'b0_10000011_11000000000000000000000; OP2 = 32'b0_10000001_11001000000010000000000; @(posedge CLK); // 28			 0.035714
		OP1 = 32'b0_10001011_11000011100001111000000; OP2 = 32'b0_10000011_11001110000000000000000; @(posedge CLK); // 7224.46875  0.000138
		OP1 = 32'b0_10000111_11000000000000000000000; OP2 = 32'b0_10000011_11001110000000000000000; @(posedge CLK); // 448         0.002232
		OP1 = 32'b1_10001111_11000011111110000000000; OP2 = 32'b1_10000111_11000000000000000000000; @(posedge CLK); // -115704..   8.642743552513310e-006
		OP1 = 32'b1_01110000_11000011111110000000000; OP1 = 32'b0_00111001_11000011111110000000000; @(posedge CLK); // 
		OP1 = 32'b1_10001111_11000011111110000000000; OP2 = 32'b1_01110000_11000011111110000000000; @(posedge CLK); // -115704..   8.642743552513310e-006
		OP1 = 32'b1_10001111_11000011111110000000000; OP2 = 32'b0_10000011_11000000000000000000000; @(posedge CLK);
		OP1 = 32'b0_10000011_11000000000000000000000; OP2 = 32'b1_10001111_11000011111110000000000; @(posedge CLK);

		@(posedge CLK);@(posedge CLK);@(posedge CLK);@(posedge CLK);@(posedge CLK);@(posedge CLK);@(posedge CLK);@(posedge CLK);@(posedge CLK);@(posedge CLK);
		@(posedge CLK);@(posedge CLK);@(posedge CLK);@(posedge CLK);@(posedge CLK);@(posedge CLK);@(posedge CLK);@(posedge CLK);@(posedge CLK);@(posedge CLK);

		@(posedge CLK);@(posedge CLK);@(posedge CLK);@(posedge CLK);@(posedge CLK);@(posedge CLK);@(posedge CLK);@(posedge CLK);@(posedge CLK);@(posedge CLK);
		@(posedge CLK);@(posedge CLK);@(posedge CLK);@(posedge CLK);@(posedge CLK);@(posedge CLK);@(posedge CLK);@(posedge CLK);@(posedge CLK);@(posedge CLK);

		$finish;
		// Add stimulus here

	end
 
 
//=====================================  Real value Presentation  =============================== //
// ****************************************************
	//variable definition
	real real_OP1, real_OP2;
	real real_result, real_result_pipe, real_result_pipe_Ito, real_result_pipe_Ito_unfold; 
// ============================================================================================== //
 // ****************************************************
	// ****
	// ****
	always @ OP1 real_OP1 = floatToReal(OP1, WIDTH_exp, WIDTH_mat);  
	always @ OP2 real_OP2 = floatToReal(OP2, WIDTH_exp, WIDTH_mat);  
	always @ result real_result = floatToReal(result, WIDTH_exp, WIDTH_mat);   
	always @ result_pipe real_result_pipe = floatToReal(result_pipe, WIDTH_exp, WIDTH_mat);   
	always @ result_pipe_Ito real_result_pipe_Ito = floatToReal(result_pipe_Ito, WIDTH_exp, WIDTH_mat);   
	always @ result_pipe_Ito_unfold real_result_pipe_Ito_unfold = floatToReal(result_pipe_Ito_unfold, WIDTH_exp, WIDTH_mat);   
   
	// ****

endmodule

