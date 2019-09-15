//////////////////////////////////////////////////////////////////////////////////
// Company:         StarPoint
// Engineer:        GUO YAN 
// 
// Create Date:     09:38:45 07/31/2015  
// Module Name:     rx_descramble_top 
// Project Name:    Rx decramble process module;
// Target Devices:  FPGA - XC7K325T - FFG900; 
// Tool versions:   ISE14.6; 
// Description:     The module achieves decramble for received data;
//
//
// Revision:        v1.0 - File Created
// Additional Comments: 
// 1. data number: 16DP(header) + 93*N(data);
//
//
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps


module rx_descramble_top(
//// clock interface ////
input               logic_clk_in,                           // 200MHz logic clock
input               logic_rst_in,                           // 7.8125ms reset

//// control singals ////
input               data_pulse_in,

//// data signals ////
input [31:0]        pn_descramble_in,
input [31:0]        data_descramble_in,

output              data_descramble_vaild,
output[31:0]        data_descramble_out,

//// debug ////
output[127:0]       debug_signal

    );


//////////////////////////////////////////////////////////////////////////////////
//// signals declaration //// 
reg [31:0]          data_descramble_reg;
reg [ 3:0]          data_pulse_reg;


//////////////////////////////////////////////////////////////////////////////////
//// parameters define ////




//////////////////////////////////////////////////////////////////////////////////
//// (0) signals assigment ////
    assign  data_descramble_vaild       = data_pulse_reg[0];
    assign  data_descramble_out[31:0]   = data_descramble_reg[31:0];



//////////////////////////////////////////////////////////////////////////////////
//// (1) descramble logic ////
always@(posedge logic_clk_in)
begin
   if (logic_rst_in)   begin
	  data_descramble_reg[31:0]          <= 32'd0;
	  data_pulse_reg[3:0]                <= 4'd0;
	end
	else if (data_pulse_in)   begin
     data_descramble_reg[31:0]           <= data_descramble_in[31:0] ^ pn_descramble_in[31:0];
	 data_pulse_reg[0]                   <= data_pulse_in;
	 data_pulse_reg[3:1]                 <= 3'd0;
   end                                   
   else   begin                          
	 data_pulse_reg[3:1]                 <= data_pulse_reg[2:0];
	 data_pulse_reg[0]                   <= 1'b0;
  end
end


//////////////////////////////////////////////////////////////////////////////////
//// debug signals ////
assign  debug_signal[127:0]               = 128'd0;


//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
endmodule
