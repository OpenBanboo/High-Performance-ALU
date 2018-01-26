`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   17:40:13 01/14/2015
// Design Name:   flot_Sqrt_Hung
// Module Name:   D:/Synchronous/Graduate Studies/Thesis/Summer2014/RecSqr9/SourceCodes/Square_root/flot_Sqrt_Hung_tb.v
// Project Name:  RecSqr9
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: flot_Sqrt_Hung
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module flot_Sqrt_Hung_tb;

// ****************************************************
	// 18 bit parameters

	parameter WIDTH = 32;					//parameters of the floating-point number
	parameter WIDTH_exp = 8;				//are defined here
	parameter WIDTH_mat = 23;
	parameter LUT_bits = 27;
	parameter LUT_addWidth = 12;

	/*
	parameter WIDTH = 24;					//parameters of the floating-point number
	parameter WIDTH_exp = 6;				//are defined here
	parameter WIDTH_mat = 17;
	parameter LUT_bits = 20;
	parameter LUT_addWidth = 9;
	*/

	/*
	parameter WIDTH = 16;					//parameters of the floating-point number
	parameter WIDTH_exp = 4;				//are defined here
	parameter WIDTH_mat = 11;
	parameter LUT_bits = 14;
	parameter LUT_addWidth = 6;
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
	wire [WIDTH-1:0] result, result_pipe;
	wire exce_out, exce_out_pipe;				// exception out
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

	flot_Sqrt_Hung 
	#(
		.WIDTH(WIDTH),	
		.WIDTH_exp(WIDTH_exp),
		.WIDTH_mat(WIDTH_mat),
		.LUT_bits(LUT_bits),
		.LUT_addWidth(LUT_addWidth)
	)
	Fang_flot_Sqrt_Hung	
	(
		.CLK(CLK), 
		.nRST(nRST), 
		.OP(OP), 
		.CE(CE), 
		.exce_in(exce_in),
		.result(result),
		.exce_out(exce_out)
	);

	flot_Sqrt_pipe
	#(
		.WIDTH(WIDTH),	
		.WIDTH_exp(WIDTH_exp),
		.WIDTH_mat(WIDTH_mat),
		.LUT_bits(LUT_bits),
		.LUT_addWidth(LUT_addWidth)
	)
	Fang_flot_Sqrt_Pipe
	(
		.CLK(CLK), 
		.nRST(nRST), 
		.OP(OP), 
		.CE(CE), 
		.exce_in(exce_in),
		.result(result_pipe),
		.exce_out(exce_out_pipe)
	);

	initial begin
		// 32 bit
		$readmemb("LUT_Sqrt_Hung_24bits.txt", flot_Sqrt_Hung_tb.Fang_flot_Sqrt_Hung.Fang_Square_Root_Hung.LUT); 
		$readmemb("LUT_Sqrt_Hung_24bits.txt", flot_Sqrt_Hung_tb.Fang_flot_Sqrt_Pipe.Fang_Square_Root_Pipe.LUT); 


		// 24 bit
		// $readmemb("LUT_sqrt_Hung_18bit.txt", flot_Sqrt_Hung_tb.Fang_flot_Sqrt_Hung.Fang_Square_Root_Hung.LUT); 

		// 16 bit
		// $readmemb("LUT_sqrt_Hung_12bit.txt", flot_Sqrt_Hung_tb.Fang_flot_Sqrt_Hung.Fang_Square_Root_Hung.LUT); 

		// Initialize Inputs
		CLK = 0;
		nRST = 0;
		OP = 0; @(posedge CLK);
		nRST = 1; CE = 1; exce_in = 0;

		/*
		// 16 bit
		OP = 16'b0_0111_11000000000; @(posedge CLK); // 1.75 		 1.322876
		OP = 16'b0_0110_11000000000; @(posedge CLK); // 0.875,      0.935414
		OP = 16'b0_0110_11100000000; @(posedge CLK); // 0.9375	    0.968245
		OP = 16'b0_1011_11000000000; @(posedge CLK); // 28			 5.291502
		OP = 16'b0_1001_11001110000; @(posedge CLK); // 28.875	    5.373546
		OP = 16'b0_1011_11000011111; @(posedge CLK); // 7224.46875  84.99687
		OP = 16'b0_1111_11000000000; @(posedge CLK); // 448         21.166010
		OP = 16'b1_1001_11000000000; @(posedge CLK); // -448       -21.166010
		OP = 16'b1_1100_11001111111; @(posedge CLK); // -115704..   3401528
		OP = 16'b1_0111_11000011111; @(posedge CLK); // -0.000054.. 0.00734
		OP = 16'b0_0001_11111111111; @(posedge CLK); // 
		*/

		// 24 bit
		/*
		OP = 24'b0_011111_11000000000000000; @(posedge CLK); // 1.75 		 1.322876
		OP = 24'b0_011110_11000000000000000; @(posedge CLK); // 0.875,      0.935414
		OP = 24'b0_011110_11100000000000000; @(posedge CLK); // 0.9375	    0.968245
		OP = 24'b0_100011_11000000000000000; @(posedge CLK); // 28			 5.291502
		OP = 24'b0_100011_11001110000000000; @(posedge CLK); // 28.875	    5.373546
		OP = 24'b0_101011_11000011100001111; @(posedge CLK); // 7224.46875  84.99687
		OP = 24'b0_100111_11000000000000000; @(posedge CLK); // 448         21.166010
		OP = 24'b1_100111_11000000000000000; @(posedge CLK); // -448       -21.166010
		OP = 24'b1_101111_11000011111110000; @(posedge CLK); // -115704..   3401528
		OP = 24'b1_011100_11000011111110000; @(posedge CLK); // -0.000054.. 0.00734
		OP = 24'b0_011101_11000011111110000; @(posedge CLK); // 
		*/

		// 32 bit
		
		OP = 32'b0_01111111_11000000000000000000000; @(posedge CLK); // 1.75 		 1.322876
		OP = 32'b0_01111110_11000000000000000000000; @(posedge CLK); // 0.875,      0.935414
		OP = 32'b0_01111110_11100000000000000000000; @(posedge CLK); // 0.9375	    0.968245
		OP = 32'b0_10000011_11000000000000000000000; @(posedge CLK); // 28			 5.291502
		OP = 32'b0_10000011_11001110000000000000000; @(posedge CLK); // 28.875	    5.373546
		OP = 32'b0_10001011_11000011100001111000000; @(posedge CLK); // 7224.46875  84.99687
		OP = 32'b0_10000111_11000000000000000000000; @(posedge CLK); // 448         21.166010
		OP = 32'b1_10000111_11000000000000000000000; @(posedge CLK); // -448       -21.166010
		OP = 32'b1_10001111_11000011111110000000000; @(posedge CLK); // -115704..   3401528
		OP = 32'b1_01110000_11000011111110000000000; @(posedge CLK); // -0.000054.. 0.00734
		OP = 32'b0_00111001_11000011111110000000000; @(posedge CLK); // 
		
		@(posedge CLK); @(posedge CLK);@(posedge CLK);@(posedge CLK);@(posedge CLK); 
		@(posedge CLK); @(posedge CLK);@(posedge CLK);@(posedge CLK);@(posedge CLK);$finish;
	end
 // ============================================================================================== //

//=====================================  Real value Presentation  =============================== //
// ****************************************************
	//variable definition
	real real_OP;
	real real_result, real_result_pipe; 
// ============================================================================================== //
 // ****************************************************
	// ****
	// ****
	always @ OP real_OP = floatToReal(OP, WIDTH_exp, WIDTH_mat);  
	always @ result real_result = floatToReal(result, WIDTH_exp, WIDTH_mat);      
	always @ result_pipe real_result_pipe = floatToReal(result_pipe, WIDTH_exp, WIDTH_mat);      

	// ****     
endmodule

