`timescale 1ns / 100ps
/*************************************************************************/
// COMPANY        :  STARPOINT
// TEAM           :  FPGA GROUP/SPG
// MODULE NAME    :  ddc
// FILE NAME      :  ddc.v
// PROJECT NAME   :  multi_mode
// HIGHER MODULE  :  
// DESCRIPTION    :  top level of lte bbu in multi mode
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
//
// REVISION HISTORY:
// -----------------------------------------------------------------------
//  Ver     Author          Date          Changes Description
// -----------------------------------------------------------------------
//  0.0     xiaowei      11/30/2015    Original Version.
/*************************************************************************/

module  fpga_stat_rpt
                  (
                    input                          clk,
                    input                          rst,
                    
                    
                    //interface to dsp
                    input                          dsp_rd_req,
                    output                         dsp_rd_resp,
                    output     [31:0]              dsp_rd_data,
                    
                    //collect info
                    input      [15:0]              hw_bbu_tmp,               // 数字版温度
                    input      [15:0]              hw_bbu_pll_unlocked,      // bbu pll state
                    input      [15:0]              hw_rf_tx_tmp,             // rru tx board temperature detect
                    input      [15:0]              hw_rf_tx0_voltage,        // rru tx board voltage detect
                    input      [15:0]              hw_rf_tx1_voltage,
                    input      [15:0]              hw_rf_tx2_voltage,
                    input      [15:0]              hw_rf_tx_pll_unlocked,    // rru pll state
                    input      [15:0]              hw_rf_rx_tmp,             // rru rx board temperature detect     
                    input      [15:0]              hw_rf_rx0_voltage,
                    input      [15:0]              hw_rf_rx1_voltage,
                    input      [15:0]              hw_rf_rx2_voltage,
                    input      [15:0]              hw_rf_rx_pll_unlocked,
                    input      [15:0]              hw_pa_tmp,                 // pa temperature
                    input      [15:0]              hw_pa_vswr_rpt,            // pa vswr  驻波比
                    input      [15:0]              hw_pa_outpwr_alarm, 
                    input      [15:0]              hw_pa_inpwr_alarm
                    
                  );
 
 //*****************************define parameter*****************************// 
 parameter       TX_WORD_NUM   = 7 ;    // N-1
 
                  
 //*********************define signal and register **************************//
 reg   [2:0]    dsp_rd_req_dly;
 reg            dsp_rd_req_posedge;
 reg            tx_word_en; 
 reg   [2:0]    tx_word_cnt;
 reg   [31:0]   tx_word; 
 reg            tx_word_en_dly;
 
 
 
 //*****************************logic and function***************************//
 assign  dsp_rd_data  = tx_word;
 assign  dsp_rd_resp  = tx_word_en_dly;
 
 
 always@(posedge clk or posedge rst)
 begin
    if(rst == 1'b1)
       dsp_rd_req_dly  <= 3'd0;
    else
       dsp_rd_req_dly  <= {dsp_rd_req_dly[1:0],dsp_rd_req};    
 end
 
 always@(posedge clk or posedge rst)
 begin
   if(rst == 1'b1)
      dsp_rd_req_posedge  <= 1'b0;
   else if(dsp_rd_req_dly[2:1] == 2'b01)
      dsp_rd_req_posedge  <= 1'b1;
   else
      dsp_rd_req_posedge  <= 1'b0;        
 end
 
 always@(posedge clk or posedge rst)
 begin
   if(rst == 1'b1)
      tx_word_en  <= 1'b0;
   else if(dsp_rd_req_posedge == 1'b1)
      tx_word_en  <= 1'b1;
   else if(tx_word_cnt >= TX_WORD_NUM)
      tx_word_en  <= 1'b0; 
   else
     ;       
 end
 
    
 always@(posedge clk or posedge rst)
 begin
   if(rst == 1'b1)
     tx_word_cnt      <= 3'd0;
   else if((tx_word_en == 1'b1) && (tx_word_cnt >= TX_WORD_NUM))  
     tx_word_cnt      <= 3'd0;
   else if(tx_word_en == 1'b1)  
     tx_word_cnt      <= tx_word_cnt + 1'b1;
   else
     ;
 end
 
 always@(posedge clk or posedge rst)
 begin
   if(rst == 1'b1)
     tx_word                <= 32'd0;
   else 
     begin
       case ({tx_word_en,tx_word_cnt})
         4'b1_000: tx_word  <= {hw_bbu_tmp,hw_bbu_pll_unlocked};                      // BBU
         4'b1_001: tx_word  <= {hw_rf_tx_tmp,hw_rf_tx0_voltage};         // RRU TX
         4'b1_010: tx_word  <= {hw_rf_tx1_voltage,hw_rf_tx2_voltage};            // RRU_TX
         4'b1_011: tx_word  <= {hw_rf_tx_pll_unlocked,hw_rf_rx_tmp};         // RRU_RX
         4'b1_100: tx_word  <= {hw_rf_rx0_voltage,hw_rf_rx1_voltage};            // RRU_RX
         4'b1_101: tx_word  <= {hw_rf_rx2_voltage,hw_rf_rx_pll_unlocked};              // RRU_PA
         4'b1_110: tx_word  <= {hw_pa_tmp,hw_pa_vswr_rpt};              // RRU_PA
         4'b1_111: tx_word  <= {hw_pa_inpwr_alarm,hw_pa_outpwr_alarm};              // RRU_PA
         default:  tx_word  <= 32'd0;
       endcase       
     end
 end
     
                 
  always@(posedge clk or posedge rst)
 begin
   if(rst == 1'b1)
      tx_word_en_dly  <= 1'b0;     
   else 
      tx_word_en_dly  <= tx_word_en;
 end                 
                  
                  
                  
endmodule