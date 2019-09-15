`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:44:52 11/17/2017 
// Design Name: 
// Module Name:    duc_iq 
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
module duc_iq(
		input clk_200m,
		input cfg_rst,
		
		input [31:0]  loop_data,
		input [27:0]  fcw_data,
		input 		    tx_dds_en,
		output [15:0] data_out_i,
		output [15:0] data_out_q,
		
		output [127:0] debug

    );
    
    
assign data_out_i = dds_mult_i_reg[31:16];
assign data_out_q = dds_mult_q_reg[31:16];


reg [27:0] fcw_data_reg;
wire signed [15:0] dds_sin;
wire signed [15:0] dds_cos;

wire signed [31:0] dds_mult_i;
wire signed [31:0] dds_mult_q;

reg signed [31:0] dds_mult_i_reg;
reg signed [31:0] dds_mult_q_reg;






always@(posedge clk_200m or posedge cfg_rst) begin
	if(cfg_rst)begin
		 fcw_data_reg <= 28'd0;
	end
	else begin
		 fcw_data_reg <= fcw_data;
	end
end





duc_dds duc_dds_inst (
  .clk(clk_200m), // input clk
  .sclr(cfg_rst), // input sclr
  .we(tx_dds_en), // input we
  .data(fcw_data_reg[27:0]), // input [27 : 0] data
  .cosine(dds_cos[15:0]), // output [15 : 0] cosine
  .sine(dds_sin[15:0]) // output [15 : 0] sine
);


s_mult_16x16 duc_dds_i(
    .clk(clk_200m),
    .a(loop_data[31:16]),        //16-bit
    .b(dds_cos[15:0]),     //16-bit
    .p(dds_mult_i[31:0])  // 32-bit
);

s_mult_16x16 duc_dds_q(
    .clk(clk_200m),
    .a(loop_data[15:0]),        //16-bit
    .b(dds_sin[15:0]),     //16-bit
    .p(dds_mult_q[31:0])  // 32-bit
);


always@(posedge clk_200m or posedge cfg_rst) begin
		if(cfg_rst)begin
				dds_mult_i_reg <= 32'd0;
				dds_mult_q_reg <= 32'd0;
		end
		else begin
				dds_mult_i_reg <=  dds_mult_i;
				dds_mult_q_reg <=  dds_mult_q;
		end
end



assign debug[31:0] = dds_mult_i;
assign debug[63:32] = dds_mult_q;
endmodule
