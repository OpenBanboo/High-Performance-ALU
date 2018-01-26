`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:12:38 11/10/2014 
// Design Name: 
// Module Name:    fp_sIsqrt 
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
`define WLO_tmp 	   (WI>=WF)? (WFO + (WI/2) + 1) : (WFO + (WF/2) + 1)  //
`define WLO_tmp_1 	(WI>=WF)? (WFO + (WI/2)) : (WFO + (WF/2))  		   //
`define WIO_APP 		(WI>=WF)? (WIO + (WI/2) - 1) : (WIO + (WF/2) - 1)
`define WIO_APP_1 	(WI>=WF)? (WIO + (WI/2) - 2) : (WIO + (WF/2) - 2)
`define WLO_TOTAL_1  (WI>=WF)? (WFO+(WI/2)-1+WIO+(WI/2)) : (WFO+(WF/2)-1+WIO+(WF/2))
`define WIO_tmp		(WI>=WF)? (WIO + (WI/2)) : (WIO + (WF/2))  			//
`define WFO_tmp		(WI>=WF)? (WFO + (WI/2)) : (WFO + (WF/2)) 			//
`define WLO_tmp_1_trim 	 (WI>=WF)? (WFO+(WI/2)+WIO) : (WFO+(WF/2)+WIO)
`define WLO_tmp_2 		 (WI>=WF)? (WFO+(WI/2)-1) 	 : (WFO+(WF/2)-1)
`define WLO_tmp_trim_WFO (WI>=WF)? (WFO+(WI/2)-WFO) : (WFO+(WF/2)-WFO)
`define WLO_pos 		32-((WI>=WF)? (WFO + (WI/2) + 1) : (WFO + (WF/2) + 1))

module fp_sIsqrt
	#(parameter 
					WI = 4,			 		// input integer size
					WF = 4,			 		// input fractional size
					WL = WI + WF,	 
					WIO = WF,   	 		// output integer size
					WFO = WI,     	 		// output fractional size,
					dWL = WL+3,
					LUT_bits = 8,
					LUT_addWidth = 4
	 )
	 (input 		CLK, 				 		// clock
					nRST, 				 	// negative reset
					CE,						// clock enable
	  input     [WI+WF-1 : 0] 	 din,	// data input
	  output  reg  [WIO+WFO-1 : 0] dout // result
    );

	// intermediate register, wires and memories
	reg sym_np;						 		// register to save whether the input is positive or negative
	reg [WL-1:0] in;
	always @ * begin
		if (din[WL-1]==1'b0) begin
			sym_np = 1'b0;
			in = din;
		end else begin 
			sym_np = 1'b1;
			in = (~din)+1;
		end
	end

	// -- priority encoder: to shift the input into WIL=1
	reg [WI+WF-1:0] e_b;
	reg [WI+WF-1:0] e_b_by2;
	reg [WI+WF-1:0] e;
	reg sym;
	
	integer counter_e; //The counter for finding the first 1
	always @ * begin
		for (counter_e=WI+WF-1; counter_e >= 0; counter_e = counter_e-1)
			if (in[WI+WF-counter_e-1]) e = counter_e;
	end
	// -- shfit
	reg [WL-1:0] in_s;	
	always @* begin	
		in_s = in << e;
		if (WI>=(e+1)) begin
			sym = 1'b0;  // denotes normalization need to shift the "node" to left, which means shift the register to right
			e_b = WI-(e+1);
		end else if ((e+1)> WI) begin
			sym = 1'b1;  // denotes normalization need to shift the "node" to right, which means shift the register to left
			e_b = (e+1)-WI;
		end 
	end 

	// Main reciprocal structure, format is 1.WF
	wire [`WLO_tmp_1 : 0] out;					// output of the normalized result
	reg  [`WIO_APP_1 : 0] app_zero;			// 
	wire [`WLO_TOTAL_1 : 0] result_tmp;
	wire [`WLO_TOTAL_1 : 0] result_tmp_1;
	reg  [`WLO_TOTAL_1 : 0] accFP;
	
	Square_Root_Reciprocal_Cascaded_NR_2
	#(
		.WL(WI+WF),									// Total word length of input
		.LUT_bits(LUT_bits),						// Look-up table bits
		.LUT_addWidth(LUT_addWidth),  		// World length of the Look-up table
		.dWL(dWL),									// Signal symbols whether to use Iterating
		.WLO(`WLO_tmp)
    )
	Fang_Root_Reciprocal_Cascaded_NR_2
	(
		.CLK(CLK), 
		.nRST(nRST), 								// negative reset
		.CE(CE), 
		.din(in_s), 
		.dout(out)									// format of the result is 1.WLO_tmp-1 = 1.(WI+WF+max(WI,WF)-1)
	);

	// append the zeros on the integer part
	assign result_tmp = {app_zero, out};

	reg [31:0] isqrttwo = 32'b0_1011_0101_0000_0100_1111_0011_0011_001;
	mult_unsigned 
	 #(.WI1(1),   .WF1(`WLO_tmp_1), .WI2(1),   .WF2(`WLO_tmp_1),   .WIO(`WIO_tmp), .WFO(`WFO_tmp)) 
	multiplier_scaling
	  (.CLK(CLK), .RST(nRST),       .in1(out), .in2(isqrttwo[31:`WLO_pos]),   .out(result_tmp_1));	

	// Scaling and denormalizing      
	always @ * begin
		app_zero = 0;
		e_b_by2 = e_b/2;
		if (e_b[0]==1'b1) begin				  		  // (mod(L,2)==1)
			if(sym==1'b0) 						  		  // shift right
				accFP = result_tmp_1 >> (e_b_by2); // shft = ceil(L/2);  cFP_temp = fpSHL(accFP, shft);
			else
				accFP = result_tmp_1 << (e_b_by2+1); // shift left  shft = ceil(L/2);  cFP_temp = fpSHL(accFP, shft);
		end else begin							  		  // (mod(L,2)==0)
			if(sym==1'b0) 						        // shift right
				accFP = result_tmp >> e_b_by2; 
			else
				accFP = result_tmp << e_b_by2; 		  // shift left
		end
	end

	//--------------------adjusting the bitwidth for the integer and fractional part----------------------------------------------------------
	reg [WIO-1 : 0]  outI;												//The integer part of the output
	reg [WFO-1 : 0]  outF;
	always @ * begin
		outI = accFP[`WLO_tmp_1_trim : `WLO_tmp_1];
		outF = accFP[`WLO_tmp_2 : `WLO_tmp_trim_WFO];   //WFO<(WF1+WF2): Truncate bits from the LSB bits
	end
	//--------------------registering the output----------------------------------------------------------------------------------
	wire [WIO+WFO-1 : 0] out_tmp;
	assign out_tmp = {outI,outF};

	always @* begin
		if (!nRST) begin
			dout = 0;
		end else begin
			if (sym_np==1'b0)
				dout = out_tmp;												//modified practical use
			else
				dout = ~out_tmp+1;
		end
	end
	
endmodule
