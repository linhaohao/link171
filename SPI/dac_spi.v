////////////////////////////////////////////////////////////////////////////////
// Company: StarPoint
// Engineer: guanzheye
//
// Create Date: 2015/9/25
// Design Name: <name_of_top-csvel_design>
// Moducs Name: <name_of_this_moducs>
// Target Device: <target device>
// Tool versions: <tool_versions>
// Description:
//  
// Dependencies:
//    <Dependencies here>
// Revision:
//    <Code_revision_information>
// Additional Comments:
//    
//   
////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps


module dac_spi(
// clk/rst
input               clk_20mhz_in, 
input               spi_rst_in,
//moducs config
input               spi_start,
input [71:0]        spi_data_in,

output reg          spi_end,        
// DAC SPI interface 	 
output              spi_clk,
output              spi_cs,	 
output              spi_sdi,	 
input               spi_sdo,	
// starte/debug 
output [63:0]       debug_signal	

);
 
//////////////////////////////////////////////////////////////////////////////////
//// signal declaration ////
reg [6:0]           spi_cs_cnt = 14'd0;
reg [71:0]          spi_reg ;

reg                 spi_data = 1'd0;
reg                 spi_cs_n = 1'd0;
reg                 spi_cs_n1 ;
reg                 spi_cs_reg ;
reg                 spi_end_pulse;




//////////////////////////////////////////////////////////////////////////////////
//// parameter ////



//////////////////////////////////////////////////////////////////////////////////
//// signal assignment ////
       assign  spi_clk     = clk_20mhz_in;

       assign  spi_sdi     = spi_data;
       
       assign  spi_cs      = spi_cs_reg;
       
     //  assign  spi_end     = spi_end_pulse;            
//////////////////////////////////////////////////////////////////////////////////
//// (1) SPI cs ////
always@(negedge clk_20mhz_in or posedge spi_rst_in)
begin
	if (spi_rst_in)
		 spi_cs_n <= 1'd0;
  else if(spi_start)
     spi_cs_n <= 1'd1;
  else if(spi_cs_cnt == 7'd71)
     spi_cs_n <= 1'd0;
end
//////////////////////////////////////////////////////////////////////////////////
//// () SPI CS ////
always@(negedge clk_20mhz_in or posedge spi_rst_in)
begin
  if (spi_rst_in)begin
  	spi_cs_n1   <= 1'd0;
    spi_cs_reg  <= 1'b1;
  end
  else begin
  	spi_cs_n1   <=  ~spi_cs_n;
    spi_cs_reg  <= spi_cs_n1;        
  end
end
//////////////////////////////////////////////////////////////////////////////////
//// () SPI cs cnt ////
always@(negedge clk_20mhz_in or posedge spi_rst_in)
begin
	if (spi_rst_in)
		 spi_cs_cnt <= 7'd0;
  else if(spi_cs_n)
     spi_cs_cnt <= spi_cs_cnt + 1'd1;
  else 
     spi_cs_cnt <= 7'd0;
end     
//////////////////////////////////////////////////////////////////////////////////
//// () SPI data ////
always@(negedge clk_20mhz_in or posedge spi_rst_in)
begin
	if (spi_rst_in)
		 spi_reg <= 72'd0;
  else if(spi_cs_cnt == 7'd0)
     spi_reg <= spi_data_in;
  else 
     spi_reg[71:1] <= spi_reg[70:0];
end     
//////////////////////////////////////////////////////////////////////////////////
//// () SPI w ²¢´®////
always@(negedge clk_20mhz_in or posedge spi_rst_in)
begin
  if (spi_rst_in)
    spi_data  <= 1'b0;
  else 
    spi_data  <= spi_reg[71];
end	

//////////////////////////////////////////////////////////////////////////////////
//// (7) ½áÊøÂö³å ////
always@(negedge clk_20mhz_in or posedge spi_rst_in)
begin
  if (spi_rst_in)   begin
    spi_end_pulse <= 1'd0;
  end
  else if(spi_cs_cnt == 7'd72)
  	spi_end_pulse <= 1'd1; 
  else
    spi_end_pulse <= 1'd0; 
end
//////////////////////////////////////////////////////////////////////////////////
//// (7) ½áÊøÂö³å ////
always@(negedge clk_20mhz_in or posedge spi_rst_in)
begin
  if (spi_rst_in)
    spi_end <= 1'd0;
  else
  	spi_end <= spi_end_pulse;
end
























//////////////////////////////////////////////////////////////////////////////////
//// debug signal ////
//assign  debug_signal[13:0]              = spi_count[13:0];
//assign  debug_signal[14]                = spi_data;
//assign  debug_signal[15]                = spi_le_n;
//assign  debug_signal[47:16]             = spi_reg[31:0];
//assign  debug_signal[48]                = lmk_spi_clk;
////assign  debug_signal[49]                = spi_le_n2;
//assign  debug_signal[50]                = lmk_spi_cs;




//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
endmodule












