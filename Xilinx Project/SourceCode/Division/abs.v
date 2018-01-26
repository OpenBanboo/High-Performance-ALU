`timescale 1ns / 1ps
//================================================================
// abs //
//================================================================
module abs #(parameter WL = 4)
		(
			input signed [WL-1:0] in,			// in 	
			output reg signed [WL-1:0] out		// out
		);

always @ * begin
//	if (in[WL-1]==1'b1)				
		out <= -in;				
//	else									
//		out <= in;						
end

endmodule