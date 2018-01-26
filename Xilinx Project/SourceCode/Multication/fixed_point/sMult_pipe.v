`timescale 1ns / 1ps
`define X_trc (WIO>=2)? (WIO-2+frcL) : frcL

//`define X_trc (WIO==1)?tmp[intL+frcL-1]:{tmp[intL+frcL-1], tmp[WIO-2+frcL:frcL]}
//////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////
module sMult_pipe
		   # (parameter WI1 = 4, 		//length of the integer part, operand 1
							 WF1 = 3, 		//length of the fraction part, operand 1
							 WI2 = 2, 		//length of the integer part, operand 2
							 WF2 = 5,		//length of the fraction part, operand 2
							 //WIR = 6,		//the length for the integer part of the required output
							 //WFR = 8,		//the length of the fraction part of the required output
							 WIO = 4,		
							 WFO = 15//(WIR==1)?(WFR-1):WFR		
							 ) 		
	(input CLK, RST, 
	 input signed [WI1+WF1-1 : 0] in1, 
	 input signed [WI2+WF2-1 : 0] in2, 
	 output reg signed [WIO+WFO-1 : 0] out);
	
	
localparam intL = WI1+WI2;				//integer length of correct results
localparam frcL = WF1+WF2;				//fraction length of correct results
		
reg signed [intL+frcL-1 : 0] tmp;			//The output with correct number of bits
reg [WIO-1 : 0] outI;					//The integer part of the output
reg [WFO-1 : 0] outF;					//The fractional part of the output

//assign tmp = in1 * in2;
always @(posedge CLK) tmp <= in1 * in2;

//--------------------adjusting the bitwidth for the fractional part----------------------------------------------------------
always  @(posedge CLK) begin

	if (WFO >= frcL)						//append 0s to the lsb bits
			outF <= {tmp[frcL-1:0] , {(WFO-frcL){1'b0}}};
	else										//WFO<(WF1+WF2): Truncate bits from the LSB bits
			outF <= tmp[frcL-1 : frcL-WFO];
end
//----------------------------------------------------------------------------------------------------------------------------

//--------------------adjusting the bitwidth for the integer part-------------------------------------------------------------
always @(posedge CLK) begin
	if (WIO>=intL)								//sign extend the integer part
			outI <= {{(WIO-intL){tmp[intL+frcL-1]}}, tmp[intL+frcL-1:frcL]};
	else	begin									//WIO<(WI1+WI2)
		if (WIO==1)
			outI <= tmp[intL+frcL-1];
		else
		    outI <= {tmp[intL+frcL-1], tmp[`X_trc:frcL]};						
	end
end
//----------------------------------------------------------------------------------------------------------------------------

//--------------------registering the output----------------------------------------------------------------------------------
always @* 	//(posedge CLK) 			//if wanna a registered multiplier decommented
	if (!RST) 
		out <= 0;						//negative reset
	else 		
		out <= {outI [WIO-1:0], outF [WFO-1:0]};
	
endmodule