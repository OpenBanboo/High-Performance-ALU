`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   20:42:35 09/25/2014
// Design Name:   Onthefly
// Module Name:   D:/Synchronous/Graduate Studies/Thesis/Summer2014/RecSqr5/SourceCodes/Division/Onthefly_tb.v
// Project Name:  RecSqr5
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: Onthefly
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module Onthefly_tb;

	// Inputs
	reg CLK;
	reg nRST;
	reg CE;
	reg [2:0] q;
	reg [2:0] q_abs;
	reg [3:0] pointer;

	// Outputs
	wire [23:0] dout;

	// Instantiate the Unit Under Test (UUT)
	Onthefly uut (
		.CLK(CLK), 
		.nRST(nRST), 
		.CE(CE), 
		.q(q), 
		.q_abs(q_abs), 
		.pointer(pointer), 
		.dout(dout)
	);

//=====================================  clock generator  ==========================================//
	parameter ClockPeriod = 2;	// Clock period
	initial 	 CLK = 0;
	always # (ClockPeriod/2) CLK = ~CLK;
//==================================================================================================//
parameter RADIX = 4;

	initial begin
	
		// Initialize Inputs
		nRST = 0; CE = 1;
		q = 0; q_abs = (~q)+1;
		pointer = 0; @(posedge CLK)
		
		nRST = 1; CE = 1; 
		q = 0;  q_abs = (~q)+1; pointer = 0;  @(posedge CLK) //q(1)
		q = 2;  q_abs = (~q)+1; pointer = 1;  @(posedge CLK) //q(2)
		q = -2; q_abs = (~q)+1; pointer = 2;  @(posedge CLK) //q(3)
		q = 0; q_abs = (~q)+1; pointer = 3;   @(posedge CLK) //q(4)
		q = 1;  q_abs = (~q)+1; pointer = 4;  @(posedge CLK) //q(5)
		q = -2;  q_abs = (~q)+1; pointer = 5; @(posedge CLK) //q(6)
		q = 2; q_abs = (~q)+1; pointer = 6;   @(posedge CLK) //q(7)
		q = -1;  q_abs = (~q)+1; pointer = 7; @(posedge CLK) //q(8)
		q = -1; q_abs = (~q)+1; pointer = 8;  @(posedge CLK) //q(9)
		q = -2; q_abs = (~q)+1; pointer = 9;  @(posedge CLK) //q(10)
		q = 1; q_abs = (~q)+1; pointer = 10; @(posedge CLK)  //q(11)
		q = 0; q_abs = (~q)+1; pointer = 11; @(posedge CLK)  //q(12)
      $finish;  
		// Add stimulus here

	end
      
endmodule

