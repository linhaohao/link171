//////////////////////////////////////////////////////////////////////////////////
// Company:        StarPoint
// Engineer:       guanzheye 
// 
// Create Date:    2015/9/10 16:48:36 
// Module Name:    if_data_process_top 
// Project Name:   DAC/ADC interface and data Process
// Target Devices: FPGA XC7K325T-2FFG900   
// Tool versions:  ISE14.6
// Description:    
//                 DAC 和 ADC 的数据传输顶层
// Revision:       v1.0 - File Created
// Additional Comments: 
//
//
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps


module if_data_process_top(
// clock & Reset
input                    sys_clk,                           
input                    sys_rst,     
input                    clk_25m,       
input                    clk_50m,                                           
// UL signal stream  ADC0 IN
input [6:0]              adc0_data_a_p,
input [6:0]              adc0_data_a_n,
input [6:0]              adc0_data_b_p,
input [6:0]              adc0_data_b_n,
input                    adc0_or_p,
input                    adc0_or_n,
// input                    adc0_clkout_p,
// input                    adc0_clkout_n,
input                    adc0_clk,

input [31:0]             mif_adc_mode,


input [15:0]             mif_dcoff_0a,
input [15:0]             mif_dcoff_0b,
input [15:0]             mif_dcoff_1a,
input [15:0]             mif_dcoff_1b,
output [28:0]            dcoff2mif_0a_data,





//-------------ADC1 IN
input                    mif_adc_fifo_rst,
input [6:0]              adc1_data_a_p,
input [6:0]              adc1_data_a_n,
input [6:0]              adc1_data_b_p,
input [6:0]              adc1_data_b_n,
input                    adc1_or_p,
input                    adc1_or_n,
// input                    adc1_clkout_p,
// input                    adc1_clkout_n,
input                    adc1_clk,

//------------ADC OUT
output [15:0]            adc0_data_a_out,
output [15:0]            adc0_data_b_out,
output [15:0]            adc1_data_a_out,
output [15:0]            adc1_data_b_out,
// DL signal stream
input                    dac_data_clk_buf,        
input                    dac_pll_lock,      
//-------------DAC OUT 
input                    dl_data_dac_window,
input                    logic_rst,
input                    tx_stat,
output                   dac_txenable,
input  [15:0]            mif_dac_data_mode,                    
input  [31:0]            msk_iq_data,     
input                    msk_data_valid,
//input  [31:0]            mif_dac_dl_time,


output [17:0]            dac_data,
//-------------DEBUG     -----------------
output [199:0]            adc_debug_signal	,	
output [199:0]            dac_debug_signal	,	
output [199:0]            dcoff_debug_signal

    );
//////////////////////////////////////////////////////////////////////////////////
//// signal declaration ////
//reg                      tx_en;
//wire [17:0]            dac_data;   
wire [15:0]            adc0_data_a;
wire [15:0]            adc0_data_b;
wire [15:0]            adc1_data_a;
wire [15:0]            adc1_data_b;  


wire [15:0]            dcoff_data_0a;
wire [15:0]            dcoff_data_0b;
wire [15:0]            dcoff_data_1a;
wire [15:0]            dcoff_data_1b;
wire [199:0]           adc_debug;
//wire [199:0]          dcoff_debug_signal;


reg signed[15:0]            adc0_data_a_out_reg;
reg signed[15:0]            adc0_data_b_out_reg;
reg signed[15:0]            adc1_data_a_out_reg;
reg signed[15:0]            adc1_data_b_out_reg;



assign    adc0_data_a_out   = adc0_data_a_out_reg;
assign    adc0_data_b_out   = adc0_data_b_out_reg;
assign    adc1_data_a_out   = adc1_data_a_out_reg;
assign    adc1_data_b_out   = adc1_data_b_out_reg;







//////////////////////////////////////////////////////////////////////////////////
////(1) ad 接收数据处理
ad_receive U1_ad_receive(
                .sys_clk                 (sys_clk),
                .sys_rst                 (sys_rst),
                .adc_switch              (2'b11  ),
				        .mif_adc_fifo_rst        (mif_adc_fifo_rst),
				        .mif_adc_mode            (mif_adc_mode[15:0]),
//-------------ADC0 IN-------------------------------------------
                .adc0_data_a_p           (adc0_data_a_p),
                .adc0_data_a_n           (adc0_data_a_n),
                .adc0_data_b_p           (adc0_data_b_p),
                .adc0_data_b_n           (adc0_data_b_n),
                .adc0_or_p               (adc0_or_p    ),
                .adc0_or_n               (adc0_or_n    ),
                // .adc0_clkout_p           (adc0_clkout_p),
                // .adc0_clkout_n           (adc0_clkout_n),
				.adc0_clk                (adc0_clk     ),
//-------------ADC1 IN-------------------------------------------
                .adc1_data_a_p           (adc1_data_a_p),
                .adc1_data_a_n           (adc1_data_a_n),
                .adc1_data_b_p           (adc1_data_b_p),
                .adc1_data_b_n           (adc1_data_b_n),
                .adc1_or_p               (adc1_or_p    ),
                .adc1_or_n               (adc1_or_n    ),
                // .adc1_clkout_p           (adc1_clkout_p),
                // .adc1_clkout_n           (adc1_clkout_n),
				.adc1_clk                (adc1_clk     ),
//-------------ADC OUT------------------------------------------
                .adc0_data_a_out         (adc0_data_a     ),
                .adc0_data_b_out         (adc0_data_b     ),
                .adc1_data_a_out         (adc1_data_a     ),          
                .adc1_data_b_out         (adc1_data_b     ),
                .debug_signal            (adc_debug)

);

//////////////////////////////////////////////////////////////////////////////////
////(2) da 发送数据处理
da_send_out U2_da_send_out(
               .clk_50m                   (clk_50m),
               .clk_25m                   (clk_25m),
               .sys_rst                   (sys_rst),
			   .logic_rst                 (logic_rst),
//-------------DAC IN------------------------------------------
             //  .mif_dac_dl_time           (mif_dac_dl_time),
               .dac_tx_en                 (dac_txenable),
               .mif_dac_data_mode         (mif_dac_data_mode),
               .dac_data_clk_buf          (dac_data_clk_buf),    
               .dac_pll_lock              (dac_pll_lock),                 
               .msk_iq_data               (msk_iq_data),
               .msk_data_valid            (msk_data_valid),  
               .dl_data_dac_window        (dl_data_dac_window),			   
//-------------DAC OUT-----------------------------------------                                           
               .dac_data                  (dac_data),  
               .debug_signal              (dac_debug_signal)     
);


ad_dc_off  U3_ad_dc_off(
               .sys_clk                    (sys_clk        ),          //200
               .sys_rst                    (sys_rst        ),
//--------------------------------------------------adc in
               .adc2dcoff_data_0a          (adc0_data_a    ),
               .adc2dcoff_data_0b          (adc0_data_b    ),
               .adc2dcoff_data_1a          (adc1_data_a    ),
               .adc2dcoff_data_1b          (adc1_data_b    ),
//--------------------------------------------------mif cfg
               .mif_dcoff_0a                (mif_dcoff_0a  ),
               .mif_dcoff_0b                (mif_dcoff_0b  ),
               .mif_dcoff_1a                (mif_dcoff_1a  ),
               .mif_dcoff_1b                (mif_dcoff_1b  ),
              // .mif_dcoff_mode              (mif_adc_mode[30:29]),
               .dcoff2mif_0a_data           (dcoff2mif_0a_data  ),
//--------------------------------------------------out
               .dcoff2adc_data_0a          (dcoff_data_0a   ),
               .dcoff2adc_data_0b          (dcoff_data_0b   ),
               .dcoff2adc_data_1a          (dcoff_data_1a   ),
               .dcoff2adc_data_1b          (dcoff_data_1b   ),
//--------------------------------------------------
               .debug_signal               (dcoff_debug_signal)
);

//////////////////////////////////////////////////////////////////////////////////
//// ADC DATA OUT MODE
always@(posedge sys_clk or posedge sys_rst)
begin
     if(sys_rst)begin
       adc0_data_a_out_reg <= 16'd0;
       adc0_data_b_out_reg <= 16'd0;
       adc1_data_a_out_reg <= 16'd0;
       adc1_data_b_out_reg <= 16'd0;
     end       
     else if(!mif_adc_mode[31])begin
     	 adc0_data_a_out_reg <= adc0_data_a;    //ADC out
       adc0_data_b_out_reg <= adc0_data_b;    
       adc1_data_a_out_reg <= adc1_data_a;    
       adc1_data_b_out_reg <= adc1_data_b;       	
     end   
     else begin
       adc0_data_a_out_reg <= dcoff_data_0a;  //dcoff out     	
       adc0_data_b_out_reg <= dcoff_data_0b;       	
       adc1_data_a_out_reg <= dcoff_data_1a;       	
       adc1_data_b_out_reg <= dcoff_data_1b;       	                                	
     end
end




assign    adc_debug_signal[127:0]     = adc_debug[127:0];
assign    adc_debug_signal[143:128]   = adc0_data_a_out_reg;
assign    adc_debug_signal[159:144]   = adc0_data_b_out_reg;
assign    adc_debug_signal[175:160]   = adc1_data_a_out_reg;
assign    adc_debug_signal[191:176]   = adc1_data_b_out_reg;
assign    adc_debug_signal[199:192]   = 8'd0;





endmodule
