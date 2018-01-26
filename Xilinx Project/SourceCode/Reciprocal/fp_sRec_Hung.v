`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:34:08 01/12/2015 
// Design Name: 
// Module Name:    fp_sRec_Hung 
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
`define WLO_tmp 		(WI>=WF)? (WFO+WI+1) : (WFO+WF+1)
`define WLO_tmp_1 	(WI>=WF)? (WFO+WI) : (WFO+WF)
`define WIO_APP 		(WI>=WF)? (WIO+WI-1) : (WIO+WF-1)
`define WIO_APP_1 	(WI>=WF)? (WIO+WI-2) : (WIO+WF-2)
`define WLO_TOTAL_1  (WI>=WF)? (WFO+WI+WIO+WI-1) : (WFO+WF+WIO+WF-1)
`define WLO_tmp_1_trim 	(WI>=WF)? (WFO+WI+WIO) : (WFO+WF+WIO)
`define WLO_tmp_2 	(WI>=WF)? (WFO+WI-1) : (WFO+WF-1)
`define WLO_tmp_trim_WFO (WI>=WF)? (WFO+WI-WFO) : (WFO+WF-WFO)
`define WL_1 WL-0
module fp_sRec_Hung
	#(parameter 
					WI = 8,			 		// input integer size
					WF = 8,			 		// input fractional size
					WL = WI + WF,	 
					WIO = WF,   	 		// output integer size, by default 
					WFO = WI,     	 		// output fractional size
					LUT_addWidth = 5,
					LUT_bits = 8
	 )
	 (input 		CLK, 				 		// clock
					nRST, 				 	// negative reset
					CE,						// clock enable
	  input     [WI+WF-1 : 0] 	 din,	// data input
	  output reg[WIO+WFO-1 : 0] dout // result
    );
	//localparam WL_2 = WL-1;
	
	// intermediate register, wires and memories
	reg sym_np;						 // register to save whether the input is positive or negative
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
	wire [`WLO_tmp_1 : 0] out;
	reg  [`WIO_APP_1 : 0] app_zero;
	wire [`WLO_TOTAL_1 : 0] result_tmp;
	reg  [`WLO_TOTAL_1 : 0] result_tmp2;
	
	Reciprocal_Cascaded_Hung
	#(
		.WL(WI+WF),								// Total word length of input
		.LUT_bits(LUT_bits),					// Look-up table bits
		.LUT_addWidth(LUT_addWidth),  	// World length of the Look-up table
		.WLO(`WLO_tmp)
    )
	Fang_Reciprocal_Hung
	(
		.CLK(CLK), 
		.nRST(nRST), 							// negative reset
		.CE(CE), 
		.din(in_s), 
		.dout(out)								// format of the result is 1.WLO_tmp-1 = 1.(WI+WF+max(WI,WF)-1)
	);
	
	// append the zeros on the integer part
	assign result_tmp = {app_zero, out};
	
	// de-normalization 
	always @ * begin
		app_zero = 0;
		if (sym==1'b0) 
			result_tmp2 = result_tmp >> e_b;
		else // sym==1'b1
			result_tmp2 = result_tmp << e_b;
	end
	
	//--------------------adjusting the bitwidth for the integer and fractional part----------------------------------------------------------
	reg [WIO-1 : 0] outI;												//The integer part of the output
	reg [WFO-1 : 0] outF;
	always @ * begin
		outI = result_tmp2[`WLO_tmp_1_trim : `WLO_tmp_1];
		outF = result_tmp2[`WLO_tmp_2 : `WLO_tmp_trim_WFO];   //WFO<(WF1+WF2): Truncate bits from the LSB bits
	end
	//--------------------registering the output----------------------------------------------------------------------------------
	wire [WIO+WFO-1 : 0] out_tmp;
	assign out_tmp = {outI,outF};
	
	always @* begin
		if (out_tmp==0) // Overflow control
			if (din[WL-1]==1'b0)
				dout = {{1'b0},{{WL-1}{1'b1}}}; 
			else
				dout = {{1'b1},{{WL-1}{1'b0}}};
		else if (sym_np==1'b0)
			dout = out_tmp;												//modified practical use
		else
			dout = ~out_tmp+1;
	end

endmodule

