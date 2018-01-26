`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 		 VLSI Design and Test Lab
// Engineer: 	 	 Christian Lin
// 
// Create Date:    16:24:49 04/29/2014 
// Design Name: 	 floating point multiplier
// Module Name:    multiplier_float 
// Project Name: 	 Floating-point IIR Filter
// Target Devices: 
// Tool versions:  14.6
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module multiplier_float
				#(parameter 		  WIDTH = 32,					 //The total bits of the inputs
										  WIDTH_exp = 8,				 //The bitwidth of the exponent part
										  WIDTH_mat = 23)				 //The bitwidth of the mantissa part
				( input 				  CLK,							 //clock				 
										  RST,							 //negative reset
				  input [WIDTH-1:0] OP1,							 //input1
										  OP2,							 //input2
				  input 			 exce_in,							 //execption in signal
				  output reg 	exce_out,							 //exception out
				  output reg [WIDTH_mat+WIDTH_exp:0] result); //final result, width is mantissa part + exponent part + sign bit

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
reg [WIDTH_exp:0]   sum_exp;									//sum of exponent with one bit wider than the exponent of operands
reg [WIDTH_exp-1:0] BIAS = (2**(WIDTH_exp-1))-1;		//calculate the bias
// ***************************
//fetch out the exponent part and subtract the BIAS
always @* begin
	sum_exp <= OP1[WIDTH-2:WIDTH-(WIDTH_exp+1)] + OP2[WIDTH-2:WIDTH-(WIDTH_exp+1)] - BIAS;  // - ((2**(WIDTH_exp-1))-1)
end
// --------------------------------------------------------------------------------------------------------- //

// ------------------------------------------------- Mantissas  -------------------------------------------- //
// ***************************
localparam WIDTH_mm  = (WIDTH_mat+1)*2; 		//width of the product of the two mantissas
localparam WIDTH_poi = log2(WIDTH_mm);	 		//find the minimal bitwith of the pointer used below
reg [WIDTH_mm-1 :0]  mul_mat;				 		//store the product of the two mantissas
reg [WIDTH_poi-1:0] 	pointer;				 		//used for pointing to the first one on the left
reg [WIDTH_exp  :0]  tmp_exp;				 		//store the reuslt after multiplier the mantissa and has some effects on exponent
reg 						exception;			 		//exception signal
reg [WIDTH_mm-1 :0]  tmp_mat;
reg [WIDTH_mat  :0]  tmp_mat_r;  		 		//Store the mantissa value after rounding, 
															//width is 1 bit more than final, 1 bit larger than tmp_mat, for deducing the rounding bit
reg [WIDTH_exp-1:0]  tmp_exp_r;			 		//Store the exponent value after normalizing
//reg [WIDTH_mat	 :0]  mantissa1, mantissa2;	//variable to store the appended 1 mantissa
// ***************************
// exception out will be set to 1 when exception in is 1 or exponent part is out of bound after calculation
always @* begin
	mul_mat = {1'b1, OP1[WIDTH_mat-1:0]} * {1'b1, OP2[WIDTH_mat-1:0]};

// ---------------------------------------- Normalization & Rounding  -------------------------------------- //
// ******* Normalization ******** 	
	if (mul_mat[WIDTH_mm-1] == 1'b1) begin										 		// [A]
		tmp_exp = sum_exp[WIDTH_exp-1:0] + 1;
		tmp_mat = mul_mat;
		if(tmp_exp[WIDTH_exp]==1'b1)
			exception = 1;
		else
			exception = 0;
	end
	else begin 																		 	 		 // [A] mul_mat[WIDTH_mm-2] == 1'b1
		tmp_exp = sum_exp[WIDTH_exp-1:0];
		tmp_mat = mul_mat << 1;	
		exception = 0;		
	end																				   		 // [A] 
// *******************************
// ******* Rounding **************
// ----  Round to nearnest ---- //
	if (exception==1'b0) begin

		if (tmp_mat[WIDTH_mm-(WIDTH_mat+1)-1]==1'b1) begin					 		 //round bit  == 1
			if(tmp_mat[WIDTH_mm-(WIDTH_mat+1)-2:0]!=0) begin				 		 //sticky bit == 1
				tmp_mat_r = tmp_mat[WIDTH_mm-1:WIDTH_mm-(WIDTH_mat+1)] + 1;		 //the width of tmp_mat_r is one larger WIDTH_mat
				// ** if there is an overflow on the mantissa, change it back and add 1 to the exponent
				if (tmp_mat_r<tmp_mat[WIDTH_mm-1:WIDTH_mm-(WIDTH_mat+1)]) begin //[C] out of bond, overflow happens
					tmp_exp_r = tmp_exp[WIDTH_exp-1:0] + 1;					 //exponent add 1
					tmp_mat_r = 0;
					tmp_mat_r[WIDTH_mat] = 1'b1;
					// ** evaluate there is an overflow on the exponent, if so, exception out set to 1
					if (tmp_exp_r==0) 
						exception = 1;													 //set exception to 1
					else
						exception = 0;
				end
				else begin
					tmp_exp_r = tmp_exp[WIDTH_exp-1:0];							 //no change for exponent
				end	
			end
			else begin																	 //sticky bit == 0 
				tmp_mat_r = tmp_mat[WIDTH_mm-1:WIDTH_mm-(WIDTH_mat+1)];
				tmp_exp_r = tmp_exp[WIDTH_exp-1:0];
			end
		end
		else begin																		//round bit == 1, no change
			tmp_mat_r = tmp_mat[WIDTH_mm-1:WIDTH_mm-(WIDTH_mat+1)];
			tmp_exp_r = tmp_exp[WIDTH_exp-1:0];			
		end
	end // exception evaluation 

end //always
// --------------------------------------------------------------------------------------------------------- //

// ------------------------------------------------- exceptions  ------------------------------------------- //
// exception out will be set to 1 when exception in is 1 or exponent part is out of bound after calculation
always @* begin
	if(exce_in||sum_exp[WIDTH_exp]||exception) 
		exce_out <= 1'b1;
	else
		exce_out <= 1'b0;
end
// --------------------------------------------------------------------------------------------------------- //

//	-----------------------------------------------------------------------------------------------------
reg sign_L;			//final result's sign bit
// Sign of the result depends on wheter the signs of the two operands are the same.
// If they are the same, make sign bit as 0 else 1.
always @ * begin							
	if(OP1[WIDTH-1]^OP2[WIDTH-1])
		sign_L = 1'b1;
	else
		sign_L = 1'b0;
end
//	-----------------------------------------------------------------------------------------------------

//	-----------------------------------------------------------------------------------------------------
// Output
always @ * begin
	if(!RST)
		result <= 0;
	else if (exce_out) begin				//there is a exception in
		result <= 0;
	end
	else
		result <= {sign_L, tmp_exp_r, tmp_mat_r[WIDTH_mat-1:0]};
end
//	-----------------------------------------------------------------------------------------------------

endmodule
