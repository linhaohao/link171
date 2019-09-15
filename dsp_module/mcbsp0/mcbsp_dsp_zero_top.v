`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 		YanFei
// 
// Create Date:    09:12:33 09/30/2015 
// Design Name: 
// Module Name:    mcbsp_dsp_zero_top 
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
module mcbsp_dsp_zero_top(
//// clock interface ////                                         
input               mcbsp_clk_in,           // 20mhz   2015/9/9 10:53:16   发用上沿，收用下沿。
input               mcbsp_rst_in,           // 高复位
input				port_clk_10mhz,			//10mhz 接口模块时钟                                           
//// MCBSP port ////
input               mcbsp_slaver_clkx,	 	//DSP给的随路时钟
input               mcbsp_slaver_mosi, 		//DSP给进FPGA的
input               mcbsp_slaver_fsx,	 
	
//FPGA送给DSP的MCBSP接口
output              mcbsp_master_clkr,	 
output              mcbsp_master_fsr,	 
output              mcbsp_master_miso,	

// input[8:0]          rx_slot_data_length,	//发送32bit数据的个数

output	[3:0]		rev_work_mode,	//工作模式
output				work_mode_vld,  //工作模式使能
//读取硬件状态需要的信号
output  port_red_stat,				//硬件状态读取使能
input	port_data_valid,			//接口给数据前的使能
input	[31:0]	port_red_data,

output              port_wr_en,     //数据有效使能。                                          
output [31:0]       port_wr_data,   //解析DSP原语后，截获 “配置”、“数据”，在10mhz下持续传输。
//dsp给的控制信号
output   reg        dsp_ctr_uart_en,
output   reg [63:0] dsp_ctr_uart_data,
//// debug ////
output[127:0]       debug_signal
    );
	
//预留配置信息，本模块暂时不输出
wire	[31:0]		rev_HwConfig;			//配置参数
wire	[31:0]		rev_HwPara;				//配置数据
// wire				wr_rd_en;				//配置数据，保持一个时钟的标识

wire              	rx_ram_addr_upd;

wire 	[31:0] 		HwPara_port;	//10mhz速率，送给接口模块
wire  	[31:0] 		HwConfig_port;	//10mhz速率

reg              	port_wr_en_r = 1'b0;      	//数据有效使能。
reg				 	port_wr_next = 1'b0;
reg 	[31:0]    	port_wr_data_r;				//配置信息更新时发给接口模块
//fpga接受
wire	[31:0]      dsp_tx_data;		//fpga接受到的数据，直到下次更新
wire              	tx_vaild_out;		//接受标识，上升沿采集数据
//// fpga发送
wire	[31:0]      dsp_rx_dina;
reg 	[1:0] 		tx_vaild_en_reg = 2'd0;
reg					tx_vaild_en = 1'b0;
reg 	[3:0]		rieve_cnt = 4'd0;
reg					command_work_en = 1'b0;
reg					command_valid_en = 1'b0;
reg					command_start_en = 1'b0;
reg 	[31:0]		rev_HwConfig_r = 32'd0;	//配置参数
reg 	[31:0]		rev_HwConfig_out = 32'd0;	//配置参数
reg					wr_rd_en_flag = 1'b0;		//读、写操作使能
reg 	[31:0]		rev_HwConfig_port = 32'd0;	//配置参数
reg 	[31:0]		rev_HwPara_r = 32'd0;	//配置数据
reg 	[31:0]		rev_HwPara_out = 32'd0;	//配置数据
reg 	[31:0]		rev_HwPara_port = 32'd0;	//配置数据
reg 	[3:0]		rev_work_mode_r = 4'd0;	//起始的工作模式，需要确定;0为初始，正常工作状态
reg 	[3:0]		rev_work_mode_out = 4'd0;	//起始的工作模式，需要确定;0为初始，正常工作状态
reg 	[3:0] 		rev_work_mode_d1,rev_work_mode_d2;
reg 	[2:0]		rev_vld_cnt = 3'd0;
reg					rev_fpga_en = 1'b0;		//FPGA时钟接受mcbsp信号的使能，多个周期
reg					pa_fpga_en = 1'b0;		//FPGA时钟接受mcbsp信号的使能，多个周期
reg		[2:0]   	port_vld_cnt = 3'd0;  
reg 				port_fpga_en = 1'b0;
reg					port_rd_flag = 1'b0;
reg		[3:0]		rev_fpga_en_flag=4'd0;
reg		[3:0]		pa_fpga_en_flag=4'd0;
reg		[3:0]		rev_fpga_en_port=4'd0;
reg 				round_wr_en = 1'b0;
reg 	[31:0]		rev_HwPara_d2=32'd0,rev_HwPara_d1=32'd0;
reg 	[31:0] 		rev_HwConfig_d2=32'd0,rev_HwConfig_d1=32'd0;
reg 	[2:0]		rx_ram_addr_upd_r = 3'd0;
reg 				round_interrupt = 1'b0;
reg 	[3:0] 		rx_int_cnt = 4'd0;	//产生接受中断高电平时间
reg 				wr_rd_flag = 1'b0;
reg 				pa_wr_rd_flag = 1'b0;
reg 				wr_rd_flag_d1 = 1'b0,wr_rd_flag_d2 = 1'b0;
reg 				pa_flag_d1 = 1'b0,pa_flag_d2 = 1'b0;
reg 	[3:0]		wr_rd_cnt = 4'd0;
reg 	[5:0]		hard_start_r = 6'd0;
reg 				hard_wr_first = 1'b0;

reg					hard_cs_en_r = 1'b0;	//高使能外部读取硬件状态
reg 	[3:0]		hard_cs_cnt  = 4'd0;
reg 	[3:0]		hard_cs_en_reg	=	4'd0;
reg					hard_cs_out		=	1'b0;
reg 				hard_wea		= 	1'b0;
reg 				[7:0] hard_wr_addr 	= 	8'd0;
reg 				[31:0] hard_data 	= 	32'd0;
reg 				round_wea		= 	1'b0;
reg 				[7:0] round_wr_addr = 	8'd0;
reg 				first_wr = 1'b0;		//标识第一次写
reg 	[31:0] 		round_data 	= 	32'd0;
reg 				round_wr_end = 1'b0,round_wr_end_d1 = 1'b0,round_wr_end_d2 = 1'b0;
reg 	[3:0] 		round_end_cnt = 4'd0;
reg 	[3:0] 		round_wr_end_reg = 4'd0;
reg 				round_wr_end_r = 1'b0;
reg 				hard_wr_end_r = 1'b0;
reg 				hard_wr_end = 1'b0;
reg		[3:0]		hard_end_cnt = 4'd0;
reg 	[2:0] 		hard_wr_end_reg = 3'd0;
reg 				hard_end_rd = 1'b0;
reg 				hard_end_valid = 1'b0;
wire 				wr_wea;
wire 	[7:0] 		wr_addr;
wire 	[31:0] 		wr_data ;
reg 				send_start 		=	1'b0;
reg		[5:0]		send_start_r = 6'd0;
reg 	[3:0]		round_end_mark		= 	4'd0;
wire 	[31:0] 		doutb;
reg 	[2:0] 		rx_interrupt_reg = 3'd0;
reg 				rx_interrupt_flag = 1'b0;	//高表示已发送完中断

reg 	[7:0] 		addrb = 8'd0;
reg 				enb = 1'b0;
reg                 addr_delay = 1'b0;
wire 				rx_mcbsp_interrupt;
wire 				wr_ram_clk;		//ram写时钟改为可选的时钟

reg 	[31:0] 		mcbsp_fpga_signal = 32'd0;	
wire 	[127:0] 	debug_signal_in;

reg     [8:0]       rx_slot_data_length = 9'd128;


parameter 	RV_MODE_DATA	=	32'h2222DDDD,	//32'h2222DDDD,
			RV_WORK_DATA	=	32'h3333CCCC,   // 3333CCCC,
			RV_PA_DATA	    =	32'h1111EEEE,   // 功放控制，原语头
			RV_LENGTH		=	4'd2,				//除去包头后，一条指令的长度
			HARD_TIMER		=	32'h1312D00;		//20M计数25'h1312D00为1S

assign		port_red_stat 			=	hard_cs_out;


	// Instantiate the Unit Under Test (UUT)
	mcbsp_dsp_if_top mcbsp_zero (
		.mcbsp_clk_in(mcbsp_clk_in), 
		.mcbsp_rst_in(mcbsp_rst_in), 
		.mcbsp_slaver_clkx(mcbsp_slaver_clkx), 
		.mcbsp_slaver_mosi(mcbsp_slaver_mosi), 
		.mcbsp_master_clkr(mcbsp_master_clkr), 
		.mcbsp_master_fsr(mcbsp_master_fsr), 
		.mcbsp_master_miso(mcbsp_master_miso), 
		.tx_mcbsp_interrupt(), 		//不用
		.mcbsp_slaver_fsx(mcbsp_slaver_fsx), 
		.dsp_tx_data(dsp_tx_data), 
		.tx_vaild_out(tx_vaild_out), 
		//此处改为用 send_start 代替以前的rx_mcbsp_interrupt接受中断
		.rx_mcbsp_interrupt(rx_mcbsp_interrupt), 
		.rx_slot_data_length(9'd128), 	//rx_slot_data_length   9'd128
		.dsp_rx_dina(dsp_rx_dina), 
		.rx_ram_addr_upd(rx_ram_addr_upd), 
		.debug_signal(debug_signal_in)
	);
///////////////////接受状态处理,时钟为随路的时钟////////////////////////////////////
//接受来自DSP的信号
always@(posedge mcbsp_slaver_clkx or posedge mcbsp_rst_in) begin
  if (mcbsp_rst_in)  begin
		tx_vaild_en_reg		<=		2'd0;    
  end
  else	tx_vaild_en_reg		<=		{tx_vaild_en_reg[0],tx_vaild_out};
end											//获得高脉冲
// assign	tx_vaild_en		=	(tx_vaild_en_reg == 2'b01) ? 1'b1 : 1'b0;//为高即接受到一个数据
always@(posedge mcbsp_slaver_clkx or posedge mcbsp_rst_in) begin
  if (mcbsp_rst_in)  begin
		tx_vaild_en		<=		1'b0;    
  end
  else	if(tx_vaild_en_reg == 2'b01)
		tx_vaild_en		<=		1'b1;
  else	tx_vaild_en		<=		1'b0;
end	

reg [3:0]	work_cnt 		= 4'd0;
reg 		work_mode_en 	= 1'b0;				//接收到工作模式的使能
reg 		work_pamode_en 	= 1'b0;				//接收到工作模式的使能

//判断包头标志，得到工作模式 
always@(posedge mcbsp_slaver_clkx or posedge mcbsp_rst_in) begin
  if (mcbsp_rst_in)  begin
		command_work_en			<=		1'd0; 
		rev_work_mode_r[3:0]	<=		4'd0; 
		work_mode_en			<=		1'b0;
		// work_cnt				<=		4'd0;
  end
  else	if(tx_vaild_en & (dsp_tx_data == RV_MODE_DATA))	 begin	//工作模式包头
		command_work_en			<=		1'b1;
		rev_work_mode_r[3:0]	<=		rev_work_mode_r[3:0];
		work_mode_en			<=		1'b0;
  end
  else	if(command_work_en & tx_vaild_en)	begin		//接收到RV_MODE_DATA后的第一个数据
		command_work_en			<=		1'd0;
		rev_work_mode_r[3:0]	<=		dsp_tx_data[3:0];
		work_mode_en			<=		1'b1;
  end
  else	
		work_mode_en			<=		1'b0;
end

/*判断包头标志，得到工作配置数据RV_WORK_DATA
	原语RV_WORK_DATA     配置参数uiHwConfig		配置数据uiHwPara
	配置参数uiHwConfig[31] 		0-写 1-读
	配置参数uiHwConfig[30:16] 	硬件状态ID
	配置参数uiHwConfig[15:0] 	reg ID   
*/
always@(posedge mcbsp_slaver_clkx or posedge mcbsp_rst_in) begin
  if (mcbsp_rst_in)  begin
		command_valid_en		<=		1'd0; 
		command_start_en		<=		1'b0;
  end
  else	if(tx_vaild_en && (dsp_tx_data == RV_WORK_DATA))	begin//工作模式包头
		command_start_en		<=		1'b1;		//接受到包头的标志，一个时钟周期
  end
  else	if(tx_vaild_en && (dsp_tx_data == RV_PA_DATA))	begin//功放控制包头
		command_valid_en		<=		1'd1;		//接收到包头
  end
  // else	if((rieve_cnt == RV_LENGTH) && tx_vaild_en) begin
  else	if(rieve_cnt == RV_LENGTH) begin
		command_valid_en		<=		1'd0;
		command_start_en		<=		1'b0;
  end
  else begin
		command_valid_en		<=		command_valid_en; 
		command_start_en		<=		1'b0;
  end
end

always@(posedge mcbsp_slaver_clkx or posedge mcbsp_rst_in) begin
  if (mcbsp_rst_in)  begin
		rieve_cnt			<=		4'd0;    
  end
  // else if(((rieve_cnt == RV_LENGTH) && tx_vaild_en))
  else if(rieve_cnt == RV_LENGTH) 
		rieve_cnt			<=		4'd0; 
  else if(command_valid_en && tx_vaild_en)
		rieve_cnt			<=		rieve_cnt + 1'b1;
end

//判断包头标志，得到工作状态设置
always@(posedge mcbsp_slaver_clkx or posedge mcbsp_rst_in) begin
  if (mcbsp_rst_in)  begin
		rev_HwConfig_r[31:0]	<=		32'd0;    
		rev_HwPara_r[31:0]		<=		32'd0;   
        work_pamode_en  		<=		1'b0;        
  end
  //包头后的第一个字节，为配置参数;第二个为数据*****************************
  else if(command_valid_en & tx_vaild_en & (rieve_cnt == 4'd0))	
		rev_HwConfig_r[31:0]	<=		dsp_tx_data[31:0];
  else if(command_valid_en & tx_vaild_en & (rieve_cnt == 4'd1))	begin
        work_pamode_en  		<=		1'b1;
		rev_HwPara_r[31:0]		<=		dsp_tx_data[31:0];
  end
  else  begin
        work_pamode_en  		<=		1'b0;
		rev_HwConfig_r[31:0]	<=		rev_HwConfig_r[31:0];    
		rev_HwPara_r[31:0]		<=		rev_HwPara_r[31:0]; 
  end
end
//给读。写操作命令加一个使能，使其只进行一次读、写操作，延时8个周期
always@(posedge mcbsp_slaver_clkx or posedge mcbsp_rst_in) begin
  if (mcbsp_rst_in)  begin
		wr_rd_cnt[3:0]	<=		4'd0;   
		wr_rd_flag		<=		1'b0;
		pa_wr_rd_flag	<=		1'b0;
  end
  else if(work_mode_en)	begin
		wr_rd_cnt[3:0]	<=		4'd0;   
		wr_rd_flag		<=		1'b1;		//得到配置数据命令后，产生读、写使能
  end
  else if(work_pamode_en)	begin
		wr_rd_cnt[3:0]	<=		4'd0;   
		pa_wr_rd_flag	<=		1'b1;		//得到配置数据命令后，产生读、写使能
  end
  else if(wr_rd_cnt >= 4'd10) begin
		wr_rd_cnt[3:0]	<=		4'd0;   
		wr_rd_flag		<=		1'b0;
		pa_wr_rd_flag	<=		1'b0;
  end
  else if(wr_rd_flag || pa_wr_rd_flag)
		wr_rd_cnt[3:0]	<=		wr_rd_cnt[3:0] + 1'b1;
  else
		;
end


//读取硬件状态rev_work_mode_r ！= 1不为回环模式
assign wr_ram_clk = (rev_work_mode_r[3:0] == 4'd1) ? mcbsp_slaver_clkx : port_clk_10mhz;
//给接口模块发送读取硬件使能，多延迟几拍
always@(posedge mcbsp_slaver_clkx or posedge mcbsp_rst_in) begin
  if (mcbsp_rst_in)  begin
		hard_cs_en_r		<=		1'b0;
		hard_cs_cnt			<=		4'd0;	
  end	
  //DSP读取硬件信息时，发给接口模块使能	 
  // else if((rev_work_mode_r[3:0] == 4'd5)&& work_mode_en) begin  command_start_en
  else if(command_start_en ) begin                   ////硬件状态上报测试2015.12.21
		hard_cs_en_r		<=		1'b1;
		hard_cs_cnt			<=		4'd0;
  end
  else if(hard_cs_cnt >= 4'd4) begin
		hard_cs_en_r		<=		1'b0;
		hard_cs_cnt			<=		4'd0;	
  end
  else if(hard_cs_en_r)
		hard_cs_cnt			<= 		hard_cs_cnt + 1'b1;
  else
		hard_cs_en_r		<=		hard_cs_en_r;
end

//此处直接用接口模块给的时钟，所以直接使用它给过来的使能
//采集状态，产生写地址;
always@(posedge port_clk_10mhz or posedge mcbsp_rst_in) begin
  if (mcbsp_rst_in)  begin
		hard_wr_addr[7:0]	<=		8'd0; 
		hard_wea			<=		1'b0;
		hard_data			<=		32'd0;
		hard_wr_first		<= 		1'b0;
  end
  // else if(rev_work_mode_r[3:0] == 4'd1) begin//回环模式下，清零
		// hard_wea			<=		1'b0;
		// hard_wr_addr[7:0]	<=		hard_wr_addr[7:0];
		// hard_data			<=		32'd0;

  // end
  else if(hard_wr_addr[7:0] >= 8'd8) begin
		hard_wea			<=		1'b0;
		hard_wr_addr[7:0]	<=		8'd0;
		hard_wr_first		<= 		1'b0;
		hard_data			<=		32'd0;
  end	

  // else if(port_data_valid &&(rev_work_mode_r[3:0] == 4'd5)) begin		//直接使用了使能
  else if(port_data_valid ) begin		//直接使用了使能
		hard_wea			<=		1'b1;
		hard_wr_addr[7:0]	<=		hard_wr_addr[7:0] + 1'b1;
		// hard_wr_first		<=		1'b1;
		hard_data			<=		port_red_data;
  end
  else begin
		hard_wea			<=		1'b0;
		hard_wr_addr[7:0]	<=		hard_wr_addr[7:0];
		hard_data			<=		port_red_data;
  end
end
//接口写完后产生结束标识
always@(posedge port_clk_10mhz or posedge mcbsp_rst_in) begin
  if (mcbsp_rst_in)  begin
		hard_wr_end			<=		1'b0; 
		hard_end_cnt		<=		4'd0;
  end
  else if(hard_wr_addr[7:0] >= 8'd8) begin
		hard_wr_end			<=		1'b1;
		hard_end_cnt		<=		4'd0;
  end
  else if(hard_end_cnt >= 4'd4) begin
		hard_wr_end			<=		1'b0;
		hard_end_cnt		<=		4'd0;
  end
  else if(hard_wr_end) begin
		hard_end_cnt		<=		hard_end_cnt + 1'b1;
  end
  else	
		hard_wr_end			<=		hard_wr_end;
end

/////回环模式下，产生写地址rev_work_mode_r[3:0] == 4'd1
always@(posedge mcbsp_slaver_clkx or posedge mcbsp_rst_in) begin
  if (mcbsp_rst_in)  begin
		round_wr_en			<=		1'b0;
  end	
  else if(round_wr_addr[7:0] >= 8'd128 ) begin
		round_wr_en			<=		1'b0;
  end
  //不需要等待写命令	(rev_HwConfig_r[31] == 1'b0) && wr_rd_flag			[31]     0
  // else if((rev_work_mode_r[3:0] == 4'd1) && work_mode_en)
		// round_wr_en			<=		1'b1;	//为高时产生写入地址,下一个即为需要存入的数据
  else if((rev_work_mode_r[3:0] == 4'd1) && tx_vaild_en && (dsp_tx_data == 32'h66669999))
		round_wr_en			<=		1'b1;	//为高时产生写入地址,下一个即为需要存入的数据
  else	
		;
end

//dsp发送来的工作模式后会多发一个同步头，所以先扔掉第一个数据，不存储
reg dsp_more_flag = 1'b0;
always@(posedge mcbsp_slaver_clkx or posedge mcbsp_rst_in) begin
  if (mcbsp_rst_in)  begin
		round_wr_addr[7:0]	<=		8'd0; 
		round_wea			<=		1'b0;
		round_data			<=		32'd0;
		first_wr			<=		1'b0;
		dsp_more_flag		<=		1'b0;
  end
  else if(round_wr_addr[7:0] >= 8'd128 ) begin
		round_wr_addr[7:0]	<=		8'd0; 
		round_wea			<=		1'b0;
		// round_data			<=		32'd0;//
		first_wr			<=		1'b0;
		dsp_more_flag		<=		1'b0;
  end
  // else if(round_wr_en && tx_vaild_en && (!first_wr)) begin
		// round_wr_addr[7:0]	<=		8'd0;
		// round_wea			<=		1'b1;
		// first_wr			<=		1'b1;
		// round_data			<=		dsp_tx_data;
  // end
					//&& (first_wr)
  else if(round_wr_en && tx_vaild_en ) begin
		round_wr_addr[7:0]	<=		round_wr_addr[7:0] + 1'b1;
		round_wea			<=		1'b1;
		round_data			<=		dsp_tx_data;	//round_wr_addr[7:0] + 3'd3;	//dsp_tx_data;
  end
  else begin
		round_wr_addr[7:0]	<=		round_wr_addr[7:0];
		round_wea			<=		1'b0;
		round_data			<=		round_data;
  end
end
//回环写完后的结束标识
always@(posedge mcbsp_slaver_clkx or posedge mcbsp_rst_in) begin
  if (mcbsp_rst_in)  begin
		round_wr_end		<=		1'b0; 
		round_end_cnt		<=		4'd0;
  end
  else if(round_wr_addr[7:0] >= 8'd128 ) begin
		round_wr_end		<=		1'b1;
		round_end_cnt		<=		4'd0;
  end
  else if(round_end_cnt[3:0] >= 4'd4 ) begin
		round_wr_end		<=		1'b0;
		round_end_cnt		<=		4'd0;
  end
  else	if(round_wr_end)
		round_end_cnt		<=		round_end_cnt + 1'b1;
  else
		round_wr_end		<=		round_wr_end;
end

assign	wr_wea		 =	(rev_work_mode_r[3:0] == 4'd1) ? round_wea	   : hard_wea;
assign	wr_addr[7:0] =	(rev_work_mode_r[3:0] == 4'd1) ? round_wr_addr[7:0] : hard_wr_addr[6:0];
assign	wr_data		 =	(rev_work_mode_r[3:0] == 4'd1) ? round_data : hard_data;

////此处由于跨时钟域问题，工作模式变化，则发使能让FPGA时钟域接受数据///////////
always@(posedge mcbsp_slaver_clkx or posedge mcbsp_rst_in) begin
  if (mcbsp_rst_in)  begin
		rev_work_mode_d1[3:0]	<=		4'd0; 
		rev_work_mode_d2[3:0]	<=		4'd0; 
		
		round_wr_end_d1			<=		1'b0;
		round_wr_end_d2			<=		1'b0;
		
		wr_rd_flag_d1			<=		1'b0;
		wr_rd_flag_d2			<=		1'b0;
        
		pa_flag_d1	    		<=		1'b0;
		pa_flag_d2	    		<=		1'b0;
  end
  else begin
		rev_work_mode_d1 		<=		rev_work_mode_r;
		rev_work_mode_d2 		<=		rev_work_mode_d1;
		
		round_wr_end_d1			<=		round_wr_end;
		round_wr_end_d2			<=		round_wr_end_d1;
		
		wr_rd_flag_d1			<=		wr_rd_flag;
		wr_rd_flag_d2			<=		wr_rd_flag_d1;
        
		pa_flag_d1			    <=		pa_wr_rd_flag;
		pa_flag_d2			    <=		pa_flag_d1;
  end
end

always@(posedge mcbsp_slaver_clkx or posedge mcbsp_rst_in) begin
  if (mcbsp_rst_in)  begin
		rev_vld_cnt[2:0]		<=		3'd0;  
		rev_fpga_en				<=		1'b0;
  end
  else if((rev_work_mode_d2 != rev_work_mode_d1) 
		|| (!round_wr_end_d2 && round_wr_end_d1)
		|| (!wr_rd_flag_d2 && wr_rd_flag_d1)) begin
		rev_vld_cnt[2:0]		<=		3'd0;
		rev_fpga_en				<=		1'b1;
  end
  else if (rev_vld_cnt[2:0] >= 3'd4) begin
		rev_vld_cnt[2:0]		<=		3'd0;  
		rev_fpga_en				<=		1'b0;
  end
  else	if(rev_fpga_en ) begin
		rev_vld_cnt[2:0]		<=		rev_vld_cnt[2:0] + 1'b1;
		rev_fpga_en				<=		rev_fpga_en;
  end
		
end
//单独给硬件接口部分的配置信息
always@(posedge mcbsp_slaver_clkx or posedge mcbsp_rst_in) begin
  if (mcbsp_rst_in)  begin
		port_vld_cnt[2:0]		<=		3'd0;  
		port_fpga_en			<=		1'b0;
  end
  else if(!pa_flag_d2 && pa_flag_d1) begin
		port_vld_cnt[2:0]		<=		3'd0;
		port_fpga_en			<=		1'b1;
  end
  else if (port_vld_cnt[2:0] >= 3'd4) begin
		port_vld_cnt[2:0]		<=		3'd0;  
		port_fpga_en			<=		1'b0;
  end
  else if(port_fpga_en) begin
		port_vld_cnt[2:0]		<=		port_vld_cnt[2:0] + 1'b1;
  end
end

////////////////////////////////////////////////////////////////////////////////
//////////////////////发送状态处理,时钟为fpga内部的时钟//////////////////////////
//将接受模块得到的命令，用FPGA--20MHz时钟发出去  

always@(negedge mcbsp_clk_in or posedge mcbsp_rst_in)
begin
  if (mcbsp_rst_in)   begin      //时隙rst,但长度1clk,10M采不到
		rev_fpga_en_flag[3:0]	<= 	4'd0;
		rx_ram_addr_upd_r[2:0]	<=	3'd0;
		send_start_r[5:0]		<=	6'd0;
		round_wr_end_reg		<=	3'd0;
		hard_wr_end_reg			<=	3'd0;
		rx_interrupt_reg		<=	3'd0;
		hard_cs_en_reg			<=	4'd0;
  end
  else begin
		rev_fpga_en_flag[3:0]	<=	{rev_fpga_en_flag[2:0],rev_fpga_en};
		pa_fpga_en_flag[3:0]	<=	{pa_fpga_en_flag[2:0],port_fpga_en};
		rx_ram_addr_upd_r[2:0]	<=	{rx_ram_addr_upd_r[1:0],rx_ram_addr_upd};
		send_start_r[5:0]		<=	{send_start_r[4:0],send_start};
		round_wr_end_reg[3:0]	<=	{round_wr_end_reg[2:0],round_wr_end};
		hard_wr_end_reg[2:0]	<=	{hard_wr_end_reg[1:0],hard_wr_end};
		hard_cs_en_reg[3:0]		<=	{hard_cs_en_reg[2:0],hard_cs_en_r};
		rx_interrupt_reg[2:0]	<=	{rx_interrupt_reg[1:0],rx_mcbsp_interrupt};//round_interrupt
  end
end

//针对单一信号，直接取沿
// assign round_wr_end_r	=	!round_wr_end_reg[3] && round_wr_end_reg[2];
always@(negedge mcbsp_clk_in or posedge mcbsp_rst_in)
begin
  if (mcbsp_rst_in)   
		round_wr_end_r	<=		1'b0;
  else if(round_wr_end_reg[3:2] == 2'b01)  
		round_wr_end_r	<=		1'b1;
  else 
		round_wr_end_r	<=		1'b0;
end

always@(negedge mcbsp_clk_in or posedge mcbsp_rst_in)
begin
  if (mcbsp_rst_in)   
		hard_cs_out	<=		1'b0;
  else if(hard_cs_en_reg[3:2] == 2'b01)  
		hard_cs_out	<=		1'b1;
  else 
		hard_cs_out	<=		1'b0;
end


always@(negedge mcbsp_clk_in or posedge mcbsp_rst_in)
begin
  if (mcbsp_rst_in)   begin      //时隙rst,但长度1clk,10M采不到
    rev_HwPara_out[31:0]	<= 	32'd0;
    rev_HwConfig_out[31:0]	<= 	32'd0;
    rev_work_mode_out[3:0]	<= 	4'd0;
	wr_rd_en_flag			<=	1'b0;
  end
  else if(rev_fpga_en_flag[3:2] == 2'b01)begin
	wr_rd_en_flag			<=	wr_rd_flag;		//和rev_HwConfig_r同步变化，维持一个周期
    rev_work_mode_out[3:0]	<= 	rev_work_mode_r[3:0];
  end
  // else if(pa_fpga_en_flag[3:2] == 2'b01)begin
    // rev_HwPara_out[31:0]	<= 	rev_HwPara_r[31:0];
    // rev_HwConfig_out[31:0]	<= 	rev_HwConfig_r[31:0];
  // end
  else	
	wr_rd_en_flag			<=	1'b0;			//只是有效一个周期
end

assign		rev_work_mode[3:0] 	=	rev_work_mode_out[3:0];
assign		rev_HwConfig[31:0] 	=	rev_HwConfig_out[31:0];
assign		rev_HwPara[31:0] 	=	rev_HwPara_out[31:0];
assign		work_mode_vld		=	wr_rd_en_flag;
//////////////////////////////////////////////////////////////////////////
//将接受模块得到的命令，用PORT--10MHz时钟发出去 
always@(negedge port_clk_10mhz or posedge mcbsp_rst_in)
begin
  if (mcbsp_rst_in)   begin      //时隙rst,但长度1clk,10M采不到
		rev_fpga_en_port[3:0]	<= 	4'd0;
  end
  else begin
		rev_fpga_en_port[3:0]	<=	{rev_fpga_en_port[2:0],port_fpga_en};
  end
end

//按接口时钟送出配置信号 10MHz
always@(negedge port_clk_10mhz or posedge mcbsp_rst_in)
begin
  if (mcbsp_rst_in)   begin      //时隙rst,但长度1clk,10M采不到
	port_rd_flag			<=	32'd0;
  end
  else if(rev_fpga_en_port[3:2] == 2'b01)begin
	port_rd_flag			<=	32'd1;
  end
  else
	port_rd_flag			<=	32'd0;
end

always@(negedge port_clk_10mhz or posedge mcbsp_rst_in)
begin
  if (mcbsp_rst_in)  begin
	port_wr_en_r				<= 1'b0;
	port_wr_next				<= 1'b0;
	port_wr_data_r				<= 32'd0;
  end
  else if(port_rd_flag) begin
	port_wr_en_r				<= 1'b1;
	port_wr_next				<= 1'b1;
	port_wr_data_r				<= rev_HwConfig_r;
  end
  else if(port_wr_next) begin
	port_wr_en_r				<= 1'b1;
	port_wr_next				<= 1'b0;
	port_wr_data_r				<= rev_HwPara_r;
  end
  else begin
	port_wr_en_r				<= 1'b0;
	port_wr_next				<= 1'b0;
	port_wr_data_r				<= 32'd0;
  end
end
assign port_wr_en				=	port_wr_en_r;
assign port_wr_data				=	port_wr_data_r;

//直接将DSP给的配置数据，拼为64bit送出
always@(negedge port_clk_10mhz or posedge mcbsp_rst_in)
begin
  if (mcbsp_rst_in)  begin
     dsp_ctr_uart_en          <= 1'b0;
     dsp_ctr_uart_data[63:0]  <= 64'd0;
  end
  else if(port_rd_flag) begin
     dsp_ctr_uart_en          <= 1'b1;
     dsp_ctr_uart_data[63:0]  <= {rev_HwConfig_r[31:0],rev_HwPara_r[31:0]};
  end
  else
     dsp_ctr_uart_en          <= 1'b0;
end

///////////////////////////////////////////////////////////////////////////
//当硬件状态接受写满地址时，产生写完标识 
always@(negedge mcbsp_clk_in or posedge mcbsp_rst_in)
begin
  if (mcbsp_rst_in)   begin      
		hard_end_rd				<=		1'b0;
  end		
  else if(hard_wr_end_reg[2:1] == 2'b01)
		hard_end_rd				<=		1'b1;
  else
		hard_end_rd				<=		1'b0;
end

//接口模块得到start后，发送过来的使能信号为10MHz，直接用20MH中采集
//port_data_valid发送过来后西安存取，此处多几个延时，让前面时间用来存RAM
always@(posedge mcbsp_clk_in or posedge mcbsp_rst_in) begin
  if (mcbsp_rst_in)  begin
		hard_start_r		<=		6'd0;
  end	
  else 
		hard_start_r		<=		{hard_start_r[4:0],port_data_valid};
end
//判断接收到读取命令时，产生读RAM地址
always@(negedge mcbsp_clk_in or posedge mcbsp_rst_in)
begin
  if (mcbsp_rst_in)   begin      
		send_start				<=		1'b0;
        hard_end_valid          <=      1'b0;
  end		
  else if((rev_work_mode_out[3:0] == 4'd1) && (addrb > 8'd128)) begin
		send_start				<=		1'b0;
  end
  //此处特殊处理，》6后，只要接收到DSP来的数据，则将长度切为128
  else if((hard_end_valid) && (addrb > 8'd8)) begin
        hard_end_valid          <=      1'b0;
		send_start				<=		1'b0;
  end
  //产生开始读取RAM的标志     不用发送完中断等待读取命令  && rx_interrupt_flag
  else if((rev_work_mode_out[3:0] == 4'd1) && round_wr_end_r) begin	//接收完开始发送
		send_start				<=		1'b1;
  end	
  else if( hard_end_rd) begin
        hard_end_valid          <=      1'b1;
		send_start				<=		1'b1;
  end

end
//*******************************************************************************************
//产生mcbsp发送模块的长度
always@(negedge mcbsp_clk_in or posedge mcbsp_rst_in)
begin
  if (mcbsp_rst_in)   begin      
        rx_slot_data_length     <=      9'd128;
        addr_delay              <=      1'b0;
  end		
  else if((hard_end_valid) && (addrb > 8'd8)) begin
        addr_delay              <=      1'b1;
  end
  else if(addr_delay && tx_vaild_en) begin
        addr_delay              <=      1'b0;
        rx_slot_data_length     <=      9'd128;
  end
  // else if((rev_work_mode_out[3:0] == 4'd5) && hard_end_rd) begin
  else if( hard_end_rd) begin
        rx_slot_data_length     <=      9'd8;
  end
end

//读地址  读取命令有效后的下一个数据才为读取的数据
always@(negedge mcbsp_clk_in or posedge mcbsp_rst_in)
begin
  if (mcbsp_rst_in)   begin      
		addrb[7:0]		<= 		8'd0;
		enb				<=		1'b0;
  end		//产生开始读取RAM的标志
  else if((rev_work_mode_out[3:0] == 4'd1) && addrb > 8'd128) begin
		addrb[7:0]		<= 		8'd0;
		enb				<=		1'b0;
  end
  else if((hard_end_valid) && (addrb > 8'd8)) begin
		addrb[7:0]		<= 		8'd0;
		enb				<=		1'b0;
  end
  else if(send_start && (rx_ram_addr_upd_r[2:1] == 2'b01)) begin
		addrb[7:0]		<= 		addrb[7:0] + 1'b1;
		enb				<=		1'b1;
  end
  else	
		enb				<=		1'b0;
end

//生成mcbsp需要的信号((rev_work_mode_out[3:0] == 4'd5) || (rev_work_mode_out[3:0] == 4'd1))

// assign dsp_rx_dina	=	((rev_work_mode_out[3:0] == 4'd5) || (rev_work_mode_out[3:0] == 4'd1)) ? doutb : 32'b0;
assign dsp_rx_dina	=	doutb;

//产生DSP的接受中断
always@(negedge mcbsp_clk_in or posedge mcbsp_rst_in)
begin
  if (mcbsp_rst_in)   begin      
		rx_int_cnt[3:0]			<= 		4'd0;
		round_interrupt			<=		1'b0;
  end	
  else if(send_start_r[5:4] == 2'b01) begin 
		rx_int_cnt[3:0]			<= 		4'd0;
		round_interrupt			<=		1'b1;
  end
  else if(send_start & (rx_int_cnt[3:0] >= 4'd2)) begin
		rx_int_cnt[3:0]			<= 		4'd0;	//中断延时时间需确定
		round_interrupt			<=		1'b0;
  end
  else if(send_start) begin
		rx_int_cnt[3:0]			<=	rx_int_cnt[3:0] + 1'b1;
  end
end

//本模块的外部输入接受中断与产生中断的选择
// assign  rx_mcbsp_interrupt	=	((rev_work_mode_out[3:0] == 4'd5) || (rev_work_mode_out[3:0] == 4'd1)) ? round_interrupt : 1'b0;
assign  rx_mcbsp_interrupt	=	round_interrupt;

ram_32x512 mcbsp_zero_ram_u (
  .clka(wr_ram_clk), 		// input clka
  .wea(wr_wea), 	// input [0 : 0] wea
  .ena(1'b1),
  .addra({1'b0,wr_addr[7:0]}), 	// input [6 : 0] addra
  .dina(wr_data), 	// input [31 : 0] dina
  .clkb(mcbsp_clk_in), 		// input clkb
  .enb(enb), 		// input enb
  .addrb({1'b0,addrb[7:0]}), 	// input [6 : 0] addrb
  .doutb(doutb) 	// output [31 : 0] doutb
);




















wire [127:0] debug_signal_r;
//*********************chipscope抓取波形定义****************************
//mcbsp0:	DSP 输入波形
 assign		debug_signal_r[0]	=	debug_signal_in[63];	//mcbsp_slaver_clkx
 assign		debug_signal_r[1]	=	debug_signal_in[62];	//mcbsp_slaver_fsx
 assign		debug_signal_r[3]	=	debug_signal_in[61];	//mcbsp_slaver_mosi

 assign		debug_signal_r[4]	=	work_mode_en;	
 assign		debug_signal_r[8:5]	=	rev_work_mode_r[3:0];
 assign		debug_signal_r[9]	=	command_start_en;
 assign		debug_signal_r[10]	=	    hard_wea;
 assign		debug_signal_r[18:11]	=	hard_wr_addr[7:0];
 assign		debug_signal_r[50:19]	=	port_wr_data[31:0];		//round_data[31:0];
 assign		debug_signal_r[51]	=	hard_wr_end;
 assign		debug_signal_r[52]	=	hard_end_rd;
 assign		debug_signal_r[53]	=	enb;
 assign		debug_signal_r[54]	=	port_wr_en;
 assign		debug_signal_r[60:55]	=	addrb[5:0];
 
 assign		debug_signal_r[61]	=	tx_vaild_en;
 
 // assign		debug_signal_r[64]	=	debug_signal_in[64];
 
 // assign		debug_signal_r[71:65]	=	debug_signal_in[25:19];
 
 assign		debug_signal_r[93:62]	=	dsp_rx_dina[31:0];
 
 assign		debug_signal_r[127:94]	=	debug_signal_in[127:94];
 
 
 
 assign 	debug_signal[127:0]			=	debug_signal_r[127:0];
// FPGA 内部逻辑信号
// assign		debug_signal[123]	=	tx_vaild_en;	//为高即接受到一个32bit数据
	
endmodule
