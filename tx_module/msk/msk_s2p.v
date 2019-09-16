//////////////////////////////////////////////////////////////////////////////////
// Company:         StarPoint
// Engineer:        guoyan
// 
// Create Date:     14:05:00 06/10/2015  
// Module Name:     s2p
// Project Name:    
// Target Devices:  FPGA - XC7K325T - FFG900; 
// Tool versions:   ISE14.6;  
// Description:     The module achieves differential encoding 
//                  and deserializing 
// 
// Revision:        v1.0 - File Created
// Additional Comments: 
// 1. differential encoding obtains adjacent input data saltus 
// 2. serial data stream convert into parallel I/Q data which rate halving,but I/Q fill same code to keep same rate.
// dif encode: b1,b2,b3,b4
// I: I0,b2,b2,b4 (I0=1,delay ts)
// Q: b1,b1,b3,b3
// 3.msk_data_in_vaild在msk_data_in_pulse的末尾处，故新的pulse时间需和新的数据对齐,相当有一个200us延迟
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

module msk_s2p(
//// clock/reset ////
input               logic_clk_in,
input               logic_rst_in,

//// data signal ////
input               msk_data_in_pulse,
input               msk_data_in_vaild,
input               msk_data_in, 
input[6:0]          msk_data_cnt,

output              s2p_pulse_out,
output              s2p_vaild_out,
output              s2p_i_out,
output              s2p_q_out,

//// debug ////
output[63:0]        debug_signal
);

//////////////////////////////////////////////////////////////////////////////////
//// (0) signal assigment ////
reg [40:0]          msk_data_pulse_dly  = 41'd0;
reg [1:0]           msk_data_vaild      = 2'h0;
reg                 dif_msk_data        = 1'b1;
reg                 des_flag            = 1'b0;
                                        
reg                 des_msk_i_reg       = 1'b1;
reg                 des_msk_q_reg       = 1'b0;

//////////////////////////////////////////////////////////////////////////////////
//// (1)differential encoding logic ////
// b(n) = a(n)^~b(n-1), same is 1,dif is 0
always@(posedge logic_clk_in)
begin
   if (logic_rst_in)   begin
	  dif_msk_data                <= 1'b1; //keep b0=a0
	end
	else if(msk_data_in_vaild)  begin
	  dif_msk_data                <= msk_data_in ^~ dif_msk_data;
	end
end

//////////////////////////////////////////////////////////////////////////////////
//// (2)deserializing encoding logic ////
always@(posedge logic_clk_in)
begin
   if (logic_rst_in)   begin
	  des_flag                    <= 1'b0;	
	end
	else if(msk_data_vaild[0])    begin
	  des_flag                    <= ~des_flag;	//I/Q, i0 i0 i1 i1 make sure deserializing rate consistently
	end
end

always@(posedge logic_clk_in)
begin
   if (logic_rst_in)   begin
	  msk_data_vaild[1:0]         <= 2'b00;
	end
   else begin
     msk_data_vaild[1:0]         <= {msk_data_vaild[0],msk_data_in_vaild};
   end
end

///////I = 1,b2,b2,b4,b4,b6,b6,b8
///////Q = b1,b1,b3,b3,b5,b5,b7,b7
always@(posedge logic_clk_in)
begin
   if (logic_rst_in)   begin
	  des_msk_i_reg               <= 1'b1;	//add first I0 
	  des_msk_q_reg               <= 1'b0;
   end
   else if(msk_data_cnt[6:0] == 7'd33) begin
     des_msk_i_reg               <= 1'b1;	//add first I0 
	  des_msk_q_reg               <= 1'b0;
   end   
   else if(msk_data_vaild[0] && (des_flag == 1'b1)) begin
      des_msk_i_reg               <= dif_msk_data;	
   end   
   else if(msk_data_vaild[0] && (des_flag == 1'b0))  begin                  
	  des_msk_q_reg               <= dif_msk_data;	
   end
end

//////////////////////////////////////////////////////////////////////////////////
//// (3)genenrate 6.4us&6.6us logic ////
always@(posedge logic_clk_in)
begin
   if (logic_rst_in)   begin
	  msk_data_pulse_dly[40:0]     <= 41'd0;
	end                           
   else begin                     
     msk_data_pulse_dly[40:0]     <= {msk_data_pulse_dly[39:0],msk_data_in_pulse}; 
   end
end

//////////////////////////////////////////////////////////////////////////////////
//// (3)output logic ////
assign s2p_i_out                    = des_msk_i_reg;
assign s2p_q_out                    = des_msk_q_reg;
assign s2p_vaild_out                = msk_data_vaild[1];    //6.4&6.6us && 5M
assign s2p_pulse_out                = msk_data_pulse_dly[40]; //6.4&6.6us 

//////////////////////////////////////////////////////////////////////////////////
//// (4)debug logic ////
assign debug_signal[56]              = msk_data_in_vaild;
assign debug_signal[57]              = msk_data_in;
assign debug_signal[58]              = msk_data_vaild[0];
assign debug_signal[59]              = dif_msk_data;
assign debug_signal[60]              = s2p_vaild_out;
assign debug_signal[61]              = s2p_i_out;
assign debug_signal[62]              = s2p_q_out;
assign debug_signal[63]              = s2p_pulse_out;
assign debug_signal[55:0]            = 56'd0;




////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
endmodule
