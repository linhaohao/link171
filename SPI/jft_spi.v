////////////////////////////////////////////////////////////////////////////////
// Company: <Company Name>
// Engineer: <Engineer Name>
//
// Create Date: <date>
// Design Name: <name_of_top-csvel_design>
// Moducs Name: <name_of_this_moducs>
// Target Device: <target device>
// Tool versions: <tool_versions>
// Description:
//    jft 项目通用 SPI接口，主控。
// Dependencies:
//    <Dependencies here>
// Revision:
//    <Code_revision_information>
// Additional Comments:
//    需要根据不同的器件，对数据位宽进行预处理再进入本模块。
//    回读数据也需要根据不同类型进行裁剪。
////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps


module jft_spi(
// clk/rst
input               spi_clk_in, 
input               spi_rst_in,
//moducs config
input               spi_start,
input               spi_wr,             //  '0' -〉w， '1' -〉 r
//input               microwire_mode,     //lmk 模式；

output              spi_end,      
output  reg         spi_all_end,    
// DAC SPI interface 	 
output              spi_clk,
output  reg         spi_cs,	 
output              spi_sdi,	 
input               spi_sdo,	
//----in
input [6:0]         spi_start_number, 
input [6:0]         spi_cs_length,
input [39:0]        spi_data_in,  
//----out
output [31:0]       spi_data_out,   
output              spi_data_valid,
//-------------------
output reg [6:0]        spi_count_starte,	
// starte/debug 
output [63:0]       debug_signal	

);
 
//////////////////////////////////////////////////////////////////////////////////
//// signal declaration ////
reg [13:0]          spi_count = 14'd0;
reg [39:0]          spi_reg ;

reg                 spi_data = 1'd0;
reg                 spi_cs_n = 1'd0;
reg                 spi_cs_n1 ;
reg                 spi_cs_reg ;
reg                 spi_repeat;
reg [31:0]          spi_data_out_reg;
reg [31:0]          spi_data_sdo;
reg                 spi_end_pulse;
reg                 spi_data_valid_reg;
reg [6:0]           spi_end_pulse_cnt;
//reg                 spi_red_lmk_cs;
//reg [6:0]           spi_red_lmk_cs_cnt;
//reg                 spi_cs_reg_dl;
//reg [26:0]          spi_rd_data_sdo;
//reg [31:0]          microwire_rd_data;
//reg                 microwire_data_valid;




//////////////////////////////////////////////////////////////////////////////////
//// parameter ////



//////////////////////////////////////////////////////////////////////////////////
//// signal assignment ////
       assign  spi_clk     = spi_clk_in;

       assign  spi_sdi     = spi_data;
       
       assign  spi_end     = spi_end_pulse;
       
      // assign  spi_count_starte = spi_count[13:7];
     //  assign  spi_data_out    = microwire_mode ? microwire_rd_data     : spi_data_out_reg ;
     //  assign  spi_data_valid  = microwire_mode ? microwire_data_valid  : spi_data_valid_reg;      
      assign  spi_data_out    = spi_data_out_reg ;  
      assign  spi_data_valid  = spi_data_valid_reg; 
     
       
       
///////////////////////////////////////////////////////////////////////////////////
//// (*)  ////      
always@(negedge spi_clk_in or posedge spi_rst_in)
begin    
	   if(spi_rst_in)
	      spi_all_end <= 1'd0;
    else if (spi_count[6:0] == spi_cs_length[6:0] - 1'd1 && spi_count[13:7] == spi_start_number[6:0] - 1'd1)   begin 
          if (spi_end_pulse)
          	  spi_all_end <= 1'd1;
          else 
              spi_all_end <= 1'd0;
     end
    else
      spi_all_end <= 1'd0;
end
       

//////////////////////////////////////////////////////////////////////////////////
//// (1) SPI count logic ////
always@(negedge spi_clk_in or posedge spi_rst_in)
begin
	if (spi_rst_in)   begin
    spi_count[13:0]   <= 14'd0;
  end
  else if(spi_start)begin
    spi_count[13:0]   <= 14'd0;
  end
  else if (spi_count[6:0] == spi_cs_length[6:0] - 1'd1 )   begin 
    if (spi_count[13:7] == spi_start_number[6:0] - 1'd1 )   begin
       spi_count[13:0] <= spi_count[13:0];
    end
    else   begin
      spi_count[13:7] <= spi_count[13:7] + 1'b1;  
      spi_count[6:0]  <= 7'd0;	
    end
  end	 
  else if(spi_cs_n)  begin
    spi_count[6:0]   <= spi_count[6:0] + 1'b1; 
  end  	     
end
//////////////////////////////////////////////////////////////////////////////////
//// (1) SPI count logic ////
always@(negedge spi_clk_in or posedge spi_rst_in)
begin
	if (spi_rst_in)
    spi_repeat <= 1'd0;
  else if ((spi_count[6:0] == spi_cs_length[6:0] - 1'd1) && (spi_count[13:7] == spi_start_number[6:0] - 1'd1))
       spi_repeat <= 1'd0;
  else if(spi_end_pulse)
       spi_repeat <= 1'd1;  
  else 
    spi_repeat <= 1'd0; 	     
  end
//////////////////////////////////////////////////////////////////////////////////
//// (2) SPI CS               CFG ////
always@(negedge spi_clk_in or posedge spi_rst_in)
begin
  if (spi_rst_in)
    spi_cs_n  <= 1'b0;
  else   if (spi_start||spi_repeat)
    spi_cs_n  <= 1'b1;	
  else if(spi_count[6:0] == spi_cs_length[6:0] - 1'd1 )
    spi_cs_n  <= 1'b0;
  else
    spi_cs_n  <= spi_cs_n;         
end
//////////////////////////////////////////////////////////////////////////////////
//// (2-1) SPI CS ////
always@(negedge spi_clk_in or posedge spi_rst_in)
begin
  if (spi_rst_in)begin
  	spi_cs_n1   <= 1'd0;
    spi_cs_reg  <= 1'b1;
  end
  else begin
  	spi_cs_n1   <=  spi_cs_n;
    spi_cs_reg  <= ~spi_cs_n1;        
  end
end


//////////////////////////////////////////////////////////////////////////////////
//// (3) SPI w 并串////
always@(negedge spi_clk_in or posedge spi_rst_in)
begin
  if (spi_rst_in)
    spi_data  <= 1'b0;
  else 
    spi_data  <= spi_reg[39];
end	
//////////////////////////////////////////////////////////////////////////////////
//// (3-1) SPI w ////
always@(negedge spi_clk_in or posedge spi_rst_in)
begin
  if (spi_rst_in)   begin
    spi_reg[39:0]  <= 40'd0;  	
  end
  else if (spi_count[6:0] == 7'd0)begin  
    spi_reg[39:0]  <= spi_data_in[39:0];
  end
  else   begin
    spi_reg[39:1]  <= spi_reg[38:0];
  end
end	
//////////////////////////////////////////////////////////////////////////////////
//// (4) SPI red  串-并  数据前半段为地址位，后半段为数据位 ////
always@(negedge spi_clk_in or posedge spi_rst_in)
begin
  if (spi_rst_in)
    spi_data_sdo[31:0] <= 32'd0;  	
  else if(spi_start||spi_repeat)
    spi_data_sdo      <= 32'd0;  
 // else if(spi_wr && !spi_cs_reg && spi_count[6:0] > 7'd17)
  else if(spi_wr && !spi_cs_reg)
    spi_data_sdo      <={spi_data_sdo[30:0],spi_sdo};
  else
    spi_data_sdo      <= spi_data_sdo;
end

////////////////////////////////////////////////////////////////////////////////////
////// (*) SPI red  串-并 microwire模式   microwire_mode////
//always@(negedge spi_clk_in or posedge spi_rst_in)
//begin
//  if (spi_rst_in)
//    spi_rd_data_sdo[26:0] <= 27'd0;  	
////  else if(spi_start || !microwire_mode)
////    spi_rd_data_sdo      <= 27'd0;  
//  else if(spi_wr && !spi_red_lmk_cs)
//    spi_rd_data_sdo      <={spi_rd_data_sdo[25:0],spi_sdo};
//  else
//    spi_rd_data_sdo      <= spi_rd_data_sdo;
//end
////////////////////////////////////////////////////////////////////////////////////
////// (*) spi_red_lmk_cs////
//always@(negedge spi_clk_in or posedge spi_rst_in)
//begin
//  if(spi_rst_in)
//     spi_cs_reg_dl <= 1'd1;
//  else if(microwire_mode && spi_wr)
//     spi_cs_reg_dl <= spi_cs_reg;
//  else
//     spi_cs_reg_dl <= 1'd1;
//end
////////////////////////////////////////////////////////////////////////////////////
////// (*)                                           ////
//always@(negedge spi_clk_in or posedge spi_rst_in)
//begin
//  if(spi_rst_in)
//     spi_red_lmk_cs <= 1'd1;
//  else if(spi_red_lmk_cs_cnt == 6'd26)
//     spi_red_lmk_cs <= 1'd1;
//  else if(!spi_cs_reg_dl && spi_cs_reg)
//     spi_red_lmk_cs <= 1'd0;
//  else
//     spi_red_lmk_cs <= spi_red_lmk_cs;
//end
//////////////////////////////////////////////////////////////////////////////////
//// (*)                                           ////
//always@(negedge spi_clk_in or posedge spi_rst_in)
//begin
//  if(spi_rst_in)
//     spi_red_lmk_cs_cnt <= 6'd0;
//  else if(!spi_red_lmk_cs)
//     spi_red_lmk_cs_cnt <= spi_red_lmk_cs_cnt + 1'd1;
//  else
//     spi_red_lmk_cs_cnt <= 6'd0;
//end 
////////////////////////////////////////////////////////////////////////////////////
////// (*)                                           ////
//always@(negedge spi_clk_in or posedge spi_rst_in)
//begin
//  if(spi_rst_in)
//     microwire_rd_data  <= 32'd0;
//  else if(spi_red_lmk_cs_cnt == 6'd27)
//     microwire_rd_data <= {spi_data_in[31:27],spi_rd_data_sdo};
//  else
//     microwire_rd_data <= microwire_rd_data;
//end 
////////////////////////////////////////////////////////////////////////////////////
////// (*)                                           ////
//always@(negedge spi_clk_in or posedge spi_rst_in)
//begin
//  if(spi_rst_in)
//     microwire_data_valid  <= 1'd0;
//  else if(spi_red_lmk_cs_cnt == 6'd27)
//     microwire_data_valid  <= 1'd1;
//  else
//     microwire_data_valid  <= 1'd0;
//end 
//////////////////////////////////////////////////////////////////////////////////
//// (6) SPI red    同时返回读地址 ////
always@(negedge spi_clk_in or posedge spi_rst_in)
begin
  if (spi_rst_in)   begin
    spi_data_out_reg <= 32'd0;  	
  end
  else if(spi_end_pulse)   begin
    spi_data_out_reg <= spi_data_sdo;
  end
end
//////////////////////////////////////////////////////////////////////////////////
//// (7) 结束脉冲 ////
always@(negedge spi_clk_in or posedge spi_rst_in)
begin
  if (spi_rst_in)   begin
    spi_end_pulse <= 1'd0;
  end
  else if(!spi_cs_n1 && !spi_cs_reg)
  	spi_end_pulse <= 1'd1; 
  else
    spi_end_pulse <= 1'd0; 
end
//////////////////////////////////////////////////////////////////////////////////
//// (8) DATA valid////
always@(negedge spi_clk_in or posedge spi_rst_in)
begin
  if (spi_rst_in)
    spi_data_valid_reg <= 1'd0;  	
  else if(spi_wr) 
  	spi_data_valid_reg <= spi_end_pulse; 
  else
    spi_data_valid_reg <= 1'd0; 
end

//////////////////////////////////////////////////////////////////////////////////
//// (8)spi_end_pulse_cnt////
always@(negedge spi_clk_in or posedge spi_rst_in)
begin
  if (spi_rst_in)
     spi_end_pulse_cnt <= 7'd0;
  else if(spi_start)
     spi_end_pulse_cnt <= 7'd0;
  else if(spi_end_pulse_cnt == spi_start_number[6:0])
     spi_end_pulse_cnt <= spi_end_pulse_cnt;
  else if(spi_end_pulse)
     spi_end_pulse_cnt <= spi_end_pulse_cnt + 7'd1;
  else
     spi_end_pulse_cnt <= spi_end_pulse_cnt;
end
//////////////////////////////////////////////////////////////////////////////////
//// (9) ////
always@(*)
begin
     if (spi_end_pulse_cnt == spi_start_number[6:0])
       spi_count_starte = 6'd0;
     else 
       spi_count_starte = spi_count[13:7];
end   
//////////////////////////////////////////////////////////////////////////////////
//// (9) ////
always@(*)
begin
     if (!spi_cs_reg)
       spi_cs = spi_cs_reg;
//     else if(!spi_red_lmk_cs) 
//       spi_cs = spi_red_lmk_cs;
     else
       spi_cs = 1'd1;
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












