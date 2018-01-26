`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////////////////
// Company: 		 VLSI Design and Test Laboratory (E-218) - SDSU
// Engineer: 		 Fang Lin
// 
// Create Date:    12:30:31 05/24/2014 
// Design Name: 	 Fixed-point Square Root Reciprocal Calculation using Newton Raphson method
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
`define declare_Square_Root_Reciprical_Ito    			//This module is using 1 iteration in the Ito algorithm
`define declare_Square_Root_Hung    			  				//This module is using 0 iteration in the Hung algorithm
`define declare_Square_Root_Reciprocal_Cascaded_NR     //This module is using 1 iteration in the NR algorithm
`define declare_Square_Root_Reciprocal_Cascaded_NR_2     //This module is using 0 iteration in the NR algorithm
`define declare_Square_Root_Reciprocal_Cascaded_GS     //This module is using 0 iteration in the GS algorithm
`define declare_declare_Square_Root_pipe
`define declare_Square_Root_Reciprical_Ito_Pipe


//========================================================================================
//========================================================================================
// Square root opearction using cascaded Newton Raphson method with fixed datapth width
// Using 0 teration
//========================================================================================

`ifdef declare_Square_Root_Reciprocal_Cascaded_NR_2
module Square_Root_Reciprocal_Cascaded_NR_2
		// ****************************
		#(parameter WL = 24,					// World length of the input
						LUT_bits = 15,			// World length of the Look-up table
						LUT_addWidth = 11,	// World length of the Look-up table
						dWL = 29,				// bitwidth of the datapath
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
			output [WLO-1:0] dout	// output
		);
	
////////////////////////////// ----- Inner wires, registers and memories ----- ///////////////////////////

	// -- iteration 0
		reg  [LUT_bits-1 : 0]     LUT [2**LUT_addWidth-1 : 0];	// Look-up table memory
		reg  [LUT_bits-1 : 0]	  iniValue;								// initial value selected from LUT
		reg  [LUT_addWidth-1:0]   reg_cmp;								// Part of input used to search in the LUT
		wire [dWL-1 :0]   		  mul1_net;								// Product of the first multiplier
		wire [dWL-1 :0]   		  mul2_net;								// Product of the second multiplier
		wire [dWL+LUT_bits-1 :0]  mul3_net;
		reg  [dWL-1 :0] 		  	  sub_1;							    // Difference between 3 and x*xi^2
		reg  [dWL-1 :0] 		  	  fpThree =  0; 						// Constant 3, bitwith is the same with mul_2_r
		//wire [WL-1 :0] 			  tmp_result_1;							// Temporary result form the first iteration
 
//========================================================================================================

// -- Main operation
// -- -- 0 Iteration

		always @* begin
			if(~nRST) begin
				reg_cmp <= 0;
				iniValue <= 0;
				sub_1   <= 0;
				fpThree[dWL-1:dWL-2] <= 2'b11; 						// assign the first two bits as 1
			end else begin
				if (CE) begin
					// -- Get the initial value from the look-up table
					reg_cmp  <= din[WL-2 : WL-1-LUT_addWidth];
					iniValue <= LUT[reg_cmp];
					
					sub_1 <= fpThree - mul2_net;			  // Acting as 3-x*x*xi^2
					// -- currently, the register format is 2.WL-2, next step is to change it into 1.WL-1
					//dout <= tmp_result_1;					// Force the temporary tmp_result_1 which format is 2.WL-2 into 1.WL-1 and put out
					
				end // if (CE)
			end // else
		end

mult_unsigned #(.WI1(1), .WF1(LUT_bits-1), .WI2(1), .WF2(LUT_bits-1), .WIO(2), .WFO(dWL-2)) multiplier_1 
				   (.CLK(CLK), .RST(nRST), .in1(iniValue), .in2(iniValue), .out(mul1_net));		

mult_unsigned #(.WI1(2), .WF1(dWL-2), .WI2(1), .WF2(WL-1), .WIO(2), .WFO(dWL-2)) multiplier_2 
				   (.CLK(CLK), .RST(nRST), .in1(mul1_net), .in2(din), .out(mul2_net));				   

mult_unsigned #(.WI1(2), .WF1(dWL-2), .WI2(1), .WF2(LUT_bits-1), .WIO(2), .WFO(dWL+LUT_bits-2)) multiplier_3
				   (.CLK(CLK), .RST(nRST), .in1(sub_1), .in2(iniValue), .out(mul3_net));	// notice that the WIO = 2 is inorder to avoid using the shifting
				   
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


//========================================================================================
//========================================================================================
// Square root reciprocal opearction using cascaded Ito's method
// RoundLength must be greater than or equal one
//========================================================================================

`ifdef declare_Square_Root_Reciprical_Ito //This module is using 0 iteration in the Hung algorithm
module Square_Root_Reciprocal_Ito_Iter1
		// ****************************
		#(parameter     
						WL = 24,						// World length of the input
						LUT_bits = 13,				// World length of the Look-up table
						LUT_addWidth = 6,			// World length of the Look-up table
						dWL = 28,					// datapath length
						m = LUT_addWidth + 1,	// parameter in MATLAB
						WLO = 24
		 ) 		
		// IO signal definition
		(
			input CLK, 								// clock signal
			input nRST,								// negative resert signal
			input CE,								// clock enable signal
			
			input [WL-1:0] din,				// input structure should be 1.23 for 24 bits input
											// for the single-precision floating-point format mantissa
			output reg [WLO-1:0] dout		// output
		);

////////////////////////////// ----- Inner wires, registers and memories ----- ///////////////////////////
		reg  [LUT_bits-1 : 0]     		LUT 	[2**LUT_addWidth-1 : 0];	// Look-up table memory
		reg  [LUT_bits :   0]	  		D1;											// initial value selected from LUT
		wire [LUT_bits+3-1 : 0]	  		iniValue;						    		// initial value
		wire [dWL-1 : 0]	  	  	  		iniValue2;								// Square of the initial value
		wire [dWL-1 : 0]	  	  	  		iniValue3;						
		wire [dWL+LUT_bits+3-1 : 0] 	iniValue4;											
		reg  [LUT_addWidth-1:0]   		reg_cmp;									// Part of input used to search in the LUT
		reg  [WL : 0]			  	  		xHat;
		reg  [dWL-1 : 0] 		  	  		fpThree =  0; 							// Constant 3
		reg  [dWL-1 : 0] 		  	  		Sub;										// temporary result 2.WF								
		wire [WLO  :0] 		  	  		Mul;
		reg  [WLO  :0] 		  	  		Mul_s;
//========================================================================================================

// -- Main operation
// -- Seperate the input x into xh and xl
		always @* begin
			if(~nRST) begin
				reg_cmp  <= 0;
				xHat <= 0;
				D1   <= 0;
				fpThree[dWL-1:dWL-2] <= 2'b11; 						// assign the first two bits as 1
			end else begin
				if (CE) begin
					reg_cmp  <= din[WL-2 : WL-1-LUT_addWidth];
					D1[LUT_bits] <= 1'b0; 
					D1[LUT_bits-1:0] <= LUT[reg_cmp];
					xHat[WL: WL-(m-1)] <= din[WL-1: WL-m];			// Stru(1:m)     = Str(1:m);
					xHat[WL-m]	 	   <= ~din[WL-(m+1)];			// if (Str(m+1)=='0') Stru(m+1) = '1'; else Stru(m+1) = '0'; end
					xHat[WL-(m+1)]	 <= din[WL-(m+1)];				// tru(m+2) = Str(m+1);  
					xHat[WL-(m+2):0] <= ~din[WL-(m+2):0];				
					Sub <= fpThree - iniValue3;
					Mul_s <= Mul >> 1;									// Shifting right 1 unit for executing *0.5 
					dout <= Mul_s[WLO-1:0];
				end
			end
		end
		
mult_unsigned #(.WI1(1), .WF1(WL), .WI2(1), .WF2(LUT_bits), .WIO(2), .WFO(LUT_bits+3-2)) multiplier_1 
				   (.CLK(CLK), .RST(nRST), .in1(xHat), .in2(D1), .out(iniValue));

mult_unsigned #(.WI1(2), .WF1(LUT_bits+3-2), .WI2(2), .WF2(LUT_bits+3-2), .WIO(2), .WFO(dWL-2)) multiplier_2 
				   (.CLK(CLK), .RST(nRST), .in1(iniValue), .in2(iniValue), .out(iniValue2));

mult_unsigned #(.WI1(1), .WF1(WL-1), .WI2(2), .WF2(dWL-2), .WIO(2), .WFO(dWL-2)) multiplier_3 
				   (.CLK(CLK), .RST(nRST), .in1(din), .in2(iniValue2), .out(iniValue3));
				   
mult_unsigned #(.WI1(2), .WF1(LUT_bits+3-2), .WI2(2), .WF2(dWL-2), .WIO(2), .WFO(dWL+LUT_bits+3-2)) multiplier_4 
				   (.CLK(CLK), .RST(nRST), .in1(iniValue), .in2(Sub), .out(iniValue4));
				   
// -- -- Rounding
		ux_round2nearest 								// Round to nearnest
			#(
				.WordLength(dWL+LUT_bits+3),		   		// Total length for the variable
				.RoundLength(dWL+LUT_bits+3-(WLO+1))    	// Wordlength for rounding
			 )
		round_Fang 
			(
				.CLK(CLK), 								// clock
				.RESET(nRST), 							// negative reset
				.CE(CE), 								// Clock enable
				.x(iniValue4), 						// input of the rounding module
				.y(Mul)									// output of the rounding module
			 );

//========================================================================================================
endmodule
`endif




//========================================================================================
//========================================================================================
// Square root reciprocal opearction using cascaded Ito's method
// RoundLength must be greater than or equal one
//========================================================================================

`ifdef declare_Square_Root_Reciprical_Ito_Pipe //This module is using 0 iteration in the Hung algorithm
module Square_Root_Reciprocal_Ito_Iter1_Pipe
		// ****************************
		#(parameter     
						WL = 24,						// World length of the input
						LUT_bits = 13,				// World length of the Look-up table
						LUT_addWidth = 6,			// World length of the Look-up table
						dWL = 28,					// datapath length
						m = LUT_addWidth + 1,		// parameter in MATLAB
						WLO = 24
		 ) 		
		// IO signal definition
		(
			input CLK, 								// clock signal
			input nRST,								// negative resert signal
			input CE,								// clock enable signal
			
			input [WL-1:0] din,					// input structure should be 1.23 for 24 bits input
														// for the single-precision floating-point format mantissa
			output reg [WLO-1:0] dout			// output
		);

////////////////////////////// ----- Inner wires, registers and memories ----- ///////////////////////////
		reg  [LUT_bits-1 : 0]     LUT 	[2**LUT_addWidth-1 : 0];	// Look-up table memory
		reg  [LUT_bits :   0]	  D1;											// initial value selected from LUT
		wire [LUT_bits+3-1 : 0]	  iniValue;						    		// initial value
		wire [dWL-1 : 0]	  	  	  iniValue2;								// Square of the initial value
		wire [dWL-1 : 0]	  	  	  iniValue3;						
		wire [dWL+LUT_bits+3-1 : 0]	  	  iniValue4;											
		reg  [LUT_addWidth-1:0]   reg_cmp;									// Part of input used to search in the LUT
		reg  [WL : 0]			  	  xHat;
		reg  [dWL-1 : 0] 		  	  fpThree =  0; 							// Constant 3
		reg  [dWL-1 : 0] 		  	  Sub;										// temporary result 2.WF								
		wire [WLO  :0] 		  	  Mul;
		reg  [WLO  :0] 		  	  Mul_s;
		
		wire [WL-1 :0]				  din_delay;
		wire [LUT_bits+3-1 : 0]   iniValue_delay;
//========================================================================================================

// -- Main operation
// -- Seperate the input x into xh and xl
		always @* begin
			if(~nRST) begin
				reg_cmp  <= 0;
				xHat <= 0;
				D1   <= 0;
				fpThree[dWL-1:dWL-2] <= 2'b11; 						// assign the first two bits as 1
			end else begin
				if (CE) begin
					reg_cmp  <= din[WL-2 : WL-1-LUT_addWidth];
					D1[LUT_bits] <= 1'b0; 
					D1[LUT_bits-1:0] <= LUT[reg_cmp];
					xHat[WL: WL-(m-1)] <= din[WL-1: WL-m];			// Stru(1:m)     = Str(1:m);
					xHat[WL-m]	 	   <= ~din[WL-(m+1)];			// if (Str(m+1)=='0') Stru(m+1) = '1'; else Stru(m+1) = '0'; end
					xHat[WL-(m+1)]	 <= din[WL-(m+1)];				// tru(m+2) = Str(m+1);  
					xHat[WL-(m+2):0] <= ~din[WL-(m+2):0];				
					Sub <= fpThree - iniValue3;
					Mul_s <= Mul >> 1;							// Shifting right 1 unit for executing *0.5 
					dout <= Mul_s[WL-1:0];
				end
			end
		end
		
mult_unsigned_pipe #(.WI1(1), .WF1(WL), .WI2(1), .WF2(LUT_bits), .WIO(2), .WFO(LUT_bits+3-2)) multiplier_1 
				   (.CLK(CLK), .RST(nRST), .in1(xHat), .in2(D1), .out(iniValue));

mult_unsigned_pipe_3stages #(.WI1(2), .WF1(LUT_bits+3-2), .WI2(2), .WF2(LUT_bits+3-2), .WIO(2), .WFO(dWL-2)) multiplier_2 
				   (.CLK(CLK), .RST(nRST), .in1(iniValue), .in2(iniValue), .out(iniValue2));

mult_unsigned_pipe #(.WI1(1), .WF1(WL-1), .WI2(2), .WF2(dWL-2), .WIO(2), .WFO(dWL-2)) multiplier_3 
				   (.CLK(CLK), .RST(nRST), .in1(din_delay), .in2(iniValue2), .out(iniValue3));
				   
mult_unsigned_pipe #(.WI1(2), .WF1(LUT_bits+3-2), .WI2(2), .WF2(dWL-2), .WIO(2), .WFO(dWL+LUT_bits+3-2)) multiplier_4 
				   (.CLK(CLK), .RST(nRST), .in1(iniValue_delay), .in2(Sub), .out(iniValue4));
				   
// -- -- Rounding
		ux_round2nearest 								// Round to nearnest
			#(
				.WordLength(dWL+LUT_bits+3),		   				// Total length for the variable
				.RoundLength(dWL+LUT_bits+3 - (WLO+1))    		// Wordlength for rounding
			 )
		round_Fang 
			(
				.CLK(CLK), 								// clock
				.RESET(nRST), 							// negative reset
				.CE(CE), 								// Clock enable
				.x(iniValue4), 							   // input of the rounding module
				.y(Mul)									// output of the rounding module
			 );


// Buffer definition

	localparam PIP_iniValue = 5; // number of pipelined stages of multiplier
	localparam PIP_din	= 5;
	reg [LUT_bits+3-1 : 0] buffer_iniValue [1: PIP_iniValue];
	reg [WL-1  : 0] buffer_din [1: PIP_din];
	integer i;
	
	always @(posedge CLK) begin
		if (!nRST) begin
			for (i=1; i<=PIP_iniValue; i=i+1)
				buffer_iniValue[i] <= 0;
				
			for (i=1; i<=PIP_din; i=i+1)
				buffer_din[i] <= 0;
				
		end else begin
			buffer_iniValue[1] <= iniValue;
			for (i=2; i<=PIP_iniValue; i=i+1)
				buffer_iniValue[i] <= buffer_iniValue[i-1];
				
			buffer_din[1] <= din;
			for (i=2; i<=PIP_din; i=i+1)
				buffer_din[i] <= buffer_din[i-1];
				
		end
	end

	assign iniValue_delay = buffer_iniValue[PIP_iniValue];
	assign din_delay = buffer_din[PIP_din];


//========================================================================================================
endmodule
`endif





//========================================================================================
//========================================================================================
// Square root opearction using cascaded Hung's method
// RoundLength must be greater than or equal one
//========================================================================================

`ifdef declare_Square_Root_Hung    //This module is using 0 iteration in the Hung algorithm
module Square_root_Hung_DirectImplementation
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
		wire [dWL+WL-1:0]	  		  Mul;							// temporary result from multiplication							
		wire [dWL-1:0] 			  mul1_net;
//========================================================================================================

// -- Get the initial value from the look-up table
		always @* begin
			reg_cmp  <= din[WL-2 : WL-1-LUT_addWidth];
			iniValue <= LUT[reg_cmp];
		end
// --

// -- Main operation
// -- Seperate the input x into xh and xl
		always @* begin
			if(~nRST) begin
				xh <= 0;
				xl <= 0;
				Sub <= 0;
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

mult_unsigned #(.WI1(1), .WF1(WL-1), .WI2(1), .WF2(LUT_bits-1), .WIO(1), .WFO(dWL-1)) multiplier_1 
				   (.CLK(CLK), .RST(nRST), .in1(Sub), .in2(iniValue), .out(mul1_net));

mult_unsigned #(.WI1(1), .WF1(WL-1), .WI2(1), .WF2(dWL-1), .WIO(1), .WFO(dWL+WL-1)) multiplier_2 
				   (.CLK(CLK), .RST(nRST), .in1(din), .in2(mul1_net), .out(Mul));

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
				.y(dout)									// output of the rounding module
			 );

//========================================================================================================
endmodule
`endif



//========================================================================================
//========================================================================================
// Square root opearction using cascaded GS method
// RoundLength must be greater than or equal one
//========================================================================================

`ifdef declare_Square_Root_Reciprocal_Cascaded_GS
module Square_root_Reciprocal_GS_DirectImplementation
		// ****************************
		#(parameter WL = 24,				// World length of the input
					LUT_bits = 9,			// World length of the Look-up table
					address_bits = 6,	   // World length of the Look-up table
					dWL = 26					// Word lenght of the datapath
		 ) 		
		// IO signal definition
		(
			input CLK, 						// clock signal
			input RST,						// negative resert signal
			input CE,						// clock enable signal
			input [WL-1:0] in,			// input structure should be 1.23 for 24 bits input
												// for the single-precision floating-point format mantissa
			output [WL-1:0] result		// output
		);
		
////////////////////////////// ----- Inner wires, registers and memories ----- ///////////////////////////

	// -- inner wires and registers
	reg  [address_bits-1:0] reg_cmp; 		// Look-up table index
	reg  [LUT_bits-1:0] ini,p1,r1;			// initial value fetched from the LUT
	reg  [WL-1:0]  d1;	
	wire [dWL-1:0] d1_net;						// temp value
	wire [dWL-1:0] d2;
	reg  [dWL-1:0] d2_s;							// right shift of d2 as d2/2
	reg  [dWL-1:0] onep5FP =  0; 				// Constant 3, bitwith is the same with mul_2_r
	reg  [dWL-1:0] p2;
	wire [dWL-1:0] r2;
	wire [dWL-1:0] d2_net;						// temp value
	wire [dWL-1:0] d3;
	reg  [dWL-1:0] d3_s;							// right shift of d3 as d3/2
	reg  [dWL-1:0] p3;	
	wire [dWL-1:0] r3_net;						
	
	// -- memories 
	reg  [LUT_bits-1:0] LUT [2**address_bits-1:0];	

// -- Get the initial value from the look-up table
	always @* begin
		reg_cmp  <= in[WL-2 : WL-1-address_bits];
		ini <= LUT[reg_cmp];
	end
// --
	 
//////////////////////////////////////////////////////////////////////////////////////////
// -- Main operation
// -- -- 0 Iteration 
	always @* begin
		if(~RST) begin
			p1 <= 0;
			r1 <= 0;
			d1 <= 0;
			onep5FP[dWL-1:dWL-2] <= 2'b11;	// assign the first two bits as 1
			d2_s <= 0;
			d3_s <= 0;
		end else begin
			p1 <= ini;
			r1 <= ini;
			d1 <= in;
			d2_s <= d2 >> 1;
			p2 <= onep5FP - d2_s;
			d3_s <= d3 >> 1;
			p3 <= onep5FP - d3_s;
		end
	end

    mult_unsigned #(.WI1(1), .WF1(LUT_bits-1), .WI2(1), .WF2(WL-1), .WIO(1), .WFO(dWL-1)) multiplier_1 
				   (.CLK(CLK), .RST(RST), .in1(p1), .in2(d1), .out(d1_net));

    mult_unsigned #(.WI1(1), .WF1(LUT_bits-1), .WI2(1), .WF2(dWL-1), .WIO(1), .WFO(dWL-1)) multiplier_2 
				   (.CLK(CLK), .RST(RST), .in1(p1), .in2(d1_net), .out(d2));
	
    mult_unsigned #(.WI1(1), .WF1(LUT_bits-1), .WI2(1), .WF2(dWL-1), .WIO(1), .WFO(dWL-1)) multiplier_4 
				   (.CLK(CLK), .RST(RST), .in1(r1), .in2(p2), .out(r2));	

    mult_unsigned #(.WI1(1), .WF1(dWL-1), .WI2(1), .WF2(dWL-1), .WIO(1), .WFO(dWL-1)) multiplier_5 
				   (.CLK(CLK), .RST(RST), .in1(p2), .in2(d2), .out(d2_net));

    mult_unsigned #(.WI1(1), .WF1(dWL-1), .WI2(1), .WF2(dWL-1), .WIO(1), .WFO(dWL-1)) multiplier_6 
				   (.CLK(CLK), .RST(RST), .in1(p2), .in2(d2_net), .out(d3));			   
				   
    mult_unsigned #(.WI1(1), .WF1(dWL-1), .WI2(1), .WF2(dWL-1), .WIO(1), .WFO(dWL-1)) multiplier_7 
				   (.CLK(CLK), .RST(RST), .in1(r2), .in2(p3), .out(r3_net));
				   
//========================================================================================================

// -- -- Rounding
	ux_round2nearest 								// Round to nearnest
		#(
			.WordLength(dWL),						// Total length for the variable
			.RoundLength(dWL-WL)					// Word length for rounding
		 )
	Fang_round
		(
			.CLK(CLK), 								// clock
			.RESET(RST), 							// negative reset
			.CE(CE), 								// Clock enable
			.x(r3_net), 								// input of the rounding module
			.y(result)								// output of the rounding module
		 );
//========================================================================================================

////////////////////////////////// ----- Output ----- ///////////////////////////////////////

//========================================================================================================
endmodule
`endif


//========================================================================================
//========================================================================================
// Square root opearction using cascaded Newton Raphson method
// RoundLength must be greater than or equal one
//========================================================================================

`ifdef declare_Square_Root_Reciprocal_Cascaded_NR
module Square_root_Reciprocal_NR_DirectImplementation
		// ****************************
		#(parameter WL = 24,				// World length of the input
						LUT_bits = 13,		// World length of the Look-up table
						LUT_addWidth = 6,	// World length of the Look-up table
						ITERATION = 1		// Signal symbols whether to use Iterating

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
	
////////////////////////////// ----- Inner wires, registers and memories ----- ///////////////////////////

	// -- iteration 0
		reg  [LUT_bits-1 : 0]     LUT [2**LUT_addWidth-1 : 0];	// Look-up table memory
		reg  [LUT_bits-1 : 0]	  iniValue;								// initial value selected from LUT
		reg  [LUT_addWidth-1:0]   reg_cmp;								// Part of input used to search in the LUT
		reg  [LUT_bits*2-1  :0]   mul_1;									// Product of the first multiplier
		reg  [WL+LUT_bits*2-1 :0] mul_2;									// Product of the second multiplier
		reg  [WL+LUT_bits*2-2 :0] mul_2_s;								// Normalized the product
		reg  [WL+LUT_bits*2-2 :0] sub_1;									// Difference between 3 and x*xi^2
		reg  [WL+LUT_bits*2-2 :0] fpThree =  0; 						// Constant 3, bitwith is the same with mul_2_r
		reg  [WL+LUT_bits*3-2 :0] mul_3;
		reg  [WL+LUT_bits*3-3 :0] mul_3_s;								// Register save the normalized value
	// -- iteration 1	

		reg  [WL*2+LUT_bits*6-5:0] mul_4;
		reg  [WL*3+LUT_bits*6-5:0]	mul_5;
		reg  [WL*3+LUT_bits*6-6:0]	mul_5_s;		
		reg  [WL*3+LUT_bits*6-6:0] fpThree_2 = 0;
		reg  [WL*3+LUT_bits*6-6:0] sub_2;								// Difference between 3 and x*xi^2
		reg  [WL*4+LUT_bits*9-8:0] mul_6;								
		reg  [WL*4+LUT_bits*9-9:0] mul_6_s;
		
		wire [WL-1 : 0]			  out_0;									// output before iteration
		wire [WL-1 : 0]			  out_1;									// output after iteration
 
//========================================================================================================

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
				mul_1   <= 0;
				mul_2   <= 0;
				mul_2_s <= 0;
				sub_1   <= 0;
				fpThree[WL+LUT_bits*2-2:WL+LUT_bits*2-3] <= 2'b11; // assign the first two bits as 1
				mul_3   <= 0;
				mul_3_s <= 0;
				mul_4   <= 0;
				mul_5	  <= 0;
				mul_5_s <= 0;
				fpThree_2[WL*3+LUT_bits*6-6:WL*3+LUT_bits*6-7] <= 2'b11;
				mul_6	  <= 0;
				mul_6_s <= 0;
			end
			else begin
				if (CE) begin
					// -- iteration 0
					mul_1 <= iniValue * iniValue;			  // square of the initial value: xi^2
					mul_2 <= mul_1 * din;					  // x*xi^2
					mul_2_s <= mul_2[WL+LUT_bits*2-2:0];  // shift left 1 unit
					sub_1 <= fpThree - mul_2_s;			  // 3-x*x*xi^2
					// -- currently, the register format is 2.x
					mul_3 <= sub_1 * iniValue;				  // product of the first iteration
					mul_3_s <= mul_3[WL+LUT_bits*3-3 :0]; // normalize to 1.x (shift left 1 units)
					
					// -- iteration 1
					mul_4 <= mul_3_s * mul_3_s;			  
					mul_5 <= mul_4 * din;					  
					mul_5_s <= mul_5[WL*3+LUT_bits*6-6:0];
					sub_2	<= fpThree_2 - mul_5_s;
					mul_6 <= sub_2 * mul_3_s;
					mul_6_s <= mul_6[WL*4+LUT_bits*9-9:0];

				end // if (CE)
			end // else
		end

// -- -- Rounding
		ux_round2nearest 								// Round to nearnest
			#(
				.WordLength(WL+LUT_bits*3-2),		// Total length for the variable
				.RoundLength(LUT_bits*3-2)			// Wordlength for rounding
			 )
		round_0 
			(
				.CLK(CLK), 								// clock
				.RESET(nRST), 							// negative reset
				.CE(CE), 								// Clock enable
				.x(mul_3_s), 							// input of the rounding module
				.y(out_0)								// output of the rounding module
			 );
		
		ux_round2nearest 								// Round to nearnest
			#(
				.WordLength(WL*4+LUT_bits*9-8),	// Total length for the variable
				.RoundLength(WL*3+LUT_bits*9-8)					// Word length for rounding
			 )
		round_1 
			(
				.CLK(CLK), 								// clock
				.RESET(nRST), 							// negative reset
				.CE(CE), 								// Clock enable
				.x(mul_6_s), 								// input of the rounding module
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
`endif