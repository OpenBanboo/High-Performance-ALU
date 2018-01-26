`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 		 VLSI Design and Test Lab
// Engineer: 	 	 Christian Lin
// 
// Create Date:    16:24:49 09/22/2015
// Design Name: 	 floating point multiplier
// Module Name:    multiplier_float 
// Project Name: 	 Floating-point IIR Filter
// Target Devices: 
// Tool versions:  14.6
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module flot_mul_pipe
				#(parameter 		  WIDTH = 64,					 //The total bits of the inputs
										  WIDTH_exp = 11,				 //The bitwidth of the exponent part
										  WIDTH_mat = 52)				 //The bitwidth of the mantissa part
				( input 				  CLK,							 //clock				 
										  nRST,							 //negative reset
				  input [WIDTH-1:0] OP1,							 //input1
										  OP2,							 //input2
				  input 			 exce_in,							 //execption in signal
				  output reg 	exce_out,							 //exception out
				  output [WIDTH_mat+WIDTH_exp:0] result); //final result, width is mantissa part + exponent part + sign bit

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

// ----------------------------------------------------------------------------------------------------------------- //
// ----------------------------------------------------- exponents  ------------------------------------------------ //
// ***************************
reg [WIDTH_exp:0]   sum_exp, sum_exp_0, sum_exp_1, sum_exp_2;									//sum of exponent with one bit wider than the exponent of operands
reg [WIDTH_exp-1:0] BIAS = (2**(WIDTH_exp-1))-1;		//calculate the bias
// ***************************

// ------------------------------------------------- Mantissas  -------------------------------------------- //
// ***************************
localparam WIDTH_mm  = (WIDTH_mat+1)*2; 		//width of the product of the two mantissas
localparam WIDTH_poi = log2(WIDTH_mm);	 		//find the minimal bitwith of the pointer used below
reg [WIDTH_mm-1 :0]  mul_mat, mul_mat_0, mul_mat_1, mul_mat_2;				 		//store the product of the two mantissas
reg [WIDTH_poi-1:0] 	pointer;				 		//used for pointing to the first one on the left
reg [WIDTH_exp  :0]  tmp_exp;				 		//store the reuslt after multiplier the mantissa and has some effects on exponent
reg 						exception;			 		//exception signal

reg [WIDTH_mm-1 :0]  tmp_mat;
reg [WIDTH_mat  :0]  tmp_mat_r;  		 		//Store the mantissa value after rounding, 
															//width is 1 bit more than final, 1 bit larger than tmp_mat, for deducing the rounding bit
reg [WIDTH_exp-1:0]  tmp_exp_r;			 		//Store the exponent value after normalizing
reg sign_L;


// --------------------------------------------------------------------------------------------------------- //
														// Pipeline Stage 1 //
// --------------------------------------------------------------------------------------------------------- //										
always @(posedge CLK) begin
		if(!nRST) begin
			sum_exp  <= 0;
			mul_mat	<= 0;
			sum_exp_0 <= 0;
			mul_mat_0 <= 0;
			sign_L <= 0;

		end else begin
			//fetch out the exponent part and subtract the BIAS
			sum_exp_0 <= OP1[WIDTH-2:WIDTH-(WIDTH_exp+1)] + OP2[WIDTH-2:WIDTH-(WIDTH_exp+1)] - BIAS;  // - ((2**(WIDTH_exp-1))-1)
			sum_exp <= sum_exp_0;
			// ***************************
			// exception out will be set to 1 when exception in is 1 or exponent part is out of bound after calculation
			(* USE_dsp48 = "no" *)
			mul_mat_0 <= {1'b1, OP1[WIDTH_mat-1:0]} * {1'b1, OP2[WIDTH_mat-1:0]};
			mul_mat <= mul_mat_0;
			// Sign of the result depends on wheter the signs of the two operands are the same.
			// If they are the same, make sign bit as 0 else 1.
			if(OP1[WIDTH-1]^OP2[WIDTH-1])
				sign_L <= 1'b1;
			else
				sign_L <= 1'b0;
						
		end
end

// --------------------------------------------------------------------------------------------------------- //

// --------------------------------------------------------------------------------------------------------- //
														// Pipeline Stage 2 //
// --------------------------------------------------------------------------------------------------------- //										
always @(posedge CLK) begin
		if(!nRST) begin
			tmp_exp  <= 0;
			tmp_mat	<= 0;
		end else begin
// ---------------------------------------- Normalization & Rounding  -------------------------------------- //
		// ******* Normalization ******** 	
			if (mul_mat[WIDTH_mm-1] == 1'b1) begin										 		// [A]
				tmp_exp <= sum_exp[WIDTH_exp-1:0] + 1;
				tmp_mat <= mul_mat;
			end
			else begin 																		 	 		 // [A] mul_mat[WIDTH_mm-2] == 1'b1
				tmp_exp <= sum_exp[WIDTH_exp-1:0];
				tmp_mat <= mul_mat << 1;	
			end																				   		 // [A] 
		end
end
// --------------------------------------------------------------------------------------------------------- //

// --------------------------------------------------------------------------------------------------------- //
												// Combinational Logics ///

always @ (posedge CLK) begin

// ******* Rounding **************
// ----  Round to nearnest ---- //
	if(!nRST) begin
		tmp_exp_r <= 0;
		tmp_exp_r <= 0;
	end
	else begin
		if (tmp_mat[WIDTH_mm-(WIDTH_mat+1)-1]==1'b1) begin					 		 //round bit  == 1
			if(tmp_mat[WIDTH_mm-(WIDTH_mat+1)-2:0]!=0) begin				 		 //sticky bit == 1
				tmp_mat_r <= tmp_mat[WIDTH_mm-1:WIDTH_mm-(WIDTH_mat+1)] + 1;	 //the width of tmp_mat_r is one larger WIDTH_mat
			end
			else begin																	 		 //sticky bit == 0 
				tmp_mat_r <= tmp_mat[WIDTH_mm-1:WIDTH_mm-(WIDTH_mat+1)];
			end
		end
		else begin																		//round bit == 1, no change
			tmp_mat_r <= tmp_mat[WIDTH_mm-1:WIDTH_mm-(WIDTH_mat+1)];
		end

		tmp_exp_r <= tmp_exp[WIDTH_exp-1:0];	
	end

end //always
// --------------------------------------------------------------------------------------------------------- //

// ------------------------------------------------- exceptions  ------------------------------------------- //
// exception out will be set to 1 when exception in is 1 or exponent part is out of bound after calculation
always @(posedge CLK) begin
	if(!nRST)
		exce_out <= 1'b0;
	else if(buffer_exce_in[PIP_exce_in]==1) 
		exce_out <= 1'b1;
	else
		exce_out <= 1'b0;
end
// --------------------------------------------------------------------------------------------------------- //

//	-----------------------------------------------------------------------------------------------------
	localparam PIP_sign_L = 3;
	localparam PIP_exce_in = 5;
	
	localparam PIP_result = 2;



	reg [WIDTH-1:0] buffer_result [1: PIP_result];		// 
	reg [1:PIP_exce_in] buffer_exce_in;
	reg [1:PIP_sign_L] buffer_sign_L;

	integer i;
	
	always @(posedge CLK) begin
		if (!nRST) begin
			for (i=1; i<=PIP_result; i=i+1)
				buffer_result[i] <= 0;

			for (i=1; i<=PIP_sign_L; i=i+1)
				buffer_sign_L[i] <= 0;

			for (i=1; i<=PIP_exce_in; i=i+1)
				buffer_exce_in[i] <= 0;

		end else begin
			buffer_result[1] <= {buffer_sign_L[PIP_sign_L], tmp_exp_r, tmp_mat_r[WIDTH_mat-1:0]};
			for (i=2; i<=PIP_result; i=i+1)
				buffer_result[i] <= buffer_result[i-1];

			buffer_sign_L[1] <= sign_L;
			for (i=2; i<=PIP_sign_L; i=i+1)
				buffer_sign_L[i] <= buffer_sign_L[i-1];

			buffer_exce_in[1] <= exce_in;
			for (i=2; i<=PIP_exce_in; i=i+1)
				buffer_exce_in[i] <= buffer_exce_in[i-1];
		end
	end

	assign result = buffer_result[PIP_result];

//	-----------------------------------------------------------------------------------------------------
// Output
/*
reg [WIDTH-1:0] result_0;
always @(posedge CLK) begin
	if(!nRST) begin
		result_0 <= 0;
		result <= 0;
	end else begin
		result <= {sign_L_delay2, tmp_exp_r, tmp_mat_r[WIDTH_mat-1:0]};
		result <= result_0;
	end
end
*/
//	-----------------------------------------------------------------------------------------------------

endmodule
