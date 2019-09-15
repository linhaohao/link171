//////////////////////////////////////////////////////////////////////////////////
// Company:        StarPoint
// Engineer:       GUOYAN
// 
// Create Date:    17:44:04 09/08/2014 
// Module Name:    clk_module_top 
// Project Name:   clock CMT module
// Target Devices: FPGA - XC7K325T - FFG900;
// Tool versions:  ISE14.6
// Description:    There are two DCM module, one which from 10MHz crystal is divided/multiply to 
//                 400KHz/7.378MHz/20MHz/10MHz(40MHz) for I2C/UART/MCBSP/SPI interface logic; another which from LMK04806 is divided/multiply to
//                 200MHz/25MHz for internal logic. 
//
//
// Revision:       v1.0 - File Created
// Additional Comments: 

//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps


module clk_loop_top(
// clock/rst
input               clk_gloal_in,    
input               hardware_rst_in,

output              clk_logic_out,           //200MHz  
output              clk_20MHz_out,           //20MHz
output              clk_25MHz_out,           //25MHz
output              clk_50MHz_out,           //50MHz

output              mmcm0_locked_out
    
	 );

//////////////////////////////////////////////////////////////////////////////////
//// signal declaration ////
wire        mmcm0_clkfbout;
wire        mmcm0_clkfb_buf;
wire        mmcm0_clkout0;
wire        mmcm0_clkout1;
wire        mmcm0_clkout2;
wire        mmcm0_locked;


//////////////////////////////////////////////////////////////////////////////////
//// parameter ////


//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//// signal assignment ////
    assign  mmcm0_locked_out             = hardware_rst_in ? 1'b0 : mmcm0_locked;

	assign  clk_logic_out                = mmcm0_clkfb_buf; //200MHz

  
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//// (2) Second MMCM for logic clock ////
MMCME2_BASE
  #(.BANDWIDTH            ("OPTIMIZED"),
    .CLKOUT4_CASCADE      ("FALSE"),
    .STARTUP_WAIT         ("FALSE"),
    .DIVCLK_DIVIDE        (1),
    .CLKFBOUT_MULT_F      (5.000),           
    .CLKFBOUT_PHASE       (0.000),
    .CLKOUT0_DIVIDE_F     (50.000),           //20MHz CLKFBOUT_MULT_F/(DIVCLK_DIVIDE*CLKOUT0_DIVIDE_F)
    .CLKOUT0_PHASE        (0.000),
    .CLKOUT0_DUTY_CYCLE   (0.500),
    .CLKOUT1_DIVIDE       (40),
    .CLKOUT1_PHASE        (0.000),
    .CLKOUT1_DUTY_CYCLE   (0.500),
	.CLKOUT2_DIVIDE       (20),
    .CLKOUT2_PHASE        (0.000),
    .CLKOUT2_DUTY_CYCLE   (0.500),
    .CLKIN1_PERIOD        (5.000),            //input clock 200M = 5ns
    .REF_JITTER1          (0.010))            //input jitter 0.010UI(default)
  u1_mmcm_base
    // Output clocks
   (.CLKFBOUT            (mmcm0_clkfbout),
    .CLKFBOUTB           (),
    .CLKOUT0             (mmcm0_clkout0), //20M
    .CLKOUT0B            (),
    .CLKOUT1             (mmcm0_clkout1), //25M
    .CLKOUT1B            (),
    .CLKOUT2             (mmcm0_clkout2), //50M
    .CLKOUT2B            (),
    .CLKOUT3             (),
    .CLKOUT3B            (),
    .CLKOUT4             (),
    .CLKOUT5             (),
    .CLKOUT6             (),
     // Input clock control
    .CLKFBIN             (mmcm0_clkfb_buf),
    .CLKIN1              (clk_gloal_in),
    // Other control and status signals
    .LOCKED              (mmcm0_locked),
    .PWRDWN              (1'b0),
    .RST                 (hardware_rst_in));

  // Output buffering
  //-----------------------------------
  BUFG mmcm1_clkf_buf
   (.O (mmcm0_clkfb_buf),
    .I (mmcm0_clkfbout));

  BUFG mmcm1_clkout0_buf
   (.O   (clk_20MHz_out),
    .I   (mmcm0_clkout0));
	
  BUFG mmcm1_clkout1_buf
   (.O   (clk_25MHz_out),
    .I   (mmcm0_clkout1));
	
  BUFG mmcm1_clkout2_buf
   (.O   (clk_50MHz_out),
    .I   (mmcm0_clkout2));
	
 
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
endmodule
