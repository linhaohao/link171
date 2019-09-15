//////////////////////////////////////////////////////////////////////////////////
// Company:         StarPoint
// Engineer:        GUO YAN 
// 
// Create Date:     10:20:15 08/24/2015 
// Module Name:     spi_interface 
// Project Name:    Link16 dsp interface module;
// Target Devices:  FPGA - XC7K325T - FFG900; 
// Tool versions:   ISE14.6; 
// Description:     
//                  
//
// Revision:        v1.0 - File Created
// Additional Comments: 
// 1.dsp6657 has only one spi interface. First, spi is used to dsp flash program load. Second, spi is to used to rtt response(header) for NTR. 
// 2.The First and second application switch by "ce" selection
// 3.spi for rtt response(header) is one way from dsp to fpga. The other data in rtt slot are still deliveried by mcbsp interface.
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps


module spi_interface(
//config parameter
input[6:0]           spi_reg_length,

////port////
input                spi_ssel,
input                spi_sck,
input                spi_mosi,
output               spi_miso,

//output
output[3:0]          spi_ram_addr_out,
output[31:0]         spi_ram_data_out,
output               spi_ram_wr_out,

//debug 
output[127:0]        debug_signal
);
//////////////////////////////////////////////////////////////////////////////////
//// signals declaration //// 
reg[6:0]       spi_count         = 7'd0;
reg[31:0]      spi_mosi_buff     = 32'd0;

reg            spi_rtt_en        = 1'b0;
reg[3:0]       spi_ram_addr      = 4'd0;
reg            spi_ram_wr        = 1'b0;
reg[31:0]      spi_ram_data      = 32'd0;
reg            spi_ram_wr_dly    = 1'b0;

//////////////////////////////////////////////////////////////////////////////////
//// parameters define ////


//////////////////////////////////////////////////////////////////////////////////
//// (0) signals assigment ////
assign   spi_ram_addr_out[3:0]   = spi_ram_addr[3:0]; 
assign   spi_ram_data_out[31:0]  = spi_ram_data[31:0];   //spi_mosi_buff[31:0];
assign   spi_ram_wr_out          = spi_ram_wr_dly;       //spi_ram_wr;

 // BUFR clk_bufg(
  // .I(spi_sck),
  // .O(spi_sck_buf)//20MHz
  // );

//////////////////////////////////////////////////////////////////////////////////
//// (1) spi logic ////
//// (1-0) spi counter ////
always @ (posedge spi_sck or posedge spi_ssel) 
begin
  if (spi_ssel)  begin 
     spi_count[6:0]               <= 7'd0;                 // spi register 32bits
  end
  else if (spi_count[6:0] == spi_reg_length[6:0])   begin  //spi_count cnt 0~31 samping ,NO.32 genenrate data
     spi_count[6:0]               <= 7'd0;	
  end
  else begin
     spi_count[6:0]               <= spi_count[6:0] + 1'b1; 
  end
end

always @ (posedge spi_sck or posedge spi_ssel) 
begin
   if (spi_ssel==1'b1)begin
       spi_mosi_buff[31:0]        <= 32'd0;
   end
   else begin                     
       spi_mosi_buff[31:1]        <= spi_mosi_buff[30:0]; //spi_count cnt 0~31 samping ,NO.32 genenrate data
       spi_mosi_buff[0]           <= spi_mosi;
   end
end

//// (1-1) spi rrt frame header detect////
always@(posedge spi_sck)
begin
  if(spi_ram_addr[3:0] == 4'd8) begin    
     spi_rtt_en                    <= 1'b0;
  end
  else if(spi_mosi_buff[31:0] == 32'h5555AAAA) begin
     spi_rtt_en                    <= 1'b1;
  end
end

//// (1-2) spi write ram logic ////
//always @ (posedge spi_sck or posedge spi_ssel) 
/*always @ (posedge spi_sck) 
begin
   // if (spi_ssel==1'b1)
       // spi_ram_addr[3:0]          <= 4'd0; //addr can't reset by ssel
   // else 
   if(spi_ram_addr[3:0] == 4'd8) begin //header 32pulse,one pulse=8bit(real 5bit),32bit = 4pulse no.1~no.8
       spi_ram_addr[3:0]          <= 4'd0; 
   end
   else if (spi_count[6:0] == spi_reg_length[6:0] - 1'b1) begin                     
       spi_ram_addr[3:0]          <= spi_ram_addr[3:0] + 1'b1;
   end
end*/

always @ (posedge spi_sck) 
begin
   if(spi_ram_addr[3:0] == 4'd8) begin //header 32pulse,one pulse=8bit(real 5bit),32bit = 4pulse no.1~no.8
       spi_ram_addr[3:0]          <= 4'd0; 
   end
   else if (spi_ram_wr) begin   //wr at beginning of frame=>NO.1-8                  
       spi_ram_addr[3:0]          <= spi_ram_addr[3:0] + 1'b1;
   end
end

always @ (posedge spi_sck or posedge spi_ssel) 
begin
   if (spi_ssel==1'b1)
       spi_ram_wr                 <= 1'b0;
   else if ((spi_count[6:0] == spi_reg_length[6:0]-1'b1) && spi_rtt_en) begin                   
       spi_ram_wr                 <= 1'b1;
   end
   else begin
       spi_ram_wr                 <= 1'b0;
   end
end

always @ (posedge spi_sck)  
begin                   
       spi_ram_wr_dly             <= spi_ram_wr; 
end


////(1-3) output logic ////
always @ (negedge spi_sck)  
begin
   if(spi_ram_wr)begin                      
       spi_ram_data[31:0]         <= spi_mosi_buff[31:0]; //keep data out unchanging
   end
end




//////////////////////////////////////////////////////////////////////////////////
//// (2) debug////

endmodule










