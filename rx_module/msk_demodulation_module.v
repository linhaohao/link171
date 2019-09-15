//////////////////////////////////////////////////////////////////////////////////
// Company:         StarPoint
// Engineer:        GUO YAN  
// 
// Create Date:     13:40:55 07/24/2015 
// Module Name:     msk_demodulation_module 
// Project Name:    MSK demodulation process module;
// Target Devices:  FPGA - XC7K325T - FFG900; 
// Tool versions:   ISE14.6;  
// Description: 
// 
//
// Revision:        v1.0 - File Created
// Additional Comments: 
//
//
//
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps


module msk_demodulation_module(
//// clock/reset ////
input               logic_clk_in,                           // 200MHz logic clock
input               logic_rst_in,   

//// data signal ////
input [31:0]        data_msk_in,                            // 25Mchips/s

output              data_msk_out,
output[15:0]        tr_msk_out,

//// debug ////
output[127:0]       debug_signal

    );


//////////////////////////////////////////////////////////////////////////////////
//// signals declaration ////
// 200MHz时钟周期下，40级延迟正好为一个码元(200ns)
wire [15:0]           base_data_i;
wire [15:0]           base_data_q;
reg  [15:0]           base_data_i_delay[0:39];
reg  [15:0]           base_data_q_delay[0:39];
wire [31:0]           mult_result_i;
wire [31:0]           mult_result_q;
wire [32:0]           add_result;
reg                   de_bit                   = 1'b0;
reg [15:0]            de_data                  = 16'd0;

//////////////////////////////////////////////////////////////////////////////////
//// parameter defination ////



//////////////////////////////////////////////////////////////////////////////////
//// (0) signal assigment ////
assign  data_msk_out       = de_bit;

assign  tr_msk_out[15:0]   = de_data[15:0];

assign  base_data_i[15:0]  = data_msk_in[15:0];
assign  base_data_q[15:0]  = data_msk_in[31:16];
//////////////////////////////////////////////////////////////////////////////////
//// (1) delay Ts assigment ////
integer i;
always @(posedge logic_clk_in)
begin
    if(logic_rst_in) begin
        for(i = 0; i < 40; i = i + 1)
            begin
            base_data_i_delay[i] <= 16'd0;
            base_data_q_delay[i] <= 16'd0;
            end
    end
    else begin
        base_data_i_delay[0]     <= base_data_i[15:0];
        base_data_q_delay[0]     <= base_data_q[15:0];
        for(i = 1; i < 40; i = i + 1) //delay TS 200ns = 40/200M
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
    .b(base_data_i_delay[39]),   // i路延迟的第一个数和q路延迟的qts数相乘
    .p(mult_result_i[31:0])       // 32-bit
);

s_mult_16x16 s_mult_16x16_q_inst(
    .clk(logic_clk_in ),
	.a(base_data_i[15:0]),         
    .b(base_data_q_delay[39]),     
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
		de_bit               <=  ~add_result[32];  // 对符号位取反，即为解调的输出
		de_data[15:0]        <= {add_result[32],add_result[29:15]};
    end
end



//////////////////////////////////////////////////////////////////////////////////




//////////////////////////////////////////////////////////////////////////////////




//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
endmodule
