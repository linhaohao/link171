////////////////////////////////////////////////////////////////////////////////
// Company: StarPoint
// Engineer: guanzheye
//
// Create Date: 2015/9/18 17:07:17
// Design Name: mif
// Module Name: 
// Target Device: FPGA XC7K325T-2FFG900 
// Tool versions: ISE 14.6
// Description:
//             
// Revision:   v1.0 - File Created
// Additional Comments:
//    
////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps


module mif(
// clock & Reset                   
input                    sys_rst,    
input                    clk_20mhz,
//
input [31:0]             mif_data_in,
input                    mif_data_en,
//state 
input                    dsp2fpga_dsp_rdy,
input                    lmk04806_1_locked_in,
input                    lmk04806_1_holdover,
input                    lmk04806_2_holdover,
input                    lmk_stable_lock,
input [2:0]              dsp_int_state,
///////////////////////////////////////////////////////////////////
output [31:0]           dsp_rd_data,

//////////////////////////////////////////////////////////////////////
output [9:0]            mif_rd_device_addr,
output reg              mif_rd_device_stat,

input [31:0]            device_rd_data,
input                   device_rd_vaild,

output [63:0]           mif_data_out,
output reg              mif_data_vaild,
//-------------------------------------------------------------------
output [31:0]           mif2dac_frame_data,
output                  mif2dac_frame_stat,
//-------------------------------------------------------------------
output [31:0]          mif_dac_data_mode,
output                 mif_rom_stat,

//-------------------------------------
output [31:0]          mif_wrtc_data,
output                 mif_wrtc_stat,

output [31:0]          mif_dec_th_data,
output [31:0]          mif_freq_convert,
output [31:0]          mif_dac_rom_dl,
output                 mif_adc_fifo_rst,
output [31:0]          mif_adc_mode,


output [31:0]         mif_tx_dds0_cfg,
output [31:0]         mif_tx_dds1_cfg,


output [31:0]          mif_rx_freq_tim,


output [31:0]         mif_freq_dds,

output [31:0]         mif_tx_feq_mode,
output [31:0]         mif_rx_adc_select,
output [31:0]         mif_dac_ioup_time,
output [31:0]         mif_dac_int_cfg,
output [31:0]         mif_data_proces_cfg,
output [31:0]         mif_rv_pbr,
output reg            dualPuls_en,
input  [23:0]         decccsk_dbg,




//output [15:0]           mif_phy_cfg,
//状态查询配置
output [63:0]           debug_signal

 
);

//////////////////////////////////////////////////////////////////////////////////
//// parameter ////
//parameter DATE           = 32'h20160216;
parameter DATE           = 32'h20161229;
parameter VERSION        = 32'haabb0930;

//////////////////////////////////////////////////////////////////////////////////
//// parameter    参数写地址////
parameter  MIF_ADDR_VERSION = 8'd0;
parameter  MIF_ADDR_DATE    = 8'd1;
parameter  MIF_ADDR_DSP     = 8'd2;
parameter  MIF_ADDR_STATE   = 8'd3;
//--------
parameter  ADC_frame_addr   = 8'd5;
parameter  DAC_mode_addr    = 8'd6;
parameter  RTC_data_addr    = 8'd7;
parameter  DEC_th_addr      = 8'd8;
parameter  FREQ_convert_addr    = 8'd9;  
parameter  DAC_rom_mode_addr    = 8'd10;   
parameter  ADC_mode_addr    = 8'd11;
parameter FREQ_time_addr    = 8'd15;
parameter FREQ_dds_addr     = 8'd16;

parameter TX_dds0_addr     = 8'd17;
parameter TX_dds1_addr     = 8'd18;
parameter TX_feq_mode_addr = 8'd19;

parameter RX_adc_data_select = 8'd20;

parameter IOUP_time_addr  = 8'd21;

parameter ADDR_dac_int = 8'd22;
parameter ADDR_dataP_cfg = 8'd24;
parameter ADDR_RVPBR_EN    = 8'd25;
parameter ADDR_dualPuls_en = 8'h80;
parameter ADDR_decccsk_dbg = 8'h81;
//parameter  PHY_cnt1_addr     = 8'd6;
//parameter  PHY_cnt2_addr     = 8'd7;

////--------------------------------------------------------------------------------
//reg [15:0]  MIF_ADDR_DATE   = 8'd1;
//reg [15:0]  MIF_ADDR_DSP    = 8'd2;
//reg [15:0]  MIF_ADDR_STATE  = 8'd3;



//////////////////////////////////////////////////////////////////////////////////
//// Signal declration ////
reg        mif_ren;
reg [5:0]  mif_en_cnt;
reg        mif_rd_mode;
reg [7:0]  mif_rd_addr;
reg [31:0] mif_out_data;
reg [31:0] mif_out_data_reg;
//reg        mif_out_en;
reg        mif_wen;
reg [7:0]  mif_wr_addr;
//--------------------------------------------------------------------------------
reg [31:0] dac_frame_data_reg;
reg        dac_frame_stat_reg;
reg        mif_adc_fifo_rst_reg; 
reg [31:0] mif_adc_mode_reg;    
reg [31:0] mif_dac_mode_reg;

reg [31:0] mif_wrtc_data_reg;
reg        mif_wrtc_stat_reg;

reg [31:0] mif_dec_th_data_reg;
reg [31:0] mif_freq_convert_reg = 32'h00000677;
reg [31:0] mif_dac_rom_dl_reg;
reg        mif_rom_stat_reg;    
reg [31:0] mif_rx_freq_tim_reg;
reg [31:0] mif_freq_dds_reg;
reg [31:0] mif_tx_dds0_cfg_reg;
reg [31:0] mif_tx_dds1_cfg_reg;
reg [31:0] mif_tx_feq_mode_cfg;
reg [31:0] mif_rx_adc_select_cfg;

reg [31:0] mif_dac_int_cfg_reg;
//reg [31:0] mif_phy_cnt1_reg;   
//reg [31:0] mif_phy_cnt2_reg;
//reg        mif_phy_stat_reg;


reg [31:0] mif_data_in_dl;
reg        mif_data_en_dl;
reg        mif_data_stat;
//---------------------------------------
reg [31:0] mif_dac_ioup_time_reg;
reg [31:0] mif_data_proces_cfg_reg;
reg [31:0] mif_rv_pbr_reg;

wire [31:0] sys_state;
//////////////////////////////////////////////////////////////////////////////////
//// signal assignment ////
 assign sys_state  = {24'd0,
                      dsp_int_state,
                      dsp2fpga_dsp_rdy,
                      lmk_stable_lock,
                      lmk04806_1_locked_in,
                      lmk04806_1_holdover,
                      lmk04806_2_holdover};

  assign mif_rd_device_addr    = {2'd0,mif_rd_addr[7:0]};

  assign mif_data_out   = {16'hBBBB,mif_rd_addr[7:0],8'hFF,mif_out_data_reg};
//  assign mif_data_vaild = mif_out_en; 
  assign mif2dac_frame_data   = dac_frame_data_reg;
  assign mif2dac_frame_stat   = dac_frame_stat_reg;   
  assign mif_dac_data_mode    = mif_dac_mode_reg;
  
  assign mif_wrtc_data = mif_wrtc_data_reg;
  assign mif_wrtc_stat = mif_wrtc_stat_reg;
  
  assign mif_dec_th_data  = mif_dec_th_data_reg;
  assign mif_adc_fifo_rst = mif_adc_fifo_rst_reg;
  assign mif_adc_mode     = mif_adc_mode_reg;
   assign mif_freq_convert = mif_freq_convert_reg;
//  assign mif_phy_cnt1         = mif_phy_cnt1_reg;
//  assign mif_phy_cnt2         = mif_phy_cnt2_reg;
  assign mif_dac_rom_dl  = mif_dac_rom_dl_reg;
  assign mif_rom_stat    = mif_rom_stat_reg;     
  assign mif_rx_freq_tim = mif_rx_freq_tim_reg;
  assign mif_freq_dds    = mif_freq_dds_reg;

 assign mif_tx_dds0_cfg  = mif_tx_dds0_cfg_reg; 
 assign mif_tx_dds1_cfg  = mif_tx_dds1_cfg_reg; 
 assign mif_tx_feq_mode  = mif_tx_feq_mode_cfg;
 assign mif_rx_adc_select = mif_rx_adc_select_cfg;

 assign mif_dac_ioup_time = mif_dac_ioup_time_reg;
 assign mif_dac_int_cfg   = mif_dac_int_cfg_reg;


 assign mif_data_proces_cfg   =  mif_data_proces_cfg_reg;
 assign mif_rv_pbr            =   mif_rv_pbr_reg;




//////////////////////////////////////////////////////////////////////////////////
//// (0) 工作使能
always@(posedge clk_20mhz or posedge sys_rst)
begin
	   if(sys_rst)
	     mif_ren <= 1'd0;
	   else if((mif_data_en && !mif_data_en_dl) && mif_data_in[31:16] == 16'hAAAA)
	   	       mif_ren <= 1'd1;
	   else if(mif_en_cnt == 6'd8)
	           mif_ren <= 1'd0;
     else
         	  mif_ren <= mif_ren;
end
//////////////////////////////////////////////////////////////////////////////////
//// (0) 
always@(posedge clk_20mhz or posedge sys_rst)
begin
	   if(sys_rst)
	     mif_data_in_dl <= 32'd0;
	   else 
	   	 mif_data_in_dl <= mif_data_in  ; 
end
//////////////////////////////////////////////////////////////////////////////////
//// (0) 
always@(posedge clk_20mhz or posedge sys_rst)
begin
	   if(sys_rst)
	     mif_data_en_dl <= 1'd0;
	   else 
	   	 mif_data_en_dl <= mif_data_en  ; 
end   
//////////////////////////////////////////////////////////////////////////////////
//// (0) 
always@(posedge clk_20mhz or posedge sys_rst)
begin
	   if(sys_rst)
	     mif_data_stat <= 1'd0;
	   else if(mif_data_en && !mif_data_en_dl)
	   	 mif_data_stat <= 1'd1; 
	   else
	     mif_data_stat <= 1'd0;
end 



//////////////////////////////////////////////////////////////////////////////////
//// (1) 工作使能
always@(posedge clk_20mhz or posedge sys_rst)
begin
	   if(sys_rst)
	     mif_en_cnt <= 6'd0;	     
	   else if(mif_ren || mif_data_vaild)
	   	       mif_en_cnt <= mif_en_cnt + 1'd1; 
     else
       mif_en_cnt <= 6'd0;
end
////////////////////////////////////////////////////////////////////////////////
// (2) mif_rd_mode   此信号目前用来区分读mif寄存器或者读器件ram。
//   = 1 RAM     = 0  MIF
always@(posedge clk_20mhz or posedge sys_rst)
begin
	   if(sys_rst)
	     mif_rd_mode <= 1'd0;
	 //  else if(mif_ren && mif_en_cnt == 6'd0)begin
	  else if(mif_en_cnt == 6'd8)
	     mif_rd_mode <= 1'd0;
	  else if((mif_data_en && !mif_data_en_dl)&&  mif_data_in[15])
//	  else if(mif_data_stat && mif_data_in[15])
	   	      mif_rd_mode <= 1'd1;
	   else
	   	      mif_rd_mode <= mif_rd_mode;
end
//////////////////////////////////////////////////////////////////////////////////
//// (3) mif_rd_addr
always@(posedge clk_20mhz or posedge sys_rst)
begin
	   if(sys_rst)
	     mif_rd_addr <= 8'd0;
	   else if(mif_ren && mif_en_cnt == 6'd0)
	   	       mif_rd_addr <= mif_data_in_dl[7:0];
      else 
       mif_rd_addr <= mif_rd_addr;  

end	 
//////////////////////////////////////////////////////////////////////////////////
//// (3) mif_wr_stat
always@(posedge clk_20mhz or posedge sys_rst)
begin
	   if(sys_rst)
	     mif_rd_device_stat <= 1'd0;
	   else if(mif_ren && mif_en_cnt == 6'd1 && mif_rd_mode)
	   	       mif_rd_device_stat <= 1'd1;
     else 
       mif_rd_device_stat <= 1'd0;

end	 	
//--------------------MIF----------------------------------------------------//
//////////////////////////////////////////////////////////////////////////////////
//// (@) RED
always@(posedge clk_20mhz or posedge sys_rst)
begin
	   if(sys_rst)
	     mif_out_data <= 32'd0;
	   else if(mif_ren && !mif_rd_mode)begin
	   	  case(mif_rd_addr)
	   	    MIF_ADDR_VERSION      : mif_out_data  <= VERSION;
	   	    MIF_ADDR_DATE         : mif_out_data  <= DATE;
	   	    MIF_ADDR_DSP          : mif_out_data  <= sys_state;
	   	    MIF_ADDR_STATE        : mif_out_data  <= 32'h00000000;        
	   	    ADC_frame_addr        : mif_out_data  <= dac_frame_data_reg;    
	   	    DAC_mode_addr         : mif_out_data  <= mif_dac_mode_reg;
	   	    RTC_data_addr         : mif_out_data  <= mif_wrtc_data_reg;
	   	    DEC_th_addr           : mif_out_data  <= mif_dec_th_data_reg;
	   	    FREQ_convert_addr     : mif_out_data  <= mif_freq_convert_reg;    
	   	    DAC_rom_mode_addr     : mif_out_data  <= mif_dac_rom_dl_reg;    
	   	    FREQ_time_addr        : mif_out_data  <= mif_rx_freq_tim_reg;   
	   	    FREQ_dds_addr         : mif_out_data  <= mif_freq_dds_reg;
			ADC_mode_addr         : mif_out_data  <= mif_adc_mode_reg;
			TX_dds0_addr          : mif_out_data  <= mif_tx_dds0_cfg_reg;
			TX_dds1_addr          : mif_out_data  <= mif_tx_dds1_cfg_reg;
			TX_feq_mode_addr      : mif_out_data  <= mif_tx_feq_mode_cfg;
			RX_adc_data_select    : mif_out_data  <= mif_rx_adc_select_cfg; 
			IOUP_time_addr        : mif_out_data  <= mif_dac_ioup_time_reg;   
			ADDR_dac_int       : mif_out_data  <= mif_dac_int_cfg_reg  ;    
			
			ADDR_dataP_cfg        : mif_out_data  <= mif_data_proces_cfg_reg;
            ADDR_RVPBR_EN         : mif_out_data  <= mif_rv_pbr_reg;
			ADDR_dualPuls_en      : mif_out_data  <= {31'd0,dualPuls_en};
			ADDR_decccsk_dbg      : mif_out_data  <= {8'd0,decccsk_dbg};
	   	//    PHY_cnt1_addr         : mif_out_data  <= mif_phy_cnt1_reg;
	   	//    PHY_cnt2_addr         : mif_out_data  <= mif_phy_cnt2_reg;   
	   	    //--预留	   	    
	   	    default: mif_out_data <= 32'd0;
	   	  endcase
	   end
	   else
	    mif_out_data <= 32'd0;
end
//////////////////////////////////////////////////////////////////////////////////
//// (@) RED data
always@(posedge clk_20mhz or posedge sys_rst)
begin
	   if(sys_rst)	
        mif_out_data_reg <= 32'd0;
     else if(mif_en_cnt == 6'd2)
             mif_out_data_reg <= mif_out_data;
     else if(device_rd_vaild)
             mif_out_data_reg <= device_rd_data;
     else
        mif_out_data_reg <= mif_out_data_reg;
end
//////////////////////////////////////////////////////////////////////////////////
//// (@) RED end
always@(posedge clk_20mhz or posedge sys_rst)
begin
	   if(sys_rst)	   	  
       mif_data_vaild <= 1'd0;
     else if(mif_en_cnt > 6'd4  && mif_en_cnt < 6'd30)
       mif_data_vaild <= 1'd1;
     else 
      mif_data_vaild <= 1'd0;
end




//////////////////////////////////////////////////////////////////////////////////////////////////
///mif 写，此处负责更改FPGA各种运行状态，以及触发各种测试模式    2015/10/23 11:52:26

//////////////////////////////////////////////////////////////////////////////////
//// (@) w 
always@(posedge clk_20mhz or posedge sys_rst)
begin
		   if(sys_rst)
	     mif_wen <= 1'd0;
	   else if(mif_data_en && mif_data_in[31:16] == 16'hCDCD)
	     mif_wen <= 1'd1;
	   else
	     mif_wen <= 1'd0;
end
//////////////////////////////////////////////////////////////////////////////////
//// (@) w 
always@(posedge clk_20mhz or posedge sys_rst)
begin
		   if(sys_rst)
	     mif_wr_addr <= 8'd0;
	   else if(mif_data_en && mif_data_in[31:16] == 16'hCDCD)
	     mif_wr_addr <= mif_data_in[7:0];
	   else
	     mif_wr_addr <= 8'd0;
end
   
//////////////////////////////////////////////////////////////////////////////////
//// (@) dac_frame_data
always@(posedge clk_20mhz or posedge sys_rst)
begin
		   if(sys_rst)
	     dac_frame_data_reg <= 32'h30000000;
	   else if(mif_data_en && mif_wr_addr == ADC_frame_addr)
	     dac_frame_data_reg <=  mif_data_in[31:0];
	   else
	     dac_frame_data_reg <= dac_frame_data_reg;
end	 
//////////////////////////////////////////////////////////////////////////////////
//// (@) dac_frame_stat   产生DAC SPI启动参数及使能脉冲信号。
always@(posedge clk_20mhz or posedge sys_rst)
begin
		 if(sys_rst)
	     dac_frame_stat_reg <= 1'd0;
	   else if(mif_data_en && mif_wr_addr == ADC_frame_addr)
	     dac_frame_stat_reg <=  1'd1;
	   else
	     dac_frame_stat_reg <= 1'd0;
end	 
//////////////////////////////////////////////////////////////////////////////////
//// (@) dac_cfg
always@(posedge clk_20mhz or posedge sys_rst)
begin
		   if(sys_rst)
	     mif_dac_mode_reg <= 32'd0;
	   else if(mif_data_en && mif_wr_addr == DAC_mode_addr)
	     mif_dac_mode_reg <=  mif_data_in[31:0];
	   else
	     mif_dac_mode_reg <= mif_dac_mode_reg;
end	
//////////////////////////////////////////////////////////////////////////////////
//// (@) RTC
always@(posedge clk_20mhz or posedge sys_rst)
begin
		   if(sys_rst)
	     mif_wrtc_data_reg <= 32'd0;
	   else if(mif_data_en && mif_wr_addr == RTC_data_addr)
	     mif_wrtc_data_reg <=  mif_data_in[31:0];
	   else
	     mif_wrtc_data_reg <= mif_wrtc_data_reg;
end	 
//////////////////////////////////////////////////////////////////////////////////
//// (@) rtc
always@(posedge clk_20mhz or posedge sys_rst)
begin
		 if(sys_rst)
	     mif_wrtc_stat_reg <= 1'd0;
	   else if(mif_data_en && mif_wr_addr == RTC_data_addr)
	     mif_wrtc_stat_reg <= 1'd1;
	   else
	     mif_wrtc_stat_reg <= 1'd0;
end	 
//////////////////////////////////////////////////////////////////////////////////
//// (@)TH
always@(posedge clk_20mhz or posedge sys_rst)
begin
		   if(sys_rst)
	     mif_dec_th_data_reg <= 32'd0;
	   else if(mif_data_en && mif_wr_addr == DEC_th_addr)
	     mif_dec_th_data_reg <=  mif_data_in[31:0];
	   else
	     mif_dec_th_data_reg <= mif_dec_th_data_reg;
end	 
//////////////////////////////////////////////////////////////////////////////////
//// (@) ADC
always@(posedge clk_20mhz or posedge sys_rst)
begin
		   if(sys_rst)
	     mif_adc_fifo_rst_reg <= 1'd0;
	   else if(mif_data_en && mif_wr_addr == ADC_mode_addr)
	     mif_adc_fifo_rst_reg <=  1'd1;
	   else
	     mif_adc_fifo_rst_reg <= 1'd0;
end
//////////////////////////////////////////////////////////////////////////////////
//// (@) ADC
always@(posedge clk_20mhz or posedge sys_rst)
begin
		   if(sys_rst)
	     mif_adc_mode_reg <= 32'd0;
	   else if(mif_data_en && mif_wr_addr == ADC_mode_addr)
	     mif_adc_mode_reg <=  mif_data_in[31:0];
	   else
	     mif_adc_mode_reg <= mif_adc_mode_reg;
end









//////////////////////////////////////////////////////////////////////////////////
//// (@) 
always@(posedge clk_20mhz or posedge sys_rst)
begin
		   if(sys_rst)
	     mif_freq_convert_reg <= 32'h00000677;
	   else if(mif_data_en && mif_wr_addr == FREQ_convert_addr)
	     mif_freq_convert_reg <=  mif_data_in[31:0];
	   else
	     mif_freq_convert_reg <= mif_freq_convert_reg;
end	 
//////////////////////////////////////////////////////////////////////////////////
//// (@) 
always@(posedge clk_20mhz or posedge sys_rst)
begin
		   if(sys_rst)
	     mif_dac_rom_dl_reg <= 32'd0;
	   else if(mif_data_en && mif_wr_addr == DAC_rom_mode_addr)
	     mif_dac_rom_dl_reg <=  mif_data_in[31:0];
	   else
	     mif_dac_rom_dl_reg <= mif_dac_rom_dl_reg;
end	 
//////////////////////////////////////////////////////////////////////////////////
//// (@) 
always@(posedge clk_20mhz or posedge sys_rst)
begin
		   if(sys_rst)
	     mif_rom_stat_reg <= 1'd0;
	   else if(mif_data_en && mif_wr_addr == DAC_rom_mode_addr)
	     mif_rom_stat_reg <= 1'd1;
	   else
	     mif_rom_stat_reg <= 1'd0;
end	 
//////////////////////////////////////////////////////////////////////////////////
//// (@) 
always@(posedge clk_20mhz or posedge sys_rst)
begin
		   if(sys_rst)
	     mif_rx_freq_tim_reg <= 32'd1;
	   else if(mif_data_en && mif_wr_addr == FREQ_time_addr)
	     mif_rx_freq_tim_reg <=  mif_data_in[31:0];
	   else
	     mif_rx_freq_tim_reg <= mif_rx_freq_tim_reg;
end	 
//////////////////////////////////////////////////////////////////////////////////
//// (@) 
always@(posedge clk_20mhz or posedge sys_rst)
begin
		   if(sys_rst)
	     mif_freq_dds_reg <= 32'd1;
	   else if(mif_data_en && mif_wr_addr == FREQ_dds_addr)
	     mif_freq_dds_reg <=  mif_data_in[31:0];
	   else
	     mif_freq_dds_reg <= mif_freq_dds_reg;
end	 
//////////////////////////////////////////////////////////////////////////////////
//// (@) 
always@(posedge clk_20mhz or posedge sys_rst)
begin
		   if(sys_rst)
	     mif_tx_dds0_cfg_reg <= 32'h00147AE1;       ///25'd1342177;  //1M*2^25/25M
	   else if(mif_data_en && mif_wr_addr == TX_dds0_addr)
	     mif_tx_dds0_cfg_reg <=  mif_data_in[31:0];
	   else
	     mif_tx_dds0_cfg_reg <= mif_tx_dds0_cfg_reg;
end	 
//////////////////////////////////////////////////////////////////////////////////
//// (@) 
always@(posedge clk_20mhz or posedge sys_rst)
begin
		   if(sys_rst)
	     mif_tx_dds1_cfg_reg <= 32'h0028F5C2;      //25'd2684354;  //2M*2^25/25M
	   else if(mif_data_en && mif_wr_addr == TX_dds1_addr)
	     mif_tx_dds1_cfg_reg <=  mif_data_in[31:0];
	   else
	     mif_tx_dds1_cfg_reg <= mif_tx_dds0_cfg_reg;
end	 
            
//////////////////////////////////////////////////////////////////////////////////
//// (@) 
always@(posedge clk_20mhz or posedge sys_rst)
begin
		   if(sys_rst)
	     mif_tx_feq_mode_cfg <= 32'd0;      //25'd2684354;  //2M*2^25/25M
	   else if(mif_data_en && mif_wr_addr == TX_feq_mode_addr)
	     mif_tx_feq_mode_cfg <=  mif_data_in[31:0];
	   else
	     mif_tx_feq_mode_cfg <= mif_tx_feq_mode_cfg;
end	           
//////////////////////////////////////////////////////////////////////////////////
//// (@) 
always@(posedge clk_20mhz or posedge sys_rst)
begin
		   if(sys_rst)
	     mif_rx_adc_select_cfg <= 32'd0;
	   else if(mif_data_en && mif_wr_addr == RX_adc_data_select)
	     mif_rx_adc_select_cfg <=  mif_data_in[31:0];
	   else
	     mif_rx_adc_select_cfg <= mif_rx_adc_select_cfg;
end	

//////////////////////////////////////////////////////////////////////////////////
//// (@) 
always@(posedge clk_20mhz or posedge sys_rst)
begin
		   if(sys_rst)
	     mif_dac_ioup_time_reg <= 32'd3;
	   else if(mif_data_en && mif_wr_addr == IOUP_time_addr)
	     mif_dac_ioup_time_reg <=  mif_data_in[31:0];
	   else
	     mif_dac_ioup_time_reg <= mif_dac_ioup_time_reg;
end	
//////////////////////////////////////////////////////////////////////////////////
//// (@) 
always@(posedge clk_20mhz or posedge sys_rst)
begin
		   if(sys_rst)
	     mif_dac_int_cfg_reg <= 32'd0;
	   else if(mif_data_en && mif_wr_addr == ADDR_dac_int)
	     mif_dac_int_cfg_reg <=  mif_data_in[31:0];
	   else
	     mif_dac_int_cfg_reg <= mif_dac_int_cfg_reg;
end	
//////////////////////////////////////////////////////////////////////////////////
//// (@) 
always@(posedge clk_20mhz or posedge sys_rst)
begin
		   if(sys_rst)
	     mif_data_proces_cfg_reg <= 32'd0;
	   else if(mif_data_en && mif_wr_addr == ADDR_dataP_cfg)
	     mif_data_proces_cfg_reg <=  mif_data_in[31:0];
	   else
	     mif_data_proces_cfg_reg <= mif_data_proces_cfg_reg;
end	

always@(posedge clk_20mhz or posedge sys_rst)
begin
		   if(sys_rst)
	     mif_rv_pbr_reg <= 32'd0;
	   else if(mif_data_en && mif_wr_addr == ADDR_RVPBR_EN)
	     mif_rv_pbr_reg <=  mif_data_in[31:0];
	   else
	     mif_rv_pbr_reg <= mif_rv_pbr_reg;
end	
always@(posedge clk_20mhz or posedge sys_rst)
begin
     if(sys_rst)
	     dualPuls_en <= 1'b0;
	   else if(mif_data_en && mif_wr_addr == ADDR_dualPuls_en)
	     dualPuls_en <=  mif_data_in[0];
	   else
	     ;
end	

////////////////////////////////////////////////////////////////////////////////////
////// (@) PHY
//always@(posedge clk_20mhz or posedge sys_rst)
//begin
//		   if(sys_rst)
//	     mif_phy_cnt1_reg <= 32'd1;
//	   else if(mif_data_en && mif_wr_addr == PHY_cnt1_addr)
//	     mif_phy_cnt1_reg <=  mif_data_in[31:0];
//	   else
//	     mif_phy_cnt1_reg <= mif_phy_cnt1_reg;
//end	 
////////////////////////////////////////////////////////////////////////////////////
////// (@) PHY
//always@(posedge clk_20mhz or posedge sys_rst)
//begin
//		   if(sys_rst)
//	     mif_phy_cnt2_reg <= 32'd2;
//	   else if(mif_data_en && mif_wr_addr == PHY_cnt2_addr)
//	     mif_phy_cnt2_reg <=  mif_data_in[31:0];
//	   else
//	     mif_phy_cnt2_reg <= mif_phy_cnt2_reg;
//end	 
//  
////////////////////////////////////////////////////////////////////////////////////
////// (@) PHY
//always@(posedge clk_20mhz or posedge sys_rst)
//begin
//		   if(sys_rst)
//	     mif_phy_stat_reg <= 1'd0;
//	   else if(mif_data_en && mif_wr_addr == PHY_cnt2_addr)
//	     mif_phy_stat_reg <= 1'd1;
//	   else
//	     mif_phy_stat_reg <= 1'd0;
//end	
////////////////////////////////////////////////////////////////////////////////////
////// (@) PHY
//always@(posedge clk_20mhz or posedge sys_rst)
//begin
//		   if(sys_rst)
//	     mif_phy_cfg_stat <= 1'd0;
//	   else 
//	     mif_phy_cfg_stat <= mif_phy_stat_reg;
//
//end	






















//////////////////////////////////////////////////////////////////////////////////
//// debug signal ////
assign  debug_signal[63:0]             = {mif_data_en,
                                          mif_data_in[15],  
                                          mif_ren,
                                          mif_data_stat,
                                          mif_rd_device_stat, 
                                          mif_rd_mode,
                                          clk_20mhz,
                                          mif_data_in[31:0],
                                          mif_data_en,
                                          23'd0
                                          };
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
endmodule