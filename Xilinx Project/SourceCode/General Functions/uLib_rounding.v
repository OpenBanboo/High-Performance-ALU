//========================================================================================
// Design Name:    Rounding modules
// Module Name:    ux_round2zero, ux_round2pInf, ux_round2nearestEven, ux_round2nearestOdd, ux_round2nearestAway
// Target Devices: Xilinx family
// Tool versions:  ISE 11
// Description:    
//
//                 This module retruns rounded value of the input for different modes
//                 Round toward negative infinity (or floor) is just truncation of bits that
//					    can be done easily by cutting the bits after the target position. 
//					    Other rounding operation may require addition by one. So the modules are clocked once.
//					    Input x is a unsigned  number in the range [0, 1) in format u16.16
//					    and output is a signed number in the range [-1, 1) in format s16.15
//
// Dependencies:   RoundLength must be greater than or equal one for Round to zero and round in plus infinity
//						 RoundLength must be greater than or equal two for Round to nearest even, odd and away
//
// Revision:       1.0
// Revision 0.01 - File Created
//
// Additional Comments: 
//
//                 This module uses logical operations and one addition operation
//					    The adder is one-stage pipelined 
//
// On a Xilinx-4 LX200 runs at 477 MHz.
// To measure the clock frequency, I used the following code 
//		reg [WordLength-1:RoundLength] xq;
//		always @(posedge CLK) begin
//			xq <= x[WordLength-1:RoundLength];
//		end
// 	and then change y <= x[WordLength-1:RoundLength] + 1'b1; to y <= xq + 1'b1; in the always statement
// to measuer the timing. Xilinx requires reg to reg for measuring the clock. 		
//
//
// Written by Amirhossein Alimohammad (amir@ukalta.com)
//========================================================================================

//`define declare_ux_round2zero_p1
//`define declare_ux_round2pInf_p1
//`define declare_ux_round2mInf_p1
`define declare_ux_round2nearest
`define declare_ux_round2nearest_pipe
//`define declare_ux_round2nearestEven_p1
//`define declare_ux_round2nearestOdd_p1
//`define declare_ux_round2nearestAway_p1

//========================================================================================
// Round to zero
// RoundLength must be greater than or equal one
//========================================================================================
`ifdef declare_ux_round2zero_p1
module ux_round2zero_p1 		
		//----------------------
		#(parameter WordLength = 32,
						RoundLength = 16) // Note that the RoundLength here does not mean the fraction part. 
											   // It is simply the part after rounding point
		// IO signal definition
		(input CLK,
		input  RESET, 
		input  CE, 
		input  signed [WordLength-1:0] x,
		output reg signed [WordLength-1:RoundLength] y);
		
		//----------------------
		always @(posedge CLK) begin
			if (RESET) begin
				y <= 0;
			end
			else begin
				if (CE) begin
					if ((x[WordLength-1]==1'b1) && (x[RoundLength-1:0]>0)) begin // if the number is negative and there is at least one 1 in rounding part bits
						y <= x[WordLength-1:RoundLength] + 1'b1;
					end
					else begin
						y <= x[WordLength-1:RoundLength];
					end
				end // if (CE)
			end
		end
endmodule
`endif

//========================================================================================
// Round to plus infinity; which is the ceil function 
// RoundLength must be greater than or equal one
//========================================================================================
`ifdef declare_ux_round2pInf_p1
module ux_round2pInf_p1 		
		//----------------------
		#(parameter WordLength = 32,
						RoundLength = 16) // Note that the RoundLength here does not mean the fraction part. 
											   // It is simply the part after rounding point
		// IO signal definition
		(input CLK,
		input  RESET, 
		input  CE, 
		input  signed [WordLength-1:0] x,
		output reg signed [WordLength-1:RoundLength] y);
		
		//----------------------
		always @(posedge CLK) begin
			if (RESET) begin
				y <= 0;
			end
			else begin
				if (CE) begin
					if (x[RoundLength-1:0]>0) begin // if there is at least one 1 in rounding part bits
						y <= x[WordLength-1:RoundLength] + 1'b1;
					end
					else begin
						y <= x[WordLength-1:RoundLength];
					end
				end  // if (CE)
			end
		end
endmodule
`endif

//========================================================================================
// Round to minus infinity; which is the floor function 
// RoundLength must be greater than or equal one
//========================================================================================
`ifdef declare_ux_round2mInf_p1
module ux_round2mInf_p1 		
		//----------------------
		#(parameter WordLength = 32,
						RoundLength = 16) // Note that the RoundLength here does not mean the fraction part. 
											             // It is simply the part after rounding point
		// IO signal definition
		(input CLK,
		input  RESET, 
		input  CE, 
		input  signed [WordLength-1:0] x,
		output reg signed [WordLength-1:RoundLength] y);
		
		//----------------------
		always @(posedge CLK) begin
			if (RESET) begin
				y <= 0;
			end
			else begin
				if (CE) begin
				   y <= x[WordLength-1:RoundLength];  // Drop the last bits
				end  // if (CE)
			end
		end
endmodule
`endif

//========================================================================================
// Round to nearest
// RoundLength must be greater than or equal two
//========================================================================================
`ifdef declare_ux_round2nearest
module ux_round2nearest 		
		//----------------------
		#(parameter WordLength = 32,
						RoundLength = 16) // Note that the RoundLength here does not mean the fraction part. 
											   // It is simply the part after rounding point
		// IO signal definition
		(input CLK,
		input  RESET, 
		input  CE, 
		input  signed [WordLength-1:0] x,
		output reg signed [WordLength-1:RoundLength] y);
		
		//----------------------
		always @ * begin
			if (!RESET) begin
				y <= 0;
			end
			else begin
				if (CE) begin
					if (x[RoundLength-1] == 1'b1) begin // if the [RoundLength-1] bit is one 
						if (x[RoundLength-2:0] > 0) begin // if there is at least one 1 in rounding part bits
							y <= x[WordLength-1:RoundLength] + 1'b1;
						end
						else begin
							y <= x[WordLength-1:RoundLength];							
						end
					end
					else begin
						y <= x[WordLength-1:RoundLength];
					end
				end //if (CE)
			end //else
		end // always
endmodule
`endif

//========================================================================================
// Round to nearest
// RoundLength must be greater than or equal two
//========================================================================================
`ifdef declare_ux_round2nearest_pipe
module ux_round2nearest_pipe		
		//----------------------
		#(parameter WordLength = 32,
						RoundLength = 16) // Note that the RoundLength here does not mean the fraction part. 
											   // It is simply the part after rounding point
		// IO signal definition
		(input CLK,
		input  RESET, 
		input  CE, 
		input  signed [WordLength-1:0] x,
		output reg signed [WordLength-1:RoundLength] y);
		
		//----------------------
		always @(posedge CLK) begin
			if (!RESET) begin
				y <= 0;
			end
			else begin
				if (CE) begin
					if (x[RoundLength-1] == 1'b1) begin // if the [RoundLength-1] bit is one 
						if (x[RoundLength-2:0] > 0) begin // if there is at least one 1 in rounding part bits
							y <= x[WordLength-1:RoundLength] + 1'b1;
						end
						else begin
							y <= x[WordLength-1:RoundLength];							
						end
					end
					else begin
						y <= x[WordLength-1:RoundLength];
					end
				end //if (CE)
			end //else
		end // always
endmodule
`endif

//========================================================================================
// Round to nearest even
// RoundLength must be greater than or equal two
//========================================================================================
`ifdef declare_ux_round2nearestEven_p1
module ux_round2nearestEven_p1 		
		//----------------------
		#(parameter WordLength = 32,
						RoundLength = 16) // Note that the RoundLength here does not mean the fraction part. 
											   // It is simply the part after rounding point
		// IO signal definition
		(input CLK,
		input  RESET, 
		input  CE, 
		input  signed [WordLength-1:0] x,
		output reg signed [WordLength-1:RoundLength] y);
		
		//----------------------
		always @(posedge CLK) begin
			if (RESET) begin
				y <= 0;
			end
			else begin
				if (CE) begin
					if (x[RoundLength-1] == 1'b1) begin // if the [RoundLength-1] bit is one 
						if (x[RoundLength-2:0] > 0) begin // if there is at least one 1 in rounding part bits
							y <= x[WordLength-1:RoundLength] + 1'b1;
						end
						else begin
							if (x[RoundLength] == 1'b1) begin // if the lsb before rounding point is 1
								y <= x[WordLength-1:RoundLength] + 1'b1;
							end
							else begin
								y <= x[WordLength-1:RoundLength];
							end							
						end
					end
					else begin
						y <= x[WordLength-1:RoundLength];
					end
				end //if (CE)
			end //else
		end // always
endmodule
`endif

//========================================================================================
// Round to nearest odd
// RoundLength must be greater than or equal two
//========================================================================================
`ifdef declare_ux_round2nearestOdd_p1
module ux_round2nearestOdd_p1
		//----------------------
		#(parameter WordLength = 32,
						RoundLength = 16) // Note that the RoundLength here does not mean the fraction part. 
											   // It is simply the part after rounding point
		// IO signal definition
		(input CLK,
		input  RESET, 
		input  CE, 
		input  signed [WordLength-1:0] x,
		output reg signed [WordLength-1:RoundLength] y);
		
		//----------------------
		always @(posedge CLK) begin
			if (RESET) begin
				y <= 0;
			end
			else begin
				if (CE) begin
					if (x[RoundLength-1] == 1'b1) begin // if the [RoundLength-1] bit is one 
						if (x[RoundLength-2:0] > 0) begin // if there is at least one 1 in rounding part bits
							y <= x[WordLength-1:RoundLength] + 1'b1;
						end
						else begin
							if (x[RoundLength] == 1'b0) begin // if the lsb before rounding point is 0
								y <= x[WordLength-1:RoundLength] + 1'b1;
							end
							else begin
								y <= x[WordLength-1:RoundLength];
							end							
						end
					end
					else begin
						y <= x[WordLength-1:RoundLength];
					end
				end //if (CE)
			end //else
		end // always
endmodule
`endif

//========================================================================================
// Round to nearest away
// RoundLength must be greater than or equal two
//========================================================================================
`ifdef declare_ux_round2nearestAway_p1
module ux_round2nearestAway_p1 		
		//----------------------
		#(parameter WordLength = 32,
						RoundLength = 16) // Note that the RoundLength here does not mean the fraction part. 
											   // It is simply the part after rounding point
		// IO signal definition
		(input CLK,
		input  RESET, 
		input  CE, 
		input  signed [WordLength-1:0] x,
		output reg signed [WordLength-1:RoundLength] y);
		
		//----------------------
		always @(posedge CLK) begin
			if (RESET) begin
				y <= 0;
			end
			else begin
				if (CE) begin
					if (x[RoundLength-1] == 1'b1) begin // if the [RoundLength-1] bit is one 
						if (x[RoundLength-2:0] > 0) begin // if there is at least one 1 in rounding part bits
							y <= x[WordLength-1:RoundLength] + 1'b1;
						end
						else begin
							if (x[WordLength-1] == 1'b0) begin // if the number is positive
								y <= x[WordLength-1:RoundLength] + 1'b1;
							end
							else begin
								y <= x[WordLength-1:RoundLength];
							end							
						end
					end
					else begin
						y <= x[WordLength-1:RoundLength];
					end
				end //if (CE)
			end //else
		end // always
endmodule
`endif
