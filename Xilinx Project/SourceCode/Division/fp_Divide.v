`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  VLSI Design and Test Lab
// Engineer:  Fang Lin
// Create Date:    11:54:21 09/21/2015 
// Design Name: 
// Module Name:    fp_Divide 
// Project Name: 
// Target Devices: Virtex-7
// Tool versions: ISE14.6
// Description: : 
//
//////////////////////////////////////////////////////////////////////////////////
module fp_Divide
	#(parameter 
					WI1 = 4,			 		// input 1 integer size
					WF1 = 4,			 		// input 1 fractional size
					WI2 = 4,			 		// input 2 integer size
					WF2 = 4,			 		// input 2 fractional size
					WL1 = WI1 + WF1,	 
					WL2 = WI2 + WF2,
					WIO = WI1,   	 		// output integer size
					WFO = WF1,     	   // output fractional size
					LUT_bits = WL2,
					LUT_addWidth = 4
	 )
	 (input 		CLK, 				 			// clock
					nRST, 				 		// negative reset
					CE,							// clock enable
	  input     [WI1+WF1-1 : 0] 	 OP1,	// data input
	  input     [WI2+WF2-1 : 0] 	 OP2,	// data input
	  output    [WIO+WFO-1 : 0]    dout // result
    );

// inner datapath parameters
localparam WFO_REC = WL2;
localparam WIO_REC = WF2+2;

// Main reciprocal structure, format is 1.WF
wire [WIO_REC+WFO_REC-1 : 0] rec_result;

// 1/b
	fp_sRec_Hung
	#
	(
		.WI(WI2),
		.WF(WF2),
		.WIO(WIO_REC),
		.WFO(WFO_REC),
		.LUT_addWidth(LUT_addWidth),
		.LUT_bits(LUT_bits)
	)
	Fang_fp_sRec
	(
		.CLK(CLK), 
		.nRST(nRST), 
		.CE(CE), 
		.din(OP2), 
		.dout(rec_result)
	);

// a * 1/b
	sMult 
	 #(.WI1(WI1),   .WF1(WF1), .WI2(WIO_REC),  .WF2(WFO_REC),   .WIO(WIO),   .WFO(WFO)) 
	result_multiplier
	  (.CLK(CLK), .RST(nRST), .in1(OP1), .in2(rec_result),  .out(dout));	

endmodule
