`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:31:18 11/02/2015 
// Design Name: 
// Module Name:    rf_ctr 
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

//*此模块流程：接收板1.通过cpld读取mcu上报的状态；
//*************					 读取8332（电压回读）的16bit
//*************2.spi总线2的操作：读取7884（功率回读）
//*此模块控制暂时用UART串口发送的命令进行控制、调试
//*************

module rf_ctr_rv(
input			sys_clk,		//外部输入时钟
input			rst,			//高复位
input			clk_40mhz,
input			time_1s_en,		//定时查询使能
//对于串口模块的控制
input			rv_uart_vld,	//串口输入命令数据标识
input	[63:0]	rv_uart_data,	//串口输入命令数据
output	reg		uart_send_en,	//发送数据使能
output	reg [63:0]	sd_uart_data,	//送出的数据
//缓存CPLD得到的数据
output	reg [63:0]	ad_collect,	//AD8332采集到的数据	
output	reg [15:0]	power_collect,//AD7884采集到的数据,此数据不进行上报	
output	reg [3:0]	rv_pll,

//SPI总线1
input			rfrv_cpld_rxd,	//spi_di_one 
output			rfrv_cpld_txd,  //spi_clk_one
// output			spi_do_one,		
// output			spi_cs_one,     
//SPI总线2
input			spi_di_two,
output			spi_clk_two,
output			spi_cs_two,

output			ini_ctr,		//调试时，发送脉冲用来切换回初始化状态，
								//重新总线1的流程，写PLL1、PLL2、PLL3、PLL4
output          rv_power_att,   //接收板功率衰减使能
                              
output	[84:0]	debug_rf
);

parameter			TIMER_1US_CN		=	25'd20;//1us计数


wire			spi_do_two;
//spi总线1例化信号
reg				wr_en_one	= 1'b0;
reg				ini_8332_en	= 1'b0;
reg				first_wr_8332 = 1'b0;
reg				first_8332_flag = 1'b0;
reg	 [31:0]		wr_spi_one	= 32'd0; 
wire			update_vld_one;
wire			dout_vld_one;
wire [31:0]		spi_dout_one;
reg				ini_ctr_r = 1'b0;		//切换回初始态标志
//串口控制数据
// reg				uart_send_en = 1'b0;	//发送数据使能
// reg	[63:0]		sd_uart_data = 64'd0;	//送出的数据

//spi总线2例化信号
reg				wr_en_two	= 1'b0;
reg				rd_en_two	= 1'b0;
reg	 [31:0]		wr_spi_two	= 32'd0; 
wire			update_vld_two;
wire			dout_vld_two;
wire [15:0]		spi_dout_two;

reg				uart_rd_ctr	=	1'b0;	//用来区分定时读和命令读取，1为命令读取
reg	 [15:0]		power_temp  = 16'h0230;
reg	 [15:0]		power_temp_l  = 16'h01d0;
reg	 [15:0]		power_temp_s  = 16'h0190;
reg  [3:0]		power_cnt	= 4'd0;
reg	 [3:0]		power_rd	= 4'd0;
reg	 [3:0]		power_rd_l	= 4'd0;
reg	 [15:0]		power_rd_r	    = 16'd0;
reg	 [15:0]		power_rd_r_l	= 16'd0;

reg	 [3:0]		att_num1  = 4'h3;
reg	 [3:0]		att_num2  = 4'ha;
reg	 [9:0]		att_num3  = 10'd3;
reg	 [9:0]		att_num4  = 10'd3;
reg	 [9:0]		att_num5  = 10'd416;
reg	 [9:0]		att_num6  = 10'd416;
reg             rv_power_att_r = 1'b0;    //接收板功率衰减使能 1--衰减
reg  [9:0]		rv_att_cnt = 10'd0;		  //采集1000次计数
reg             count_en   = 1'b0;
reg  [9:0]      count_wide = 10'd0;
reg  [15:0]     count_att  = 16'd0;
reg  [15:0]     count_lth  = 16'd594;



reg				ini_restat	= 1'b0;		//总线1初始化起始使能
reg				ini_stat	= 1'b1;		//上电初始计数标识
reg		[4:0]	time_1us_cnt = 5'd0;
reg				time_1us_en	= 1'b1;
reg	 [5:0]		wr_spi_cnt	= 6'd0;
reg	 [3:0]		ini_ctr_cnt	= 4'd0;
reg				wr_state	= 1'b0;		//写进程的标识，为高则再写过程中

wire [31:0]		debug_spi_one;
wire [31:0]		debug_spi_two;

wire			rv_cpld_vld;
wire [127:0]	rv_cpld_data;
reg  [127:0]	rv_cpld_data_r;
reg				rv_send_en;
reg  [127:0]	rv_send_data;

reg [2:0]		dout_vld_two_reg;
reg         pa_att_selec = 1'b0;
reg         pa_att_in;

//FPGA与CPLD之间的串口
uart_top_cpld  rf_uart_top_rv(
				.clk                         (sys_clk      ),
				.rst_n                       (~rst         ),
				.rs232_rx                    (rfrv_cpld_rxd),
				.rs232_tx                    (rfrv_cpld_txd),
				.recieve_data                (rv_cpld_data ),
				.recirve_vld                 (rv_cpld_vld  ),
				.send_en                     (     ),	//rv_send_en
				.send_data                   (     ),   //rv_send_data保持时间要长
				.send_vld                    (   )
				
				);
//目前调试阶段，收到一条指令后发给cpld
always@(posedge sys_clk or posedge rst) begin
	if (rst) begin
		rv_send_en			<=	1'b0;
		rv_send_data[127:0]	<=	64'd0;
	end
	else if(rv_cpld_vld) begin
		rv_send_en			<=	1'b0;
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
	else if(rv_uart_vld && (rv_uart_data[63:0] == 64'h1f00_0000_0000_0002))	
		rv_cpld_data_r[127:0]	<=	128'd0;
	else
		rv_cpld_data_r[127:0]	<=	rv_cpld_data_r[127:0];
end

//spi总线2的例化
	spi_ctr spi_uut2 (
		.sys_clk(clk_40mhz), //sys_clk
		.rst(rst), 
		.spi_di(spi_di_two), 
		.spi_clk(spi_clk_two), 
		.spi_do(spi_do_two), 
		.spi_cs(spi_cs_two), 
		.wr_spi_data(wr_spi_two), 
		.wr_en(wr_en_two), 
		.rd_en(rd_en_two), 
		.update_vld(update_vld_two), 
		.spi_dout(spi_dout_two), 
		.dout_vld(dout_vld_two),
		.debug_spi(debug_spi_two)
	);
	
//取上升沿
always @(posedge sys_clk) begin
	dout_vld_two_reg[2:0]	<=	{dout_vld_two_reg[1:0],dout_vld_two};
end
//***********产生1us的计数器*************************
always@(posedge sys_clk or posedge rst) begin
	if (rst) begin
		time_1us_cnt[4:0]		<=		5'd0;
		time_1us_en				<=		1'b1;
	end
	else if(time_1us_cnt >= TIMER_1US_CN) begin
		time_1us_cnt[4:0]		<=		5'd0;
		time_1us_en				<=		1'b1;
	end
	else begin
		time_1us_cnt[4:0]		<=		time_1us_cnt[4:0] + 1'b1;
		time_1us_en				<=		1'b0;
	end
end
//*****针对spi2的读取操作  7884直接读取
always@(posedge sys_clk or posedge rst) begin
	if (rst) begin
		rd_en_two			<=	1'b0;
	end
	else if(rv_uart_vld && (rv_uart_data[63:0] == 64'h1f00_0000_0000_0003))
		rd_en_two			<=	1'b1;
	else if(time_1us_en)
		rd_en_two			<=	1'b1;		//每一秒使能一次
	else begin
		rd_en_two			<=	1'b0;
	end
end

//*************读取完成后，将得到的数据从串口发送走
always@(posedge sys_clk or posedge rst) begin
	if (rst) begin
		uart_send_en		<=	1'b0;
		sd_uart_data[63:0]	<=	64'd0;
		uart_rd_ctr			<=	1'b0;
	end
	else if(rv_uart_vld && (rv_uart_data[63:0] == 64'h1f00_0000_0000_0003))
		uart_rd_ctr			<=	1'b1;
	else if(rv_uart_vld && (rv_uart_data[63:32] == 32'h1f1d_0000))
		power_temp[15:0]	<=	rv_uart_data[15:0];
	else if(rv_uart_vld && (rv_uart_data[63:32] == 32'h1f1d_0002))
		power_temp_l[15:0]	<=	rv_uart_data[15:0];  
	else if(rv_uart_vld && (rv_uart_data[63:32] == 32'h1f1d_0009))
		power_temp_s[15:0]	<=	rv_uart_data[15:0];  
	else if(rv_uart_vld && (rv_uart_data[63:32] == 32'h1f1d_0005)) begin  
		att_num1[3:0]		<=	rv_uart_data[19:16];
		att_num2[3:0]		<=	rv_uart_data[3:0];
	end
	else if(rv_uart_vld && (rv_uart_data[63:32] == 32'h1f1d_0007)) begin  
		count_lth[15:0]		<=	rv_uart_data[15:0];
	end
	else if(rv_uart_vld && (rv_uart_data[63:32] == 32'h1f1d_0006)) begin
		att_num3[9:0]		<=	rv_uart_data[25:16];
		att_num4[9:0]		<=	rv_uart_data[9:0];
	end
	else if(rv_uart_vld && (rv_uart_data[63:32] == 32'h1f1d_0008)) begin
		att_num5[9:0]		<=	rv_uart_data[25:16];
		att_num6[9:0]		<=	rv_uart_data[9:0];
	end
    // else if(dout_vld_two && uart_rd_ctr) begin
	else if((dout_vld_two_reg[1:0] == 2'b01) && uart_rd_ctr) begin
		uart_send_en		<=	1'b1;
		uart_rd_ctr			<=	1'b0;
		sd_uart_data[63:0]	<=	{48'h1f00_0022_0000,spi_dout_two[15:0]};
	end
		//收到读取命令返给cpu
	else if(rv_uart_vld && (rv_uart_data[63:0] == 64'h1f00_0000_0000_0002))	begin
		uart_send_en		<=	1'b1;
		sd_uart_data[63:0]	<=	rv_cpld_data_r[127:64];
	end
	else if(rv_uart_vld && (rv_uart_data[63:0] == 64'h1f00_0000_0000_001a))	begin
		uart_send_en		<=	1'b1;
		sd_uart_data[63:0]	<=	rv_cpld_data_r[63:0];
	end
        //读出定时数据 电压
	else if(rv_uart_vld && (rv_uart_data[63:0] == 64'h1f00_0000_0000_0005))	begin
		uart_send_en		<=	1'b1;
		sd_uart_data[63:0]	<=	ad_collect[63:0];
	end
	else if(rv_uart_vld && (rv_uart_data[63:0] == 64'h1f00_0000_0000_0006))	begin
		uart_send_en		<=	1'b1;
		sd_uart_data[63:0]	<=	rv_pll[3:0];
	end
	else if(rv_uart_vld && (rv_uart_data[63:32] == 32'h1f1d_0001)) begin
		uart_send_en		<=	1'b1;
		sd_uart_data[63:0]	<=	{48'h1f00_0022_0000,12'd0,power_rd_r[3:0]};
	end
	else if(rv_uart_vld && (rv_uart_data[63:32] == 32'h1f1d_0003)) begin
		uart_send_en		<=	1'b1;
		sd_uart_data[63:0]	<=	{48'h1f00_0022_0000,12'd0,power_rd_r_l[3:0]};//低比较
	end
	else if(rv_uart_vld && (rv_uart_data[63:32] == 32'h1f1d_000a)) begin
		pa_att_selec    		<=	rv_uart_data[16];
		pa_att_in         	<=	rv_uart_data[0];
	end
	else
		uart_send_en		<=	1'b0;
end

//每一秒更新一次内部数据
always@(posedge sys_clk or posedge rst) begin
	if (rst) begin
		// power_collect[15:0]		<=	16'd0;
		ad_collect[63:0]		<=	64'd0;
		rv_pll[3:0]				<=	4'hf;
	end
	// else if(dout_vld_two) begin
	else if(time_1s_en) begin
		// power_collect[15:0]		<=	spi_dout_two[15:0];
		ad_collect[63:0]		<=	rv_cpld_data_r[127:64];		//ad采集数据
		rv_pll[3:0]				<=	rv_cpld_data_r[63:60];
	end
	else begin
		// power_collect[15:0]		<=	power_collect[15:0];
		ad_collect[63:0]		<=	ad_collect[63:0];		//ad采集数据
		rv_pll[3:0]				<=	rv_pll[3:0];
	end
end



//功率判断,功率设置值 power_temp
always@(posedge sys_clk or posedge rst) begin
	if (rst) begin
		power_cnt[3:0]		<=	4'd0;
		power_rd[3:0]		<=	4'd0;
		power_rd_l[3:0]		<=	4'd0;
	end
	else if(power_cnt[3:0] >= 4'd12) begin
		power_cnt[3:0]		<=	4'd0;
		power_rd[3:0]		<=	4'd0;
		power_rd_l[3:0]		<=	4'd0;

	end
	// else if(dout_vld_two) begin
	else if((dout_vld_two_reg[1:0] == 2'b01)) begin
		power_cnt[3:0]		<=	power_cnt[3:0] + 1'b1;
        
        if(count_en) begin
            if(spi_dout_two[15:0] >= power_temp[15:0])
                power_rd[3:0] 	<=	power_rd[3:0] + 1'b1;
            else if(spi_dout_two[15:0] <= power_temp_l[15:0])
                power_rd_l[3:0]   <= power_rd_l[3:0] + 1'b1;
        end
        else begin
            if(spi_dout_two[15:0] >= power_temp_s[15:0])  //判断起始值
                power_rd[3:0] 	<=	power_rd[3:0] + 1'b1; //共用计数变量
        end
	end
end
//采集1000次，求个数700个左右 
always@(posedge sys_clk or posedge rst) begin
	if (rst) begin
		rv_att_cnt		<=	10'd0;
		power_rd_r  [15:0] <=	16'd0;
		power_rd_r_l[15:0] <=	16'd0;
		rv_power_att_r		<=	1'd0;
        count_en        <=  1'b0;
        count_att[15:0] <=  16'd0;
        count_wide[9:0] <=  10'd0;
	end
	else if((count_en) && (count_att[15:0] >= count_lth[15:0])) begin
		rv_att_cnt		<=	10'd0;
		power_rd_r  [15:0] <=	16'd0;
		power_rd_r_l[15:0] <=	16'd0;
        count_att[15:0] <=  16'd0;
        count_en        <=  1'b0;
		
		if(rv_power_att_r && (power_rd_r_l >= att_num6))
			   rv_power_att_r		<=	1'd0;
		else if(!rv_power_att_r && (power_rd_r >= att_num5))
			   rv_power_att_r		<=	1'd1;
		else 
			rv_power_att_r		<=	rv_power_att_r;
		
	end
    else if(count_wide[9:0] >= count_lth[9:0]) begin
        count_wide[9:0]             <=  10'd0;
        rv_power_att_r		        <=	1'd0;
    end
	else if((!count_en) && (rv_att_cnt >= 10'd5)) begin
		rv_att_cnt		            <=	10'd0;
		power_rd_r  [15:0]          <=	16'd0;
		power_rd_r_l[15:0]          <=	16'd0;
        count_att[15:0]             <=  16'd0;
            
        if((power_rd_r >= att_num3)) begin
            count_wide[9:0]         <=  10'd0;
			count_en        		<=	1'd1;
        end
        //没有达到起始门限则不停的计数，计数超过时隙长度，则不衰减
		else  begin
            count_wide[9:0]         <=  count_wide[9:0] + 1'b1; 
            count_en                <=  count_en;
        end
	end
	else if(power_cnt[3:0] >= 4'd12) begin
		rv_att_cnt		<= rv_att_cnt + 1'b1;
        
        if(count_en)    begin 
            count_att[15:0]     <=  count_att[15:0] + 1'b1;
            
            if(power_rd[3:0] >= att_num1)	//高峰 默认为7
                power_rd_r[15:0] <= power_rd_r[15:0] + 1'b1;
            else if(power_rd_l[3:0] >= att_num2)	//高峰 默认为7
                power_rd_r_l[15:0] <= power_rd_r_l[15:0] + 1'b1;
        end
        else begin
            if(power_rd[3:0] >= att_num1)	//高峰 默认为7
                power_rd_r[15:0] <= power_rd_r[15:0] + 1'b1;
        end
	end
	else
		rv_power_att_r		<=	rv_power_att_r;
end

//功率衰减使能
assign rv_power_att       =   pa_att_selec ? pa_att_in : rv_power_att_r;
    
//测试信号 
assign		debug_rf[84:75]	=	count_wide[9:0];
assign		debug_rf[74:71]	=	power_rd[3:0];
assign		debug_rf[70:67]	=	power_rd_l[3:0];
assign		debug_rf[66]	=	count_en;

assign		debug_rf[65:56]	=	power_rd_r[9:0];
assign		debug_rf[55:46]	=	power_rd_r_l[9:0];
assign		debug_rf[45:36]	=	count_att[9:0];
assign		debug_rf[35]	=	rv_power_att_r;


assign		debug_rf[34:31]	=	att_num1[3:0];
assign		debug_rf[30:27]	=	att_num3[3:0];
assign		debug_rf[26:17]	=	att_num5[3:0];
assign		debug_rf[15:0]	=	spi_dout_two[15:0];

endmodule

