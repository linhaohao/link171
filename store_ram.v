`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:47:57 04/24/2017 
// Design Name: 
// Module Name:    store_ram 
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
module store_ram(
		input clk_50m,
		input cfg_rst,
		input clk_mcbsp,
		

		input  [15:0] data_200k_i_out,
		input  [15:0] data_200k_q_out,
		///////////////////////////////
		input part_syn_start,
		output part_syn_en,
		/////////////////////////////
		output read_quest,
		output [31:0] data_dsp,

		input init_rx_slot,
		input slot_start_count,
		
		input data_updated,
      input start_send,
		input [15:0]	 send_step,
 
		
		output [255:0] debug_decode,
		output [255:0] data_dsp_debug
	
    );


assign read_quest = read_quest_reg;
assign data_dsp =  dout;





reg 	[31:0] data_save;
wire  [31:0] dout;
reg 	[16:0] wr_addr;
reg 	[16:0] rd_addr_reg;
reg 	[13:0] count_200k;


reg clk_200k;
reg part_syn_en;
reg read_quest_reg;
reg init_addr_reg; 
reg init_addr_reg_dl;
wire init_addr; 
reg wr_croase_en;
reg flag;









/////////////////////////generate  clk_100k//////////////////
always@(posedge clk_50m or posedge cfg_rst) 
begin
		if(cfg_rst) begin
				count_200k <= 14'd0;
		end
		else if(count_200k == 14'd124) begin
				count_200k <= 14'd0;
		end
		else if(slot_start_count)begin
				count_200k <= count_200k + 14'd1;
		end
		else begin
				count_200k <= 14'd0;
		end
end

always@(posedge clk_50m or posedge cfg_rst)
begin
		if(cfg_rst) begin
				clk_200k <= 1'd0;
		end
		else if(count_200k == 14'd124) begin
				clk_200k <= !clk_200k;
		end
		else begin
				clk_200k <= clk_200k;
		end
end


//
////////////////////croase syn///////////////////////////

always@(posedge clk_50m or posedge cfg_rst)
begin
		if(cfg_rst) begin
				init_addr_reg <= 1'd1;
		end
		else if(init_rx_slot) begin
				init_addr_reg <= 1'b0;
		end
		else begin
				init_addr_reg <= init_addr_reg;
		end
end

always@(posedge clk_50m or posedge cfg_rst)      //mann  改了时钟 由200k ->50m
begin
		if(cfg_rst) begin
				init_addr_reg_dl <= 1'b1;
		end
		else begin
				init_addr_reg_dl <= init_addr_reg;
		end
end

always@(posedge clk_50m or posedge cfg_rst) begin
		if(cfg_rst) begin
				wr_croase_en <= 1'b0;
				flag         <= 1'b1;
		end
		else if(count_200k == 14'd100) begin
					flag  <= !flag;
				if(flag) begin
					wr_croase_en <= 1'b1;
			  end
		end
		else begin
				wr_croase_en <= 0;
				flag <= flag;
		end
end	

always@(posedge clk_50m or posedge cfg_rst) 
begin
		if(cfg_rst) begin
				wr_addr <= 17'd0;
		end
		else if(init_rx_slot)begin
				wr_addr <= 17'd0;
		end
		else if((wr_addr == 17'd51999) && wr_croase_en) begin
				wr_addr <= 17'd54000;
		end
		else if((wr_addr == 17'd105999) && wr_croase_en) begin
				wr_addr <= 17'd0;
		end
		else if(wr_croase_en)begin
				wr_addr <= wr_addr + 17'd1;
		end
		else begin
				wr_addr <= wr_addr;
		end
end

	
always@(posedge clk_50m or posedge cfg_rst)             //mann  改了时钟 由200k ->50m
begin
		if(cfg_rst) begin
				read_quest_reg <= 1'b0;
		end
		else if(init_addr_reg_dl)begin
				read_quest_reg <= 1'b0;
		end
		else if((wr_addr == 17'd51999) || (wr_addr == 17'd105999)) begin
				read_quest_reg <= 1'b1;
		end
		else begin
				read_quest_reg <= 1'b0;
		end
end						




	
///////////////////////store data///////////////////////////////////

always@(posedge clk_50m or posedge cfg_rst)        //用250k采64k的数
begin
		if(cfg_rst) begin
				data_save <= 32'd0;
		end
		else if(wr_croase_en)begin
				data_save <= {data_200k_q_out,data_200k_i_out};
		end
		else begin
			  data_save <= data_save;
		end
	
end

///////////////////////////////////////////////////////////////
//////////////////////时钟隔离////////////////////////////
reg [5:0] data_updated_dl;
reg [3:0] send_start_reg;
reg data_update_reg;
reg send_start;




always@(posedge clk_50m or posedge cfg_rst) 
begin
		if(cfg_rst) begin
				data_updated_dl <= 6'd0;
		end
		else begin
				data_updated_dl <= {data_updated_dl[4:0],data_updated};
		end
end
always@(posedge clk_50m or posedge cfg_rst) begin
		if(cfg_rst) begin
				data_update_reg <= 1'b0;
		end
		else if(data_updated_dl[4:3] == 2'b01) begin
				data_update_reg <= 1'b1;
		end
		else begin
				data_update_reg <= 1'b0;
		end
end
								
always@(posedge clk_50m or posedge cfg_rst) 
begin
		if(cfg_rst) begin
				send_start_reg <= 4'd0;
		end
		else begin
				send_start_reg <= {send_start_reg[2:0],start_send};
		end
end

always@(posedge clk_50m or posedge cfg_rst) begin
		if(cfg_rst) begin
				send_start <= 1'b0;
		end
		else if(send_start_reg[3:2] == 2'b01) begin
				send_start <= 1'b1;
		end
		else begin
				send_start <= 1'b0;
		end
end



					
				
always@(posedge clk_50m or posedge cfg_rst) 
begin
		if(cfg_rst) begin
				rd_addr_reg <= 17'd0;  //first read all 32'd0				
		end
		else if(send_start) begin
				if(wr_addr >= 17'd52000)begin
					rd_addr_reg <= send_step;				
				end
				else if(wr_addr <= 17'd52000) begin
					rd_addr_reg <= 17'd54000 + send_step;
				end
				else begin
					rd_addr_reg <= rd_addr_reg;
				end
				end		
		else if(data_update_reg && !part_syn_en )begin
				rd_addr_reg <= rd_addr_reg + 17'd8;
		end
		else if(data_update_reg && part_syn_en)begin
				rd_addr_reg <= rd_addr_reg + 17'd1;
		end
		else begin
				rd_addr_reg <= rd_addr_reg;
		end
end



always@(posedge clk_50m or posedge cfg_rst) begin
		if(cfg_rst) begin
				part_syn_en <= 1'b0;
		end
		else if(part_syn_start) begin
				part_syn_en <= 1'b1;
		end
		else if((rd_addr_reg == 17'd4799)||(rd_addr_reg == 17'd58799)) begin
				part_syn_en <= 1'b0;
		end
		else begin
				part_syn_en <= part_syn_en;
		end
end



ram_buffer receive_buffer (
  .clka(clk_50m), // input clka
  .wea(wr_croase_en), // input [0 : 0] wea
  .addra(wr_addr), // input [16 : 0] addra
  .dina(data_save), // input [31 : 0] dina
  .clkb(clk_50m), // input clkb
  .enb(1'b1), // input enb
  .addrb(rd_addr_reg), // input [16 : 0] addrb
  .doutb(dout) // output [31 : 0] doutb
);




assign data_dsp_debug[0]=clk_50m;
assign data_dsp_debug[1]=wr_croase_en;
assign data_dsp_debug[18:2]=wr_addr;
assign data_dsp_debug[35:19]= rd_addr_reg;
assign data_dsp_debug[67:36] = data_save;
assign data_dsp_debug[99:68] = dout;
assign data_dsp_debug[100] = part_syn_en;

assign data_dsp_debug[118] = part_syn_start;















endmodule
