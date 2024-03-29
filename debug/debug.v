////////////////////////////////////////////////////////////////////////////////
// Company: StarPoint
// Engineer: guanzheye
//
// Create Date: 
// Design Name: 
// Module Name: 
// Target Device: FPGA XC7K325T-2FFG900 
// Tool versions: ISE 14.6
// Description:
//       ��
// Revision:   v1.0 - File Created
// Additional Comments:
//   DEBUG
////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

module debug(
// clock & Reset
input 				 clk_400k,
input                clk_5mhz,
input 				 clk_50mhz,
input                clk_10mhz,  
input                clk_20mhz, 
input                clk_100mhz,     
input                clk_200mhz,
input                sys_rst, 
input 				 dac_data_clk, 
//--------------------------------------
//sys_state
input                dsp2fpga_dsp_rdy,
input                lmk04806_1_locked_in,
input                lmk04806_1_holdover,
input                lmk04806_2_holdover,

input                tx_slot_dsp_interrupt,
input 							 rx_data_dsp_interrupt,
input                usb2fpga_uart_rxd,


input  [255:0]       tx_debug,
input  [255:0]		 tx_debug_2,
input  [255:0]		 tx_debug_3,
input  [255:0]		 adc_debug,
input  [255:0]		 adc_debug_2,
input  [255:0]		 ddc_iq_debug,		
input  [255:0]       debug_decode,
input  [255:0]       debug_data_dsp,
input  [255:0]       dec_debug_1,
input  [255:0]       dec_debug_2,
input  [255:0]		 mcbsp_debug,
input  [58:0] 		 store10k_debug,
input  [255:0]       slot_debug,  
input  [199:0]       dac_cfg_debug,
input  [63:0]        sys_debug,
input  [255:0] 		 uart_debug

);

//////////////////////////////////////////////////////////////////////////////////
wire  [35:0]        control0;
wire  [35:0]        control1;
wire  [15:0]        async_vio_out;
wire  [255:0]       debug_data;
wire  [255:0]       debug_data_2;
wire debug_clk;

icon_core  icon_module
    (
     .CONTROL0(control0[35:0]),
     .CONTROL1(control1[35:0])     
    );

vio_core   vio_module
    (
	 .CONTROL(control0[35:0]),    
     .ASYNC_OUT(async_vio_out[15:0]) 
	 );

ila_core  ila_module
   (
    .CONTROL(control1[35:0]),
    .CLK(debug_clk),
    .TRIG0(debug_data[255:0]) 
   );



                                  
assign debug_data[255:0] = 
//													(async_vio_out[15:8] == 8'd21 )?  {54'b0,rx_data_dsp_interrupt,tx_slot_dsp_interrupt,clk_100mhz,dac_data_clk,dac_cfg_debug[197:0]}  :
													(async_vio_out[15:8] == 8'd19 )?  mcbsp_debug:
//													(async_vio_out[15:8] == 8'd20 )?  dec_debug_2:
													(async_vio_out[15:8] == 8'd21 )?  mcbsp_debug:

//                             (async_vio_out[15:8] == 8'd22 )?  {slot_debug[2:0],sys_debug[63:0],tx_debug_2[210:197],mcbsp_debug[238:222],slot_debug[39:8],mcbsp_debug[125:0]}: 
////	                         (async_vio_out[15:8] == 8'd23 )?  {91'b0,slot_debug[39:33],tx_debug_3[227],tx_debug_3[169:166],adc_debug[191],debug_data_dsp[96:84],debug_data_dsp[35:0],tx_debug_3[243:228],tx_debug_3[165:144],adc_debug[159:128],slot_debug[32:0] } :
//	                          (async_vio_out[15:8] == 8'd23 )?  tx_debug :
//	                          (async_vio_out[15:8] == 8'd24 )?  tx_debug :
//	                          (async_vio_out[15:8] == 8'd25 )?  slot_debug :
////                          //  (async_vio_out[15:8] == 8'd25 )?  {12'b0,debug_data_dsp[70:69],debug_data_dsp[38:23],debug_data_dsp[255:247],debug_data_dsp[17:2],slot_debug[200:0]} :
//	                         (async_vio_out[15:8] == 8'd26 )?  slot_debug : 
//	                         (async_vio_out[15:8] == 8'd27 )?  debug_data_dsp : 
//	                         (async_vio_out[15:8] == 8'd28 )?  tx_debug_3    :
////	                         (async_vio_out[15:8] == 8'd29 )?  debug_data_dsp : 
//	                         (async_vio_out[15:8] == 8'd30 )?   mcbsp_debug:
//	                         (async_vio_out[15:8] == 8'd30 )?  {109'b0,tx_debug_3[227],tx_debug_3[169:144],tx_debug_3[246:245],tx_debug[42:0],slot_debug[39:33],tx_debug[9],tx_debug[255:243],debug_data_dsp[167:152],mcbsp_debug[1],mcbsp_debug[128],mcbsp_debug[187],rx_data_dsp_interrupt,tx_slot_dsp_interrupt,slot_debug[32:0]} : 
//                          (async_vio_out[15:8] == 8'd31 )?	 {33'b0,adc_debug_2[50:40],store10k_debug[58:0],debug_decode[152:0]}:	
                          256'd0; 
//	                         (async_vio_out[15:8] == 8'd32 )?	 {23'b0,debug_data_dsp[201:184],slot_debug[39:8],debug_data_dsp[96],debug_data_dsp[203],debug_data_dsp[204],debug_data_dsp[246],mcbsp_debug[235],mcbsp_debug[69:64],debug_data_dsp[245:241],debug_data_dsp[208],debug_data_dsp[34],mcbsp_debug[186:155],debug_data_dsp[33:18],debug_data_dsp[167:152],debug_data_dsp[118:103],debug_data_dsp[240:209],debug_data_dsp[83:68],debug_data_dsp[97],debug_data_dsp[67:36],debug_data_dsp[201:200],debug_data_dsp[207:206]}	:	
//	                         (async_vio_out[15:8] == 8'd33 )?	 {slot_debug[19:8],tx_debug_2[243:0]}:	256'd0;      
                                  
assign debug_clk = 
									(async_vio_out[15:8] == 8'd19 )?  clk_400k  :
//									(async_vio_out[15:8] == 8'd20 )?  clk_200mhz  :
									(async_vio_out[15:8] == 8'd21 )?  clk_200mhz  :
//                  (async_vio_out[15:8] == 8'd22 )?  clk_100mhz : 
//                  (async_vio_out[15:8] == 8'd23 )?  clk_200mhz :
//                  (async_vio_out[15:8] == 8'd24 )?  clk_400k :
//                  (async_vio_out[15:8] == 8'd25 )?  clk_100mhz :
//                  (async_vio_out[15:8] == 8'd26 )?  clk_50mhz : 
                  //(async_vio_out[15:8] == 8'd27 )?  clk_100mhz :
//                  (async_vio_out[15:8] == 8'd28 )?  clk_400k :
//                  (async_vio_out[15:8] == 8'd29 )?  clk_200k :                             
//                   (async_vio_out[15:8] == 8'd30 )?  clk_50mhz : 
//                  (async_vio_out[15:8] == 8'd31 )?  clk_100mhz : 
                  clk_100mhz; 
//                    (async_vio_out[15:8] == 8'd32 )? clk_50mhz :
//                    (async_vio_out[15:8] == 8'd33 )? clk_400k : clk_100mhz;                                         
//assign  debug_data_2[255:0] = debug_data_dsp;                        
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
endmodule








