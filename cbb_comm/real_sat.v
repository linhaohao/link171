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
module real_sat #
 (     
   parameter   IN_WIDTH                        =  32 ,
   parameter   SAT_WIDTH                       =  16 
) (
   input                                        clk,
   input                                        rst,
   input      [ IN_WIDTH-1 :0]                  din,
   
   output reg [ IN_WIDTH-SAT_WIDTH-1:0]         dout
  );
  
  
//******************* signal define*********************//

//*********************function*************************//   

//always@(posedge clk or posedge rst)
//begin
//   if(rst == 1)
//      dout  <= {{IN_WIDTH-SAT_WIDTH}{1'b0}};
//   else if( (din[IN_WIDTH - 1 :IN_WIDTH - SAT_WIDTH - 1] == {{SAT_WIDTH}{1'b0}}) || (din[IN_WIDTH - 1 :IN_WIDTH - SAT_WIDTH - 1] == {{SAT_WIDTH}{1'b1}}))
//      dout  <= din[IN_WIDTH-SAT_WIDTH-1:0];
//   else
//      dout  <= {din[IN_WIDTH-1],{{IN_WIDTH-SAT_WIDTH-2}{~din[IN_WIDTH-1]}}};
//end

always@(posedge clk or posedge rst)
begin
   if(rst == 1)
      dout  <= {{IN_WIDTH-SAT_WIDTH}{1'b0}};
   else if( din[IN_WIDTH - 2:IN_WIDTH-SAT_WIDTH - 1] != {{SAT_WIDTH} {din[IN_WIDTH - 1]}})
      dout  <= {din[IN_WIDTH-1],{{IN_WIDTH-SAT_WIDTH-1}{~din[IN_WIDTH-1]}}};     
   else
     dout  <= din[IN_WIDTH-SAT_WIDTH-1:0];
      
end
  
  
  
endmodule             
