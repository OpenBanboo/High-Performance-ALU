`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:07:51 09/25/2014 
// Design Name: 
// Module Name:    Onthefly 
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
module Onthefly
		// ****************************
		#(
			parameter N = 12,
						 WL = 24,
						 RADIX = 4,
						 addpointer = cLog2(N)
		)
		(
			input CLK, 						// clock signal
			input nRST,						// negative resert signal
			input CE,						// clock enable signal
			input signed [2:0]	q,
			input signed [2:0] q_abs,			// input structure should be 1.23 for 24 bits input: Dividend
												// for the single-precision floating-point format mantissa
			input [addpointer-1:0] pointer,		// pointer in
			output reg[WL-1:0] dout		// quotient (1.WF format)
		);

		// -- Memories -- //

		reg  [1:0]		  		  QM		 [2**addpointer-1 : 0];
		reg  [1:0]  	  		  QN		 [2**addpointer-1 : 0];
		
		// -- 
		reg [addpointer-1:0] loop_pointer = 0;
		reg [addpointer-1:0] loop_pointer_2 = 0;
		reg [addpointer:0] loop_pointer_3 = 0;
		reg [addpointer:0] loop_pointer_4 = 0;
		reg [addpointer:0] loop_pointer_5 = 0;
		reg [addpointer:0] loop_pointer_6 = 0;

	always @* begin
		if(~nRST) begin
			for (loop_pointer = 0; loop_pointer <= N-1; loop_pointer = loop_pointer + 1 ) begin
				QN [loop_pointer] <= 0;					// reset the QN, QM memory
				QM [loop_pointer] <= 0;	
			end
			dout <= 0;	

		end else begin		
			
			if (CE) begin
				if (pointer==0) begin
					
					QN[0] <= 0;
					QM[0] <= 0;
					
					if (q > 0) begin
						// -- QM(j+1) = q(j)-1;
						QM[1] <= q - 1;				
						// -- QN(j+1) = q(j);
						QN[1] <= q;
					end else if (q==0) begin
						// -- QN(j+1) = q(j);
						QN[1] <= 0; // q;  // q = 0	
						// -- QM(j+1) = (R-1)-abs(q(j));	
						QM[1] <= RADIX-1;  // -q_abs 
					end else begin
						// -- QM(j+1) = (R-1)-abs(q(j));
						QM[1] <= RADIX-1-q_abs;
						// -- QN(j+1) = R-abs(q(j));
						QN[1] <= RADIX-q_abs;
					end
					
					for (loop_pointer_2 = 2; loop_pointer_2 <= N-1; loop_pointer_2 = loop_pointer_2 + 1 ) begin
						QN [loop_pointer_2] <= 0;			 // reset the QN, QM memory
						QM [loop_pointer_2] <= 0;
					end
					
				end else begin  // pointer != 0 

					//- refreshing QN
					if (q[2]==1'b0) begin 
						for(loop_pointer_3 = 0; loop_pointer_3 <= pointer; loop_pointer_3 = loop_pointer_3 + 1 ) begin
							QN[loop_pointer_3] <= QN[loop_pointer_3];
						end
						QN[pointer+1] <= q;
					end else begin
						for(loop_pointer_4 = 0; loop_pointer_4 <= pointer; loop_pointer_4 = loop_pointer_4 + 1 ) begin
							QN[loop_pointer_4] <= QM[loop_pointer_4];
						end
						QN[pointer+1] <= RADIX-q_abs;
					end

					//- refreshing QM
					if ((q[2]==1'b1)||(q==3'b000)) begin 
						for(loop_pointer_6 = 0; loop_pointer_6 <= pointer; loop_pointer_6 = loop_pointer_6 + 1 ) begin
							QM[loop_pointer_6] <= QM[loop_pointer_6];
						end
						QM[pointer+1] <= RADIX-1-q_abs;
					end else begin
						for(loop_pointer_5 = 0; loop_pointer_5 <= pointer; loop_pointer_5 = loop_pointer_5 + 1 ) begin
							QM[loop_pointer_5] <= QN[loop_pointer_5];
						end
						QM[pointer+1] <= q-1;
					end


				end //else begin
				dout <= {QN[0],QN[1],QN[2],QN[3], QN[4], QN[5],QN[6],
							QN[7],QN[8],QN[9],QN[10],QN[11]};
			end
		end
	end

		//--------------------------
		//ceiling of the log base 2 function
		// Actually calculates ceil(log2(x+1)) which is required as the number of address bits in verilog
		function integer cLog2;
			input [31:0] value;
			integer i;
			begin
			  i = value;
				for (cLog2=0; i>0; cLog2=cLog2+1)
					i = i >> 1;
			end		
		endfunction	
		
endmodule
