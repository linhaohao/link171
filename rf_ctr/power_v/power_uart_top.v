`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:22:37 11/23/2015 
// Design Name: 
// Module Name:    power_uart_top 
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
module power_uart_top(
				clk,rst_n,
				rs232_rx,
				rs232_tx,
				recieve_data,recirve_vld,
				send_en,send_data,send_vld
				);

input clk;			// 50MHz主时钟
input rst_n;		//低电平复位信号

input rs232_rx;		// RS232接收数据信号
output rs232_tx;	//	RS232发送数据信号

output [39:0] recieve_data;		//命令串解析后的接受数据
output recirve_vld;				//命令接受指示，为高表示接受到一个64位数据

input send_en;					//发送数据指示，为高脉冲即发送一个64位送入的数据
input [31:0] send_data;			//命令串解析后的接受数据
output send_vld;				//发送命令过程中为高，send_en需在send_vld为低时有效

wire bps_start1,bps_start2;	//接收到数据后，波特率时钟启动信号置位
wire clk_bps1,clk_bps2;		// clk_bps_r高电平为接收数据位的中间采样点,同时也作为发送数据的数据改变点 
wire[7:0] rx_data;	//接收数据寄存器，保存直至下一个数据来到
wire rx_int;		//接收数据中断信号,接收到数据期间始终为高电平
wire comnd_en;		//外部命令使能发送模块
wire [7:0] comnd_data;
wire send_en_valid;	//内部发送时期为高

parameter		BPS_PARA 	=	2082,	//115200--172//波特率分频计数值 = （系统时钟clk / 波特率）-1
				BPS_PARA_2	=	1041,		//为波特率分频计数值的一半，用于数据采样
				WAIT_TIME	=	22916;	//115200--1910//WAIT_TIME == clk / 波特率 * 11

//----------------------------------------------------
//下面的四个模块中，speed_rx和speed_tx是两个完全独立的硬件模块，可称之为逻辑复制
//（不是资源共享，和软件中的同一个子程序调用不能混为一谈）
////////////////////////////////////////////
speed_select	#(.BPS_PARA(BPS_PARA),
				  .BPS_PARA_2(BPS_PARA_2))	
				speed_rx(	
							.clk(clk),	//波特率选择模块
							.rst_n(rst_n),
							.bps_start(bps_start1),
							.clk_bps(clk_bps1)
						);

my_uart_rx			my_uart_rx(		
							.clk(clk),	//接收数据模块
							.rst_n(rst_n),
							.rs232_rx(rs232_rx),		//rs232_rx
							.rx_data(rx_data),
							.rx_int(rx_int),
							.clk_bps(clk_bps1),
							.bps_start(bps_start1)
						);

///////////////////////////////////////////						
speed_select	#(.BPS_PARA(BPS_PARA),
				  .BPS_PARA_2(BPS_PARA_2))	
			  speed_tx(	
							.clk(clk),	//波特率选择模块
							.rst_n(rst_n),
							.bps_start(bps_start2),
							.clk_bps(clk_bps2)
						);

my_uart_tx			my_uart_tx(		
							.clk(clk),	//发送数据模块
							.rst_n(rst_n),
							.rx_data(rx_data),
							.rx_int(rx_int),
							.rs232_tx(rs232_tx),
							.clk_bps(clk_bps2),
							.bps_start(bps_start2),
							.comnd_en(comnd_en),
							.send_en_valid(send_en_valid),
							.comnd_data(comnd_data)
						);
//接受命令串
power_rx_decode	#(.WAIT_TIME(WAIT_TIME))		
            rx_decode_u(
							.clk(clk),	//发送数据模块
							.rst_n(rst_n),
							.rx_ready(bps_start1),	//为高时表示正在接受状态，为低才进行新的接受
							.rx_data(rx_data),
							.recieve_data(recieve_data),
							.recirve_vld(recirve_vld)
						);
//发送命令串
power_tx_decode			tx_decode_u(
							.clk(clk),	//发送数据模块
							.rst_n(rst_n),
							.tx_ready(bps_start2),	//为高时表示正在接受状态，为低才进行新的接受
							.send_en(send_en),
							.send_en_valid(send_en_valid),
							.tx_data(send_data),
							.comnd_data(comnd_data),
							.send_vld(send_vld),
							.comnd_en(comnd_en)
						);

endmodule

