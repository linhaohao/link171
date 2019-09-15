`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    09:40:33 03/28/2017 
// Design Name: 
// Module Name:    ddc_top 
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
module ddc_top(
		input clk_200m,
		input cfg_rst,
		
		input [15:0] adc0_data_a,
//		input [15:0] adc0_data_b,
//		input [15:0] adc1_data_a,
//		input [15:0] adc1_data_b,    
      input [31:0] loop_data,
		input dac_txenable,
		input rx_dds_en,
		
		output [15:0] data_out_1_i,
		output [15:0] data_out_1_q,
//		output [15:0] data_out_2_i,
//		output [15:0] data_out_2_q,
//		output [15:0] data_out_3_i,
//		output [15:0] data_out_3_q,
//		output [15:0] data_out_4_i,
//		output [15:0] data_out_4_q,
		
		output [255:0] ddc_iq_debug
					
    );

//assign data_out_1_i = data_out_1_i_r;
//assign data_out_1_q = data_out_1_q_r;
//assign data_out_2_i = data_out_2_i_r;
//assign data_out_2_q = data_out_2_q_r;
//assign data_out_3_i = data_out_3_i_r;
//assign data_out_3_q = data_out_3_q_r;
//assign data_out_4_i = data_out_4_i_r;
//assign data_out_4_q = data_out_4_q_r;

wire [255:0] ddc_iq_debug;
//wire [127:0] debug_dds_2;
//wire [127:0] debug_dds_3;
//wire [127:0] debug_dds_4;

//wire [15:0] data_out_1_i_r;
//wire [15:0] data_out_1_q_r;
//wire [15:0] data_out_2_i_r;
//wire [15:0] data_out_2_q_r;
//wire [15:0] data_out_3_i_r;
//wire [15:0] data_out_3_q_r;
//wire [15:0] data_out_4_i_r;
//wire [15:0] data_out_4_q_r;



reg [27:0]  adc0_data_a_fcw;
//reg [27:0]  adc0_data_b_fcw;
//reg [27:0]  adc1_data_a_fcw;
//reg [27:0]  adc1_data_b_fcw;

always@(posedge clk_200m or posedge cfg_rst) begin
	if(cfg_rst) begin
			adc0_data_a_fcw <= 28'd0;
//			adc0_data_b_fcw <= 28'd0;
//			adc1_data_a_fcw <= 28'd0;
//			adc1_data_b_fcw <= 28'd0;
	end
	else begin
//			adc0_data_a_fcw <= 28'h5333333;
			adc0_data_a_fcw <= 28'h4000000;//50MHZ的DDS输出频率控制字
//			adc0_data_b_fcw <= 28'd0;
//			adc1_data_a_fcw <= 28'd0;
//			adc1_data_b_fcw <= 28'd0;
	end
end
			
ddc_iq ddc_iq_1(
		.clk_200m				(clk_200m),
		.cfg_rst					(cfg_rst),
		
		.dac_txenable 		   (dac_txenable),
		.rx_dds_en				(rx_dds_en),
		.data						(adc0_data_a),		
		.loop_data				(loop_data),
		.fcw_data				(adc0_data_a_fcw),
		
		.data_out_i				(data_out_1_i[15:0]),
		.data_out_q				(data_out_1_q[15:0]),
		.ddc_iq_debug			(ddc_iq_debug)
);


//ddc_iq ddc_iq_2(
//		.clk_200m					(clk_200m),
//		.cfg_rst					(cfg_rst),
//		
//		.data							(adc0_data_b),
//		.fcw_data					(adc0_data_b_fcw),
//		
//		.data_out_i				(data_out_2_i),
//		.data_out_q				(data_out_2_q),
//		.debug						(debug_dds_2)
//);
//
//ddc_iq ddc_iq_3(
//		.clk_200m					(clk_200m),
//		.cfg_rst					(cfg_rst),
//		
//		.data							(adc1_data_a),
//		.fcw_data					(adc1_data_a_fcw),
//		
//		.data_out_i				(data_out_3_i),
//		.data_out_q				(data_out_3_q),
//		.debug						(debug_dds_3)
//);
//
//ddc_iq ddc_iq_4(
//		.clk_200m					(clk_200m),
//		.cfg_rst					(cfg_rst),
//		
//		.data							(adc1_data_b),
//		.fcw_data					(adc1_data_b_fcw),
//		
//		.data_out_i				(data_out_4_i),
//		.data_out_q				(data_out_4_q),
//		.debug						(debug_dds_4)
//);



 
endmodule
