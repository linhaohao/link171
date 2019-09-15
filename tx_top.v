`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:51:26 03/03/2017 
// Design Name: 
// Module Name:    tx_module 
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
module tx_top(
	input clk_5m,
	input clk_50m,
	input clk_200m,
	input cfg_rst,
	
	input dac_data_clk_buf,
	input slot_interrupt,
	input slot_start_count,//接收到dac返回的SPI结束信号，就将slot_start_count置1，且之后一直是1

	input send_start,
	input dac_spi_end,
	input dsp_start_send,//MCBSB0口接收到32bit数据符合32'h66669999就开始接收数据,置1之后一直为1
	input [31:0] send_data,
	
	output reg clk_25kHz,
	output reg [13:0] read_addr,



	output [31:0] loop_data,
	output  reg dac_tx_en,
	
	output [17:0] dac_out,
	output [255:0] debug_1,
	output [255:0] debug_2,
	output [255:0] debug_3
	
    );

assign dac_out = fpga_dac_data_reg_dl; 
assign loop_data = loop_data_reg;
//assign dac_tx_en = dac_tx_en_dl3[0];
reg [15:0] tx_i_data;
reg [15:0] tx_q_data;
reg dac_tx_en_dl;
reg [3:0] dac_tx_en_dl3;
reg [31:0] loop_data_reg;
wire rdy;
reg [14:0] count;
reg [14:0] count2;
reg [14:0] count_50k;
wire [2:0] tx_addr;
reg [6:0] addra;
reg clk_50kHz;
reg [15:0] tx_i_data_reg;
reg [15:0] tx_q_data_reg;
reg [2:0] count3;
wire [31:0] douta;
reg send_en_reg;
reg send_en_regdl2;
reg send_en_regdl3;
//wire [31:0] send_data; for debug
//reg [13:0] read_addr; for debug
reg send_start_reg;
reg [4:0] send_start_dl;
reg start;
reg send_en;
reg start_count;
reg clk_25MHz;


/////////////////////////link16/////////////
reg [7:0] ram_waddr;
reg [8:0] ram_raddr;
reg       ram_wr_en;
reg       ram_red_en;
reg  [35:0] ram_wr_data;
wire [17:0] ram_red_data;
reg [4:0] ram_wr_en_dl;
reg [4:0] ram_rd_en_dl;
reg [17:0]fpga_dac_data_reg;
reg [17:0]fpga_dac_data_reg_dl;
////////////////////////////////////////////
///////////////50kHz clk generate////////////
always@(posedge clk_50m or posedge cfg_rst)
begin
	  if(cfg_rst) begin
	  	count_50k <= 15'd0;
	  end
	  else if(count_50k == 15'd499)begin
	  	count_50k <= 15'd0;
	  end
	  else if(slot_start_count)begin
	  	count_50k <= count_50k + 15'd1;
	  end
	  else begin
	  	count_50k <= 15'd0;
	  end
end

always@(posedge clk_50m or posedge cfg_rst)
begin
	  if(cfg_rst) begin
	  	clk_50kHz <= 1'b0;
	  end
	  else if(count_50k == 15'd499)begin
	  	clk_50kHz <= !clk_50kHz;
	  end
	  else begin
	  	clk_50kHz <= clk_50kHz;
	  end
end
///////////////////////////////////////////////////
///////////////25kHz clk generate//////////////////
always@(posedge clk_50m or posedge cfg_rst)
begin
	  if(cfg_rst) begin
	  	count <= 15'd0;
	  end
	  else if(count == 15'd999)begin
	  	count <= 15'd0;
	  end
	  else if(slot_start_count)begin
	  	count <= count + 15'd1;
	  end
	  else begin
	  	count <= 15'd0;
	  end
end

always@(posedge clk_50m or posedge cfg_rst)
begin
	  if(cfg_rst) begin
	  	clk_25kHz <= 1'b0;
	  end
	  else if(count == 15'd999)begin
	  	clk_25kHz <= !clk_25kHz;
	  end
	  else begin
	  	clk_25kHz <= clk_25kHz;
	  end
end
///////////////25MHz clk generate///////////////


always@(posedge clk_50m or posedge cfg_rst)
begin
	  if(cfg_rst) begin
	  	clk_25MHz <= 1'b0;
	  end
	  else begin
	  	clk_25MHz <= !clk_25MHz;
	  end
end
///////////////////////////////////////////////////

///////////////////////////////////////////////////
reg send_dl;

always@(posedge clk_25kHz or posedge cfg_rst) begin
		if(cfg_rst) begin
				read_addr <= 14'b0;
		end
		else if(read_addr == 14'd1259)begin
				read_addr <= 14'd6000;
		end
		else if(read_addr == 14'd7259)begin
				read_addr <= 14'd0;
		end
		else if(send_en)begin
				read_addr <= read_addr + 14'd1;
		end
		else begin
				read_addr <= read_addr;
		end
end

always@(posedge clk_50m or posedge cfg_rst) begin
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

always@(posedge clk_25kHz or posedge cfg_rst) begin
		if(cfg_rst) begin
				send_start_dl <= 5'd0;
		end
		else begin
				send_start_dl <= {send_start_dl[3:0],send_start_reg};
		end
end


always@(posedge clk_25kHz or posedge cfg_rst) begin
		if(cfg_rst) begin
				start <= 1'b0;
		end
		else if((send_start_dl[1:0] == 2'b01)||(send_start_dl[1:0] == 2'b10))begin
				start <= 1'b1;//持续两个25khz时钟周期
		end
		else begin
				start <= 1'b0;
		end
end

always@(posedge clk_25kHz or posedge cfg_rst) begin
		if(cfg_rst) begin
				send_en <= 1'b0;
		end
		else if((read_addr == 14'd1259) || (read_addr == 14'd7259))begin
				send_en <= 1'b0;
		end
		else if(start)begin
				send_en <= 1'b1;
		end
		else begin
				send_en <= send_en;
		end
end
always@(posedge clk_25kHz or posedge cfg_rst) begin
		if(cfg_rst) begin
				send_en_reg <= 1'b0;
		end
		else begin
				send_en_reg <= send_en;
		end
end

reg signed [15:0] rem_i_data;
always@(posedge clk_25kHz or posedge cfg_rst) begin
		if(cfg_rst) begin
				tx_i_data_reg <= 16'b0;
				tx_q_data_reg <= 16'b0;
		end
		else if(send_en_reg)begin
				tx_i_data_reg <= send_data[15:0];
				tx_q_data_reg <= send_data[31:16];
		end
		else begin
				tx_i_data_reg <= 16'b0;
				tx_q_data_reg <= 16'b0;
		end			
end

/////////////////////////////////tx_i_data_detect//////////////



always@(posedge clk_50kHz or posedge cfg_rst) begin
		if(cfg_rst) begin
				start_count <= 1'b0;
		end
		else if(send_en) begin
				start_count <= 1'b1;
		end
		else  begin
				start_count <= start_count;
		end
end


always@(posedge clk_50kHz or posedge cfg_rst) begin
	if(cfg_rst) begin
			count3 <= 3'd0;
	end
	else if(count3 == 3'd1)begin
			count3 <= 3'd0;
	end
	else if(start_count)begin
			count3 <= count3 + 3'd1;
	end
	else begin
			count3 <= 3'd0;
	end
end 

always@(posedge clk_50kHz or posedge cfg_rst) begin
		if(cfg_rst) begin
				tx_i_data <= 16'b0;
				tx_q_data <= 16'b0;
		end
		else if(count3 == 3'd0)begin
				tx_i_data <= tx_i_data_reg;
				tx_q_data <= tx_q_data_reg;
		end
		else begin
				tx_i_data <= 16'd0;
				tx_q_data <= 16'd0;	
		end			
end
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
//////////////////////////////////////////////////////////////////////
reg [35:0] tx_data_reg;
reg dl_data_dac_window;
reg tx_end_reg;
reg [24:0] count_end;
reg tx_end;
		
/////////////////////////tx_rc_filter///////output data_rate 50k//////////////
//==============================================================
//==============================================================
wire tx_rc_rdy;
reg  tx_cic1_en;
reg  tx_cic1_en_dl;
wire [31:0] dout_rc_i;
wire [31:0] dout_rc_q;
wire [17:0] dout_rc_i_rnd;
wire [17:0] dout_rc_q_rnd;
wire [15:0] tx_cic1_i;
wire [15:0] tx_cic1_q;
//==============================================================
tx_rc_shape tx_rc_inst (                     //成型滤波器
	.sclr(fir_rst), // input sclr
	.clk(clk_50m), // input clk
	.ce(1'b1), // input ce
	.nd(1'b1), // input nd
	.rfd(), // output rfd
	.rdy(tx_rc_rdy), // output rdy
	.din_1(tx_i_data), // input [15 : 0] din_1
	.din_2(tx_q_data), // input [15 : 0] din_2
	.dout_1(dout_rc_i), // output [31 : 0] dout_1
	.dout_2(dout_rc_q)); // output [31 : 0] dout_2	
	

rnd #
  (     
    .IN_WIDTH     ( 32 ),  //32
    .RND_WIDTH    ( 14)   //14
 )
  u1_rnd 
  (                                                   
    .clk    ( clk_50m ),
    .rst    ( fir_rst  ),
    .din_i  ( dout_rc_i   ),
    .din_q  ( dout_rc_q   ),
                                       
    .dout_i ( dout_rc_i_rnd),
    .dout_q ( dout_rc_q_rnd )
   );
   
   
  sat #
   (     
     .IN_WIDTH    ( 18 ),//18
     .SAT_WIDTH   ( 2 ) //2
   ) 
   u1_sat
   (                                                    
     .clk   ( clk_50m ),
     .rst   ( fir_rst  ),
     .din_i ( dout_rc_i_rnd ),
     .din_q ( dout_rc_q_rnd ),
            
     .dout_i( tx_cic1_i ),
     .dout_q( tx_cic1_q )
    );   
always@(posedge clk_50m or posedge cfg_rst) begin
		if(cfg_rst) begin
			tx_cic1_en 		<= 1'b0;
			tx_cic1_en_dl <= 1'b0;
		end
		else begin
			tx_cic1_en_dl <= tx_rc_rdy;
			tx_cic1_en 		<= tx_cic1_en_dl;		
		end
end
//==============================================================
//==============================================================
wire tx_cic1_rdy;
reg  tx_cic2_en;
reg  tx_cic2_en_dl;
wire [31:0] tx_fir_1_i;
wire [31:0] tx_fir_1_q;
wire [18:0] tx_fir_1_i_rnd;
wire [18:0] tx_fir_1_q_rnd;
wire [15:0] tx_cic2_i;
wire [15:0] tx_cic2_q;
//==============================================================

tx_fir_cic1  tx_fir_1_inst (         //内插4倍，由50k到200k
	.sclr(fir_rst), // input sclr
	.clk(clk_50m), // input clk
	.ce(1'b1), // input ce
	.nd(tx_cic1_en), // input nd
	.rfd(), // output rfd
	.rdy(tx_cic1_rdy), // output rdy
	.din_1(tx_cic1_i), // input [15 : 0] din_1
	.din_2(tx_cic1_q), // input [15 : 0] din_2
	.dout_1(tx_fir_1_i), // output [31 : 0] dout_1
	.dout_2(tx_fir_1_q)); // output [31 : 0] dout_2
	
rnd #
  (     
    .IN_WIDTH     ( 32 ),  //32
    .RND_WIDTH    ( 13 )   //14
 )
  u2_rnd 
  (                                                   
    .clk    ( clk_50m ),
    .rst    ( fir_rst  ),
    .din_i  ( tx_fir_1_i   ),
    .din_q  ( tx_fir_1_q   ),
                                       
    .dout_i ( tx_fir_1_i_rnd ),
    .dout_q ( tx_fir_1_q_rnd )
   );
   
   
  sat #
   (     
     .IN_WIDTH    ( 19 ),//18
     .SAT_WIDTH   ( 3 ) //2
   ) 
   u2_sat
   (                                                    
     .clk   ( clk_50m ),
     .rst   ( fir_rst  ),
     .din_i ( tx_fir_1_i_rnd ),
     .din_q ( tx_fir_1_q_rnd ),
            
     .dout_i( tx_cic2_i ),
     .dout_q( tx_cic2_q )
    );   
always@(posedge clk_50m or posedge cfg_rst) begin
		if(cfg_rst) begin
			tx_cic2_en 		<= 1'b0;
			tx_cic2_en_dl <= 1'b0;
		end
		else begin
			tx_cic2_en_dl <= tx_cic1_rdy;
			tx_cic2_en 		<= tx_cic2_en_dl;		
		end
end
//==============================================================
//==============================================================
wire tx_cic2_rdy;
reg  tx_cic3_en;
reg  tx_cic3_en_dl;
wire [31:0] tx_fir_2_i;
wire [31:0] tx_fir_2_q;
wire [17:0] tx_fir_2_i_rnd;
wire [17:0] tx_fir_2_q_rnd;
wire [15:0] tx_cic3_i;
wire [15:0] tx_cic3_q;
//==============================================================
tx_fir_cic2  tx_fir_2_inst (             //内插5倍，由200k到1m
	.sclr(fir_rst), // input sclr
	.clk(clk_50m), // input clk
	.ce(1'b1), // input ce
	.nd(tx_cic2_en), // input nd
	.rfd(), // output rfd
	.rdy(tx_cic2_rdy), // output rdy
	.din_1(tx_cic2_i), // input [15 : 0] din_1
	.din_2(tx_cic2_q), // input [15 : 0] din_2
	.dout_1(tx_fir_2_i), // output [31 : 0] dout_1
	.dout_2(tx_fir_2_q)  // output [31 : 0] dout_2
	); 

rnd #
  (     
    .IN_WIDTH     ( 32 ),  //32
    .RND_WIDTH    ( 14 )   //14
 )
  u3_rnd 
  (                                                   
    .clk    ( clk_50m ),
    .rst    ( fir_rst  ),
    .din_i  ( tx_fir_2_i   ),
    .din_q  ( tx_fir_2_q   ),
                                       
    .dout_i ( tx_fir_2_i_rnd ),
    .dout_q ( tx_fir_2_q_rnd )
   );
   
   
  sat #
   (     
     .IN_WIDTH    ( 18 ),//18
     .SAT_WIDTH   ( 2 ) //2
   ) 
   u3_sat
   (                                                    
     .clk   ( clk_50m ),
     .rst   ( fir_rst  ),
     .din_i ( tx_fir_2_i_rnd ),
     .din_q ( tx_fir_2_q_rnd ),
            
     .dout_i( tx_cic3_i ),
     .dout_q( tx_cic3_q )
    );   
always@(posedge clk_50m or posedge cfg_rst) begin
		if(cfg_rst) begin
			tx_cic3_en 		<= 1'b0;
			tx_cic3_en_dl <= 1'b0;
		end
		else begin
			tx_cic3_en_dl <= tx_cic2_rdy;
			tx_cic3_en 		<= tx_cic3_en_dl;		
		end
end
//==============================================================
//==============================================================
wire tx_cic3_rdy;
reg  tx_cic4_en;
reg  tx_cic4_en_dl;
wire [31:0] tx_fir_3_i;
wire [31:0] tx_fir_3_q;
wire [17:0] tx_fir_3_i_rnd;
wire [17:0] tx_fir_3_q_rnd;
wire [15:0] tx_cic4_i;
wire [15:0] tx_cic4_q;
//==============================================================
tx_fir_cic3  tx_fir_3_inst (                  //内插5倍，由1m到5m
	.sclr(fir_rst), // input sclr
	.clk(clk_50m), // input clk
	.ce(1'b1), // input ce
	.nd(tx_cic3_en), // input nd
	.rfd(), // output rfd
	.rdy(tx_cic3_rdy), // output rdy
	.din_1(tx_cic3_i), // input [15 : 0] din_1
	.din_2(tx_cic3_q), // input [15 : 0] din_2
	.dout_1(tx_fir_3_i), // output [31 : 0] dout_1
	.dout_2(tx_fir_3_q)); // output [31 : 0] dout_2

rnd #
  (     
    .IN_WIDTH     ( 32 ),  //32
    .RND_WIDTH    ( 14 )   //14
 )
  u4_rnd 
  (                                                   
    .clk    ( clk_50m ),
    .rst    ( fir_rst  ),
    .din_i  ( tx_fir_3_i   ),
    .din_q  ( tx_fir_3_q   ),
                                       
    .dout_i ( tx_fir_3_i_rnd ),
    .dout_q ( tx_fir_3_q_rnd )
   );
   
   
  sat #
   (     
     .IN_WIDTH    ( 18 ),//18
     .SAT_WIDTH   ( 2 ) //2
   ) 
   u4_sat
   (                                                    
     .clk   ( clk_50m ),
     .rst   ( fir_rst  ),
     .din_i ( tx_fir_3_i_rnd ),
     .din_q ( tx_fir_3_q_rnd ),
            
     .dout_i( tx_cic4_i ),
     .dout_q( tx_cic4_q )
    );   
always@(posedge clk_50m or posedge cfg_rst) begin
		if(cfg_rst) begin
			tx_cic4_en 		<= 1'b0;
			tx_cic4_en_dl <= 1'b0;
		end
		else begin
			tx_cic4_en_dl <= tx_cic3_rdy;
			tx_cic4_en 		<= tx_cic4_en_dl;		
		end
end
//==============================================================
//==============================================================
wire tx_cic4_rdy;
reg  tx_out_en;
reg  tx_out_en_dl;
wire [31:0] tx_fir_4_i;
wire [31:0] tx_fir_4_q;
wire [19:0] tx_fir_4_i_rnd;
wire [19:0] tx_fir_4_q_rnd;
wire [17:0] tx_i;
wire [17:0] tx_q;
//==============================================================
tx_fir_cic4  tx_fir_4_inst (                          //内插5倍，由5m到25m
	.sclr(fir_rst), // input sclr
	.clk(clk_50m), // input clk
	.ce(1'b1), // input ce
	.nd(tx_cic4_en), // input nd
	.rfd(), // output rfd
	.rdy(tx_cic4_rdy), // output rdy
	.din_1(tx_cic4_i), // input [15 : 0] din_1
	.din_2(tx_cic4_q), // input [15 : 0] din_2
	.dout_1(tx_fir_4_i), // output [31 : 0] dout_1
	.dout_2(tx_fir_4_q)); // output [31 : 0] dout_2
	
rnd #
  (     
    .IN_WIDTH     ( 32 ),  //32
    .RND_WIDTH    ( 12 )   //14
 )
  u5_rnd 
  (                                                   
    .clk    ( clk_50m ),
    .rst    ( fir_rst  ),
    .din_i  ( tx_fir_4_i   ),
    .din_q  ( tx_fir_4_q   ),
                                       
    .dout_i ( tx_fir_4_i_rnd ),
    .dout_q ( tx_fir_4_q_rnd )
   );
   
   
  sat #
   (     
     .IN_WIDTH    ( 20 ),//18
     .SAT_WIDTH   ( 2 ) //2
   ) 
   u5_sat
   (                                                    
     .clk   ( clk_50m ),
     .rst   ( fir_rst  ),
     .din_i ( tx_fir_4_i_rnd ),
     .din_q ( tx_fir_4_q_rnd ),
            
     .dout_i( tx_i ),
     .dout_q( tx_q )
    ); 
always@(posedge clk_50m or posedge cfg_rst) begin
		if(cfg_rst) begin
			tx_out_en 		<= 1'b0;
			tx_out_en_dl   <= 1'b0;
		end
		else begin
			tx_out_en_dl  <= tx_cic4_rdy;
			tx_out_en 	  <= tx_out_en_dl;		
		end
end
   

always@(posedge clk_50m or posedge cfg_rst) begin
		if(cfg_rst) begin
			tx_end_reg <= 1'b0;
		end
		else if(count_end == 25'd199999)begin
			tx_end_reg <= 1'b0;
		end
		else if((read_addr == 14'd5759) || (read_addr == 14'd11759))begin
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
				
always@(posedge clk_50m or posedge cfg_rst) begin
		if(cfg_rst) begin
				tx_data_reg <= 36'd0;
		end
		else begin
				tx_data_reg <= {tx_q,tx_i};
		end
end
/////////////////////////////////////////////////////////////////////////////
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
always @(posedge clk_50m or posedge cfg_rst) begin
	   if(cfg_rst) begin
	     ram_wr_en_dl <= 5'd0;
	   end
     else begin
	 		 ram_wr_en_dl <= {dl_data_dac_window,ram_wr_en_dl[4:1]};
	 end
end     
//////////////////////////////////////////////////////////////////////////////////

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
always @(posedge dac_data_clk_buf or posedge cfg_rst) begin
	   if(cfg_rst)  
	     ram_rd_en_dl <= 5'd0;
	   else
       ram_rd_en_dl <= {ram_red_en,ram_rd_en_dl[4:1]};
end   
//////////////////////////////////////////////////////////////////////////////////
//// (8) ////
always @(posedge dac_data_clk_buf or posedge cfg_rst) begin
   if(cfg_rst) begin
      dac_tx_en <= 1'd0;
   end		   
   else begin
   	dac_tx_en <= ram_rd_en_dl[3]; 
   end
end	
/////////////////////////////////////////////////////////////////////////////////
/// (9) data I Q 调整，正交                           ////	 
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
always @(posedge dac_data_clk_buf or posedge cfg_rst) begin
   if(cfg_rst) begin
   	  fpga_dac_data_reg_dl <= 18'd0;
   end
   else begin 
      fpga_dac_data_reg_dl <= fpga_dac_data_reg; 
   end
end 


//////////////////////test  i  q/////////////////////////
reg test_iq;
reg [15:0] count_tx;
always@(posedge dac_data_clk_buf or posedge cfg_rst)begin
	if(cfg_rst) begin
			test_iq <= 1'b0;
	end
	else if(ram_rd_en_dl[3])begin
			test_iq <= !test_iq;
	end
	else begin
			test_iq <= test_iq;
	end
end

always@(posedge dac_data_clk_buf or posedge cfg_rst)begin
	if(cfg_rst) begin
			count_tx <= 16'd0;
	end
	else if(dac_tx_en_dl)begin
			count_tx <= count_tx + 16'd1;
	end
	else begin
			count_tx <= 16'd0;
	end
end

reg [13:0] read_addr_check;
reg check_ping_addr;
always@(posedge clk_50m or posedge cfg_rst) begin
		if(cfg_rst) begin
				read_addr_check <= 14'd6000;
		end
		else if(slot_interrupt && send_dl) begin
				read_addr_check <= read_addr;
		end
		else begin
				read_addr_check <= read_addr_check;
		end
end

always@(posedge clk_50m or posedge cfg_rst) begin
		if(cfg_rst) begin
				check_ping_addr <= 1'b0;
		end
		else if(slot_interrupt && send_dl && (read_addr_check == read_addr))begin
				check_ping_addr <= 1'b1;
		end
		else begin
				check_ping_addr <= check_ping_addr;
		end
end




	
//assign debug_1[0] = slot_interrupt;
//assign debug_1[1] = clk_2500Hz;
//assign debug_1[4:2] = send_start_dl[2:0];
//assign debug_1[5] = test;
//assign debug_1[6] = send_start_reg;
//assign debug_1[7] = start;
//assign debug_1[8] = send_en;
//assign debug_1[9] = read_addr[13];
//assign debug_1[10] = send_dl;
//assign debug_1[42:11] = send_data;
//
//assign debug_1[76:43] = dout_rc_i;
//assign debug_1[110:77] = fir_4_i_5;
//assign debug_1[140:123] = dac_data;
//assign debug_1[141] = dac_iq_flag;
//assign debug_1[142] = dac_pdclk_buf;
//assign debug_1[143] = clk_2500Hz;
//assign debug_1[144] = rdy;
//assign debug_1[168:145] = cic_1_i_4;
//assign debug_1[192:169] = cic_1_q_4;
//assign debug_1[217:193] = cic_4_i_5;
//assign debug_1[242:218] = cic_4_q_5;
//assign debug_1[255:243] = read_addr[12:0];
//assign debug_1 [177:145] = dout_rc_i;
//assign debug_1 [210:178] = dout_rc_q;
//assign debug_1 [226:211] = tx_i_data;
//assign debug_1 [229:227] = count3;
//assign debug_1 [230] = clk_10kHz;
assign debug_2[32] = slot_interrupt;
assign debug_2[242:227]   = tx_i_data;
assign debug_2[226:211]   = tx_q_data;

assign debug_2[15:0]      = tx_cic1_q;
assign debug_2[31:16]     = tx_cic2_q;
assign debug_2[48:33]     = tx_cic1_i;
assign debug_2[64:49]     = tx_cic2_i;
assign debug_2[80:65]     = tx_cic3_i;
assign debug_2[96:81]     = tx_cic4_i;
assign debug_2[114:97]    = tx_i;
assign debug_2[132:115]   = tx_q;
assign debug_2[148:133]   = tx_cic3_q;
assign debug_2[164:149]   = tx_cic4_q;




//assign debug_2[196:165] = loop_data_reg;
//assign debug_2[194] = clk_25kHz;
//assign debug_2[195] = clk_50kHz;
//assign debug_2[196] = 0;
assign debug_2[210:197] = read_addr;
//assign debug_2[211] = clk_10kHz;

assign debug_2[243] = start;

//assign debug_2[233:209] = cic_4_i_5;
assign debug_2[255:244] = 0;


//
assign debug_3[6]       = clk_25MHz;
assign debug_3[7]       = clk_50m;
assign debug_3[8]       = dac_data_clk_buf;
assign debug_3[9]       = tx_end;
assign debug_3[34:10]   = count_end;
assign debug_3[35]      = tx_end_reg;
assign debug_3[36]      = tx_out_en;
assign debug_3[37]      = dl_data_dac_window;
assign debug_3[73:38]   = tx_data_reg;
assign debug_3[74]      = ram_wr_en;
assign debug_3[110:75]  = ram_wr_data;
assign debug_3[118:111] = ram_waddr;
assign debug_3[119]     = ram_red_en;
assign debug_3[128:120] = ram_raddr;
assign debug_3[146:129] = ram_red_data;
assign debug_3[164:147] = fpga_dac_data_reg_dl;
assign debug_3[182:165] = tx_i;
assign debug_3[200:183] = tx_q;






//assign debug_3[0] = clk_50kHz;
//assign debug_3[1] = send_en;
//assign debug_3[2] = send_en_reg;
//assign debug_3[3] = send_en_regdl2;
//assign debug_3[4] = send_en_regdl3;
//assign debug_3[5] = start_count;
////assign debug_3[6] = tx_cic5_en;
//assign debug_3[7] = tx_out_en;
//assign debug_3[188:171] = tx_i;
////assign debug_3[25:8] = tx_out_i;
//assign debug_3[26] = dac_data_clk_buf;
//assign debug_3[33:27] = 0;
//assign debug_3[69:34] = tx_data_reg;
//
//assign debug_3[70]    = dl_data_dac_window;
//assign debug_3[71]    = tx_end_reg;
//assign debug_3[96:72] = count_end;
//assign debug_3[97] = tx_end;
//assign debug_3[115] = ram_wr_en;
//assign debug_3[105:98] = ram_waddr;
//assign debug_3[152:117] = ram_wr_data;
//assign debug_3[153] = tx_cic4_rdy;
//assign debug_3[154] = tx_cic3_rdy;
//assign debug_3[155] = tx_cic2_rdy;
//assign debug_3[156] = tx_cic1_rdy;
////assign debug_3[116] = ram_red_en;
////assign debug_3[114:106] = ram_raddr;
////assign debug_3[170:153] = ram_red_data;
//
//
//
//
//
//
////assign debug_3[180:176] = ram_rd_en_dl;
////assign debug_3[198:181] = fpga_dac_data_reg;
//assign debug_3[216:199] = fpga_dac_data_reg_dl;
//assign debug_3[217] = dac_tx_en;
//assign debug_3[235:218] = dac_out;
////assign debug_3[253:236] = tx_out_q;
//assign debug_3[255:254] = 0;


endmodule
