//////////////////////////////////////////////////////////////////////////////////
// Company:        StarPoint
// Engineer:       guanzheye 
// Create Date:    2015/10/20 
// Module Name:    sys_state_crl 
// Project Name:   JFT
// Target Devices: FPGA - XC7K325T - FFG900;   
// Tool versions:  ISE14.6 
// Description:    
//           系统运行所需各种控制观测类信号的产生。
// Revision:       v1.0 - File Created
// Additional Comments: 
//           2015/11/4 新增网口启动模式。 
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps


module  sys_state_crl(
// Clock & Reset   
input                      clk_20mhz,
input                      clk_10mhz,
input 										 clk_20mhz_2,
input                      sys_rest,
input                      clk_200mhz,
input                      clk_dcm1_pll,
input                      clk_dcm0_pll,

input                      rs_rx_data_vlde ,
input  [63:0]              rs_rx_data,
input                      dsp_ctr_uart_en,
input  [63:0]              dsp_ctr_uart_data,


input                      lmk04806_2_holdover,  
input                      lmk04806_1_locked_in,
input                      lmk04806_1_holdover, 
input                      lmk_stable_lock,
input                      dsp2fpga_dsp_rdy,
input                      lmk_failure_led,
//2015/10/18 16:51:51
input  [1:0]               dsp_mode,    //2|???a1? 01 == spi ?￡ê?￡? 10 == i2c 00 -- boot?￡ê?
inout                      dsp_enddian, //????D????￡ê?
inout  [6:0]               dsp_bootmode,

output                     fpga_dsp_cfgok,
output                     fpga2cpld_dsp_rdy,

output                     fpga2cpld_dsp_mode,  //·￠??CPLDμ??μ?±?óóDóé1???μ?
output                     fpga_clk_div24,      //D?ì?D?o?
output                     fpga_2cpld_dspen,     //DSPμ??′ê1?ü
output                     fpga_2cpld_rst1,      //DSP?′??1
output                     fpga_2cpld_rst2,      //DSP?′??2
output                     fpga_2cpld_rst3,      //DSP?′??3

output                      dsp_rst_in,          //dsp给算法部分的复位信号
output                      dsp_net_in,          //dsp给算法部分的入网指示


output [1:0]               lmk_clk_sel,
output                     dac_master_reset,
output                     dac_io_reset,
output                     dac_ext_pwr_dwn,

output                     dac_txenable,
output                     lmk_pll_lock,
output [7:0]               led_startus,
//----------------
output                     phy_rst,
input                      phy_int, 

output                     dac_stat,
output [2:0]              dsp_int_state,
 

input                     gpio_tx_interrupt,             
input                     gpio_rx_interrupt,


output reg               lmk_int2_stat,

//debug
output [63:0]             debug_signal 

);

//////////////////////////////////////////////////////////////////////////////////
//// parameter ////
parameter CLED20      = 25'd20000000;
parameter CLED10      = 24'd10000000;
parameter CLED200     = 28'd200000000;


parameter PHY_N       = 32'd400000; //20ms
parameter CNT150MS    = 32'd3000000;//150ms

parameter TIME_CNT1MS    = 14'd10000;//1ms

parameter TIME_RST_LOW   = 32'd5000000;//1ms
//parameter CLED20      = 25'd200;
//parameter PHY_N       = 32'd400; //20ms
//parameter CNT150MS    = 32'd3000;//150ms


//////////////////////////////////////////////////////////////////////////////////
//// signal declaration ////
reg                 lmk_pll_lock_reg = 1'd0;  
reg                 clk_20mhz_led;
reg [24:0]          clk_20mhz_led_cnt;
reg                 clk_200mhz_led;
reg [27:0]          clk_200mhz_led_cnt;

reg                 clk_10mhz_led;
reg [23:0]          clk_10mhz_led_cnt;
reg [6:0]           dsp_bootmode_reg = 7'h0 ;
reg                 dsp_rdy;
///HPY----------------------------------
reg [31:0]          phy_cnt;
reg [31:0]          phy_150ms_cnt;
reg [2:0]           phy_rest_duration;
reg [2:0]           phy_max_repeat;
reg                 phy_int_en;
reg                 phy_rst_reg;
reg                 phy_int_err;
reg                 phy_int_state_en;
//---------------------------------------

reg                 lmk2dsp_pll_ok;

reg                 dac_rst;
reg [11:0]          dac_rst_cnt;
reg                 dac_stat_reg;
reg [3:0]           dac_stat_en;
reg [1:0]           dsp_mode_dly;


reg mif_phy_cfg_en;
reg dac_txenable_en;
reg [31:0] dac_txenable_cnt;
reg mif_phy_rst_tmp;

reg [4:0] heart_cnt       = 5'd0;
reg       heart_clk_div24 = 1'b0;
reg [13:0] time_1ms_cnt   = 14'd0;
reg [12:0] time_cpld_cnt   = 13'd0;
wire [6:0] dsp_bootmode_r;
wire [6:0] dsp_bootmode_out;
// wire [6:0] dsp_bootmode_g;
wire       direc_change;
reg        reset_begin     = 1'b0;  //重新加载复位使能
reg  [2:0] reset_begin_cnt = 3'd0;  //重新加载复位使能
reg        reset_low       = 1'b0;  //重新加载拉低标识
reg        reg_select      = 1'b1;  //默认选择由串口开关控制
//////////////////////////////////////////////////////
//reg [1:0]  mode_select     = 2'b00;  //默认选择spi模式
reg [1:0]  mode_select     = 2'b01;  //默认选择spi模式  mann
/////////////////////////////////////////////////////
reg [31:0] reset_low_cnt   = 32'd0;
reg [2:0]  reset_low_posedge = 3'd0;
wire       dsp_rst_in_r;
wire       dsp_net_in_r;
reg [2:0] dsp_int_rst_cnt;
reg       dsp_int_rtr;
reg [2:0] dsp_int_cnt;
//------------------------------------------------------------------2016/2/22 13:33:52
assign dsp_int_state = dsp_int_cnt;

//------------------------------------------------------------------


always@(posedge clk_10mhz)   begin
    reset_low_posedge[2:0]      <=  {reset_low_posedge[1:0],reset_low};
end
//-----------------------------------
always@(posedge clk_20mhz or posedge sys_rest )   begin 
   if(sys_rest) begin
        reset_begin             <=  1'd0;
        reg_select              <=  1'd1;
 /////////////////////////////////////////////////
				mode_select             <=  2'b01;//mann
				//mode_select             <=  2'b00;//mann
/////////////////////////////////////////////////
        reset_begin_cnt         <=  3'd0;
   end
   // else if(rs_rx_data_vlde && (rs_rx_data[63:0] == 64'hCDCD_0058_0000_0001)) begin
		// reset_begin				<=	1'b1;
        // reset_begin_cnt         <=  3'd0;
   // end
   else if(rs_rx_data_vlde && (rs_rx_data[63:32] == 32'hCDCD_0058)) begin
		reg_select				<=	rs_rx_data[16];
		mode_select				<=	rs_rx_data[1:0];
		reset_begin				<=	1'b1;
        reset_begin_cnt         <=  3'd0;
   end
   else if(dsp_ctr_uart_en && dsp_ctr_uart_data[63:0] == 64'hCDCD_0051_0000_0001) begin
		reg_select				<=	1'b1;
		mode_select				<=	2'b01;
		reset_begin				<=	1'b1;
        reset_begin_cnt         <=  3'd0;
   end
   else if(reset_begin_cnt >= 3'd2)
        reset_begin				<=	1'b0;
   else if(reset_begin)
        reset_begin_cnt         <=  reset_begin_cnt + 1'b1;
   else
        ;
end
//----------------------------------------------------------------------------
//--2016/2/22 11:21:41   
//上电5秒检测DSP是否上电成功，失败则重新复位DSP，SPI模式下。
//----------------
//bot模式不做检测,dsp启动成功不做检测，重复初始化3次还失败则挂死。
always@(posedge clk_10mhz or posedge sys_rest )   begin 
   if(sys_rest) 
      dsp_int_rst_cnt <= 3'd0;
   else if(mode_select == 2'd0 || dsp2fpga_dsp_rdy || dsp_int_cnt == 2'd3 || dsp_int_rst_cnt == 3'd5)
      dsp_int_rst_cnt <= 3'd0;
   else if(clk_10mhz_led_cnt == CLED10 - 1'd1)
      dsp_int_rst_cnt <= dsp_int_rst_cnt + 1'd1;
   else 
     dsp_int_rst_cnt <= dsp_int_rst_cnt;
end
//----------------   
always@(posedge clk_10mhz or posedge sys_rest )   begin 
   if(sys_rest) 
      dsp_int_rtr <= 1'd0;
   else if(dsp2fpga_dsp_rdy)
      dsp_int_rtr <= 1'd0; 
   else if(dsp_int_rst_cnt == 3'd5)   	       
      dsp_int_rtr <= 1'd1;
   else
      dsp_int_rtr <= 1'd0;
end
//----------------
always@(posedge clk_10mhz or posedge sys_rest )   begin 
   if(sys_rest) 
      dsp_int_cnt <= 3'd0;
   else if(dsp_int_rtr)
      dsp_int_cnt <= dsp_int_cnt + 1'd1;
   else 
      dsp_int_cnt <= dsp_int_cnt;
end
//-----------------------------------------------------------------------------
  always@(posedge clk_10mhz or posedge sys_rest )      
 begin 
   if(sys_rest) begin
        reset_low_cnt    <=  32'd0;
        reset_low        <=  1'b0;
   end
 //  else if(reset_begin) begin
   else if(reset_begin || dsp_int_rtr) begin
        reset_low        <=  1'b1;
        reset_low_cnt    <=  32'd0;
   end
   else if(reset_low_cnt >= TIME_RST_LOW) begin
        reset_low        <=  1'b0;
        reset_low_cnt    <=  reset_low_cnt;
   end
   else if(reset_low )
        reset_low_cnt    <=  reset_low_cnt + 1'b1;
   else 
        ;
end

//生成CPLD需要的心跳信号  or posedge sys_rest   lmk2dsp_pll_ok
 always@(posedge clk_10mhz or posedge sys_rest )      
 begin 
   if(sys_rest) begin
        heart_clk_div24 <=  1'b0;
        heart_cnt       <=  5'd0;
   end
   else if(heart_cnt >= 5'd12) begin
        heart_cnt       <=  5'd0;
        heart_clk_div24 <=  ~heart_clk_div24;
   end
   else begin
        heart_cnt       <=  heart_cnt + 1'b1;
        heart_clk_div24 <=  heart_clk_div24;
   end
end

//lmk锁定后再产生心跳信号
// assign  fpga_clk_div24  =   heart_clk_div24;
assign  fpga_clk_div24  =   lmk_stable_lock ? heart_clk_div24 : 1'b0;
 
 ////lmk锁定后，过1S时间，拉高DSP电源信号

////1MS时间计时  lmk_stable_lock
 always@(posedge clk_10mhz or posedge sys_rest )      
 begin 
   if(sys_rest) begin
        time_1ms_cnt    <=  14'd0;
   end
   else if(reset_low_posedge[2:1] == 2'b10)
        time_1ms_cnt    <=  14'd0;
   else if(time_cpld_cnt >= 13'd130)
        time_1ms_cnt    <=  time_1ms_cnt;
   else if(time_1ms_cnt >= TIME_CNT1MS)
        time_1ms_cnt    <=  14'd0;
   else if(lmk_stable_lock)
        time_1ms_cnt    <=  time_1ms_cnt + 1'b1;
   else 
        time_1ms_cnt    <=  time_1ms_cnt;
 end

  always@(posedge clk_10mhz or posedge sys_rest )      
 begin 
   if(sys_rest) begin
        time_cpld_cnt    <=  13'd0;
   end
   else if(reset_low_posedge[2:1] == 2'b10)
        time_cpld_cnt    <=  13'd0;
   else if(time_cpld_cnt >= 13'd130)            //?àóàμ?100msó?à′?D??êy?Yμ????ò?ú
        time_cpld_cnt    <=  time_cpld_cnt;
   else if(lmk_stable_lock && (time_1ms_cnt >= TIME_CNT1MS))
        time_cpld_cnt    <=  time_cpld_cnt + 1'b1;
   else 
        time_cpld_cnt    <=  time_cpld_cnt;
 end
 
// assign  fpga_2cpld_dspen =   (time_cpld_cnt >= 13'd3500) ? 1'b1 : 1'b0;
assign  fpga_2cpld_dspen =   lmk_stable_lock               ? 1'b1 : 1'b0;
assign  fpga_2cpld_rst1  =   reset_low ? 1'b0 : ((time_cpld_cnt >= 13'd100) ? 1'b1 : 1'b0);
assign  fpga_2cpld_rst2  =   reset_low ? 1'b0 : ((time_cpld_cnt >= 13'd110) ? 1'b1 : 1'b0);
assign  fpga_2cpld_rst3  =   reset_low ? 1'b0 : ((time_cpld_cnt >= 13'd120) ? 1'b1 : 1'b0);
//----------------------------------------------------2016/1/8 15:44:12
always@(posedge clk_10mhz or posedge sys_rest )      
 begin 
   if(sys_rest)
     lmk_int2_stat <= 1'd0;
   else if(lmk_stable_lock && (time_1ms_cnt >= TIME_CNT1MS))begin
           if(time_cpld_cnt == 13'd1)
             lmk_int2_stat <= 1'd1;
           else
             lmk_int2_stat <= 1'd0;
           end
  else 
      lmk_int2_stat <= 1'd0;
end
//---------------------------------------------------------------------          

// assign  fpga2cpld_dsp_mode           = dsp_mode[0];   //2015/12/3 14:02:09

// assign  dsp_enddian                  = 1'd1 ;
//assign  dsp_bootmode                 = dsp_bootmode_reg ;

// assign  dsp_bootmode_r             = (dsp_mode == 2'b01)?7'h06:
                                    // ((dsp_mode == 2'b10)?7'h05:7'h00);
assign  fpga2cpld_dsp_mode         = reg_select ? mode_select[0] : dsp_mode[0];   //2015/12/3 14:02:09
                            
assign  dsp_bootmode_r             = reg_select ? ((mode_select == 2'b01) ? 7'h06 : ((mode_select == 2'b10) ? 7'h05 : 7'h00))
                                                : ((dsp_mode == 2'b01)    ? 7'h06 : ((dsp_mode == 2'b10)    ? 7'h05 : 7'h00));
//  发给COLD进行重新复位的使能
assign  fpga2cpld_dsp_rdy          = reset_low;              //CPLD对dsp配置成功。

                                    
//???ò?ú±ê??
assign  direc_change               = (time_cpld_cnt >= 13'd130) ? 1'b1  : 1'b0;
 
// assign  dsp_bootmode_out[3]        = (time_cpld_cnt >= 13'd220) ? dsp_net_in_r    : dsp_bootmode_r[3];
assign  dsp_bootmode_out[4]        = (time_cpld_cnt >= 13'd130) ? gpio_rx_interrupt : dsp_bootmode_r[4];
assign  dsp_bootmode_out[5]        = (time_cpld_cnt >= 13'd130) ? gpio_tx_interrupt : dsp_bootmode_r[5];
  
assign  dsp_rst_in                 = (time_cpld_cnt >= 13'd130) ? dsp_rst_in_r      : 1'b1;
assign  dsp_net_in                 = (time_cpld_cnt >= 13'd130) ? dsp_net_in_r      : 1'b0;
//èyì?ê?3?*********************************************
// genvar m;
  // generate 
    // for (m=0;m<7;m=m+1)
    // begin: tx_carrier_sel_dif
       // IOBUF #(
          // .DRIVE(12), // Specify the output drive strength
          // .IBUF_LOW_PWR("TRUE"),  // Low Power - "TRUE", High Performance = "FALSE" 
          // .IOSTANDARD("DEFAULT"), // Specify the I/O standard
          // .SLEW("SLOW") // Specify the output slew rate
       // ) IOBUF_bootmode (
          // .O(              ),       // Buffer output  2?1?D?
          // .IO(dsp_bootmode[m]),     // Buffer inout port (connect directly to top-level port)
          // .I(dsp_bootmode_r[m]),      	    // Buffer input
          // .T(direc_change)      // 3-state enable input, high=input, low=output
       // );
    // end
  // endgenerate
  
  //boot【6:0】分别赋值
  //   boot[0]
       IOBUF #(
          .DRIVE(12), // Specify the output drive strength
          .IBUF_LOW_PWR("TRUE"),  // Low Power - "TRUE", High Performance = "FALSE" 
          .IOSTANDARD("DEFAULT"), // Specify the I/O standard
          .SLEW("SLOW") // Specify the output slew rate
       ) IOBUF_bootmode0 (
          .O(              ),       // Buffer output  2?1?D?
          .IO(dsp_bootmode [0]),     // Buffer inout port (connect directly to top-level port)
          .I(dsp_bootmode_r[0]),      	    // Buffer input
          .T(direc_change)      // 3-state enable input, high=input, low=output
       );
       
  //   boot[1]
       IOBUF #(
          .DRIVE(12), // Specify the output drive strength
          .IBUF_LOW_PWR("TRUE"),  // Low Power - "TRUE", High Performance = "FALSE" 
          .IOSTANDARD("DEFAULT"), // Specify the I/O standard
          .SLEW("SLOW") // Specify the output slew rate
       ) IOBUF_bootmode1 (
          .O(              ),       // Buffer output  2?1?D?
          .IO(dsp_bootmode [1]),     // Buffer inout port (connect directly to top-level port)
          .I(dsp_bootmode_r[1]),      	    // Buffer input
          .T(direc_change)      // 3-state enable input, high=input, low=output
       );
       
  //   boot[2]
       IOBUF #(
          .DRIVE(12), // Specify the output drive strength
          .IBUF_LOW_PWR("TRUE"),  // Low Power - "TRUE", High Performance = "FALSE" 
          .IOSTANDARD("DEFAULT"), // Specify the I/O standard
          .SLEW("SLOW") // Specify the output slew rate
       ) IOBUF_bootmode2 (
          .O(              ),       // Buffer output  2?1?D?
          .IO(dsp_bootmode [2]),     // Buffer inout port (connect directly to top-level port)
          .I(dsp_bootmode_r[2]),      	    // Buffer input
          .T(direc_change)      // 3-state enable input, high=input, low=output
       );
       
  //   boot[3]  只作为输出管脚
       IOBUF #(
          .DRIVE(12), // Specify the output drive strength
          .IBUF_LOW_PWR("TRUE"),  // Low Power - "TRUE", High Performance = "FALSE" 
          .IOSTANDARD("DEFAULT"), // Specify the I/O standard
          .SLEW("SLOW") // Specify the output slew rate
       ) IOBUF_bootmode3 (
          .O(  dsp_net_in_r     ),       // Buffer output  2?1?D?
          .IO(dsp_bootmode[3] ),     // Buffer inout port (connect directly to top-level port)
          .I(dsp_bootmode_r[3]),      	    // Buffer input
          .T(direc_change)      // 3-state enable input, high=input, low=output
       );
       
  //   boot[4]  只作为输出管脚
       IOBUF #(
          .DRIVE(12), // Specify the output drive strength
          .IBUF_LOW_PWR("TRUE"),  // Low Power - "TRUE", High Performance = "FALSE" 
          .IOSTANDARD("DEFAULT"), // Specify the I/O standard
          .SLEW("SLOW") // Specify the output slew rate
       ) IOBUF_bootmode4 (
          .O(              ),       // Buffer output  2?1?D?
          .IO(dsp_bootmode   [4]),     // Buffer inout port (connect directly to top-level port)
          .I(dsp_bootmode_out[4]),      	    // Buffer input
          .T(1'b0)      // 3-state enable input, high=input, low=output
       );
       
  //   boot[5]  只作为输出管脚
       IOBUF #(
          .DRIVE(12), // Specify the output drive strength
          .IBUF_LOW_PWR("TRUE"),  // Low Power - "TRUE", High Performance = "FALSE" 
          .IOSTANDARD("DEFAULT"), // Specify the I/O standard
          .SLEW("SLOW") // Specify the output slew rate
       ) IOBUF_bootmode5 (
          .O(              ),       // Buffer output  2?1?D?
          .IO(dsp_bootmode   [5]),     // Buffer inout port (connect directly to top-level port)
          .I(dsp_bootmode_out[5]),      	    // Buffer input
          .T(1'b0)      // 3-state enable input, high=input, low=output
       );
       
  //   boot[6]
       IOBUF #(
          .DRIVE(12), // Specify the output drive strength
          .IBUF_LOW_PWR("TRUE"),  // Low Power - "TRUE", High Performance = "FALSE" 
          .IOSTANDARD("DEFAULT"), // Specify the I/O standard
          .SLEW("SLOW") // Specify the output slew rate
       ) IOBUF_bootmode6 (
          .O( dsp_rst_in_r    ),       // Buffer output  2?1?D?
          .IO(dsp_bootmode [6]),     // Buffer inout port (connect directly to top-level port)
          .I(dsp_bootmode_r[6]),      	    // Buffer input
          .T(direc_change)      // 3-state enable input, high=input, low=output
       );
       
  
  
   IOBUF #(
      .DRIVE(12), // Specify the output drive strength
      .IBUF_LOW_PWR("TRUE"),  // Low Power - "TRUE", High Performance = "FALSE" 
      .IOSTANDARD("DEFAULT"), // Specify the I/O standard
      .SLEW("SLOW") // Specify the output slew rate
   ) IOBUF_inst (
      .O(         ),        // Buffer output  2?1?D?
      .IO(dsp_enddian),     // Buffer inout port (connect directly to top-level port)
      .I(1'b1),      	    // Buffer input
      .T(direc_change)      // 3-state enable input, high=input, low=output
   );	
                            // T = 1 ?òinout?aê?è?￡?·??ò?aê?3?

//--------------------------2015/11/2 15:06:58
 //         assign  tmp_p28 = clk_10mhz_led;
        
//   OBUF #(
//      .DRIVE(4),   // Specify the output drive strength
//      .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
//      .SLEW("SLOW") // Specify the output slew rate
//   ) OBUF_inst (
//      .O(tmp_p28),     // Buffer output (connect directly to top-level port)
//      .I(clk_10mhz_led)      // Buffer input 
//   );


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//// () signal assigment ////
      assign  lmk_pll_lock                 = lmk_pll_lock_reg;
	  
      assign  led_startus[0]               = 0;
      assign  led_startus[1]               = lmk_stable_lock;    
      assign  led_startus[2]               = dsp2fpga_dsp_rdy;
      assign  led_startus[3]               = clk_10mhz_led;
      assign  led_startus[4]               = clk_20mhz_led;
      assign  led_startus[5]               = clk_200mhz_led;
      
      assign  led_startus[6]               = clk_dcm1_pll;
      assign  led_startus[7]               = 0;          
      
      assign  dac_txenable                 = 1'd1;      //2015/9/29 11:42:28 时序未造，临时全开。

      
//cpld 
   //   assign  fpga_dsp_cfgok               = lmk_stable_lock ;     //FPGA对dsp配置设置完成。
      assign  fpga_dsp_cfgok               = lmk2dsp_pll_ok;
      // assign  fpga2cpld_dsp_rdy            = dsp_rdy;              //CPLD对dsp配置成功。
//lmk
      assign  lmk_clk_sel                  = 2'b0;
//dac 
     assign  dac_master_reset             = dac_rst;
     assign  dac_io_reset                 = 1'd0;
     assign  dac_ext_pwr_dwn              = 1'd0;

//-----------------
     assign   phy_rst      =        phy_rst_reg;
    // assign   phy_int      =        1'b1;
//------------------------------------------------------
     assign   dac_stat     =        dac_stat_reg;


//////////////////////////////////////////////////////////////////////////////////
////(0) clk pll
 always@(posedge clk_10mhz)      
 begin                                           
   if(lmk04806_2_holdover && lmk04806_1_holdover && lmk04806_1_locked_in)   
 	   lmk_pll_lock_reg  <= 1'd1;                   
   else
     lmk_pll_lock_reg  <= 1'd0;
end



//////////////////////////////////////////////////////////////////////////////////
////(@) 
 // always@(*)      
 // begin                                         
 	   // if(sys_rest)
 	      // dsp_bootmode_reg <= 7'b0000101;
 	   // else if(lmk_stable_lock)begin
 	   	      // if(dsp_mode == 2'b01)   // SPI   
 	            // dsp_bootmode_reg <= 7'b0000110;
 	          // else if(dsp_mode == 2'b10)  // I2C
 	            // dsp_bootmode_reg <= 7'b0000101; 	            
 	          // else                   //bootmode
 	            // dsp_bootmode_reg <= 7'b0000000;
 	   // end
 	   // else 
 	       // dsp_bootmode_reg <= 7'b0000101;
// end

//////////////////////////////////////////////////////////////////////////////////
////(@) 
 always@(*)      
 begin                                         
 	   if(sys_rest)
 	      dsp_rdy = 1'd0;
 	   else if(dsp2fpga_dsp_rdy || !dsp_mode)
 	      dsp_rdy = 1'd1;
 	   else
 	      dsp_rdy = 1'd0;
end






/*
时钟稳定性监测，用振源钟产生秒灯，以此作为参照观察其它时钟是否稳定。
观察闪动频率是否一致。
*/

//////////////////////////////////////////////////////////////////////////////////
////() 10兆 秒计数
always@(posedge clk_10mhz or posedge sys_rest)begin
    if (sys_rest)
      clk_10mhz_led_cnt <= 24'd0;
    else if(clk_10mhz_led_cnt == CLED10 - 1'd1)
      clk_10mhz_led_cnt <= 24'd0;
    else
      clk_10mhz_led_cnt <= clk_10mhz_led_cnt + 18'd1; 
end
//////////////////////////////////////////////////////////////////////////////////
////() 
always@(posedge clk_10mhz or posedge sys_rest)begin
    if (sys_rest)
      clk_10mhz_led <= 1'd0;
    else if(clk_10mhz_led_cnt == CLED10 - 1'd1)
      clk_10mhz_led <= ~clk_10mhz_led;
end

//////////////////////////////////////////////////////////////////////////////////
////() 20兆 秒计数
always@(posedge clk_20mhz_2 or posedge sys_rest)begin
    if (sys_rest)
      clk_20mhz_led_cnt <= 25'd0;
    else if(clk_20mhz_led_cnt == CLED20 - 1'd1)
      clk_20mhz_led_cnt <= 25'd0;
    else if(lmk_pll_lock_reg)
      clk_20mhz_led_cnt <= clk_20mhz_led_cnt + 25'd1;
    else 
    	clk_20mhz_led_cnt <= 25'd0;
end
//////////////////////////////////////////////////////////////////////////////////
////() 20兆 秒灯
always@(posedge clk_20mhz_2 or posedge sys_rest)begin
    if (sys_rest)
      clk_20mhz_led <= 1'd0;
    else if(clk_20mhz_led_cnt == CLED20 - 1'd1)
      clk_20mhz_led <= ~clk_20mhz_led;
end
//////////////////////////////////////////////////////////////////////////////////
////() 200兆 秒计数
always@(posedge clk_200mhz or posedge sys_rest)begin
    if (sys_rest)
      clk_200mhz_led_cnt <= 28'd0;
    else if(clk_200mhz_led_cnt == CLED200 - 1'd1)
      clk_200mhz_led_cnt <= 28'd0;
    else
      clk_200mhz_led_cnt <= clk_200mhz_led_cnt + 1'd1; 
end
//////////////////////////////////////////////////////////////////////////////////
////() 200兆 秒灯
always@(posedge clk_200mhz or posedge sys_rest)begin
    if (sys_rest)
      clk_200mhz_led <= 1'd0;
    else if(clk_200mhz_led_cnt == CLED200 - 1'd1)
      clk_200mhz_led <= ~clk_200mhz_led;
    else
      clk_200mhz_led <= clk_200mhz_led; 
end
//////////////////////////////////////////////////////////////////////////////////
////() DAC stat,产生DAC初始化信号，验证DAC rest是否持续一秒。 2015/10/26 9:02:50
always@(posedge clk_20mhz_2 or posedge sys_rest)begin
    if (sys_rest)
      dac_stat_en[3:0] <= 4'b0001;
    else if(clk_20mhz_led_cnt == CLED20 - 1'd1)
      dac_stat_en[3:1] <= dac_stat_en[2:0];
    else 
      dac_stat_en      <= dac_stat_en;
end
//////////////////////////////////////////////////////////////////////////////////
////() 时钟三秒产生2015/10/26 9:03:03
always@(posedge clk_20mhz_2 or posedge sys_rest)begin
    if (sys_rest)
      dac_stat_reg    <=1'b0;
    else if(clk_20mhz_led_cnt == CLED20 - 1'd1)begin
    	      if(dac_stat_en[2] && !dac_stat_en[3])
               dac_stat_reg    <=1'b1; 
            else
               dac_stat_reg    <=1'b0;
    end 
    else 
      dac_stat_reg    <=1'b0;
end
//////////////////////////////////////////////////////////////////////////////////
////(*)  DAc RST
always@(posedge clk_20mhz_2 or posedge sys_rest)begin
    if (sys_rest)
       dac_rst_cnt  <= 11'd1;  
    else if(dac_rst_cnt == 11'd21) 
       dac_rst_cnt  <= 11'd0;
    else if(dac_rst_cnt != 11'd0)
       dac_rst_cnt  <= dac_rst_cnt + 11'd1;  
    else 
       dac_rst_cnt  <= dac_rst_cnt;  
end
//////////////////////////////////////////////////////////////////////////////////
////(*)  DAc RST
always@(posedge clk_20mhz_2 or posedge sys_rest)begin
    if (sys_rest)
       dac_rst      <= 1'd0;  
    else if(dac_rst_cnt == 11'd20) 
       dac_rst      <= 1'd1; 
    else 
       dac_rst      <= 1'd0;
end




//////////////////////////////////////////////////////////////////////////////////
////(*)  网口初始化结束，开启int状态检测
always@(posedge clk_20mhz_2 or posedge sys_rest)begin
    if (sys_rest)
          phy_int_en <= 1'd0;
   else if(phy_cnt == PHY_N)
          phy_int_en <= 1'd1;
    else
         phy_int_en <= phy_int_en;
end   	     
//////////////////////////////////////////////////////////////////////////////////
////(*)  rest保持周期
always@(posedge clk_20mhz_2 or posedge sys_rest)begin
    if (sys_rest)
       phy_cnt  <= 32'd0;
    else if(phy_cnt == PHY_N)
       phy_cnt  <= 32'd0;
    else if(lmk_stable_lock)
       phy_cnt  <=  phy_cnt + 1'd1;
    else
       phy_cnt  <= phy_cnt;
end
//////////////////////////////////////////////////////////////////////////////////
////(*)  rest拉低后150ms检测INT信号状态，持续检测
always@(posedge clk_20mhz_2 or posedge sys_rest)begin
    if (sys_rest)
       phy_150ms_cnt  <= 32'd0;
    else if(phy_rst_reg)
      phy_150ms_cnt  <= 32'd0;
    else if(phy_150ms_cnt == CNT150MS)
      phy_150ms_cnt  <= phy_150ms_cnt;
    else if(phy_int_en)
       phy_150ms_cnt  <= phy_150ms_cnt + 1'd1;
    else
      phy_150ms_cnt  <= 32'd0;
end
//////////////////////////////////////////////////////////////////////////////////
////(*)  150ms后检测INT信号状态，持续检测
always@(posedge clk_20mhz_2 or posedge sys_rest)begin
    if (sys_rest)
       phy_int_state_en  <= 1'd0;
    else if(phy_150ms_cnt == CNT150MS)
      phy_int_state_en  <= 1'd1;
    else
      phy_int_state_en  <= 1'd0;
end
//////////////////////////////////////////////////////////////////////////////////
////(*)  INT错误响应，指导rest复位。
always@(posedge clk_20mhz_2 or posedge sys_rest)begin
    if (sys_rest)
       phy_int_err  <= 1'd0;
    else if(phy_int_state_en)begin
    	      if(phy_int)
    	        phy_int_err <= 1'd1;
    	      else
    	        phy_int_err <= 1'd0;
    end
    else
      phy_int_err  <= 1'd0;
    end
//////////////////////////////////////////////////////////////////////////////////
////(*)  rest - duration，rest保持时间，至少一个20ms
always@(posedge clk_20mhz_2 or posedge sys_rest)begin
    if (sys_rest)
       phy_rest_duration  <= 2'd0;
    else if(phy_rest_duration == 2'd2)
       phy_rest_duration  <= 2'd0;
    else if(phy_rst_reg && phy_int_en)begin
    	      if(phy_cnt == PHY_N)
    	        phy_rest_duration  <=  phy_rest_duration + 1'd1;
    	      else
    	        phy_rest_duration <= phy_rest_duration;
    end
    else
      phy_rest_duration  <= 2'd0;
    end
//////////////////////////////////////////////////////////////////////////////////
////(*)  PHY rst
always@(posedge clk_20mhz_2 or posedge sys_rest)begin
    if (sys_rest)
       phy_rst_reg  <= 1'd1;
    else if(phy_rest_duration == 2'd2 || phy_max_repeat == 2'd2)
       phy_rst_reg  <= 1'd0;
    else if(phy_int_en)begin
    	     if(phy_int_err)
    	       phy_rst_reg  <= 1'd1;
    	     else
    	       phy_rst_reg  <= phy_rst_reg;
    end
    else if(!phy_int_en && phy_cnt == PHY_N) 
       phy_rst_reg  <= 1'd0;
    else
       phy_rst_reg  <= phy_rst_reg;
end 
//////////////////////////////////////////////////////////////////////////////////
////(*)  PHY最大复位次数
always@(posedge clk_20mhz_2 or posedge sys_rest)begin
    if (sys_rest)
      phy_max_repeat <= 2'd0;
    else if(phy_rest_duration == 2'd2) 
       phy_max_repeat <= phy_max_repeat + 2'd1;
    else
       phy_max_repeat <= phy_max_repeat;
end
//////////////////////////////////////////////////////////////////////////////////
////(*) 这个配置下LMK失锁DSP不会掉电 2015/10/22 11:41:57
always@(posedge clk_20mhz_2 or posedge sys_rest)begin
    if (sys_rest) 
       lmk2dsp_pll_ok <= 1'd0;
//    else if(phy_rest_ok && lmk_stable_lock)
    else if(lmk_stable_lock)
       lmk2dsp_pll_ok <= 1'd1;
    else
       lmk2dsp_pll_ok <= lmk2dsp_pll_ok;
end     


//////////////////////////////////////////////////////////////////////////////////
//// debug signal ////
assign  debug_signal[63:0] = {dsp_bootmode_out[5:4],62'd0
                                //dsp_mode,
//                              lmk_stable_lock,
//                              lmk04806_1_holdover,
//                              lmk04806_1_locked_in,
//                              lmk04806_2_holdover,
//                              fpga_dsp_cfgok,
//                              fpga2cpld_dsp_rdy,
//                              lmk_pll_lock_reg,
//                         //     dsp_enddian,
//                              dsp_mode,
//                              dsp_bootmode_reg,
//                              clk_20mhz,
//                              phy_rst_reg,                           
//                              lmk2dsp_pll_ok,
//                              lmk_stable_lock,
//                              39'd0 ,     
//                              fpga_2cpld_rst3,
//                              dsp2fpga_dsp_rdy,
//                              0,
//                              0,
//                              0                    
                              };












////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////                                                                                                      
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
endmodule 




