`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:31:24 09/26/2015 
// Design Name: 
// Module Name:    IP_Divider_32bit 
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
module IP_Divider_32bit
			#(parameter WIDTH = 32)

			( input 				  CLK,						  //clock				 
									 // nRST,						  //negative reset
			  input [WIDTH-1:0] OP1,						  //input
			  input [WIDTH-1:0] OP2,						  //input
			  input 				  CE,								
			  output 	 	  		rfd,					  //exception out
			  output 	 	  		quotient,					  //exception out
			  output [WIDTH-1:0]	fractional,					  //exception out
			  output [WIDTH-1:0] result //final width = mantissa part + exponent part + sign bit
			 ); 

IP_Divider YourInstanceName (
	.clk(CLK), // input clk
	.ce(CE), // input ce
	.rfd(rfd), // output rfd
	.dividend(OP1), // input [31 : 0] dividend
	.divisor(OP2), // input [31 : 0] divisor
	.quotient(quotient), // output [31 : 0] quotient
	.fractional(fractional)); // output [31 : 0] fractional

endmodule
