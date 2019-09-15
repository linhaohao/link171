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
// 1. MMCM(zero)  input = 10MHz,output=10MHz/20MHz/40MHz/7.378MHz/400KHz(counter);
// 2. MMCM(one)  input = 200MHz, output=200MHz/25MHz.

//----------------------------------------------------------------------------
// "Output    Output      Phase     Duty      Pk-to-Pk        Phase"
// "Clock    Freq (MHz) (degrees) Cycle (%) Jitter (ps)  Error (ps)"
//----------------------------------------------------------------------------
// CLK_OUT1____20.000______0.000______50.0______796.553____874.060
// CLK_OUT2____40.000______0.000______50.0______722.527____874.060
// CLK_OUT3___100.000______0.000______50.0______635.630____874.060
//
//----------------------------------------------------------------------------
// "Input Clock   Freq (MHz)    Input Jitter (UI)"
//----------------------------------------------------------------------------
// __primary______________10____________0.001
//
//----------------------------------------------------------------------------
// "Output    Output      Phase     Duty      Pk-to-Pk        Phase"
// "Clock    Freq (MHz) (degrees) Cycle (%) Jitter (ps)  Error (ps)"
//----------------------------------------------------------------------------
//CLK_OUT1____25.000______0.000______50.0______148.629____89.971
//CLK_OUT2____50.000______0.000______50.0______129.198____89.971
//
//----------------------------------------------------------------------------
// "Input Clock   Freq (MHz)    Input Jitter (UI)"
//----------------------------------------------------------------------------
// __primary_________200.000____________0.010
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps


module clk_module_top(
// clock/rst
input               clk_gloal_in,    
input               clk_10MHz_in,
input               clk_rst_in,               // rst from LMK04806 locked
input               hardware_rst_in,

output              clk_logic_out,           //200MHz  
output              clk_20MHz,           //20MHz
output              clk_50MHz_out,           //50MHz
                                 
output              clk_400KHz_out,          //400KHz
output              clk_100MHz_out,          //100MHz
output              clk_5MHz_out,           //40MHz
output              clk_20MHz_out,           //20MHz
output              clk_10MHz_out,           //10MHz

output              mmcm0_locked_out,
output              mmcm1_locked_out

//output[63:0]        debug_signal
    
	 );

//////////////////////////////////////////////////////////////////////////////////
//// signal declaration ////
wire        mmcm0_clkfbout;
wire        mmcm0_clkfb_buf;
wire        mmcm0_clkout0;
wire        mmcm0_clkout1;
wire        mmcm0_clkout2;
wire        mmcm0_locked;

wire        mmcm1_clkfbout;
wire        mmcm1_clkfb_buf;
wire        mmcm1_clkout0;
wire        mmcm1_clkout1;
wire        mmcm1_locked;

reg         mmcm1_rst_in = 1'b0;
reg [15:0]  mmcm1_rst_count = 16'd0;
reg [ 4:0]  clk_divider = 5'd0;


//////////////////////////////////////////////////////////////////////////////////
//// parameter ////


//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//// signal assignment ////
    assign  mmcm0_locked_out             = hardware_rst_in ? 1'b0 : mmcm0_locked;
    assign  mmcm1_locked_out             = hardware_rst_in ? 1'b0 : mmcm1_locked;

	assign  clk_10MHz_out                = mmcm0_clkfb_buf; //10MHz	
	assign  clk_logic_out                = mmcm1_clkfb_buf; //200MHz

//////////////////////////////////////////////////////////////////////////////////
//// (1) First MMCM for 10MHz cystal ////
MMCME2_BASE
  #(.BANDWIDTH            ("OPTIMIZED"),
    .CLKOUT4_CASCADE      ("FALSE"),
    .STARTUP_WAIT         ("FALSE"),
    .DIVCLK_DIVIDE        (1),
    .CLKFBOUT_MULT_F      (60.000),
    .CLKFBOUT_PHASE       (0.000),
    .CLKOUT0_DIVIDE_F     (30.000),         //clk0 20MHz; 10M*CLKFBOUT_MULT_F/CLKOUT0_DIVIDE_F
    .CLKOUT0_PHASE        (0.000),
    .CLKOUT0_DUTY_CYCLE   (0.500),         //50% Duty Ratio
    .CLKOUT1_DIVIDE       (120),            //clk1 5MHz; 10M*CLKFBOUT_MULT_F/CLKOUT1_DIVIDE_F
    .CLKOUT1_PHASE        (0.000),
    .CLKOUT1_DUTY_CYCLE   (0.500),         //50% Duty Ratio
	.CLKOUT2_DIVIDE       (6),            //clk1 100MHz; 10M*CLKFBOUT_MULT_F/CLKOUT2_DIVIDE_F
    .CLKOUT2_PHASE        (0.000),
    .CLKOUT2_DUTY_CYCLE   (0.500),         //50% Duty Ratio
    .CLKIN1_PERIOD        (100.0),        //input clock 10M = 100ns
    .REF_JITTER1          (0.001))         //input jitter 0.001UI(user enter)
  u0_mmcm_base
    // Output clocks
   (.CLKFBOUT            (mmcm0_clkfbout),
    .CLKFBOUTB           (),
    .CLKOUT0             (mmcm0_clkout0),
    .CLKOUT0B            (),
    .CLKOUT1             (mmcm0_clkout1),
    .CLKOUT1B            (),
    .CLKOUT2             (mmcm0_clkout2),
    .CLKOUT2B            (),
    .CLKOUT3             (),
    .CLKOUT3B            (),
    .CLKOUT4             (),
    .CLKOUT5             (),
    .CLKOUT6             (),
     // Input clock control
    .CLKFBIN             (mmcm0_clkfb_buf),
    .CLKIN1              (clk_10MHz_in),
    // Other control and status signals
    .LOCKED              (mmcm0_locked),
    .PWRDWN              (1'b0),
    .RST                 (hardware_rst_in));

  // Output buffering
  //-----------------------------------
  BUFG mmcm0_clkf_buf
   (.O (mmcm0_clkfb_buf),
    .I (mmcm0_clkfbout));

  BUFG mmcm0_clkout1_buf
   (.O   (clk_20MHz_out),
    .I   (mmcm0_clkout0));
	
  BUFG mmcm0_clkout2_buf
   (.O   (clk_5MHz_out),
    .I   (mmcm0_clkout1));
	
 BUFG mmcm0_clkout3_buf
   (.O   (clk_100MHz_out),
    .I   (mmcm0_clkout2));
	 
//////////////////////////////////////////////////////////////////////////////////
//// I2C clock generator ////
//always@(posedge clk_10MHz_out)
//begin
//  if (clk_divider[4:0] == 5'd27)   begin
//    clk_divider[4:0]                    <= 5'd0;
//  end
//  else   begin
//    clk_divider[4:0]                    <= clk_divider[4:0] + 1'b1;
//  end 
//end
//
//assign  clk_400KHz_out                = clk_divider[4];
reg [11:0] count;
reg clk_500kHz;
always@(posedge clk_50MHz_out )
begin
    if(count == 12'd49)begin
	  	count <= 12'd0;
	  end
	  else begin
	  	count <= count + 12'd1;
	  end
end

always@(posedge clk_50MHz_out )
begin
    if(count == 12'd49)begin
	  	clk_500kHz <= !clk_500kHz;
	  end
	  else begin
	  	clk_500kHz <= clk_500kHz;
	  end
end


assign  clk_400KHz_out                = clk_500kHz;  
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
    .CLKOUT1_DIVIDE       (20),
    .CLKOUT1_PHASE        (0.000),
    .CLKOUT1_DUTY_CYCLE   (0.500),
    .CLKIN1_PERIOD        (5.000),            //input clock 200M = 5ns
    .REF_JITTER1          (0.010))            //input jitter 0.010UI(default)
  u1_mmcm_base
    // Output clocks
   (.CLKFBOUT            (mmcm1_clkfbout),
    .CLKFBOUTB           (),
    .CLKOUT0             (mmcm1_clkout0),
    .CLKOUT0B            (),
    .CLKOUT1             (mmcm1_clkout1),
    .CLKOUT1B            (),
    .CLKOUT2             (),
    .CLKOUT2B            (),
    .CLKOUT3             (),
    .CLKOUT3B            (),
    .CLKOUT4             (),
    .CLKOUT5             (),
    .CLKOUT6             (),
     // Input clock control
    .CLKFBIN             (mmcm1_clkfb_buf),
    .CLKIN1              (clk_gloal_in),
    // Other control and status signals
    .LOCKED              (mmcm1_locked),
    .PWRDWN              (1'b0),
    .RST                 (mmcm1_rst_in));

  // Output buffering
  //-----------------------------------
  BUFG mmcm1_clkf_buf
   (.O (mmcm1_clkfb_buf),
    .I (mmcm1_clkfbout));

  BUFG mmcm1_clkout0_buf
   (.O   (clk_20MHz),
    .I   (mmcm1_clkout0));
	
BUFG mmcm1_clkout1_buf
  (.O   (clk_50MHz_out),
   .I   (mmcm1_clkout1));
	
	

//////////////////////////////////////////////////////////////////////////////////
//// mmcm1 reset logic ////
always@(posedge clk_10MHz_out or posedge clk_rst_in)
begin
  if (clk_rst_in)   begin
     mmcm1_rst_in                         <= 1'b1;
	 mmcm1_rst_count[15:0]                <= 16'd0;
  end
  else if (mmcm1_locked)   begin
     mmcm1_rst_in                         <= 1'b0;
	 mmcm1_rst_count[15:0]                <= 16'd0;  
  end
  else if (mmcm1_rst_count[15:0] > 16'd65500)   begin
     mmcm1_rst_in                         <= 1'b1;
	 mmcm1_rst_count[15:0]                <= mmcm1_rst_count[15:0] + 1'b1;   
  end
  else   begin
     mmcm1_rst_in                         <= 1'b0;
	 mmcm1_rst_count[15:0]                <= mmcm1_rst_count[15:0] + 1'b1;   
  end
end

  
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
endmodule
