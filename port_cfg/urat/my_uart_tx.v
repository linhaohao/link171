`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:    17:11:32 08/28/08
// Design Name:    
// Module Name:    my_uart_rx
// Project Name:   
// Target Device:  
// Tool versions:  
// Description:
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////
module my_uart_tx(
				clk,rst_n,
				rx_data,rx_int,rs232_tx,
				clk_bps,bps_start,
				comnd_en,
				send_en_valid,
				comnd_data
			);

input clk;			// 50MHz主时钟
input rst_n;		//低电平复位信号
input clk_bps;		// clk_bps_r高电平为接收数据位的中间采样点,同时也作为发送数据的数据改变点
input[7:0] rx_data;	//接收数据寄存器
input rx_int;		//接收数据中断信号,接收到数据期间始终为高电平,在该模块中利用它的下降沿来启动串口发送数据
output rs232_tx;	// RS232发送数据信号
output bps_start;	//接收或者要发送数据，波特率时钟启动信号置位
input [7:0] comnd_data;	//内部逻辑需要发送的数据
input comnd_en;			//内部发送的使能
input send_en_valid;	//内部发送时为高

//---------------------------------------------------------
reg rx_int0 = 1'b0,rx_int1 = 1'b0,rx_int2 = 1'b0;	//rx_int信号寄存器，捕捉下降沿滤波用
reg neg_rx_int = 1'b0;	// rx_int下降沿标志位

reg	neg_rx_flag = 1'b0;
reg [1:0]	neg_rx_flag_reg = 2'd0;

//---------------------------------------------------------
reg[7:0] tx_data = 8'd0;	//待发送数据的寄存器
//---------------------------------------------------------
reg bps_start_r = 1'b0;
reg tx_en = 1'b0;	//发送数据使能信号，高有效
reg[3:0] num = 4'd0;
always @ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
			rx_int0 <= 1'b0;
			rx_int1 <= 1'b0;
			rx_int2 <= 1'b0;
			
			neg_rx_flag_reg		<=	2'd0;
		end
	else begin
			rx_int0 <= rx_int;
			rx_int1 <= rx_int0;
			rx_int2 <= rx_int1;
			
			neg_rx_flag_reg[1:0]		<=	{neg_rx_flag_reg[0],neg_rx_flag};
		end
end

//在发送状态过程中接受到下降沿产生一个特殊标识
always @ (posedge clk or negedge rst_n) begin
	if(!rst_n) 	
			neg_rx_flag		<= 		1'b0;			//默认空闲态
	else if (rx_int2 && (!rx_int1) && (tx_en)) 		//在发送状态接受到下降沿
			neg_rx_flag		<= 		1'b1;			//保持到上一次发送完毕
	else if(!tx_en)
			neg_rx_flag		<= 		1'b0;
end

// assign neg_rx_int =  ~rx_int1 & rx_int2;	//捕捉到下降沿后，neg_rx_int拉高保持一个主时钟周期
always @ (posedge clk or negedge rst_n) begin
	if(!rst_n) 	
			neg_rx_int		<= 		1'b0;			//默认空闲态
	else if (rx_int2 && (!rx_int1) && (!tx_en)) 	//没有在发送状态接受到下降沿
			neg_rx_int		<= 		1'b1;
	else	
			neg_rx_int		<= 		1'b0;
end



always @ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
			bps_start_r <= 1'b0;
			tx_en <= 1'b0;
			tx_data <= 8'd0;
		end
	//接收数据完毕，准备把接收到的数据发回去;需在内部没有发送数据时	
//	else if(neg_rx_int && (!send_en_valid)) begin	
//			bps_start_r <= 1'b1;
//			tx_data <= rx_data;	//把接收到的数据存入发送数据寄存器
//			tx_en <= 1'b1;		//进入发送数据状态中
//		end
//	else if((neg_rx_flag_reg[1:0] == 2'b10) && (!send_en_valid)) begin	
//			bps_start_r <= 1'b1;
//			tx_data <= rx_data;	//把接收到的数据存入发送数据寄存器neg_rx_flag_reg
//			tx_en <= 1'b1;		//进入发送数据状态中
//		end
	else if(comnd_en) begin		//接收数据完毕，准备把接收到的数据发回去
			bps_start_r <= 1'b1;
			tx_data <= comnd_data;	//把接收到的数据存入发送数据寄存器
			tx_en <= 1'b1;			//进入发送数据状态中
		end
	else if(num==4'd11) begin	//数据发送完成，复位
			bps_start_r <= 1'b0;
			tx_en <= 1'b0;
		end
end

assign bps_start = bps_start_r;

//---------------------------------------------------------
reg rs232_tx_r = 1'b1;

always @ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
			num <= 4'd0;
			rs232_tx_r <= 1'b1;
		end
	else if(tx_en) begin
			if(clk_bps)	begin
					num <= num+1'b1;
					case (num)
						4'd0: rs232_tx_r <= 1'b0; 	//发送起始位
						4'd1: rs232_tx_r <= tx_data[0];	//发送bit0
						4'd2: rs232_tx_r <= tx_data[1];	//发送bit1
						4'd3: rs232_tx_r <= tx_data[2];	//发送bit2
						4'd4: rs232_tx_r <= tx_data[3];	//发送bit3
						4'd5: rs232_tx_r <= tx_data[4];	//发送bit4
						4'd6: rs232_tx_r <= tx_data[5];	//发送bit5
						4'd7: rs232_tx_r <= tx_data[6];	//发送bit6
						4'd8: rs232_tx_r <= tx_data[7];	//发送bit7
						4'd9: rs232_tx_r <= 1'b1;	//发送结束位
					 	default: rs232_tx_r <= 1'b1;
						endcase
				end
			else if(num==4'd11) num <= 4'd0;	//复位
		end
end

assign rs232_tx = rs232_tx_r;

endmodule


