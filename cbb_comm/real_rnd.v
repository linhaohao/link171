`timescale 1ns / 1ps
/*************************************************************************/
// COMPANY        :  STARPOINT
// TEAM           :  FPGA GROUP/SPG
// MODULE NAME    :  real_sat
// FILE NAME      :  real_sat.v
// PROJECT NAME   :  real_sat
// HIGHER MODULE  :  
// DESCRIPTION    :  top level of real_sat
// NOTES          :  NONE.
// LIMITATIONS    :  NONE.
// ERRORS         :  NONE KNOWN.
// INCLUDE FILES  :  N/A
//
// AUTHOR         :  xiaowei
// EMAIL          :  xiaowei@starpointcomm.com
// PLATFORM       :  Target Chip : Xilinx; XC5VSX50T-1FFG665C
//                   Synthesis   : xst
//                   Layout      : Xilinx ISE 13.2
//                                 Output Slew Rate   : Fast
//                                 Logic Optimization : Speed
// REVISION HISTORY:
// -----------------------------------------------------------------------
//  Ver     Author          Date          Changes Description
// -----------------------------------------------------------------------
//  0.0     xiaowei      11/05/2015    Original Version.
/*************************************************************************/
module real_rnd #
 (     
   parameter   IN_WIDTH                        =  32 ,
   parameter   RND_WIDTH                       =  16 
) (
   input                                        clk,
   input                                        rst,
   input      [ IN_WIDTH-1 :0]                  din,
   
   output     [ IN_WIDTH-RND_WIDTH-1:0]         dout
  );
  
 //***********************define****************************//
 reg    [IN_WIDTH - RND_WIDTH : 0]       dout_tmp;
  
 assign dout = dout_tmp[ IN_WIDTH - RND_WIDTH :1];
  
 always@(posedge clk or posedge rst)
 begin
   if( rst == 1'b1 )
      dout_tmp        <= {{ IN_WIDTH - RND_WIDTH +1 }{1'b0}};
   else
      dout_tmp        <= {din[IN_WIDTH-1],din[IN_WIDTH-1:RND_WIDTH]} + din[RND_WIDTH-1];
 end
  

endmodule