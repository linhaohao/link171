////////////////////////////////////////////////////////////////////////////////
// Company: StarPoint
// Engineer: guanzheye
//
// Create Date: 
// Design Name: rf_cfg_top
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

module initial_ct(
// clock & Reset
input                    clk_20mhz,                    
input                    sys_rest,    
//------
input                    dsp_startus_rdy,
input                    lmk_pll_lock,

output reg               dsp_rdy_pulse,      //TO AD DA initial start
output reg               spi_initial_start,  //TO LMK   initial start
output reg               lmk_stable_lock,
output reg               repeat_failure_en,
output reg               initial_en,


output [63:0]            debug_signal 

);

//////////////////////////////////////////////////////////////////////////////////
//// parameter ////
parameter Repeat_N    = 4'd3;
parameter R_TIME      = 32'd6000000;   //250ms

//////////////////////////////////////////////////////////////////////////////////
//// signal declaration ////
reg [31:0]            spi_initial_time_cnt = 32'd0;
reg [5:0]             dsp_startus_rdy_dl = 6'd0;     
reg [1:0]             spi_initial_start_cnt = 2'd0;
//-------------------------------
reg                   stable_en = 1'd0;
reg [31:0]            stable_a_cnt = 32'd101;
reg [31:0]            stable_b_cnt = 32'd0;
//reg                   lmk_stable_lock = 1'd0;
reg [3:0]             repeat_cnt = 4'd0;
reg [31:0]            repeat_time_cnt = 32'd0;
//reg                   repeat_failure_en = 1'd0;





//////////////////////////////////////////////////////////////////////////////////
////(2) spi_initial_start  上电配置顺序
/*
1、CPLD启动FPGA加载，加载成功复位FPGA。
2、FPGA用10MHZ时钟倍频20MHZ、通过SPI配置LMK04806,LMK锁定后保持DSP寄存器配置，告知CPLD配置完毕。
3、CPLD得到FPGA配置DSP完毕信号，开始上电配置并复位DSP等操作。                                                           
4、FPGA得到DSP RDY信号，送给CPLD，同时开启配置AD/DA/射频本震。
*/    
//------

always@(posedge clk_20mhz or posedge sys_rest)begin
    if (sys_rest)
        initial_en <= 1'd1;
    else if(spi_initial_time_cnt == 32'd9999 || lmk_pll_lock)
        initial_en <= 1'd0;
    else
        initial_en <= initial_en;
end



//initial_time_cnt
always@(posedge clk_20mhz or posedge sys_rest)begin
    if (sys_rest)
       spi_initial_time_cnt <= 32'd0;
    else if (spi_initial_time_cnt == 32'd10000)
       spi_initial_time_cnt <= spi_initial_time_cnt;
    else
       spi_initial_time_cnt <= spi_initial_time_cnt  + 1'd1;
end

//////////////////////////////////////////////////////////////////////////////////
////(2) dsp rdy_dl 
always@(posedge clk_20mhz or posedge sys_rest)begin
    if (sys_rest)
      dsp_startus_rdy_dl[5:0] <= 6'd0;
    else 
   //   dsp_startus_rdy_dl[5:0] <= {dsp_startus_rdy,dsp_startus_rdy_dl[5:1]};    2015/10/21 15:30:06 
      dsp_startus_rdy_dl[5:0] <= {lmk_stable_lock,dsp_startus_rdy_dl[5:1]};   
    end  
//////////////////////////////////////////////////////////////////////////////////
////() dsp rdy_dl 
always@(posedge clk_20mhz or posedge sys_rest)begin
    if (sys_rest)
	   dsp_rdy_pulse <= 1'd0;
    else if(dsp_startus_rdy_dl[1] && !dsp_startus_rdy_dl[0])
      dsp_rdy_pulse <= 1'd1;
    else 
      dsp_rdy_pulse <= 1'd0;
end          
//////////////////////////////////////////////////////////////////////////////////
////(2-1) spi_initial_start      
always@(posedge clk_20mhz or posedge sys_rest)begin
    if (sys_rest)
       spi_initial_start <= 1'd0;
    else if (spi_initial_time_cnt == 32'd999|| (repeat_time_cnt == R_TIME && repeat_cnt != Repeat_N))   //lmk
       spi_initial_start <= 1'd1;
    else
       spi_initial_start <= 1'd0;
end

reg [3:0]   lmk_pll_lock_reg = 4'd0;

//////////////////////////////////////////////////////////////////////////////////
////(*) 检测稳定  Stable
always@(posedge clk_20mhz or posedge sys_rest)begin
    if (sys_rest)
        lmk_pll_lock_reg[3:0]   <=  4'd0;
    else
        lmk_pll_lock_reg[3:0]   <=  {lmk_pll_lock_reg[2:0],lmk_pll_lock};
end
      // stable_en <= 1'd0;
    // else if(stable_a_cnt == 32'd3000)
      // stable_en <= 1'd0;
    // else if(lmk_pll_lock && stable_b_cnt == 32'd100)
      // stable_en <= 1'd1;
    // else
      // stable_en <= stable_en;
    // end
//////////////////////////////////////////////////////////////////////////////////
////(*-1) 检测稳定  Stable
always@(posedge clk_20mhz or posedge sys_rest)begin
    if (sys_rest) begin
        stable_a_cnt <= 32'd0;
        lmk_stable_lock <= 1'd0;
    end
    else if(stable_a_cnt >= 32'd2000000) begin  //100ms计数
        stable_a_cnt <= stable_a_cnt;
        lmk_stable_lock <= 1'd1;
    end
    else if((!lmk_pll_lock) && (lmk_pll_lock_reg[3:2] == 2'b01))
        stable_a_cnt <= 32'd0;
    else if(lmk_pll_lock)
        stable_a_cnt <= stable_a_cnt + 1'd1;
    else begin
        lmk_stable_lock <= lmk_stable_lock ;
        stable_a_cnt <= stable_a_cnt;
    end
end   
// always@(posedge clk_20mhz or posedge sys_rest)begin
    // if (sys_rest || lmk_stable_lock)
      // stable_a_cnt <= 32'd101;
    // else if(stable_a_cnt == 32'd3000)
      // stable_a_cnt <= 32'd101;
    // else if(stable_en)
      // stable_a_cnt <= stable_a_cnt + 1'd1;
    // else
      // stable_a_cnt <= stable_a_cnt;
    // end    
//////////////////////////////////////////////////////////////////////////////////
////(*-1) 检测稳定  Stable
// always@(posedge clk_20mhz or posedge sys_rest)begin
    // if (sys_rest || lmk_stable_lock)
      // stable_b_cnt <= 32'd0;
    // else if(stable_a_cnt == 32'd3000)
      // stable_b_cnt <= 32'd0;  
    // else if(lmk_pll_lock)
      // stable_b_cnt <= stable_b_cnt + 1'd1;
    // else
      // stable_b_cnt <= stable_b_cnt;
    // end
//////////////////////////////////////////////////////////////////////////////////
////(*-1) 检测稳定  Stable
// always@(posedge clk_20mhz or posedge sys_rest)begin
    // if (sys_rest || !lmk_pll_lock)
      // lmk_stable_lock <= 1'd0;
    // else if(stable_b_cnt == 32'd2998)begin
       // if(stable_a_cnt == stable_b_cnt)
            // lmk_stable_lock <= 1'd1;
       // else 
            // lmk_stable_lock <= lmk_stable_lock ;
    // end
    // else 
      // lmk_stable_lock <= lmk_stable_lock ;
    // end
//////////////////////////////////////////////////////////////////////////////////
////(A-1) Repeat_N  重配机制
always@(posedge clk_20mhz or posedge sys_rest)begin
    if (sys_rest)
      repeat_cnt <= 4'd0;
    else if(repeat_cnt == Repeat_N)
      repeat_cnt <= repeat_cnt;  
    else if(spi_initial_start && !lmk_pll_lock)
      repeat_cnt <= repeat_cnt + 4'd1;
    else
      repeat_cnt <= repeat_cnt;
end
//////////////////////////////////////////////////////////////////////////////////
////(A-2) Repeat_N  重配j间隔
always@(posedge clk_20mhz or posedge sys_rest)begin
    if (sys_rest)
      repeat_time_cnt <= 32'd0;
    else if(spi_initial_start || lmk_pll_lock || repeat_cnt == Repeat_N)
      repeat_time_cnt <= 32'd0;
    else 
      repeat_time_cnt <= repeat_time_cnt + 1'd1;
end
//////////////////////////////////////////////////////////////////////////////////
////(X) Repeat_N   Failure 三次失败点灯 LED
always@(posedge clk_20mhz or posedge sys_rest)begin
    if (sys_rest)
      repeat_failure_en <= 1'd0;
    else if(repeat_cnt == Repeat_N && !lmk_pll_lock)
      repeat_failure_en <= 1'd1;
    else
      repeat_failure_en <= 1'd0;
end




//////////////////////////////////////////////////////////////////////////////////
//// debug signal ////
assign  debug_signal[63:0]              = {dsp_startus_rdy,
                                           lmk_pll_lock,
                                           lmk_stable_lock,
                                           dsp_rdy_pulse,
                                           spi_initial_start,
                                           repeat_failure_en,
                                           initial_en,
                                           57'd0                                           
                                           };













////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////                                                                                                      
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
endmodule     















