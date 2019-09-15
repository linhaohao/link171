//////////////////////////////////////////////////////////////////////////////////
// Company:         StarPoint
// Engineer:        GUO YAN 
// 
// Create Date:     13:40:22 07/24/2015 
// Module Name:     msk_demodulation_top 
// Project Name:    Link16 Rx MSK demodulation process module;
// Target Devices:  FPGA - XC7K325T - FFG900; 
// Tool versions:   ISE14.6;  
// Description:     The module achieves data MSK demodulation.
// 
//
// Revision:        v1.0 - File Created
// Additional Comments: 
//
//
//
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps


module msk_demodulation_top(
//// clock/reset ////
input               logic_clk_in,                           // 200MHz logic clock
input               logic_rst_in,   

//// data signal ////
input [31:0]        data_msk0_in,
input [31:0]        data_msk1_in,
input [31:0]        data_msk2_in,
input [31:0]        data_msk3_in,

output              data_msk0_out,
output              data_msk1_out,
output              data_msk2_out,
output              data_msk3_out,

output [15:0]       tr_msk0_out,
output [15:0]       tr_msk1_out,
output [15:0]       tr_msk2_out,
output [15:0]       tr_msk3_out,


//// debug ////
output[127:0]       debug_signal

    );


//////////////////////////////////////////////////////////////////////////////////
//// signals declaration ////



//////////////////////////////////////////////////////////////////////////////////
//// parameter defination ////


//////////////////////////////////////////////////////////////////////////////////
//// (0) signal assigment ////



//////////////////////////////////////////////////////////////////////////////////
//// (1) link0 MSK demodulation mapping ////
msk_demodulation_module   u0_msk_demodulation
   (
	// clock&reset signals
	.logic_clk_in(logic_clk_in),                             // 200MHz
	.logic_rst_in(logic_rst_in),
	
	// data signals
	.data_msk_in(data_msk0_in[31:0]),                       // 25Mchips/s
	.data_msk_out(data_msk0_out),                           // 1bit/200ns
	
	.tr_msk_out(tr_msk0_out[15:0]),
	
	// debug
	.debug_signal()
	
	);


//////////////////////////////////////////////////////////////////////////////////
//// (2) link1 MSK demodulation mapping ////
msk_demodulation_module   u1_msk_demodulation
   (
	// clock&reset signals
	.logic_clk_in(logic_clk_in),                             // 200MHz
	.logic_rst_in(logic_rst_in),
	
	// data signals
	.data_msk_in(data_msk1_in[31:0]),                       // 25Mchips/s
	.data_msk_out(data_msk1_out),                           // 1bit/200ns
	
	.tr_msk_out(tr_msk1_out[15:0]),
	
	// debug
	.debug_signal()
	
	);


//////////////////////////////////////////////////////////////////////////////////
//// (3) link2 MSK demodulation mapping ////
msk_demodulation_module   u2_msk_demodulation
   (
	// clock&reset signals
	.logic_clk_in(logic_clk_in),                             // 200MHz
	.logic_rst_in(logic_rst_in),
	
	// data signals
	.data_msk_in(data_msk2_in[31:0]),                       // 25Mchips/s
	.data_msk_out(data_msk2_out),                           // 1bit/200ns
	
	.tr_msk_out(tr_msk2_out[15:0]),
	
	// debug
	.debug_signal()
	
	);


//////////////////////////////////////////////////////////////////////////////////
//// (4) link3 MSK demodulation mapping ////
msk_demodulation_module   u3_msk_demodulation
   (
	// clock&reset signals
	.logic_clk_in(logic_clk_in),                             // 200MHz
	.logic_rst_in(logic_rst_in),
	
	// data signals
	.data_msk_in(data_msk3_in[31:0]),                       // 25Mchips/s
	.data_msk_out(data_msk3_out),                           // 1bit/200ns
	
	.tr_msk_out(tr_msk3_out[15:0]),
	
	// debug
	.debug_signal()
	
	);

	
//////////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////////////////
//// debug signals ////



//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
endmodule
