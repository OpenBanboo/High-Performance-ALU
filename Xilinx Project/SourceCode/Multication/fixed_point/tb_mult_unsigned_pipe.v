`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   13:26:10 11/01/2014
// Design Name:   mult_unsigned_pipe
// Module Name:   D:/Synchronous/Graduate Studies/Thesis/Summer2014/RecSqr5/SourceCodes/tb_mult_unsigned_pipe.v
// Project Name:  RecSqr5
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: mult_unsigned_pipe
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_mult_unsigned_pipe;

	parameter WI1 = 1, 		//length of the integer part, operand 1
				 WF1 = 5, 		//length of the fraction part, operand 1
				 WI2 = 1, 		//length of the integer part, operand 2
				 WF2 = 6,		//length of the fraction part, operand 2
				 WIO = 2, 		//default length for the integer part of the required output
				 WFO = 15,	 	//default length of the fraction part of the required output
				 PIP = 1;		//number of pipeline stages

	// Inputs
	reg CLK;
	reg RST;
	reg [WI1+WF1-1:0] in1;
	reg [WI2+WF2-1:0] in2;

	// Outputs
	wire [WIO+WFO-1:0] out;

// ================================  Function Definition  =======================================//
	// Present the fixed point number into real number
	function real unsigned_fixedToFloat;
		input [2047:0] in;	//should cover every bit of the maximal value
		input integer WI;
		input integer WF;
		integer idx;
		real retVal;
		begin
			retVal = 0;
			for (idx = 0; idx < WI+WF; idx = idx + 1) begin
				if(in[idx] == 1'b1) begin
					retVal = retVal + (2.0**(idx-WF));
				end
			end
		unsigned_fixedToFloat = retVal;
		end
	endfunction
//==================================================================================================//	

//=====================================  clock generator  ==========================================//
	parameter ClockPeriod = 2;	// Clock period
	initial 	 CLK = 0;
	always # (ClockPeriod/2) CLK = ~CLK;
//==================================================================================================//

	// Instantiate the Unit Under Test (UUT)
	mult_unsigned_pipe 
	#(
		.WI1(WI1), 		//length of the integer part, operand 1
		.WF1(WF1), 		//length of the fraction part, operand 1
		.WI2(WI2), 		//length of the integer part, operand 2
		.WF2(WF2),		//length of the fraction part, operand 2
		.WIO(WIO), 		//default length for the integer part of the required output
		.WFO(WFO),	 	//default length of the fraction part of the required output
		.PIP(PIP)		//number of pipeline stages
	)
	uut 
	(
		.CLK(CLK), 
		.RST(RST), 
		.in1(in1), 
		.in2(in2), 
		.out(out)
	);

	// Real number presentation
	real real_in1, real_in2, real_out;

	initial begin
		// Initialize Inputs
		RST = 0; @(posedge CLK); RST = 1; 
		in1 = 6'b1_00000; in2 = 7'b1_100000; @(posedge CLK);
		in1 = 6'b1_11000; in2 = 7'b1_110000; @(posedge CLK);
		in1 = 6'b1_11100; in2 = 7'b1_010000; @(posedge CLK);
		@(posedge CLK); @(posedge CLK); @(posedge CLK); $finish;
	end
	
	// -- input -- //
	always @ in1 real_in1 = unsigned_fixedToFloat(in1, WI1, WF1);
	always @ in2 real_in2 = unsigned_fixedToFloat(in2, WI2, WF2);
	always @ out real_out = unsigned_fixedToFloat(out, WIO, WFO);      
endmodule

