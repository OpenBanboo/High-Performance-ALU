//--------------------------
//leading one detector function
// This function returns two aprameters
// If the most significant bit is 1 then the remaining bits is the index of leading one
// If the most significant bit is 0, it means that the content is all zero and there is no leading one

module leadingOne 
		#(parameter xWL = 32)

		// IO signal definition
		(input clk,
		 input ce,
		 input sclr,
		 input [xWL-1:0] x,
		 output reg [cLog2(xWL-1):0] loPosition);

		//--------------------------
		// Local parameter definition
		parameter ctrWidth = cLog2(xWL-1);
		
		//--------------------------
		always @ (posedge clk) begin
			loPosition = LOD(x);
		end
		
		//--------------------------
		function [ctrWidth :0] LOD;
		
		input [xWL-1:0] val;
		// ctr of type integer can be assigned into type reg so I commented ctrCopy
		//reg   [ctrWidth-1 :0] ctrCopy, indx;
		reg   [ctrWidth-1 :0] indx;
		integer found;
		integer ctr;
		
		begin
		   found   = 0;
			//ctrCopy = {ctrWidth{1'b1}};
			// I could have checked found in the for() so it stops looking after it finds
			// but this does not make any difference in hardware as the for loop should be supported 
			// for the worst case scenario
			for( ctr = xWL-1; ctr >= 0; ctr = ctr-1 ) begin
				if( val[ctr] && !found) begin
					//indx = ctrCopy;
					indx = ctr;
					found = 1;
				end
			   //ctrCopy = ctrCopy - 1;
			end
			LOD = {found,indx};
		end	

		endfunction

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

