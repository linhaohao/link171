//////////////////////////////////////////////////////////////////////////////////
// Company:         StarPoint
// Engineer:        GUO YAN 
// 
// Create Date:     16:16:12 07/27/2015 
// Module Name:     rx_decision_top 
// Project Name:    Rx synchronization correlation process;
// Target Devices:  FPGA - XC7K325T - FFG900; 
// Tool versions:   ISE14.6;   
// Description:     The module achieves data of SYNC/TR correlation which used for 
//                  judging received slot message position.
//
// Revision:        v1.0 - File Created
// Additional Comments: 
// 1. 1 PN code correlation of SYNC data for four link;
// 2. S0 correlation of TR data;
// 3. 
//
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps


module rx_decision_top(
//// clock/reset ////
input               logic_clk_in,                           // 200MHz logic clock
input               logic_rst_in, 

//// cvs signals ////
input [11:0]        mif_dec_th_in,

input [31:0]        link_sync_pn,
input [3:0]         link_sync_hop_chan,
input               link_sync_pn_hop_en,

input [31:0]        link_tr_s0,

//// data signals ////
input               data_corr0_in,
input               data_corr1_in,
input               data_corr2_in,
input               data_corr3_in,

input               tr_syn_en,
input [15:0]        data_tr_in,

//// decision conclusion ////
output[4:0]         coarse_position_out,
output              coarse_syn_success_out, 

output[6:0]         tr_position_out,
output              tr_syn_success_out,
output              tr_syn_finish_out,

//// debug ////
output[199:0]       debug_signal

    );



//////////////////////////////////////////////////////////////////////////////////
//// signals declaration //// 
reg  [10:0]         decision_threshold          = 11'd800;//11'd1000;

wire [199:0]        debug_rx_dec_signal;



//////////////////////////////////////////////////////////////////////////////////
//// parameter defination ////

//////////////////////////////////////////////////////////////////////////////////
//// (0) coarse threshold selection ////
always@(posedge logic_clk_in) 
begin
    if (logic_rst_in)   begin
	  decision_threshold[10:0]                    <= 11'd800;//11'd1000;
	end
	else if(mif_dec_th_in[11])begin
	  decision_threshold[10:0]                    <= mif_dec_th_in[10:0];
	end
end

//////////////////////////////////////////////////////////////////////////////////
//// (1) link1 MSK decision logic mapping ////
rx_decision_module   u0_rx_decision
   (
	// clock&reset signals
	.logic_clk_in(logic_clk_in),                        // 200MHz
	.logic_rst_in(logic_rst_in),
	
	// cvs signals
	.sync_pn_in(link_sync_pn[31:0]),
    .sync_hop_chan_in(link_sync_hop_chan[3:0]),
    .sync_pn_hop_en_in(link_sync_pn_hop_en),
	
	.corr_tr_s0(link_tr_s0[31:0]),
	
	.decision_term(decision_threshold[10:0]),
	
	// data signals
	.data_corr0_in(data_corr0_in),                      // 25Mchips/s
	.data_corr1_in(data_corr1_in),
	.data_corr2_in(data_corr2_in),
	.data_corr3_in(data_corr3_in),
	
    .tr_syn_en(tr_syn_en),
    .data_tr_in(data_tr_in[15:0]),
	
	.coarse_position_out(coarse_position_out[4:0]),
    .coarse_syn_success_out(coarse_syn_success_out), 

    .tr_position_out(tr_position_out[6:0]),
    .tr_syn_success_out(tr_syn_success_out),
    .tr_syn_finish_out(tr_syn_finish_out),
	
	// debug
	.debug_signal(debug_rx_dec_signal[199:0])	
	
	);



//////////////////////////////////////////////////////////////////////////////////
//// debug ////
assign  debug_signal[199:0]             = debug_rx_dec_signal[199:0];



//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
endmodule
