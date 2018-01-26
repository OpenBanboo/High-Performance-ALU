`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   13:57:59 09/21/2015
// Design Name:   fp_Divide
// Module Name:   C:/Users/User/Google Drive/2015/Thesis backup/RecSqr11/RecSqr11/SourceCodes/Division/fp_Divide_tb.v
// Project Name:  test
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: fp_Divide
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module fp_Divide_tb;

	parameter 
				WI1 = 12,			 		// input integer size
				WF1 = 12,			 		// input fractional size
				WI2 = 12,			 		// input integer size
				WF2 = 12,			 		// input fractional size
				WL1 = WI1 + WF1,	 
				WL2 = WI2 + WF2,
				WIO = 12,   	 			// output integer size
				WFO = 12,     	   		// output fractional size
				WLO = WIO + WFO,
				LUT_bits = 24,
				LUT_addWidth = 12;

	// Inputs
	reg CLK;
	reg nRST;
	reg CE;
	reg [WL1-1:0] OP1;
	reg [WL2-1:0] OP2;

	// Outputs
	wire [WLO-1:0] dout;

	// Real number presentation
	real real_OP1, real_OP2;
	real real_dout;
// ================================  Function Definition  =======================================//

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
	// Present the fixed point number into real number
	function real unsigned_fixedToFloat;
		input [2047:0] in;	//should cover every bit of the maximal value
		input integer WI;
		input integer WF;
		integer idx;
		real retVal;
		begin
			retVal = 0;
			for (idx = 0; idx < WI+WF; idx = idx + 1) begin
				if(in[idx] == 1'b1) begin
					retVal = retVal + (2.0**(idx-WF));
				end
			end
		unsigned_fixedToFloat = retVal;
		end
	endfunction
	
	// ================================Function Definition==================================//
	function real fixedToFloat;
		input [2047:0] in;
		input integer WI;
		input integer WF;
		integer idx;
		real retVal;
		begin
			retVal = 0;
			for (idx = 0; idx < WI+WF-1; idx = idx + 1) begin
				if(in[idx] == 1'b1) begin
					retVal = retVal + (2.0**(idx-WF));
				end
			end
		fixedToFloat = retVal - (in[WI+WF-1] * (2.0**(WI-1)));
		end
	endfunction
// ======================================================================================//
	
//==================================================================================================//	

//=====================================  clock generator  ==========================================//
	parameter ClockPeriod = 2;	// Clock period
	initial 	 CLK = 0;
	always # (ClockPeriod/2) CLK = ~CLK;
//==================================================================================================//

	// Instantiate the Unit Under Test (UUT)
	fp_Divide 
	#
	(
		.WI1(WI1),
		.WF1(WF1),
		.WI2(WI2),
		.WF2(WF2),
		.WIO(WIO),
		.WFO(WFO),
		.LUT_addWidth(LUT_addWidth),
		.LUT_bits(LUT_bits)
	)
	Fang_Divider 
	(
		.CLK(CLK), 
		.nRST(nRST), 
		.CE(CE), 
		.OP1(OP1), 
		.OP2(OP2), 
		.dout(dout)
	);

	initial begin

		$readmemb("LUT_rec_Hung_prar_24bit.txt", fp_Divide_tb.Fang_Divider.Fang_fp_sRec.Fang_Reciprocal_Hung.LUT); 
		
		// Initialize Inputs
		nRST = 0; CE = 0; 						// reset
		@(posedge CLK); CE = 1; 
		nRST = 1;  									// start

		OP1 = 24'b000000000001_100000000000; OP2 = 24'b000000001001_100000000000; @(posedge CLK); //000000000000.001010000110
		OP1 = 24'b000001011001_100000000000; OP2 = 24'b000000001111_100110000000; @(posedge CLK); //000000000000.001010000110
		OP1 = 24'b000000000000_001110000000; OP2 = 24'b000000000000_001011000000; @(posedge CLK); //000000000000.001010000110

		// Wait 100 ns for global reset to finish
		$finish;
        
		// Add stimulus here

	end

	// -- input -- //	
	always @ OP1 real_OP1 = fixedToFloat(OP1, WI1, WF1);
	always @ OP2 real_OP2 = fixedToFloat(OP2, WI2, WF2);

	// -- output -- //	
	always @ dout real_dout = fixedToFloat(dout, WIO, WFO);

endmodule

