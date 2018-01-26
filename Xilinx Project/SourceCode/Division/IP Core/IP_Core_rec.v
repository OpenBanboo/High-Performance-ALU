`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:56:39 09/26/2015 
// Design Name: 
// Module Name:    IP_Core_rec 
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
module IP_Core_rec
(
  CLK, nRST, s_axis_a_tvalid, m_axis_result_tvalid, s_axis_a_tdata, m_axis_result_tdata
)/* synthesis syn_black_box syn_noprune=1 */;
  input CLK;
  input nRST;
  input s_axis_a_tvalid;
  output reg m_axis_result_tvalid;
  input [31 : 0] s_axis_a_tdata;
  output reg [31 : 0] m_axis_result_tdata;

  reg TMP_s_axis_a_tvalid;
  reg [31 : 0] TMP_s_axis_a_tdata;
  wire [31 : 0] TMP_m_axis_result_tdata;
  wire TMP_m_axis_result_tvalid;

//----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG
IP_Core_rec_7Stages Fang_IP_core (
  .aclk(CLK), // input aclk
  .s_axis_a_tvalid(TMP_s_axis_a_tvalid), // input s_axis_a_tvalid
  .s_axis_a_tdata(TMP_s_axis_a_tdata), // input [31 : 0] s_axis_a_tdata
  .m_axis_result_tvalid(TMP_m_axis_result_tvalid), // output m_axis_result_tvalid
  .m_axis_result_tdata(TMP_m_axis_result_tdata) // output [31 : 0] m_axis_result_tdata
);

always @ (posedge CLK) begin
	if (!nRST) begin
		TMP_s_axis_a_tvalid <= 0;
		TMP_s_axis_a_tdata <= 0;
	end else begin
		TMP_s_axis_a_tvalid <= s_axis_a_tvalid;
		TMP_s_axis_a_tdata <= s_axis_a_tdata;
		m_axis_result_tvalid <= TMP_m_axis_result_tvalid;
		m_axis_result_tdata <= TMP_m_axis_result_tdata;
	end
end


endmodule
