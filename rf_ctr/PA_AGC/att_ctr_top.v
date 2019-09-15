`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:47:45 12/02/2015 
// Design Name: 
// Module Name:    att_ctr_top 
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
//输入的32位bit数据为iq和路数据，低16bit为i路数据，高16为q路数据；分开做增益，然后再和路
//////////////////////////////////////////////////////////////////////////////////
module att_ctr_top(
input                   clk_50m,            //da时钟，50Mhz
input                   clk_20m,
// input           rst,
//对于串口模块的控制
input			        rv_uart_vld,	//串口输入命令数据标识
input	[63:0]	        rv_uart_data,	//串口输入命令数据

input                   power_en,       //功放静默开

input   [7:0]           power_wr_adr,   //e2prom存入的地址
input   [7:0]           power_wr_data,  //数据即为需要的地址
input   [1:0]           choose_temp,    //温度补偿选择通道  0--正常系数 1--低值系数 2--高值系数
input   [35:0]          freq_rf_ctr_slc,  //频率控制字

output			        uart_send_en,	//发送数据使能
output	[63:0]	        sd_uart_data,	//送出的数据
input  signed [31:0]    data_aa,        //输入的功放数据
input                   din_stat0,      //da数据同步的使能信号
input                   din_stat1,
// input  signed [15:0]    data_bb,
output  reg             dout_stat0,
output  reg             dout_stat1,
output signed [31:0]    data_out    //输出的功率值
    );

wire  signed  [47:0]   data_out_r;
wire  signed  [31:0]   data_out_i,data_out_q;
reg           [6:0]    uart_addr    =   7'd0;
reg           [6:0]    addr_in      =   7'd0;
reg                    sel_coe      =   1'b0;
wire  signed  [15:0]   dout_coe;
reg   signed  [15:0]   dout_coe_r;            //串口直接输去的参数
wire  signed  [15:0]   dout_coe_in;            //串口直接输去的参数
reg           [7:0]   change_num   =   8'd0;  //截取范围控制
reg           [7:0]   change_bit   =   8'd0;  //截取范围控制
reg			          uart_send_en_r = 1'b0;	//发送数据使能
reg	[63:0]	          sd_uart_data_r = 64'd0;	//送出的数据

reg           [7:0]   rd_eprom_adr,rd_eprom_adr_d1;
wire          [7:0]   eprom_addr;
wire          [6:0]   addr_out;
reg                   sel_adr       =   1'b1;
reg                   change_r      =   1'b0;
reg                   change_en     =   1'b0;
wire          [7:0]   select_adr;

//根据不同的通道，来决定实际地址值需要增加的便宜量
assign  select_adr[7:0]     =   (choose_temp[1:0] == 2'd1)  ?   8'd52   :    
                                (choose_temp[1:0] == 2'd2)  ?   8'd104  :   8'd0; 
//根据频率字选择对应的地址值
always @(*) begin
    case(freq_rf_ctr_slc[35:0])
      36'h42A3D70A4 :   rd_eprom_adr     <=      8'd0   ;   //+   select_adr[7:0];
      36'h42B333333 :   rd_eprom_adr     <=      8'd1   ;   //+   select_adr[7:0];
      36'h42C28F5C3 :   rd_eprom_adr     <=      8'd2   ;   //+   select_adr[7:0];
      36'h42D1EB852 :   rd_eprom_adr     <=      8'd3   ;   //+   select_adr[7:0];
      36'h42E147AE1 :   rd_eprom_adr     <=      8'd4   ;   //+   select_adr[7:0];
      36'h42F0A3D71 :   rd_eprom_adr     <=      8'd5   ;   //+   select_adr[7:0];
      36'h430000000 :   rd_eprom_adr     <=      8'd6   ;   //+   select_adr[7:0];
      36'h430F5C28F :   rd_eprom_adr     <=      8'd7   ;   //+   select_adr[7:0];
      36'h431EB851F :   rd_eprom_adr     <=      8'd8   ;   //+   select_adr[7:0];
      36'h432E147AE :   rd_eprom_adr     <=      8'd9   ;   //+   select_adr[7:0];
      36'h433D70A3D :   rd_eprom_adr     <=      8'd10  ;   //+   select_adr[7:0];
      36'h434CCCCCD :   rd_eprom_adr     <=      8'd11  ;   //+   select_adr[7:0];
      36'h435C28F5C :   rd_eprom_adr     <=      8'd12  ;   //+   select_adr[7:0];
      36'h436B851EC :   rd_eprom_adr     <=      8'd13  ;   //+   select_adr[7:0];
      36'h13428F5C3 :   rd_eprom_adr     <=      8'd14  ;   //+   select_adr[7:0];
      36'h1351EB852 :   rd_eprom_adr     <=      8'd15  ;   //+   select_adr[7:0];
      36'h136147AE1 :   rd_eprom_adr     <=      8'd16  ;   //+   select_adr[7:0];
      36'h1370A3D71 :   rd_eprom_adr     <=      8'd17  ;   //+   select_adr[7:0];
      36'h138000000 :   rd_eprom_adr     <=      8'd18  ;   //+   select_adr[7:0];
      36'h23CCCCCCD :   rd_eprom_adr     <=      8'd19  ;   //+   select_adr[7:0];
      36'h23BD70A3D :   rd_eprom_adr     <=      8'd20  ;   //+   select_adr[7:0];
      36'h23AE147AE :   rd_eprom_adr     <=      8'd21  ;   //+   select_adr[7:0];
      36'h239EB851F :   rd_eprom_adr     <=      8'd22  ;   //+   select_adr[7:0];
      36'h238F5C28F :   rd_eprom_adr     <=      8'd23  ;   //+   select_adr[7:0];
      36'h238000000 :   rd_eprom_adr     <=      8'd24  ;   //+   select_adr[7:0];
      36'h2370A3D71 :   rd_eprom_adr     <=      8'd25  ;   //+   select_adr[7:0];
      36'h236147AE1 :   rd_eprom_adr     <=      8'd26  ;   //+   select_adr[7:0];
      36'h2351EB852 :   rd_eprom_adr     <=      8'd27  ;   //+   select_adr[7:0];
      36'h23428F5C3 :   rd_eprom_adr     <=      8'd28  ;   //+   select_adr[7:0];
      36'h233333333 :   rd_eprom_adr     <=      8'd29  ;   //+   select_adr[7:0];
      36'h2323D70A4 :   rd_eprom_adr     <=      8'd30  ;   //+   select_adr[7:0];
      36'h23147AE14 :   rd_eprom_adr     <=      8'd31  ;   //+   select_adr[7:0];
      36'h23051EB85 :   rd_eprom_adr     <=      8'd32  ;   //+   select_adr[7:0];
      36'h22F5C28F6 :   rd_eprom_adr     <=      8'd33  ;   //+   select_adr[7:0];
      36'h22E666666 :   rd_eprom_adr     <=      8'd34  ;   //+   select_adr[7:0];
      36'h634CCCCCD :   rd_eprom_adr     <=      8'd35  ;   //+   select_adr[7:0];
      36'h633D70A3D :   rd_eprom_adr     <=      8'd36  ;   //+   select_adr[7:0];
      36'h632E147AE :   rd_eprom_adr     <=      8'd37  ;   //+   select_adr[7:0];
      36'h631EB851F :   rd_eprom_adr     <=      8'd38  ;   //+   select_adr[7:0];
      36'h630F5C28F :   rd_eprom_adr     <=      8'd39  ;   //+   select_adr[7:0];
      36'h630000000 :   rd_eprom_adr     <=      8'd40  ;   //+   select_adr[7:0];
      36'h62F0A3D71 :   rd_eprom_adr     <=      8'd41  ;   //+   select_adr[7:0];
      36'h62E147AE1 :   rd_eprom_adr     <=      8'd42  ;   //+   select_adr[7:0];
      36'h62D1EB852 :   rd_eprom_adr     <=      8'd43  ;   //+   select_adr[7:0];
      36'h62C28F5C3 :   rd_eprom_adr     <=      8'd44  ;   //+   select_adr[7:0];
      36'h62B333333 :   rd_eprom_adr     <=      8'd45  ;   //+   select_adr[7:0];
      36'h62A3D70A4 :   rd_eprom_adr     <=      8'd46  ;   //+   select_adr[7:0];
      36'h62947AE14 :   rd_eprom_adr     <=      8'd47  ;   //+   select_adr[7:0];
      36'h62851EB85 :   rd_eprom_adr     <=      8'd48  ;   //+   select_adr[7:0];
      36'h6275C28F6 :   rd_eprom_adr     <=      8'd49  ;   //+   select_adr[7:0];
      36'h626666666 :   rd_eprom_adr     <=      8'd50  ;   //+   select_adr[7:0];
      default       :   rd_eprom_adr     <=      8'd0   ;   //+   select_adr[7:0]; 
    endcase
end

e2prom_rom U1_e2prom (
  .clka     (clk_20m            ), // input clka
  .wea      (1'b1               ), // input [0 : 0] wea
  .addra    (power_wr_adr       ), // input [7 : 0] addra
  .dina     (power_wr_data      ), // input [7 : 0] dina
  .clkb     (clk_20m            ), // input clkb
  .addrb    (rd_eprom_adr[7:0]  ), // input [7 : 0] addrb
  .doutb    (eprom_addr[7:0]    )  // output [7 : 0] doutb
);

//串口得到得到16位地址数据
always @(posedge clk_20m) begin   //控制差分信号的命令
    rd_eprom_adr_d1         <=  rd_eprom_adr;
	if(rv_uart_vld && (rv_uart_data[63:32] == 32'h1f1a_0add)) begin //c0 f987 8600 0001 0000 cf
		uart_addr[6:0] 	    <=	rv_uart_data[6:0];
        sel_coe             <=  1'b0;
        sel_adr             <=  rv_uart_data[8];
    end
	else if(rv_uart_vld && (rv_uart_data[63:32] == 32'h1f1a_1add)) begin //c0 f987 8600 0001 0000 cf
        sel_coe             <=  1'b1;
        dout_coe_r[15:0]    <=  rv_uart_data[15:0];
    end
	else if(rv_uart_vld && (rv_uart_data[63:32] == 32'h1f1a_3bbb))
        change_num[7:0]     <=  rv_uart_data[7:0];
	else if(rv_uart_vld && (rv_uart_data[63:0] == 64'h1f1a_3d3d_0000_0000)) begin
        uart_send_en_r      <=  1'b1;
        sd_uart_data_r[63:0]<=  {32'h1f1a_3d3d,25'd0,addr_in[6:0]};
    end
	else if(rv_uart_vld && (rv_uart_data[63:0] == 64'h1f1a_3e3e_0000_0000)) begin
        uart_send_en_r      <=  1'b1;
        sd_uart_data_r[63:0]<=  {32'h1f1a_3e3e,24'd0,change_bit[7:0]};
    end      
//    else if(rd_eprom_adr_d1 != rd_eprom_adr)
//        change_en           <=  1'b1;
//    else if(change_en) begin
//        change_en           <=  1'b0;
//        uart_send_en_r      <=  1'b1;
//        sd_uart_data_r[63:0]<=  {32'h1f1a_3e3e,16'd0,rd_eprom_adr[7:0],eprom_addr[7:0]};
//    end  
    else begin
        uart_addr[6:0]      <=  uart_addr[6:0];
        uart_send_en_r      <=  1'b0;
        change_num[7:0]     <=  change_num[7:0];
    end
end
//变化的地址
always @(*) begin
        addr_in[6:0]        =   uart_addr[6:0];
end
assign  addr_out[6:0]       =   sel_adr  ?  (power_en ? eprom_addr[6:0] : 7'd0) : addr_in[6:0];

//变化的截取范围
always @(*) begin
        change_bit[7:0]    =   change_num[7:0];
end

assign  dout_coe_in[15:0]   =   sel_coe ? dout_coe_r[15:0] : dout_coe[15:0];

//根据串口命令得到增益系数，送入地址得到系数
//地址与增益系数 地址--系数（0--1， 1--0.99。。。99--0.01）
att_rom att_rom_u0 (
  .clka         (clk_50m                ), // input clka
  .addra        (addr_out[6:0]           ), // input [6 : 0] addra
  .douta        (dout_coe[15:0]         ) // output [15 : 0] douta
);

//da数据与AGC增益相乘
// mult_ctr mult_ctr_u0 (
  // .clk          (clk_50m               ), // input clk
  // .a            (data_aa[31:0]         ), // input [7 : 0] a
  // .b            (dout_coe_in[15:0]     ), // input [7 : 0] b
  // .p            (data_out_r[47:0]      ) // output [15 : 0] p
// );

//i、q两路数据分别与系数进行相乘
mult_16_16 mult_i (
  .clk			(clk_50m				), // input clk
  .a			(data_aa[15:0]			), // input [15 : 0] a
  .b			(dout_coe_in[15:0]		), // input [15 : 0] b
  .p			(data_out_i[31:0]		) // output [31 : 0] p
);

mult_16_16 mult_q (
  .clk			(clk_50m				), // input clk
  .a			(data_aa[31:16]			), // input [15 : 0] a
  .b			(dout_coe_in[15:0]		), // input [15 : 0] b
  .p			(data_out_q[31:0]		) // output [31 : 0] p
);
   
   //乘以16位的有符号数，有效数值为15位，截取掉15位即为实际的值
   // 截取范围进行控制
assign  data_out[31:0]  =   (change_bit[7:0] == 8'd0) ? {{data_out_q[31],data_out_q[29:15]},{data_out_i[31],data_out_i[29:15]} }:
                            (change_bit[7:0] == 8'd1) ? {{data_out_q[31],data_out_q[28:14]},{data_out_i[31],data_out_i[28:14]} }:
                            (change_bit[7:0] == 8'd2) ? {{data_out_q[31],data_out_q[27:13]},{data_out_i[31],data_out_i[27:13]} }:
                            (change_bit[7:0] == 8'd3) ? {{data_out_q[31],data_out_q[26:12]},{data_out_i[31],data_out_i[26:12]} }:
                            (change_bit[7:0] == 8'd4) ? {{data_out_q[31],data_out_q[25:11]},{data_out_i[31],data_out_i[25:11]} }:
                            (change_bit[7:0] == 8'd5) ? {{data_out_q[31],data_out_q[24:10]},{data_out_i[31],data_out_i[24:10]} }:
                            (change_bit[7:0] == 8'd6) ? {{data_out_q[31],data_out_q[23:9]} ,{data_out_i[31],data_out_i[23:9]}  }:
                            (change_bit[7:0] == 8'd7) ? {{data_out_q[31],data_out_q[22:8]} ,{data_out_i[31],data_out_i[22:8]}  }:
                            (change_bit[7:0] == 8'd8) ? {{data_out_q[31],data_out_q[30:16]},{data_out_i[31],data_out_i[30:16]} }:
                                                        {{data_out_q[31],data_out_q[29:15]},{data_out_i[31],data_out_i[29:15]} };   
//*******随DA一起的使能信号，延迟一拍，与DA数据进行同步
  always @(posedge clk_50m) begin
        dout_stat0    <=    din_stat0;
        dout_stat1    <=    din_stat1;
  end
  
  assign    uart_send_en        =   uart_send_en_r;
  assign    sd_uart_data[63:0]  =   sd_uart_data_r[63:0];
endmodule
