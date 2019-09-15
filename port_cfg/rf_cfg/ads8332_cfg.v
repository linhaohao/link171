////////////////////////////////////////////////////////////////////////////////
// Company: StarPoint
// Engineer: guanzheye
//
// Create Date: 
// Design Name: 
// Module Name: 
// Target Device: FPGA XC7K325T-2FFG900 
// Tool versions: ISE 14.6
// Description:
//             
// Revision:   v1.0 - File Created
// Additional Comments:
//    ADS8332 电源监控
////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

module ads8332_cfg(

input                          sys_rest,      
input                          spi_clk,     

input                          ads_start,
                               
input[31:0]                    ads_in_data        ,
input                          ads_data_valid    ,
input                          ads_wr_en          ,
input [7:0]                    ads_cfg_rddr       ,
output [31:0]                  ads_rd_parameter   ,
output                         ads_out_valid      ,

input                          ads8332_spi_start,                                       
output  wire                   ads_spi_clk  ,
output  wire                   ads_spi_cs   ,
output  wire                   ads_spi_sdi  ,
input                          ads_spi_sdo  ,
                                       
output [63:0]                  ads_debug    

);

//////////////////////////////////////////////////////////////////////////////////
//// signal declaration ////

wire [6:0]          ads8332_count;
wire [31:0]         spi_data_out;
wire                spi_data_valid;





//////////////////////////////////////////////////////////////////////////////////
//// parameter ////
parameter START_NUMBER = 7'd1;
parameter CS_LENGTH    = 7'd32;


//////////////////////////////////////////////////////////////////////////////////
//// (0) signal assignment ////
     assign  ads_rd_parameter  = spi_data_out;
     assign  ads_out_valid     = spi_data_valid;







//////////////////////////////////////////////////////////////////////////////////
//// (1) ads8332 SPI ////
jft_spi   U0_ads8332_spi 
    (
	 .spi_clk_in        (~spi_clk),
	 .spi_rst_in        (sys_rest),
	 .spi_start          (ads_start),   //可以控制一下复位后加载时间
	 .spi_wr            (1'd1),        //只读？2015/9/14 10:34:57
	 .spi_end           (),

	 .spi_start_number  (START_NUMBER),
	 .spi_cs_length     (CS_LENGTH),
	 .spi_data_in       (ads8332_reg),
	 
   .spi_clk           (ads_spi_clk),	 
   .spi_cs            (ads_spi_cs ),	 
   .spi_sdi           (ads_spi_sdi),	 
   .spi_sdo           (ads_spi_sdo),	
   
   .spi_data_out      (spi_data_out),
   .spi_data_valid    (spi_data_valid),	 
   
	 .spi_count_starte   (ads8332_count[6:0]),
	 .debug_signal()	 	 
	 );



//////////////////////////////////////////////////////////////////////////////////
//// debug signal ////
assign  ads_debug[32:0]  = {spi_data_valid,spi_data_out};




//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
endmodule
