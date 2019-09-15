`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    09:41:27 03/28/2017 
// Design Name: 
// Module Name:    ddc_iq 
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
module ddc_iq(
		input clk_200m,
		input cfg_rst,
		
		input  [15:0] data,
		input  [27:0] fcw_data,
		input         dac_txenable,
		input 		  rx_dds_en,
		input  [31:0] loop_data,
		output [15:0] data_out_i,
		output [15:0] data_out_q,
		
		output [255:0] ddc_iq_debug

    );

assign data_out_i = dds_mult_i_reg[27:12];
assign data_out_q = dds_mult_q_reg[27:12];


//assign data_out_i = dds_mult_i_reg[21:6];
//assign data_out_q = dds_mult_q_reg[21:6];

reg [27:0] fcw_data_reg;
wire signed [15:0] dds_sin;
wire signed [15:0] dds_cos;

wire signed [31:0] dds_mult_i;
wire signed [31:0] dds_mult_q;

reg signed [31:0] dds_mult_i_reg;
reg signed [31:0] dds_mult_q_reg;

//wire signed [20:0] dds_mult_i_rnd;
//wire signed [20:0] dds_mult_q_rnd;
//
//wire signed [15:0] dds_mult_i_out;
//wire signed [15:0] dds_mult_q_out;



always@(posedge clk_200m or posedge cfg_rst) begin
	if(cfg_rst)begin
		 fcw_data_reg <= 28'd0;
	end
	else begin
		 fcw_data_reg <= fcw_data;
	end
end


//////////////////////////////////////////////////////////////////////////////////
//// (1) DDS module for  IF

	
ddc_dds_new ddc_dds_inst (
  .clk(clk_200m), // input clk
  .sclr(cfg_rst), // input sclr
  .we(rx_dds_en), // input we
  .data(fcw_data_reg[27:0]), // input [27 : 0] data
  .cosine(dds_cos[15:0]), // output [15 : 0] cosine
  .sine(dds_sin[15:0]) // output [15 : 0] sine
);	
////	
//dds_ddc dds_ddc_inst (
//  .clk(clk_200m), // input clk
//  .sclr(cfg_rst), // input sclr
//  .cosine(dds_cos[15:0]), // output [15 : 0] cosine
//  .sine(dds_sin[15:0]) // output [15 : 0] sine
//);



s_mult_16x16 dds_i(
    .clk(clk_200m),
    .a(data[15:0]),        //16-bit
    .b(dds_cos[15:0]),     //16-bit
    .p(dds_mult_i[31:0])  // 32-bit
);

s_mult_16x16 dds_q(
    .clk(clk_200m),
    .a(data[15:0]),        //16-bit
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


// rnd #
//  (     
//    .IN_WIDTH                          ( 32                 ),  //32
//    .RND_WIDTH                         ( 11                 )   //14
// ) u0_rnd (                                                   
//    .clk                               ( clk_200m       ),
//    .rst                               ( cfg_rst       ),
//    .din_i                             ( dds_mult_i   ),
//    .din_q                             ( dds_mult_q   ),
//                                       
//    .dout_i                            ( dds_mult_i_rnd ),
//    .dout_q                            ( dds_mult_q_rnd )
//   );
//   
//   
//  sat #
//   (     
//     .IN_WIDTH                          ( 21                 ),//18
//     .SAT_WIDTH                         ( 5                  ) //2
//   ) u0_sat(                                                    
//     .clk                               ( clk_200m       ),
//     .rst                               ( cfg_rst       ),
//     .din_i                             ( dds_mult_i_rnd ),
//     .din_q                             ( dds_mult_q_rnd ),
//            
//     .dout_i                            ( dds_mult_i_out     ),
//     .dout_q                            ( dds_mult_q_out     )
//    );  
//    



assign ddc_iq_debug[15:0]    = dds_sin;
assign ddc_iq_debug[31:16]   = dds_cos;
assign ddc_iq_debug[63:32]   = dds_mult_i;
assign ddc_iq_debug[95:64]   = dds_mult_q;
assign ddc_iq_debug[111:96]  = data_out_i;
assign ddc_iq_debug[127:112] = data_out_q;
assign ddc_iq_debug[128]     = dac_txenable;
assign ddc_iq_debug[144:129] = data;

endmodule
