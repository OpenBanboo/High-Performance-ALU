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
// On a Xilinx Spartan-6 runs at 477 MHz.

// Revision: 		 2.0: Direct Cascaded Implementation
// Revision 0.01 - File Created
// Additional Comments: 
// 					 1.To measuer the timing. Xilinx requires reg to reg for measuring the clock. 
//

///////////////////////////////////////////////////////////////////////////////////////////
//`define declare_Reciprocal_GS_multicycle			//This module is using the GS algorithm with the fixed datapath width in multicycle
//`define declare_Reciprocal_Jeong_multicycle		//This module is using the Jeong's algorithm with the fixed datapath width in multicycle
`define declare_Reciprocal_NR_multicycle			//This module is using the NR algorithm with the fixed datapath width in multicycle
//`define declare_Reciprocal_Cascaded_interpolat		//This module is using the GS algorithm (zero iteration) 
//========================================================================================


//========================================================================================
// Reciprocal Opearction using cascaded Interpolating method with 0 iteration 
// RoundLength must be greater than or equal one
// This module use the signed mutiplier and adder
//========================================================================================
//`ifdef declare_Reciprocal_Cascaded_interpolat




`ifdef declare_Reciprocal_GS_multicycle
module Reciprocal_GS_multicycle
		#(parameter 
				WL = 24,  
				//LUT_addWidth = 12, 
				//LUT_bits = 15,
				//dWL = 27,
				//ITERATION = 0
				LUT_addWidth = 6, 
				LUT_bits = 13,
				dWL = 27,
				ITERATION = 1
				
		)
		(
			input CLK, nRST,
			input CE,					// clock enable
			input [WL-1:0] din,	    	// input 
			
			output reg [WL-1:0] dout
			
		);
			reg   [LUT_bits-1:0] LUT [2**LUT_addWidth-1:0];
			wire  [dWL-1:0] d1_net, r2_net;	// intermediate variables
			reg	  [dWL-1:0] p2;
			wire  [WL-1 :0] tmp_result_1;
			reg   [WL-1 :0] tmp_result_2;
			reg   [LUT_bits-1 : 0]	  ini;								// initial value selected from LUT
			reg   [WL-1		  : 0]    ini2;								// save the initial value from the LUT into normalised format		
			reg   [LUT_addWidth-1:0] reg_cmp;
			wire  [WL-1:0] iniValue;
			reg   Sel;								// Selection bit of the mutiplexer	
			//reg	[WL-1:0] din_reg;
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
			end else begin
				if (CE) begin
					reg_cmp  <= din[WL-2 : WL-1-LUT_addWidth];  
					ini <= LUT[reg_cmp];								// get the initial value
					ini2[WL-1:WL-LUT_bits] <= ini;
					p2 <= ~d1_net;
				end // if (CE)
			end // else	
	end	
		
multiplexer #(.N(WL)) Sel_input_mux (.a(ini2),.b(tmp_result_2),.Sel(Sel),.out(iniValue));			
			
mult_unsigned #(.WI1(1), .WF1(WL-1), .WI2(1), .WF2(WL-1), .WIO(1), .WFO(dWL-1)) multiplier_1 
				   (.CLK(CLK), .RST(nRST), .in1(iniValue), .in2(din), .out(d1_net));

///////////////////////////////////iteration 1/////////////////////////////////////////////
mult_unsigned #(.WI1(1), .WF1(WL-1), .WI2(1), .WF2(dWL-1), .WIO(1),.WFO(dWL-1)) multiplier_2 
				   (.CLK(CLK), .RST(nRST), .in1(iniValue), .in2(p2), .out(r2_net));

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
				.x(r2_net), 							// input of the rounding module
				.y(tmp_result_1)						// output of the rounding module
			 );	
				   
endmodule
`endif


//========================================================================================
//========================================================================================
// Reciprocal Opearction using Jeong method with multicycle iteration 
// RoundLength must be greater than or equal one
//========================================================================================
`ifdef declare_Reciprocal_Jeong_multicycle
module Reciprocal_Jeong_multicycle

		// ****************************
		#(parameter 	WL = 24,			// World length of the input
						LUT_bits = 18,		// World length of the Look-up table
						LUT_addWidth = 12,	// World length of the Look-up table
						dWL = 35,			// datapath length
						ITERATION = 0		
		 )
		// IO signal definition
		(
			input CLK, 						// clock signal
			input nRST,						// negative resert signal
			input CE,						// clock enable signal
			input [WL-1:0] din,				// input structure should be 1.23 for 24 bits input
											// for the single-precision floating-point format mantissa
			output reg[WL-1:0] dout				// output (1.WF format)
		);
		
////////////////////////////// ----- Inner wires, registers and memories ----- ///////////////////////////
		reg  [LUT_bits-1 : 0]     LUT 	[2**LUT_addWidth-1 : 0];	// Look-up table memory
		reg  [LUT_bits-1 : 0]	  ini;								// initial value selected from LUT
		reg  [WL-1		 :  0]    ini2;								// save the initial value from the LUT into normalised format		
		wire [WL-1 : 0]	  		  iniValue;							// initial value selected from LUT
		reg  [LUT_addWidth-1:0]   reg_cmp;							// Part of input used to search in the LUT
		reg  [WL-1:0]	  		  xh;								// Higher parts 
		reg  [WL-1:0]			  xl;								// Lower parts
		reg  [WL-1:0]			  Sub;								// Difference between high part and lower part 
		wire [dWL-1:0] 			  mul1_net;
		wire [dWL-1:0] 			  mul2_net;
		reg  [dWL-1:0]			  mul2_net_i;
		wire [dWL*2-1:0]	  	  Mul;								// temporary result from multiplication						
		wire [WL-1 :0] 			  tmp_result_1;						// Temporary result form the first iteration		
		reg  [WL-1 :0]			  tmp_result_2;
		reg  					  Sel;								// Selection bit of the mutiplexer		
		
////////////////////////////////// ----- Modle Intialization ----- ///////////////////////////////////////

// -- Main operation
/////////////////////////////////  ----- Controller -----  ////////////////////////////////////////////
integer pointer;

		always @ (CLK) begin
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

// -- Seperate the input x into xh and xl
		always @* begin
			if(~nRST) begin
				reg_cmp <= 0;
				xh <= 0;
				xl <= 0;
				Sub <= 0;
				mul2_net_i <= 0;
				ini <= 0;
				ini2 <= 0;
				//dout <= 0;
			end else begin
				if (CE) begin
					reg_cmp  <= din[WL-2 : WL-1-LUT_addWidth];  
					ini <= LUT[reg_cmp];								// get the initial value
					ini2[WL-1:WL-LUT_bits] <= ini;
					xh[WL-1:WL-(LUT_addWidth+1)] <= din[WL-1:WL-(LUT_addWidth+1)];
					xh[WL-(LUT_addWidth+1)-1:0]	<= 0;
					xl[WL-(LUT_addWidth+1)-1:0] <= din[WL-(LUT_addWidth+1)-1:0];
					xl[WL-1:WL-(LUT_addWidth+1)] <= 0;
					Sub <= xh - xl;
					mul2_net_i <= ~mul2_net;
				end
			end
		end

multiplexer #(.N(WL)) Sel_input_mux (.a(ini2),.b(tmp_result_2),.Sel(Sel),.out(iniValue));
		
mult_unsigned #(.WI1(1), .WF1(WL-1), .WI2(1), .WF2(WL-1), .WIO(1), .WFO(dWL-1)) multiplier_1 
				   (.CLK(CLK), .RST(nRST), .in1(Sub), .in2(iniValue), .out(mul1_net));

mult_unsigned #(.WI1(1), .WF1(WL-1), .WI2(1), .WF2(dWL-1), .WIO(1), .WFO(dWL-1)) multiplier_2 
				   (.CLK(CLK), .RST(nRST), .in1(din), .in2(mul1_net), .out(mul2_net));

mult_unsigned #(.WI1(1), .WF1(dWL-1), .WI2(1), .WF2(dWL-1), .WIO(1), .WFO(dWL*2-1)) multiplier_3 
				   (.CLK(CLK), .RST(nRST), .in1(mul1_net), .in2(mul2_net_i), .out(Mul));		

// -- -- Rounding
		ux_round2nearest 							// Round to nearnest
			#(
				.WordLength(dWL*2),					// Total length for the variable
				.RoundLength(dWL*2-WL)				// Wordlength for rounding
			 )
		round_Fang
			(
				.CLK(CLK), 							// clock
				.RESET(nRST), 						// negative reset
				.CE(CE), 							// Clock enable
				.x(Mul), 							// input of the rounding module
				.y(tmp_result_1)					// output of the rounding module
			 );
		
endmodule
`endif	
				   

`ifdef declare_Reciprocal_NR_multicycle
module Reciprocal_NR_multicycle
//========================================================================================
//========================================================================================
// Reciprocal Opearction using Newton Raphson method with multicycle iteration 
// RoundLength must be greater than or equal one
//========================================================================================
		// ****************************
		#(parameter 	
						WL = 24,			// World length of the input
						LUT_bits = 10,		// World length of the Look-up table
						LUT_addWidth = 6,	// World length of the Look-up table
						dWL = 26,			// datapath bitwidth
						ITERATION = 1
						//WL = 24,			// World length of the input
						//LUT_bits = 15,		// World length of the Look-up table
						//LUT_addWidth = 12,	// World length of the Look-up table
						//dWL = 26,			// datapath bitwidth
						//ITERATION = 0
		 ) 		
		// IO signal definition
		(
			input CLK, 						// clock signal
			input nRST,						// negative reset signal
			input CE,						// clock enable signal
			
			input [WL-1:0] din,				// input structure should be 1.23 for 24 bits input
											// for the single-precision floating-point format mantissa
			output reg [WL-1:0] dout		// output
		);

////////////////////////////// ----- Inner wires, registers and memories ----- ///////////////////////////
		reg  [LUT_bits-1 : 0]     LUT [2**LUT_addWidth-1 : 0];	// Look-up table memory
		reg  [LUT_bits-1 : 0]	  ini;							// initial value selected from LUT
		reg  [WL-1		 :  0]    ini2;							// save the initial value from the LUT into normalised format
		wire [WL-1		 : 0]  	  iniValue;
		reg  [LUT_addWidth-1:0]   reg_cmp;						// Part of input used to search in the LUT
		wire [dWL-1 :0]   		  mul1_net;						// Product of the first multiplier
		reg  [dWL-1 :0]   		  mul_1_r;						// bit reverse of the multiplier product
		wire [dWL*2-1:0]	  	  mul2_net;						// Product of the second multiplier
		wire [WL-1:0]			  tmp_result_1;
		reg  [WL-1:0]			  tmp_result_2;
		reg  					  Sel;							// Selection bit of the mutiplexer
//========================================================================================================


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
					reg_cmp <= 0;											// reset
					ini <= 0;
					ini2 <= 0;
					mul_1_r <= 0;		
			end else begin
				if (CE) begin
					reg_cmp  <= din[WL-2 : WL-1-LUT_addWidth];
					ini <= LUT[reg_cmp];							// get the initial value
					ini2[WL-1:WL-LUT_bits] <= ini;
					mul_1_r <= ~mul1_net; 						// bit reverse of product1
				end // if (CE)
			end // else	
	end

multiplexer #(.N(WL)) mux (.a(ini2),.b(tmp_result_2),.Sel(Sel),.out(iniValue));
		
mult_unsigned #(.WI1(1), .WF1(WL-1), .WI2(1), .WF2(WL-1), .WIO(1), .WFO(dWL-1)) multiplier_1 
				   (.CLK(CLK), .RST(nRST), .in1(din), .in2(iniValue), .out(mul1_net));
				   
mult_unsigned #(.WI1(1), .WF1(dWL-1), .WI2(1), .WF2(WL-1), .WIO(1), .WFO(dWL*2-1)) multiplier_2 
				   (.CLK(CLK), .RST(nRST), .in1(mul_1_r), .in2(iniValue), .out(mul2_net));

// -- -- Rounding
		ux_round2nearest 								// Round to nearnest
			#(									
				.WordLength(dWL*2),					// Total length for the variable
				.RoundLength(dWL*2-WL)				// Wordlength for rounding
			 )
		round_0 
			(
				.CLK(CLK), 								// clock
				.RESET(nRST), 							// negative reset
				.CE(CE), 							  	// Clock enable
				.x(mul2_net), 							// input of the rounding module
				.y(tmp_result_1)						// output of the rounding module
			 );
			 
endmodule
`endif