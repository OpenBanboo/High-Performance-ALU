`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   16:07:12 11/03/2014
// Design Name:   fp_sRec
// Module Name:   D:/Synchronous/Graduate Studies/Thesis/Summer2014/RecSqr9/SourceCodes/Reciprocal/fp_sRec_tb.v
// Project Name:  RecSqr9
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: fp_sRec
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module fp_sRec_tb;

	parameter 
				WI = 4,			 		// input integer size
				WF = 4,			 		// input fractional size
				WL = WI + WF,	 
				WIO = 4,   	 		// output integer size
				WFO = 4,
				LUT_addWidth = 4,
				LUT_bits = 8;   // output fractional size

	// Inputs
	reg CLK;
	reg nRST;
	reg CE;
	reg [WL-1:0] din;

	// Outputs
	wire [WL-1:0] dout;
	
	// Real number presentation
	real real_din;
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
	/*
	fp_sRec_Hung 
	#
	(
		.WI(WI),
		.WF(WF),
		.WIO(WIO),
		.WFO(WFO),
		.LUT_addWidth(LUT_addWidth)
	)
	Fang_fp_sRec
	(
		.CLK(CLK), 
		.nRST(nRST), 
		.CE(CE), 
		.din(din), 
		.dout(dout)
	);
	*/

	fp_sRec_Hung
	#
	(
		.WI(WI),
		.WF(WF),
		.WIO(WIO),
		.WFO(WFO),
		.LUT_addWidth(LUT_addWidth),
		.LUT_bits(LUT_bits)
	)
	Fang_fp_sRec
	(
		.CLK(CLK), 
		.nRST(nRST), 
		.CE(CE), 
		.din(din), 
		.dout(dout)
	);

	initial begin
	
		// initialize the Look-up Table
		// 24 bit
		//$readmemb("LUT_rec_NR_iter0_24bit_para.txt", fp_sRec_tb.Fang_fp_sRec.Fang_Reciprocal_Cascaded_NR_2.LUT); 
		$readmemb("LUT_rec_Hung_prar_24bit.txt", fp_sRec_tb.Fang_fp_sRec.Fang_Reciprocal_Hung.LUT); 
		//$readmemb("LUT_rec_Hung_20bits.txt", fp_sRec_tb.Fang_fp_sRec.Fang_Reciprocal_Hung.LUT);

		// 20 bit
		// $readmemb("LUT_rec_Hung_20bits.txt", fp_sRec_tb.Fang_fp_sRec.Fang_Reciprocal_Hung.LUT);
		//$readmemb("LUT_rec_NR_iter0_20bit_para.txt", fp_sRec_tb.Fang_fp_sRec.Fang_Reciprocal_Cascaded_NR_2.LUT); 

		// 16 bit
		// $readmemb("LUT_rec_Hung_16bits.txt", fp_sRec_tb.Fang_fp_sRec.Fang_Reciprocal_Hung.LUT);

		// 12 bit
		// $readmemb("LUT_rec_Hung_12bits.txt", fp_sRec_tb.Fang_fp_sRec.Fang_Reciprocal_Hung.LUT);


		// 10 bit
		// $readmemb("LUT_rec_Hung_10bits.txt", fp_sRec_tb.Fang_fp_sRec.Fang_Reciprocal_Hung.LUT);

		// 8 bit
		// $readmemb("LUT_rec_Hung_8bits.txt", fp_sRec_tb.Fang_fp_sRec.Fang_Reciprocal_Hung.LUT);


		
		// Initialize Inputs
		nRST = 0; CE = 0; 						// reset
		@(posedge CLK); CE = 1; 
		nRST = 1;  	// start

		// 8 bits
		// input: 4.4 output: 4.4
		// positive number
		/*
		din = 10'b0001_1000; @(posedge CLK); // input=1.5 result: 000000000000.101010101010 (0.6667)
	   din = 10'b0000_1001; @(posedge CLK); // input= 000000000000.000001000101 (0.00146484375) result: 000000111011.010111001100 (59.362318840579711) // very small number
		din = 10'b0000_0110; @(posedge CLK); // result: 001010101010.101010101010 result: 001010101010.101010101010  // very small positive number
		din = 10'b0000_0001; @(posedge CLK); // result: 001010101010.101010101010 result: 001010101010.101010101010  // very small positive number
		din = 10'b0011_0000; @(posedge CLK); // input=240 result: 001010101010.101010101010 result: 000000000000.000000000100  // large positive number
		din = 10'b0111_1111; @(posedge CLK); // input=2.047999755859375e+003 result: 001010101010.101010101010 result: 000000000000.000000000100  // large positive number

		// negative number
		din = 10'b1110_1000; @(posedge CLK);  // result: 111111011001.010110111101 // very small negative number
		din = 10'b1111_1111; @(posedge CLK);  // result: 111111011001.010110111101 // very small negative number
		din = 10'b1111_1010; @(posedge CLK);  // -0.37 result: 1111111101.0100101010
		din = 10'b1000_0000; @(posedge CLK);  //
		*/
		
		// 10 bits
		// input: 5.5 output: 5.5
		// positive number
		/*
		din = 10'b00001_10000; @(posedge CLK); // input=1.5 result: 000000000000.101010101010 (0.6667)
	   din = 10'b00000_01001; @(posedge CLK); // input= 000000000000.000001000101 (0.00146484375) result: 000000111011.010111001100 (59.362318840579711) // very small number
		din = 10'b00000_00110; @(posedge CLK); // result: 001010101010.101010101010 result: 001010101010.101010101010  // very small positive number
		din = 10'b00000_00001; @(posedge CLK); // result: 001010101010.101010101010 result: 001010101010.101010101010  // very small positive number
		din = 10'b00111_00000; @(posedge CLK); // input=240 result: 001010101010.101010101010 result: 000000000000.000000000100  // large positive number
		din = 10'b01111_11111; @(posedge CLK); // input=2.047999755859375e+003 result: 001010101010.101010101010 result: 000000000000.000000000100  // large positive number

		// negative number
		din = 10'b11110_10000; @(posedge CLK);  // result: 111111011001.010110111101 // very small negative number
		din = 10'b11111_11111; @(posedge CLK);  // result: 111111011001.010110111101 // very small negative number
		din = 10'b11111_11010; @(posedge CLK);  // -0.37 result: 1111111101.0100101010
		din = 10'b10000_00000; @(posedge CLK);  //
		*/
		
		// 12 bits
		// input: 6.6 output: 6.6
		// positive number
		/*
		din = 12'b000001_100000; @(posedge CLK); // input=1.5 result: 000000000000.101010101010 (0.6667)
	   din = 12'b000000_010001; @(posedge CLK); // input= 000000000000.000001000101 (0.00146484375) result: 000000111011.010111001100 (59.362318840579711) // very small number
		din = 12'b000000_000110; @(posedge CLK); // result: 001010101010.101010101010 result: 001010101010.101010101010  // very small positive number
		din = 12'b000000_000001; @(posedge CLK); // result: 001010101010.101010101010 result: 001010101010.101010101010  // very small positive number
		din = 12'b001111_000000; @(posedge CLK); // input=240 result: 001010101010.101010101010 result: 000000000000.000000000100  // large positive number
		din = 12'b011111_111111; @(posedge CLK); // input=2.047999755859375e+003 result: 001010101010.101010101010 result: 000000000000.000000000100  // large positive number

		// negative number
		din = 12'b111110_100000; @(posedge CLK);  // result: 111111011001.010110111101 // very small negative number
		din = 12'b111111_111111; @(posedge CLK);  // result: 111111011001.010110111101 // very small negative number
		din = 12'b111111_110101; @(posedge CLK);  // -0.37 result: 1111111101.0100101010
		din = 12'b100000_000000; @(posedge CLK);  //
		*/
		
		// 16 bits
		// input: 8.8 output: 8.8
		// positive number
		/*
		din = 16'b00000001_10000000; @(posedge CLK); // input=1.5 result: 000000000000.101010101010 (0.6667)
	   din = 16'b00000000_01000101; @(posedge CLK); // input= 000000000000.000001000101 (0.00146484375) result: 000000111011.010111001100 (59.362318840579711) // very small number
		din = 16'b00000000_00000110; @(posedge CLK); // result: 001010101010.101010101010 result: 001010101010.101010101010  // very small positive number
		din = 16'b00000000_00000001; @(posedge CLK); // result: 001010101010.101010101010 result: 001010101010.101010101010  // very small positive number
		din = 16'b00111100_00000000; @(posedge CLK); // input=240 result: 001010101010.101010101010 result: 000000000000.000000000100  // large positive number
		din = 16'b01111111_11111111; @(posedge CLK); // input=2.047999755859375e+003 result: 001010101010.101010101010 result: 000000000000.000000000100  // large positive number

		// negative number
		din = 16'b11111110_10000000; @(posedge CLK);  // result: 111111011001.010110111101 // very small negative number
		din = 16'b11111111_11111111; @(posedge CLK);  // result: 111111011001.010110111101 // very small negative number
		din = 16'b11111111_11010101; @(posedge CLK);  // -0.37 result: 1111111101.0100101010
		din = 16'b10000000_00000000; @(posedge CLK);  //
		*/
		// 20 bits
		// input: 10.10 output: 10.10
		// positive number
		/*
		din = 20'b0000000001_1000000000; @(posedge CLK); // input=1.5 result: 000000000000.101010101010 (0.6667)
	   din = 20'b0000000000_0001000101; @(posedge CLK); // input= 000000000000.000001000101 (0.00146484375) result: 000000111011.010111001100 (59.362318840579711) // very small number
		din = 20'b0000000000_0000000110; @(posedge CLK); // result: 001010101010.101010101010 result: 001010101010.101010101010  // very small positive number
		din = 20'b0000000000_0000000001; @(posedge CLK); // result: 001010101010.101010101010 result: 001010101010.101010101010  // very small positive number
		din = 20'b0011110000_0000000000; @(posedge CLK); // input=240 result: 001010101010.101010101010 result: 000000000000.000000000100  // large positive number
		din = 20'b0111111111_1111111111; @(posedge CLK); // input=2.047999755859375e+003 result: 001010101010.101010101010 result: 000000000000.000000000100  // large positive number

		// negative number
		din = 20'b1111111110_1000000000; @(posedge CLK);  // result: 111111011001.010110111101 // very small negative number
		din = 20'b1111111111_1111111111; @(posedge CLK);  // result: 111111011001.010110111101 // very small negative number
		din = 20'b1111111111_1010000110; @(posedge CLK);  // -0.37 result: 1111111101.0100101010
		din = 20'b1000000000_0000000000; @(posedge CLK);  //
		*/
		// 24 bits
		// input: 12.12 output: 12.12
		// positive number
		
		din = 24'b000000000001_100000000000; @(posedge CLK);	// input=1.5 result: 000000000000.101010101010 (0.6667)
	   din = 24'b000000000000_000001000101; @(posedge CLK);  // input= 000000000000.000001000101 (0.017) result: 000000111011.010111001100 (59.362318840579711) // very small number
		din = 24'b000000000000_000000000110; @(posedge CLK);  // result: 001010101010.101010101010 result: 001010101010.101010101010  // very small positive number
		din = 24'b000000000000_000000000001; @(posedge CLK);  // result: 001010101010.101010101010 result: 001010101010.101010101010  // very small positive number
		din = 24'b001111000000_000000000000; @(posedge CLK);  // input=960 result: 001010101010.101010101010 result: 000000000000.000000000100  // large positive number
		din = 24'b011111111111_111111111111; @(posedge CLK);  // input=2.047999755859375e+003 result: 001010101010.101010101010 result: 000000000000.000000000100  // large positive number

		// negative number
		din = 24'b111111111111_111110010110; @(posedge CLK);  // result: 111111011001.010110111101 // very small negative number
		din = 24'b111111111111_111111111111; @(posedge CLK);  // result: 111111011001.010110111101 // very small negative number
		din = 24'b111010100001_111110010110; @(posedge CLK);  // result:
		din = 24'b100000000000_000000000000; @(posedge CLK);  //
		
		
		
		// input: 4.20 output: 20.4
/*		
		din = 24'b0001_10000000000000000000; @(posedge CLK);	// input=1.5 result: 000000000000.101010101010 (0.6667)
	   din = 24'b0111_00000000000000000000; @(posedge CLK);  // input= 000000000000.000001000101 (0.017) result: 000000111011.010111001100 (59.362318840579711) // very small number
		din = 24'b0000_00101010000000000001; @(posedge CLK);  // result: 001010101010.101010101010 result: 001010101010.101010101010  // very small positive number
		din = 24'b1000_00100000000000000000; @(posedge CLK);  // result: 001010101010.101010101010 result: 001010101010.101010101010  // very small positive number
*/
		//  Wait 100 ns for global reset to finish
		$finish;
        
		// Add stimulus here

	end

	// -- input -- //	
	always @ din real_din = fixedToFloat(din, WI, WF);

	// -- output -- //	
	always @ dout real_dout = fixedToFloat(dout, WIO, WFO);
      
endmodule

