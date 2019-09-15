`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:26:08 11/23/2015 
// Design Name: 
// Module Name:    power_ctr_top 
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
module power_ctr_top(
input               clk,			// 50MHz主时钟
input               rst_n,		//低电平复位信号
input				time_1s_en,		//更新操作使能

input               rs232_rx,	// RS232接收数据信号
output              rs232_tx,	// RS232发送数据信号
input               power_en,    // 功放静默开关
output              power_send_p,       //功放收发P,高发低收
output              power_send_n,       //功放收发n
output              power_slot_p,       //功放时隙p
output              power_slot_n,       //功放时隙n
output  reg [3:0]   power_std_collect,  //功放的查询状态送给DSP, 3--a,2--b,1--c,0--d
output  reg [7:0]   pa_temp_collect,    //功放的温度值

//对于串口模块的控制
input			    rv_uart_vld,	//串口输入命令数据标识
input	[63:0]	    rv_uart_data,	//串口输入命令数据

input               dsp_ctr_uart_en,
input    [63:0]     dsp_ctr_uart_data,

output	reg		    uart_send_en,	//发送数据使能
output	reg [63:0]	sd_uart_data	//送出的数据

);

wire send_vld;
wire recirve_vld;
wire [39:0] recieve_data;
reg  send_en = 1'b0;
reg  [31:0] send_data = 32'd0;

// reg [39:0] rv_send_data = 40'd0;
reg        power_en_r = 1'b0;

reg [3:0]   time_cnt = 4'd0;
reg         time_ini_en = 1'b0;

reg			uart_rd_ctr		=	1'b0;	//用来区分定时读和命令读取，1为命令读取

reg         power_send_r = 1'b0;    //功放收发
reg         power_slot_r = 1'b0;    //功放时隙
reg         first_rd     = 1'b0;    //定时切换温度和功率值

parameter     TIMER_1S_CNT  =   4'd3;   //3S
                                   
//fpga与功放间的例化
power_uart_top  rf_uart_top_rv(
				.clk                         (clk        ),
				.rst_n                       (rst_n        ),
				.rs232_rx                    (rs232_rx),
				.rs232_tx                    (rs232_tx),
				.recieve_data                (recieve_data       ),
				.recirve_vld                 (recirve_vld  ),
				.send_en                     (send_en   ),
				.send_data                   (send_data     ),    //保持时间要长
				.send_vld                    (   )
				
				);
//******************************************************************
//*************I@C读取操作,送给串口*******************************
always@(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		uart_send_en    		<=	1'b0;
		sd_uart_data[63:0]		<=	64'd0;
		uart_rd_ctr				<=	1'b0;
        // power_std_collect       <=  4'hf;
        pa_temp_collect         <=  8'd0;
	end
    //读出静默开关的状态 
	else if(rv_uart_vld && (rv_uart_data[63:0] == 64'h1f1a_1f00_001a_001f)) begin
		uart_send_en		<=	1'd1;
		sd_uart_data[63:0]	<=	{24'h1a1f_22,39'd0,power_en};
	end
    else if(dsp_ctr_uart_en) begin
		uart_send_en		<=	1'd1;
		sd_uart_data[63:0]	<=	dsp_ctr_uart_data[63:0];
	end
    //fpga发给CPU的值
	// else if(rv_uart_vld && (rv_uart_data[63:0] == 64'h1f1a_0000_001a_001f)) begin
		// uart_send_en		<=	1'd1;
        // uart_rd_ctr			<=	1'b1;
		// sd_uart_data[63:0]	<=	{24'h1a1f_11,rv_send_data[39:0]};
	// end
	else if(rv_uart_vld && (rv_uart_data[63:32] == 64'h1f1a_1a1f)) begin
        uart_rd_ctr			<=	1'b1;
    end
    else if(recirve_vld && uart_rd_ctr) begin
		uart_send_en		<=	1'd1;
        uart_rd_ctr			<=	1'b0;
		sd_uart_data[63:0]	<=	{24'h1a1f_11,recieve_data[39:0]};
    end
    //将查询的状态送给DSP   
	// else if(recirve_vld && (send_data[31:0] == 32'h00040102)) begin
        // power_std_collect   <=  {recieve_data[28],recieve_data[24],recieve_data[36],recieve_data[32]};
    // end
    //将查询的温度送给DSP   
	else if(recirve_vld && (send_data[31:0] == 32'h00030102)) begin
        pa_temp_collect     <=  recieve_data[39:32];
    end
    //读出功放控制状态的状态 
	else if(rv_uart_vld && (rv_uart_data[63:0] == 64'h1f1a_1f00_b01a_001f)) begin
		uart_send_en		<=	1'd1;
		sd_uart_data[63:0]	<=	{24'h1a1f_22,28'd0,pa_temp_collect,power_std_collect};
	end
    else begin
		sd_uart_data[63:0]  <=  sd_uart_data[63:0];
        uart_send_en		<=	1'd0;
        // power_std_collect[3:0]  <=  power_std_collect[3:0];
        pa_temp_collect[7:0]    <=  pa_temp_collect[7:0];
    end
end

//1s计数器
always@(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		time_cnt[3:0]	<=	4'd0;
	end
	else if(time_cnt[3:0] == TIMER_1S_CNT) begin
        time_cnt[3:0]	<=	time_cnt[3:0] + 1'b1;
	end
    else if(time_1s_en && (time_cnt[3:0] < TIMER_1S_CNT))begin
		time_cnt[3:0]	<=	time_cnt[3:0] + 1'b1;
    end
    else
        time_cnt[3:0]	<=	time_cnt[3:0];
end


//对功放的控制
always@(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		send_en				<=	1'd0;
		// uart_send_en		<=	1'd0;
		send_data[31:0]		<=	32'd0;
        power_en_r          <=  1'b0;
        first_rd            <=  1'b0;
        power_std_collect   <=  4'hf;
	end
    //开机后3s，软件关闭功放
    else if(time_cnt[3:0] == TIMER_1S_CNT) begin
		send_en				<=	1'd1;
		send_data[31:0]		<=	32'h00010103;
    end
    else if(dsp_ctr_uart_en && dsp_ctr_uart_data[63:0] == 64'hCDCD005000000001) begin
		send_en				<=	1'd1;
		send_data[31:0]		<=	32'h01010103;
        power_std_collect   <=  4'h0;
	end
    else if(dsp_ctr_uart_en && dsp_ctr_uart_data[63:0] == 64'hCDCD005000000000) begin
		send_en				<=	1'd1;
		send_data[31:0]		<=	32'h00010103;
        power_std_collect   <=  4'hf;
	end
    //发给功放的命令
	else if(rv_uart_vld && (rv_uart_data[63:32] == 32'h1f1a_1a1f)) begin
		send_en				<=	1'd1;
		send_data[31:0]		<=	rv_uart_data[31:0];
	end
	//定时读取功放状态
	else if(time_1s_en) begin	//读取功放状态
		send_en				<=	1'd1;
        first_rd            <=  1'b1;
		send_data[31:0]		<=	32'h00040102;
	end
    //定时读取功放温度
	else if(first_rd && recirve_vld) begin	
		send_en				<=	1'd1;
        first_rd            <=  1'b0;
		send_data[31:0]		<=	32'h00030102;
	end
    //写入收发的状态 power_send_r
	else if(rv_uart_vld && (rv_uart_data[63:32] == 32'h1f1a_1f01)) begin
		power_send_r		<=	rv_uart_data[0];
	end
    //写入时隙的状态
	else if(rv_uart_vld && (rv_uart_data[63:32] == 32'h1f1a_1f02)) begin
		power_slot_r		<=	rv_uart_data[0];
	end
	else begin
		send_en				<=	1'd0;
		send_data[31:0]		<=	send_data[31:0];
	end
end
    
//将单端输出信号转化为差分信号
   OBUFDS #(
      .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
      .SLEW("SLOW")           // Specify the output slew rate
   ) power_send_u0 (
      .O(power_send_p),     	// Diff_p output (connect directly to top-level port)
      .OB(power_send_n),   	// Diff_n output (connect directly to top-level port)
      .I(power_send_r)     // Buffer input 
   );
    
//将单端输出信号转化为差分信号
   OBUFDS #(
      .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
      .SLEW("SLOW")           // Specify the output slew rate
   ) power_slot_u0 (
      .O(power_slot_p),     	// Diff_p output (connect directly to top-level port)
      .OB(power_slot_n),   	// Diff_n output (connect directly to top-level port)
      .I(power_slot_r)     // Buffer input 
   );
    
endmodule
