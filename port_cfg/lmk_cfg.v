//////////////////////////////////////////////////////////////////////////////////
// Company:        StarPoint
// Engineer:       guanzheye
// Create Date:    2015/9/28 15:48:13 
// Module Name:    LMK CFG
// Project Name:   
// Target Devices: FPGA:
// Tool versions:  
// Description:   

// Revision:       v1.0 - File Created
// Additional Comments: 
//                 完成LMK 上电初始配置
//                 支持回读
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps


module lmk_cfg(
// Clock & Reset    
input               cfg_spi_clk,	                           // 10MHz SPI cfg clk
input               cfg_rst_in,
//
input               spi_rd_stat,
input               spi_rd_en,

input               lmk_int2_stat,

//LMK04806 1
input               lmk_1_spi_start, 
output              lmk04806_1_spi_clk,
output              lmk04806_1_spi_cs,
output              lmk04806_1_spi_sdi,
input               lmk04806_1_spi_sdo,
//LMK04806 2
input               lmk_2_spi_start, 
output              lmk04806_2_spi_clk,
output              lmk04806_2_spi_cs,
output              lmk04806_2_spi_sdi,
input               lmk04806_2_spi_sdo,




//  DSP  wr    
input               spi_single_en        ,  
input               lmk_cfg_valid        ,
input [7:0]         lmk_cfg_addr         ,      
input [31:0]        lmk_cfg_data         ,
output reg[31:0]    lmk_rd_parameter    ,
output reg          lmk_rd_valid  	    ,
// debug
output[63:0]       debug_signal

	 );

//////////////////////////////////////////////////////////////////////////////////
//// parameter ////
parameter LMKCS_LENGTH    = 7'd32;      
//parameter SPI_NUMBER      = 7'd29;



//////////////////////////////////////////////////////////////////////////////////
//// Signal declration ////
// LMK04806    1
wire                lmk04806_1_spi_clk_reg;
wire                lmk04806_1_spi_cs_reg;
wire                lmk04806_1_spi_cs_sdi_reg;

// SPI register 
reg [31:0]          lmk04806_1_reg  = 40'd0;
wire[ 6:0]          lmk04806_1_count;
wire                lmk04806_1_rst_ctl;
//// LMK04806C register ////(28bits data+4bits address)
parameter     lmk04806_1_reg0_rst   = 32'h80160180;
//parameter     lmk04806_1_reg0       = 32'h00140300;//2016/1/8 15:12:12
parameter     lmk04806_1_reg0       = 32'h80140300;

parameter     lmk04806_1_reg1       = 32'h00140181;
parameter     lmk04806_1_reg2       = 32'h00140182;
parameter     lmk04806_1_reg3       = 32'h00140063;
parameter     lmk04806_1_reg4       = 32'h40140024;
//parameter     lmk04806_1_reg5       = 32'h00140485; 10.22
//parameter     lmk04806_1_reg5       = 32'h00140605; //2016/1/8 15:12:43
parameter     lmk04806_1_reg5       = 32'h80140605;

//parameter     lmk04806_1_reg6       = 32'h01110006;//2016/1/8 15:13:15
parameter     lmk04806_1_reg6       = 32'h01000006;

parameter     lmk04806_1_reg7       = 32'h01110007;
//parameter     lmk04806_1_reg8       = 32'h01110008;//2016/1/8 15:13:48
parameter     lmk04806_1_reg8       = 32'h00010008;

parameter     lmk04806_1_reg9       = 32'h55555549;
//parameter     lmk04806_1_reg10      = 32'h91c2410a;//2016/1/8 15:14:22
parameter     lmk04806_1_reg10      = 32'h90c2410a;


parameter     lmk04806_1_reg11      = 32'h040c300b;
parameter     lmk04806_1_reg12      = 32'h0b0c016c;
parameter     lmk04806_1_reg13      = 32'h1300866d;
parameter     lmk04806_1_reg14      = 32'h0030000e;
parameter     lmk04806_1_reg15      = 32'h8010800f;
parameter     lmk04806_1_reg16      = 32'h01550410;
parameter     lmk04806_1_reg17      = 32'h00000058;
parameter     lmk04806_1_reg18      = 32'h3209c419;
parameter     lmk04806_1_reg19      = 32'hafa8001a;
parameter     lmk04806_1_reg20      = 32'h1000005b;
parameter     lmk04806_1_reg21      = 32'h0020015c;
parameter     lmk04806_1_reg22      = 32'h0000031d;
parameter     lmk04806_1_reg23      = 32'h0200031e;
parameter     lmk04806_1_reg24      = 32'h0000001f;
parameter     lmk04806_1_reg25      = 32'h000c300b;
parameter     lmk04806_1_reg26      = 32'h040c300b;
parameter     lmk04806_1_reg27      = 32'h0000003f;



wire[31:0]          lmk04806_1_data_out;
wire                lmk04806_1_data_valid;
//////////////////////////////////////////////////////////////////////////////////
//// Signal declration ////
// LMK04806    2
wire                lmk04806_2_spi_clk_reg;
wire                lmk04806_2_spi_cs_reg;
wire                lmk04806_2_spi_cs_sdi_reg;

// SPI register 
reg [31:0]          lmk04806_2_reg  = 40'd0;
wire[ 6:0]          lmk04806_2_count;
wire                lmk04806_2_rst_ctl;
//// LMK04806C register ////(28bits data+4bits address)
parameter        lmk04806_2_reg0_rst   = 32'h80160180;
//parameter        lmk04806_2_reg0       = 32'h00140320;//2016/1/8 15:14:49
parameter        lmk04806_2_reg0       = 32'h80140320;

//parameter        lmk04806_2_reg1       = 32'h00140321;//2016/1/8 15:15:09
parameter        lmk04806_2_reg1       = 32'h80140321;

//parameter        lmk04806_2_reg2       = 32'h00140142;
parameter        lmk04806_2_reg2       = 32'h80140142;

parameter        lmk04806_2_reg3       = 32'h40140023;
//parameter        lmk04806_2_reg4       = 32'h00140324;//2016/1/8 15:16:24
parameter        lmk04806_2_reg4       = 32'h80140324;

parameter        lmk04806_2_reg5       = 32'h80140325;
//parameter        lmk04806_2_reg6       = 32'h01010006;//2016/1/8 15:16:48
parameter        lmk04806_2_reg6       = 32'h00000006;

//parameter        lmk04806_2_reg7       = 32'h01110007;//2016/1/8 15:17:12
parameter        lmk04806_2_reg7       = 32'h01000007;

//parameter        lmk04806_2_reg8       = 32'h00010008;//2016/1/8 15:17:42
parameter        lmk04806_2_reg8       = 32'h00000008;


parameter        lmk04806_2_reg9       = 32'h55555549;
parameter        lmk04806_2_reg10      = 32'h9002410a;
parameter        lmk04806_2_reg11      = 32'h340c300b;
parameter        lmk04806_2_reg12      = 32'h0b0c016c;
parameter        lmk04806_2_reg13      = 32'h1300866d;
parameter        lmk04806_2_reg14      = 32'h0030000e;
parameter        lmk04806_2_reg15      = 32'h8010800f;
parameter        lmk04806_2_reg16      = 32'h01550410;
parameter        lmk04806_2_reg17      = 32'h00000058;
parameter        lmk04806_2_reg18      = 32'h3209c419;
parameter        lmk04806_2_reg19      = 32'hafa8001a;
parameter        lmk04806_2_reg20      = 32'h1000005b;
parameter        lmk04806_2_reg21      = 32'h0020015c;
parameter        lmk04806_2_reg22      = 32'h0000033d;
parameter        lmk04806_2_reg23      = 32'h0200033e;
parameter        lmk04806_2_reg24      = 32'h0000001f;
parameter        lmk04806_2_reg25      = 32'h300c300b;
parameter        lmk04806_2_reg26      = 32'h340c300b;
parameter        lmk04806_2_reg27      = 32'h0000003f;

wire[31:0]          lmk04806_2_data_out;
wire                lmk04806_2_data_valid;



wire                spi_1_rend;
wire                spi_1_wend;

wire                spi_2_rend;
wire                spi_2_wend;
 reg [31:0]         lmk_wdata_reg;



reg[6:0]            spi_number;
reg                 spi_wr_en;      
reg                 spi_1_stat;
reg                 spi_2_stat;
reg                 lmk_rd_en;


wire [63:0]         lmk_2_debug;
//------------------------------------------------------------------
//由于DSP，二次初始化               2016/1/8 15:52:07
//-----LMK1
parameter           lmk_int2_data1      = 32'h0000001f;
parameter           lmk_int2_data2      = 32'h00140300;  //0x00140300
parameter           lmk_int2_data3      = 32'h00140605;  //0x00140605
parameter           lmk_int2_data4      = 32'h01010006;  //0x01010006
parameter           lmk_int2_data5      = 32'h01010008;  //0x01010008
//parameter           lmk_int2_data6      = 32'h000c300b;  //32'h040c300b;
//parameter           lmk_int2_data7      = 32'h040c300b;  //32'h000c300b;
parameter           lmk_int2_data8      = 32'h0000003f;
//-----LMK2
parameter           lmk2_int2_data1      = 32'h0000001f;
parameter           lmk2_int2_data2      = 32'h00140142;
parameter           lmk2_int2_data3      = 32'h01100007;
parameter           lmk2_int2_data4      = 32'h00140142;
parameter           lmk2_int2_data5      = 32'h01100007;
parameter           lmk2_int2_data6      = 32'h0000003f;
//------------------------------------------------------------------
reg [3:0]  lmk_int2_stat_dl;
reg        lmk_int2_pulse;
reg        lmk_int2_en;



//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//// (0) signal assignment ////
    assign  lmk04806_1_rst_ctl   = cfg_rst_in ; 
	  assign  lmk04806_2_rst_ctl   = cfg_rst_in ; 

//////////////////////////////////////////////////////////////////////////////////
//// (1) SPI chips address decoder ////     
     assign  lmk04806_1_spi_clk  =  lmk04806_1_spi_clk_reg;
     assign  lmk04806_1_spi_cs   =  lmk04806_1_spi_cs_reg;
     assign  lmk04806_1_spi_sdi  =  lmk04806_1_spi_cs_sdi_reg;
     assign  lmk04806_2_spi_clk  =  lmk04806_2_spi_clk_reg;
     assign  lmk04806_2_spi_cs   =  lmk04806_2_spi_cs_reg;
     assign  lmk04806_2_spi_sdi  =  lmk04806_2_spi_cs_sdi_reg;          
     
 //---------------------2016/1/8 16:11:55
always@(negedge cfg_spi_clk or posedge cfg_rst_in)
begin
	    if(cfg_rst_in)
         lmk_int2_stat_dl <= 4'd0;
      else 
         lmk_int2_stat_dl <= {lmk_int2_stat_dl[2:0],lmk_int2_stat};
end 
/////////
always@(negedge cfg_spi_clk or posedge cfg_rst_in)
begin
	    if(cfg_rst_in)
         lmk_int2_pulse <= 1'd0;
      else if(lmk_int2_stat_dl[3:2] == 2'b01)
         lmk_int2_pulse <= 1'd1;
      else
         lmk_int2_pulse <= 1'd0;
end 
/////////
always@(negedge cfg_spi_clk or posedge cfg_rst_in)
begin
	    if(cfg_rst_in)
         lmk_int2_en <= 1'd0;
      else if(spi_1_wend)
         lmk_int2_en <= 1'd0;
      else if(lmk_int2_pulse)
         lmk_int2_en <= 1'd1;
      else
         lmk_int2_en <= lmk_int2_en;
end 


//-------------------------------------------------------   
//////////////////////////////////////////////////////////////////////////////////
//// (*) SPI操作次数，
//always@(negedge cfg_spi_clk )
//begin
//	    if(spi_single_en && (lmk_1_spi_start||lmk_2_spi_start)) //单写
//         spi_number <= 6'd2;
//      else if(lmk_1_spi_start||lmk_2_spi_start) //初始化
//         spi_number <= 6'd28;
//      else if(spi_rd_stat)     //读
//         spi_number <= 6'd25;
//      else
//         spi_number <= spi_number;
//end   

always@(negedge cfg_spi_clk )
begin
	    if(spi_single_en && (lmk_1_spi_start||lmk_2_spi_start)) //单写
         spi_number <= 6'd2;
      else if(lmk_1_spi_start||lmk_2_spi_start) //初始化
         spi_number <= 6'd28;
      else if(lmk_int2_pulse)
         spi_number <= 6'd5;            
      else if(spi_rd_stat)     //读
         spi_number <= 6'd25;
      else
         spi_number <= spi_number;
end   
//////////////////////////////////////////////////////////////////////////////////
//// (*) 单写使能
always@(negedge cfg_spi_clk or posedge cfg_rst_in)
begin
	    if(cfg_rst_in)
	       spi_wr_en <= 1'd0;
	    else if(spi_single_en && (lmk_1_spi_start||lmk_2_spi_start))
         spi_wr_en <= 1'd1;
      else if(spi_1_wend||spi_2_wend)    
   //   else if(spi_1_wend)    
         spi_wr_en <= 1'd0;
      else
         spi_wr_en <= spi_wr_en;
end      
//////////////////////////////////////////////////////////////////////////////////
////(*1) SPI stat select ////
always@(negedge cfg_spi_clk )
begin
//    if(lmk_1_spi_start || spi_rd_stat)  //2016/1/8 16:20:29
    if(lmk_1_spi_start || spi_rd_stat || lmk_int2_pulse)              
      spi_1_stat <= 1'd1;
    else
      spi_1_stat <= 1'd0;
end     
//////////////////////////////////////////////////////////////////////////////////
////(*2) SPI stat select ////
always@(negedge cfg_spi_clk )
begin
    if(lmk_2_spi_start || (spi_rd_en && spi_1_rend)||lmk_int2_pulse)      
      spi_2_stat <= 1'd1;
    else
      spi_2_stat <= 1'd0;
end 
   

//////////////////////////////////////////////////////////////////////////////////
//// (*) spi red
always@(negedge cfg_spi_clk or posedge cfg_rst_in)
begin
	if(cfg_rst_in)begin
		lmk_rd_valid     = 1'd0;
      lmk_rd_parameter = 32'd0;
	 end
  else if(lmk04806_1_data_valid)begin
    lmk_rd_valid     = 1'd1;
    lmk_rd_parameter = lmk04806_1_data_out;  
  end
  else if(lmk04806_2_data_valid)begin
    lmk_rd_valid     = 1'd1;
    lmk_rd_parameter = lmk04806_2_data_out;  
  end
  else begin
  	lmk_rd_valid     = 1'd0;
    lmk_rd_parameter = 32'd0;
  end
end


//////////////////////////////////////////////////////////////////////////////////
//// (*) spi red
always@(negedge cfg_spi_clk or posedge cfg_rst_in)
begin
	if(cfg_rst_in)
     lmk_wdata_reg <= 32'd0;
  else if(lmk_cfg_valid)
     lmk_wdata_reg <= lmk_cfg_data;
  else
     lmk_wdata_reg <= lmk_wdata_reg;
end


//////////////////////////////////////////////////////////////////////////////////
//// (2) ADC LMK04806 1 SPI configuration ////


lmk_spi     U1_lmk1(

     .clk_in                        (cfg_spi_clk               ),
     .rst_in                        (lmk04806_1_rst_ctl        ),
//------------
     .spi_stat                       (spi_1_stat               ),
     .spi_data_in                    (lmk04806_1_reg           ),
     .spi_red_en                     (spi_rd_en                ),
     .spi_wr_en                      (spi_wr_en                ),
     .spi_number                     (spi_number               ),
//
     .spi_clk                        (lmk04806_1_spi_clk_reg   ),
     .spi_cs                         (lmk04806_1_spi_cs_reg    ),	 
     .spi_sdi                        (lmk04806_1_spi_cs_sdi_reg),	 
     .spi_sdo                        (lmk04806_1_spi_sdo       ),

     .spi_wend                       (spi_1_wend               ),    
     .spi_rend                       (spi_1_rend               ),
     
     .spi_data_valid                 (lmk04806_1_data_valid    ),
     .spi_data_out                   (lmk04806_1_data_out      ),
     .spi_count_starte	             (lmk04806_1_count         ), 
     .debug_signal                   (lmk_1_debug              )
);


//// ADC board clock PLL-LMK04806C //// 14 registers
always@(negedge cfg_spi_clk or posedge cfg_rst_in)
begin
  if (cfg_rst_in)   begin
    lmk04806_1_reg[31:0]                  <= 32'd0;
  end
  //  else if(spi_wr_en && lmk_cfg_valid)  //URAT|DSP写数据
  //         lmk04806_1_reg[31:0] <= lmk_cfg_data[31:0] ; 
  else if(spi_wr_en)begin  //URAT|DSP写数据
         case(lmk04806_1_count[6:0])
           7'd0   : lmk04806_1_reg[31:0] <= {11'd0,5'd0,10'd0,6'b011111}; 
           7'd1   : lmk04806_1_reg[31:0] <= lmk_wdata_reg[31:0] ; 
           7'd2   : lmk04806_1_reg[31:0] <= {11'd0,5'd0,10'd0,6'b111111}; 
           default:lmk04806_1_reg[31:0]     <= 32'd0; 
         endcase
  end  
  else if(spi_rd_en)begin
  	 case(lmk04806_1_count[6:0])  //读寄存器     //32bit  ={31:21 , 20:16 addr , 15:6 ,5:0 11111}    
         7'd0   : lmk04806_1_reg[31:0] <= {11'd0,5'd0,10'd0,6'b011111};
         7'd1   : lmk04806_1_reg[31:0] <= {11'd0,5'd1,10'd0,6'b011111};     
         7'd2   : lmk04806_1_reg[31:0] <= {11'd0,5'd2,10'd0,6'b011111};     
         7'd3   : lmk04806_1_reg[31:0] <= {11'd0,5'd3,10'd0,6'b011111};     
         7'd4   : lmk04806_1_reg[31:0] <= {11'd0,5'd4,10'd0,6'b011111};    
         7'd5   : lmk04806_1_reg[31:0] <= {11'd0,5'd5,10'd0,6'b011111};     
         7'd6   : lmk04806_1_reg[31:0] <= {11'd0,5'd6,10'd0,6'b011111};     
         7'd7   : lmk04806_1_reg[31:0] <= {11'd0,5'd7,10'd0,6'b011111};     
         7'd8   : lmk04806_1_reg[31:0] <= {11'd0,5'd8,10'd0,6'b011111};     
         7'd9   : lmk04806_1_reg[31:0] <= {11'd0,5'd9,10'd0,6'b011111};     
         7'd10  : lmk04806_1_reg[31:0] <= {11'd0,5'd10,10'd0,6'b011111};	   
         7'd11  : lmk04806_1_reg[31:0] <= {11'd0,5'd11,10'd0,6'b011111};	    
         7'd12  : lmk04806_1_reg[31:0] <= {11'd0,5'd12,10'd0,6'b011111};	    
         7'd13  : lmk04806_1_reg[31:0] <= {11'd0,5'd13,10'd0,6'b011111};	    
         7'd14  : lmk04806_1_reg[31:0] <= {11'd0,5'd14,10'd0,6'b011111};	    
         7'd15  : lmk04806_1_reg[31:0] <= {11'd0,5'd15,10'd0,6'b011111};	    
         7'd16  : lmk04806_1_reg[31:0] <= {11'd0,5'd16,10'd0,6'b011111};		   
         7'd17  : lmk04806_1_reg[31:0] <= {11'd0,5'd24,10'd0,6'b011111};		   
         7'd18  : lmk04806_1_reg[31:0] <= {11'd0,5'd25,10'd0,6'b011111};		   
         7'd19  : lmk04806_1_reg[31:0] <= {11'd0,5'd26,10'd0,6'b011111};	   
         7'd20  : lmk04806_1_reg[31:0] <= {11'd0,5'd27,10'd0,6'b011111};		   
         7'd21  : lmk04806_1_reg[31:0] <= {11'd0,5'd28,10'd0,6'b011111};	    
         7'd22  : lmk04806_1_reg[31:0] <= {11'd0,5'd29,10'd0,6'b011111};	    
         7'd23  : lmk04806_1_reg[31:0] <= {11'd0,5'd30,10'd0,6'b011111};	    
         7'd24  : lmk04806_1_reg[31:0] <= {11'd0,5'd31,10'd0,6'b011111};	
         7'd25  : lmk04806_1_reg[31:0] <= 32'd0;    
         7'd26  : lmk04806_1_reg[31:0] <= 32'd0;   
         7'd27  : lmk04806_1_reg[31:0] <=	32'd0;   
         7'd28  : lmk04806_1_reg[31:0] <=	32'd0;
      default:lmk04806_1_reg[31:0]     <= 32'd0;   	 
	 endcase
  end  
  //---------------------------------2016/1/8 16:21:46
  else if(lmk_int2_en)begin
          case(lmk04806_1_count[6:0])
               7'd0   : lmk04806_1_reg[31:0]   <= lmk_int2_data1[31:0];
	             7'd1   : lmk04806_1_reg[31:0]   <= lmk_int2_data2[31:0];
	             7'd2   : lmk04806_1_reg[31:0]   <= lmk_int2_data3[31:0];
	             7'd3   : lmk04806_1_reg[31:0]   <= lmk_int2_data4[31:0];
	             7'd4   : lmk04806_1_reg[31:0]   <= lmk_int2_data5[31:0];
	             7'd5   : lmk04806_1_reg[31:0]   <= lmk_int2_data8[31:0];
	          //   7'd6   : lmk04806_1_reg[31:0]   <= lmk_int2_data7[31:0];
	         //    7'd7   : lmk04806_1_reg[31:0]   <= lmk_int2_data8[31:0];
	         default: lmk04806_1_reg[31:0]   <= 32'd0;
	        endcase
	end 
  else   begin
    case(lmk04806_1_count[6:0])    //初始化全写
     7'd0   : lmk04806_1_reg[31:0]   <= lmk04806_1_reg0_rst[31:0];
	   7'd1   : lmk04806_1_reg[31:0]   <= lmk04806_1_reg0[31:0];
	   7'd2   : lmk04806_1_reg[31:0]   <= lmk04806_1_reg1[31:0];
	   7'd3   : lmk04806_1_reg[31:0]   <= lmk04806_1_reg2[31:0];
	   7'd4   : lmk04806_1_reg[31:0]   <= lmk04806_1_reg3[31:0];
	   7'd5   : lmk04806_1_reg[31:0]   <= lmk04806_1_reg4[31:0];
	   7'd6   : lmk04806_1_reg[31:0]   <= lmk04806_1_reg5[31:0];
	   7'd7   : lmk04806_1_reg[31:0]   <= lmk04806_1_reg6[31:0];
	   7'd8   : lmk04806_1_reg[31:0]   <= lmk04806_1_reg7[31:0];
	   7'd9   : lmk04806_1_reg[31:0]   <= lmk04806_1_reg8[31:0];
	   7'd10  : lmk04806_1_reg[31:0]   <= lmk04806_1_reg9[31:0];	   
	   7'd11  : lmk04806_1_reg[31:0]   <= lmk04806_1_reg10[31:0]; 
	   7'd12  : lmk04806_1_reg[31:0]   <= lmk04806_1_reg11[31:0];
	   7'd13  : lmk04806_1_reg[31:0]   <= lmk04806_1_reg12[31:0]; 
	   7'd14  : lmk04806_1_reg[31:0]   <= lmk04806_1_reg13[31:0];  
	   7'd15  : lmk04806_1_reg[31:0]   <= lmk04806_1_reg14[31:0];    
	   7'd16  : lmk04806_1_reg[31:0]   <= lmk04806_1_reg15[31:0];	   
	   7'd17  : lmk04806_1_reg[31:0]   <= lmk04806_1_reg16[31:0];	   
	   7'd18  : lmk04806_1_reg[31:0]   <= lmk04806_1_reg17[31:0];	   
	   7'd19  : lmk04806_1_reg[31:0]   <= lmk04806_1_reg18[31:0];	  
     7'd20  : lmk04806_1_reg[31:0]   <= lmk04806_1_reg19[31:0];	 
	   7'd21  : lmk04806_1_reg[31:0]   <= lmk04806_1_reg20[31:0];        	   
	   7'd22  : lmk04806_1_reg[31:0]   <= lmk04806_1_reg21[31:0];       	   
	   7'd23  : lmk04806_1_reg[31:0]   <= lmk04806_1_reg22[31:0];       	   
	   7'd24  : lmk04806_1_reg[31:0]   <= lmk04806_1_reg23[31:0];       	   
	   7'd25  : lmk04806_1_reg[31:0]   <= lmk04806_1_reg24[31:0];       	   
	   7'd26  : lmk04806_1_reg[31:0]   <= lmk04806_1_reg25[31:0];       	     	   
	   7'd27  : lmk04806_1_reg[31:0]   <=	lmk04806_1_reg26[31:0];  
	   7'd28  : lmk04806_1_reg[31:0]   <=	lmk04806_1_reg27[31:0];  	   
	   default:lmk04806_1_reg[31:0]    <= lmk04806_1_reg0_rst[31:0];	 
	 endcase
  end
end
///////////////////////////////////////////////////////////////////////////

lmk_spi     U2_lmk2(

     .clk_in                        (cfg_spi_clk               ),
     .rst_in                        (lmk04806_2_rst_ctl        ),
//------------
     .spi_stat                       (spi_2_stat               ),
     .spi_data_in                    (lmk04806_2_reg           ),
     .spi_red_en                     (spi_rd_en                ),
     .spi_wr_en                      (spi_wr_en                ),
     .spi_number                     (spi_number               ),
//
     .spi_clk                        (lmk04806_2_spi_clk_reg   ),
     .spi_cs                         (lmk04806_2_spi_cs_reg    ),	 
     .spi_sdi                        (lmk04806_2_spi_cs_sdi_reg),	 
     .spi_sdo                        (lmk04806_2_spi_sdo       ),

     .spi_wend                       (spi_2_wend               ),    
     .spi_rend                       (spi_2_rend               ),
     
     .spi_data_valid                 (lmk04806_2_data_valid    ),
     .spi_data_out                   (lmk04806_2_data_out      ),
     .spi_count_starte	             (lmk04806_2_count         ), 
     .debug_signal                   (lmk_2_debug              )
);

//// ADC board clock PLL-LMK04806C //// 14 registers
always@(negedge cfg_spi_clk or posedge cfg_rst_in)
begin
  if (cfg_rst_in)   begin
    lmk04806_2_reg[31:0]                  <= 40'd0;
  end
  else if(spi_wr_en)begin  //URAT|DSP写数据
         case(lmk04806_2_count[6:0])
           7'd0   : lmk04806_2_reg[31:0] <= {11'd0,5'd0,10'd0,6'b011111}; 
           7'd1   : lmk04806_2_reg[31:0] <= lmk_wdata_reg[31:0] ; 
           7'd2   : lmk04806_2_reg[31:0] <= {11'd0,5'd0,10'd0,6'b111111}; 
           default:lmk04806_2_reg[31:0]     <= 32'd0; 
         endcase
  end  
  else if(spi_rd_en)begin
  	 case(lmk04806_2_count[6:0])
         7'd0   : lmk04806_2_reg[31:0]     <= {11'd0,5'd0,10'd0,6'b011111}; 
         7'd1   : lmk04806_2_reg[31:0]     <= {11'd0,5'd1,10'd0,6'b011111}; 
         7'd2   : lmk04806_2_reg[31:0]     <= {11'd0,5'd2,10'd0,6'b011111}; 
         7'd3   : lmk04806_2_reg[31:0]     <= {11'd0,5'd3,10'd0,6'b011111}; 
         7'd4   : lmk04806_2_reg[31:0]     <= {11'd0,5'd4,10'd0,6'b011111}; 
         7'd5   : lmk04806_2_reg[31:0]     <= {11'd0,5'd5,10'd0,6'b011111}; 
         7'd6   : lmk04806_2_reg[31:0]     <= {11'd0,5'd6,10'd0,6'b011111}; 
         7'd7   : lmk04806_2_reg[31:0]     <= {11'd0,5'd7,10'd0,6'b011111}; 
         7'd8   : lmk04806_2_reg[31:0]     <= {11'd0,5'd8,10'd0,6'b011111}; 
         7'd9   : lmk04806_2_reg[31:0]     <= {11'd0,5'd9,10'd0,6'b011111}; 
         7'd10  : lmk04806_2_reg[31:0]     <= {11'd0,5'd10,10'd0,6'b011111};
         7'd11  : lmk04806_2_reg[31:0]     <= {11'd0,5'd11,10'd0,6'b011111};
         7'd12  : lmk04806_2_reg[31:0]     <= {11'd0,5'd12,10'd0,6'b011111};
         7'd13  : lmk04806_2_reg[31:0]     <= {11'd0,5'd13,10'd0,6'b011111};
         7'd14  : lmk04806_2_reg[31:0]     <= {11'd0,5'd14,10'd0,6'b011111};
         7'd15  : lmk04806_2_reg[31:0]     <= {11'd0,5'd15,10'd0,6'b011111};
         7'd16  : lmk04806_2_reg[31:0]     <= {11'd0,5'd16,10'd0,6'b011111};
         7'd17  : lmk04806_2_reg[31:0]     <= {11'd0,5'd24,10'd0,6'b011111};
         7'd18  : lmk04806_2_reg[31:0]     <= {11'd0,5'd25,10'd0,6'b011111};
         7'd19  : lmk04806_2_reg[31:0]     <= {11'd0,5'd26,10'd0,6'b011111};
         7'd20  : lmk04806_2_reg[31:0]     <= {11'd0,5'd27,10'd0,6'b011111};
         7'd21  : lmk04806_2_reg[31:0]     <= {11'd0,5'd28,10'd0,6'b011111};
         7'd22  : lmk04806_2_reg[31:0]     <= {11'd0,5'd29,10'd0,6'b011111};
         7'd23  : lmk04806_2_reg[31:0]     <= {11'd0,5'd30,10'd0,6'b011111};
         7'd24  : lmk04806_2_reg[31:0]     <= {11'd0,5'd31,10'd0,6'b011111};
         7'd25  : lmk04806_2_reg[31:0]     <= 32'd0;    
         7'd26  : lmk04806_2_reg[31:0]     <= 32'd0;   
         7'd27  : lmk04806_2_reg[31:0]     <=	32'd0;   
         7'd28  : lmk04806_2_reg[31:0]     <=	32'd0;
      default:lmk04806_2_reg[31:0]    <= 32'd0;    	 
	   endcase
  end  
  //---------------------------------2016/1/8 16:21:46
  else if(lmk_int2_en)begin
          case(lmk04806_2_count[6:0])
               7'd0   : lmk04806_2_reg[31:0]   <= lmk2_int2_data1[31:0];
	             7'd1   : lmk04806_2_reg[31:0]   <= lmk2_int2_data2[31:0];
	             7'd2   : lmk04806_2_reg[31:0]   <= lmk2_int2_data3[31:0];
	             7'd3   : lmk04806_2_reg[31:0]   <= lmk2_int2_data4[31:0];
	             7'd4   : lmk04806_2_reg[31:0]   <= lmk2_int2_data5[31:0];
	             7'd5   : lmk04806_2_reg[31:0]   <= lmk2_int2_data6[31:0];
	          //   7'd6   : lmk04806_1_reg[31:0]   <= lmk_int2_data7[31:0];
	         //    7'd7   : lmk04806_1_reg[31:0]   <= lmk_int2_data8[31:0];
	         default: lmk04806_2_reg[31:0]   <= 32'd0;
	        endcase
	end   

  else   begin
    case(lmk04806_2_count[6:0])     //初始化全写
     7'd0   : lmk04806_2_reg[31:0]     <= lmk04806_2_reg0_rst[31:0];
	   7'd1   : lmk04806_2_reg[31:0]     <= lmk04806_2_reg0[31:0];
	   7'd2   : lmk04806_2_reg[31:0]     <= lmk04806_2_reg1[31:0];
	   7'd3   : lmk04806_2_reg[31:0]     <= lmk04806_2_reg2[31:0];
	   7'd4   : lmk04806_2_reg[31:0]     <= lmk04806_2_reg3[31:0];
	   7'd5   : lmk04806_2_reg[31:0]     <= lmk04806_2_reg4[31:0];
	   7'd6   : lmk04806_2_reg[31:0]     <= lmk04806_2_reg5[31:0];
	   7'd7   : lmk04806_2_reg[31:0]     <= lmk04806_2_reg6[31:0];
	   7'd8   : lmk04806_2_reg[31:0]     <= lmk04806_2_reg7[31:0];
	   7'd9   : lmk04806_2_reg[31:0]     <= lmk04806_2_reg8[31:0];
	   7'd10  : lmk04806_2_reg[31:0]     <= lmk04806_2_reg9[31:0];	   
	   7'd11  : lmk04806_2_reg[31:0]     <= lmk04806_2_reg10[31:0]; 
	   7'd12  : lmk04806_2_reg[31:0]     <= lmk04806_2_reg11[31:0];
	   7'd13  : lmk04806_2_reg[31:0]     <= lmk04806_2_reg12[31:0]; 
	   7'd14  : lmk04806_2_reg[31:0]     <= lmk04806_2_reg13[31:0];  
	   7'd15  : lmk04806_2_reg[31:0]     <= lmk04806_2_reg14[31:0];    
	   7'd16  : lmk04806_2_reg[31:0]     <= lmk04806_2_reg15[31:0];	   
	   7'd17  : lmk04806_2_reg[31:0]     <= lmk04806_2_reg16[31:0];	   
	   7'd18  : lmk04806_2_reg[31:0]     <= lmk04806_2_reg17[31:0];	   
	   7'd19  : lmk04806_2_reg[31:0]     <= lmk04806_2_reg18[31:0];	  
     7'd20  : lmk04806_2_reg[31:0]     <= lmk04806_2_reg19[31:0];	 
	   7'd21  : lmk04806_2_reg[31:0]     <= lmk04806_2_reg20[31:0];        	   
	   7'd22  : lmk04806_2_reg[31:0]     <= lmk04806_2_reg21[31:0];       	   
	   7'd23  : lmk04806_2_reg[31:0]     <= lmk04806_2_reg22[31:0];       	   
	   7'd24  : lmk04806_2_reg[31:0]     <= lmk04806_2_reg23[31:0];       	   
	   7'd25  : lmk04806_2_reg[31:0]     <= lmk04806_2_reg24[31:0];       	   
	   7'd26  : lmk04806_2_reg[31:0]     <= lmk04806_2_reg25[31:0];       	     	   
	   7'd27  : lmk04806_2_reg[31:0]     <=	lmk04806_2_reg26[31:0];  
	   7'd28  : lmk04806_2_reg[31:0]     <=	lmk04806_2_reg27[31:0];  	   
	   default:lmk04806_2_reg[31:0]    <= lmk04806_2_reg0_rst[31:0];	 
	 endcase
  end
end





//////////////////////////////////////////////////////////////////////////////////
//// debug signal ////
assign  debug_signal[63:0]  = {spi_wr_en,
                               spi_single_en,
                               lmk_2_spi_start,
                               lmk04806_2_count,
                               lmk04806_2_spi_clk_reg,
                               lmk04806_2_spi_cs_reg,
                               lmk04806_2_spi_cs_sdi_reg,
                               lmk04806_2_spi_sdo,
                               lmk04806_2_reg,
                               spi_rd_en,
                               spi_1_rend,
                               spi_2_stat,
                               3'd0
                               };




 
                                  



//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
endmodule
