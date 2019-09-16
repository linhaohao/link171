`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:32:51 09/16/2019 
// Design Name: 
// Module Name:    debug_pc 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
// 通过串口传输的方式传输到电脑上进行观察内部信号变量的值的变化是否符合预期情况
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module debug_pc(
input sys_rest,

input clk_20mhz,
input clk_50mhz,
input clk_25kHz,

input rv_uart_vld,
input [63:0] rv_uart_data,

input uart_demsk_data_valid,
input [63:0] uart_demsk_data,

input [31:0] send_data,

output mif_data_vaild,
output [63:0] mif_data_out
    );

reg [7:0] choice;
reg watch_dog;
reg close_watch_dog;
reg [31:0]timing_1s;

//根据串口传输过来的指令选择观察什么信号
always@(posedge clk_20mhz or posedge sys_rest)begin
	if(sys_rest)begin
		choice[7:0] <= 8'd0;
	end
	else if(rv_uart_vld && rv_uart_data[63:0] == 64'haabb0001)begin
		choice[7:0] <= 8'd1;
	end
	else if(rv_uart_vld && rv_uart_data[63:0] == 64'haabb0002)begin
		choice[7:0] <= 8'd2;
	end
	else if(close_watch_dog)begin
		choice[7:0] <= choice[7:0];
	end
	else if(watch_dog)begin
		choice[7:0] <= 8'd0;
	end
end

//choice不等于0且1秒的时间到了，关闭choice通道
always@(posedge clk_20mhz or posedge sys_rest)begin
	if(sys_rest)begin
		watch_dog <= 1'b0;
	end
	else if(timing_1s[31:0] == 32'd20000000)begin
		watch_dog <= 1'b1;
	end
	else begin
		watch_dog <= 1'b0;
	end
end
always@(posedge clk_20mhz or posedge sys_rest)begin
	if(sys_rest)begin
		timing_1s[31:0] <= 32'd0;
	end
	else if(timing_1s[31:0] == 32'd20000000)begin//计时1秒
		timing_1s[31:0] <= 32'd0;
	end
	else if(choice[7:0] != 8'd0)begin
		timing_1s[31:0] <= timing_1s[31:0] + 32'd1;
	end
	else begin
		timing_1s[31:0] <= timing_1s[31:0];
	end
end
//关闭watch_dog效果
always@(posedge clk_20mhz or posedge sys_rest)begin
	if(sys_rest)begin
		close_watch_dog <= 1'b0;
	end
	else if(rv_uart_vld && rv_uart_data[63:0] == 64'haabb0000)begin
		close_watch_dog <= 1'b1;
	end
end

//将选择的信号连接到输出串口上
assign mif_data_out[63:0] = (choice[7:0] == 8'd1) ? uart_demsk_data[63:0]:
							(choice[7:0] == 8'd2) ? {choice[7:0],24'd0,send_data[31:0]}:
							64'd0;
							
assign mif_data_vaild = (choice[7:0] == 8'd1) ? uart_demsk_data_valid:
						(choice[7:0] == 8'd2) ? clk_25kHz:
						64'd0;


endmodule
