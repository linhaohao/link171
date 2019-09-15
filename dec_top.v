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
module dec_top(
			
		input clk_200m,
		input cfg_rst,
		
		input [15:0] data_1_i,
		input [15:0] data_1_q,
//		input [15:0] data_2_i,
//		input [15:0] data_2_q,
//		input [15:0] data_3_i,
//		input [15:0] data_3_q,
//		input [15:0] data_4_i,
//		input [15:0] data_4_q,
		input [31:0] loop_data,		

		output [15:0] data_200k_i_out,
		output [15:0] data_200k_q_out,
		
		output [255:0] debug_dec_1,
		output [255:0] debug_dec_2
		
		
    );
    
assign debug_dec_1 =  debug_1_1;
assign debug_dec_2 =  debug_1_2;
    
//wire [15:0] data_out_1_i;
//wire [15:0] data_out_1_q;
//wire [15:0] data_out_2_i;
//wire [15:0] data_out_2_q;
//wire [15:0] data_out_3_i;
//wire [15:0] data_out_3_q;
//wire [15:0] data_out_4_i;
//wire [15:0] data_out_4_q;

wire [255:0] debug_1_1;
wire [255:0] debug_1_2;

  
dec_10k  dec_10_1_inst(

		.clk_200m			(clk_200m),
		.cfg_rst				(cfg_rst),
		
		.data_i					(data_1_i),
		.data_q					(data_1_q),
		.loop_data			(loop_data),
				

		.data_200k_i_out			(data_200k_i_out),
		.data_200k_q_out			(data_200k_q_out),
		

		.debug_1				(debug_1_1),
		.debug_2				(debug_1_2)

);

//dec_10k  dec_10_2_inst(
//
//		.clk_200m				(clk_200m),
//		.cfg_rst				(cfg_rst),
//		
//		.data_i					(data_2_i),
//		.data_q					(data_2_q),
//		
//		.data_i_out			(data_out_2_i),
//		.data_q_out			(data_out_2_q),
//		
//		.debug_1				(),
//		.debug_2				()
//
//);
//
//dec_10k  dec_10_3_inst(
//
//		.clk_200m				(clk_200m),
//		.cfg_rst				(cfg_rst),
//		
//		.data_i					(data_3_i),
//		.data_q					(data_3_q),
//		
//		.data_i_out			(data_out_3_i),
//		.data_q_out			(data_out_3_q),
//		
//		.debug_1				(),
//		.debug_2				()
//
//);
//
//dec_10k  dec_10_4_inst(
//
//		.clk_200m				(clk_200m),
//		.cfg_rst				(cfg_rst),
//		
//		.data_i					(data_4_i),
//		.data_q					(data_4_q),
//		
//		.data_i_out			(data_out_4_i),
//		.data_q_out			(data_out_4_q),
//		
//		.debug_1				(),
//		.debug_2				()
//
//);


endmodule
