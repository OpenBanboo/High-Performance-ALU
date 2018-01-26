`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:12:01 01/14/2015 
// Design Name: 
// Module Name:    flot_Sqrt_Hung 
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
module flot_Sqrt_Hung
			#(parameter 		  
			
									  WIDTH = 32,				  //The total bits of the inputs
									  WIDTH_exp = 8,			  //The bitwidth of the exponent part
									  WIDTH_mat = 23,			  //The bitwidth of the mantissa part
									  LUT_addWidth = 12,		  //Address table is 12 bits for the 23 mantissa part
									  LUT_bits = 27
			
			/*
									  WIDTH = 24,				  //The total bits of the inputs
									  WIDTH_exp = 6,			  //The bitwidth of the exponent part
									  WIDTH_mat = 17,			  //The bitwidth of the mantissa part
									  LUT_addWidth = 9,		  //Address table is 12 bits for the 23 mantissa part
									  LUT_bits = 20
			*/
			/*
									  WIDTH = 16,				  //The total bits of the inputs
									  WIDTH_exp = 4,			  //The bitwidth of the exponent part
									  WIDTH_mat = 11,			  //The bitwidth of the mantissa part
									  LUT_addWidth = 6,		  //Address table is 12 bits for the 23 mantissa part
									  LUT_bits = 14	
			*/
									  )			
			( input 				  CLK,						  //clock				 
									  nRST,						  //negative reset
			  input [WIDTH-1:0] OP,							  //input
			  input 				  CE,
			  input 				  exce_in,
			  output reg 		  exce_out,						  //exception out
			  output reg [WIDTH_mat+WIDTH_exp:0] result //final width = mantissa part + exponent part + sign bit
			 ); 

/////////////////////////////////  ----- Function Deginition -----  ///////////////////////////////////////////////////
	function integer log2;				// calculate log2(n)
		input integer n;					// always be used to calculate the minimal address bits of a signal array
		begin
			log2 = 0;
			while (2**log2<n) begin
				log2 = log2 + 1;
			end
		end
	endfunction
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// ======================================  Module Instiation  =============================================//
// *************************************************************
	reg 					  sign;		// sign of the operand
	reg [WIDTH_exp-1:0] exp;		// exponential part of the operand
	reg [WIDTH_exp:0]   exp_out;
	reg [WIDTH_mat	 :0] mati;		// mantissa with appended 
	wire[WIDTH_mat  :0] mati_tmp;	// mantissa with appended 
	wire[WIDTH_mat  :0] mati_tmp2;// mantissa with appended 
	reg [WIDTH_mat-1:0] mati_out;	// mantissa out
// -- seperate the operand into three parts: sign, exponential and mantissa
	always @ * begin
		if(!nRST) begin
			sign 	 = 0;	
			exp  	 = 0;
			mati 	 = 0;
		end else begin
			sign 	 = OP[WIDTH-1];		
			exp  	 = OP[WIDTH-1-1:WIDTH-1-WIDTH_exp];
			mati[WIDTH_mat] 		= 1'b1;
			mati[WIDTH_mat-1 :0] = OP[WIDTH_mat-1 :0];
		end
	end
// ------------------------------------------------------------------------
// -- process the reciprocal for the mantissa part
	Square_root_Hung_DirectImplementation
	#(
		.WL(WIDTH_mat+1),					// Total word length of input
		.LUT_bits(LUT_bits),				// Look-up table bits
		.LUT_addWidth(LUT_addWidth),  // World length of the Look-up table
		.dWL(WIDTH_mat+1+3),			   // Signal symbols whether to use Iterating
		.WLO(WIDTH_mat+1)
    )
	Fang_Square_Root_Hung 
	(
		.CLK(CLK), 							// clock
		.nRST(nRST), 						// negative reset
		.CE(CE), 							// clock enable
		.din(mati), 						// data input 
		.dout(mati_tmp)					// data output
	 );

// ------------------------------------------------
// ------------------------------------------------------------------------
// -- process the reciprocal for the exponential part and mantissa part
	reg [WIDTH_exp-1:0] bias = (2**(WIDTH_exp-1))-1;	//calculate the bias
	reg [WIDTH_exp-1:0] diff;									// difference between the exponent part and bias
	
	reg [31:0] sqrttwo = 32'b1_0110_1010_0000_1001_1110_0110_0110_011;
	mult_unsigned 
	 #(.WI1(1),   .WF1(WIDTH_mat), .WI2(1),   	  .WF2(WIDTH_mat),   .WIO(1),    		.WFO(WIDTH_mat)) 
	multiplier_scaling
	  (.CLK(CLK), .RST(nRST), .in1(mati_tmp), .in2(sqrttwo[31:(32-WIDTH_mat-1)]),  .out(mati_tmp2));	
	
	always @ * begin
		if(!nRST) begin
			exp_out = 0;
			mati_out = 0;
			diff = 0;
		end else begin
			if (exp>=bias) begin
				diff = exp - bias;
				if (diff[0]==1'b0) begin
					exp_out = bias + (exp - bias)/2;
					mati_out = mati_tmp[WIDTH_mat-1:0];
				end else begin
					exp_out = bias + (exp - bias)/2;
					mati_out = mati_tmp2[WIDTH_mat-1:0];
				end
			end else begin
				diff = bias - exp;
				if (diff[0]==1'b0) begin
					exp_out  = bias - (bias - exp)/2;
					mati_out = mati_tmp[WIDTH_mat-1:0];
				end else begin
					exp_out = bias - (bias - exp)/2 -1;
					mati_out = mati_tmp2[WIDTH_mat-1:0];
				end
			end
		end
	end 
	// the exponent should reverse and minus one beacuse the tempororary result is starting with "0"
// ------------------------------------------------
// ------------------------------------------------------------------------
// -- combine the parts into the final result
	always @* begin
		if(!nRST) begin
			result = 0;
		end else begin
			result = {sign, exp_out[WIDTH_exp-1:0], mati_out};
		end
	end

// ------------------------------------------ exceptions handle  ------------------------------------------- //
// exception out will be set to 1 when exception in is 1 or exponent part is out of bound after calculation
always @* begin
	if(exce_in||exp_out[WIDTH_exp]) 
		exce_out <= 1'b1;
	else
		exce_out <= 1'b0;
end
// --------------------------------------------------------------------------------------------------------- //

endmodule
