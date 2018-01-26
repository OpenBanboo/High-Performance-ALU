`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:14:33 11/01/2014 
// Design Name: 
// Module Name:    buffer 
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
module buffer
		#(parameter  WL = 8,     // input width
                   DEPTH = 5)  // depth of the queue
           (input  [WL-1:0] in,    // input to the delay line
            input 			 CLK,
				output [WL-1:0] out); //output of the delay line
 
		reg [WL-1:0] delay [1: DEPTH];
		integer i;
 
       always @(posedge CLK) begin
            delay[1] <= in;
            for (i=2; i<=DEPTH; i=i+1)
                  delay[i] <= delay[i-1];
       end 
       
       assign out = delay[DEPTH];
 
endmodule