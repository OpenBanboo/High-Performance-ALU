`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////////////////
// Company: 		 VLSI Design and Test Laboratory (E-218) - SDSU
// Engineer: 		 Fang Lin
// 
// Create Date:    12:30:31 05/24/2014 
// Design Name: 	 Fixed-point Reciprocal Calculation using Different algorithms
// Module Name:    Reciprocal_Multicicle
// Project Name:   Architectural Design Space Exploration of Reciprocal and Square
//						 Root for Singl-Precision Floating-Poin Arithmetic
// Target Devices: Xilinx family
// Tool versions:  ISE 14.6

// Description: 	 
//						 This design is created for evaluating and veryfying the Floating-
//						 point reciprocal operation using 
// Dependencies: 
//						 The input of this module is fixed as 1.x sturcture as the same 
//						 with the mantissa part of Single-Precision Floating-point format
//						 This module can be used to explored into parametric Fixed-point
//						 and Floating point stucture in the future.

// Clock Frequency:
// On a Xilinx Virtex 
//		Square_Root_Reciprocal_NR_multicycle runs at 91.156 MHz.
//		Square_Root_Reciprocal_GS_multicycle runs at 

// Revision: 		 2.0: Direct Cascaded Implementation
// Revision 0.01 - File Created
// Additional Comments: 
// 					 1.To measuer the timing. Xilinx requires reg to reg for measuring the clock. 
//
///////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////////
`define declare_Square_Root_Reciprocal_NR_multicycle			//This module is using the NR algorithm with the fixed datapath width
//`define declare_Square_Root_Reciprocal_GS_multicycle			//This module is using the GS algorithm with the fixed datapath width

`ifdef declare_Square_Root_Reciprocal_GS_multicycle
module Square_Root_Reciprocal_GS_multicycle
		// ****************************
		#(parameter WL = 24,				// World length of the input
						//LUT_bits = 11,			// World length of the Look-up table
						//LUT_addWidth = 6,		// World length of the Look-up table
						//dWL = 26,
						//ITERATION = 1,
						LUT_bits = 15,			// World length of the Look-up table
						LUT_addWidth = 12,		// World length of the Look-up table
						dWL = 26,
						ITERATION = 0,
						m = LUT_addWidth + 1
						
		 ) 		
		// IO signal definition
		(
			input CLK, 							// clock signal
			input nRST,							// negative resert signal
			input CE,							// clock enable signal
			     
			input [WL-1:0] din,				// input structure should be 1.23 for 24 bits input
													// for the single-precision floating-point format mantissa
			output reg [WL-1:0] dout		// output
		);	

			reg   [LUT_bits-1:0] LUT [2**LUT_addWidth-1:0];
			wire  [dWL-1:0] d1_net, r2_net;	// intermediate variables
			reg	  [dWL-1:0] p2;
			wire  [dWL-1:0] d2;
			reg   [dWL-1:0] d2_s;							// right shift of d2 as d2/2
			reg   [dWL-1:0] onep5FP =  0; 				// Constant 3, bitwith is the same with mul_2_r
			wire  [dWL-1:0] r2;
			wire  [WL-1 :0] tmp_result_1;
			reg   [WL-1 :0] tmp_result_2;
			reg   [LUT_bits-1 : 0]	  ini;								// initial value selected from LUT
			reg   [WL-1		  : 0]    ini2;								// save the initial value from the LUT into normalised format		
			reg   [LUT_addWidth-1:0] reg_cmp;
			wire  [WL-1:0] iniValue;
			reg   Sel;								// Selection bit of the mutiplexer			

////////////////////////////////// ----- Modle Intialization ----- ///////////////////////////////////////

// -- Main operation
/////////////////////////////////  ----- Controller -----  ////////////////////////////////////////////
integer pointer;

		always @ (posedge CLK) begin
			if(~nRST) begin
					Sel <= 1'b0;
					pointer <= 0;
			end
			else begin
				if (CE) begin
					tmp_result_2 <= tmp_result_1;				// save the temporary result used for iterating
					if (pointer == ITERATION) begin
						dout <= tmp_result_1;
						pointer <= 0;
						Sel <= 1'b0;
					end else begin
						pointer <= pointer + 1;
						Sel <= 1'b1;
					end
				end // if (CE)
			end // else
		end		

	always @ * begin
			if(~nRST) begin
					reg_cmp <= 0;									// reset
					p2 <= 0;
					ini <= 0;
					ini2 <= 0;
					p2 <= 0;
					d2_s <= 0;
					onep5FP[dWL-1:dWL-2] <= 2'b11;	// assign the first two bits as 1
			end else begin
				if (CE) begin
					reg_cmp  <= din[WL-2 : WL-1-LUT_addWidth];  
					ini <= LUT[reg_cmp];								// get the initial value
					ini2[WL-1:WL-LUT_bits] <= ini;
					d2_s <= d2 >> 1;
					p2 <= onep5FP - d2_s;
				end // if (CE)
			end // else	
	end	

	multiplexer #(.N(WL)) Sel_input_mux (.a(ini2),.b(tmp_result_2),.Sel(Sel),.out(iniValue));	
	
    mult_unsigned #(.WI1(1), .WF1(WL-1), .WI2(1), .WF2(WL-1), .WIO(1), .WFO(dWL-1)) multiplier_1 
				   (.CLK(CLK), .RST(nRST), .in1(iniValue), .in2(din), .out(d1_net));

    mult_unsigned #(.WI1(1), .WF1(WL-1), .WI2(1), .WF2(dWL-1), .WIO(1), .WFO(dWL-1)) multiplier_2 
				   (.CLK(CLK), .RST(nRST), .in1(iniValue), .in2(d1_net), .out(d2));
	
    mult_unsigned #(.WI1(1), .WF1(WL-1), .WI2(1), .WF2(dWL-1), .WIO(1), .WFO(dWL-1)) multiplier_4 
				   (.CLK(CLK), .RST(nRST), .in1(iniValue), .in2(p2), .out(r2));	

// -- -- Rounding
	ux_round2nearest 								// Round to nearnest
		#(
			.WordLength(dWL),						// Total length for the variable
			.RoundLength(dWL-WL)					// Wordlength for rounding
		 )
	round_0 
		(
			.CLK(CLK), 								// clock
			.RESET(RST), 							// negative reset
			.CE(CE), 								// Clock enable
			.x(r2), 							    // input of the rounding module
			.y(tmp_result_1)						// output of the rounding module
		 );	
			   
endmodule
`endif

//========================================================================================
//========================================================================================
// Reciprocal Opearction using Newton Raphson method with multicycle iteration 
// RoundLength must be greater than or equal one
//========================================================================================
`ifdef declare_Square_Root_Reciprocal_NR_multicycle
module Square_Root_Reciprocal_NR_multicycle

		// ****************************
		#(parameter 	
					
						WL = 24,					// World length of the input
						LUT_bits = 11,			// World length of the Look-up table
						LUT_addWidth = 6,		// World length of the Look-up table
						dWL = 26,				// datapath bitwidth
						ITERATION = 1
					
					/*
					WL = 24,
						LUT_bits = 15,
						LUT_addWidth = 11,
						dWL = 29,
						ITERATION = 0
					*/
		 )
		// IO signal definition
		(
			input CLK, 						// clock signal
			input nRST,						// negative resert signal
			input CE,						// clock enable signal
			
			input [WL-1:0] din,			// input structure should be 1.23 for 24 bits input
												// for the single-precision floating-point format mantissa
			output reg [WL-1:0] dout	// output
		);
////////////////////////////// ----- Inner wires, registers and memories ----- ////////////////////////////
		reg  [LUT_bits-1 : 0]     LUT [2**LUT_addWidth-1 : 0];	// Look-up table memory
		reg  [LUT_bits-1 : 0]	  ini;									// initial value selected from LUT
		reg  [WL-1		 :  0]    ini2;									// save the initial value from the LUT into normalised format
		wire [WL-1		 : 0]  	  iniValue;
		reg  [LUT_addWidth-1:0]   reg_cmp;								// Part of input used to search in the LUT	
		wire [dWL-1 :0]   		  mul1_net;								// Product of the first multiplier
		wire [dWL-1 :0]   		  mul2_net;								// Product of the second multiplier
		wire [dWL+LUT_bits-1 :0]  mul3_net;		
		reg  [dWL-1 :0] 		  sub_1;							    	// Difference between 3 and x*xi^2
		reg  [dWL-1 :0] 		  fpThree =  0; 						// Constant 3, bitwith is the same with mul_2_r
		wire [WL-1 :0] 			  tmp_result_1;						// Temporary result form the first iteration		
		reg  [WL-1:0]			  tmp_result_2;
		reg  					  	  	  Sel;									// Selection bit of the mutiplexer
///////////////////////////////////////////////////////////////////////////////////////////////////////////		
// -- Main operation
/////////////////////////////////  ----- Controller -----  ////////////////////////////////////////////
integer pointer;

	always @ (posedge CLK) begin
		if(~nRST) begin
				Sel <= 1'b0;
				pointer <= 0;
		end
		else begin
			if (CE) begin
				tmp_result_2 <= tmp_result_1;				// save the temporary result used for iterating
				if (pointer == ITERATION) begin
					dout <= tmp_result_1;
					pointer <= 0;
					Sel <= 1'b0;
				end else begin
					pointer <= pointer + 1;
					Sel <= 1'b1;
				end
			end // if (CE)
		end // else
	end

	always @ * begin
			if(~nRST) begin
					reg_cmp <= 0;									// reset
					ini <= 0;
					ini2 <= 0;
					sub_1   <= 0;
					fpThree[dWL-1:dWL-2] <= 2'b11; 					// assign the first two bits as 1
			end else begin
				if (CE) begin
					reg_cmp  <= din[WL-2 : WL-1-LUT_addWidth];
					ini <= LUT[reg_cmp];							// get the initial value
					ini2[WL-1:WL-LUT_bits] <= ini;
					sub_1 <= fpThree - mul2_net;			  		// Acting as 3-x*x*xi^2
					// -- currently, the register format is 2.WL-2, next step is to change it into 1.WL-1
				end // if (CE)
			end // else	
	end		

multiplexer #(.N(WL)) Sel_input_mux (.a(ini2),.b(tmp_result_2),.Sel(Sel),.out(iniValue));
	
mult_unsigned #(.WI1(1), .WF1(WL-1), .WI2(1), .WF2(WL-1), .WIO(2), .WFO(dWL-2)) multiplier_1 
				   (.CLK(CLK), .RST(nRST), .in1(iniValue), .in2(iniValue), .out(mul1_net));		

mult_unsigned #(.WI1(2), .WF1(dWL-2), .WI2(1), .WF2(WL-1), .WIO(2), .WFO(dWL-2)) multiplier_2 
				   (.CLK(CLK), .RST(nRST), .in1(mul1_net), .in2(din), .out(mul2_net));				   

mult_unsigned #(.WI1(2), .WF1(dWL-2), .WI2(1), .WF2(WL-1), .WIO(2), .WFO(dWL+LUT_bits-2)) multiplier_3
				   (.CLK(CLK), .RST(nRST), .in1(sub_1), .in2(iniValue), .out(mul3_net));			
		
// -- -- Rounding
		ux_round2nearest 								// Round to nearnest
			#(
				.WordLength(dWL+LUT_bits),				// Total length for the variable
				.RoundLength(dWL+LUT_bits-WL)			// Wordlength for rounding
			 )
		Fang_rounding 
			(
				.CLK(CLK), 								// clock
				.RESET(nRST), 							// negative reset
				.CE(CE), 								// Clock enable
				.x(mul3_net), 							// input of the rounding module
				.y(tmp_result_1)						// output of the rounding module
			 );

//========================================================================================================
endmodule
`endif		
		
		