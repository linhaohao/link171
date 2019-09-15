`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:31:41 11/17/2017 
// Design Name: 
// Module Name:    duc_top 
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
module duc_top(


		input clk_200m,
		input cfg_rst,
		input rx_dds_en,
		input  [31:0]  loop_data,
		output [15:0]  loopdata_out_i,
		output [15:0]  loopdata_out_q
		
		
		
    );


reg [27:0]  dac_data_fcw;

always@(posedge clk_200m or posedge cfg_rst) begin
	if(cfg_rst) begin
			dac_data_fcw <= 28'd0;
	end
	else begin
			dac_data_fcw <= 28'h5333333;
	end
end

duc_iq duc_iq_inst(
		.clk_200m					(clk_200m),
		.cfg_rst					(cfg_rst),	
		.tx_dds_en				(rx_dds_en),
		.loop_data				(loop_data),		
		.fcw_data					(dac_data_fcw),
		
		.data_out_i				(loopdata_out_i),
		.data_out_q				(loopdata_out_q),
		.debug						()
);


endmodule
