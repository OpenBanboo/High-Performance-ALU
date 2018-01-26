`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    09/02/2015 
// Design Name: 
// Module Name:    Div_Radix4
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
module Div_Radix4
		// ****************************
		#(parameter	WL = 24,				// World length of the input,
						WF = 23,				// fraction length
						RADIX = 4,			// The number of redices of the recurrences
						N = 12, 				// WL/cLog2(RADIX) 12,				// Iteration times
						LUT_size = 8,		// The size of the LUT table,
						LUT_bits = 7,		// the width of the LUT table
						LUT_addWidth = RADIX,
						addpointer = cLog2(N)
		 )
												// IO signal definition
		(
			input CLK, 						// clock signal
			input nRST,						// negative resert signal
			input CE,						// clock enable signal
			input [WL-1:0] din_x,		// input structure should be 1.23 for 24 bits input: Dividend
												// for the single-precision floating-point format mantissa
			input [WL-1:0] din_d,		// divider
			output reg[WL-1:0] dout		// quotient (1.WF format)
		);
		
		// -- Memories -- //
		reg  [LUT_bits-1 : 0]  LUT_m2  [LUT_size-1 : 0];		// m2	
		reg  [LUT_bits-1 : 0]  LUT_m1  [LUT_size-1 : 0];		// m1
		reg  [LUT_bits-1 : 0]  LUT_mm1 [LUT_size-1 : 0];		// mm1
		reg  [LUT_bits-1 : 0]  LUT_m0  [LUT_size-1 : 0];		// m0
		
		reg  [LUT_addWidth-1:0] reg_cmp, index;					// the value fetched from the leading 4 bits except the first one

		reg  											Sel;					// Selection signal for the multiplexer
		reg  [2:0]									fpSeven = 0;		// register storing the number 7

		reg  [LUT_bits-1:0]						m2, m1, m0, mm1; 	// registers for storing the chose value
		reg  [WL+2-1:0]  							rwj_ini = 0;		// 
		reg  [WL+2-1:0]  							rwj_shf;
		wire [WL+2-1:0]  							rwj;
		reg  signed  [2+4 :0]					yHatTimesr = 0;
		reg  signed  [2:0]						q;				 		// store the 4 bit representation of the radix 4
		wire signed  [2:0]						q_abs;				// abs(q)
		
		wire signed  [WL+2-1:0] 				qjd;					// qjd = q(j) * d; 
		reg  signed  [WL+2-1:0] 				wjp;
		wire  		 [WL-1:0]					tmp_result_1;

		reg  [WL-1:0]		  		  QM;
		reg  [WL-1:0]  	  		  QN;
		reg  [WL-1:0]		  		  QM_tmp;
		reg  [WL-1:0]  	  		  QN_tmp;
		reg  [1:0]					  QM_next;
		reg  [1:0]					  QN_next;
		
////////////////////////////////// ----- Modle Intialization ----- ///////////////////////////////////////

/////////////////////////////////  ----- Controller and sequential part -----  ////////////////////////////////////////////
	reg [addpointer-1:0] pointer = 0;

	integer looper_2 = 0;
		always @ (posedge CLK) begin
			if(~nRST) begin
					Sel <= 1'b0;							
					pointer <= 0;
					dout <= 0;						// reset output as 0
					QN <= 0;
					QM <= 0;
			end
			else begin
				if (CE) begin

					if (pointer == N-1) begin					
						dout <= QN << 3;  // obtain the output every 12 clock cycles
						pointer <= 0;
						Sel <= 1'b0;				
						QN <= 0;
						QM <= 0;
					end else begin
						//tmp_result_1[WL-1-pointer*cLog2(RADIX):WL-1-pointer*cLog2(RADIX)-1] <= tmp_result_0[1:0];
						pointer <= pointer + 1;
						Sel <= 1'b1;

						// The QN selection part
						if(q>=0) begin
							QN[WL-1:2] <= QN_tmp[WL-3:0];
						end else begin
							QN[WL-1:2] <= QM_tmp[WL-3:0]; 
						end
						
						if(q>0) begin
							QM[WL-1:2] <= QN_tmp[WL-3:0];
						end else begin
							QM[WL-1:2] <= QM_tmp[WL-3:0];
						end

						QN[1:0]		 <= QN_next;						
						QM[1:0]      <= QM_next;
						
					end
					rwj_shf <= wjp << 2;		  // save the temporary result used for iterating
				end // if (CE)
			end // else
		end	

	multiplexer #(.N(WL+2)) Sel_input_mux (.a(rwj_ini),.b(rwj_shf),.Sel(Sel),.out(rwj));			

	abs #(.WL(3)) abs_Fang (.in(q), .out(q_abs));

	sMult #(.WI1(3), .WF1(0), .WI2(WL-WF), .WF2(WF), .WIO(WL+2-WF), .WFO(WF)) multiplier 
						(.CLK(CLK), .RST(nRST), .in1(q), .in2(din_d), .out(qjd));

//	Onthefly #(.N(N),.WL(WL),.RADIX(RADIX)) Onthefly_Fang
//				 (.CLK(CLK), .nRST(nRST), .CE(CE), .q(q), .q_abs(q_abs), .pointer(pointer), .dout(tmp_result_1));

	always @ * begin
			if(~nRST) begin
					reg_cmp = 0;									// reset
					index = 0;
					fpSeven[RADIX-2:0] = 3'b111;				// assign the first three bits as 1
					rwj_ini = 0;									// reset the inivalue of rwj before iteration
					wjp = 0;
					yHatTimesr = 0;
					q = 0;
					QN_tmp = 0;
					QM_tmp = 0;
			end else begin	// if
				if (CE) begin
					reg_cmp   = din_d[WL-2 : WL-1-RADIX];   
					index = reg_cmp - fpSeven;
					m2 = LUT_m2[index-1];							// -- Get the initial value from the look-up table
					m1 = LUT_m1[index-1];							// -- Get the initial value from the look-up table
					m0 = LUT_m0[index-1];							// -- Get the initial value from the look-up table
					mm1 = LUT_mm1[index-1];						   // -- Get the initial value from the look-up table

					rwj_ini[WL-1:0] = din_x;					// -- the initial value of input of the first iteration
					yHatTimesr = rwj[WL+2-1 : WL+2-(1+2+RADIX)];
					
					if (yHatTimesr[6]==1'b0) begin						  // yHatTimer >=0
						if (yHatTimesr >= m2)
							q = 3'b010;
						else if ((yHatTimesr<m2)&&(yHatTimesr>=m1))
							q = 3'b001;
						else if (yHatTimesr<m1) 					//
							q = 3'b000;
					end else begin												  // yHatTimesr <0
						if ((-yHatTimesr)<=-m0)
							q = 3'b000;
						else if (((-yHatTimesr)>-m0)&&((-yHatTimesr)<=-mm1))
							q = 3'b111;
						else
							q = 3'b110;
					end
						
					if (q > 0) begin
						// -- QM(j+1) = q(j)-1;
						QM_next = q - 1;				
						// -- QN(j+1) = q(j);
						QN_next = q;
					end else if (q==0) begin
						// -- QN(j+1) = q(j);
						QN_next = 0; // q;  // q = 0	
						// -- QM(j+1) = (R-1)-abs(q(j));	
						QM_next = RADIX-1;  // -q_abs 
					end else begin
						// -- QM(j+1) = (R-1)-abs(q(j));
						QM_next = RADIX-1-q_abs;
						// -- QN(j+1) = R-abs(q(j));
						QN_next = RADIX-q_abs;
					end
					
					QN_tmp = QN;
					QM_tmp = QM;
					
					wjp = rwj - qjd;	// wjp1FP = fpSub(rwjFP, qjdFP);
					
				end // if (CE)
			end // else	
	end // always		
	
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
