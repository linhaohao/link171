`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    09:54:01 05/25/2017 
// Design Name: 
// Module Name:    slot_timer 
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
//1. creater 60ms slot_plus to dsp
//////////////////////////////////////////////////////////////////////////////////
module slot_timer(
		input clk_5mhz,
		input clk_50mhz,
		input cfg_rst,
		input slot_start_count,//接收到dac返回的SPI结束信号，就将slot_start_count置1，且之后一直是1
		
		//////////////////////////////
		input adjust_pos_en,//从dsp发送过来的调整时隙位置的使能信号
		input [31:0] adjust_pos,
		////////////////////////////
		
		output reg rx_dds_en,//dds使能信号
		output init_rx_slot,//接收的PING-PONG buffer的初始化中断信号
		output reg cancel_interrupt,//时隙进行调整时为1，置1时没有60ms时隙中断
		output slot_interrupt_out,//60ms时隙中断，脉宽20ns
		output reg slot_rx_interrupt,  //init dsp rx interrupt
		output  slot_dsp_interrupt,//60ms时隙中断，脉宽2us
		output [255:0] debug
    );


reg [19:0] count_40us;
reg [14:0] count_interrupt;
reg [7:0] delay_count;
reg [7:0] delay_rx_count;
reg init_rx_slot_reg;
reg init_rx_slot_reg_dl;

//reg slot_interrupt;
reg slot_dsp_interrupt_reg;
reg slot_interrupt;
reg adjust_rx_en;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//// parameter define ////
//parameter           SLOT_LENGTH         = 15'd6499;
parameter           SLOT_LENGTH         = 15'd1624;

/////////////////////////////////////////////////////////////////////////////////////////////////////

assign slot_interrupt_out = adjust_pos_endl ? 1'b0 : slot_interrupt;
assign slot_dsp_interrupt = cancel_interrupt ? 1'b0 : slot_dsp_interrupt_reg;
assign init_rx_slot = !init_rx_slot_reg_dl&init_rx_slot_reg;

/////////////////////////入网及同步时隙调整////////////////////////////
reg [14:0] adjust_pos_reg;
reg adjust_pos_endl; 
reg [14:0] slot_length;
reg adjust_once;
always@(posedge clk_50mhz or posedge cfg_rst) begin
		if(cfg_rst) begin
				adjust_pos_endl <= 1'b0;
				adjust_pos_reg  <= 15'd0;
		end
		else if(adjust_pos_endl && slot_interrupt) begin
				adjust_pos_endl <=  1'b0;
				adjust_pos_reg  <= 15'd0;
		end		
		else if(adjust_pos_en)begin
				adjust_pos_endl <= 1'b1;
				adjust_pos_reg  <= adjust_pos[14:0];
		end
		else begin
				adjust_pos_endl <= adjust_pos_endl;
				adjust_pos_reg  <= adjust_pos_reg;
		end
end


always@(posedge clk_50mhz or posedge cfg_rst) begin
		if(cfg_rst) begin
				slot_length  <= SLOT_LENGTH;
				adjust_rx_en <= 1'b0;
				adjust_once  <= 1'b0;
		end
		else if(adjust_pos_endl && slot_interrupt) begin
				slot_length <=  adjust_pos_reg;
				adjust_rx_en <= 1'b0;				
				adjust_once  <= 1'b1;
		end
		else if(slot_interrupt && adjust_once)begin
				slot_length  <= SLOT_LENGTH; 
				adjust_rx_en <= 1'b1;//调整时隙结束，接收使能
				adjust_once  <= 1'b0;
		end
		else begin
				slot_length  <= slot_length;
				adjust_rx_en <= 1'b0;
				adjust_once  <= adjust_once;
		end
end


/////////////////更改为40us  40us*1625=65ms/////////////////////////////
always@(posedge clk_50mhz or posedge cfg_rst)begin
	if(cfg_rst) begin
			count_40us <= 20'd0;
	end
	else if(count_40us == 20'd1999)begin
			count_40us <= 20'd0;
	end
	else if(slot_start_count)begin
			count_40us <= count_40us + 20'd1;
	end
	else begin
			count_40us <= count_40us;
	end
end

always@(posedge clk_50mhz or posedge cfg_rst) begin
	if(cfg_rst) begin
			count_interrupt <= 15'd0;
	end
	else if((count_interrupt == SLOT_LENGTH) && (count_40us == 20'd1999))begin
			count_interrupt <= 15'd0;
	end
	else if(count_40us == 20'd1999) begin
			count_interrupt <= count_interrupt + 15'd1;
	end
	else begin
			count_interrupt <= count_interrupt;
	end
end

always@(posedge clk_50mhz or posedge cfg_rst) begin
	if(cfg_rst) begin
			slot_interrupt <= 1'b0;
	end
	else if((count_interrupt == SLOT_LENGTH) && (count_40us == 20'd1999))begin
			slot_interrupt <= 1'b1;
	end
	else begin
			slot_interrupt <= 1'b0;
	end
end

///////////////////////产生接收buffer地址初始化中断/////////////////////////////////
always@(posedge clk_50mhz or posedge cfg_rst) begin
	if(cfg_rst) begin
			init_rx_slot_reg <= 1'b0;
	end
	else if(adjust_rx_en) begin
			init_rx_slot_reg <= 1'b0;
	end
	else if((count_interrupt == 15'd37) && (count_40us == 20'd999))begin
			init_rx_slot_reg <= 1'b1;
	end
	else begin
			init_rx_slot_reg <= init_rx_slot_reg;
	end
end

always@(posedge clk_50mhz or posedge cfg_rst) begin
	if(cfg_rst) begin
			init_rx_slot_reg_dl <= 1'b0;
	end
	else begin
			init_rx_slot_reg_dl <= init_rx_slot_reg;
	end
end
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////generate rx dds we//////////////////////////////
always@(posedge clk_50mhz or posedge cfg_rst) begin
	if(cfg_rst) begin
			rx_dds_en <= 1'b0;
	end
	else if((count_interrupt == 15'd25) && (count_40us == 20'd999))begin//第一次置1之后永远是1
			rx_dds_en <= 1'b1;
	end
	else begin
			rx_dds_en <= rx_dds_en;
	end
end


//// (6) slot intterrupt to dsp(last 2us high level) ///////////////////////////
always@(posedge clk_50mhz or posedge cfg_rst) begin
   if (cfg_rst)   begin
	   slot_dsp_interrupt_reg                 <= 1'b0;
   end
   else if (delay_count  == 8'd100)  begin   
	   slot_dsp_interrupt_reg                 <= 1'b0;
   end
   else if(slot_interrupt)begin
	   slot_dsp_interrupt_reg                 <= 1'b1;
    end
end

always@(posedge clk_50mhz or posedge cfg_rst)begin
   if (cfg_rst)   begin
	   delay_count                   <= 8'd0;
   end  
   else if (delay_count  == 8'd100)  begin  
	   delay_count                   <= 8'd0;
   end
   else if(slot_dsp_interrupt_reg)begin
	   delay_count                   <= delay_count  + 8'b1;
   end
end


//////////////////////generate first rx_interrupt/////////////////////////////////////
always@(posedge clk_50mhz or posedge cfg_rst) begin
   if (cfg_rst)   begin
	   slot_rx_interrupt                 <= 1'b0;
   end
   else if (delay_rx_count  == 8'd100)  begin   
	   slot_rx_interrupt                 <= 1'b0;
   end
   else if(init_rx_slot)begin//产生地址初始化中断的脉冲之后，产生第一次接收中断给DSP
	   slot_rx_interrupt                 <= 1'b1;
   end
   else begin
   	 slot_rx_interrupt                 <= 1'b0;	 
   end
end

always@(posedge clk_50mhz or posedge cfg_rst)begin
   if (cfg_rst)   begin
	   delay_rx_count                   <= 8'd0;
   end  
   else if (delay_rx_count  == 8'd100)  begin  
	   delay_rx_count                   <= 8'd0;
   end
   else if(slot_rx_interrupt)begin
	   delay_rx_count                   <= delay_rx_count  + 8'b1;
   end
   else begin
   	 delay_rx_count                 <= 8'd0;	 
   end
end

////////////////////////no interrupt time////////////////////////////////////
//当进行时隙调整的时候，不会向DSP发送时隙中断信号

always@(posedge clk_50mhz or posedge cfg_rst) begin
		if(cfg_rst) begin
				cancel_interrupt <= 1'b0;
		end
		else if(adjust_pos_en)begin
			  cancel_interrupt   <= 1'b1;
		end 
		else if(adjust_rx_en) begin
				cancel_interrupt   <= 1'b0;
		end
		else begin
				cancel_interrupt   <= cancel_interrupt;
		end
end



assign debug[0] 			= clk_5mhz ;
assign debug[1] 			= slot_interrupt;
assign debug[2] 			= slot_dsp_interrupt_reg;
assign debug[3] 			= init_rx_slot;
assign debug[4] 			= init_rx_slot_reg;
assign debug[19:5] 		= count_interrupt;
assign debug[39:20] 	= count_40us;	
assign debug[54:40] 	= adjust_pos_reg;
assign debug[55]    	= adjust_pos_endl;
assign debug[70:56] 	= slot_length;
assign debug[71]    	= cancel_interrupt;	
assign debug[72]    	= adjust_rx_en;	
assign debug[73]    	= adjust_pos_en;
assign debug[105:74]  = adjust_pos;
assign debug[106] 		= adjust_once;
assign debug[255:107] = 0;


endmodule
