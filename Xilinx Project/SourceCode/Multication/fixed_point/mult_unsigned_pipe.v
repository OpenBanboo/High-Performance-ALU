`timescale 1ns / 1ps
`define X_trc (WIO>=2)? (WIO-2+frcL) : frcL
//////////////////////////////////////////////////////////////////////////////////
// Company: 
//
//////////////////////////////////////////////////////////////////////////////////
module mult_unsigned_pipe
		   # (parameter WI1 = 1, 		//length of the integer part, operand 1
							 WF1 = 23, 		//length of the fraction part, operand 1
							 WI2 = 1, 		//length of the integer part, operand 2
							 WF2 = 23,		//length of the fraction part, operand 2
							 WIO = 2, 		//default length for the integer part of the required output
							 WFO = 2,	 	//default length of the fraction part of the required output
							 PIP = 46			//number of pipeline stages
				)
	(input CLK, RST, input [WI1+WF1-1 : 0] in1, input [WI2+WF2-1 : 0] in2, output reg [WIO+WFO-1 : 0] out);
	
	localparam intL = WI1+WI2;				//integer length of correct results
	localparam frcL = WF1+WF2;				//fraction length of correct results
			
	reg [intL+frcL-1 : 0] tmp;			//The output with correct number of bits
	reg [WIO-1 : 0] outI;					//The integer part of the output
	reg [WFO-1 : 0] outF;

	//assign tmp = in1 * in2;
	always @(posedge CLK) tmp <= in1 * in2;
	//--------------------adjusting the bitwidth for the fractional part----------------------------------------------------------
	always @(posedge CLK) begin
		if (WFO >= frcL)						//append 0s to the lsb bits
				outF <= {tmp[frcL-1:0] , {(WFO-frcL){1'b0}}};
		else										//WFO<(WF1+WF2): Truncate bits from the LSB bits
				outF <= tmp[frcL-1 : frcL-WFO];
	end
	//--------------------adjusting the bitwidth for the integer part-------------------------------------------------------------
	always @(posedge CLK) begin
		if (WIO>=intL)							//sign extend the integer part
				outI <= {{(WIO-intL){1'b0}}, tmp[intL+frcL-1:frcL]};
		else begin								//WIO<(WI1+WI2)
				if(WIO==1)
					outI <= tmp[frcL]; 		//truncate bits from the MSB part but keep the least bit of Integer part
				else
					outI <= {tmp[intL+frcL-1], tmp[`X_trc:frcL]};
		end
	end
	//--------------------registering the output----------------------------------------------------------------------------------
	//wire [WIO+WFO-1 : 0] out_tmp;
	always @ * out <= {outI,outF};
	/*
	assign out_tmp = {outI,outF};
	
	reg [WIO+WFO-1:0] buffer [1: PIP];		// 
	integer i;
	
	
	always @(posedge CLK) begin
		if (!RST) begin
			for (i=1; i<=PIP; i=i+1)
				buffer[i] <= 0;
		end else begin
			buffer[1] <= out_tmp;
			for (i=2; i<=PIP; i=i+1)
				buffer[i] <= buffer[i-1];
		end
	end

	assign out = buffer[PIP];
	*/

endmodule


module mult_unsigned_pipe_3stages
		   # (parameter WI1 = 1, 		//length of the integer part, operand 1
							 WF1 = 23, 		//length of the fraction part, operand 1
							 WI2 = 1, 		//length of the integer part, operand 2
							 WF2 = 23,		//length of the fraction part, operand 2
							 WIO = 2, 		//default length for the integer part of the required output
							 WFO = 2,	 	//default length of the fraction part of the required output
							 PIP = 46			//number of pipeline stages
				)
	(input CLK, RST, input [WI1+WF1-1 : 0] in1, input [WI2+WF2-1 : 0] in2, output reg [WIO+WFO-1 : 0] out);
	
	localparam intL = WI1+WI2;				//integer length of correct results
	localparam frcL = WF1+WF2;				//fraction length of correct results
			
	reg [intL+frcL-1 : 0] tmp;			//The output with correct number of bits
	reg [WIO-1 : 0] outI;					//The integer part of the output
	reg [WFO-1 : 0] outF;

	//assign tmp = in1 * in2;
	always @(posedge CLK) tmp <= in1 * in2;
	//--------------------adjusting the bitwidth for the fractional part----------------------------------------------------------
	always @(posedge CLK) begin
		if (WFO >= frcL)						//append 0s to the lsb bits
				outF <= {tmp[frcL-1:0] , {(WFO-frcL){1'b0}}};
		else										//WFO<(WF1+WF2): Truncate bits from the LSB bits
				outF <= tmp[frcL-1 : frcL-WFO];
	end
	//--------------------adjusting the bitwidth for the integer part-------------------------------------------------------------
	always @(posedge CLK) begin
		if (WIO>=intL)							//sign extend the integer part
				outI <= {{(WIO-intL){1'b0}}, tmp[intL+frcL-1:frcL]};
		else begin								//WIO<(WI1+WI2)
				if(WIO==1)
					outI <= tmp[frcL]; 		//truncate bits from the MSB part but keep the least bit of Integer part
				else
					outI <= {tmp[intL+frcL-1], tmp[`X_trc:frcL]};
		end
	end
	//--------------------registering the output----------------------------------------------------------------------------------
	//wire [WIO+WFO-1 : 0] out_tmp;
	always @ (posedge CLK) out <= {outI,outF};
	/*
	assign out_tmp = {outI,outF};
	
	reg [WIO+WFO-1:0] buffer [1: PIP];		// 
	integer i;
	
	
	always @(posedge CLK) begin
		if (!RST) begin
			for (i=1; i<=PIP; i=i+1)
				buffer[i] <= 0;
		end else begin
			buffer[1] <= out_tmp;
			for (i=2; i<=PIP; i=i+1)
				buffer[i] <= buffer[i-1];
		end
	end

	assign out = buffer[PIP];
	*/

endmodule