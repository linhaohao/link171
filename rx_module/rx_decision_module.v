//////////////////////////////////////////////////////////////////////////////////
// Company:         StarPoint
// Engineer:        GUO YAN 
// 
// Create Date:     09:31:20 07/27/2015 : 
// Module Name:     rx_decision_module 
// Project Name:    Rx synchronization correlation process;
// Target Devices:  FPGA - XC7K325T - FFG900; 
// Tool versions:   ISE14.6;  
// Description:     The module achieves SYNC and TR data of slot message correlation.
//
//
// Revision:        v1.0 - File Created
// Additional Comments: 
// 1. SYNC data: 16DP => 8 frequency;
// 2. TR data: 4DP => 8 frequency (same with SYNC frequency);
//
//
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps


module rx_decision_module(
//// clock/reset ////
input               logic_clk_in,                           // 200MHz logic clock
input               logic_rst_in, 

//// cvs signals ////
input [31:0]        sync_pn_in,                            // 32bits SYNC PN code
input [3:0]         sync_hop_chan_in,
input               sync_pn_hop_en_in,

input [31:0]        corr_tr_s0,                             // 32bits TR S0 code

input [10:0]        decision_term,                          // ^ correlation decision threhold

//// data signals ////
input               data_corr0_in,
input               data_corr1_in,
input               data_corr2_in,
input               data_corr3_in,
                    
input               tr_syn_en,
input [15:0]        data_tr_in,
                    
output[ 4:0]        coarse_position_out,
output              coarse_syn_success_out,
                    
output[ 6:0]        tr_position_out,
output              tr_syn_success_out,
output              tr_syn_finish_out,
                    
//// debug ////     
output[199:0]       debug_signal

    );


//////////////////////////////////////////////////////////////////////////////////
//// signals declaration ////
reg [ 4:0]          pn_xor_reg;

wire                correlate_success_all;
wire[10:0]          correlate_peak_all;

wire [199:0]        debug_coarse_syn_signal;
wire [127:0]        debug_tr_signal;

//////////////////////////////////////////////////////////////////////////////////
//// parameter defination ////

//////////////////////////////////////////////////////////////////////////////////
//// (0) signal assigment ////
assign   coarse_syn_success_out     = correlate_success_all;
assign   coarse_position_out[4:0]   = 5'd31;

//////////////////////////////////////////////////////////////////////////////////
//// (1) SYNC correlation ////
coarse_syn_four_chan u_coarse_syn_four_chan
    (
    .logic_clk_in(logic_clk_in),						// 200M
    .logic_rst_in(logic_rst_in),
	
    .sync_pn_in(sync_pn_in[31:0]),                         
    .sync_hop_chan_in(sync_hop_chan_in[3:0]),
    .sync_pn_hop_en_in(sync_pn_hop_en_in),
	
    .data_corr0_in(data_corr0_in), 					    // 第一路输入的25M码元
    .data_corr1_in(data_corr1_in), 					
    .data_corr2_in(data_corr2_in),
    .data_corr3_in(data_corr3_in),
    
    .decision_term(decision_term[10:0]),
	
    .correlate_success_all(correlate_success_all),
	.correlate_peak_all(correlate_peak_all[10:0]),
    
    .debug_signal(debug_coarse_syn_signal[199:0])
    
    );

//////////////////////////////////////////////////////////////////////////////////
//// (2) TR decision logic ////
tr_syn_module u_tr_syn_module
   (
   .logic_clk_in(logic_clk_in),           		// 200M
   .logic_rst_in(logic_rst_in),
   
   .data_in(data_tr_in[15:0]),  			
   .tr_syn_en(tr_syn_en),
   .tr_syn_code(corr_tr_s0[31:0]),                  

   .tr_position_out(tr_position_out[6:0]),
   .tr_syn_success_out(tr_syn_success_out),
   .tr_syn_finish_out(tr_syn_finish_out),
   
   .debug_signal(debug_tr_signal[127:0])
   );




//////////////////////////////////////////////////////////////////////////////////
//// debug ////
assign  debug_signal[199:0]            = debug_coarse_syn_signal[199:0]; 
//assign  debug_signal[199:171]          = //debug_tr_signal[71:0];


//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
endmodule
