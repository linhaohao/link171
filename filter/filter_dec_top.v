`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:21:22 05/27/2019 
// Design Name: 
// Module Name:    filter_dec_top 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: ½øÐÐ3125±¶³éÈ¡ÂË²¨£¬·Ö5¼¶5±¶½øÐÐ³éÈ¡ÂË²¨£¬200mhz->64khz
//
//////////////////////////////////////////////////////////////////////////////////
module filter_dec_top(
		input  clk_200m,
		input  cfg_rst,
		
		input  [15:0] data_i,//200m sample
		input  [15:0] data_q,
		
		output [15:0] data_64k_i_out,//64k sample
		output [15:0] data_64k_q_out,
		output data_64k_out_en,
		
		output [255:0] debug_1,
		output [255:0] debug_2
    );
	 
//////////////////////////////////////////////////////////////////////////////////
//// parameters define ////


//////////////////////////////////////////////////////////////////////////////////
//// (0) signals assigment ////
assign data_64k_i_out[15:0]  = rx_firhb_i[15:0];
assign data_64k_q_out[15:0]  = rx_firhb_q[15:0];
assign data_64k_out_en       = rx_fir_hb_en;

//////////////////////////////////////////////////////////////////////////////////
//// (1) 3125±¶³éÈ¡ÂË²¨ ////
//==============================================================
wire rx_fir1_rdy;
reg  rx_fir2_en;
reg  rx_fir2_en_dl;
wire [34:0] rx_fir_1_i;
wire [34:0] rx_fir_1_q;
wire [18:0] rx_fir_1_i_rnd;
wire [18:0] rx_fir_1_q_rnd;
wire [15:0] rx_fir2_i;
wire [15:0] rx_fir2_q;
//==============================================================200m->40m
rx_fir_200m rx_fir_1_inst (
	.sclr(cfg_rst), // input sclr
	.clk(clk_200m), // input clk
	.ce(1'b1), // input ce
	.rfd(), // output rfd
	.rdy(rx_fir1_rdy), // output rdy
	.din_1(data_i[15:0]), // input [15 : 0] din_1
	.din_2(data_q[15:0]), // input [15 : 0] din_2
	.dout_1(rx_fir_1_i[34:0]), // output [34 : 0] dout_1
	.dout_2(rx_fir_1_q[34:0])); // output [34 : 0] dout_2


rnd #
  (     
    .IN_WIDTH     ( 35 ),  //35
    .RND_WIDTH    ( 16 )   //16
 )
  u1_rnd 
  (                                                   
    .clk    ( clk_200m ),
    .rst    ( cfg_rst  ),
    .din_i  ( rx_fir_1_i[34:0]   ),
    .din_q  ( rx_fir_1_q[34:0]   ),
                                       
    .dout_i ( rx_fir_1_i_rnd[18:0] ),
    .dout_q ( rx_fir_1_q_rnd[18:0] )
   );
   
   
  sat #
   (     
     .IN_WIDTH    ( 19 ),//19
     .SAT_WIDTH   ( 3 ) //3
   ) 
   u1_sat
   (                                                    
     .clk   ( clk_200m ),
     .rst   ( cfg_rst  ),
     .din_i ( rx_fir_1_i_rnd[18:0] ),
     .din_q ( rx_fir_1_q_rnd[18:0] ),
            
     .dout_i( rx_fir2_i[15:0] ),
     .dout_q( rx_fir2_q[15:0] )
    );  

always@(posedge clk_200m or posedge cfg_rst) begin
		if(cfg_rst) begin
				rx_fir2_en 		<= 1'b0;
				rx_fir2_en_dl <= 1'b0;
		end
		else begin
				rx_fir2_en_dl <= rx_fir1_rdy;
				rx_fir2_en    <= rx_fir2_en_dl;
		end
end
//==============================================================
//==============================================================
wire rx_fir2_rdy;
reg  rx_fir3_en_dl;
reg  rx_fir3_en;
wire [34:0] rx_fir_2_i;
wire [34:0] rx_fir_2_q;
wire [18:0] rx_fir_2_i_rnd;
wire [18:0] rx_fir_2_q_rnd;
wire [15:0] rx_fir3_i;
wire [15:0] rx_fir3_q;
//==============================================================40m->8m

rx_fir_40to8 rx_fir_2_inst (
	.sclr(cfg_rst), // input sclr
	.clk(clk_200m), // input clk
	.ce(1'b1), // input ce
	.nd(rx_fir2_en), // input nd
	.rfd(), // output rfd
	.rdy(rx_fir2_rdy), // output rdy
	.din_1(rx_fir2_i[15:0]), // input [15 : 0] din_1
	.din_2(rx_fir2_q[15:0]), // input [15 : 0] din_2
	.dout_1(rx_fir_2_i[34:0]), // output [34 : 0] dout_1
	.dout_2(rx_fir_2_q[34:0])); // output [34 : 0] dout_2




rnd #
  (     
    .IN_WIDTH     ( 35 ),  //35
    .RND_WIDTH    ( 16 )   //16
 )
  u2_rnd 
  (                                                   
    .clk    ( clk_200m       ),
    .rst    ( cfg_rst       ),
    .din_i  ( rx_fir_2_i[34:0]   ),
    .din_q  ( rx_fir_2_q[34:0]   ),
                                       
    .dout_i ( rx_fir_2_i_rnd[18:0] ),
    .dout_q ( rx_fir_2_q_rnd[18:0] )
   );
   
   
  sat #
   (     
     .IN_WIDTH    ( 19 ),//19
     .SAT_WIDTH   ( 3 ) //3
   ) 
   u2_sat
   (                                                    
     .clk   ( clk_200m ),
     .rst   ( cfg_rst  ),
     .din_i ( rx_fir_2_i_rnd[18:0] ),
     .din_q ( rx_fir_2_q_rnd[18:0] ),
            
     .dout_i( rx_fir3_i[15:0] ),
     .dout_q( rx_fir3_q[15:0] )
    );   

always@(posedge clk_200m or posedge cfg_rst) begin
		if(cfg_rst) begin
				rx_fir3_en 		<= 1'b0;
				rx_fir3_en_dl <= 1'b0;
		end
		else begin
				rx_fir3_en_dl <= rx_fir2_rdy;
				rx_fir3_en    <= rx_fir3_en_dl;
		end
end
//==============================================================
//==============================================================
wire rx_fir3_rdy;
reg  rx_fir4_en_dl;
reg  rx_fir4_en;
wire [34:0] rx_fir_3_i;
wire [34:0] rx_fir_3_q;
wire [18:0] rx_fir_3_i_rnd;
wire [18:0] rx_fir_3_q_rnd;
wire [15:0] rx_fir4_i;
wire [15:0] rx_fir4_q;
//==============================================================8m->1600k

rx_fir_8to1600k rx_fir_3_inst (
	.sclr(cfg_rst), // input sclr
	.clk(clk_200m), // input clk
	.ce(1'b1), // input ce
	.nd(rx_fir3_en), // input nd
	.rfd(), // output rfd
	.rdy(rx_fir3_rdy), // output rdy
	.din_1(rx_fir3_i[15:0]), // input [15 : 0] din_1
	.din_2(rx_fir3_q[15:0]), // input [15 : 0] din_2
	.dout_1(rx_fir_3_i[34:0]), // output [34 : 0] dout_1
	.dout_2(rx_fir_3_q[34:0])); // output [34 : 0] dout_2




rnd #
  (     
    .IN_WIDTH     ( 35 ),  //35
    .RND_WIDTH    ( 16 )   //16
 )
  u3_rnd 
  (                                                   
    .clk    ( clk_200m       ),
    .rst    ( cfg_rst       ),
    .din_i  ( rx_fir_3_i[34:0]   ),
    .din_q  ( rx_fir_3_q[34:0]   ),
                                       
    .dout_i ( rx_fir_3_i_rnd[18:0] ),
    .dout_q ( rx_fir_3_q_rnd[18:0] )
   );
   
   
  sat #
   (     
     .IN_WIDTH    ( 19 ),//19
     .SAT_WIDTH   ( 3 ) //3
   ) 
   u3_sat
   (                                                    
     .clk   ( clk_200m ),
     .rst   ( cfg_rst  ),
     .din_i ( rx_fir_3_i_rnd[18:0] ),
     .din_q ( rx_fir_3_q_rnd[18:0] ),
            
     .dout_i( rx_fir4_i[15:0] ),
     .dout_q( rx_fir4_q[15:0] )
    );   

always@(posedge clk_200m or posedge cfg_rst) begin
		if(cfg_rst) begin
				rx_fir4_en 		<= 1'b0;
				rx_fir4_en_dl <= 1'b0;
		end
		else begin
				rx_fir4_en_dl <= rx_fir3_rdy;
				rx_fir4_en    <= rx_fir4_en_dl;
		end
end
//==============================================================
//==============================================================
wire rx_fir4_rdy;
reg  rx_fir5_en_dl;
reg  rx_fir5_en;
wire [34:0] rx_fir_4_i;
wire [34:0] rx_fir_4_q;
wire [18:0] rx_fir_4_i_rnd;
wire [18:0] rx_fir_4_q_rnd;
wire [15:0] rx_fir5_i;
wire [15:0] rx_fir5_q;
//==============================================================1600k->320k

rx_fir_1600to320k rx_fir_4_inst (
	.sclr(cfg_rst), // input sclr
	.clk(clk_200m), // input clk
	.ce(1'b1), // input ce
	.nd(rx_fir4_en), // input nd
	.rfd(), // output rfd
	.rdy(rx_fir4_rdy), // output rdy
	.din_1(rx_fir4_i[15:0]), // input [15 : 0] din_1
	.din_2(rx_fir4_q[15:0]), // input [15 : 0] din_2
	.dout_1(rx_fir_4_i[34:0]), // output [34 : 0] dout_1
	.dout_2(rx_fir_4_q[34:0])); // output [34 : 0] dout_2




rnd #
  (     
    .IN_WIDTH     ( 35 ),  //35
    .RND_WIDTH    ( 16 )   //16
 )
  u4_rnd 
  (                                                   
    .clk    ( clk_200m       ),
    .rst    ( cfg_rst       ),
    .din_i  ( rx_fir_4_i[34:0]   ),
    .din_q  ( rx_fir_4_q[34:0]   ),
                                       
    .dout_i ( rx_fir_4_i_rnd[18:0] ),
    .dout_q ( rx_fir_4_q_rnd[18:0] )
   );
   
   
  sat #
   (     
     .IN_WIDTH    ( 19 ),//19
     .SAT_WIDTH   ( 3 ) //3
   ) 
   u4_sat
   (                                                    
     .clk   ( clk_200m ),
     .rst   ( cfg_rst  ),
     .din_i ( rx_fir_4_i_rnd[18:0] ),
     .din_q ( rx_fir_4_q_rnd[18:0] ),
            
     .dout_i( rx_fir5_i[15:0] ),
     .dout_q( rx_fir5_q[15:0] )
    );   

always@(posedge clk_200m or posedge cfg_rst) begin
		if(cfg_rst) begin
				rx_fir5_en 		<= 1'b0;
				rx_fir5_en_dl <= 1'b0;
		end
		else begin
				rx_fir5_en_dl <= rx_fir4_rdy;
				rx_fir5_en    <= rx_fir5_en_dl;
		end
end
//==============================================================
//==============================================================
wire rx_fir5_rdy;
reg  rx_fir6_en_dl;
reg  rx_fir6_en;
wire [34:0] rx_fir_5_i;
wire [34:0] rx_fir_5_q;
wire [18:0] rx_fir_5_i_rnd;
wire [18:0] rx_fir_5_q_rnd;
wire [15:0] rx_fir6_i;
wire [15:0] rx_fir6_q;
//==============================================================320k->64k

rx_fir_320kto64k rx_fir_5_inst (
	.sclr(cfg_rst), // input sclr
	.clk(clk_200m), // input clk
	.ce(1'b1), // input ce
	.nd(rx_fir5_en), // input nd
	.rfd(), // output rfd
	.rdy(rx_fir5_rdy), // output rdy
	.din_1(rx_fir5_i[15:0]), // input [15 : 0] din_1
	.din_2(rx_fir5_q[15:0]), // input [15 : 0] din_2
	.dout_1(rx_fir_5_i[34:0]), // output [34 : 0] dout_1
	.dout_2(rx_fir_5_q[34:0])); // output [34 : 0] dout_2




rnd #
  (     
    .IN_WIDTH     ( 35 ),  //35
    .RND_WIDTH    ( 16 )   //16
 )
  u5_rnd 
  (                                                   
    .clk    ( clk_200m       ),
    .rst    ( cfg_rst       ),
    .din_i  ( rx_fir_5_i[34:0]   ),
    .din_q  ( rx_fir_5_q[34:0]   ),
                                       
    .dout_i ( rx_fir_5_i_rnd[18:0] ),
    .dout_q ( rx_fir_5_q_rnd[18:0] )
   );
   
   
  sat #
   (     
     .IN_WIDTH    ( 19 ),//19
     .SAT_WIDTH   ( 3 ) //3
   ) 
   u5_sat
   (                                                    
     .clk   ( clk_200m ),
     .rst   ( cfg_rst  ),
     .din_i ( rx_fir_5_i_rnd[18:0] ),
     .din_q ( rx_fir_5_q_rnd[18:0] ),
            
     .dout_i( rx_fir6_i[15:0] ),
     .dout_q( rx_fir6_q[15:0] )
    );   

always@(posedge clk_200m or posedge cfg_rst) begin
		if(cfg_rst) begin
				rx_fir6_en 		<= 1'b0;
				rx_fir6_en_dl <= 1'b0;
		end
		else begin
				rx_fir6_en_dl <= rx_fir5_rdy;
				rx_fir6_en    <= rx_fir6_en_dl;
		end
end
//==============================================================
//==============================================================
wire rx_fir6_rdy;
reg  rx_fir_hb_en;
reg  rx_fir_hb_en_dl;
wire [33:0] rx_fir_6_i;
wire [33:0] rx_fir_6_q;
wire [17:0] rx_fir_6_i_rnd;
wire [17:0] rx_fir_6_q_rnd;
wire [15:0] rx_firhb_i;
wire [15:0] rx_firhb_q;
//==============================================================64k RC ¸ùÓàÏÒÂË²¨Æ÷½øÐÐÆ¥ÅäÂË²¨
rx_fir_64k_rc rx_fir_6_inst (
	.sclr(cfg_rst), // input sclr
	.clk(clk_200m), // input clk
	.ce(1'b1), // input ce
	.nd(rx_fir6_en), // input nd
	.rfd(), // output rfd
	.rdy(rx_fir6_rdy), // output rdy
	.din_1(rx_fir6_i[15:0]), // input [15 : 0] din_1   35
	.din_2(rx_fir6_q[15:0]), // input [15 : 0] din_2   35
	.dout_1(rx_fir_6_i[33:0]), // output [33 : 0] dout_1
	.dout_2(rx_fir_6_q[33:0])); // output [33 : 0] dout_2


rnd #
  (     
    .IN_WIDTH     ( 34 ),  //34
    .RND_WIDTH    ( 16 )   //16
  )
  u6_rnd 
  (                                                   
    .clk    ( clk_200m       ),
    .rst    ( cfg_rst       ),
    .din_i  ( rx_fir_6_i[33:0]   ),
    .din_q  ( rx_fir_6_q[33:0]   ),
                                       
    .dout_i ( rx_fir_6_i_rnd[17:0] ),
    .dout_q ( rx_fir_6_q_rnd[17:0] )
   );
   
   
  sat #
   (     
     .IN_WIDTH    ( 18 ),//18
     .SAT_WIDTH   ( 2 ) //2
   ) 
   u6_sat
   (                                                    
     .clk   ( clk_200m       ),
     .rst   ( cfg_rst       ),
     .din_i ( rx_fir_6_i_rnd[17:0] ),
     .din_q ( rx_fir_6_q_rnd[17:0] ),
            
     .dout_i( rx_firhb_i[15:0]     ),
     .dout_q( rx_firhb_q[15:0]     )
    );   
always@(posedge clk_200m or posedge cfg_rst) begin
		if(cfg_rst) begin
				rx_fir_hb_en   <= 1'b0;
				rx_fir_hb_en_dl<= 1'b0;
		end
		else if (rx_fir6_rdy)begin
				rx_fir_hb_en_dl <= 1'b1;
//				rx_fir_hb_en_dl  <= rx_fir6_rdy;
//				rx_fir_hb_en     <= rx_fir_hb_en_dl;
		end
		else begin
				rx_fir_hb_en    <= rx_fir_hb_en_dl;
		end
end
endmodule
