`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:32:00 11/02/2015 
// Design Name: 
// Module Name:    spi_ctr 
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

//******此模块的写操作针对器件ADF4351，写入32bit数据，
//******读取操作针对器件ads8332（功率检测），读取16bit数据，
//******另外器件ads7884的读取操作与8332一样，所以共用读取操作，
//******暂时不对ads8332、ads7884进行读取操作
//******

module spi_ctr(
input			sys_clk,		//外部输入时钟，为spiclk的2倍
input			rst,			//高复位

//spi控制接口
input			spi_di,
output			spi_clk,
output			spi_do,
output			spi_cs,

//外围需要控制的信号
input	[31:0]	wr_spi_data,	//通过spi写入的数据
input			wr_en,			//高有效，电平有效
input			rd_en,			//高有效
output			update_vld,		//写完数据后的指示信号,一个sys_clk脉冲

output	[15:0]	spi_dout,		//读取到的spi数据
output			dout_vld,		//读到数据后的指示,一个sys_clk脉冲
output	[31:0]	debug_spi
);

parameter		TIME_WR_LTH		=	7'd80,		//写操作时的总计数
				WR_CS_STAT		=	7'd4,		//cs拉低时的起始
				WR_CS_END		=	7'd75,
				WR_CLK_STAT		=	7'd7,
				WR_CLK_END		=	7'd70,
				WR_DATA_STAT	=	7'd2,		//外部写入数据的锁存
				WR_DATA_SLL		=	7'd6,		//开始移位操作点
				
				TIME_RD_LTH		=	7'd35,//7'd40,		//写操作时的总计数
				RD_CS_STAT		=	7'd1,//7'd2,		//cs拉低时的起始
				RD_CS_END		=	7'd34,//7'd37,
				RD_CLK_STAT		=	7'd2,//7'd4,
				RD_CLK_END		=	7'd33;//7'd35;



//写操作情况下，spi输出信号
reg			wr_spi_clk 	=	1'b0;			
reg			wr_spi_do	=	1'b0;
reg			wr_spi_cs	=	1'b1;
reg		wr_update_vld	=	1'b0;	//写完后的指示

//读操作情况下，spi输出信号
reg			rd_spi_clk 	=	1'b0;			
reg			rd_spi_do	=	1'b0;
reg			rd_spi_cs	=	1'b1;
reg	 [15:0]	spi_dout_r	=	16'd0;
reg	 [15:0]	spi_dout_o	=	16'd0;
reg			dout_vld_r	=	1'b0;

reg			wr_stat 	=	1'b0;	//写入过程开始指示
reg			rd_stat 	=	1'b0;	//读取过程开始指示

reg  [6:0]	time_cnt	=	7'd0;
reg  [6:0]	rd_time_cnt	=	7'd0;	//读、写计数分开
reg	 [31:0]	data_in		=	32'd0;


//// 读或者写使能时，分别产生标识
always@(posedge sys_clk or posedge rst)
begin
	if (rst) begin
		wr_stat			<=	1'b0;
		rd_stat			<=	1'b0;
	end
	// else if(time_cnt >= 7'd80) begin
	else if(wr_stat && (time_cnt >= TIME_WR_LTH)) begin
		wr_stat			<=	1'b0;
	end
	else if(rd_stat && (rd_time_cnt >= TIME_RD_LTH)) begin
		rd_stat			<=	1'b0;
	end
	else if(wr_en && !rd_stat)			//不支持同事读。写
		wr_stat			<=	1'b1;
	else if(rd_en && !wr_stat)
		rd_stat			<=	1'b1;
	else begin
		wr_stat			<=	wr_stat;
		rd_stat			<=	rd_stat;
	end
end
//	使能后即开始产生一次写操作的计数,共80次计数
always@(posedge sys_clk or posedge rst) begin
	if (rst) begin
		time_cnt[6:0]	<=	7'd0;
	end
	else if(wr_stat && (time_cnt >= TIME_WR_LTH))
		time_cnt[6:0]	<=	7'd0;
	// else if(rd_stat && (time_cnt >= TIME_RD_LTH))
		// time_cnt[6:0]	<=	7'd0;
	else if(wr_stat) 
		time_cnt[6:0]	<=	time_cnt + 1'b1;
	else
		time_cnt[6:0]	<=	7'd0;
end
//************产生写操作下的spi信号*********************
//	写操作情况下的cs
always@(posedge sys_clk or posedge rst) begin
	if (rst) begin
		wr_spi_cs		<=	1'b1;
	end
	else if((time_cnt[6:0] == WR_CS_STAT))
		wr_spi_cs		<=	1'b0;
	else if((time_cnt[6:0] == WR_CS_END))
		wr_spi_cs		<=	1'b1;
end
//	写操作下的时钟信号
always@(posedge sys_clk or posedge rst) begin
	if (rst) begin
		wr_spi_clk		<=	1'b0;
	end
	else if((time_cnt[6:0] >= WR_CLK_STAT) && (time_cnt[6:0] <= WR_CLK_END)) 
		wr_spi_clk		<=	time_cnt[0];	//相当于wr_spi_clk取反操作
	else
		wr_spi_clk		<=	1'b0;
end
//	写操作下的输出数据信号
reg[5:0]	test_tb = 6'd0;
always@(posedge sys_clk or posedge rst) begin
	if (rst) begin
		wr_spi_do		<=	1'b0;
		data_in			<=	32'd0;
		test_tb[5:0]	<=	6'd0;
	end
	else if(time_cnt[6:0] == WR_DATA_STAT) begin
		data_in[31:0]	<=	wr_spi_data[31:0];
	end
	else if(time_cnt[6:0] >= (WR_CLK_END + 1)) begin
		test_tb[5:0]	<=	6'd0;
		wr_spi_do		<=	1'b0;
	end
	else if((time_cnt[6:0] >= WR_DATA_SLL) && (time_cnt[0] == 1'b0)) begin
		data_in[31:0]	<=	{data_in[30:0],1'b0};
		wr_spi_do		<=	data_in[31];
		test_tb[5:0]	<=	test_tb[5:0] + 1'b1;
	end
	else
		wr_spi_do		<=	wr_spi_do;
end
//	写完后的指示 
always@(posedge sys_clk or posedge rst)	begin
	if (rst) begin
		wr_update_vld	<=	1'b0;
	end
	// else if(time_cnt[6:0] >= 7'd80)
	else if(time_cnt[6:0] >= TIME_WR_LTH)
		wr_update_vld	<=	1'b1;
	else
		wr_update_vld	<=	1'b0;
end

//***********************************************************
//************产生读操作下的spi信号*********************
//读取计数
always@(posedge sys_clk or posedge rst) begin
	if (rst) begin
		rd_time_cnt[6:0]	<=	7'd0;
	end
	else if(rd_stat && (rd_time_cnt >= TIME_RD_LTH))
		rd_time_cnt[6:0]	<=	7'd0;
	else if(rd_stat) 
		rd_time_cnt[6:0]	<=	rd_time_cnt + 1'b1;
	else
		rd_time_cnt[6:0]	<=	7'd0;
end
//	读操作情况下的cs
always@(posedge sys_clk or posedge rst) begin
	if (rst) begin
		rd_spi_cs		<=	1'b1;
	end
	else if(rd_time_cnt[6:0] == RD_CS_STAT) 
		rd_spi_cs		<=	1'b0;
	else if(rd_time_cnt[6:0] == RD_CS_END)
		rd_spi_cs		<=	1'b1;
end
//	读操作下的时钟信号
always@(posedge sys_clk or posedge rst) begin
	if (rst) begin
		rd_spi_clk		<=	1'b1;			//读取时默认为高
	end
	else if((rd_time_cnt[6:0] >= RD_CLK_STAT) && (rd_time_cnt[6:0] <= RD_CLK_END)) 
		rd_spi_clk		<=	rd_time_cnt[0];	//相当于rd_spi_clk取反操作
	else
		rd_spi_clk		<=	1'b1;
end
//	写操作下的输出数据信号
reg[4:0]	test_rd = 5'd0;
always@(posedge sys_clk or posedge rst) begin
	if (rst) begin
		spi_dout_r[15:0]	<=	16'b0;
		spi_dout_o[15:0]	<=	16'b0;
		test_rd				<=	5'd0;
		// dout_vld_r			<=	1'b0;
	end
	else if(rd_time_cnt[6:0] >= RD_CLK_END) begin
		test_rd				<=	5'd0;
		// spi_dout_r[15:0]	<=	spi_dout_r[15:0];
		spi_dout_o[15:0]	<=	{4'd0,spi_dout_r[15:4]};
	end
	else if((rd_time_cnt[6:0] >= RD_CLK_STAT) && (rd_time_cnt[0] == 1'b0)) begin
		spi_dout_r[15:0]	<=	{spi_dout_r[14:0],spi_di};
		test_rd				<=	test_rd + 1'b1;
	end
	else begin	
		spi_dout_r[15:0]	<=	spi_dout_r[15:0];
	end
end
//输出信号标示,在40Mhz下沿3拍，用20Mhz采集此信号
always@(posedge sys_clk or posedge rst) begin
	if (rst) begin
		dout_vld_r			<=	1'b0;
	end
	else if((rd_time_cnt[6:0] >= RD_CLK_END) && (rd_time_cnt[6:0] <= TIME_RD_LTH))
		dout_vld_r			<=	1'b1;
	else  
		dout_vld_r			<=	1'b0;
end

//***********输出选择输出
assign		spi_clk		=		wr_stat		?	wr_spi_clk	: rd_spi_clk;
assign		spi_do		=		wr_stat		?	wr_spi_do	: 1'b0;
assign		spi_cs		=		wr_stat		?	wr_spi_cs	: rd_spi_cs;
assign		update_vld	=		wr_update_vld;
assign		spi_dout[15:0]	=	spi_dout_o[15:0];//已经去掉了低4位
assign		dout_vld	=		dout_vld_r;

//测试信号
assign		debug_spi[0]		=	wr_stat;
assign		debug_spi[1]		=	wr_spi_cs;
assign		debug_spi[2]		=	wr_spi_clk;
assign		debug_spi[3]		=	wr_spi_do;
assign		debug_spi[4]		=	wr_update_vld;
assign		debug_spi[10:5]		=	test_tb[5:0];

assign		debug_spi[11]		=	rd_stat;
assign		debug_spi[12]		=	rd_spi_cs;
assign		debug_spi[13]		=	rd_spi_clk;
assign		debug_spi[14]		=	dout_vld_r;
assign		debug_spi[15]		=	dout_vld_r;
assign		debug_spi[31:16]	=	spi_dout_r[15:0];
endmodule

