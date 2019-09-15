`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:04:50 09/05/2017 
// Design Name: 
// Module Name:    syn_control 
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
module syn_control(
		input clk_50m,
		input cfg_rst,
		input    			lose,
		input 				corase_syn_en,
		input					fine_syn_en,
		input  				slot_interrupt,
		input [31:0]  corase_syn_pos,
		input [31:0]  fine_syn_pos,
		
		output [31:0] corase_pos,
		output [31:0] fine_pos,
		output reg send40k_en,
		output reg send10k_en,
		input data_send_end,
		input [15:0] wr_addr_out,
		
		output [255:0] debug

    );


assign corase_pos = corase_pos_reg;
assign fine_pos   = fine_pos_reg;
reg [3:0] syn_state;
reg [31:0] fine_pos_reg;
reg [31:0] corase_pos_reg;
always@(posedge clk_50m or posedge cfg_rst) begin
		if(cfg_rst) begin
				syn_state 					<= 4'd0;
				fine_pos_reg 				<= 32'd0;
				corase_pos_reg      <= 32'd0;
				send40k_en          <= 1'b0;
				send10k_en					<= 1'b0;
		end
		else begin
				case(syn_state) 
				4'd0: begin					
		      if(lose)begin
		      		send40k_en <= 1'b0;
		      		send10k_en <= 1'b0;
		      end
		      else if(corase_syn_en) begin
							syn_state  <= 4'd1;							
		      end					
				  else if(fine_syn_en)   begin
				  		syn_state  <= 4'd2;
							send40k_en <= 1'b0;
							send10k_en <= 1'b1;
				  end 
					else if(data_send_end) begin
							syn_state  <= 4'd0;
							send10k_en <= 1'b0;
							send40k_en <= 1'b1;
					end
					else begin
							send10k_en <= send10k_en;
							send40k_en <= send40k_en;
							syn_state  <= 4'd0;
					end
				end
				4'd1: begin
					if(slot_interrupt)	begin			
					 		corase_pos_reg <= corase_syn_pos;							
							send40k_en <= 1'b1;											
							syn_state  <= 4'd0;
					end
					else begin
							syn_state <= 1'b1;
					end
				end
				4'd2: begin	
						syn_state    <= 4'd0;				
					  if(fine_syn_pos == 32'd0) begin
							fine_pos_reg <= 32'd0;
						end
						else begin
							fine_pos_reg <= fine_syn_pos;
						end		 
				end
				default:begin
						syn_state <= 4'd0;
				end
			endcase
		end	
end 


assign debug[0]=corase_syn_en;
assign debug[1]=fine_syn_en;
assign debug[33:2]=corase_syn_pos;
assign debug[65:34]=fine_syn_pos;
assign debug[97:66]=corase_pos;
assign debug[129:98]=fine_pos;
assign debug[130]=send40k_en;
assign debug[131]=send10k_en;
assign debug[135:132]=syn_state;
assign debug[136]=lose;
assign debug[137]=data_send_end;
assign debug[255:138]=0;

endmodule
