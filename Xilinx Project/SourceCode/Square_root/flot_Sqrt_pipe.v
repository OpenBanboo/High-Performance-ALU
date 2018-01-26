`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    22:28:46 09/24/2015 
// Design Name: 
// Module Name:    flot_Sqrt_pipe 
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
module flot_Sqrt_pipe
			#(parameter 		  
	
			
									  WIDTH = 64,				  //The total bits of the inputs
									  WIDTH_exp = 11,			  //The bitwidth of the exponent part
									  WIDTH_mat = 52,			  //The bitwidth of the mantissa part
									  LUT_addWidth = 32,		  //Address table is 12 bits for the 23 mantissa part
									  LUT_bits = 54	
		
			
			/*
									  WIDTH = 32,				  //The total bits of the inputs
									  WIDTH_exp = 8,			  //The bitwidth of the exponent part
									  WIDTH_mat = 23,			  //The bitwidth of the mantissa part
									  LUT_addWidth = 12,		  //Address table is 12 bits for the 23 mantissa part
									  LUT_bits = 27
			*/

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
	reg 					  	sign;		// sign of the operand
	reg [WIDTH_exp-1:0] 	exp;		// exponential part of the operand
	reg [WIDTH_exp:0]   	exp_out;
	reg [WIDTH_mat	 :0] 	mati;		// mantissa with appended 
	wire[WIDTH_mat  :0] 	mati_tmp;	// mantissa with appended
	wire[WIDTH_mat  :0] 	mati_tmp_delay;
	wire					  	sign_delay;
	wire 					  	exce_in_delay;
	wire [WIDTH_exp-1:0] exp_delay;
	wire[WIDTH_mat  :0] 	mati_tmp2;// mantissa with appended 
	reg [WIDTH_mat-1:0] 	mati_out;	// mantissa out
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
	Square_root_pipe
	#(
		.WL(WIDTH_mat+1),					// Total word length of input
		.LUT_bits(LUT_bits),				// Look-up table bits
		.LUT_addWidth(LUT_addWidth),  // World length of the Look-up table
		.dWL(WIDTH_mat+1+3),			   // Signal symbols whether to use Iterating
		.WLO(WIDTH_mat+1)
    )
	Fang_Square_Root_Pipe
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
	reg [WIDTH_exp-1:0] diff;					// difference between the exponent part and bias
	wire [WIDTH_exp-1:0] diff_delay;	

	reg [52:0] sqrttwo = 53'b1_0110101000001001111001100110011111110011101111001101;
	mult_unsigned_pipe
	 #(.WI1(1),   .WF1(WIDTH_mat), .WI2(1),   	  .WF2(WIDTH_mat),   .WIO(1),    		.WFO(WIDTH_mat)) 
	multiplier_scaling
	  (.CLK(CLK), .RST(nRST), .in1(mati_tmp), .in2(sqrttwo[52:(53-WIDTH_mat-1)]),  .out(mati_tmp2));	
	
	always @ * begin
		if(!nRST) begin
			diff <= 0;
		end else begin
			if (exp>=bias) begin
				diff <= exp - bias;
			end else begin
				diff <= bias - exp;
			end
		end
	end
	
	always @ (posedge CLK) begin
		if(!nRST) begin
			exp_out <= 0;
			mati_out <= 0;
		end else begin
			if (exp_delay>=bias) begin
				if (diff_delay[0] == 1'b0) begin
					exp_out <= bias + (exp_delay - bias)/2;
					mati_out <= mati_tmp_delay[WIDTH_mat-1:0];
				end else begin
					exp_out <= bias + (exp_delay - bias)/2;
					mati_out <= mati_tmp2[WIDTH_mat-1:0];
				end
			end else begin
				if (diff_delay[0] == 1'b0) begin
					exp_out  <= bias - (bias - exp_delay)/2;
					mati_out <= mati_tmp_delay[WIDTH_mat-1:0];
				end else begin
					exp_out <= bias - (bias - exp_delay)/2 -1;
					mati_out <= mati_tmp2[WIDTH_mat-1:0];
				end
			end
		end
	end 
	// the exponent should reverse and minus one beacuse the tempororary result is starting with "0"
// ------------------------------------------------

// ------------------------------------------ exceptions handle  ------------------------------------------- //
// exception out will be set to 1 when exception in is 1 or exponent part is out of bound after calculation
/*
always @ (posedge CLK) begin
	if(exce_in_delay||exp_out[WIDTH_exp]) 
		exce_out <= 1'b1;
	else
		exce_out <= 1'b0;
end
*/
// --------------------------------------------------------------------------------------------------------- //

	localparam PIP_exce_in = 7; //8
	localparam PIP_result = 1;
	localparam PIP_exp = 7;
	localparam PIP_diff = 7;
	localparam PIP_sign = 8; //8
	localparam PIP_mati_tmp = 2;

// ------------------Buffer for pipeline ---------------------- //
	reg [WIDTH_mat+WIDTH_exp:0] buffer_result [1: PIP_result];		// 
	reg [1: PIP_exce_in] buffer_exce_in;
	reg [WIDTH_exp-1:0] buffer_exp [1:PIP_exp];
	reg [WIDTH_exp-1:0] buffer_diff [1:PIP_diff];
	reg [1: PIP_sign] buffer_sign;
	reg [WIDTH_mat:0] buffer_mati_tmp [1 : PIP_mati_tmp];
	
	integer i;

always @ * begin
	if(exce_in_delay||exp_out[WIDTH_exp]) 
		exce_out <= 1'b1;
	else
		exce_out <= 1'b0;

	result <= {sign_delay, exp_out[WIDTH_exp-1:0], mati_out};
end
	
	always @(posedge CLK) begin
		if (!nRST) begin
//			for (i=1; i<=PIP_result; i=i+1)
//				buffer_result[i] <= 0;
				
			for (i=1; i<=PIP_exce_in; i=i+1)
				buffer_exce_in[i] <= 0;

			for (i=1; i<=PIP_exp; i=i+1)
				buffer_exp[i] <= 0;

			for (i=1; i<=PIP_diff; i=i+1)
				buffer_diff[i] <= 0;

			for (i=1; i<=PIP_sign; i=i+1)
				buffer_sign[i] <= 0;

			for (i=1; i<=PIP_mati_tmp; i=i+1)
				buffer_mati_tmp[i] <= 0;
				
		end else begin
//			buffer_result[1] <= {sign_delay, exp_out[WIDTH_exp-1:0], mati_out};
//			for (i=2; i<=PIP_result; i=i+1)
//				buffer_result[i] <= buffer_result[i-1];
				
			buffer_exce_in[1] <= exce_in;
			for (i=2; i<=PIP_exce_in; i=i+1)
				buffer_exce_in[i] <= buffer_exce_in[i-1];

			buffer_exp[1] <= exp;
			for (i=2; i<=PIP_exp; i=i+1)
				buffer_exp[i] <= buffer_exp[i-1];

			buffer_diff[1] <= diff;
			for (i=2; i<=PIP_diff; i=i+1)
				buffer_diff[i] <= buffer_diff[i-1];

			buffer_sign[1] <= sign;
			for (i=2; i<=PIP_sign; i=i+1)
				buffer_sign[i] <= buffer_sign[i-1];

			buffer_mati_tmp[1] <= mati_tmp;
			for (i=2; i<=PIP_mati_tmp; i=i+1)
				buffer_mati_tmp[i] <= buffer_mati_tmp[i-1];

		end
	end

	assign sign_delay = buffer_sign[PIP_sign];
//	assign result = buffer_result[PIP_result];
	assign exp_delay = buffer_exp[PIP_exp];
	assign diff_delay = buffer_diff[PIP_diff];
	assign sign_delay = buffer_sign[PIP_sign];
	assign mati_tmp_delay = buffer_mati_tmp[PIP_mati_tmp];
	assign exce_in_delay = buffer_exce_in[PIP_exce_in];

//	-----------------------------------------------------------------------------------------------------

endmodule




module flot_isqrt_Ito_pipe
			#(parameter 		  
			
									  WIDTH = 32,				  //The total bits of the inputs
									  WIDTH_exp = 8,			  //The bitwidth of the exponent part
									  WIDTH_mat = 23,			  //The bitwidth of the mantissa part
									  LUT_addWidth = 6,		  //Address table is 12 bits for the 23 mantissa part
									  LUT_bits = 13
			
			/*
									  WIDTH = 24,				  //The total bits of the inputs
									  WIDTH_exp = 6,			  //The bitwidth of the exponent part
									  WIDTH_mat = 17,			  //The bitwidth of the mantissa part
									  LUT_addWidth = 9,		  //Address table is 12 bits for the 23 mantissa part
									  LUT_bits = 18
			*/
			/*
									  WIDTH = 16,				  //The total bits of the inputs
									  WIDTH_exp = 4,			  //The bitwidth of the exponent part
									  WIDTH_mat = 11,			  //The bitwidth of the mantissa part
									  LUT_addWidth = 6,		  //Address table is 12 bits for the 23 mantissa part
									  LUT_bits = 12
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
	reg 					  	sign;		// sign of the operand
	reg [WIDTH_exp-1:0] 	exp;		// exponential part of the operand
	reg [WIDTH_exp:0] 	exp_out;
	reg [WIDTH_mat	 :0] 	mati;		// mantissa with appended 
	wire[WIDTH_mat+1:0] 	mati_tmp;	// mantissa with appended 
	wire[WIDTH_mat+1:0] 	mati_tmp2;	// mantissa with appended 
	reg [WIDTH_mat-1:0] 	mati_out;	// mantissa out
	wire[WIDTH_mat  :0] 	mati_tmp_delay;
	wire					  	sign_delay;
	wire 					  	exce_in_delay;
	wire [WIDTH_exp-1:0] exp_delay;

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
	Square_Root_Reciprocal_Ito_Iter1_Pipe
	#(
		.WL(WIDTH_mat+1),							// Total word length of input
		.LUT_bits(LUT_bits),						// Look-up table bits
		.LUT_addWidth(LUT_addWidth),  		// World length of the Look-up table
		.dWL(WIDTH_mat+1+3),						// Signal symbols whether to use Iterating
		.WLO(WIDTH_mat+2)
    )
	Fang_Square_Root_Reciprocal_Ito_Iter1_pipe
	(
		.CLK(CLK), 
		.nRST(nRST), 								// negative reset
		.CE(CE), 
		.din(mati), 
		.dout(mati_tmp)							// format of the result is 1.WLO_tmp-1 = 1.(WI+WF+max(WI,WF)-1)
	);

//	------------------------------------------------
// ------------------------------------------------------------------------
// -- process the reciprocal for the exponential part and mantissa part
	reg [WIDTH_exp-1:0] bias = (2**(WIDTH_exp-1))-1;	//calculate the bias
	reg [WIDTH_exp-1:0] diff;									// difference between the exponent part and bias
	wire [WIDTH_exp-1:0] diff_delay;	
	
	reg [52:0] sqrttwo = 53'b1_0110101000001001111001100110011111110011101111001101;
	mult_unsigned_pipe
	 #(.WI1(1),   .WF1(WIDTH_mat+1), .WI2(1),   	  .WF2(WIDTH_mat+1),   .WIO(1),    		.WFO(WIDTH_mat+1)) 
	multiplier_scaling
	  (.CLK(CLK), .RST(nRST), .in1(mati_tmp), .in2(sqrttwo[52:(53-WIDTH_mat-2)]),  .out(mati_tmp2));	

	always @ * begin
		if(!nRST) begin
			diff <= 0;
		end else begin
			if (exp>=bias) begin
				diff <= exp - bias;
			end else begin
				diff <= bias - exp;
			end
		end
	end
	
	always @ (posedge CLK) begin
		if(!nRST) begin
			exp_out <= 0;
			mati_out <= 0;
		end else begin
			if (exp_delay>=bias) begin
				if (diff_delay[0]==1'b0) begin
					exp_out <= bias - (exp_delay - bias)/2 - 1; // minus here is for normalizing
					mati_out <= mati_tmp_delay[WIDTH_mat-1:0];
				end else begin
					exp_out <= bias - (exp_delay - bias)/2 - 1; // minus here is for balancing the "positive exp into negative"
					mati_out <= mati_tmp2[WIDTH_mat :1];
				end
			end else begin
				if (diff_delay[0]==1'b0) begin
					exp_out  <= bias + (bias - exp_delay)/2;
					mati_out <= mati_tmp_delay[WIDTH_mat-1:0]-1; // minus here is for normalizing
				end else begin
					exp_out  <= bias + (bias - exp_delay)/2;
					mati_out <= mati_tmp2[WIDTH_mat :1];
				end
			end
		end
	end 


// --------------------------------------------------------------------------------------------------------- //

	localparam PIP_exce_in = 11; //8
	localparam PIP_result = 1;
	localparam PIP_exp = 11;
	localparam PIP_diff = 11;
	localparam PIP_sign = 12; //8
	localparam PIP_mati_tmp = 2;

// ------------------Buffer for pipeline ---------------------- //
	reg [WIDTH_mat+WIDTH_exp:0] buffer_result [1: PIP_result];		// 
	reg [1: PIP_exce_in] buffer_exce_in;
	reg [WIDTH_exp-1:0] buffer_exp [1:PIP_exp];
	reg [WIDTH_exp-1:0] buffer_diff [1:PIP_diff];
	reg [1: PIP_sign] buffer_sign;
	reg [WIDTH_mat:0] buffer_mati_tmp [1 : PIP_mati_tmp];
	
	integer i;

	always @(posedge CLK) begin
		if (!nRST) begin
//			for (i=1; i<=PIP_result; i=i+1)
//				buffer_result[i] <= 0;
				
			for (i=1; i<=PIP_exce_in; i=i+1)
				buffer_exce_in[i] <= 0;

			for (i=1; i<=PIP_exp; i=i+1)
				buffer_exp[i] <= 0;

			for (i=1; i<=PIP_diff; i=i+1)
				buffer_diff[i] <= 0;

			for (i=1; i<=PIP_sign; i=i+1)
				buffer_sign[i] <= 0;

			for (i=1; i<=PIP_mati_tmp; i=i+1)
				buffer_mati_tmp[i] <= 0;
				
		end else begin
//			buffer_result[1] <= {sign_delay, exp_out[WIDTH_exp-1:0], mati_out};
//			for (i=2; i<=PIP_result; i=i+1)
//				buffer_result[i] <= buffer_result[i-1];
				
			buffer_exce_in[1] <= exce_in;
			for (i=2; i<=PIP_exce_in; i=i+1)
				buffer_exce_in[i] <= buffer_exce_in[i-1];

			buffer_exp[1] <= exp;
			for (i=2; i<=PIP_exp; i=i+1)
				buffer_exp[i] <= buffer_exp[i-1];

			buffer_diff[1] <= diff;
			for (i=2; i<=PIP_diff; i=i+1)
				buffer_diff[i] <= buffer_diff[i-1];

			buffer_sign[1] <= sign;
			for (i=2; i<=PIP_sign; i=i+1)
				buffer_sign[i] <= buffer_sign[i-1];

			buffer_mati_tmp[1] <= mati_tmp;
			for (i=2; i<=PIP_mati_tmp; i=i+1)
				buffer_mati_tmp[i] <= buffer_mati_tmp[i-1];

		end
	end

	assign sign_delay = buffer_sign[PIP_sign];
//	assign result = buffer_result[PIP_result];
	assign exp_delay = buffer_exp[PIP_exp];
	assign diff_delay = buffer_diff[PIP_diff];
	assign sign_delay = buffer_sign[PIP_sign];
	assign mati_tmp_delay = buffer_mati_tmp[PIP_mati_tmp];
	assign exce_in_delay = buffer_exce_in[PIP_exce_in];


always @ * begin
	if(exce_in_delay||exp_out[WIDTH_exp]) 
		exce_out <= 1'b1;
	else
		exce_out <= 1'b0;

	result <= {sign_delay, exp_out[WIDTH_exp-1:0], mati_out};
end

// --------------------------------------------------------------------------------------------------------- //

endmodule
