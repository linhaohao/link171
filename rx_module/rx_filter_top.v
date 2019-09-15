//////////////////////////////////////////////////////////////////////////////////
// Company:         StarPoint
// Engineer:        GUO YAN 
// 
// Create Date:     17:10:41 07/30/2015  
// Module Name:     rx_filter_top 
// Project Name:    fir16 Rx filter process module;
// Target Devices:  FPGA - XC7K325T - FFG900; 
// Tool versions:   ISE14.6;  
// Description:     The module achieves 8-firs data filter processing;
// 
//
// Revision:        v1.0 - File Created
// Additional Comments: 
// 1. data rate: 200M -> 100M -> 50M -> 25M;
// 2. 3 halfband filter + 1 lowpass pulse-shaping filter;
//
//
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps


module rx_filter_top(
//// clock/reset ////
input               logic_clk_in,     // 200MHz logic clock
input               logic_rst_in,                       

//// data signal ////
input [31:0]        data_fir0_in,
input [31:0]        data_fir1_in,
input [31:0]        data_fir2_in,
input [31:0]        data_fir3_in,     // 4-firs data input(200Mchip/s)

output[31:0]        data_fir0_out,
output[31:0]        data_fir1_out,
output[31:0]        data_fir2_out,
output[31:0]        data_fir3_out,    // 4-firs data output(20Mchip/s)

output              fir0_rdy_out,
output              fir1_rdy_out,
output              fir2_rdy_out,
output              fir3_rdy_out,

//// debug ////
output[199:0]       debug_signal

    );


//////////////////////////////////////////////////////////////////////////////////
//// signals declaration ////
wire[31:0]          fir0_data_out;
wire[31:0]          fir1_data_out;
wire[31:0]          fir2_data_out;
wire[31:0]          fir3_data_out;

wire                fir0_rdy_reg;
wire                fir1_rdy_reg;
wire                fir2_rdy_reg;
wire                fir3_rdy_reg;

wire[199:0]         debug_signal_fir0;
wire[199:0]         debug_signal_fir1;
wire[199:0]         debug_signal_fir2;
wire[199:0]         debug_signal_fir3;


//////////////////////////////////////////////////////////////////////////////////
//// parameter defination ////


//////////////////////////////////////////////////////////////////////////////////
//// (0) signal assigment ////
   //// filter output data ////
   assign  data_fir0_out[31:0]          = fir0_data_out[31:0];
   assign  data_fir1_out[31:0]          = fir1_data_out[31:0];
   assign  data_fir2_out[31:0]          = fir2_data_out[31:0];
   assign  data_fir3_out[31:0]          = fir3_data_out[31:0];

   assign  fir0_rdy_out                 = fir0_rdy_reg;
   assign  fir1_rdy_out                 = fir1_rdy_reg;
   assign  fir2_rdy_out                 = fir2_rdy_reg;
   assign  fir3_rdy_out                 = fir3_rdy_reg;


//////////////////////////////////////////////////////////////////////////////////
//// (1) Filter mapping logic ////
//// fir1 firter module ////
rx_filter_module   u0_rx_filter  
    (
	//clock&reset signals
	.logic_clk_in(logic_clk_in),                             // 200MHz
	.logic_rst_in(logic_rst_in),

	//data signals
	.data_fir_in(data_fir0_in[31:0]),                        // 200Mchips/s
	.data_fir_out(fir0_data_out[31:0]),                      // 25Mchips/s
	
	.fir_rdy_out(fir0_rdy_reg),
	
	//debug
	.debug_signal(debug_signal_fir0[199:0])
	
	 );


rx_filter_module   u1_rx_filter  
    (
	//clock&reset signals
	.logic_clk_in(logic_clk_in),                             // 200MHz
	.logic_rst_in(logic_rst_in),

	//data signals
	.data_fir_in(data_fir1_in[31:0]),                        // 200Mchips/s
	.data_fir_out(fir1_data_out[31:0]),                      // 25Mchips/s
	
	.fir_rdy_out(fir1_rdy_reg),
	
	//debug
	.debug_signal(debug_signal_fir1[199:0])
	
	 );
	 

rx_filter_module   u2_rx_filter  
    (
	// clock&reset signals
	.logic_clk_in(logic_clk_in),                             // 200MHz
	.logic_rst_in(logic_rst_in),

	// data signals
	.data_fir_in(data_fir2_in[31:0]),                        // 200Mchips/s
	.data_fir_out(fir2_data_out[31:0]),                      // 25Mchips/s
	
	.fir_rdy_out(fir2_rdy_reg),
	
	// debug
	.debug_signal(debug_signal_fir2[199:0])
	
	 );

 rx_filter_module  u3_rx_filter  
     (
	//clock&reset signals
	 .logic_clk_in(logic_clk_in),                             // 200MHz
	 .logic_rst_in(logic_rst_in),

	//data signals
	 .data_fir_in(data_fir3_in[31:0]),                        // 200Mchips/s
	 .data_fir_out(fir3_data_out[31:0]),                      // 25Mchips/s
	
	 .fir_rdy_out(fir3_rdy_reg),
	
	//debug
	.debug_signal(debug_signal_fir3[199:0])
	
	  );


//////////////////////////////////////////////////////////////////////////////////





//////////////////////////////////////////////////////////////////////////////////
//// (11) debug ////
assign  debug_signal[199:0]             = debug_signal_fir0[199:0];





//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
endmodule
