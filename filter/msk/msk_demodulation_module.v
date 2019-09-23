`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:58:47 05/27/2019 
// Design Name: 
// Module Name:    msk_demodulation_module 
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
module msk_demodulation_module(
//// clock/reset ////
input               logic_clk_in,                           // 200MHz logic clock
input               logic_rst_in,
input               clk_20mhz,
input               clk_64khz,
input               clk_64_3khz,

//// data signal ////
input [31:0]        data_msk_in,                            // 64k sample rate
input               data_msk_in_en,

output[31:0]        data_msk_out,                           //MSK解调出的数据
output              data_msk_out_en,                        //每接收32Bit给出一个5ns脉宽的脉冲
output[15:0]        tr_msk_out,                             //用于精同步


output[63:0]        uart_demsk_data,                        //MSK解调出的数据，组装成64bit，用于发送给PC
output              uart_demsk_data_valid,                  //每接收64BIT给出一个50ns脉宽的脉冲
//// debug ////
output[255:0]       debug_signal,
output[255:0]       FM_debug,
input[32:0]			debug_msk
    );




//////////////////////////////////////////////////////////////////////////////////
//// signals declaration ////
// 64kHz时钟周期下，3级延迟正好为一个码元(21.33khz)
wire [15:0]           base_data_i;
wire [15:0]           base_data_q;
reg  [15:0]           base_data_i_delay[0:2];
reg  [15:0]           base_data_q_delay[0:2];
wire [31:0]           mult_result_i;
wire [31:0]           mult_result_q;
wire [32:0]           add_result;
reg                   de_bit                   = 1'b0;
reg  [15:0]           de_data                  = 16'd0;
reg  [31:0]           data_msk_out_reg;

wire [17:0] 	FM_out;
wire 			FM_out_en;
wire 			FM_de_bit;
//////////////////////////////////////////////////////////////////////////////////
//// parameter defination ////

//FM解调模块
// FM_Receive #(18) FM_Receive(
// .logic_rst_in(logic_rst_in),
// .nrst(!logic_rst_in),
// .clk(logic_clk_in),
// .I_in({base_data_i[15:0],2'd0}),
// .Q_in({base_data_q[15:0],2'd0}),
// .in_en(data_msk_in_en),//电平触发，数据有效后一直为高电平
// .FM_out(FM_out[17:0]),
// .FM_out_en(FM_out_en),
// .FM_de_bit(FM_de_bit),
// .debug(FM_debug)
// );

//////////////////////////////////////////////////////////////////////////////////
//// (0) signal assigment ////
assign  data_msk_out[31:0] = data_msk_out_reg[31:0];
assign  data_msk_out_en    = rx_data_valid;
assign  tr_msk_out[15:0]   = de_data[15:0];

assign  base_data_i[15:0]  = data_msk_in[15:0];
assign  base_data_q[15:0]  = data_msk_in[31:16];
//////////////////////////////////////////////////////////////////////////////////
//// (1) delay Ts assigment ////
integer i;
always @(posedge clk_64khz)
begin
    if(logic_rst_in) begin
        for(i = 0; i < 3; i = i + 1)
            begin
            base_data_i_delay[i] <= 16'd0;
            base_data_q_delay[i] <= 16'd0;
            end
    end
    else begin
        base_data_i_delay[0]     <= base_data_i[15:0];
        base_data_q_delay[0]     <= base_data_q[15:0];
        for(i = 1; i < 3; i = i + 1) //delay TS 1.5ms = 3/64hz
            begin
            base_data_i_delay[i] <= base_data_i_delay[i-1];
            base_data_q_delay[i] <= base_data_q_delay[i-1];
            end
    end
end

//////////////////////////////////////////////////////////////////////////////////
//// (2) diff multiply and sum ////
s_mult_16x16 s_mult_16x16_i_inst(
    .clk(logic_clk_in),
    .a(base_data_q[15:0]),        //16-bit
    .b(base_data_i_delay[2]),   // i路延迟的第一个数和q路延迟的qts数相乘
    .p(mult_result_i[31:0])       // 32-bit
);

s_mult_16x16 s_mult_16x16_q_inst(
    .clk(logic_clk_in ),
	.a(base_data_i[15:0]),         
    .b(base_data_q_delay[2]),     
    .p(mult_result_q[31:0])
);
            
s_add_31_31 s_add_31_31_inst(
    .clk(logic_clk_in ),
    .a(mult_result_i[31:0]),   // i - q
    .b(mult_result_q[31:0]),
	.add(1'b0), //sub
    .s(add_result[32:0])
);

//////////////////////////////////////////////////////////////////////////////////
//// (3) decision////
//判决模块，通过对最高位的判决，可将模拟信号，回归为数字单极性，当符号位为1，则此时为负对应0，
//当符号位为0，则此时为正，对应1，因此只需要将高位取反就可以完成判决工作		               
always @(posedge logic_clk_in)
begin
    if(logic_rst_in) begin
        de_bit               <= 1'b0;
        de_data[15:0]        <= 16'd0;
    end                      
    else begin               
		de_bit               <= ~add_result[32];  // 对符号位取反，即为解调的输出
		de_data[15:0]        <= {add_result[32],add_result[29:15]};
    end
end

//////////////////////////////////////////////////////////////////////////////////
//// (4)output freq ctl and rx data 
//一个跳频周期1.5ms开始rx_fh_period_counter计数
reg [19:0] rx_fh_period_counter;
reg rx_data_valid;
reg rx_data_valid_dly;
reg [31:0]rx_data;
//-------------------------------------------------------
always @(posedge logic_clk_in or posedge logic_rst_in)
begin
	if(logic_rst_in)
		rx_fh_period_counter[19:0] <= 20'd0;
	else if(rx_fh_period_counter[19:0] == 20'd299999)
		rx_fh_period_counter[19:0] <= 20'd0;
	else if(data_msk_in_en)
		rx_fh_period_counter[19:0] <= rx_fh_period_counter[19:0] + 20'd1;
end
always @(posedge logic_clk_in or posedge logic_rst_in)
begin
    if(logic_rst_in)
        rx_data_valid <= 1'b0;
    else if(rx_fh_period_counter[19:0] == 20'd299999) //接收完32-bit数据，产生数据有效信号
        rx_data_valid <= 1'b1;
    else
        rx_data_valid <= 1'b0;
end
//-------------------------------------------------------
reg rx_data_valid_count;
reg rx_data_valid_count_reg;
reg [63:0]uart_demsk_data_dl;
assign uart_demsk_data_valid = rx_data_valid_count;  // 每接收完21.33KBIT/S的数据流64BIT，产生一次上升沿
assign uart_demsk_data[63:0] = (rx_data_valid_count & !rx_data_valid_count_reg)?uart_demsk_data_dl[63:0]:uart_demsk_data[63:0];  // 每接收完64bit更新一次
always @(posedge logic_clk_in or posedge logic_rst_in)
begin
    if(logic_rst_in)
        rx_data_valid_count <= 1'b0;
    else if(rx_data_valid) //接收完32-bit数据，产生数据有效信号
        rx_data_valid_count <= rx_data_valid_count + 1'b1;
end
always @(posedge clk_20mhz or posedge logic_rst_in)
begin
    if(logic_rst_in)
        rx_data_valid_count_reg <= 1'b0;
    else
        rx_data_valid_count_reg <= rx_data_valid_count;
end
always @(posedge logic_clk_in or posedge logic_rst_in)
begin
    if(logic_rst_in)
        uart_demsk_data_dl[63:0] <= 64'd0;
    else if(rx_data_valid) //接收完32-bit数据，产生数据有效信号
        uart_demsk_data_dl[63:0] <= {uart_demsk_data_dl[31:0],data_msk_out_reg[31:0]};
end
//-------------------------------------------------------
assign de_bit_in = de_bit;
// assign de_bit_in = FM_de_bit;
always @(posedge logic_clk_in or posedge logic_rst_in)
begin
    if(logic_rst_in)begin
        rx_data[31:0] <= 32'd0;
		  data_msk_out_reg[31:0] <= 32'd0;
	 end
    else  if((rx_fh_period_counter[19:0] >= 20'd0) && (rx_fh_period_counter[19:0] <= 20'd291625))begin
       case(rx_fh_period_counter[19:0])        //MSB first at tx module
         20'd0:         rx_data[31]       <= de_bit_in;  //1bit=46.875us=46.875su*200MZ=9875clk
         20'd9375:      rx_data[30]       <= de_bit_in;
         20'd18750:     rx_data[29]       <= de_bit_in;  
         20'd28125:     rx_data[28]       <= de_bit_in;
         20'd37500:     rx_data[27]       <= de_bit_in;
         20'd46875:     rx_data[26]       <= de_bit_in;  
         20'd56250:     rx_data[25]       <= de_bit_in;
         20'd65625:     rx_data[24]       <= de_bit_in;
         20'd75000:     rx_data[23]       <= de_bit_in;  
         20'd84375:     rx_data[22]       <= de_bit_in;
         20'd93750:     rx_data[21]       <= de_bit_in;
         20'd103125:    rx_data[20]       <= de_bit_in;  
         20'd112500:    rx_data[19]       <= de_bit_in;
         20'd121875:    rx_data[18]       <= de_bit_in;
         20'd131250:    rx_data[17]       <= de_bit_in;  
         20'd140625:    rx_data[16]       <= de_bit_in;
         20'd150000:    rx_data[15]       <= de_bit_in;
         20'd159375:    rx_data[14]       <= de_bit_in;  
         20'd168750:    rx_data[13]       <= de_bit_in;
         20'd178125:    rx_data[12]       <= de_bit_in;
         20'd187500:    rx_data[11]       <= de_bit_in; 
         20'd196875:    rx_data[10]       <= de_bit_in;  
         20'd206250:    rx_data[9]        <= de_bit_in;
         20'd215625:    rx_data[8]        <= de_bit_in;
         20'd225000:    rx_data[7]        <= de_bit_in;  
         20'd234375:    rx_data[6]        <= de_bit_in;
         20'd243750:    rx_data[5]        <= de_bit_in;
         20'd253125:    rx_data[4]        <= de_bit_in;  
         20'd262500:    rx_data[3]        <= de_bit_in;
         20'd271875:    rx_data[2]        <= de_bit_in;
         20'd281250:    rx_data[1]        <= de_bit_in; 
         20'd290625:    rx_data[0]        <= de_bit_in;  
         default:    rx_data[31:0]     <= rx_data[31:0];
       endcase
    end
    else begin
         rx_data[31:0]                 <= rx_data[31:0];
			data_msk_out_reg[31:0]            <= rx_data[31:0];
	 end
end



//////////////////////////////////////////////////////////////////////////////////
assign debug_signal[0] = clk_64khz;
assign debug_signal[1] = clk_64_3khz;
assign debug_signal[33:2] = data_msk_in[31:0];
assign debug_signal[34] = data_msk_in_en;
assign debug_signal[66:35] = data_msk_out[31:0];
assign debug_signal[67] = data_msk_out_en;
assign debug_signal[83:68] = base_data_i[15:0];
assign debug_signal[99:84] = base_data_q[15:0];
assign debug_signal[115:100] = base_data_i_delay[2];
assign debug_signal[131:116] = base_data_q_delay[2];
assign debug_signal[164:132] = add_result[32:0];
assign debug_signal[165] = de_bit;
assign debug_signal[166] = de_bit_in;
assign debug_signal[182:167] = de_data[15:0];
assign debug_signal[215:183] = rx_data[31:0];
assign debug_signal[235:216] = rx_fh_period_counter[19:0];
assign debug_signal[236] = rx_data_valid;



//////////////////////////////////////////////////////////////////////////////////




//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
endmodule
