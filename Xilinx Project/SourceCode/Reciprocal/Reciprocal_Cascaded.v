`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////////////////
// Company: 		 VLSI Design and Test Laboratory (E-218) - SDSU
// Engineer: 		 Fang Lin
// 
// Create Date:    12:30:31 05/24/2014 
// Design Name: 	 Fixed-point Reciprocal Calculation using different algorithms
// Module Name:    Reciprocal_NR_DirectImplementation 
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
`define declare_Reciprocal_Cascaded_Jeong     //This module is using the Jeong algorithm
`define declare_Reciprocal_Cascaded_Hung      //This module is using the Hung algorithm
`define declare_Reciprocal_Cascaded_NR        //This module is using the NR algorithm without limit the datapath
`define declare_Reciprocal_Cascaded_NR_2		//This module is using the NR algorithm with the fixed datapath width
`define declare_Reciprocal_Cascaded_ItoNR    	//This module is using the Ito algorithm 
`define declare_Reciprocal_Cascaded_GS	  	//This module is using the GS algorithm (once iteration)
`define declare_Reciprocal_Cascaded_GS_2	  	//This module is using the GS algorithm (zero iteration) 


//========================================================================================
//========================================================================================
// Reciprocal Opearction using cascaded Hung's method with 0 iteration 
// RoundLength must be greater than or equal one
//========================================================================================
//`ifdef declare_Reciprocal_Cascaded_Hung
module Reciprocal_Cascaded_Hung
		// ****************************
		#(parameter WL = 24,				 // World length of the input
						LUT_bits = 24,		 // World length of the Look-up table
						LUT_addWidth = 12, // World length of the Look-up table
						WLO = 24	  			 // World length of the output
		 )
		// IO signal definition
		(
			input CLK, 						// clock signal
			input nRST,						// negative resert signal
			input CE,						// clock enable signal
			input [WL-1:0] din,			// input structure should be 1.23 for 24 bits input
											   // for the single-precision floating-point format mantissa
			output reg [WLO-1:0] dout	// output (1.WF format)
		);

////////////////////////////// ----- Inner wires, registers and memories ----- ///////////////////////////
		reg  [LUT_bits-1 : 0]     LUT 	[2**LUT_addWidth-1 : 0];	// Look-up table memory
		reg  [LUT_bits-1 : 0]	  iniValue;							// initial value selected from LUT
		reg  [LUT_addWidth-1:0]   reg_cmp;							// Part of input used to search in the LUT
		reg  [WL-1:0]	  		  	  xh;								   // Higher parts 
		reg  [WL-1:0]			  	  xl;								   // Lower parts
		reg  [WL-1:0]			  	  Sub;								// Difference between high part and lower part 
		reg  [WL+LUT_bits-1:0]	  Mul;								// temporary result from multiplication
		wire [WLO:0] 			  	  temp_result;						// temporary result 2.WF								
		
////////////////////////////////// ----- Modle Intialization ----- ///////////////////////////////////////

		
// -- Seperate the input x into xh and xl
		always @* begin
			if(~nRST) begin
				xh <= 0;
				xl <= 0;
				Sub <= 0;
				Mul <= 0;
				dout <= 0;
				reg_cmp  <= 0;
				iniValue <= 0;
			end else begin
				if (CE) begin
					reg_cmp  <= din[WL-2 : WL-1-LUT_addWidth];
					iniValue <= LUT[reg_cmp];
					xh[WL-1:WL-(LUT_addWidth+1)] <= din[WL-1:WL-(LUT_addWidth+1)];
					xh[WL-(LUT_addWidth+1)-1:0]	<= 0;
					xl[WL-(LUT_addWidth+1)-1:0] <= din[WL-(LUT_addWidth+1)-1:0];
					xl[WL-1:WL-(LUT_addWidth+1)] <= 0;
					Sub <= xh - xl;
					Mul <= Sub * iniValue;
					dout <= temp_result[WLO-1:0];
				end
			end
		end
		
// -- -- Rounding
		ux_round2nearest 								// Round to nearnest
			#(
				.WordLength(WL+LUT_bits),			// Total length for the variable
				.RoundLength(LUT_bits+WL-WLO-1)  // Wordlength for rounding
			 )
		round_0 
			(
				.CLK(CLK), 								// clock
				.RESET(nRST), 							// negative reset
				.CE(CE), 								// Clock enable
				.x(Mul), 								// input of the rounding module
				.y(temp_result)						// output of the rounding module
			 );
		
endmodule
//`endif		

//========================================================================================
// Reciprocal Opearction using cascaded Jeong's method with 0 iteration 
// RoundLength must be greater than or equal one
//========================================================================================
//`ifdef declare_Reciprocal_Cascaded_Jeong
module Reciprocal_Cascaded_Jeong
		// ****************************
		#(parameter	WL = 24,			// World length of the input
						LUT_bits = 14,		// World length of the Look-up table
						LUT_addWidth = 6,	// World length of the Look-up table
						dWL = 26			// datapath length
		 )
		// IO signal definition
		(
			input CLK, 						// clock signal
			input nRST,						// negative resert signal
			input CE,						// clock enable signal
			input [WL-1:0] din,				// input structure should be 1.23 for 24 bits input
											// for the single-precision floating-point format mantissa
			output[WL-1:0] dout				// output (1.WF format)
		);

////////////////////////////// ----- Inner wires, registers and memories ----- ///////////////////////////
		reg  [LUT_bits-1 : 0]     LUT 	[2**LUT_addWidth-1 : 0];	// Look-up table memory
		reg  [LUT_bits-1 : 0]	  iniValue;							// initial value selected from LUT
		reg  [LUT_addWidth-1:0]   reg_cmp;							// Part of input used to search in the LUT
		reg  [WL-1:0]	  		  xh;								// Higher parts 
		reg  [WL-1:0]			  xl;								// Lower parts
		reg  [WL-1:0]			  Sub;								// Difference between high part and lower part 
		wire [dWL-1:0] 			  mul1_net;
		wire [dWL-1:0] 			  mul2_net;
		reg  [dWL-1:0]			  mul2_net_i;
		wire [dWL*2-1:0]	  	  Mul;								// temporary result from multiplication							
		
////////////////////////////////// ----- Modle Intialization ----- ///////////////////////////////////////
		
// -- Seperate the input x into xh and xl
		always @* begin
			if(~nRST) begin
				reg_cmp <= 0;
				iniValue <= 0;
				xh <= 0;
				xl <= 0;
				Sub <= 0;
				mul2_net_i <= 0;
			end else begin
				if (CE) begin
					reg_cmp  <= din[WL-2 : WL-1-LUT_addWidth];   
					iniValue <= LUT[reg_cmp];							// -- Get the initial value from the look-up table
					xh[WL-1:WL-(LUT_addWidth+1)] <= din[WL-1:WL-(LUT_addWidth+1)];
					xh[WL-(LUT_addWidth+1)-1:0]	<= 0;
					xl[WL-(LUT_addWidth+1)-1:0] <= din[WL-(LUT_addWidth+1)-1:0];
					xl[WL-1:WL-(LUT_addWidth+1)] <= 0;
					Sub <= xh - xl;
					mul2_net_i <= ~mul2_net;
				end
			end
		end

mult_unsigned #(.WI1(1), .WF1(WL-1), .WI2(1), .WF2(LUT_bits-1), .WIO(1), .WFO(dWL-1)) multiplier_1 
				   (.CLK(CLK), .RST(nRST), .in1(Sub), .in2(iniValue), .out(mul1_net));

mult_unsigned #(.WI1(1), .WF1(WL-1), .WI2(1), .WF2(dWL-1), .WIO(1), .WFO(dWL-1)) multiplier_2 
				   (.CLK(CLK), .RST(nRST), .in1(din), .in2(mul1_net), .out(mul2_net));

mult_unsigned #(.WI1(1), .WF1(dWL-1), .WI2(1), .WF2(dWL-1), .WIO(1), .WFO(dWL*2-1)) multiplier_3 
				   (.CLK(CLK), .RST(nRST), .in1(mul1_net), .in2(mul2_net_i), .out(Mul));
				   
// -- -- Rounding
		ux_round2nearest 								// Round to nearnest
			#(
				.WordLength(dWL*2),			// Total length for the variable
				.RoundLength(dWL*2-WL)				// Wordlength for rounding
			 )
		round_Fang
			(
				.CLK(CLK), 								// clock
				.RESET(nRST), 							// negative reset
				.CE(CE), 								// Clock enable
				.x(Mul), 							// input of the rounding module
				.y(dout)								// output of the rounding module
			 );
		
endmodule
//`endif	



		
//========================================================================================
//========================================================================================
// Reciprocal operation using cascaded Newton Raphson method with fixed datapath limitation
// This module is using 0 times iteration
//========================================================================================
//`ifdef declare_Reciprocal_Cascaded_NR_2
module Reciprocal_Cascaded_NR_2
		// ****************************
		#(parameter 	
						WL = 24,					// World length of the input
						LUT_bits = 15,			// World length of the Look-up table
						LUT_addWidth = 12,	// World length of the Look-up table
						dWL = 26,				// datapath bitwidth
						WLO = 25					// World length of the output
		 ) 		
		// IO signal definition
		(
			input CLK, 						// clock signal
			input nRST,						// negative reset signal
			input CE,						// clock enable signal
			input [WL-1:0] din,			// input structure should be 1.23 for 24 bits input
												// for the single-precision floating-point format mantissa
			output[WLO-1:0] dout		   // output
		);
			
////////////////////////////// ----- Inner wires, registers and memories ----- ///////////////////////////
		reg  [LUT_bits-1 : 0]     LUT [2**LUT_addWidth-1 : 0];	// Look-up table memory
		reg  [LUT_bits-1 : 0]	  iniValue;								// initial value selected from LUT
		reg  [LUT_addWidth-1:0]   reg_cmp;								// Part of input used to search in the LUT
		wire [dWL-1 :0]   		  mul1_net;								// Product of the first multiplier
		reg  [dWL-1 :0]   		  mul_1_r;								// bit reverse of the multiplier product
		wire [dWL+LUT_bits-1:0]	  mul2_net;								// Product of the second multiplier
//========================================================================================================


////////////////////////////////// ----- Modle Intialization ----- ///////////////////////////////////////

// -- Main operation
// -- -- 0 Iteration
		always @* begin
			if(~nRST) begin
					reg_cmp <= 0;												// reset
					iniValue <= 0;
					mul_1_r <= 0;
			end
			else begin
				if (CE) begin
					reg_cmp  <= din[WL-2 : WL-1-LUT_addWidth];
					iniValue <= LUT[reg_cmp];								// get the initial value
					mul_1_r <= ~mul1_net; 									// bit reverse of product1
				end // if (CE)
			end // else
		end

mult_unsigned #(.WI1(1), .WF1(WL-1), .WI2(1), .WF2(LUT_bits-1), .WIO(1), .WFO(dWL-1)) multiplier_1 
				   (.CLK(CLK), .RST(nRST), .in1(din), .in2(iniValue), .out(mul1_net));
				   
mult_unsigned #(.WI1(1), .WF1(dWL-1), .WI2(1), .WF2(LUT_bits-1), .WIO(1), .WFO(dWL+LUT_bits-1)) multiplier_2 
				   (.CLK(CLK), .RST(nRST), .in1(mul_1_r), .in2(iniValue), .out(mul2_net));

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
				.x(mul2_net), 							// input of the rounding module
				.y(dout)									// output of the rounding module
			 );
			
//========================================================================================================


//========================================================================================================
endmodule
//`endif


//========================================================================================
//========================================================================================
// Reciprocal operation using cascaded Newton Raphson method
// RoundLength must be greater than or equal one
//========================================================================================
//`ifdef declare_Reciprocal_Cascaded_NR
module Reciprocal_Cascaded_NR
		// ****************************
		#(parameter 	WL = 24,			// World length of the input
						LUT_bits = 10,		// World length of the Look-up table
						LUT_addWidth = 6,	// World length of the Look-up table
						ITERATION = 1		// Signal symbols whether to use Iterating
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
		reg  [LUT_bits-1 : 0]     LUT [2**LUT_addWidth-1 : 0];			// Look-up table memory
		reg  [LUT_bits-1 : 0]	  iniValue;								// initial value selected from LUT
		reg  [LUT_addWidth-1:0]   reg_cmp;								// Part of input used to search in the LUT
		reg  [WL+LUT_bits-1 :0]   mul_1;									// Product of the first multiplier
		reg  [WL+LUT_bits-2 :0]	  mul_1_s;								// normalize mul_1
		reg  [WL+LUT_bits-2 :0]   mul_1_r;								// bit reverse of the multiplier product
		reg  [WL+LUT_bits*2-2 :0] mul_2;									// Product of the second multiplier
		reg  [WL+LUT_bits*2-3 :0] mul_2_s;								// Normalized the product
		wire [WL-1 : 0]			  out_0;									// output before iteration
		wire [WL-1 : 0]			  out_1;									// output after iteration
		reg  [WL*2-1 : 0] 		  mul_3;									// multplier_0 in iteration
		reg  [WL*2-2 : 0] 		  mul_3_r;								// bit reverse of mul_3
		reg  [WL*2-2 : 0]		     mul_3_s;
		reg  [WL*3-2 : 0] 		  mul_4;									// multplier_1 in iteration
		reg  [WL*3-3 : 0] 		  mul_4_s;								// multplier_1 in iteration	 
//========================================================================================================


////////////////////////////////// ----- Modle Intialization ----- ///////////////////////////////////////

// -- Get the initial value from the look-up table
		always @* begin
			reg_cmp  <= din[WL-2 : WL-1-LUT_addWidth];
			iniValue <= LUT[reg_cmp];
		end
// --

// -- Main operation
// -- -- 0 Iteration
		always @* begin
			if(~nRST) begin
				mul_1 <= 0;
				mul_1_r <= 0;
				mul_2 <= 0;
				mul_2_s <= 0;
				mul_3_r <= 0;
				mul_4 <= 0;
			end
			else begin
				if (CE) begin
					mul_1 <= din * iniValue;				// multiply the input and the initial value from the LUT
					mul_1_s <= mul_1[WL+LUT_bits-2 :0];	  	// Normalization	
					mul_1_r <= ~mul_1_s; 					// bit reverse of product1

					mul_2 <= mul_1_r * iniValue;			// The second multiplier
					mul_2_s <= mul_2[WL+LUT_bits*2-3 :0]; 	// Normalization

					mul_3 <= din * out_0;					// multiply in the iteration
					mul_3_s <= mul_3[WL*2-2 : 0]; 
					mul_3_r <= ~mul_3_s;					   // bit reverse of product2
					
					mul_4 <= out_0 * mul_3_r;				// multiply 2 in the iteration
					mul_4_s <= mul_4[WL*3-3 : 0];
				end // if (CE)
			end // else
		end
		
// -- -- Rounding
		ux_round2nearest 								// Round to nearnest
			#(
				.WordLength(WL+LUT_bits*2-2),			// Total length for the variable
				.RoundLength(LUT_bits*2-2)				// Wordlength for rounding
			 )
		round_0 
			(
				.CLK(CLK), 								// clock
				.RESET(nRST), 							// negative reset
				.CE(CE), 								// Clock enable
				.x(mul_2_s), 							// input of the rounding module
				.y(out_0)								// output of the rounding module
			 );
		
		ux_round2nearest 								// Round to nearnest
			#(
				.WordLength(WL*3-2),					// Total length for the variable
				.RoundLength(WL*2-2)					// Word length for rounding
			 )
		round_1 
			(
				.CLK(CLK), 								// clock
				.RESET(nRST), 							// negative reset
				.CE(CE), 								// Clock enable
				.x(mul_4_s), 								// input of the rounding module
				.y(out_1)								// output of the rounding module
			 );		
//========================================================================================================

////////////////////////////////// ----- Output ----- ///////////////////////////////////////

		always @ * begin
			if(~nRST) begin
				dout <= 0;
			end
			else begin
				if (CE) begin
					if (ITERATION==1)
						dout <= out_1;
					else
						dout <= out_0;
				end
			end
		end

//========================================================================================================
endmodule
//`endif



//========================================================================================
//========================================================================================
// Reciprocal Opearction using cascaded GS method with fixed data bitwise (no iteration)
// RoundLength must be greater than or equal one
//========================================================================================
//`ifdef declare_Reciprocal_Cascaded_GS_2	  	//This module is using the GS algorithm (zero iteration) 
module Reciprocal_Cascaded_GS_2
	#(parameter 
				WL = 24,  
				LUT_addWidth = 12, 
				LUT_bits = 15,
				dWL = 27)
		(
			input CLK, nRST,
			input CE,					// clock enable
			input [WL-1:0] din,	    	// input 
			
			output reg [WL-1:0] dout
			
		);
			reg  [LUT_bits-1:0] LUT [2**LUT_addWidth-1:0];
			wire  [dWL-1:0] d1_net, r2_net;	// intermediate variables
			reg	[dWL-1:0] p2;
			wire  [WL-1 :0] tmp_result_1;
			reg   [LUT_addWidth-1:0] reg_cmp;
			reg   [LUT_bits-1:0] iniValue;
///////////////////////// -- prepare for the start of GS algorithm -- ////////////////////////////

	always @ * begin
			if(~nRST) begin
					reg_cmp <= 0;									// reset
					iniValue <= 0;
					p2 <= 0;
			end else begin
				if (CE) begin
					reg_cmp  <= din[WL-2 : WL-1-LUT_addWidth];
					iniValue <= LUT[reg_cmp];
					p2 <= ~d1_net;
					dout <= tmp_result_1;							// Force the temporary tmp_result_1 which format is 2.WL-2 into 1.WL-1 and put out
				end // if (CE)
			end // else	
	end		

mult_unsigned #(.WI1(1), .WF1(LUT_bits-1), .WI2(1), .WF2(WL-1), .WIO(1), .WFO(dWL-1)) multiplier_1 
				   (.CLK(CLK), .RST(RST), .in1(iniValue), .in2(din), .out(d1_net));

///////////////////////////////////iteration 1/////////////////////////////////////////////
mult_unsigned #(.WI1(1), .WF1(LUT_bits-1), .WI2(1), .WF2(dWL-1), .WIO(1),.WFO(dWL-1)) multiplier_2 
				   (.CLK(CLK), .RST(RST), .in1(iniValue), .in2(p2), .out(r2_net));
		
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
//`endif




//========================================================================================
//========================================================================================
// Reciprocal Opearction using cascaded GS method with fixed data bitwise (once iteration)
// RoundLength must be greater than or equal one
//========================================================================================
//`ifdef declare_Reciprocal_Cascaded_GS
module Division_GS_unsigned_rec_24bit
	#(parameter 
				WL = 24, 
				WLO2 = 24, 
				address_bits = 6, 
				LUT_bits = 13,
				dWL = 27)
		(
			input CLK, RST,
			input CE,				// clock enable
			input  [WL-1:0] in,	    // input 
			output reg  [dWL-1:0] d1,p2, d2, d2_s, p3, r3, r2,r2_s,	// intermediate variables

			output [WLO2-1:0] result,
			output reg  [address_bits-1:0] reg_cmp
		);
// -- Inner wires
 wire  [dWL-1:0] d1_net; 
 wire  [dWL-1:0] r2_net;
 wire  [dWL-1:0] d2_net;
 wire  [dWL-1:0] r3_net;

 reg  [LUT_bits-1:0] LUT [2**address_bits-1:0];
 reg  [LUT_bits-1:0] ini,p1,r1;

// -- Get the initial value from the look-up table
	always @* begin
		reg_cmp  <= in[WL-2 : WL-1-address_bits];
		ini <= LUT[reg_cmp];
	end
// --

///////////////////////// -- prepare for the start of GS algorithm -- ////////////////////////////
always @ * begin
	p1 <= ini;
	r1 <= ini;
	d1 <= d1_net;
end
mult_unsigned #(.WI1(1), .WF1(LUT_bits-1), .WI2(1), .WF2(WL-1), .WIO(1), .WFO(dWL-1)) multiplier_1 
				   (.CLK(CLK), .RST(RST), .in1(p1), .in2(in), .out(d1_net));

///////////////////////////////////iteration 1/////////////////////////////////////////////
always @ * p2 = ~d1;
mult_unsigned #(.WI1(1), .WF1(LUT_bits-1), .WI2(1), .WF2(dWL-1), .WIO(1),.WFO(dWL-1)) multiplier_2 
				   (.CLK(CLK), .RST(RST), .in1(r1), .in2(p2), .out(r2_net));
always @ * begin 
	r2 <= r2_net;
	r2_s <= r2; //{r2 [WL+1:0], r2 [WL+2]};
end
mult_unsigned #(.WI1(1), .WF1(dWL-1), .WI2(1), .WF2(dWL-1), .WIO(1), .WFO(dWL-1)) multiplier_3 
					(.CLK(CLK), .RST(RST), .in1(d1), .in2(p2), .out(d2_net));
always @ * begin 
	d2 <= d2_net;
	d2_s <= d2; //{d2 [WL+1:0], d2 [WL+2]};
end

///////////////////////////////////iteration 2//////////////////////////////////////////////
always @ * p3 = ~d2_s;
mult_unsigned #(.WI1(1), .WF1(dWL-1), .WI2(1), .WF2(dWL-1), .WIO(1), .WFO(dWL-1)) multiplier_4
               (.CLK(CLK), .RST(RST), .in1(r2_s), .in2(p3), .out(r3_net));

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
				.x(r3_net), 							// input of the rounding module
				.y(result)								// output of the rounding module
			 );

endmodule
//`endif


//========================================================================================
//========================================================================================
// Reciprocal pipelined Ito(LUT) + Newton Raphson method
// 
//========================================================================================
module Reciprocal_Cascaded_ItoNR
		// ****************************
		#(parameter WL = 24,					// World length of the input
						LUT_bits = 13,			// World length of the Look-up table
						LUT_addWidth = 6,		// World length of the Look-up table
						dWL = 26,
						m = LUT_addWidth + 1
		 ) 		
		// IO signal definition
		(
			input CLK, 							// clock signal
			input nRST,							// negative resert signal
			input CE,							// clock enable signal
			     
			input [WL-1:0] din,				// input structure should be 1.23 for 24 bits input
													// for the single-precision floating-point format mantissa
			output [WL-1:0] dout		// output
		);
		
////////////////////////////// ----- Inner wires, registers and memories ----- ///////////////////////////
		reg  [LUT_bits   : 0]     LUT [2**LUT_addWidth-1 : 0];	// Look-up table memory
		reg  [LUT_bits-1 : 0]	  B1;							// initial value selected from LUT
		reg  [LUT_bits : 0]	  	  B1_real;						// initial value selected from LUT		
		wire [LUT_addWidth-1:0]   reg_cmp;						// Part of input used to search in the LUT
		reg  [WL-1 : 0]			  xHat;
		wire [LUT_bits+2-1 : 0]  iniValue;								// initial value selected from LUT						// initial value selected from LUT
		wire [dWL-1 : 0]  mul2_net;							    // Product of the second multiplier
		reg  [dWL-1 : 0]  mul2_net_r;
		wire [dWL+LUT_bits+2-1 : 0]  Mul;
//========================================================================================================


////////////////////////////////// ----- Modle Intialization ----- ///////////////////////////////////////

// -- Main operation
// -- -- 0 Iteration
		assign reg_cmp = din[WL-2 : WL-1-LUT_addWidth];				// MATLAB LINE 91： addStr = Strp(2:m+1);
		always @* begin
			if(~nRST) begin
					mul2_net_r <= 0;
					B1 <= 0;
					B1_real <= 0;
					xHat <= 0;
			end
			else begin
				if (CE) begin
					B1 <= LUT[reg_cmp];										// -- Get the initial value from the look-up table
					B1_real[LUT_bits-1 : 0] <= B1;
					B1_real[LUT_bits] <= 1'b0;		  						// append the fiest 0 to the initial value from LUT
					xHat[WL-1:WL-m] <=  din[WL-1:WL-m];
					xHat[WL-(m+1):0] <= ~din[WL-(m+1):0];
					mul2_net_r <= ~mul2_net; 			  					// bit reverse of product1
				end // if (CE)
			end // else
		end

mult_unsigned #(.WI1(1), .WF1(WL-1), .WI2(1), .WF2(LUT_bits), .WIO(1), .WFO(LUT_bits+2-1)) multiplier_1 
				   (.CLK(CLK), .RST(nRST), .in1(xHat), .in2(B1_real), .out(iniValue));
				   
mult_unsigned #(.WI1(1), .WF1(WL-1), .WI2(1), .WF2(LUT_bits+2-1), .WIO(1), .WFO(dWL-1)) multiplier_2 
				   (.CLK(CLK), .RST(nRST), .in1(din), .in2(iniValue), .out(mul2_net));
				   
mult_unsigned #(.WI1(1), .WF1(dWL-1), .WI2(1), .WF2(LUT_bits+2-1), .WIO(1), .WFO(dWL+LUT_bits+2-1)) multiplier_3 
				   (.CLK(CLK), .RST(nRST), .in1(mul2_net_r), .in2(iniValue), .out(Mul));
		
// -- -- Rounding
		ux_round2nearest 								// Round to nearnest
			#(
				.WordLength(dWL+LUT_bits+2),		// Total length for the variable
				.RoundLength(dWL+LUT_bits+2 - WL)		// Wordlength for rounding
			 )
		round_0 
			(
				.CLK(CLK), 								// clock
				.RESET(nRST), 							// negative reset
				.CE(CE), 								// Clock enable
				.x(Mul), 							   // input of the rounding module
				.y(dout)								// output of the rounding module
			 );
		
//========================================================================================================

//========================================================================================================
endmodule