`timescale 1ns / 1ps                                                       
/*************************************************************************/
// COMPANY        :  STARPOINT                                             
// TEAM           :  FPGA GROUP/SPG                                        
// MODULE NAME    :  rnd                                              
// FILE NAME      :  rnd.v                                            
// PROJECT NAME   :  rnd                                             
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
module sat #
 (     
   parameter   IN_WIDTH                        =  32   ,
   parameter   SAT_WIDTH                       =  16   
 ) (                                                    
   input                                        clk    ,
   input                                        rst    ,
   input      [ IN_WIDTH-1 :0]                  din_i  ,
   input      [ IN_WIDTH-1 :0]                  din_q  ,
                                                       
   output     [ IN_WIDTH-SAT_WIDTH-1:0]         dout_i ,
   output     [ IN_WIDTH-SAT_WIDTH-1:0]         dout_q 
  );
  
   real_sat #
   (     
     .IN_WIDTH                         ( IN_WIDTH       ),
     .SAT_WIDTH                        ( SAT_WIDTH      )
   ) real_sat_i (                       
      .clk                             ( clk            ),
      .rst                             ( rst            ),
      .din                             ( din_i          ),
                                                        
      .dout                            ( dout_i         )
     );  
    
   real_sat #
   (     
     .IN_WIDTH                         ( IN_WIDTH        ),
     .SAT_WIDTH                        ( SAT_WIDTH       )
  ) real_sat_q (                        
     .clk                              ( clk             ),
     .rst                              ( rst             ),
     .din                              ( din_q           ),
                                       
     .dout                             ( dout_q          )
    );  
  
   
endmodule