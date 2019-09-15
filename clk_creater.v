`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:00:01 05/25/2019 
// Design Name: 
// Module Name:    clk_creater 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module clk_creater(
input clk_200m,
input clk_50m,

input cfg_rst,
input slot_start_count,//接收到dac返回的SPI结束信号，就将slot_start_count置1，且之后一直是1

output clk_64khz,
output clk_64_3khz,//21.33khz ~= 64khz/3
output clk_64_96khz//666.67hz ~= 64khz/96
    );
	 

reg clk_64khz_reg;
reg clk_64_3khz_reg;
reg clk_64_96khz_reg;
reg [14:0]count_64khz;
reg [14:0]count_64_3khz;
reg [19:0]count_64_96khz;
//////////////////////////////////////////////////////////////////////////////////

assign clk_64khz    = clk_64khz_reg;
assign clk_64_3khz  = clk_64_3khz_reg;
assign clk_64_96khz = clk_64_96khz_reg;

//////////////////////////////////////////////////////////////////////////////////


///////////////64kHz clk generate//////////////////
always@(posedge clk_200m or posedge cfg_rst)
begin
	  if(cfg_rst) begin
	  	count_64khz <= 15'd0;
	  end
	  else if(count_64khz == 15'd3124)begin//200mhz的3125分频得到64khz
	  	count_64khz <= 15'd0;
	  end
	  else if(slot_start_count)begin
	  	count_64khz <= count_64khz + 15'd1;
	  end
	  else begin
	  	count_64khz <= 15'd0;
	  end
end

always@(posedge clk_200m or posedge cfg_rst)
begin
	  if(cfg_rst) begin
	  	clk_64khz_reg <= 1'b0;
	  end
	  else if(count_64khz == 15'd1561)begin
	  	clk_64khz_reg <= !clk_64khz_reg;
	  end
	  else if(count_64khz == 15'd3124)begin
	   clk_64khz_reg <= !clk_64khz_reg;
	  end
	  else begin
	  	clk_64khz_reg <= clk_64khz_reg;
	  end
end
///////////////21.33kHz clk generate//////////////////
always@(posedge clk_200m or posedge cfg_rst)
begin
	  if(cfg_rst) begin
	  	count_64_3khz <= 15'd0;
	  end
	  else if(count_64_3khz == 15'd9374)begin//200mhz的3125*3=9375分频得到21.33khz
	  	count_64_3khz <= 15'd0;
	  end
	  else if(slot_start_count)begin
	  	count_64_3khz <= count_64_3khz + 15'd1;
	  end
	  else begin
	  	count_64_3khz <= 15'd0;
	  end
end

always@(posedge clk_200m or posedge cfg_rst)
begin
	  if(cfg_rst) begin
	  	clk_64_3khz_reg <= 1'b0;
	  end
	  else if(count_64_3khz == 15'd4686)begin
	  	clk_64_3khz_reg <= !clk_64_3khz_reg;
	  end
	  else if(count_64_3khz == 15'd9374)begin
	   clk_64_3khz_reg <= !clk_64_3khz_reg;
	  end
	  else begin
	  	clk_64_3khz_reg <= clk_64_3khz_reg;
	  end
end
///////////////666.67Hz clk generate//////////////////
always@(posedge clk_200m or posedge cfg_rst)
begin
	  if(cfg_rst) begin
	  	count_64_96khz <= 20'd0;
	  end
	  else if(count_64_96khz == 20'd299999)begin//200mhz的3125*96=300000分频得到666.67hz
	  	count_64_96khz <= 20'd0;
	  end
	  else if(slot_start_count)begin
	  	count_64_96khz <= count_64_96khz + 20'd1;
	  end
	  else begin
	  	count_64_96khz <= 20'd0;
	  end
end

always@(posedge clk_200m or posedge cfg_rst)
begin
	  if(cfg_rst) begin
	  	clk_64_96khz_reg <= 1'b0;
	  end
	  else if(count_64_96khz == 20'd149999)begin
	  	clk_64_96khz_reg <= !clk_64_96khz_reg;
	  end
	  else if(count_64_96khz == 20'd299999)begin
	   clk_64_96khz_reg <= !clk_64_96khz_reg;
	  end
	  else begin
	  	clk_64_96khz_reg <= clk_64_96khz_reg;
	  end
end

endmodule
