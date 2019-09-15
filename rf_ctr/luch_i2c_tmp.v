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
module luch_i2c_tmp(
// clock & reset
input				sys_clk,		//外部输入时钟,20MHz
input				rst,			//高复位
input				time_1s_en,
//输出数据缓存
output	reg [15:0]	lunch_i2c_data,	//送出的数据
output	reg [63:0]	lunch_ad_collect,
output	reg [3:0]	lunch_pll,

//对于串口模块的控制
input				rv_uart_vld,	//串口输入命令数据标识
input	[63:0]		rv_uart_data,	//串口输入命令数据
output	reg			i2c_uart_send_en,	//发送数据使能
output	reg[63:0]	i2c_uart_data,	//送出的数据

input   [7:0]       pa_temp_collect,    //采集的功放的温度值

// I2C interface
output              i2c_scl_out,
inout               i2c_sda_out,
output				i2c_sda_slect,
output				i2c_tmp_e2p_en,	//温度和e2prom选择，1--e2prom
// output              i2c_ready,                             // I2C 空闲标识，高为空闲态
//与MCU见得uart接口
input				rfrv_cpld_rxd,
output				rfrv_cpld_txd,
output reg  [7:0]   power_wr_adr,
output reg  [7:0]   power_wr_data,
output reg  [1:0]     choose_temp,

output      [3:0]	lunch_att_io,

// debug
output[74:0]        debug_signal


    );

	
parameter	I2C_WR_LENTH	=	6'd1,
			I2C_WR_CONFIG	=	16'h0160;
parameter     TIMER_3S_CNT  =   4'd3;   //3S

//串口控制数据
// reg				i2c_uart_send_en = 1'b0;	//发送数据使能
// reg	[63:0]		i2c_uart_data = 64'd0;	//送出的数据
			
wire		i2c_rd_valid;
wire[15:0]	i2c_reg_out;
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
reg				wr_state	= 1'b0;		//写进程的标识，为高则再写过程中

reg			uart_rd_ctr		=	1'b0;	//用来区分定时读和命令读取，1为命令读取
//***************与MCU间的UART控制*****************
//FPGA与CPLD之间的串口
wire			rv_cpld_vld;
wire [127:0]	rv_cpld_data;
reg  [127:0]	rv_cpld_data_r;
reg				rv_send_en;
reg  [127:0]	rv_send_data;

reg			i2c_select		 =	 1'b0;	//为高时，写e2prom
wire [3:0]	lunch_att_io_r ;
reg  [3:0]	lunch_att_io_r0  =   4'h1111;
reg  [3:0]	lunch_att_io_r1  =   4'h1111;
reg  [3:0]	lunch_att_io_r2  =   4'h1111;
reg  [3:0]	lunch_att_io_r3  =   4'h1111;

reg  [7:0]     temp_byte_0;
reg  [7:0]     temp_byte_1;
reg  [7:0]     temp_byte_2;

reg  [22:0]    sum_temp;
reg  [5:0]     temp_cnt;
reg  [7:0]     pa_temp_rl;
wire [7:0]     pa_temp_o;
reg            temp_sel_r = 1'b0;

uart_top_cpld  rf_uart_top_sd(
				.clk                         (sys_clk        ),
				.rst_n                       (~rst        ),
				.rs232_rx                    (rfrv_cpld_rxd),
				.rs232_tx                    (rfrv_cpld_txd),
				.recieve_data                (rv_cpld_data       ),
				.recirve_vld                 (rv_cpld_vld  ),
				.send_en                     (rv_send_en   ),
				.send_data                   (rv_send_data     ),    //保持时间要长
				.send_vld                    (   )
				
				);
//目前调试阶段，收到一条指令后发给cpld
always@(posedge sys_clk or posedge rst) begin
	if (rst) begin
		rv_send_en			<=	1'b0;
		rv_send_data[127:0]	<=	64'd0;
	end
	else if(rv_cpld_vld) begin
		rv_send_en			<=	1'b1;
		rv_send_data[127:0]	<=	rv_cpld_data[127:0];
	end
	else 
		rv_send_en			<=	1'b0;
end
//缓存cpld来的控制数据
always@(posedge sys_clk or posedge rst) begin
	if (rst) begin
		rv_cpld_data_r[127:0]	<=	128'd0;
	end
	else if(rv_cpld_vld) 
		rv_cpld_data_r[127:0]	<=	rv_cpld_data[127:0];
		//有读取命令后清空缓存
	else if(rv_uart_vld && (rv_uart_data[63:0] == 64'h1f11_0000_0000_0002))	
		rv_cpld_data_r[127:0]	<=	128'd0;
	else
		rv_cpld_data_r[127:0]	<=	rv_cpld_data_r[127:0];
end



reg         conf_pa_en      =   1'b0;   //初始读pa门限值使能
reg [7:0]   conf_pa_cnt     =   8'd0;   //读取门限个数       


//*************************************************

//分频20k的时钟
always@(posedge sys_clk or posedge rst) begin
	if (rst) begin
		i2c_20k_cnt[9:0]		<=	10'd0;
		i2c_scl_in				<=	1'b0;
	end
	else if(i2c_20k_cnt[9:0] >= 10'd100)	begin		//50
		i2c_20k_cnt[9:0]		<=	10'd0;
		i2c_scl_in				<=	~i2c_scl_in;
	end
	else begin
		i2c_20k_cnt[9:0]		<=	i2c_20k_cnt[9:0] + 1'b1;
		i2c_scl_in				<=	i2c_scl_in;
	end
end
	
	I2C_temp_e2prom uut (
		.i2c_scl_in(i2c_scl_in), 
		.i2c_rst_in(rst), 
		.i2c_eprom(i2c_eprom), 
		.i2c_wr_rd(i2c_wr_rd), 
		.i2c_wp_enable(i2c_wp_enable), 
		.i2c_reg_in(i2c_reg_in), 
		.i2c_reg_out(i2c_reg_out), 
		.i2c_rd_valid(i2c_rd_valid), 
		.i2c_scl_out(i2c_scl_out), 
		.i2c_sda_out(i2c_sda_out), 
		.i2c_sda_slect(i2c_sda_slect), 
		.i2c_ready(i2c_ready), 
		.debug_signal()
	);
	
assign	i2c_tmp_e2p_en		=	i2c_eprom;
	
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
		i2c_eprom				<=	1'b0;
		i2c_select				<=	1'b0;
        conf_pa_en              <=  1'b0;
        conf_pa_cnt[7:0]        <=  8'd0;
	end
    //开机后3s，软件写入温度初始值
    else if(time_cnt[3:0] == TIMER_3S_CNT) begin
		i2c_ini_stat			<=	1'b1;		//初始写一次
    end
	else if(rv_uart_vld && (rv_uart_data[63:0] == 64'h1e2f_0000_0000_0001)) begin
		i2c_eprom				<=	1'b1;
		i2c_select				<=	1'b1;
	end
	else if(rv_uart_vld && (rv_uart_data[63:0] == 64'hed2f_0000_0000_0000)) begin
		i2c_eprom				<=	1'b0;
		i2c_select				<=	1'b0;
	end
	else if(rv_uart_vld && (rv_uart_data[63:0] == 64'h1f00_0000_0000_0001)) begin
		i2c_ini_stat			<=	1'b1;		//初始写一次
	end
	else if(i2c_ini_stat ) begin
		i2c_wr_rd				<=	1'b0;
		i2c_reg_in[31:0] 		<=	{16'h0101,I2C_WR_CONFIG};
		wait_scl_clk			<=	1'b1;		//启动延时
		i2c_wp_enable			<=	1'b1;
        i2c_eprom				<=	1'b0;
		i2c_ini_stat			<=	1'b0;
        conf_pa_en              <=  1'b1;
        conf_pa_cnt[7:0]        <=  8'd0;
	end
    //写完了关于温度传感器精度配置
	// else if(conf_pa_en && (i2c_ready_reg[2:1] == 2'b01) && (conf_pa_cnt[7:0] == 52)) begin
	else if(conf_pa_en && (i2c_ready_reg[2:1] == 2'b01) && (conf_pa_cnt[7:0] == 58)) begin
        conf_pa_en              <=  1'b0;
        // i2c_eprom				<=	1'b0;         //读取e2prom
        conf_pa_cnt[7:0]        <=  8'd0;
	end
	// else if(conf_pa_en && (i2c_ready_reg[2:1] == 2'b01) && (conf_pa_cnt[7:0] <= 51)) begin
	else if(conf_pa_en && (i2c_ready_reg[2:1] == 2'b01) && (conf_pa_cnt[7:0] <= 57)) begin
		i2c_wr_rd				<=	1'b1;
		i2c_wp_enable			<=	1'b1;
		wait_scl_clk			<=	1'b1;		  //启动延时
        
		i2c_reg_in[31:16] 		<=	conf_pa_cnt[7:0]; //地址4づϹ应高值h_byte、l_byte   
        
        // case(conf_pa_cnt[3:0])
           // 4'd0 :  i2c_reg_in[31:0] 		<=	32'h00040000;
           // 4'd1 :  i2c_reg_in[31:0] 		<=	32'h00050000;
           // 4'd2 :  i2c_reg_in[31:0] 		<=	32'h00060000;
           // 4'd3 :  i2c_reg_in[31:0] 		<=	32'h00070000;
           // 4'd4 :  i2c_reg_in[31:0] 		<=	32'h00080000;
           // 4'd5 :  i2c_reg_in[31:0] 		<=	32'h00090000;
           // 4'd6 :  i2c_reg_in[31:0] 		<=	32'h000a0000;
        // default :  i2c_reg_in[31:0] 		<=	32'h00080000;
        // endcase 

        i2c_eprom				<=	1'b1;         //读取e2prom
        conf_pa_cnt[7:0]        <=  conf_pa_cnt[7:0] + 1'b1;
	end
	//**********************************随机一次写操作，低16位即配置写的数据
	else if(rv_uart_vld && (rv_uart_data[63:32] == 32'h1e00_0000)) begin
		i2c_wr_rd				<=	1'b0;
		i2c_wp_enable			<=	1'b1;
		wait_scl_clk			<=	1'b1;		//启动延时
		i2c_reg_in[31:0] 		<=	rv_uart_data[31:0];
	end
	//************************************          **随机读取操作
	else if(rv_uart_vld && (rv_uart_data[63:32] == 32'h1e01_0000)) begin
		i2c_wr_rd				<=	1'b1;
		i2c_wp_enable			<=	1'b1;
		wait_scl_clk			<=	1'b1;		//启动延时
		i2c_reg_in[31:0] 		<=	rv_uart_data[31:0];
	end
	//定时读取
	else if(time_1s_en && (!i2c_select) && (!conf_pa_en) && (time_cnt[3:0] >= TIMER_3S_CNT)) begin		//读取温度值
		i2c_eprom				<=	1'b0;
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
always@(posedge sys_clk or posedge rst) begin
	if (rst) begin
		i2c_uart_send_en		<=	1'b0;
		i2c_uart_data[63:0]		<=	64'd0;
		uart_rd_ctr				<=	1'b0;
	end
	else if(rv_uart_vld && (rv_uart_data[63:32] == 32'h1e01_0000))
		uart_rd_ctr				<=	1'b1;
	else if(uart_rd_ctr && (i2c_valid_reg[2:1] == 2'b01)) begin
		uart_rd_ctr				<=	1'b0;
		i2c_uart_send_en		<=	1'b1;
		i2c_uart_data[63:0]		<=	{48'h1e01_0000_0011,i2c_reg_out[15:0]};
	end
		//收到读取命令返给cpu
	else if(rv_uart_vld && (rv_uart_data[63:0] == 64'h1f11_0000_0000_0002))	begin
		i2c_uart_send_en		<=	1'b1;
		i2c_uart_data[63:0]	        <=	rv_cpld_data_r[127:64];
	end
		//收到读取命令返给cpu
	else if(rv_uart_vld && (rv_uart_data[63:0] == 64'h1f11_0000_0000_002a))	begin
		i2c_uart_send_en		<=	1'b1;
		i2c_uart_data[63:0]	        <=	rv_cpld_data_r[63:0];
	end
	else if(rv_uart_vld && (rv_uart_data[63:0] == 64'h1f11_0000_1234_0001))	begin
		i2c_uart_send_en		<=	1'b1;
		i2c_uart_data[63:0]	        <=	lunch_ad_collect[63:0];
	end
	else if(rv_uart_vld && (rv_uart_data[63:0] == 64'h1f11_0000_1234_0002))	begin
		i2c_uart_send_en		<=	1'b1;
		i2c_uart_data[63:0]	        <=	{48'h1e01_3412_0011,lunch_i2c_data[15:0]};
	end
	else if(rv_uart_vld && (rv_uart_data[63:0] == 64'h1f11_0000_1234_0003))	begin
		i2c_uart_send_en		<=	1'b1;
		i2c_uart_data[63:0]	        <=	{48'h1e01_3412_0011,12'd0,lunch_pll[3:0]};
	end
	else if(rv_uart_vld && (rv_uart_data[63:0] == 64'h1f11_0000_1234_0004))	begin
		i2c_uart_send_en		<=	1'b1;
		i2c_uart_data[63:0]	        <=	{40'h1e01_3412_00,lunch_att_io_r0,lunch_att_io_r1,lunch_att_io_r2,lunch_att_io_r3,lunch_att_io_r[3:0]};
	end
	else if(rv_uart_vld && (rv_uart_data[63:0] == 64'h1f11_0000_1234_0005))	begin
		i2c_uart_send_en		<=	1'b1;
		i2c_uart_data[63:0]	        <=	{48'h1e01_aaaa_0011,6'd0,choose_temp[1:0],pa_temp_rl[7:0]};
	end
	else if(rv_uart_vld && (rv_uart_data[63:0] == 64'h1f11_0000_1234_0006))	begin
		i2c_uart_send_en		<=	1'b1;
		i2c_uart_data[63:0]	        <=	{40'h1e01_aaaa_00,temp_byte_0[7:0],temp_byte_1[7:0],temp_byte_2[7:0]};
	end
	else if(rv_uart_vld && (rv_uart_data[63:8] == 64'h1f11_0000_1234_ad))	begin  
		temp_sel_r          		<=	rv_uart_data[0];
	end
	else if((i2c_eprom) && (i2c_valid_reg[1:0] == 2'b01)) begin
		i2c_uart_send_en		<=	1'b1;
		i2c_uart_data[63:0]		<=	{48'h1d03_0000,i2c_reg_in[31:16],i2c_reg_out[15:0]};
    end
	else
		i2c_uart_send_en		<=	1'b0;
end

//每一秒更新一次内部数据
always@(posedge sys_clk or posedge rst) begin
	if (rst) begin
		lunch_i2c_data[15:0]	<=	16'd0;
		lunch_ad_collect[63:0]	<= 	64'd0;
        temp_byte_0             <=  8'd20;
        temp_byte_1             <=  8'd50;
        temp_byte_2             <=  8'd70;
	end
	else if((!i2c_eprom) && (i2c_valid_reg[2:1] == 2'b01)) begin
		lunch_i2c_data[15:0]	<=	i2c_reg_out[15:0];
		lunch_ad_collect[63:0]	<= 	rv_cpld_data_r[127:64];
		lunch_pll[3:0]			<= 	rv_cpld_data_r[63:60];
		
	end
	else if((i2c_eprom) && (i2c_valid_reg[1:0] == 2'b01)) begin
        power_wr_adr[7:0]   <=  i2c_reg_in[31:16];
        
        if(i2c_reg_out[7:0] == 8'hff) begin
            //衰减增益值
		    if((i2c_reg_in[31:16] >= 16'd51) && (i2c_reg_in[31:16] <= 16'd57)) begin
                case(i2c_reg_in[31:16])
                  16'd51  : lunch_att_io_r0 <= 4'hf;
                  16'd52  : lunch_att_io_r1 <= 4'hf;
                  16'd53  : lunch_att_io_r2 <= 4'hf;
                  16'd54  : lunch_att_io_r3 <= 4'hf;
                  16'd55  : temp_byte_0     <= 8'd20;
                  16'd56  : temp_byte_1     <= 8'd50;
                  16'd57  : temp_byte_2     <= 8'd70;
                  default : ;
                endcase
            end
            else
				power_wr_data[7:0]   <=  8'd0;
	    end
        else begin
		    // if(i2c_reg_in[31:16] == 16'd51)
		    if((i2c_reg_in[31:16] >= 16'd51) && (i2c_reg_in[31:16] <= 16'd57)) begin
                case(i2c_reg_in[31:16])
                  16'd51  : lunch_att_io_r0 <= i2c_reg_out[3:0];
                  16'd52  : lunch_att_io_r1 <= i2c_reg_out[3:0];
                  16'd53  : lunch_att_io_r2 <= i2c_reg_out[3:0];
                  16'd54  : lunch_att_io_r3 <= i2c_reg_out[3:0];
                  16'd55  : temp_byte_0     <= i2c_reg_out[7:0];
                  16'd56  : temp_byte_1     <= i2c_reg_out[7:0];
                  16'd57  : temp_byte_2     <= i2c_reg_out[7:0];
                  default : ;
                endcase
            end
		    else
				power_wr_data[7:0]   <=  i2c_reg_out[7:0];
        end
	end
	else begin
		lunch_i2c_data[15:0]	<=	lunch_i2c_data[15:0];
		lunch_ad_collect[63:0]	<= 	lunch_ad_collect[63:0];
	end
end

// assign  lunch_att_io_r[3:0]   =   (choose_temp[1:0] == 2'd0)  ?    lunch_att_io_r0  :
                                  // (choose_temp[1:0] == 2'd1)  ?    lunch_att_io_r1  :
                                  // (choose_temp[1:0] == 2'd2)  ?    lunch_att_io_r2  :
                                  // (choose_temp[1:0] == 2'd3)  ?    lunch_att_io_r3  :   lunch_att_io_r2;
assign  lunch_att_io_r[3:0]   =   lunch_att_io_r0  ;

                                  
                                  
//根据功放输入的温度，来进行不同的通道、系数的选择 
always@(posedge sys_clk or posedge rst) begin
	if (rst) begin
		sum_temp[22:0]	        <=	23'd0;
		temp_cnt[5:0]	        <= 	6'd0;
        pa_temp_rl[7:0]         <=  8'd30;
	end
    else if(temp_cnt[5:0] >= 6'd16) begin
        sum_temp[22:0]	        <=	23'd0;
        temp_cnt[5:0]	        <= 	6'd0;
        pa_temp_rl[7:0]         <=  sum_temp[11:4];   //sum = tmp*16; out = sum / 16
    end
    else if(time_1s_en && (pa_temp_collect[7:0] != 8'd0)) begin
        temp_cnt[5:0]	        <= 	temp_cnt[5:0]  + 1'b1;
        sum_temp[22:0]	        <=	sum_temp[22:0] + pa_temp_collect[7:0];
    end
end


assign  pa_temp_o   =   temp_sel_r  ?  pa_temp_collect  : pa_temp_rl;

//根据16个数的平均值，来进行通道、系数选择 0--正常系数 1--低值系数 2--高值系数
always@(posedge sys_clk or posedge rst) begin
	if (rst) begin
		choose_temp[1:0]	    <=	2'd2;
	end
    else if(pa_temp_o[7:0] < temp_byte_0[7:0])
        choose_temp[1:0]	    <=	2'd0;
    else if((pa_temp_o[7:0] >= temp_byte_0[7:0]) && (pa_temp_o[7:0] < temp_byte_1[7:0]))
        choose_temp[1:0]	    <=	2'd1;
    else if((pa_temp_o[7:0] >= temp_byte_1[7:0]) && (pa_temp_o[7:0] < temp_byte_2[7:0]))
        choose_temp[1:0]	    <=	2'd2;
    else if(pa_temp_o[7:0] >= temp_byte_2[7:0])
        choose_temp[1:0]	    <=	2'd3;
    else
        ;
end

assign		lunch_att_io[3:0]	=	lunch_att_io_r[3:0];
//测试信号
assign		debug_signal[64]	=	rv_cpld_vld;
assign		debug_signal[70:65]	=	i2c_uart_data[5:0];
assign		debug_signal[71]	=	rv_send_en;
assign		debug_signal[72]	=	rv_cpld_data_r[127];
assign		debug_signal[73]	=	rv_cpld_data_r[126];
assign		debug_signal[74]	=	i2c_uart_send_en;
            
assign		debug_signal[63:0]	=	rv_cpld_data_r[63:0];

endmodule
