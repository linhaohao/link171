`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:43:44 05/25/2019 
// Design Name: 
// Module Name:    tx_top_new 
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
module tx_top_new(
	input clk_msk_in,//50mhz
   input clk_5m,
	input clk_50m,
	input clk_200m,
	input cfg_rst,
	
	input dac_data_clk_buf,
	input slot_interrupt,//58ms一次20ns脉宽脉冲，用作时隙中断
	input slot_start_count,//接收到dac返回的SPI结束信号，就将slot_start_count置1，且之后一直是1

	input send_start,
	input dac_spi_end,
	input dsp_start_send,//MCBSB0口接收到32bit数据符合32'h66669999就开始接收数据,置1之后一直为1
	input [31:0] send_data,
	
	output clk_64khz,
	output clk_64_3kHz,
	output clk_64_96khz,//从ping-pong存储器中读取数据的速率,666.67bit/s
	output reg [13:0] read_addr,
	
	output [31:0] loop_data,
	
	output dac_tx_en,
	output [17:0] dac_out,
	
	output [255:0] debug_1,
	output [255:0] debug_2,
	output [255:0] debug_3
    );


//////////////////////////////////////////////////////////////////////////////////
//(0)signals assigment

assign dac_tx_en     = dac_tx_en_reg;
assign dac_out[17:0] = fpga_dac_data_reg_dl[17:0];

//////////////////////////////////////////////////////////////////////////////////
//(1-1)21.33khz时钟产生模块
clk_creater clk_module(
.clk_200m(clk_200m),//in
.clk_50m(clk_50m),

.cfg_rst(cfg_rst),
.slot_start_count(slot_start_count),//接收到dac返回的SPI结束信号，就将slot_start_count置1，且之后一直是1

.clk_64khz(clk_64khz),//out
.clk_64_3khz(clk_64_3khz),//21.33khz
.clk_64_96khz(clk_64_96khz)//666.67hz
);
/////////////////loop_test////////////////////////////
reg fir_start;
reg [29:0] fir_delay;
reg fir_rst;
always@(posedge clk_50m or posedge cfg_rst) begin
		if(cfg_rst) begin
				fir_start <= 1'b0;
		end
		else if(fir_delay == 30'd49999)begin
				fir_start <= 1'b0;
		end
		else if(dac_spi_end)begin//接收到dac返回的SPI结束信号
				fir_start <= 1'b1;
		end
		else begin
				fir_start <= fir_start;
		end
end

always@(posedge clk_50m or posedge cfg_rst) begin
		if(cfg_rst) begin
				fir_delay <= 30'd0;
		end
		else if(fir_delay == 30'd49999)begin
				fir_delay <= 30'd0;
		end
		else if(fir_start)begin
				fir_delay <= fir_delay + 30'd1;
		end
		else begin
				fir_delay <= fir_delay;
		end
end

always@(posedge clk_50m or posedge cfg_rst) begin
		if(cfg_rst) begin
				fir_rst <= 1'b1;
		end
		else if(fir_delay == 30'd49999)begin
				fir_rst <= 1'b0;
		end
		else begin
				fir_rst <= fir_rst;
		end
end
//////////////////////////////////////////////////////////////////////////////////
//(1-2)ping-pong存储器地址生成
//以32bit/1.5ms ~= 666.67hz读取,以32bit为单位进行msk调制，一共40跳，需要60ms
//一个时隙间隔是65ms

parameter read_addr_length = 14'd39;//40个32bit储存空间可以放1280bit

reg send_en;
reg start;
reg [4:0]send_start_dl;
reg send_start_reg;

always@(posedge clk_64_96khz or posedge cfg_rst) begin
		if(cfg_rst) begin
				read_addr[13:0] <= 14'b0;
		end
		else if(read_addr[13:0] == read_addr_length)begin
				read_addr[13:0] <= 14'd6000;
		end
		else if(read_addr[13:0] == (14'd6000+read_addr_length))begin
				read_addr[13:0] <= 14'd0;
		end
		else if(send_en)begin
				read_addr[13:0] <= read_addr[13:0] + 14'd1;
		end
		else begin
				read_addr[13:0] <= read_addr[13:0];
		end
end
always@(posedge clk_64_96khz or posedge cfg_rst) begin
		if(cfg_rst) begin
				send_en <= 1'b0;
		end
		else if((read_addr[13:0] == read_addr_length) || (read_addr[13:0] == (14'd6000+read_addr_length)))begin
				send_en <= 1'b0;
		end
		else if(start)begin
				send_en <= 1'b1;
		end
		else begin
				send_en <= send_en;
		end
end
always@(posedge clk_64_96khz or posedge cfg_rst) begin
		if(cfg_rst) begin
				start <= 1'b0;
		end
		else if((send_start_dl[1:0] == 2'b01)||(send_start_dl[1:0] == 2'b10))begin//根据时隙中断进行反正的寄存器来判断是否来了时隙中断
				start <= 1'b1;
		end
		else begin
				start <= 1'b0;
		end
end
always@(posedge clk_64_96khz or posedge cfg_rst) begin
		if(cfg_rst) begin
				send_start_dl[4:0] <= 5'd0;
		end
		else begin
				send_start_dl[4:0] <= {send_start_dl[3:0],send_start_reg};
		end
end
always@(posedge clk_50m or posedge cfg_rst) begin//这里用50mhz时钟的原因是因为时隙中断也是用的50mhz时钟
	  if(cfg_rst) begin
	  		send_start_reg <= 1'b0;
	  end
	  else if(slot_interrupt & dsp_start_send) begin
	  		send_start_reg <= !send_start_reg;
	  end
	  else begin
	  		send_start_reg <= send_start_reg;
	  end
end

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////(2-1) MSK data in  ////
reg [3:0]data_pulse_reg;
reg clk_64_96khz_reg;
assign clk_64_96khz_pulse = !clk_64_96khz_reg & clk_64_96khz;
always@(posedge clk_200m)
begin
	if(cfg_rst) begin
		clk_64_96khz_reg <= 1'b0;
	end
	else begin
		clk_64_96khz_reg <= clk_64_96khz;
	end
end
always@(posedge clk_200m)
begin
   if (cfg_rst)   begin
      data_pulse_reg[3:0]                <= 4'd0;
   end
   else    begin
      data_pulse_reg[3:0]                <= {data_pulse_reg[2:0],clk_64_96khz_pulse};//bit速率为21.33kbit/s，一跳是1.5ms(666.67hz)间隔
   end
end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//(2-2)21.33khz data rate into MSK

////200M clk output 21.33khz data ////
reg vaild_21k_start;
reg [14:0] div_21k_cnt;
always@(posedge clk_200m)
begin
   if (cfg_rst)   begin  //slot reset
       vaild_21k_start                     <= 1'b0; 
       div_21k_cnt[14:0]                   <= 15'd0;
   end                                   
   else if(data_pulse_reg[0])  begin   //码元速率和比特速率都是21.33k，一跳是1.5ms(666.67hz)间隔
       vaild_21k_start                     <= 1'b1;//vaild_21k_start置1之后一直为1
       div_21k_cnt[14:0]                   <= 15'd0;
   end
   else if(div_21k_cnt[14:0] == 15'd9374)begin  
       div_21k_cnt[14:0]                   <= 15'd0; //21.33kbit/s rate = 9375/200clk
   end                                   
   else if(vaild_21k_start)begin     
       div_21k_cnt[14:0]                   <= div_21k_cnt[14:0] + 15'b1;
   end
end
reg valid_21k_en;
always@(posedge clk_200m)
begin
   if (cfg_rst)   begin  //slot reset
       valid_21k_en                       <= 1'b0; 
   end                                   
   else if(vaild_21k_start && (div_21k_cnt[14:0] == 15'd9374))begin  
       valid_21k_en                       <= 1'b1; ////plus at 21.33k end
   end                                   
   else begin     
       valid_21k_en                       <= 1'b0; 
   end
end
reg [31:0]msk_precode;
always@(posedge clk_200m)
begin
   if (cfg_rst)   begin
      msk_precode[31:0]                  <= 32'd0;
   end
   else if(data_pulse_reg[0])begin
      msk_precode[31:0]                  <= send_data[31:0]; 
   end
   else if(vaild_21k_start && (div_21k_cnt[14:0] == 15'd0)) begin
      msk_precode[31:0]                  <= {msk_precode[30:0],1'b0}; //21.33k only bit into MSK
   end
end
reg msk_precode_reg;
always@(posedge clk_200m)
begin
   if (cfg_rst)   begin
      msk_precode_reg                     <= 1'b0;
   end
   else if(vaild_21k_start && (div_21k_cnt[14:0] == 8'd0))begin 
	   msk_precode_reg                    <= msk_precode[31]; // MSB first,LSB later
   end
end

/////(1.5ms:1.5ms/32bits = 46.875us/bit)
reg [6:0] chip_21k_cnt;
always@(posedge clk_200m)
begin
   if (cfg_rst)   begin
      chip_21k_cnt[6:0]                 <= 7'd0;
   end
   else if(valid_21k_en && (chip_21k_cnt[6:0] == 7'd31)) begin
      chip_21k_cnt[6:0]                 <= 7'd0;  
   end
   else if(valid_21k_en) begin  //from 0-31 1.5ms
      chip_21k_cnt[6:0]                 <= chip_21k_cnt[6:0] + 1'b1; 
   end
end
reg msk_precode_reg_en;
always@(posedge clk_200m)
begin
   if (cfg_rst)   begin
      msk_precode_reg_en                <= 1'b0;
   end
   else if(data_pulse_reg[1:0] == 2'b10) begin
      msk_precode_reg_en                <= 1'b1; //start begin (chip_21k_cnt[6:0] == 7'd0)
   end
   else if(valid_21k_en && (chip_21k_cnt[6:0] < 7'd32)) begin 
      msk_precode_reg_en                <= 1'b1; //1.5ms
	end
   else begin
      msk_precode_reg_en                <= msk_precode_reg_en;
   end
end

//////////////////////////////////////////////////////////////////////////////////
//// (3) MSK modulation ////
wire msk_vaild_ahead;
wire msk_vaild_out;
wire [15:0]msk_i_out;
wire [15:0]msk_q_out;
msk_top u_msk_top(
      //IN
      .clk_msk_in(clk_50m),
      .logic_clk_in(clk_200m),
      .logic_rst_in(cfg_rst),
      .msk_data_in_pulse(msk_precode_reg_en),//一直为1
      .msk_data_in_5M(valid_21k_en),         //plus at 21.33k end
      .msk_data_in(msk_precode_reg),         //msk data in
      .msk_data_cnt(chip_21k_cnt[6:0]),      //有效data计数
      //OUT
      .msk_vaild_ahead(msk_vaild_ahead),
      .msk_vaild_out(msk_vaild_out),         //1.5ms
      .msk_i_out(msk_i_out[15:0]),
      .msk_q_out(msk_q_out[15:0]),
	  //DEBUG
      .debug_msk_signal()
      );

//////////////////////////////////////////////////////////////////////////////////
//// (4) Pulse-shape Filter(1x) ////    MSK output 50M sample which 21.33k data rate
wire tx_cic4_rdy;
reg  tx_cic5_en;
reg  tx_cic5_en_dl;
wire [34:0] tx_fir_4_i;
wire [34:0] tx_fir_4_q;
wire [18:0] tx_fir_4_i_rnd;
wire [18:0] tx_fir_4_q_rnd;
wire [15:0] tx_fir5_i;
wire [15:0] tx_fir5_q;
tx_half_band_shape   tx_half_band_shape //tx coe same with rx half_band1_filter
   (
	.clk(clk_50m),
	.sclr(cfg_rst), 	
	.ce(1'b1),
	.nd(msk_vaild_out),// 50Mchip/s
	.din_1(msk_i_out[15:0]),
	.din_2(msk_q_out[15:0]),
	.dout_1(tx_fir_4_i[34:0]),
	.dout_2(tx_fir_4_q[34:0]),
	.rfd(),                                                           // core is ready for new data
	.rdy(tx_cic4_rdy)   //delay 15clk(50M),every rdy occupy 1.5ms     // filter out is ready	
	);
	
rnd #
  (     
    .IN_WIDTH     ( 35 ),  //35
    .RND_WIDTH    ( 16 )   //15
 )
  u4_rnd 
  (                                                   
    .clk    ( clk_50m ),
    .rst    ( fir_rst  ),
    .din_i  ( tx_fir_4_i[34:0]   ),
    .din_q  ( tx_fir_4_q[34:0]   ),
                                       
    .dout_i ( tx_fir_4_i_rnd[18:0] ),
    .dout_q ( tx_fir_4_q_rnd[18:0] )
   );
   
   
  sat #
   (     
     .IN_WIDTH    ( 19 ),//20
     .SAT_WIDTH   ( 3 ) //2
   ) 
   u4_sat
   (                                                    
     .clk   ( clk_50m ),
     .rst   ( fir_rst  ),
     .din_i ( tx_fir_4_i_rnd[18:0] ),
     .din_q ( tx_fir_4_q_rnd[18:0] ),
            
     .dout_i( tx_fir5_i[15:0] ),
     .dout_q( tx_fir5_q[15:0] )
    ); 
always@(posedge clk_50m or posedge cfg_rst) begin
		if(cfg_rst) begin
			tx_cic5_en 		<= 1'b0;
			tx_cic5_en_dl   <= 1'b0;
		end
		else begin
			tx_cic5_en_dl  <= tx_cic4_rdy;
			tx_cic5_en 	  <= tx_cic5_en_dl;		
		end
end

//////////////////////////////////////////////////////////////////////////////////
//// (5) RC shape fir  ////
wire tx_cic5_rdy;
reg  tx_out_en;
reg  tx_out_en_dl;
wire [31:0] tx_fir_5_i;
wire [31:0] tx_fir_5_q;
wire [19:0] tx_fir_5_i_rnd;
wire [19:0] tx_fir_5_q_rnd;
wire [17:0] tx_i;
wire [17:0] tx_q;
tx_rc_shape_1   tx_rc_shape 
   (
	.clk(clk_50m),
	.sclr(cfg_rst), 	
	.ce(1'b1),
	.nd(tx_cic5_en),
	.din_1(tx_fir5_i[15:0]),
	.din_2(tx_fir5_q[15:0]),
	.dout_1(tx_fir_5_i[31:0]),
	.dout_2(tx_fir_5_q[31:0]),
	.rfd(),
	.rdy(tx_cic5_rdy)
	);
	
rnd #
  (     
    .IN_WIDTH     ( 32 ),  //35
    .RND_WIDTH    ( 12 )   //15
 )
  u5_rnd 
  (                                                   
    .clk    ( clk_50m ),
    .rst    ( fir_rst  ),
    .din_i  ( tx_fir_5_i[31:0]   ),
    .din_q  ( tx_fir_5_q[31:0]   ),
                                       
    .dout_i ( tx_fir_5_i_rnd[19:0] ),
    .dout_q ( tx_fir_5_q_rnd[19:0] )
   );
   
   
  sat #
   (     
     .IN_WIDTH    ( 20 ),//20
     .SAT_WIDTH   ( 2 ) //2
   ) 
   u5_sat
   (                                                    
     .clk   ( clk_50m ),
     .rst   ( fir_rst  ),
     .din_i ( tx_fir_5_i_rnd[19:0] ),
     .din_q ( tx_fir_5_q_rnd[19:0] ),
            
     .dout_i( tx_i[17:0] ),
     .dout_q( tx_q[17:0] )
    ); 
always@(posedge clk_50m or posedge cfg_rst) begin
		if(cfg_rst) begin
			tx_out_en 		<= 1'b0;
			tx_out_en_dl   <= 1'b0;
		end
		else begin
			tx_out_en_dl  <= tx_cic5_rdy;
			tx_out_en 	  <= tx_out_en_dl;		
		end
end
   
reg tx_end;
reg tx_end_reg;
reg [24:0]count_end;
always@(posedge clk_50m or posedge cfg_rst) begin
		if(cfg_rst) begin
			tx_end_reg <= 1'b0;
		end
		else if(count_end == 25'd199999)begin//持续4ms
			tx_end_reg <= 1'b0;
		end
		else if((read_addr[13:0] == read_addr_length) || (read_addr[13:0] == (14'd6000+read_addr_length)))begin
			tx_end_reg <= 1'b1;
		end
		else begin
			tx_end_reg <= tx_end_reg;
		end
end
always@(posedge clk_50m or posedge cfg_rst) begin
		if(cfg_rst) begin
				count_end <= 25'd0;
		end
		else if(count_end == 25'd199999)begin
			   count_end <= 25'd0;
		end	
		else if(tx_end_reg) begin
				count_end <= count_end + 25'd1;
		end
		else begin
				count_end <= count_end;
		end
end
always@(posedge clk_50m or posedge cfg_rst) begin
		if(cfg_rst) begin
			  tx_end <= 1'b0;
		end
		else if(count_end == 25'd199999)begin
			  tx_end <= 1'b1;
		end	
		else begin
			  tx_end <= 1'b0;
		end
end
reg dl_data_dac_window;
always@(posedge clk_50m or posedge cfg_rst) begin  
		if(cfg_rst) begin
				dl_data_dac_window <= 1'b0;
		end
		else if(tx_end) begin
				dl_data_dac_window <= 1'b0;
		end
		else if(tx_out_en) begin
			   dl_data_dac_window <= 1'b1;
		end
		else begin
				dl_data_dac_window <= dl_data_dac_window;
		end
end
reg [35:0]tx_data_reg;
always@(posedge clk_50m or posedge cfg_rst) begin
		if(cfg_rst) begin
				tx_data_reg <= 36'd0;
		end
		else begin
				tx_data_reg <= {tx_q,tx_i};
		end
end
/////////////////////////////////////////////////////////////////////////////
reg ram_wr_en;
always@(posedge clk_50m or posedge cfg_rst) begin
	   if(cfg_rst) begin
	   	ram_wr_en <= 1'd0;  	
	   end		  			  
     else if(dl_data_dac_window) begin
	      ram_wr_en <= ~ram_wr_en;
	   end
	   else begin
	      ram_wr_en <= 1'd0;
	   end 
end	 
////////////////////////////////////////////////////////////////////////////////
// (2) ram data                         ////	   
reg [35:0]ram_wr_data;
always @(posedge clk_50m or posedge cfg_rst) begin
	   if(cfg_rst) begin
	   	ram_wr_data <= 36'd0;  
	   end
	   else begin
	      ram_wr_data <= tx_data_reg;
	   end
end	

////////////////////////////////////////////////////////////////////////////////
// (3) w addr                        
reg [7:0]ram_waddr;
always @(posedge clk_50m or posedge cfg_rst) begin
	   if(cfg_rst) begin
	      ram_waddr <= 8'd0;
	   end
     else if(dl_data_dac_window)begin
            if(ram_wr_en)
	             ram_waddr <= ram_waddr + 8'd1;
	          else
	             ram_waddr <= ram_waddr;
	   end
	   else begin
	      ram_waddr <= 8'd0;
		 end
end
 ////////////////////////////////////////////////////////////////////////////////
// (4) w en     dl                    ////	 
reg [4:0]ram_wr_en_dl;  
always @(posedge clk_50m or posedge cfg_rst) begin
	   if(cfg_rst) begin
	     ram_wr_en_dl <= 5'd0;
	   end
     else begin
	 	  ram_wr_en_dl <= {dl_data_dac_window,ram_wr_en_dl[4:1]};
	 end
end     
//////////////////////////////////////////////////////////////////////////////////
wire [17:0]ram_red_data;
reg ram_red_en;
reg [8:0]ram_raddr;
data_ram data_ram_inst(
  .clka(clk_50m), // input clka
  .ena(1'b1), // input ena
  .wea(ram_wr_en), // input [0 : 0] wea
  .addra(ram_waddr), // input [7 : 0] addra
  .dina(ram_wr_data), // input [35 : 0] dina
  .clkb(dac_data_clk_buf), // input clkb             AD9957反馈回来的50M时钟
  .enb(ram_red_en), // input enb
  .addrb(ram_raddr), // input [8 : 0] addrb
  .doutb(ram_red_data) // output [17 : 0] doutb
);

/////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
// (*) red en                        ////	   
always@(posedge dac_data_clk_buf or posedge cfg_rst) begin
	   if(cfg_rst)  
	     ram_red_en <= 1'd0;
	   else
        ram_red_en <= ram_wr_en_dl[0];
end 
////////////////////////////////////////////////////////////////////////////////
// (6) R addr                         ////	   

always @(posedge dac_data_clk_buf or posedge cfg_rst) begin
	   if(cfg_rst)
	     ram_raddr <= 9'd0;
	   else if(ram_red_en)
	     ram_raddr <= ram_raddr + 9'd1;
	   else
	     ram_raddr <= 9'd0;
end	

////////////////////////////////////////////////////////////////////////////////
// (7) red en                        ////	   
reg [4:0]ram_rd_en_dl;
always @(posedge dac_data_clk_buf or posedge cfg_rst) begin
	   if(cfg_rst)  
	    ram_rd_en_dl <= 5'd0;
	   else
       ram_rd_en_dl <= {ram_red_en,ram_rd_en_dl[4:1]};
end   
//////////////////////////////////////////////////////////////////////////////////
//// (8) ////
reg dac_tx_en_reg;
always @(posedge dac_data_clk_buf or posedge cfg_rst) begin
   if(cfg_rst) begin
    dac_tx_en_reg <= 1'd0;
   end		   
   else begin
    dac_tx_en_reg <= ram_rd_en_dl[3];
//    dac_tx_en_reg <= 1'd1;
   end
end	
/////////////////////////////////////////////////////////////////////////////////
/// (9) data I Q 调整，正交                           ////	 
reg [17:0]fpga_dac_data_reg;
always @(posedge dac_data_clk_buf or posedge cfg_rst) begin
   if(cfg_rst) begin
   	fpga_dac_data_reg <= 18'd0;
   end
	 else if(ram_rd_en_dl[4]) begin
	   fpga_dac_data_reg <= ram_red_data;
	 end 
	 else begin
      fpga_dac_data_reg <= fpga_dac_data_reg;
   end
end 

/////////////////////////////////////////////////////////////////////////////////
/// (9) data I Q DL                          ////	 
reg [17:0]fpga_dac_data_reg_dl;
always @(posedge dac_data_clk_buf or posedge cfg_rst) begin
   if(cfg_rst) begin
   	fpga_dac_data_reg_dl <= 18'd0;
   end
   else begin 
      fpga_dac_data_reg_dl <= fpga_dac_data_reg;
//      fpga_dac_data_reg_dl <= 18'b011101010101010101;
   end
end 

//////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////
assign debug_1[0] = dac_tx_en_reg;
assign debug_1[18:1] = fpga_dac_data_reg_dl[17:0];
assign debug_1[19] = fir_rst;
assign debug_1[51:20] = send_data[31:0];
assign debug_1[52] = send_start;
assign debug_1[53] = slot_start_count;//接收到dac返回的SPI结束信号，就将slot_start_count置1，且之后一直是1
assign debug_1[54] = start;//检测到时隙中断就给出一个脉冲信号
assign debug_1[57:55] = {clk_64_96khz,clk_64_3khz,clk_64khz};
assign debug_1[58] = dac_data_clk_buf;
assign debug_1[72:59] = read_addr[13:0];
assign debug_1[73] = valid_21k_en;
assign debug_1[106:74] = msk_precode[31:0];
assign debug_1[107] = msk_precode_reg;
assign debug_1[108] = msk_precode_reg_en;
assign debug_1[116:109] = chip_21k_cnt[6:0];
assign debug_1[117] = vaild_21k_start;
assign debug_1[133:118] = msk_i_out[15:0];
assign debug_1[149:134] = msk_q_out[15:0];
assign debug_1[150] = send_en;
assign debug_1[151] = msk_vaild_out;
assign debug_1[152] = msk_vaild_ahead;
assign debug_1[153] = slot_interrupt;

endmodule
