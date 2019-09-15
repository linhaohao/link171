//////////////////////////////////////////////////////////////////////////////////
// Company:         StarPoint
// Engineer:        GUO YAN 
// 
// Create Date:     09:31:20 07/27/2015  
// Module Name:     coarse_syn_four_chan 
// Project Name:    Rx synchronization correlation process;
// Target Devices:  FPGA - XC7K325T - FFG900; 
// Tool versions:   ISE14.6;  
// Description:     The module achieves SYNC data of slot message correlation.
//                  Apply four channel with a pn code,four channel frequency is adjacent
//
// Revision:        v1.0 - File Created
// Additional Comments: 
// 1. SYNC data: 16DP => 8 frequency;
// 2. TR data: 4DP => 8 frequency (same with SYNC frequency);
//
//
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

module coarse_syn_four_chan(
//// clock/reset ////
input               logic_clk_in,        // 200M
input               logic_rst_in,

//// cvs signals ////
input[31:0]         sync_pn_in,                         
input[3:0]          sync_hop_chan_in,
input               sync_pn_hop_en_in,                         

//// data signals ////
input               data_corr0_in, 		// first channel 25M code
input               data_corr1_in, 					   
input               data_corr2_in,
input               data_corr3_in, 		

////coarse threhold////
input [10:0]        decision_term, 		

output              correlate_success_all,
output[10:0]        correlate_peak_all,

output[199:0]       debug_signal
);

//////////////////////////////////////////////////////////////////////////////////
//// signals declaration ////
reg [5:0]          correlate_peak_all_reg  = 6'd0;
wire[10:0]         correlate_peak_out;
wire               correlate_success_out;

wire[199:0]        debug_signal_chan;

reg  [3:0]         pattern_reg [0:31];
reg  [1:0]         pattern_wr_state;
reg  [4:0]         pattern_count;
reg  [9:0]         pattern_renew_delay;
wire [127:0] 	   pattern_reg_buffer;
//////////////////////////////////////////////////////////////////////////////////
//// parameter defination ////


//////////////////////////////////////////////////////////////////////////////////
//// (0) signal assigment ////
assign   correlate_success_all      = correlate_success_out;  
assign   correlate_peak_all[10:0]   = correlate_peak_out[10:0];
 
//////////////////////////////////////////////////////////////////////////////////
////(1)The first synchronization code waiting for related signal
digital_correlate u_digital_correlate_0
   (
   .logic_clk_in(logic_clk_in),     // 200MHz
   .logic_rst_in(logic_rst_in),
   .bit_in_1(data_corr0_in),
   .bit_in_2(data_corr1_in),
   .bit_in_3(data_corr2_in),
   .bit_in_4(data_corr3_in),
   .pattern_reg_buffer(pattern_reg_buffer),
   .sync_pn_hop_en_in(sync_pn_hop_en_in),
   .sync_pn_in(sync_pn_in[31:0]),
   .threshold(decision_term[10:0]),
   .correlate_success_out(correlate_success_out),
   .correlate_peak_out(correlate_peak_out[10:0]),
   .debug_signal(debug_signal_chan[199:0])      
   );

//////////////////////////////////////////////////////////////////////////////////
////frequency hopping pattern////
always@(posedge logic_clk_in)
begin
	if(logic_rst_in)
		begin:  rst_pattern_reg
			integer k;
			for(k =0; k < 32; k = k + 1)
				pattern_reg[k] <= 4'd0;
			
			pattern_count <= 5'd0;
			pattern_renew_delay <= 10'd0;
			pattern_wr_state <= 2'd0;
		end                                   
	else                                      
		begin                                 
			case(pattern_wr_state)
			2'd0:
				begin
				pattern_count <= 5'd0;
				pattern_renew_delay <= 10'd0;
				if(sync_pn_hop_en_in)
					begin
						pattern_wr_state <= 2'd1;
						pattern_count <= 5'd1;
						pattern_reg[0] <= sync_hop_chan_in;
					end
				else
					pattern_wr_state <= 2'd0;	
				end
			2'd1:
				begin
					pattern_count <= pattern_count + 5'd1;
					pattern_reg[pattern_count] <= sync_hop_chan_in;
					if(pattern_count == 5'd31)
						pattern_wr_state <= 2'd2;
					else	
						pattern_wr_state <= 2'd1;
				end
			2'd2:
				begin
					if(pattern_renew_delay == 10'd100)
						begin						
							pattern_renew_delay <= 10'd0;
							pattern_wr_state <= 2'd3;
						end
					else 
						pattern_renew_delay <= pattern_renew_delay + 10'd1;						
				end
			2'd3:
				begin
					pattern_wr_state <= 2'd0;
					pattern_count <= 5'd0;
				end
			endcase
		end
end

assign pattern_reg_buffer[127:96] = {pattern_reg[0],pattern_reg[1],pattern_reg[2],pattern_reg[3],pattern_reg[4],pattern_reg[5],pattern_reg[6],pattern_reg[7]}; 			 
assign pattern_reg_buffer[95:64]  = {pattern_reg[8],pattern_reg[9],pattern_reg[10],pattern_reg[11],pattern_reg[12],pattern_reg[13],pattern_reg[14],pattern_reg[15]}; 
assign pattern_reg_buffer[63:32]  = {pattern_reg[16],pattern_reg[17],pattern_reg[18],pattern_reg[19],pattern_reg[20],pattern_reg[21],pattern_reg[22],pattern_reg[23]}; 
assign pattern_reg_buffer[31:0]   = {pattern_reg[24],pattern_reg[25],pattern_reg[26],pattern_reg[27],pattern_reg[28],pattern_reg[29],pattern_reg[30],pattern_reg[31]}; 
//////////////////////////////////////////////////////////////////////////////////
//// debug ////
assign   debug_signal[199:0]        = debug_signal_chan[199:0];






//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////


endmodule 