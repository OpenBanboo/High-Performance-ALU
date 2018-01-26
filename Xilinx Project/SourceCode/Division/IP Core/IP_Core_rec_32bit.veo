/*******************************************************************************
*     This file is owned and controlled by Xilinx and must be used solely      *
*     for design, simulation, implementation and creation of design files      *
*     limited to Xilinx devices or technologies. Use with non-Xilinx           *
*     devices or technologies is expressly prohibited and immediately          *
*     terminates your license.                                                 *
*                                                                              *
*     XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS" SOLELY     *
*     FOR USE IN DEVELOPING PROGRAMS AND SOLUTIONS FOR XILINX DEVICES.  BY     *
*     PROVIDING THIS DESIGN, CODE, OR INFORMATION AS ONE POSSIBLE              *
*     IMPLEMENTATION OF THIS FEATURE, APPLICATION OR STANDARD, XILINX IS       *
*     MAKING NO REPRESENTATION THAT THIS IMPLEMENTATION IS FREE FROM ANY       *
*     CLAIMS OF INFRINGEMENT, AND YOU ARE RESPONSIBLE FOR OBTAINING ANY        *
*     RIGHTS YOU MAY REQUIRE FOR YOUR IMPLEMENTATION.  XILINX EXPRESSLY        *
*     DISCLAIMS ANY WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE    *
*     IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR           *
*     REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF          *
*     INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A    *
*     PARTICULAR PURPOSE.                                                      *
*                                                                              *
*     Xilinx products are not intended for use in life support appliances,     *
*     devices, or systems.  Use in such applications are expressly             *
*     prohibited.                                                              *
*                                                                              *
*     (c) Copyright 1995-2015 Xilinx, Inc.                                     *
*     All rights reserved.                                                     *
*******************************************************************************/

/*******************************************************************************
*     Generated from core with identifier: xilinx.com:ip:floating_point:5.0    *
*                                                                              *
*     The Xilinx Floating-Point Operator is capable of being configured to     *
*     provide a range of floating-point operations. The core offers            *
*     addition, subtraction, multiplication, division, square-root, compare    *
*     and conversion operations. High-speed, with single-cycle throughput      *
*     is provided at a wide range of wordlengths that includes both single     *
*     and double precision. Embedded multipliers or XtremeDSP slices can be    *
*     used with certain operations.                                            *
*******************************************************************************/

// Interfaces:
//    a_intf
//    clk_intf
//    sclr_intf
//    ce_intf
//    b_intf
//    a_negate_intf
//    b_negate_intf
//    operation_intf
//    a_nd_intf
//    a_rfd_intf
//    b_nd_intf
//    b_rfd_intf
//    operation_nd_intf
//    operation_rfd_intf
//    aclr_intf
//    result_intf
//    status_intf
//    exception_intf
//    underflow_intf
//    overflow_intf
//    invalid_op_intf
//    inexact_intf
//    divide_by_zero_intf
//    rdy_intf
//    cts_intf

// The following must be inserted into your Verilog file for this
// core to be instantiated. Change the instance name and port connections
// (in parentheses) to your own signal names.

//----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG
IP_Core_rec_32bit your_instance_name (
  .a(a), // input [31 : 0] a
  .clk(clk), // input clk
  .ce(ce), // input ce
  .result(result) // output [31 : 0] result
);
// INST_TAG_END ------ End INSTANTIATION Template ---------

// You must compile the wrapper file IP_Core_rec_32bit.v when simulating
// the core, IP_Core_rec_32bit. When compiling the wrapper file, be sure to
// reference the XilinxCoreLib Verilog simulation library. For detailed
// instructions, please refer to the "CORE Generator Help".

