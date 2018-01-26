`timescale 1ns / 1ps

module flot_Rec_Hung_tb;

// ****************************************************
	// 

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
	parameter LUT_bits = 24;

// ****************************************************	

// ****************************************************			 
	// Inputs
	reg CLK;
	reg nRST;
	reg [WIDTH-1:0] OP;
	reg CE;
	reg exce_in;

	// Outputs
	wire [WIDTH-1:0] result;
	wire exce_out;				// exception out

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

	// Instantiate the Unit Under Test (UUT)
	flot_Rec_Hung
	  #(
		.WIDTH(WIDTH),	
		.WIDTH_exp(WIDTH_exp),
		.WIDTH_mat(WIDTH_mat),
		.LUT_bits(LUT_bits),
		.LUT_addWidth(LUT_addWidth)
		)
	Fang_flo_Rec_Hung 
		(
		.CLK(CLK), 
		.nRST(nRST), 
		.OP(OP), 
		.CE(CE),
		.exce_in(exce_in),
		.result(result),
		.exce_out(exce_out)
		);

	// Instantiate the Unit Under Test (UUT)
	flot_Rec_pipe
	  #(
		.WIDTH(WIDTH),	
		.WIDTH_exp(WIDTH_exp),
		.WIDTH_mat(WIDTH_mat),
		.LUT_bits(LUT_bits),
		.LUT_addWidth(LUT_addWidth)
		)
	Fang_flo_Rec_pipe
		(
		.CLK(CLK), 
		.nRST(nRST), 
		.OP(OP), 
		.CE(CE),
		.exce_in(exce_in),
		.result(result),
		.exce_out(exce_out)
		);

	initial begin
		
		// LUT for 32bits
		$readmemb("LUT_rec_Hung_24bit.txt", flot_Rec_Hung_tb.Fang_flo_Rec_Hung.Fang_Reciprocal_Hung.LUT); 

		// LUT for 24bits
		// $readmemb("LUT_rec_Hung_18bits.txt", flot_Rec_Hung_tb.Fang_flo_Rec_Hung.Fang_Reciprocal_Hung.LUT); 

		// LUT for 16bits
		// $readmemb("LUT_rec_Hung_12bits.txt", flot_Rec_Hung_tb.Fang_flo_Rec_Hung.Fang_Reciprocal_Hung.LUT); 		
		
		// Initialize Inputs
		CLK = 0;
		nRST = 0;
		OP = 0; @(posedge CLK);
		nRST = 1; CE = 1; exce_in = 0;

		// 16 bit
		/*
		OP = 16'b0_0111_11000000000; @(posedge CLK); // 1.75 		 0.571428
		OP = 16'b0_0110_11000000000; @(posedge CLK); // 0.875,      1.142857
		OP = 16'b0_0110_11100000000; @(posedge CLK); // 0.9375	    1.066667
		OP = 16'b0_1011_11000000000; @(posedge CLK); // 28			 0.035714
		OP = 16'b0_1001_11001110000; @(posedge CLK); // 28.875	    0.034632
		OP = 16'b0_1010_11000010111; @(posedge CLK); // 7224.46875  0.000138
		OP = 16'b0_1011_11000000000; @(posedge CLK); // 448         0.002232
		OP = 16'b1_1111_11000000000; @(posedge CLK); // -448       -0.002232
		OP = 16'b1_1011_11000011111; @(posedge CLK); // -115704..   8.642743552513310e-006
		OP = 16'b1_0110_11000011111; @(posedge CLK); // -0.000054.. 1.851851851851852e+004
		OP = 16'b0_0111_11000011111; @(posedge CLK); // 
		*/


		// 24 bit
		/*
		OP = 24'b0_011111_11000000000000000; @(posedge CLK); // 1.75 		 0.571428
		OP = 24'b0_011110_11000000000000000; @(posedge CLK); // 0.875,      1.142857
		OP = 24'b0_011110_11100000000000000; @(posedge CLK); // 0.9375	    1.066667
		OP = 24'b0_100011_11000000000000000; @(posedge CLK); // 28			 0.035714 
		exce_in = 1;
		OP = 24'b0_100001_11001110000000000; @(posedge CLK); // 28.875	    0.034632
		OP = 24'b0_100010_11000011100001111; @(posedge CLK); // 7224.46875  0.000138
		exce_in = 0;
		OP = 24'b0_100111_11000000000000000; @(posedge CLK); // 448         0.002232
		OP = 24'b1_100111_11000000000000000; @(posedge CLK); // -448       -0.002232
		OP = 24'b1_100011_11000011111110000; @(posedge CLK); // -115704..   8.642743552513310e-006
		OP = 24'b1_011100_11000011111110000; @(posedge CLK); // -0.000054.. 1.851851851851852e+004
		OP = 24'b0_001110_11000011111110000; @(posedge CLK); // 
		*/
		
		//32 bit
		OP = 32'b0_01111111_11000000000000000000000; @(posedge CLK); // 1.75 		 0.571428
		OP = 32'b0_01111110_11000000000000000000000; @(posedge CLK); // 0.875,      1.142857
		OP = 32'b0_01111110_11100000000000000000000; @(posedge CLK); // 0.9375	    1.066667
		OP = 32'b0_10000011_11000000000000000000000; @(posedge CLK); // 28			 0.035714
		OP = 32'b0_10000011_11001110000000000000000; @(posedge CLK); // 28.875	    0.034632
		OP = 32'b0_10001011_11000011100001111000000; @(posedge CLK); // 7224.46875  0.000138
		OP = 32'b0_10000111_11000000000000000000000; @(posedge CLK); // 448         0.002232
		OP = 32'b1_10000111_11000000000000000000000; @(posedge CLK); // -448       -0.002232
		OP = 32'b1_10001111_11000011111110000000000; @(posedge CLK); // -115704..   8.642743552513310e-006
		OP = 32'b1_01110000_11000011111110000000000; @(posedge CLK); // -0.000054.. 1.851851851851852e+004
		OP = 32'b0_00111001_11000011111110000000000; @(posedge CLK); // 

		
		@(posedge CLK); $finish;

	end
// ============================================================================================== //

//=====================================  Real value Presentation  =============================== //
// ****************************************************
	//variable definition
	real real_OP;
	real real_result; 
// ============================================================================================== //
 // ****************************************************
	// ****
	// ****
	always @ OP real_OP = floatToReal(OP, WIDTH_exp, WIDTH_mat);  
	always @ result real_result = floatToReal(result, WIDTH_exp, WIDTH_mat);      
	// ****
		
endmodule

