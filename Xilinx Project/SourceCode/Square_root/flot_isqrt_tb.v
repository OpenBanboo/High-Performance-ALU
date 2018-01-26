`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   22:09:59 01/14/2015
// Design Name:   flot_isqrt
// Module Name:   D:/Synchronous/Graduate Studies/Thesis/Summer2014/RecSqr9/SourceCodes/Square_root/flot_isqrt_tb.v
// Project Name:  RecSqr9
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: flot_isqrt
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module flot_isqrt_tb;
// ****************************************************
	// 32 bit parameters
	
	parameter WIDTH = 32;					//parameters of the floating-point number
	parameter WIDTH_exp = 8;				//are defined here
	parameter WIDTH_mat = 23;
	parameter LUT_addWidth =12;
	parameter LUT_bits = 24;
	parameter LUT_addWidth_Ito = 6;
	parameter LUT_bits_Ito = 13;
	
	
	// 24 bit parameters
	/*
	parameter WIDTH = 24;					//parameters of the floating-point number
	parameter WIDTH_exp = 6;				//are defined here
	parameter WIDTH_mat = 17;
	parameter LUT_addWidth = 9;
	parameter LUT_bits = 18;
	*/
	
	// 16 bit parameters
	/*
	parameter WIDTH = 16;					//parameters of the floating-point number
	parameter WIDTH_exp = 4;				//are defined here
	parameter WIDTH_mat = 11;
	parameter LUT_addWidth = 6;
	parameter LUT_bits = 12;
	*/
// ****************************************************	

// ****************************************************			 
	// Inputs
	reg CLK;
	reg nRST;
	reg [WIDTH-1:0] OP;
	reg CE;
	reg exce_in;

	// Outputs
	wire [WIDTH-1:0] result, result_Ito, result_Ito_pipe;
	wire exce_out, exce_out_Ito, exce_out_Ito;				// exception out

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

// ================================   UUT Instialization  =======================================//

	flot_isqrt
	#(
		.WIDTH(WIDTH),	
		.WIDTH_exp(WIDTH_exp),
		.WIDTH_mat(WIDTH_mat),
		.LUT_bits(LUT_bits),
		.LUT_addWidth(LUT_addWidth)

	)
	Fang_flot_isqrt
	(
		.CLK(CLK), 
		.nRST(nRST), 
		.OP(OP), 
		.CE(CE), 
		.exce_in(exce_in),
		.result(result),
		.exce_out(exce_out)
	);


	flot_isqrt_Ito
	#(
		.WIDTH(WIDTH),	
		.WIDTH_exp(WIDTH_exp),
		.WIDTH_mat(WIDTH_mat),
		.LUT_bits(LUT_bits_Ito),
		.LUT_addWidth(LUT_addWidth_Ito)

	)
	Fang_flot_isqrt_Ito
	(
		.CLK(CLK), 
		.nRST(nRST), 
		.OP(OP), 
		.CE(CE), 
		.exce_in(exce_in),
		.result(result_Ito),
		.exce_out(exce_out_Ito)
	);

	flot_isqrt_Ito_pipe
	#(
		.WIDTH(WIDTH),	
		.WIDTH_exp(WIDTH_exp),
		.WIDTH_mat(WIDTH_mat),
		.LUT_bits(LUT_bits_Ito),
		.LUT_addWidth(LUT_addWidth_Ito)

	)
	Fang_flot_isqrt_Ito_pipe
	(
		.CLK(CLK), 
		.nRST(nRST), 
		.OP(OP), 
		.CE(CE), 
		.exce_in(exce_in),
		.result(result_Ito_pipe),
		.exce_out(exce_out_Ito_pipe)
	);

	initial begin
	
		// LUT for 32bit
		$readmemb("LUT_Isqrt_WLbits_24bit.txt", flot_isqrt_tb.Fang_flot_isqrt.Fang_Root_Reciprocal_Cascaded_NR_2.LUT);
		$readmemb("LUT_isqt_Ito.txt", flot_isqrt_tb.Fang_flot_isqrt_Ito.Fang_Square_Root_Reciprocal_Ito_Iter1.LUT);
		$readmemb("LUT_isqt_Ito.txt", flot_isqrt_tb.Fang_flot_isqrt_Ito_pipe.Fang_Square_Root_Reciprocal_Ito_Iter1_pipe.LUT);

		// LUT for 24bit
	   // $readmemb("LUT_isqt_NR_iter0_18bit.txt", flot_isqrt_tb.Fang_flot_isqrt.Fang_Root_Reciprocal_Cascaded_NR_2.LUT);

		// LUT for 24bit
	   // $readmemb("LUT_isqt_NR_iter0_12bit.txt", flot_isqrt_tb.Fang_flot_isqrt.Fang_Root_Reciprocal_Cascaded_NR_2.LUT);
		// Initialize Inputs
		CLK = 0;
		nRST = 0;
		OP = 0; @(posedge CLK);
		nRST = 1; CE = 1; exce_in = 0;

		/*
		OP = 16'b0_0111_11000000000; @(posedge CLK); // 1.75 		 0.7559289
		OP = 16'b0_0110_11000000000; @(posedge CLK); // 0.875,      1.069045
		OP = 16'b0_0110_11100000000; @(posedge CLK); // 0.9375	    1.032796
		OP = 16'b0_1011_11000000000; @(posedge CLK); // 28			 0.188982
		OP = 16'b0_1011_11001110000; @(posedge CLK); // 28.875	    0.186097
		OP = 16'b0_1010_11001111111; @(posedge CLK); // 7224.46875  0.011765
		OP = 16'b0_1111_11000000000; @(posedge CLK); // 448         0.047246
		exce_in = 1;
		OP = 16'b1_1001_11000000000; @(posedge CLK); // -448       -0.047246
		OP = 16'b1_1011_11000011111; @(posedge CLK); // -115704..   0.002940
		exce_in = 0;
		OP = 16'b1_0111_11000011111; @(posedge CLK); // -0.000054.. -136.235641
		OP = 16'b0_0001_11111111111; @(posedge CLK); // NA

		*/

		// 24 bit
		/*
		OP = 24'b0_011111_11000000000000000; @(posedge CLK); // 1.75 		 0.7559289
		OP = 24'b0_011110_11000000000000000; @(posedge CLK); // 0.875,      1.069045
		OP = 24'b0_011110_11100000000000000; @(posedge CLK); // 0.9375	    1.032796
		OP = 24'b0_100011_11000000000000000; @(posedge CLK); // 28			 0.188982
		OP = 24'b0_100011_11001110000000000; @(posedge CLK); // 28.875	    0.186097
		OP = 24'b0_101011_11000011100001111; @(posedge CLK); // 7224.46875  0.011765
		OP = 24'b0_100111_11000000000000000; @(posedge CLK); // 448         0.047246
		OP = 24'b1_100111_11000000000000000; @(posedge CLK); // -448       -0.047246
		OP = 24'b1_100011_11000011111110000; @(posedge CLK); // -115704..   0.002940
		OP = 24'b1_011100_11000011111110000; @(posedge CLK); // -0.000054.. -136.235641
		OP = 24'b0_010000_11111111111110000; @(posedge CLK); // NA
		*/
		
		// 32 bit
		OP = 32'b0_01111111_11000000000000000000000; @(posedge CLK); // 1.75 		 0.7559289
		OP = 32'b0_01111110_11000000000000000000000; @(posedge CLK); // 0.875,      1.069045
		OP = 32'b0_01111110_11100000000000000000000; @(posedge CLK); // 0.9375	    1.032796
		OP = 32'b0_10000011_11000000000000000000000; @(posedge CLK); // 28			 0.188982
		OP = 32'b0_10000011_11001110000000000000000; @(posedge CLK); // 28.875	    0.186097
		OP = 32'b0_10001011_11000011100001111000000; @(posedge CLK); // 7224.46875  0.011765
		OP = 32'b0_10000111_11000000000000000000000; @(posedge CLK); // 448         0.047246
		OP = 32'b1_10000111_11000000000000000000000; @(posedge CLK); // -448       -0.047246
		OP = 32'b1_10001111_11000011111110000000000; @(posedge CLK); // -115704..   0.002940
		OP = 32'b1_01110000_11000011111110000000000; @(posedge CLK); // -0.000054.. -136.235641
		OP = 32'b0_00111001_11000011111110000000000; @(posedge CLK); // NA
		@(posedge CLK);@(posedge CLK);@(posedge CLK);@(posedge CLK);@(posedge CLK);@(posedge CLK);@(posedge CLK);@(posedge CLK);
		@(posedge CLK);@(posedge CLK);@(posedge CLK);@(posedge CLK);@(posedge CLK);@(posedge CLK);@(posedge CLK);@(posedge CLK);
		
		@(posedge CLK); $finish;
	end
 // ============================================================================================== //

//=====================================  Real value Presentation  =============================== //
// ****************************************************
	//variable definition
	real real_OP;
	real real_result, real_result_Ito, real_result_Ito_pipe; 
// ============================================================================================== //
 // ****************************************************
	// ****
	// ****
	always @ OP real_OP = floatToReal(OP, WIDTH_exp, WIDTH_mat);  
	always @ result real_result = floatToReal(result, WIDTH_exp, WIDTH_mat);      
	always @ result_Ito real_result_Ito = floatToReal(result_Ito, WIDTH_exp, WIDTH_mat);  
	always @ result_Ito_pipe real_result_Ito_pipe = floatToReal(result_Ito_pipe, WIDTH_exp, WIDTH_mat); 

endmodule

