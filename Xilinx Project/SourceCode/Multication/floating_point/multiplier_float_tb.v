`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   15:36:20 04/30/2014
// Design Name:   multiplier_float
// Module Name:   D:/Synchronous/Graduate Studies/Homework/672/HWprojects/HW6-IIR/multiplier_float_tb.v
// Project Name:  HW6-IIR
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: multiplier_float
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module multiplier_float_tb;
// ****************************************************
	parameter WIDTH = 32;					//parameters of the floating-point number
	parameter WIDTH_exp = 8;				//are defined here
	parameter WIDTH_mat = 23;
// ****************************************************	
// ****************************************************			 
	// Inputs
	reg CLK;
	reg RST;										//negtive reset
	reg [WIDTH-1:0] OP1;						//operand 1
	reg [WIDTH-1:0] OP2;						//operand 2
	reg exce_in;								//exception in
// ****************************************************
	// Outputs
	wire exce_out, exce_out_pipe;						//exception out
	wire [WIDTH-1:0] result, result_pipe;			//result
// ****************************************************
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

// ================================   UUT Instialization  =======================================//

	// Instantiate the Unit Under Test (UUT)
	multiplier_float 
	#(
		.WIDTH(WIDTH),	
		.WIDTH_exp(WIDTH_exp),
		.WIDTH_mat(WIDTH_mat)
		)
	Fang_floMul (
		.CLK(CLK), 
		.RST(RST), 
		.OP1(OP1), 
		.OP2(OP2), 
		.exce_in(exce_in), 
		.exce_out(exce_out), 
		.result(result)
	);

	// Instantiate the Unit Under Test (UUT)
	flot_mul_pipe 
	#(
		.WIDTH(WIDTH),	
		.WIDTH_exp(WIDTH_exp),
		.WIDTH_mat(WIDTH_mat)
		)
	Fang_floMul_PIP (
		.CLK(CLK), 
		.nRST(RST), 
		.OP1(OP1), 
		.OP2(OP2), 
		.exce_in(exce_in), 
		.exce_out(exce_out_pipe), 
		.result(result_pipe)
	);

// ==============================================================================================//

//=====================================  clock generator  ==========================================//
	parameter ClockPeriod = 10;
	initial 	 CLK = 1;
	always # (ClockPeriod/2) CLK = ~CLK;
//==================================================================================================//

// ====================================    Initialize Inputs    ====================================//
	initial begin

		RST = 0; OP1 = 0; OP2 = 0; exce_in = 0; @(posedge CLK);

		RST = 1; OP1 = 32'b0_01111100_00000000000000001111000; OP2 = 32'b0_01111110_11100000000000000000000; exce_in = 0; @(posedge CLK); 	//test for fraction number
		//
		
		RST = 1; OP1 = 32'b0_01111110_11000000000000000000000; OP2 = 32'b0_01111110_11100000000000000000000; exce_in = 0; @(posedge CLK); 	//test for fraction number
		//
		
		RST = 1; OP1 = 32'b0_10000011_11000000000000000000000; OP2 = 32'b0_10000011_11000000000000000000000; exce_in = 0; @(posedge CLK);
		
		//
		RST = 1; OP1 = 32'b0_10000111_11000000000000000000000;  OP2 = 32'b0_10000011_11000000000000000000000; exce_in = 1; @(posedge CLK);
		
		//
		RST = 1; OP1 = 32'b1_10000111_11000000000000000000000;  OP2 = 32'b0_10000011_11000000000000000000000; exce_in = 0; @(posedge CLK);
		
		//
		RST = 1; OP1 = 32'b0_10001111_11000000000000000000000;  OP2 = 32'b0_10001111_11000000000000000000000; exce_in = 0; @(posedge CLK);
		
		//
		RST = 1; OP1 = 32'b1_10001111_11000000000000000000000;  OP2 = 32'b0_10011111_11000000000000000000000; exce_in = 0; @(posedge CLK);
		@(posedge CLK);
		// Wait 100 ns for global reset to finish
		@(posedge CLK);		@(posedge CLK);
		@(posedge CLK);		@(posedge CLK);


		$finish;

	end
// ============================================================================================== //    
      
//=====================================  Real value Presentation  ========================================== //
// ****************************************************
	//variable definition
	real real_OP1, real_OP2;
	real real_result, real_result_pipe; 

// ****************************************************
	// ****
	// ****
	always @ OP1 real_OP1 = floatToReal(OP1, WIDTH_exp, WIDTH_mat);  
	always @ OP2 real_OP2 = floatToReal(OP2, WIDTH_exp, WIDTH_mat);
	always @ result real_result = floatToReal(result, WIDTH_exp, WIDTH_mat);
	always @ result_pipe real_result_pipe = floatToReal(result_pipe, WIDTH_exp, WIDTH_mat);

//========================================================================================================== //

		
endmodule

