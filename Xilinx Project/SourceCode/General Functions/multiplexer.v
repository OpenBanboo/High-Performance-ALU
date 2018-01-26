`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 		 VLSI Design and Test Laboratory (E-218) - SDSU
// Engineer: 		 Fang Lin
// 
// Create Date:    12:20:57 02/21/2014 
// Design Name: 
// Module Name:    multiplexer 
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
module multiplexer #(parameter N = 8)(
    input [N-1:0] a,b, input Sel,
	 output reg [N-1:0] out
	 );
always @ * begin
	if (!Sel)		//Sel==0 out = a; 
						//Sel==1 out = b
		out = a;
	else
		out = b;
end
endmodule
