`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:00:40 11/02/2015 
// Design Name: 
// Module Name:    t2c_tmp 
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
module digt_i2c_tmp(
// clock & reset
input				sys_clk,		//外部输入时钟,20MHz
input				rst,			//高复位
input				time_1s_en,		//更新操作使能

//对于串口模块的控制
input				rv_uart_vld,	//串口输入命令数据标识
input	[63:0]		rv_uart_data,	//串口输入命令数据
output	reg			i2c_uart_send_en,	//发送数据使能
output	reg [63:0]		i2c_uart_data,	//送出的数据

// I2C interface
output              i2c_scl_out_one,
inout               i2c_sda_out_one,

output              i2c_scl_out_two,
inout               i2c_sda_out_two,

output				i2c_sda_slect,

//上报给DSP的数据,数字版温度
output  reg [15:0]  i2c_tmp_one,
output  reg [15:0]  i2c_tmp_two,

// debug
output[31:0]        debug_signal
    );

	
parameter	I2C_WR_LENTH	=	6'd1,
			I2C_WR_CONFIG	=	16'h0160;
parameter     TIMER_3S_CNT  =   4'd3;   //3S

//串口控制数据
//reg				i2c_uart_send_en = 1'b0;	//发送数据使能
//reg	[63:0]		i2c_uart_data = 64'd0;	//送出的数据
			
wire		i2c_rd_valid;
wire[15:0]	i2c_reg_out_one;            //数字板1号温度传感器
wire[15:0]	i2c_reg_out_two;
reg			i2c_eprom		=	1'b0;
reg			i2c_ini_stat	=	1'b1;	//初始化状态
reg			i2c_scl_in		=	1'b0;
reg	[9:0]	i2c_20k_cnt		=	10'd0;
reg [5:0]	i2c_wr_cnt		=	6'd0;	//进行写操作的个数
reg [2:0]	i2c_valid_reg	=	3'd0;
reg [3:0]   time_cnt = 4'd0;

//控制i2c接口的输入
reg			i2c_wr_rd		=	1'b0;	//默认为写状态
reg			i2c_wp_enable	=	1'b0;	//不使能
reg			wait_scl_clk	=	1'b0;	//延长长度
reg	[2:0]	wait_clk_cnt	=	3'd0;	//延长scl_clk个数计数
reg	[2:0]	i2c_ready_reg	=	3'd0;	//采集上升沿
reg [31:0]  i2c_reg_in		=	32'd0;	//写入的数据
reg			wr_state	= 1'b0;		//写进程的标识，为高则再写过程中
reg			uart_rd_ctr		=	1'b0;	//用来区分定时读和命令读取，1为命令读取

//分频20k的时钟
always@(posedge sys_clk or posedge rst) begin
	if (rst) begin
		i2c_20k_cnt[9:0]		<=	10'd0;
		i2c_scl_in				<=	1'b0;
	end
	else if(i2c_20k_cnt[9:0] >= 10'd100)	begin		//100
		i2c_20k_cnt[9:0]		<=	10'd0;
		i2c_scl_in				<=	~i2c_scl_in;
	end
	else begin
		i2c_20k_cnt[9:0]		<=	i2c_20k_cnt[9:0] + 1'b1;
		i2c_scl_in				<=	i2c_scl_in;
	end
end
	
	digt_I2C_WRRD uut (
		.i2c_scl_in(i2c_scl_in), 
		.i2c_rst_in(rst), 
		.i2c_eprom(1'b0), 
		.i2c_wr_rd(i2c_wr_rd), 
		.i2c_wp_enable(i2c_wp_enable), 
		.i2c_reg_in(i2c_reg_in), 
		.i2c_reg_out_one(i2c_reg_out_one), 
		.i2c_reg_out_two(i2c_reg_out_two), 
		.i2c_rd_valid(i2c_rd_valid), 
		.i2c_scl_out_one(i2c_scl_out_one), 
		.i2c_scl_out_two(i2c_scl_out_two), 
		.i2c_sda_out_one(i2c_sda_out_one), 
		.i2c_sda_out_two(i2c_sda_out_two), 
		.i2c_sda_slect(i2c_sda_slect), 
		.i2c_ready(i2c_ready), 
		.debug_signal(debug_signal)
	);
	
	
always@(posedge sys_clk) begin
		i2c_ready_reg[2:0]		<=	{i2c_ready_reg[1:0],i2c_ready};
		i2c_valid_reg[2:0]		<=	{i2c_valid_reg[1:0],i2c_rd_valid};
end
	
//3s计数器
always@(posedge sys_clk or posedge rst) begin
	if (rst) begin
		time_cnt[3:0]	<=	4'd0;
	end
	else if(time_cnt[3:0] == TIMER_3S_CNT) begin
        time_cnt[3:0]	<=	time_cnt[3:0] + 1'b1;
	end
    else if(time_1s_en && (time_cnt[3:0] < TIMER_3S_CNT))begin
		time_cnt[3:0]	<=	time_cnt[3:0] + 1'b1;
    end
    else
        time_cnt[3:0]	<=	time_cnt[3:0];
end

    
//i2c接口的写操作
always@(posedge sys_clk or posedge rst) begin
	if (rst) begin
		i2c_wr_rd				<=	1'b0;
		i2c_wp_enable			<=	1'b0;
		wait_scl_clk			<=	1'b0;
	end
    //开机后3s，软件写入温度初始值
    else if(time_cnt[3:0] == TIMER_3S_CNT) begin
		i2c_ini_stat			<=	1'b1;		//初始写一次
    end
	else if(rv_uart_vld && (rv_uart_data[63:0] == 64'h1e00_0000_0000_0002)) begin
		i2c_ini_stat			<=	1'b1;		//初始写一次
	end
	else if(i2c_ini_stat ) begin
		i2c_wr_rd				<=	1'b0;
		i2c_reg_in[31:0] 		<=	{16'h0101,I2C_WR_CONFIG};
		wait_scl_clk			<=	1'b1;		//启动延时
		i2c_wp_enable			<=	1'b1;
		i2c_ini_stat			<=	1'b0;
	end
	//**********************************随机一次写操作，低16位即配置写的数据
	else if(rv_uart_vld && (rv_uart_data[63:32] == 32'h1d00_0001)) begin
		i2c_wr_rd				<=	1'b0;
		i2c_wp_enable			<=	1'b1;
		wait_scl_clk			<=	1'b1;		//启动延时
		i2c_reg_in[31:0] 		<=	rv_uart_data[31:0];
	end
	//************************************          **随机读取操作
	else if(rv_uart_vld && (rv_uart_data[63:32] == 32'h1d01_0001)) begin
		i2c_wr_rd				<=	1'b1;
		i2c_wp_enable			<=	1'b1;
		wait_scl_clk			<=	1'b1;		//启动延时
		i2c_reg_in[31:0] 		<=	rv_uart_data[31:0];
	end
	//定时读取
	else if(time_1s_en ) begin	//读取温度值
		i2c_wr_rd				<=	1'b1;
		i2c_wp_enable			<=	1'b1;
		wait_scl_clk			<=	1'b1;		//启动延时
		i2c_reg_in[31:0] 		<=	32'd0;		//温度读取0x00地址
	end
	else if((wait_clk_cnt[2:0] >= 3'd5))begin
		// i2c_wr_rd				<=	1'b0;
		i2c_wp_enable			<=	1'b0;
		wait_scl_clk			<=	1'b0;
	end
	else begin
		i2c_wr_rd				<=	i2c_wr_rd;
		i2c_wp_enable			<=	i2c_wp_enable;
	end
end
/////延时控制i2c接口的信号标识
always@(posedge i2c_scl_in or posedge rst) begin
	if (rst) begin
		wait_clk_cnt[2:0]		<=	3'd0;
	end
	else if(wait_clk_cnt[2:0] >= 3'd5)
		wait_clk_cnt[2:0]		<=	3'd0;
	else if(wait_scl_clk)
		wait_clk_cnt[2:0]		<=	wait_clk_cnt[2:0] + 1'b1;
	else
		wait_clk_cnt[2:0]		<=	wait_clk_cnt[2:0];
end		
//******************************************************************
//*************I@C读取操作*******************************
//读取   c0 1d01 0001 0000 0000 cf  得到的值乘以 精度 0.0625 如 2f6 * 0.0625

//写入   c0 1d00 0001 0101 6060 cf


always@(posedge sys_clk or posedge rst) begin
	if (rst) begin
		i2c_uart_send_en		<=	1'b0;
		i2c_uart_data[63:0]		<=	64'd0;
        uart_rd_ctr				<=	1'b0;
	end
	else if(rv_uart_vld && (rv_uart_data[63:32] == 32'h1d01_0001)) begin
		uart_rd_ctr				<=	1'b1;
	end
	else if(uart_rd_ctr && (i2c_valid_reg[2:1] == 2'b01)) begin
		uart_rd_ctr				<=	1'b0;
                i2c_uart_send_en		<=	1'b1;
		i2c_uart_data[63:0]		<=	{32'h1d01_aaaa,i2c_reg_out_two[15:0],i2c_reg_out_one[15:0]};
	end
	else
		i2c_uart_send_en		<=	1'b0;
end

//每一秒更新一次内部数据
always@(posedge sys_clk or posedge rst) begin
	if (rst) begin
		i2c_tmp_one[15:0]		<=	16'd0;
		i2c_tmp_two[15:0]		<=	16'd0;
	end
	else if((i2c_valid_reg[2:1] == 2'b01)) begin
		i2c_tmp_one[15:0]		<=	i2c_reg_out_one[15:0];
		i2c_tmp_two[15:0]		<=	i2c_reg_out_two[15:0];
	end
	else begin
		i2c_tmp_one[15:0]		<=	i2c_tmp_one[15:0];
		i2c_tmp_two[15:0]		<=	i2c_tmp_two[15:0];
	end
end

endmodule
