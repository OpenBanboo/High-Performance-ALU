`timescale 1ns/1ps
/////////////////////////////////////////////////////////////////////
// This module used for inversing every bit of a register input

module bitInv 
	#(parameter N = 8)
	(
		input [N-1:0] din,
		output [N-1:0] out
	);
	
	assign out = ~din;

endmodule