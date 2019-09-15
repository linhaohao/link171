`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    09:31:26 03/28/2017 
// Design Name: 
// Module Name:    rx_top 
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
module rx_top(
		input clk_200m,
		input clk_5m,
		input clk_50m,
		input clk_20m,
		input cfg_rst,
		
		//-------------ADC0 IN--------------------
		input [6:0]              adc0_data_a_p,
		input [6:0]              adc0_data_a_n,
		input [6:0]              adc0_data_b_p,
		input [6:0]              adc0_data_b_n,
		input                    adc0_or_p,
		input                    adc0_or_n,
		input                    adc0_clk,
		//-------------ADC1 IN--------------------
		input [6:0]              adc1_data_a_p,
		input [6:0]              adc1_data_a_n,
		input [6:0]              adc1_data_b_p,
		input [6:0]              adc1_data_b_n,
		input                    adc1_or_p,
		input                    adc1_or_n,
		input                    adc1_clk,

		input 						 dac_txenable,
      input 						 data_updated,	
      input 						 start_send,
		input [16:0]				 send_step,
		output    					 dsp_receive_interrupt,
		output [31:0]				 data_dsp,
		input  [31:0]				 loop_data,
		input  						 slot_interrupt,
		input 						 slot_start_count,
		input 						 init_rx_slot,
		input 						 rx_dds_en,
		input 						 part_syn_start,
		output						 part_syn_en,
		
		output [63:0]            uart_demsk_data,
		output                   uart_demsk_data_valid,
		
		output [255:0]				 debug_decode,
		output [255:0]           debug_data_dsp,		
		output [255:0]           sync_con_debug,
		output [255:0]           debug_iq,
		output [255:0]           debug_adc_2,
		output [255:0]	          debug_dec_1,
		output [255:0]	          debug_dec_2
    );

wire rx_hb1_en;
wire rx_fir6_rdy;
wire [255:0] debug_iq;
wire [127:0] debug_signal;
wire [255:0] debug_adc;
assign dsp_receive_interrupt = dsp_receive_interrupt_reg_dl;
//assign debug_dec_1 = 256'd0;
//assign debug_dec_2 = 256'd0;

wire [15:0]            adc0_data_a;
wire [15:0]            adc0_data_b;
wire [15:0]            adc1_data_a;
wire [15:0]            adc1_data_b;

wire signed [15:0] data_out_1_i;
wire signed [15:0] data_out_1_q;
//wire signed [15:0] data_out_2_i;
//wire signed [15:0] data_out_2_q;
//wire signed [15:0] data_out_3_i;
//wire signed [15:0] data_out_3_q;
//wire signed [15:0] data_out_4_i;
//wire signed [15:0] data_out_4_q;

wire signed [15:0] data_dsp_1_i;
wire signed [15:0] data_dsp_1_q;


wire signed [15:0] data_64_3k_i_out;
wire signed [15:0] data_64_3k_q_out;
wire data_msk_out_en;

wire [31:0] corase_pos;
wire [31:0]	fine_pos;
wire [15:0] wr_addr_out;
wire data_send_end;

ad_receive ad_receive_inst(
	 .clk_200m								 (clk_200m),
	 .cfg_rst								 (cfg_rst),
		
		//-------------ADC0 IN-------------------------------------------
    .adc0_data_a_p           (adc0_data_a_p),
    .adc0_data_a_n           (adc0_data_a_n),
    .adc0_data_b_p           (adc0_data_b_p),
    .adc0_data_b_n           (adc0_data_b_n),
    .adc0_or_p               (adc0_or_p    ),
    .adc0_or_n               (adc0_or_n    ),
	 .adc0_clk                (adc0_clk     ),
		
		//-------------ADC1 IN-------------------------------------------
    .adc1_data_a_p           (adc1_data_a_p),
    .adc1_data_a_n           (adc1_data_a_n),
    .adc1_data_b_p           (adc1_data_b_p),
    .adc1_data_b_n           (adc1_data_b_n),
    .adc1_or_p               (adc1_or_p    ),
    .adc1_or_n               (adc1_or_n    ),
	 .adc1_clk                (adc1_clk     ),
		
		//-------------ADC OUT------------------------------------------
    .adc0_data_a_out         (adc0_data_a     ),//200m
    .adc0_data_b_out         (adc0_data_b     ),
    .adc1_data_a_out         (adc1_data_a     ),          
    .adc1_data_b_out         (adc1_data_b     ),
    .debug_signal				  (debug_signal    )			
);


ddc_top ddc_top_inst(//进行50MHZ的数字下变频
	 .clk_200m								 (clk_200m),
	 .cfg_rst								 (cfg_rst),
	 //IN
    .adc0_data_a				 		(adc0_data_a   ),    
    .loop_data							(loop_data),
//    .adc0_data_b         		(adc0_data_b  ),
//    .adc1_data_a         		(adc1_data_a  ),          
//    .adc1_data_b 		         (adc1_data_b  ),
    .dac_txenable						(dac_txenable),//无用信号，仅供于给debug_iq进行调试
    .rx_dds_en							(rx_dds_en),
    //OUT
    .data_out_1_i						(data_out_1_i[15:0]),
	 .data_out_1_q						(data_out_1_q[15:0]),
//		.data_out_2_i						(data_out_2_i),
//		.data_out_2_q						(data_out_2_q),
//		.data_out_3_i						(data_out_3_i),
//		.data_out_3_q						(data_out_3_q),
//		.data_out_4_i						(data_out_4_i),
//		.data_out_4_q						(data_out_4_q),
    .ddc_iq_debug						(debug_iq)	

);






dec_top_new dec_top_inst(
		.clk_200m				(clk_200m),
		.cfg_rst					(cfg_rst),
		.clk_20mhz           (clk_20m),

      .data_1_i				(data_out_1_i[15:0]),//200m sample
		.data_1_q				(data_out_1_q[15:0]),
//		.data_2_i				(data_out_2_i),
//		.data_2_q				(data_out_2_q),
//		.data_3_i				(data_out_3_i),
//		.data_3_q				(data_out_3_q),
//		.data_4_i				(data_out_4_i),
//		.data_4_q				(data_out_4_q),
		
//		.loop_data				(loop_data),
		
		.data_64k_i_out		  (),
		.data_64k_q_out		  (),
		.data_64k_out_en       (),
		.data_msk_out          ({data_64_3k_q_out,data_64_3k_i_out}),//21.33k sample rate
		.data_msk_out_en       (data_msk_out_en),
		.uart_demsk_data       (uart_demsk_data[63:0]),
		.uart_demsk_data_valid (uart_demsk_data_valid),
		.debug_dec_1 			  (debug_dec_1),
		.debug_dec_2			  (debug_dec_2)

);



store_ram  store_ram_inst
(
		.clk_50m						(clk_50m),
		.cfg_rst						(cfg_rst),
		.clk_mcbsp					(clk_20m),		

		.data_200k_i_out		(data_64_3k_i_out),
		.data_200k_q_out		(data_64_3k_q_out),
		.read_quest					(read_quest),
		.data_dsp						(data_dsp),	
		/////////////////////////////////////////// 
	 	.part_syn_en        (part_syn_en),
	  .part_syn_start     (part_syn_start), 	
	  //////////////////////////////////////////////		

		.init_rx_slot				(init_rx_slot),
		.slot_start_count		(slot_start_count),		

		.data_updated				(data_updated),
		.start_send  				(start_send),
		.send_step					(send_step),
				
		.debug_decode				(debug_decode),
		.data_dsp_debug			(debug_data_dsp)

);


///////////////////////产生取数中断/////////////////

reg read_quest_dl;
wire dsp_receive_interrupt_reg;
reg dsp_receive_interrupt_reg_dl;
reg [7:0] dsp_receive_interrupt_count;
reg slot_reg;
reg slot_count_start;
reg [31:0] slot_count;

always@(posedge clk_50m or posedge cfg_rst) begin
		if(cfg_rst) begin
			read_quest_dl <= 1'b0;
		end
		else begin
			read_quest_dl <= read_quest;
		end
end


assign dsp_receive_interrupt_reg = !read_quest_dl & read_quest;


always@(posedge clk_50m or posedge cfg_rst) begin
		if(cfg_rst) begin
			dsp_receive_interrupt_reg_dl <= 1'd0;
		end
		else if(dsp_receive_interrupt_count >= 8'd100)begin
			dsp_receive_interrupt_reg_dl <= 1'd0;
		end
		else if(dsp_receive_interrupt_reg)begin
			dsp_receive_interrupt_reg_dl <= 1'd1;
		end
		else begin
			dsp_receive_interrupt_reg_dl <= dsp_receive_interrupt_reg_dl;
		end
end

always@(posedge clk_50m or posedge cfg_rst) begin
		if(cfg_rst) begin
			dsp_receive_interrupt_count <= 8'b0;
		end
		else if(dsp_receive_interrupt_count >= 8'd100)begin
			dsp_receive_interrupt_count <= 8'b0;
		end
		else if(dsp_receive_interrupt_reg_dl)begin
			dsp_receive_interrupt_count <= dsp_receive_interrupt_count + 8'd1;
		end
		else begin
			dsp_receive_interrupt_count <= dsp_receive_interrupt_count;
		end
end


/////////////test the frequency of the request signal///////////////			
reg [10:0] count_interrupt;

always@(posedge clk_50m or posedge cfg_rst) begin
		if(cfg_rst) begin
			count_interrupt <= 11'd0;
		end
		else if(slot_interrupt) begin
			count_interrupt <= 11'd0;
		end
		else if(dsp_receive_interrupt_reg)begin
			count_interrupt <= count_interrupt + 11'd1;
		end
		else begin
			count_interrupt <= count_interrupt;
		end
end




//assign debug_adc[127:0] = debug_signal;
//assign debug_adc[255:128] = debug_iq;
//
//assign debug_adc_2[15:0]  = data_out_1_i;
//assign debug_adc_2[31:16] = data_out_1_q;
//assign debug_adc_2[32] = read_quest;
//assign debug_adc_2[33] = read_quest_dl;
//assign debug_adc_2[34] = dsp_receive_interrupt_reg;
//assign debug_adc_2[35] = dsp_receive_interrupt_reg_dl;
//assign debug_adc_2[39:36] = dsp_receive_interrupt_count;
//assign debug_adc_2[50:40] = count_interrupt;
//assign debug_adc_2[51] = slot_reg;
//assign debug_adc_2[52] = slot_count_start;
//assign debug_adc_2[84:53] = slot_count;
//assign debug_adc_2[127:85] = 0;
//assign debug_adc_2[255:128] = debug_iq;

//assign debug_dec_1[31:0] = {data_64_3k_q_out,data_64_3k_i_out};
//assign debug_dec_1[32] = data_msk_out_en;

endmodule
