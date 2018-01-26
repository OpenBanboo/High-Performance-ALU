`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:09:51 09/24/2015 
// Design Name: 
// Module Name:    Square_root_pipe 
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


//========================================================================================
//========================================================================================
// Square root opearction using cascaded Hung's method
// RoundLength must be greater than or equal one
//========================================================================================

module Square_root_pipe
		// ****************************
		#(parameter WL = 24,					// World length of the input
						LUT_bits = 27,			// World length of the Look-up table
						LUT_addWidth = 12,	// World length of the Look-up table
						dWL = 27,				// datapath length
						WLO = 24					// World length of the output
		 ) 		
		// IO signal definition
		(
			input CLK, 						// clock signal
			input nRST,						// negative resert signal
			input CE,						// clock enable signal
			
			input [WL-1:0] din,			// input structure should be 1.23 for 24 bits input
												// for the single-precision floating-point format mantissa
			output [WLO-1:0] dout		// output
		);


////////////////////////////// ----- Inner wires, registers and memories ----- ///////////////////////////
		reg  [LUT_bits-1 : 0]     LUT 	[2**LUT_addWidth-1 : 0];	// Look-up table memory
		reg  [LUT_bits-1 : 0]	  iniValue;						// initial value selected from LUT
		reg  [LUT_addWidth-1:0]   reg_cmp;						// Part of input used to search in the LUT
		reg  [WL-1:0]	  		     xh;								// Higher parts 
		reg  [WL-1:0]			     xl;								// Lower parts
		reg  [WL-1:0]			     xl_s;							// Lower parts shifted right as xl/2
		reg  [WL-1:0]			     Sub;							// Difference between high part and lower part 
		wire [dWL+WL-1:0]			  Mul;
		wire [dWL-1:0] 			  mul1_net;
		reg  [dWL-1:0]				  mul1_reg;
		wire [WLO-1:0]				  dout_tmp;
//========================================================================================================

// -- Get the initial value from the look-up table
		always @ * begin
			reg_cmp  <= din[WL-2 : WL-1-LUT_addWidth];
			iniValue <= LUT[reg_cmp];
		end
// --

// -- Main operation
// -- Seperate the input x into xh and xl
		always @ * begin
			if(~nRST) begin
				xh <= 0;
				xl <= 0;
				Sub <= 0;
				xl_s <= 0;
			end else begin
				if (CE) begin
					xh[WL-1:WL-(LUT_addWidth+1)] <= din[WL-1:WL-(LUT_addWidth+1)];
					xh[WL-(LUT_addWidth+1)-1:0]	<= 0;
					xl[WL-(LUT_addWidth+1)-1:0] <= din[WL-(LUT_addWidth+1)-1:0];
					xl[WL-1:WL-(LUT_addWidth+1)] <= 0;
					xl_s <= xl >> 1;
					Sub <= xh - xl_s;
				end
			end
		end


//	-----------------------------------------------------------------------------------------------------
	localparam PIP_din = 2;
	localparam PIP_result = 1;

mult_unsigned_pipe #(.WI1(1), .WF1(WL-1), .WI2(1), .WF2(LUT_bits-1), .WIO(1), .WFO(dWL-1)) multiplier_1 
				   (.CLK(CLK), .RST(nRST), .in1(Sub), .in2(iniValue), .out(mul1_net));

mult_unsigned_pipe #(.WI1(1), .WF1(WL-1), .WI2(1), .WF2(dWL-1), .WIO(1), .WFO(dWL+WL-1)) multiplier_2 
				   (.CLK(CLK), .RST(nRST), .in1(buffer_din[PIP_din]), .in2(mul1_net), .out(Mul));

// -- -- Rounding
		ux_round2nearest 								// Round to nearnest
			#(
				.WordLength(dWL+WL),		   		// Total length for the variable
				.RoundLength(dWL+WL-WLO)    		// Wordlength for rounding
			 )
		round_Fang 
			(
				.CLK(CLK), 								// clock
				.RESET(nRST), 							// negative reset
				.CE(CE), 								// Clock enable
				.x(Mul), 							   // input of the rounding module
				.y(dout_tmp)									// output of the rounding module
			 );

//========================================================================================================

	reg [WLO-1:0] buffer_result [1: PIP_result];		// 
	reg [WL-1:0] buffer_din [1: PIP_din];

	integer i;
	
	always @(posedge CLK) begin
		if (!nRST) begin
			for (i=1; i<=PIP_result; i=i+1)
				buffer_result[i] <= 0;
				
			for (i=1; i<=PIP_din; i=i+1)
				buffer_din[i] <= 0;
				
		end else begin
			buffer_result[1] <= dout_tmp;
			for (i=2; i<=PIP_result; i=i+1)
				buffer_result[i] <= buffer_result[i-1];
				
			buffer_din[1] <= din;
			for (i=2; i<=PIP_din; i=i+1)
				buffer_din[i] <= buffer_din[i-1];

		end
	end

	assign dout = buffer_result[PIP_result];

//	-----------------------------------------------------------------------------------------------------

endmodule
