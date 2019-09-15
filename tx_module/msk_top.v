//////////////////////////////////////////////////////////////////////////////////
// Company:         StarPoint
// Engineer:        guoyan
// 
// Create Date:     15:24:00 06/10/2015  
// Module Name:     msk_top
// Project Name:    
// Target Devices:  FPGA - XC7K325T - FFG900; 
// Tool versions:   ISE14.6;  
// Description:     The module achieves msk modulation which contains 3 submodule
// 
// Revision:        v1.0 - File Created
// Additional Comments: 
// 
// 
//
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

module msk_top(
//// clock/reset ////
input               clk_msk_in, //50M
input               logic_clk_in,
input               logic_rst_in,

//// data signal ////
input              	msk_data_in_pulse, //6.4us&6.6us
input               msk_data_in_5M,    //5M en occupy 1 clk(200M)
input               msk_data_in,       //200M sample && 5M rate
input[6:0]          msk_data_cnt,      //5M chip counter

// output              msk_vaild_out,
// output[15:0]        msk_mod_out,
output              msk_vaild_ahead,
output              msk_vaild_out, //6.4&6.6us
output[15:0]        msk_i_out,
output[15:0]        msk_q_out,

//// debug ////
output[127:0]       debug_msk_signal
);

//////////////////////////////////////////////////////////////////////////////////
//// signals declaration //// 
/////
wire	             msk_data_in_vaild;	
		  
//// s2p signals ////
wire                 s2p_pulse_out;
wire                 s2p_vaild_out;
wire                 s2p_i_out;
wire                 s2p_q_out;

//// phase signals
wire                 phase_vaild_ahead;
wire                 phase_vaild_out;
wire signed[15:0]    phase_cos_out;
wire signed[15:0]    phase_sin_out; //signed only for printf

//// debug signals
wire [63:0]          debug_msk_s2p;
wire [63:0]          debug_msk_phase;	

///////
assign  msk_data_in_vaild = msk_data_in_pulse && msk_data_in_5M; //MSK work only in 5M rate,otherwise diff conversion will make mistake

//////////////////////////////////////////////////////////////////////////////////
//调用基带数据处理模块
msk_s2p U0_msk_s2p
       (
	    .logic_clk_in(logic_clk_in),
        .logic_rst_in(logic_rst_in),
		.msk_data_in_pulse(msk_data_in_pulse),
        .msk_data_in_vaild(msk_data_in_vaild),
        .msk_data_in(msk_data_in),
		.msk_data_cnt(msk_data_cnt[6:0]),
        .s2p_pulse_out(s2p_pulse_out),		
		.s2p_vaild_out(s2p_vaild_out),
        .s2p_i_out(s2p_i_out),
        .s2p_q_out(s2p_q_out),
        .debug_signal(debug_msk_s2p[63:0])
        ); 
		
//////////////////////////////////////////////////////////////////////////////////
//调用IQ路加权模块phase.v
msk_phase U1_msk_phase
       (
        .clk_msk_in(clk_msk_in),
        .logic_rst_in(logic_rst_in),
		.phase_pulse_in(s2p_pulse_out),
        .phase_vaild_in(s2p_vaild_out),
        .phase_i_in(s2p_i_out),
        .phase_q_in(s2p_q_out), //5M rate, 200M sample
		.phase_vaild_ahead(phase_vaild_ahead),
		.phase_vaild_out(phase_vaild_out),
        .phase_cos_out(phase_cos_out[15:0]),
        .phase_sin_out(phase_sin_out[15:0]),
        .debug_signal(debug_msk_phase[63:0])
	   );
	   
assign msk_i_out[15:0] = phase_cos_out[15:0];
assign msk_q_out[15:0] = phase_sin_out[15:0];
assign msk_vaild_out   = phase_vaild_out;
assign msk_vaild_ahead = phase_vaild_ahead;
  
//////////////////////////////////////////////////////////////////////////////////
//载波调制相加模块iqmodu.v
// msk_iqmodu U2_msk_iqmodu
       // (
        // .clk_msk_in(clk_msk_in),
        // .logic_rst_in(logic_rst_in),
        // .mod_vaild_in(phase_vaild_out),
        // .mod_i_in(phase_cos_out),
        // .mod_q_in(phase_sin_out),
		// .msk_vaild_out(msk_vaild_out),
        // .msk_mod_out(msk_mod_out),
        // .debug_signal()
       // );
	   
//////////////////////////////////////////////////////////////////////////////////
//// debug signals ////
assign  debug_msk_signal[63:0]    = debug_msk_s2p[63:0];
assign  debug_msk_signal[127:64]  = debug_msk_phase[63:0];	

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////   
endmodule



