////////////////////////////////////////////////////////////////////////////////
// Company:  StarPoint
// Engineer: GZY
//
// Create Date: <date>
// Design Name: <name_of_top-level_design>
// Module Name: <name_of_this_module>
// Target Device: FPGA XC7K325T-2FFG900 
// Tool versions: <tool_versions>
// Description:
//    <Description here>
// Dependencies:
//    <Dependencies here>
// Revision:
//    <Code_revision_information>
// Additional Comments:
//    对AD FIFO输出数据做去除直流操作。
////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

module ad_dc_off(

input                    sys_clk,          //200
input                    sys_rst,
//--------------------------------------------------
input [15:0]             adc2dcoff_data_0a,
input [15:0]             adc2dcoff_data_0b,
input [15:0]             adc2dcoff_data_1a,
input [15:0]             adc2dcoff_data_1b,
//--------------------------------------------------
input [15:0]             mif_dcoff_0a,
input [15:0]             mif_dcoff_0b,
input [15:0]             mif_dcoff_1a,
input [15:0]             mif_dcoff_1b,
//input  [1:0]             mif_dcoff_mode,
output [28:0]            dcoff2mif_0a_data,


//--------------------------------------------------
output [15:0]            dcoff2adc_data_0a,
output [15:0]            dcoff2adc_data_0b,
output [15:0]            dcoff2adc_data_1a,
output [15:0]            dcoff2adc_data_1b,
//--------------------------------------------------
output [199:0]           debug_signal
);
//////////////////////////////////////////////////////////////////////////////////
//// parameters define ////
parameter COUNT_N = 16'd8191;


reg [15:0]   rx_dcoff_count;
reg          rx_dcoff_en;

reg signed[28:0]   adc_dc_off_0a;
reg signed[28:0]   adc_dc_off_0b;
reg signed[28:0]   adc_dc_off_1a;
reg signed[28:0]   adc_dc_off_1b;


reg signed[28:0]   adc_dc_off_0a_reg;
reg signed[28:0]   adc_dc_off_0b_reg;
reg signed[28:0]   adc_dc_off_1a_reg;
reg signed[28:0]   adc_dc_off_1b_reg;

reg signed[15:0]   dcoff2adc_data_0a_reg;
reg signed[15:0]   dcoff2adc_data_0b_reg;
reg signed[15:0]   dcoff2adc_data_1a_reg;
reg signed[15:0]   dcoff2adc_data_1b_reg;



//-----------------------------------------------------

assign dcoff2adc_data_0a     = dcoff2adc_data_0a_reg; 
assign dcoff2adc_data_0b     = dcoff2adc_data_0b_reg; 
assign dcoff2adc_data_1a     = dcoff2adc_data_1a_reg; 
assign dcoff2adc_data_1b     = dcoff2adc_data_1b_reg; 

assign dcoff2mif_0a_data     = adc_dc_off_0a_reg;





//////////////////////////////////////////////////////////////////////////////////
//// ADC DC OFF   
always@(posedge sys_clk or posedge sys_rst)
begin
     if(sys_rst)
       rx_dcoff_count <= 16'd0;
     else if(rx_dcoff_count == COUNT_N)
       rx_dcoff_count <= 16'd0;
     else
       rx_dcoff_count <= rx_dcoff_count + 1'd1;
end

//////////////////////////////////////////////////////////////////////////////////
//// ADC DC OFF   0A
always@(posedge sys_clk or posedge sys_rst)
begin
     if(sys_rst)
       adc_dc_off_0a <= 29'd0;
     else if(rx_dcoff_count == COUNT_N)
       adc_dc_off_0a <= 29'd0;
     else
       adc_dc_off_0a <= adc_dc_off_0a + {{13{adc2dcoff_data_0a[15]}},adc2dcoff_data_0a[15:0]};
end   	
//---------------------------------------------------------------------------------
always@(posedge sys_clk or posedge sys_rst)
begin
     if(sys_rst)
       adc_dc_off_0a_reg <= 29'd0;
     else if(rx_dcoff_count == COUNT_N - 1)
       adc_dc_off_0a_reg <= adc_dc_off_0a;
     else
       adc_dc_off_0a_reg <= adc_dc_off_0a_reg;
end
//---------------------------------------------------------------------------------
always@(posedge sys_clk or posedge sys_rst)
begin
     if(sys_rst)
       dcoff2adc_data_0a_reg <= 15'd0;
     else 
       dcoff2adc_data_0a_reg <= adc2dcoff_data_0a - adc_dc_off_0a_reg[28:13];
end
//////////////////////////////////////////////////////////////////////////////////
//// ADC DC OFF   0B
always@(posedge sys_clk or posedge sys_rst)
begin
     if(sys_rst)
       adc_dc_off_0b <= 29'd0;
     else if(rx_dcoff_count == COUNT_N)
       adc_dc_off_0b <= 29'd0;
     else
       adc_dc_off_0b <= adc_dc_off_0b + {{13{adc2dcoff_data_0b[15]}},adc2dcoff_data_0b[15:0]};
end   	
//---------------------------------------------------------------------------------
always@(posedge sys_clk or posedge sys_rst)
begin
     if(sys_rst)
       adc_dc_off_0b_reg <= 29'd0;
     else if(rx_dcoff_count == COUNT_N - 1)
       adc_dc_off_0b_reg <= adc_dc_off_0b;
     else
       adc_dc_off_0b_reg <= adc_dc_off_0b_reg;
end
//---------------------------------------------------------------------------------
always@(posedge sys_clk or posedge sys_rst)
begin
     if(sys_rst)
       dcoff2adc_data_0b_reg <= 15'd0; 
     else
       dcoff2adc_data_0b_reg <= adc2dcoff_data_0b - adc_dc_off_0b_reg[28:13];
end
//////////////////////////////////////////////////////////////////////////////////
//// ADC DC OFF   1A
always@(posedge sys_clk or posedge sys_rst)
begin
     if(sys_rst)
       adc_dc_off_1a <= 29'd0;
     else if(rx_dcoff_count == COUNT_N)
       adc_dc_off_1a <= 29'd0;
     else
       adc_dc_off_1a <= adc_dc_off_1a + {{13{adc2dcoff_data_1a[15]}},adc2dcoff_data_1a[15:0]};
end  	
//---------------------------------------------------------------------------------
always@(posedge sys_clk or posedge sys_rst)
begin
     if(sys_rst)
       adc_dc_off_1a_reg <= 29'd0;
     else if(rx_dcoff_count == COUNT_N - 1)
       adc_dc_off_1a_reg <= adc_dc_off_1a;
     else
       adc_dc_off_1a_reg <= adc_dc_off_1a_reg;
end
//---------------------------------------------------------------------------------
always@(posedge sys_clk or posedge sys_rst)
begin
     if(sys_rst)
       dcoff2adc_data_1a_reg <= 15'd0;
     else
       dcoff2adc_data_1a_reg <= adc2dcoff_data_1a - adc_dc_off_1a_reg[28:13];
end
//////////////////////////////////////////////////////////////////////////////////
//// ADC DC OFF   1b
always@(posedge sys_clk or posedge sys_rst)
begin
     if(sys_rst)
       adc_dc_off_1b <= 29'd0;
     else if(rx_dcoff_count == COUNT_N)
       adc_dc_off_1b <= 29'd0;
     else
       adc_dc_off_1b <= adc_dc_off_1b + {{13{adc2dcoff_data_1b[15]}},adc2dcoff_data_1b[15:0]};
end	
//---------------------------------------------------------------------------------
always@(posedge sys_clk or posedge sys_rst)
begin
     if(sys_rst)
       adc_dc_off_1b_reg <= 29'd0;
     else if(rx_dcoff_count == COUNT_N - 1)
       adc_dc_off_1b_reg <= adc_dc_off_1b;
     else
       adc_dc_off_1b_reg <= adc_dc_off_1b_reg;
end
//---------------------------------------------------------------------------------
always@(posedge sys_clk or posedge sys_rst)
begin
     if(sys_rst)
       dcoff2adc_data_1b_reg <= 15'd0;  
     else
       dcoff2adc_data_1b_reg <= adc2dcoff_data_1b - adc_dc_off_1b_reg[28:13];
end


//-------------------------------------------------------------------------------
 assign debug_signal[28:0]   =  adc_dc_off_0a_reg;
 assign debug_signal[57:29]  =  adc_dc_off_0b_reg;
 assign debug_signal[86:58]  =  adc_dc_off_1a_reg;
 assign debug_signal[115:87] =  adc_dc_off_1b_reg;
 assign debug_signal[131:116] =  dcoff2adc_data_0a_reg; 
 assign debug_signal[147:132] =  dcoff2adc_data_0b_reg;  
 assign debug_signal[163:148] =  dcoff2adc_data_1a_reg;  
 assign debug_signal[179:164] =  dcoff2adc_data_1b_reg;
 assign debug_signal[195:180] =  adc2dcoff_data_0a;                                                           
 assign debug_signal[199:196] =  6'd0;                                                             
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
endmodule























































