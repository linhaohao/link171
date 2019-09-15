`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:05:11 11/03/2015 
// Design Name: 
// Module Name:    io_ctr_rf 
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
//此模块用来测试FPGA与射频板间的链路，每个输出管脚输出不同频率的时钟进行
//回路测试。
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module io_ctr_rf(
//// clock interface ////                                         
input               clk_20mhz,           // 20mhz   2015/9/9 10:53:16   发用上沿，收用下沿。
                                
//对于串口模块的控制
input				rv_uart_vld,	//串口输入命令数据标识
input	[63:0]		rv_uart_data,	//串口输入命令数据
input               power_en,       //功放静默开关
input               tx_rx_switch_out, //1--发射时隙
input   [31:0]      mif_rv_pbr,
//// RF port ///////////////////////////////
/////  RF射频发射板    
output				tx_lo_c1p,
output				tx_lo_c1n,
output				tx_lo_c2p,			//发送时隙接口
output				tx_lo_c2n,


output	[2:0]		pe_slect_p,			//本振选择开关4——6
output	[2:0]		pe_slect_n,

output	[3:0]		pdbrf_en_p,			//本振使能
output	[3:0]		pdbrf_en_n,

output	[3:0]		sd_power_low_en,	//功率衰减使能
output				sd_sig_mode,		//发送板大小信号切换
output	[1:0]		sd_temp_test,		//温度检测
output	[3:0]		sd_levl_en,			//电压检测

input   [3:0]	    lunch_att_io,
///////////////  RF灏勯鎺ュ彈鏉
output	[3:0]		rv_pdbrf_en_p,		//鏈尟浣胯兘
output	[3:0]		rv_pdbrf_en_n,

output				rv_power_low_en,	//功率衰减使能,"1"衰减
output				tmp100_e2prom,		//功率衰减使能 “1”控制温度
output				rs232_rx,			//FPGA接受来自CPLD的数据
output				rs232_tx,			//CPLD接受FPGA的数据
output	[1:0]		sig_mode,			//"2'b01 -- 小信号接受"
										//"2'b00 -- 小信号发送"
                                        //"2'b10 -- 大信号模式"
output	[1:0]		i2c_test			//i2c检测

//// debug ////
// output[19:0]       debug_signal_rf
    );

reg		[15:0]	io_select	  =	16'd0;
reg		[31:0]	rv_io_mode	  =	32'd0;
reg		[40:0]	sd_io_mode	  =	41'h11111;
reg             sig_mode_chg  = 1'b0;
reg             sd_sig_mode_chg  = 1'b0;
reg             lunch_att_select = 1'b0;
reg     [3:0]   rv_prb_reg ;

//将单端输出信号转化为差分信号
   OBUFDS #(
      .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
      .SLEW("SLOW")           // Specify the output slew rate
   ) OBUFDS_u1 (
      .O(tx_lo_c1p),     	// Diff_p output (connect directly to top-level port)
      .OB(tx_lo_c1n),   	// Diff_n output (connect directly to top-level port)
      .I(io_select[0])     // Buffer input 
   );

   OBUFDS #(
      .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
      .SLEW("SLOW")           // Specify the output slew rate
   ) OBUFDS_u2 (
      .O(tx_lo_c2p),     	// Diff_p output (connect directly to top-level port)
      .OB(tx_lo_c2n),   	// Diff_n output (connect directly to top-level port)
      .I(io_select[1])     // Buffer input 
   );
   
   OBUFDS #(
      .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
      .SLEW("SLOW")           // Specify the output slew rate
   ) OBUFDS_u3 (
      .O(pe_slect_p[0]),     	// Diff_p output (connect directly to top-level port)
      .OB(pe_slect_n[0]),   	// Diff_n output (connect directly to top-level port)
      .I(io_select[2])     // Buffer input 
   );
   
   OBUFDS #(
      .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
      .SLEW("SLOW")           // Specify the output slew rate
   ) OBUFDS_u4 (
      .O(pe_slect_p[1]),     	// Diff_p output (connect directly to top-level port)
      .OB(pe_slect_n[1]),   	// Diff_n output (connect directly to top-level port)
      .I(io_select[3])     // Buffer input 
   );
   
   OBUFDS #(
      .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
      .SLEW("SLOW")           // Specify the output slew rate
   ) OBUFDS_u5 (
      .O(pe_slect_p[2]),     	// Diff_p output (connect directly to top-level port)
      .OB(pe_slect_n[2]),   	// Diff_n output (connect directly to top-level port)
      .I(io_select[4])     // Buffer input 
   );

   OBUFDS #(
      .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
      .SLEW("SLOW")           // Specify the output slew rate
   ) OBUFDS_u6 (
      .O(pdbrf_en_p[0]),     	// Diff_p output (connect directly to top-level port)
      .OB(pdbrf_en_n[0]),   	// Diff_n output (connect directly to top-level port)
      .I(io_select[5])     // Buffer input 
   );
   
   OBUFDS #(
      .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
      .SLEW("SLOW")           // Specify the output slew rate
   ) OBUFDS_u7 (
      .O(pdbrf_en_p[1]),     	// Diff_p output (connect directly to top-level port)
      .OB(pdbrf_en_n[1]),   	// Diff_n output (connect directly to top-level port)
      .I(io_select[6])     // Buffer input 
   );
   
   OBUFDS #(
      .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
      .SLEW("SLOW")           // Specify the output slew rate
   ) OBUFDS_u8 (
      .O(pdbrf_en_p[2]),     	// Diff_p output (connect directly to top-level port)
      .OB(pdbrf_en_n[2]),   	// Diff_n output (connect directly to top-level port)
      .I(io_select[7])     // Buffer input 
   );
   
   OBUFDS #(
      .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
      .SLEW("SLOW")           // Specify the output slew rate
   ) OBUFDS_u9 (
      .O(pdbrf_en_p[3]),     	// Diff_p output (connect directly to top-level port)
      .OB(pdbrf_en_n[3]),   	// Diff_n output (connect directly to top-level port)
      .I(io_select[8])     // Buffer input 
   );
   
//接受板本振使能  
always @(posedge clk_20mhz) begin  
	if(mif_rv_pbr[16] == 1'b0)  begin
        if(tx_rx_switch_out)
            rv_prb_reg[3:0] 	<=	mif_rv_pbr[3:0];
        else
            rv_prb_reg[3:0] 	<=	4'hf;
    end
	else
		rv_prb_reg[3:0] 	<=	4'hf;
end
   
   OBUFDS #(
      .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
      .SLEW("SLOW")           // Specify the output slew rate
   ) OBUFDS_u10 (
      .O(rv_pdbrf_en_p[0]),     	// Diff_p output (connect directly to top-level port)
      .OB(rv_pdbrf_en_n[0]),   	// Diff_n output (connect directly to top-level port)
      .I(rv_prb_reg[0])     // Buffer input 
   );
   
   OBUFDS #(
      .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
      .SLEW("SLOW")           // Specify the output slew rate
   ) OBUFDS_u11 (
      .O(rv_pdbrf_en_p[1]),     	// Diff_p output (connect directly to top-level port)
      .OB(rv_pdbrf_en_n[1]),   	// Diff_n output (connect directly to top-level port)
      .I(rv_prb_reg[1])     // Buffer input 
   );
   
   OBUFDS #(
      .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
      .SLEW("SLOW")           // Specify the output slew rate
   ) OBUFDS_u12 (
      .O(rv_pdbrf_en_p[2]),     	// Diff_p output (connect directly to top-level port)
      .OB(rv_pdbrf_en_n[2]),   	// Diff_n output (connect directly to top-level port)
      .I(rv_prb_reg[2])     // Buffer input 
   );
   
   OBUFDS #(
      .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
      .SLEW("SLOW")           // Specify the output slew rate
   ) OBUFDS_u13 (
      .O(rv_pdbrf_en_p[3]),     	// Diff_p output (connect directly to top-level port)
      .OB(rv_pdbrf_en_n[3]),   	// Diff_n output (connect directly to top-level port)
      .I(rv_prb_reg[3])     // Buffer input 
   );
   
always @(posedge clk_20mhz) begin   //控制差分信号的命令
	if(rv_uart_vld && (rv_uart_data[63:16] == 48'h1a1a_0000_1111)) 
		io_select[15:0] 	<=	rv_uart_data[15:0];
	else
		io_select[15:0] 	<=	io_select[15:0];
end

//接收板的切换控制命令********************************************
always @(posedge clk_20mhz) begin   //控制差分信号的命令
	if(rv_uart_vld && (rv_uart_data[63:32] == 32'h1b1b_0001)) 
		rv_io_mode[31:0] 	<=	rv_uart_data[31:0];
	else
		rv_io_mode[31:0] 	<=	rv_io_mode[31:0];
end

//接收板大小信号开关和命令切换
always @(posedge clk_20mhz) begin   //控制差分信号的命令   
	if(rv_uart_vld && (rv_uart_data[63:32] == 32'h1b1b_3e01)) 
		sig_mode_chg     	<=	1'b1;
	else if(rv_uart_vld && (rv_uart_data[63:32] == 32'h1b1b_3e02)) 
		sig_mode_chg     	<=	1'b0;
	else
		;
end
//目前版本暂时不和接受、发射时隙联系起来，为常态         1--大信号                           2'b00
assign		sig_mode[1:0]		=   (!sig_mode_chg) ? (power_en ? 2'b10 : (tx_rx_switch_out ? 2'b01 : 2'b00)) : ({rv_io_mode[20],rv_io_mode[16]});

assign		rv_power_low_en		=	rv_io_mode[0];
assign		tmp100_e2prom		=   rv_io_mode[4];
assign		rs232_rx			=   rv_io_mode[8];
assign		rs232_tx			=   rv_io_mode[12];
// assign		sig_mode[1:0]		=   {rv_io_mode[20],rv_io_mode[16]};
assign		i2c_test[1:0]		=   {rv_io_mode[28],rv_io_mode[24]};


//****************************************************************
	
//发送板的切换控制命令********************************************
always @(posedge clk_20mhz) begin   //控制差分信号的命令
	if(rv_uart_vld && (rv_uart_data[63:41] == 23'h7c_c3c3)) //c0 f987 8600 0001 0000 cf
		sd_io_mode[40:0] 	<=	rv_uart_data[40:0];
	else if(rv_uart_vld && (rv_uart_data[63:32] == 32'h1b1b_3e0a))
		lunch_att_select	<=	rv_uart_data[0];
	else
		sd_io_mode[40:0] 	<=	sd_io_mode[40:0];
end

//发射板大小信号开关和命令切换
always @(posedge clk_20mhz) begin   //控制差分信号的命令   
	if(rv_uart_vld && (rv_uart_data[63:32] == 32'h1b1b_3e03)) 
		sd_sig_mode_chg     	<=	1'b1;
	else if(rv_uart_vld && (rv_uart_data[63:32] == 32'h1b1b_3e04)) 
		sd_sig_mode_chg     	<=	1'b0;
	else
		;
end
//目前版本暂时不和接受、发射时隙联系起来，为常态         0--大信号
assign		sd_sig_mode			=   (!sd_sig_mode_chg) ? (power_en ? 1'b0 : 1'b1) : sd_io_mode[16];

//assign		sd_power_low_en[3:0]=	{sd_io_mode[12],sd_io_mode[8],sd_io_mode[4],sd_io_mode[0]};
assign		sd_power_low_en[3:0]=	lunch_att_select ? {sd_io_mode[12],sd_io_mode[8],sd_io_mode[4],sd_io_mode[0]} : (power_en ? lunch_att_io[3:0] : 4'b1111);

// assign		sd_sig_mode			=   sd_io_mode[16];
assign		sd_temp_test[1:0]	=   {sd_io_mode[24],sd_io_mode[20]};
assign		sd_levl_en[3:0]		=   {sd_io_mode[40],sd_io_mode[36],sd_io_mode[32],sd_io_mode[28]};

//****************************************************************

endmodule

