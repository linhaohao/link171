`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:34:58 03/28/2017 
// Design Name: 
// Module Name:    dec_10k 
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
module dec_10k(
		input  clk_200m,
		input  cfg_rst,
		
		input  [15:0] data_i,
		input  [15:0] data_q,
		input  [31:0] loop_data,
		output [15:0] data_200k_i_out,
		output [15:0] data_200k_q_out,
		
		output [255:0] debug_1,
		output [255:0] debug_2

    );


assign data_200k_i_out = dout_end_i;
assign data_200k_q_out = dout_end_q;

//==============================================================
//==============================================================
wire rx_fir1_rdy;
reg  rx_fir2_en;
reg  rx_fir2_en_dl;
wire [33:0] rx_fir_1_i;
wire [33:0] rx_fir_1_q;
wire [17:0] rx_fir_1_i_rnd;
wire [17:0] rx_fir_1_q_rnd;
wire [15:0] rx_fir2_i;
wire [15:0] rx_fir2_q;
//==============================================================
rx_fir_1 rx_fir_1_inst (
	.sclr(cfg_rst), // input sclr
	.clk(clk_200m), // input clk
	.ce(1'b1), // input ce
	.rfd(), // output rfd
	.rdy(rx_fir1_rdy), // output rdy
	.din_1(data_i), // input [15 : 0] din_1
	.din_2(data_q), // input [15 : 0] din_2
	.dout_1(rx_fir_1_i), // output [33 : 0] dout_1
	.dout_2(rx_fir_1_q)); // output [33 : 0] dout_2


rnd #
  (     
    .IN_WIDTH     ( 34 ),  //32
    .RND_WIDTH    ( 16 )   //14
 )
  u1_rnd 
  (                                                   
    .clk    ( clk_200m ),
    .rst    ( cfg_rst  ),
    .din_i  ( rx_fir_1_i   ),
    .din_q  ( rx_fir_1_q   ),
                                       
    .dout_i ( rx_fir_1_i_rnd ),
    .dout_q ( rx_fir_1_q_rnd )
   );
   
   
  sat #
   (     
     .IN_WIDTH    ( 18 ),//18
     .SAT_WIDTH   ( 2 ) //2
   ) 
   u1_sat
   (                                                    
     .clk   ( clk_200m ),
     .rst   ( cfg_rst  ),
     .din_i ( rx_fir_1_i_rnd ),
     .din_q ( rx_fir_1_q_rnd ),
            
     .dout_i( rx_fir2_i ),
     .dout_q( rx_fir2_q )
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
wire [33:0] rx_fir_2_i;
wire [33:0] rx_fir_2_q;
wire [17:0] rx_fir_2_i_rnd;
wire [17:0] rx_fir_2_q_rnd;
wire [15:0] rx_fir3_i;
wire [15:0] rx_fir3_q;
//==============================================================

rx_fir_2 rx_fir_2_inst (
	.sclr(cfg_rst), // input sclr
	.clk(clk_200m), // input clk
	.ce(1'b1), // input ce
	.nd(rx_fir2_en), // input nd
	.rfd(), // output rfd
	.rdy(rx_fir2_rdy), // output rdy
	.din_1(rx_fir2_i), // input [15 : 0] din_1
	.din_2(rx_fir2_q), // input [15 : 0] din_2
	.dout_1(rx_fir_2_i), // output [33 : 0] dout_1
	.dout_2(rx_fir_2_q)); // output [33 : 0] dout_2




rnd #
  (     
    .IN_WIDTH     ( 34 ),  //32
    .RND_WIDTH    ( 16 )   //14
 )
  u2_rnd 
  (                                                   
    .clk    ( clk_200m       ),
    .rst    ( cfg_rst       ),
    .din_i  ( rx_fir_2_i   ),
    .din_q  ( rx_fir_2_q   ),
                                       
    .dout_i ( rx_fir_2_i_rnd ),
    .dout_q ( rx_fir_2_q_rnd )
   );
   
   
  sat #
   (     
     .IN_WIDTH    ( 18 ),//18
     .SAT_WIDTH   ( 2 ) //2
   ) 
   u2_sat
   (                                                    
     .clk   ( clk_200m ),
     .rst   ( cfg_rst  ),
     .din_i ( rx_fir_2_i_rnd ),
     .din_q ( rx_fir_2_q_rnd ),
            
     .dout_i( rx_fir3_i ),
     .dout_q( rx_fir3_q )
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
////////////////////////////////////////////////////////

//==============================================================
//==============================================================
wire rx_fir3_rdy;
reg  rx_fir4_en;
reg  rx_fir4_en_dl;
wire [34:0] rx_fir_3_i;
wire [34:0] rx_fir_3_q;
wire [18:0] rx_fir_3_i_rnd;
wire [18:0] rx_fir_3_q_rnd;
wire [15:0] rx_fir4_i;
wire [15:0] rx_fir4_q;

//==============================================================
rx_fir_3 rx_fir_3_inst (
	.sclr(cfg_rst), // input sclr
	.clk(clk_200m), // input clk
	.ce(1'b1), // input ce
	.nd(rx_fir3_en), // input nd
	.rfd(), // output rfd
	.rdy(rx_fir3_rdy), // output rdy
	.din_1(rx_fir3_i), // input [15 : 0] din_1   35
	.din_2(rx_fir3_q), // input [15 : 0] din_2   35
	.dout_1(rx_fir_3_i), // output [34 : 0] dout_1
	.dout_2(rx_fir_3_q)); // output [34 : 0] dout_2


rnd #
  (     
    .IN_WIDTH     ( 35 ),  //32
    .RND_WIDTH    ( 16 )   //14
  )
  u3_rnd 
  (                                                   
    .clk    ( clk_200m       ),
    .rst    ( cfg_rst       ),
    .din_i  ( rx_fir_3_i   ),
    .din_q  ( rx_fir_3_q   ),
                                       
    .dout_i ( rx_fir_3_i_rnd ),
    .dout_q ( rx_fir_3_q_rnd )
   );
   
   
  sat #
   (     
     .IN_WIDTH    ( 19 ),//18
     .SAT_WIDTH   ( 3 ) //2
   ) 
   u3_sat
   (                                                    
     .clk   ( clk_200m       ),
     .rst   ( cfg_rst       ),
     .din_i ( rx_fir_3_i_rnd ),
     .din_q ( rx_fir_3_q_rnd ),
            
     .dout_i( rx_fir4_i     ),
     .dout_q( rx_fir4_q     )
    );   

always@(posedge clk_200m or posedge cfg_rst) begin
		if(cfg_rst) begin
				rx_fir4_en    <= 1'b0;	
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
reg  rx_fir_hb_en;
reg  rx_fir_hb_en_dl;
wire [34:0] rx_fir_4_i;
wire [34:0] rx_fir_4_q;
wire [18:0] rx_fir_4_i_rnd;
wire [18:0] rx_fir_4_q_rnd;
wire [15:0] rx_firhb_i;
wire [15:0] rx_firhb_q;
//==============================================================
rx_fir_4 rx_fir_4_inst (
	.sclr(cfg_rst), // input sclr
	.clk(clk_200m), // input clk
	.ce(1'b1), // input ce
	.nd(rx_fir4_en), // input nd
	.rfd(), // output rfd
	.rdy(rx_fir4_rdy), // output rdy
	.din_1(rx_fir4_i), // input [15 : 0] din_1   35
	.din_2(rx_fir4_q), // input [15 : 0] din_2   35
	.dout_1(rx_fir_4_i), // output [34 : 0] dout_1
	.dout_2(rx_fir_4_q)); // output [34 : 0] dout_2


rnd #
  (     
    .IN_WIDTH     ( 35 ),  //32
    .RND_WIDTH    ( 16 )   //14
  )
  u4_rnd 
  (                                                   
    .clk    ( clk_200m       ),
    .rst    ( cfg_rst       ),
    .din_i  ( rx_fir_4_i   ),
    .din_q  ( rx_fir_4_q   ),
                                       
    .dout_i ( rx_fir_4_i_rnd ),
    .dout_q ( rx_fir_4_q_rnd )
   );
   
   
  sat #
   (     
     .IN_WIDTH    ( 19 ),//18
     .SAT_WIDTH   ( 3 ) //2
   ) 
   u4_sat
   (                                                    
     .clk   ( clk_200m       ),
     .rst   ( cfg_rst       ),
     .din_i ( rx_fir_4_i_rnd ),
     .din_q ( rx_fir_4_q_rnd ),
            
     .dout_i( rx_firhb_i     ),
     .dout_q( rx_firhb_q     )
    );   
always@(posedge clk_200m or posedge cfg_rst) begin
		if(cfg_rst) begin
				rx_fir_hb_en   <= 1'b0;
				rx_fir_hb_en_dl<= 1'b0;
		end
		else begin
				rx_fir_hb_en_dl  <= rx_fir4_rdy;
				rx_fir_hb_en     <= rx_fir_hb_en_dl;
				
		end
end
//==============================================================
wire [25:0] cic_5_i;
wire [25:0] cic_5_q;
wire cic_5_rdy;

cic_5 cic_5_i_inst (
	.din(rx_firhb_i), // input [15 : 0] din
	.nd(rx_fir_hb_en), // input nd
	.ce(1'b1), // input ce
	.sclr(cfg_rst), // input sclr
	.clk(clk_200m), // input clk
	.dout(cic_5_i), // output [25 : 0] dout
	.rdy(), // output rdy
	.rfd()); // output rfd

cic_5 cic_5_q_inst (
	.din(rx_firhb_q), // input [15 : 0] din
	.nd(rx_fir_hb_en), // input nd
	.ce(1'b1), // input ce
	.sclr(cfg_rst), // input sclr
	.clk(clk_200m), // input clk
	.dout(cic_5_q), // output [25 : 0] dout
	.rdy(cic_5_rdy), // output rdy
	.rfd()); // output rfd	


//=============================================================	
//=============================================================
wire rx_fir_rc_rdy;
wire [33:0] dout_fir_i;
wire [33:0] dout_fir_q;
wire [17:0] dout_fir_i_rnd;
wire [17:0] dout_fir_q_rnd;
wire [15:0] dout_end_i;
wire [15:0] dout_end_q;
rx_fir_rc100k rx_fir_rc200k_inst (
	.sclr(cfg_rst), // input sclr
	.clk(clk_200m), // input clk
	.ce(1'b1), // input ce
	.nd(cic_5_rdy), // input nd
	.rfd(), // output rfd
	.rdy(rx_fir_rc_rdy), // output rdy
	.din_1(cic_5_i[24:9]), // input [15 : 0] din_1
	.din_2(cic_5_q[24:9]), // input [15 : 0] din_2
	.dout_1(dout_fir_i), // output [33 : 0] dout_1
	.dout_2(dout_fir_q)); // output [33 : 0] dout_2



rnd #
  (     
    .IN_WIDTH     ( 34 ),  //32
    .RND_WIDTH    ( 16 )   //14
  )
  u6_rnd 
  (                                                   
    .clk    ( clk_200m       ),
    .rst    ( cfg_rst       ),
    .din_i  ( dout_fir_i   ),
    .din_q  ( dout_fir_q   ),
                                       
    .dout_i ( dout_fir_i_rnd ),
    .dout_q ( dout_fir_q_rnd )
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
     .din_i ( dout_fir_i_rnd ),
     .din_q ( dout_fir_q_rnd ),
            
     .dout_i( dout_end_i     ),
     .dout_q( dout_end_q     )
    );  
    
    
 
   
    
    
//     
 
assign debug_2[15:0]       =   data_i;  
assign debug_2[31:16]      =   data_q; 
assign debug_2[207:192]    =   rx_fir2_i;
assign debug_2[223:208]  	 = 	 rx_fir2_q;
assign debug_2[47:32]      =   rx_fir3_i;      
assign debug_2[63:48]      =   rx_fir3_q;
assign debug_2[111:96]     =   rx_fir4_i;     
assign debug_2[127:112]    =   rx_fir4_q;  
assign debug_2[143:128]    =   rx_firhb_i;
assign debug_2[159:144]    =   rx_firhb_q; 
//assign debug_2[79:64]  	   = 	 rx_hb_i;     
//assign debug_2[95:80]  	   = 	 rx_hb_q;     
assign debug_2[175:160]    =   dout_end_i;
assign debug_2[191:176]  	 = 	 dout_end_q; 
     

////////////////////////////////////////////////
assign debug_1[34:0]          =   rx_fir_1_i; 
assign debug_1[50:35]         =   rx_fir2_i;  
//assign debug_1[78:51]         =   cic_8_i;  
//assign debug_1[106:79]        =   cic_8_q; 
assign debug_1[140:107]       =   rx_fir_2_i;
assign debug_1[156:141]       =   rx_fir3_i;
assign debug_1[182:157]       =   cic_5_i ;
assign debug_1[208:183]       =   cic_5_i ; 
assign debug_1[224:209]       =   rx_fir4_i; 
endmodule
