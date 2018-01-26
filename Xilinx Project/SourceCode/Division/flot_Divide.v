`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:33:30 09/21/2015 
// Design Name: 
// Module Name:    flot_Divide 
// Project Name: 
// Target Devices: 
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
module flot_Divide
			#(parameter 		  
			 
									  WIDTH = 32,				  //The total bits of the inputs
									  WIDTH_exp = 8,			  //The bitwidth of the exponent part
									  WIDTH_mat = 23,		  	  //The bitwidth of the mantissa part					  
									  LUT_addWidth = 12,		  //Address table is 12 bits for the 23 mantissa part
									  LUT_bits = 24
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
			  output reg 		  exce_out,					  //exception out
			  output [WIDTH_mat+WIDTH_exp:0] result //final width = mantissa part + exponent part + sign bit
			 ); 				 

wire exce_out_rec, exce_out_mul;
wire [WIDTH-1:0] result_rec;

	// Instantiate the reciprocal module
	// 1/b
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
		.OP(OP2), 
		.CE(CE),
		.exce_in(exce_in),
		.result(result_rec),
		.exce_out(exce_out_rec)
		);

	// Instantiate the multiplier
	// a * 1/b
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
		.OP2(result_rec), 
		.exce_in(exce_in), 
		.exce_out(exce_out_mul), 
		.result(result)
	);

// -------------------------------------------- exceptions handler  ------------------------------------------- //
// exception out will be set to 1 when exception in is 1 or exponent part is out of bound after calculation
always @* begin
	if(exce_in||exce_out_mul||exce_out_rec) 
		exce_out <= 1'b1;
	else
		exce_out <= 1'b0;
end
// --------------------------------------------------------------------------------------------------------- //

endmodule
