`timescale 1ns / 1ps

//========================================================================================
//========================================================================================
// NR Reciprocal
// This module is pipelined without iteration
//========================================================================================

module Reciprocal_Pipelined_NR
		// ****************************
		#(parameter 	
		/*
						WL = 24,					// World length of the input
						LUT_bits = 15,			// World length of the Look-up table
						LUT_addWidth = 12,	// World length of the Look-up table
						dWL = 26,				// datapath bitwidth
						WLO = 24
						*/
						WL = 24,					// World length of the input
						LUT_bits = 15,			// World length of the Look-up table
						LUT_addWidth = 12,	// World length of the Look-up table
						dWL = 26,				// datapath bitwidth
						WLO = 24
		 ) 		
		// IO signal definition
		(
			input CLK, 						// clock signal
			input nRST,						// negative reset signal
			input CE,						// clock enable signal
			
			input [WL-1:0] din,			// input structure should be 1.23 for 24 bits input
												// for the single-precision floating-point format mantissa
			output [WLO-1:0] dout		   // output
		);
			
////////////////////////////// ----- Inner wires, registers and memories ----- ///////////////////////////
		reg  [LUT_bits-1 : 0]     LUT [2**LUT_addWidth-1 : 0];	// Look-up table memory
		reg  [LUT_bits-1 : 0]	  iniValue;								// initial value selected from LUT
		wire [LUT_addWidth-1:0]   reg_cmp;								// Part of input used to search in the LUT
		reg  [WL-1:0] 				  din_delay;							// buffer of the input
		reg  [LUT_bits-1 : 0] 	  iniValue_delay;						// buffer of the iniValue		
		reg  [LUT_bits-1 : 0] 	  iniValue_delay2;					// buffer of the iniValue
		reg  [LUT_bits-1 : 0] 	  iniValue_delay3;					// buffer of the iniValue

		wire [dWL-1 :0]   		  mul1_net;								// Product of the first multiplier
		reg  [dWL-1 :0]   		  mul_1_r;								// bit reverse of the multiplier product
		wire [dWL+LUT_bits-1:0]	  mul2_net;								// Product of the second multiplier
//========================================================================================================


////////////////////////////////// ----- Modle Intialization ----- ///////////////////////////////////////

// -- Main operation
// -- -- 0 Iteration
		assign reg_cmp = din[WL-2 : WL-1-LUT_addWidth];
		always @(posedge CLK) begin
			if(~nRST) begin
					iniValue <= 0;
					mul_1_r <= 0;
					din_delay <= 0;
					iniValue_delay3 <= 0;
					iniValue_delay2 <= 0;
					iniValue_delay <= 0;
					//reg_cmp <= 0;
			end
			else begin
				if (CE) begin
					//reg_cmp <= din[WL-2 : WL-1-LUT_addWidth];
					din_delay <= din;
					iniValue_delay <= iniValue;
					iniValue_delay2 <= iniValue_delay;
					iniValue_delay3 <= iniValue_delay2;
					iniValue <= LUT[reg_cmp];							// get the initial value
					mul_1_r <= ~mul1_net; 								// bit reverse of product1
				end // if (CE)
			end // else
		end

// Here use customized 1 stages pipelined multiplier
mult_unsigned_pipe #(.WI1(1), .WF1(WL-1), .WI2(1), .WF2(LUT_bits-1), .WIO(1), .WFO(dWL-1)) multiplier_1 
						  (.CLK(CLK), .RST(nRST), .in1(din_delay), .in2(iniValue), .out(mul1_net));
						  
// Here use customized 2 stages pipelined multiplier 
mult_unsigned_pipe #(.WI1(1), .WF1(dWL-1), .WI2(1), .WF2(LUT_bits-1), .WIO(1), .WFO(dWL+LUT_bits-1)) multiplier_2 
						  (.CLK(CLK), .RST(nRST), .in1(mul_1_r), .in2(iniValue_delay3), .out(mul2_net));

// -- -- Rounding
		ux_round2nearest 								// Round to nearnest
			#(
				.WordLength(dWL+LUT_bits),			// Total length for the variable
				.RoundLength(dWL+LUT_bits-WLO)		// Wordlength for rounding
			 )
		round_0 
			(
				.CLK(CLK), 								// clock
				.RESET(nRST), 							// negative reset
				.CE(CE), 								// Clock enable
				.x(mul2_net), 							// input of the rounding module
				.y(dout)									// output of the rounding module
			 );
endmodule			
//========================================================================================================

//========================================================================================
//========================================================================================
// GS Reciprocal
// This module is pipelined without iteration
//========================================================================================


module Reciprocal_Pipelined_GS
	  #(parameter 
				WL = 24,  
				LUT_addWidth = 12, 
				LUT_bits = 15,
				dWL = 27)
		(
			input CLK, nRST,
			input CE,						// clock enable
			input [WL-1:0] din,	    	// input 
			
			output [WL-1:0] dout
			
		);
			reg   [LUT_bits-1:0] LUT [2**LUT_addWidth-1:0];
			reg   [WL-1:0]  			  din_delay;							// buffer of the input
			wire  [dWL-1:0] 			  d1_net, r2_net;						// intermediate variables
			reg	[dWL-1:0] 			  p2;
			reg   [LUT_bits-1:0] 	  iniValue;
			reg   [LUT_bits-1 : 0] 	  iniValue_delay;						// buffer of the iniValue		
			reg   [LUT_bits-1 : 0] 	  iniValue_delay2;					// buffer of the iniValue
			reg   [LUT_addWidth-1:0]  reg_cmp;
///////////////////////// -- prepare for the start of GS algorithm -- ////////////////////////////

	always @*   reg_cmp <= din[WL-2 : WL-1-LUT_addWidth];
	always @ (posedge CLK) begin
			if(~nRST) begin
					din_delay <= 0;
					iniValue <= 0;
					p2 <= 0;
					iniValue_delay <= 0;
					iniValue_delay2 <= 0;
			end else begin
				if (CE) begin
					din_delay <= din;
					iniValue <= LUT[reg_cmp];
					iniValue_delay <= iniValue;
					iniValue_delay2 <= iniValue_delay;
					p2 <= ~d1_net;
				end // if (CE)
			end // else	
	end		

mult_unsigned_pipe #(.WI1(1), .WF1(LUT_bits-1), .WI2(1), .WF2(WL-1), .WIO(1), .WFO(dWL-1)) multiplier_1 
						  (.CLK(CLK), .RST(RST), .in1(iniValue), .in2(din_delay), .out(d1_net));

///////////////////////////////////iteration 1/////////////////////////////////////////////
mult_unsigned_pipe #(.WI1(1), .WF1(LUT_bits-1), .WI2(1), .WF2(dWL-1), .WIO(1),.WFO(dWL-1)) multiplier_2 
						  (.CLK(CLK), .RST(RST), .in1(iniValue_delay2), .in2(p2), .out(r2_net));
		
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
				.y(dout)									// output of the rounding module
			 );			
		
endmodule

// =========================================================================================================








module Reciprocal_Pipelined_Hung
		// ****************************
		#(parameter 	
						WL = 24,			// World length of the input
						LUT_bits = 26,		// World length of the Look-up table
						LUT_addWidth = 12	// World length of the Look-up table
		 )
		// IO signal definition
		(
			input CLK, 						// clock signal
			input nRST,						// negative resert signal
			input CE,						// clock enable signal
			input [WL-1:0] din,			// input structure should be 1.23 for 24 bits input
											   // for the single-precision floating-point format mantissa
			output [WL-1:0] dout			// output (1.WF format)
		);

////////////////////////////// ----- Inner wires, registers and memories ----- ///////////////////////////
		reg  [LUT_bits-1 : 0]     LUT 	[2**LUT_addWidth-1 : 0];	// Look-up table memory
		reg  [LUT_bits-1 : 0]	  iniValue;							// initial value selected from LUT
		reg  [LUT_bits-1 : 0]	  iniValue_delay;							// initial value selected from LUT
		wire [LUT_addWidth-1:0]   reg_cmp;							// Part of input used to search in the LUT
		reg  [WL-1:0]	  		  	  xh;								   // Higher parts 
		reg  [WL-1:0]			  	  xl;								   // Lower parts
		reg  [WL-1:0]			  	  Sub;								// Difference between high part and lower part 
		reg  [WL+LUT_bits-1:0]	  Mul;								// temporary result from multiplication
		wire [WL:0] 			  	  temp_result;						// temporary result 2.WF								
		
////////////////////////////////// ----- Modle Intialization ----- ///////////////////////////////////////

		
// -- Seperate the input x into xh and xl
		assign reg_cmp = din[WL-2 : WL-1-LUT_addWidth];
		always @(posedge CLK) begin
			if(~nRST) begin
					xh <= 0;
					xl <= 0;
					Sub <= 0;
					Mul <= 0;
					iniValue <= 0;
					iniValue_delay <= 0;
			end else begin
				if (CE) begin
					iniValue <= LUT[reg_cmp];
					iniValue_delay <= iniValue;
					xh[WL-1:WL-(LUT_addWidth+1)] <= din[WL-1:WL-(LUT_addWidth+1)];
					xh[WL-(LUT_addWidth+1)-1:0]	<= 0;
					xl[WL-(LUT_addWidth+1)-1:0] <= din[WL-(LUT_addWidth+1)-1:0];
					xl[WL-1:WL-(LUT_addWidth+1)] <= 0;
					Sub <= xh - xl;
					Mul <= Sub * iniValue_delay;
					//dout <= temp_result[WL-1:0];
				end
			end
		end
		
// -- -- Rounding
		ux_round2nearest 								// Round to nearnest
			#(
				.WordLength(WL+LUT_bits),			// Total length for the variable
				.RoundLength(LUT_bits-1)			// Wordlength for rounding
			 )
		round_0 
			(
				.CLK(CLK), 								// clock
				.RESET(nRST), 							// negative reset
				.CE(CE), 								// Clock enable
				.x(Mul), 								// input of the rounding module
				.y(temp_result)						// output of the rounding module
			 );
		
		assign dout = temp_result[WL-1:0];
		
endmodule











//========================================================================================
//========================================================================================
// Reciprocal Opearction using cascaded Ito(LUT) + Newton Raphson method
// RoundLength must be greater than or equal one
//========================================================================================
module Reciprocal_Pipelined_ItoNR
		// ****************************
		#(parameter 
						/*
						WL = 53,					// World length of the input
						LUT_bits = 27,			// World length of the Look-up table
						LUT_addWidth = 13,		// World length of the Look-up table
						dWL = 56,
						m = LUT_addWidth + 1,
						WLO = 57
						*/
						
						WL = 24,					// World length of the input
						LUT_bits = 13,			// World length of the Look-up table
						LUT_addWidth = 6,		// World length of the Look-up table
						dWL = 26,
						WLO = 24,
						m = LUT_addWidth + 1
						
		 ) 		
		// IO signal definition
		(
			input CLK, 							// clock signal
			input nRST,							// negative resert signal
			input CE,							// clock enable signal
			     
			input [WL-1:0] din,				// input structure should be 1.23 for 24 bits input
													// for the single-precision floating-point format mantissa
			output [WLO-1:0] dout		// output
		);
		
////////////////////////////// ----- Inner wires, registers and memories ----- ///////////////////////////
		wire [WL-1:0] 				  din_delay;
		reg  [LUT_bits   : 0]     LUT [2**LUT_addWidth-1 : 0];	// Look-up table memory
		reg  [LUT_bits-1 : 0]	  B1;										// initial value selected from LUT
		reg  [LUT_bits : 0]	  	  B1_real;								// initial value selected from LUT		
		wire [LUT_addWidth-1:0]   reg_cmp;								// Part of input used to search in the LUT
		reg  [WL-1 : 0]			  xHat;
		wire [LUT_bits+2-1 : 0]  iniValue, iniValue_delay;					// initial value selected from LUT
		wire [dWL-1 : 0]  mul2_net;							    		// Product of the second multiplier
		reg  [dWL-1 : 0]  mul2_net_r, mul2_net_r_delay;
		wire [dWL+LUT_bits+2-1 : 0]  Mul;
//========================================================================================================

////////////////////////////////// ----- Modle Intialization ----- ///////////////////////////////////////

// -- Main operation
// -- -- 0 Iteration
		assign reg_cmp = din[WL-2 : WL-1-LUT_addWidth];				// MATLAB LINE 91ï¼addStr = Strp(2:m+1);
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
				   
mult_unsigned_pipe #(.WI1(1), .WF1(WL-1), .WI2(1), .WF2(LUT_bits+2-1), .WIO(1), .WFO(dWL-1)) multiplier_2 
				   (.CLK(CLK), .RST(nRST), .in1(din), .in2(iniValue), .out(mul2_net));
				   
mult_unsigned_pipe_3stages #(.WI1(1), .WF1(dWL-1), .WI2(1), .WF2(LUT_bits+2-1), .WIO(1), .WFO(dWL+LUT_bits+2-1)) multiplier_3 
				   (.CLK(CLK), .RST(nRST), .in1(mul2_net_r), .in2(iniValue_delay), .out(Mul));

// -- -- Rounding
		ux_round2nearest_pipe 								// Round to nearnest
			#(
				.WordLength(dWL+LUT_bits+2),					// Total length for the variable
				.RoundLength(dWL+LUT_bits+2 - WLO)			// Wordlength for rounding
			 )
		round_0 
			(
				.CLK(CLK), 								// clock
				.RESET(nRST), 							// negative reset
				.CE(CE), 								// Clock enable
				.x(Mul), 								// input of the rounding module
				.y(dout)									// output of the rounding module
			 );

// Buffer definition

	localparam PIP_iniValue = 2; // number of pipelined stages of multiplier
	localparam PIP_din	= 1;
	reg [LUT_bits+2-1 : 0] buffer_iniValue [1: PIP_iniValue];
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

endmodule	
//========================================================================================================







//========================================================================================
//========================================================================================
// Reciprocal Opearction using cascaded Ito(LUT) + Newton Raphson method _ Unfolded
// RoundLength must be greater than or equal one
//========================================================================================
module Reciprocal_Pipelined_ItoNR_unfold
		// ****************************
		#(parameter 
						/*
						WL = 53,					// World length of the input
						LUT_bits = 15,			// World length of the Look-up table
						LUT_addWidth = 6,		// World length of the Look-up table
						dWL = 56,
						dWL_s2 = 30,
						m = LUT_addWidth + 1,
						WLO = 57
						*/
						
						
						WL = 24,					// World length of the input
						LUT_bits = 9,			// World length of the Look-up table
						LUT_addWidth = 3,		// World length of the Look-up table
						dWL = 27,
						dWL_s2 = 15,
						m = LUT_addWidth + 1,
						WLO = 25
						
		 ) 		
		// IO signal definition
		(
			input CLK, 							// clock signal
			input nRST,							// negative resert signal
			input CE,							// clock enable signal
			     
			input [WL-1:0] din,				// input structure should be 1.23 for 24 bits input
													// for the single-precision floating-point format mantissa
			output [WLO-1:0] dout		// output
		);
		
////////////////////////////// ----- Inner wires, registers and memories ----- ///////////////////////////
		wire [WL-1:0] 				  din_delay;
		reg  [LUT_bits   : 0]     LUT [2**LUT_addWidth-1 : 0];	// Look-up table memory
		reg  [LUT_bits-1 : 0]	  B1;										// initial value selected from LUT
		reg  [LUT_bits : 0]	  	  B1_real;								// initial value selected from LUT		
		wire [LUT_addWidth-1:0]   reg_cmp;								// Part of input used to search in the LUT
		reg  [WL-1 : 0]			  xHat;
		wire [LUT_bits+2-1 : 0]   iniValue, iniValue_delay;					// initial value selected from LUT
		wire [dWL_s2-1 : 0]  	  mul2_net, mul3_net, mul3_net_delay;		// Product of the second multiplier
		wire [dWL-1		: 0]  	  mul4_net;
		reg  [dWL-1		: 0]  	  mul4_net_r;
		reg  [dWL_s2-1 : 0]  	  mul2_net_r, mul2_net_r_delay;
		wire [dWL+dWL_s2-1 : 0]   Mul;
//========================================================================================================

////////////////////////////////// ----- Modle Intialization ----- ///////////////////////////////////////

// -- Main operation
// -- -- 0 Iteration
		assign reg_cmp = din[WL-2 : WL-1-LUT_addWidth];				// MATLAB LINE 91ï¼addStr = Strp(2:m+1);
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
					mul4_net_r <= ~mul4_net;
				end // if (CE)
			end // else
		end

mult_unsigned #(.WI1(1), .WF1(WL-1), .WI2(1), .WF2(LUT_bits), .WIO(1), .WFO(LUT_bits+2-1)) multiplier_1 
				   (.CLK(CLK), .RST(nRST), .in1(xHat), .in2(B1_real), .out(iniValue));
				   
mult_unsigned_pipe #(.WI1(1), .WF1(WL-1), .WI2(1), .WF2(LUT_bits+2-1), .WIO(1), .WFO(dWL_s2-1)) multiplier_2 
				   (.CLK(CLK), .RST(nRST), .in1(din), .in2(iniValue), .out(mul2_net));
				   
mult_unsigned_pipe #(.WI1(1), .WF1(dWL_s2-1), .WI2(1), .WF2(LUT_bits+2-1), .WIO(1), .WFO(dWL_s2-1)) multiplier_3 
				   (.CLK(CLK), .RST(nRST), .in1(mul2_net_r), .in2(iniValue_delay), .out(mul3_net));

mult_unsigned_pipe #(.WI1(1), .WF1(WL-1), .WI2(1), .WF2(dWL_s2-1), .WIO(1), .WFO(dWL-1)) multiplier_4
				   (.CLK(CLK), .RST(nRST), .in1(din_delay), .in2(mul3_net), .out(mul4_net));

mult_unsigned_pipe #(.WI1(1), .WF1(dWL-1), .WI2(1), .WF2(dWL_s2-1), .WIO(1), .WFO(dWL+dWL_s2-1)) multiplier_5 
				   (.CLK(CLK), .RST(nRST), .in1(mul4_net_r), .in2(mul3_net_delay), .out(Mul));

// -- -- Rounding
		ux_round2nearest 								// Round to nearnest
			#(
				.WordLength(dWL+dWL_s2),					// Total length for the variable
				.RoundLength(dWL+dWL_s2 - WLO)			// Wordlength for rounding
			 )
		round_0 
			(
				.CLK(CLK), 								// clock
				.RESET(nRST), 							// negative reset
				.CE(CE), 								// Clock enable
				.x(Mul), 								// input of the rounding module
				.y(dout)									// output of the rounding module
			 );
// Buffer definition

	localparam PIP_iniValue = 2; // number of pipelined stages of multiplier
	localparam PIP_din	= 4;
	localparam PIP_mul3_net = 2;
	reg [LUT_bits+2-1 : 0] buffer_iniValue [1: PIP_iniValue];
	reg [WL-1  : 0] buffer_din [1: PIP_din];
	reg [dWL_s2-1 : 0] buffer_mul3_net [1: PIP_mul3_net];
	integer i;
	
	always @(posedge CLK) begin
		if (!nRST) begin
			for (i=1; i<=PIP_iniValue; i=i+1)
				buffer_iniValue[i] <= 0;
				
			for (i=1; i<=PIP_din; i=i+1)
				buffer_din[i] <= 0;

			for (i=1; i<=PIP_mul3_net; i=i+1)
				buffer_mul3_net[i] <= 0;
				
		end else begin
			buffer_iniValue[1] <= iniValue;
			for (i=2; i<=PIP_iniValue; i=i+1)
				buffer_iniValue[i] <= buffer_iniValue[i-1];
				
			buffer_din[1] <= din;
			for (i=2; i<=PIP_din; i=i+1)
				buffer_din[i] <= buffer_din[i-1];

			buffer_mul3_net[1] <= mul3_net;
			for (i=2; i<=PIP_mul3_net; i=i+1)
				buffer_mul3_net[i] <= buffer_mul3_net[i-1];
		end
	end

	assign iniValue_delay = buffer_iniValue[PIP_iniValue];
	assign din_delay = buffer_din[PIP_din];
	assign mul3_net_delay = buffer_mul3_net[PIP_mul3_net];
//========================================================================================================
endmodule


