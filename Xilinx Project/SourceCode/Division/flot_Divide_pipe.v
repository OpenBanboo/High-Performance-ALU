`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 	VLSI Design and TEST Lab - SDSU	
// Engineer:   Fang Lin
// 
// Create Date:    17:00:18 09/22/2015 
// Design Name: 
// Module Name:    flot_Divide_pipe 
// Project Name: 
// Target Devices: Virtex-7
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module flot_Divide_pipe
			#(parameter 		  
			/*
									  WIDTH = 64,				  //The total bits of the inputs
									  WIDTH_exp = 11,			  //The bitwidth of the exponent part
									  WIDTH_mat = 52,		  	  //The bitwidth of the mantissa part					  
									  LUT_addWidth = 32,		  //Address table is 12 bits for the 23 mantissa part
									  LUT_bits = 52
			*/

			
									  WIDTH = 32,				  //The total bits of the inputs
									  WIDTH_exp = 8,			  //The bitwidth of the exponent part
									  WIDTH_mat = 23,		  	  //The bitwidth of the mantissa part					  
									  LUT_addWidth = 12,		  //Address table is 12 bits for the 23 mantissa part
									  LUT_bits = 15
			
/*			 
									  WIDTH = 24,				  //The total bits of the inputs
									  WIDTH_exp = 6,			  //The bitwidth of the exponent part
									  WIDTH_mat = 17,		     //The bitwidth of the mantissa part					  
									  LUT_addWidth = 9,		  //Address table is 12 bits for the 23 mantissa part
									  LUT_bits = 19
				  
									  WIDTH = 16,				  //The total bits of the inputs
									  WIDTH_exp = 4,			  //The bitwidth of the exponent part
									  WIDTH_mat = 11,		     //The bitwidth of the mantissa part					  
									  LUT_addWidth = 6,		  //Address table is 12 bits for the 23 mantissa part
									  LUT_bits = 13	
*/
									  )

			( input 				  CLK,						  //clock				 
									  nRST,						  //negative reset
			  input [WIDTH-1:0] OP1,						  //input
			  input [WIDTH-1:0] OP2,						  //input
			  input 				  CE,								
			  input 				  exce_in,
			  output reg	 	  exce_out,					  //exception out
			  output reg [WIDTH-1:0] result //final width = mantissa part + exponent part + sign bit
			 ); 
			 
wire exce_out_rec, exce_out_mul;
wire [WIDTH-1:0] result_rec, result_mul;
wire [WIDTH-1:0] OP1_delay;
reg nRST_delay;

	// Instantiate the reciprocal module
	// 1/b
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
		.OP(OP2), 
		.CE(CE),
		.exce_in(exce_in),
		.result(result_rec),
		.exce_out(exce_out_rec)
		);

	// Instantiate the multiplier
	// a * 1/b

	flot_mul_pipe 
	#(
		.WIDTH(WIDTH),	
		.WIDTH_exp(WIDTH_exp),
		.WIDTH_mat(WIDTH_mat)
		)
	Fang_floMul_PIP (
		.CLK(CLK), 
		.nRST(nRST_delay), 
		.OP1(OP1_delay), 
		.OP2(result_rec), 
		.exce_in(exce_out_rec), 
		.exce_out(exce_out_mul),
		.result(result_mul)
	);

	localparam PIP = 7; // number of pipelined stages of multiplier
	reg [WIDTH-1:0] buffer_OP1 [1: PIP];
	integer i;
	
	always @(posedge CLK) begin
		if (!nRST) begin
			for (i=1; i<=PIP; i=i+1)
				buffer_OP1[i] <= 0;
		end else begin
			buffer_OP1[1] <= OP1;
			for (i=2; i<=PIP; i=i+1)
				buffer_OP1[i] <= buffer_OP1[i-1];
		end
	end

	assign OP1_delay = buffer_OP1[PIP];

// -------------------------------------------- exceptions handler  ------------------------------------------- //
// exception out will be set to 1 when exception in is 1 or exponent part is out of bound after calculation
always @(posedge CLK) begin
	if(!nRST) begin
		result <= result_mul;
		exce_out <= 0;
		nRST_delay <= 0;
	end
	else begin
		result <= result_mul;
		exce_out <= exce_out_mul;
		nRST_delay <= 1;
	end
end
// --------------------------------------------------------------------------------------------------------- //	
// Arbitrary-precision floating-point divider using Ito's method

endmodule








module flot_Divide_pipe_Ito
			#(parameter 		  
			
			
									  WIDTH = 64,				  //The total bits of the inputs
									  WIDTH_exp = 11,			  //The bitwidth of the exponent part
									  WIDTH_mat = 52,		  	  //The bitwidth of the mantissa part					  
									  LUT_addWidth = 13,		  //Address table is 12 bits for the 23 mantissa part
									  LUT_bits = 28
			
			
			/*
									  WIDTH = 32,				  //The total bits of the inputs
									  WIDTH_exp = 8,			  //The bitwidth of the exponent part
									  WIDTH_mat = 23,		  	  //The bitwidth of the mantissa part					  
									  LUT_addWidth = 6,		  //Address table is 12 bits for the 23 mantissa part
									  LUT_bits = 13
			*/
/*			 
									  WIDTH = 24,				  //The total bits of the inputs
									  WIDTH_exp = 6,			  //The bitwidth of the exponent part
									  WIDTH_mat = 17,		     //The bitwidth of the mantissa part					  
									  LUT_addWidth = 9,		  //Address table is 12 bits for the 23 mantissa part
									  LUT_bits = 19
				  
									  WIDTH = 16,				  //The total bits of the inputs
									  WIDTH_exp = 4,			  //The bitwidth of the exponent part
									  WIDTH_mat = 11,		     //The bitwidth of the mantissa part					  
									  LUT_addWidth = 6,		  //Address table is 12 bits for the 23 mantissa part
									  LUT_bits = 13	
*/
									  )

			( input 				  CLK,						  //clock				 
									  nRST,						  //negative reset
			  input [WIDTH-1:0] OP1,						  //input
			  input [WIDTH-1:0] OP2,						  //input
			  input 				  CE,								
			  input 				  exce_in,
			  output reg	 	  exce_out,					  //exception out
			  output reg [WIDTH-1:0] result //final width = mantissa part + exponent part + sign bit
			 ); 
			 
wire exce_out_rec, exce_out_mul;
wire [WIDTH-1:0] result_rec, result_mul;
wire [WIDTH-1:0] OP1_delay;
reg nRST_delay;

	// Instantiate the reciprocal module
	// 1/b
	flot_Rec_pipe_Ito
	  #(
		.WIDTH(WIDTH),	
		.WIDTH_exp(WIDTH_exp),
		.WIDTH_mat(WIDTH_mat),
		.LUT_bits(LUT_bits),
		.LUT_addWidth(LUT_addWidth)
		)
	Fang_flo_Rec_Ito
		(
		.CLK(CLK), 
		.nRST(nRST), 
		.OP(OP2), 
		.CE(CE),
		.exce_in(exce_in),
		.result(result_rec),
		.exce_out(exce_out_rec)
		);

	// Instantiate the multiplier
	// a * 1/b

	flot_mul_pipe 
	#(
		.WIDTH(WIDTH),	
		.WIDTH_exp(WIDTH_exp),
		.WIDTH_mat(WIDTH_mat)
		)
	Fang_floMul_PIP (
		.CLK(CLK), 
		.nRST(nRST_delay), 
		.OP1(OP1_delay), 
		.OP2(result_rec), 
		.exce_in(exce_out_rec), 
		.exce_out(exce_out_mul),
		.result(result_mul)
	);

	localparam PIP = 7; // number of pipelined stages of reciprocal
	reg [WIDTH-1:0] buffer_OP1 [1: PIP];
	integer i;
	
	always @(posedge CLK) begin
		if (!nRST) begin
			for (i=1; i<=PIP; i=i+1)
				buffer_OP1[i] <= 0;
		end else begin
			buffer_OP1[1] <= OP1;
			for (i=2; i<=PIP; i=i+1)
				buffer_OP1[i] <= buffer_OP1[i-1];
		end
	end

	assign OP1_delay = buffer_OP1[PIP];

// -------------------------------------------- exceptions handler  ------------------------------------------- //
// exception out will be set to 1 when exception in is 1 or exponent part is out of bound after calculation
always @(posedge CLK) begin
	if(!nRST) begin
		result <= result_mul;
		exce_out <= 0;
		nRST_delay <= 0;
	end
	else begin
		result <= result_mul;
		exce_out <= exce_out_mul;
		nRST_delay <= 1;
	end
end
// --------------------------------------------------------------------------------------------------------- //	

endmodule










module flot_Divide_pipe_Ito_unfold
			#(parameter 		  
			
			
									  WIDTH = 64,				  //The total bits of the inputs
									  WIDTH_exp = 11,			  //The bitwidth of the exponent part
									  WIDTH_mat = 52,		  	  //The bitwidth of the mantissa part					  
									  LUT_addWidth = 6,		  //Address table is 12 bits for the 23 mantissa part
									  LUT_bits = 28
			
			
			/*
									  WIDTH = 32,				  //The total bits of the inputs
									  WIDTH_exp = 8,			  //The bitwidth of the exponent part
									  WIDTH_mat = 23,		  	  //The bitwidth of the mantissa part					  
									  LUT_addWidth = 3,		  //Address table is 12 bits for the 23 mantissa part
									  LUT_bits = 9
			*/
/*			 
									  WIDTH = 24,				  //The total bits of the inputs
									  WIDTH_exp = 6,			  //The bitwidth of the exponent part
									  WIDTH_mat = 17,		     //The bitwidth of the mantissa part					  
									  LUT_addWidth = 9,		  //Address table is 12 bits for the 23 mantissa part
									  LUT_bits = 19
				  
									  WIDTH = 16,				  //The total bits of the inputs
									  WIDTH_exp = 4,			  //The bitwidth of the exponent part
									  WIDTH_mat = 11,		     //The bitwidth of the mantissa part					  
									  LUT_addWidth = 6,		  //Address table is 12 bits for the 23 mantissa part
									  LUT_bits = 13	
*/
									  )

			( input 				  CLK,						  //clock				 
									  nRST,						  //negative reset
			  input [WIDTH-1:0] OP1,						  //input
			  input [WIDTH-1:0] OP2,						  //input
			  input 				  CE,								
			  input 				  exce_in,
			  output reg	 	  exce_out,					  //exception out
			  output reg [WIDTH-1:0] result //final width = mantissa part + exponent part + sign bit
			 ); 
			 
wire exce_out_rec, exce_out_mul;
wire [WIDTH-1:0] result_rec, result_mul;
wire [WIDTH-1:0] OP1_delay;
reg nRST_delay;

	// Instantiate the reciprocal module
	// 1/b
	flot_Rec_pipe_Ito_unfold
	  #(
		.WIDTH(WIDTH),	
		.WIDTH_exp(WIDTH_exp),
		.WIDTH_mat(WIDTH_mat),
		.LUT_bits(LUT_bits),
		.LUT_addWidth(LUT_addWidth)
		)
	Fang_flo_Rec_Ito_unfold
		(
		.CLK(CLK), 
		.nRST(nRST), 
		.OP(OP2), 
		.CE(CE),
		.exce_in(exce_in),
		.result(result_rec),
		.exce_out(exce_out_rec)
		);

	// Instantiate the multiplier
	// a * 1/b

	flot_mul_pipe 
	#(
		.WIDTH(WIDTH),	
		.WIDTH_exp(WIDTH_exp),
		.WIDTH_mat(WIDTH_mat)
		)
	Fang_floMul_PIP (
		.CLK(CLK), 
		.nRST(nRST_delay), 
		.OP1(OP1_delay), 
		.OP2(result_rec), 
		.exce_in(exce_out_rec), 
		.exce_out(exce_out_mul),
		.result(result_mul)
	);

	localparam PIP = 9; // number of pipelined stages of reciprocal
	reg [WIDTH-1:0] buffer_OP1 [1: PIP];
	integer i;
	
	always @(posedge CLK) begin
		if (!nRST) begin
			for (i=1; i<=PIP; i=i+1)
				buffer_OP1[i] <= 0;
		end else begin
			buffer_OP1[1] <= OP1;
			for (i=2; i<=PIP; i=i+1)
				buffer_OP1[i] <= buffer_OP1[i-1];
		end
	end

	assign OP1_delay = buffer_OP1[PIP];

// -------------------------------------------- exceptions handler  ------------------------------------------- //
// exception out will be set to 1 when exception in is 1 or exponent part is out of bound after calculation
always @(posedge CLK) begin
	if(!nRST) begin
		result <= result_mul;
		exce_out <= 0;
		nRST_delay <= 0;
	end
	else begin
		result <= result_mul;
		exce_out <= exce_out_mul;
		nRST_delay <= 1;
	end
end
// --------------------------------------------------------------------------------------------------------- //	

endmodule