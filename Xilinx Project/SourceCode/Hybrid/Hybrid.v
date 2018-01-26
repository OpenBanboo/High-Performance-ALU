`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:27:57 08/24/2014 
// Design Name: 
// Module Name:    Hybrid 
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
module Hybrid
		#(	parameter WL = 24,				// word length of the input
						 LUT_bits = 26,		// word length of a certain element of the LUT
						 LUT_addWidth = 11,	// address length of the LUT
						 dWL = 27,				// word length of the datapath
						 p = 1,					// degree number of the interpolating
						 LUT_capacity = 2**(LUT_addWidth+p)
		 )
		(
			input CLK, nRST,					// clock and negative reset
			input CE,							// clock enable
			input [WL-1:0] din,	    		// input
			input [1:0]	FUNCTION,			// 0: reciprocal, 1: sqrt, 2: isqt 
			output reg [WL-1:0] dout		// output
		);		 
		
////////////////////////////// ----- Inner wires, registers and memories ----- ///////////////////////////
		reg  [LUT_bits-1 : 0]     LUT_rec 	[LUT_capacity-1 : 0];			// Look-up table memory	for reciprocal	
		reg  [LUT_bits-1 : 0]	  LUT_sqrt  [LUT_capacity-1 : 0];			// Look-up table memory for square root
		reg  [LUT_bits-1 : 0]	  LUT_isqt  [LUT_capacity-1 : 0];			// Look-up table memory for reciprocal square root


		reg  [LUT_bits-1 : 0]	  iniValue;										// initial value 1 selected from LUT
		reg  [LUT_addWidth:0]     reg_cmp;							// Part of input used to search in the LUT		 			
		reg  [dWL-1:0] oneFP =  0; 									// Constant 3, bitwith is the same with mul_2_r
		reg  [dWL-1:0] xopow;
		wire [dWL-1:0] xopow_wire;
		wire [dWL-1:0] xopow_net;
		wire [dWL-1:0] ini_net;
		wire [dWL-1:0] mul2_net;
		reg  [dWL-1:0] ini = 0;											// initial value
		wire [dWL-1:0] input_mul1;										// the input value of the first multiplier
		wire  [WL-1:0]  tmp_result;										// temporary result from the rounding module
		reg  [dWL-1:0] iniFP;											// used to save the initial value for every interpolation 
		reg  [WL-LUT_addWidth-1:0] xo;								// rare part of the input 
		reg	Sel;
////////////////////////////////// ----- Modle Intialization ----- ///////////////////////////////////////
integer pointer;		
// -- Seperate the input x into xh and xl

		always @ (posedge CLK) begin
			if(~nRST) begin
					Sel <= 1'b0;
					pointer <= 0;
					ini <= 0;
					iniFP <= 0;
			end
			else begin
				if (CE) begin
					xopow <= xopow_net;
					if (pointer == p) begin
						//dout <= ini_net;
						dout <= tmp_result;
						pointer <= 0;
						Sel <= 1'b0;
						ini <= 0;
					end else begin
						pointer <= pointer + 1;
						Sel <= 1'b1;
						ini <= ini_net;
					end
				end // if (CE)
			end // else
		end	

		always @* begin
			if(~nRST) begin
				reg_cmp <= 0;
				iniValue <= 0;
				oneFP[dWL-2] <= 1'b1;									// assign the first two bits as 1
				xo <= 0;
			end else begin
				if (CE) begin
					reg_cmp  <= din[WL-2-1 : WL-1-LUT_addWidth-1];
					if (FUNCTION == 2'b00)
						iniValue <= LUT_rec[reg_cmp + pointer*(2**LUT_addWidth)];		// -- Get the initial value from the reciprocal look-up table
					else if (FUNCTION == 2'b01)
						iniValue <= LUT_sqrt[reg_cmp + pointer*(2**LUT_addWidth)];		// -- Get the initial value from the square root look-up table
					else
						iniValue <= LUT_isqt[reg_cmp + pointer*(2**LUT_addWidth)];		// -- Get the initial value from the reciprocal square root look-up table
					
					xo <= din[WL-2-LUT_addWidth-1:0];											// -- Get the lower part
				end
			end
		end		

multiplexer #(.N(dWL)) Sel_input_mux (.a(oneFP),.b(xopow),.Sel(Sel),.out(input_mul1));	

sMult #(.WI1(2), .WF1(WL-LUT_addWidth-2), .WI2(2), .WF2(dWL-2), .WIO(2), .WFO(dWL-2)) multiplier_1 
				   (.CLK(CLK), .RST(nRST), .in1(xo), .in2(input_mul1), .out(xopow_net));		
					
sMult #(.WI1(2), .WF1(LUT_bits-2), .WI2(2), .WF2(dWL-2), .WIO(2), .WFO(dWL-2)) multiplier_2 
				   (.CLK(CLK), .RST(nRST), .in1(iniValue), .in2(input_mul1), .out(mul2_net));

sAdd 		#(	.WI1(2), 		//	length of the integer part, operand 1
				.WF1(dWL-2), 	//	length of the fraction part, operand 1
				.WI2(2), 		//	length of the integer part, operand 2
				.WF2(dWL-2),	//	length of the fraction part, operand 2
				.WIO(2), 		//	default length for the integer part of the required output
				.WFO(dWL-2)) 	Fang_fixed_adder 
			 ( .CLK(CLK), .RST(nRST), .in1(mul2_net), .in2(ini), .out(ini_net));



// -- -- Round to nearst

	ux_round2nearest 								// Round to nearnest
		#(
			.WordLength(dWL),						// Total length for the variable
			.RoundLength(dWL-WL)					// Wordlength for rounding
		 )
	Fang_round 
		(
			.CLK(CLK), 								// clock
			.RESET(RST), 							// negative reset
			.CE(CE), 								// Clock enable
			.x(ini_net), 							// input of the rounding module
			.y(tmp_result)							// output of the rounding module
		 );	

	
endmodule