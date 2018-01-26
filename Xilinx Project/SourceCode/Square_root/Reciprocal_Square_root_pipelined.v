`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:00:01 09/22/2015 
// Design Name: 
// Module Name:    Reciprocal_Square_root_pipelined 
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
`define declare_Reciprocal_Square_root_pipelined_NR     //This module is using 0 iteration in the NR algorithm

//========================================================================================
//========================================================================================
// Reciprocal Square root opearction using cascaded Newton Raphson method with fixed datapth width
// Using 0 teration
//========================================================================================

// 

`ifdef declare_Reciprocal_Square_root_pipelined_NR
module Reciprocal_Square_root_pipelined_NR
		// ****************************
		#(parameter WL = 24,					// World length of the input
						LUT_bits = 15,			// World length of the Look-up table
						LUT_addWidth = 11,	// World length of the Look-up table
						dWL = WL,				// bitwidth of the datapath
						ITERATION = 0,			// Signal symbols whether to use Iterating
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

	// -- iteration 0
		reg  [LUT_bits-1 : 0]     LUT [2**LUT_addWidth-1 : 0];	// Look-up table memory
		reg  [LUT_bits-1 : 0]	  iniValue;								// initial value selected from LUT
		wire [LUT_bits-1 : 0]	  iniValue_delay;					   // initial value selected from LUT
		wire [WL-1:0]				  din_delay;
		wire [LUT_addWidth-1:0]   reg_cmp;								// Part of input used to search in the LUT
		wire [dWL-1 :0]   		  mul1_net;								// Product of the first multiplier
		wire [dWL-1 :0]   	  	  mul2_net;								// Product of the second multiplier
		wire [dWL+LUT_bits-1 :0]  mul3_net;
		reg  [dWL-1 :0] 		  	  sub_1;							    // Difference between 3 and x*xi^2
		reg  [dWL-1 :0] 		  	  fpThree =  0; 						// Constant 3, bitwith is the same with mul_2_r
		//wire [WL-1 :0] 			  tmp_result_1;							// Temporary result form the first iteration
 
//========================================================================================================

// -- Main operation
// -- -- 0 Iteration

		assign reg_cmp = din[WL-2 : WL-1-LUT_addWidth];				// MATLAB LINE 91： addStr = Strp(2:m+1);


		always @* begin
			if(~nRST) begin
				iniValue <= 0;
				sub_1   <= 0;
				fpThree[dWL-1:dWL-2] <= 2'b11; 						// assign the first two bits as 1
			end else begin
				if (CE) begin
					// -- Get the initial value from the look-up table
					iniValue <= LUT[reg_cmp];
					sub_1 <= fpThree - mul2_net;			  // Acting as 3-x*x*xi^2
					
				end // if (CE)
			end // else
		end


// ------------------------------------------------------------------------
// -- process the reciprocal for the exponential part

	localparam PIP_STAGE_MUL = 2; // the pipeline stage of the pipelined multiplier is 6
	reg [WL-1:0] buffer_din [1: PIP_STAGE_MUL*2];		
	reg [LUT_bits-1 : 0] buffer_iniValue [1: PIP_STAGE_MUL*2];		 
	integer i;

// Buffer stages 

	always @(posedge CLK) begin
		if(!nRST) begin
			//exp_out <= 0;
			for (i=1; i<=PIP_STAGE_MUL*2; i=i+1) begin
				buffer_iniValue[i] <= 0;
				buffer_din[i] <= 0;
			end
		end else begin
			buffer_iniValue[1] <= iniValue;
			buffer_din[1] <= din;
			for (i=2; i<=PIP_STAGE_MUL*2; i=i+1) begin
				buffer_iniValue[i] <= buffer_iniValue[i-1];
				buffer_din[i] <= buffer_din[i-1];
			end
		end 
	end 
	assign din_delay = buffer_din[PIP_STAGE_MUL];
	assign iniValue_delay = buffer_iniValue[PIP_STAGE_MUL*2];

mult_unsigned_pipe #(.WI1(1), .WF1(LUT_bits-1), .WI2(1), .WF2(LUT_bits-1), .WIO(2), .WFO(dWL-2)) multiplier_1 
				   (.CLK(CLK), .RST(nRST), .in1(iniValue), .in2(iniValue), .out(mul1_net));		

mult_unsigned_pipe #(.WI1(2), .WF1(dWL-2), .WI2(1), .WF2(WL-1), .WIO(2), .WFO(dWL-2)) multiplier_2 
				   (.CLK(CLK), .RST(nRST), .in1(mul1_net), .in2(din_delay), .out(mul2_net));				   

mult_unsigned_pipe #(.WI1(2), .WF1(dWL-2), .WI2(1), .WF2(LUT_bits-1), .WIO(2), .WFO(dWL+LUT_bits-2)) multiplier_3
				   (.CLK(CLK), .RST(nRST), .in1(sub_1), .in2(iniValue_delay), .out(mul3_net));	// notice that the WIO = 2 is inorder to avoid using the shifting
				   
// -- -- Rounding
		ux_round2nearest 								// Round to nearnest
			#(
				.WordLength(dWL+LUT_bits),			// Total length for the variable
				.RoundLength(dWL+LUT_bits-WLO)	// Wordlength for rounding
			 )
		round_0 
			(
				.CLK(CLK), 								// clock
				.RESET(nRST), 							// negative reset
				.CE(CE), 								// Clock enable
				.x(mul3_net), 							// input of the rounding module
				.y(dout)									// output of the rounding module
			 );

//========================================================================================================
endmodule
`endif
