`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:31:06 03/28/2017 
// Design Name: 
// Module Name:    dec_top 
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
module dec_top_new(
			
		input clk_200m,
		input cfg_rst,
		input clk_20mhz,
		
		input [15:0] data_1_i,
		input [15:0] data_1_q,
		input [31:0] loop_data,		

		output [15:0] data_64k_i_out,//解调后的IQ数据
		output [15:0] data_64k_q_out,
		output data_64k_out_en,
		
		output [31:0] data_msk_out,//解调后的32bit数据
		output data_msk_out_en,
		
		output [63:0] uart_demsk_data,
		output uart_demsk_data_valid,
		
		output [255:0] debug_dec_1,
		output [255:0] debug_dec_2
		
		
    );
    
assign debug_dec_1 =  debug_1_1;
assign debug_dec_2 =  debug_1_2;
    
wire clk_64khz;
wire clk_64_3khz;
wire clk_64_96khz;
wire [255:0] debug_1_1;
wire [255:0] debug_1_2;

//////////////////////////////////////////////////////////////////////////////////
//(1)21.33khz时钟产生模块
clk_creater clk_module(
.clk_200m(clk_200m),//in
.clk_50m(),

.cfg_rst(cfg_rst),
.slot_start_count(1'b1),//接收到dac返回的SPI结束信号，就将slot_start_count置1，且之后一直是1

.clk_64khz(clk_64khz),//out
.clk_64_3khz(clk_64_3khz),//21.33khz
.clk_64_96khz(clk_64_96khz)//666.67hz
);
//////////////////////////////////////////////////////////////////////////////////
//(2)200m->64khz滤波器组
filter_dec_top  dec_3125_inst(

		.clk_200m			(clk_200m),
		.cfg_rst				(cfg_rst),
		
		.data_i				(data_1_i),//200m sample
		.data_q				(data_1_q),
				

		.data_64k_i_out	(data_64k_i_out),//64k sample
		.data_64k_q_out	(data_64k_q_out),
		.data_64k_out_en  (data_64k_out_en),
		

		.debug_1				(/*debug_1_1*/),
		.debug_2				(/*debug_1_2*/)

);
//////////////////////////////////////////////////////////////////////////////////
//(3)msk解调模块
wire [15:0]tr_msk_out;
msk_demodulation_module demodulation_module
(
//// clock/reset ////
.logic_clk_in(clk_200m),// 200MHz logic clock
.logic_rst_in(cfg_rst),
.clk_20mhz(clk_20mhz),
.clk_64khz(clk_64khz),   //64khz
.clk_64_3khz(clk_64_3khz),//21.33khz
//// data signal ////
.data_msk_in({data_64k_q_out,data_64k_i_out}),// 64k sample rate
.data_msk_in_en(data_64k_out_en),
.data_msk_out(data_msk_out[31:0]),//32bit/1.5ms
.data_msk_out_en(data_msk_out_en),
.tr_msk_out(tr_msk_out[15:0]),

.uart_demsk_data_valid(uart_demsk_data_valid),
.uart_demsk_data(uart_demsk_data[63:0]),
//// debug ////
.debug_signal(debug_1_2)
);

////debug
assign debug_1_1[31:0] = data_msk_out[31:0];
assign debug_1_1[32] = data_msk_out_en;
assign debug_1_1[35:33] = {clk_64khz,clk_64_3khz,clk_64_96khz};
assign debug_1_1[51:36] = data_1_i[15:0];
assign debug_1_1[67:52] = data_1_q[15:0];
assign debug_1_1[83:68] = data_64k_i_out[15:0];
assign debug_1_1[99:84] = data_64k_q_out[15:0];
assign debug_1_1[100] = data_64k_out_en;

endmodule
