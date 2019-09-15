`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:
// Design Name:    
// Module Name:    my_uart_top
// Project Name:   
// Target Device:  
// Tool versions:  
// Description:
//
// Dependencies:
// RS232接受或发送8byte的命令串，命令串（10个字节）起始、结束标识分别为8'hc0、8'hcf;
// 本模块中53--55行的数值需要根据时钟和波特率，这个正确设置
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 欢迎加入EDN的FPGA/CPLD助学小组一起讨论：http://group.ednchina.com/1375/
////////////////////////////////////////////////////////////////////////////////
module uart_top(
				clk,rst_n,
				rs232_rx,
				rs232_tx,
				recieve_data,recirve_vld,
				send_en,send_data,send_vld,
				debug_signal
				);

input clk;			// 50MHz主时钟
input rst_n;		//低电平复位信号

input rs232_rx;		// RS232接收数据信号
output rs232_tx;	//	RS232发送数据信号

output [63:0] recieve_data;		//命令串解析后的接受数据
output recirve_vld;				//命令接受指示，为高表示接受到一个64位数据

input send_en;					//发送数据指示，为高脉冲即发送一个64位送入的数据
input [63:0] send_data;			//命令串解析后的接受数据
output send_vld;				//发送命令过程中为高，send_en需在send_vld为低时有效
output [255:0] debug_signal;  //debug信号

wire bps_start1,bps_start2;	//接收到数据后，波特率时钟启动信号置位
wire clk_bps1,clk_bps2;		// clk_bps_r高电平为接收数据位的中间采样点,同时也作为发送数据的数据改变点 
wire[7:0] rx_data;	//接收数据寄存器，保存直至下一个数据来到
wire rx_int;		//接收数据中断信号,接收到数据期间始终为高电平
wire comnd_en;		//外部命令使能发送模块
wire [7:0] comnd_data;
wire send_en_valid;	//内部发送时期为高

parameter		BPS_PARA 	=	172,		//波特率分频计数值 = （系统时钟clk / 波特率）-1
				BPS_PARA_2	=	86,		//为波特率分频计数值的一半，用于数据采样
				WAIT_TIME	=	1910;	//WAIT_TIME == clk / 波特率 * 11

wire       rs232_tx_intel;  //FPGA内部输出的信号   
                
//切换发送总线的输出，在接受字节过程中时，直接短接tx = rx_data
assign     rs232_tx     =    bps_start1 ? rs232_rx : rs232_tx_intel;
                
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
							.rs232_tx(rs232_tx_intel), //rs232_tx
							.clk_bps(clk_bps2),
							.bps_start(bps_start2),
							.comnd_en(comnd_en),
							.send_en_valid(send_en_valid),
							.comnd_data(comnd_data)
						);
//接受命令串
rx_decode	#(.WAIT_TIME(WAIT_TIME))		
            rx_decode_u(
							.clk(clk),	//发送数据模块
							.rst_n(rst_n),
							.rx_ready(bps_start1),	//为高时表示正在接受状态，为低才进行新的接受
							.rx_data(rx_data),
							.recieve_data(recieve_data),
							.recirve_vld(recirve_vld)
						);
//发送命令串
tx_decode			tx_decode_u(
							.clk(clk),	//发送数据模块
							.rst_n(rst_n),
							.tx_ready(bps_start2),	//为高时表示正在接受状态，为低才进行新的接受,input
							.send_en(send_en),  //input
							.send_en_valid(send_en_valid),
							.tx_data(send_data),  //input
							.comnd_data(comnd_data),
							.send_vld(send_vld),
							.comnd_en(comnd_en)
						);


//////////////////////////////////////////////////////////////////////////////////////////////
assign debug_signal[0] = rs232_rx;
assign debug_signal[1] = rs232_tx;
assign debug_signal[2] = recirve_vld;
assign debug_signal[3] = send_en;
assign debug_signal[4] = send_vld;
assign debug_signal[68:5] = recieve_data[63:0];
assign debug_signal[132:69] = send_data[63:0];

endmodule
