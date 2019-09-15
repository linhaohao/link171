////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Company:         StarPoint
// Engineer:        GUO YAN 
// 
// Create Date:     10:27:30 10/09/2015   
// Module Name:     hard_timing_ctl
// Project Name:    timing control module for hard board
// Target Devices:  FPGA - XC7K325T - FFG900; 
// Tool versions:   ISE14.6;
// Description:     The module achieves two timing synchronization process,including:
//                  digital board timing ctontrl for DA
//                  rf board timing ctontrl for local oscillator, channel selection and carrier shut
//                  
// 
// Revision:        v1.0 - File Created
// Additional Comments: 
// 1.
// 
//
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps


module hard_timing_ctl(
//// clock interface ////
input               logic_clk_in,                 // 200MHz logic clock
input               logic_rst_in,
input				clk_20mhz,
input               dac_io_update,
//关于FPGA UART的控制信号
input				rv_uart_vld,		//串口输入命令数据标识
input	[63:0]		rv_uart_data,		//串口输入命令数据
input               tx_rx_switch_out,

//// time information ////
input [31:0]        slot_timer,
input [31:0]        net_slot_rfposi,
input [31:0]        net_tx_pulse_num,

input               dl_data_dac_en,

//// freq hop information ////
input [7:0]         tx_feq_cfg,


input [31:0]        mif_tx_feq_mode,

input               tx_end_pulse,

//// output rf tx timing ctl ////
output[2:0]         tx_chan_sel_p, 
output[2:0]         tx_chan_sel_n, 

output[3:0]         tx_lo_en_p,
output[3:0]         tx_lo_en_n,

output[1:0]         tx_carrier_sel_p,
output[1:0]         tx_carrier_sel_n,

output              tx_rf_test,

output              power_send_p,       //功放收发P,高发低收
output              power_send_n,       //功放收发n
output              power_slot_p,       //功放时隙p
output              power_slot_n,       //功放时隙n

output              power_send_out,    //功放收发
output              power_slot_out,    //功放时隙

//// debug signals ////
output[127:0]       debug_signal
	 
);


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//// signals declaration ////
reg [7:0]         tx_feq_cfg_reg          = 8'd0;

reg               tx_rf_en                = 1'b0;	   
reg               tx_rf_ctl               = 1'b0;   
reg [15:0]        tx_rf_cnt               = 16'd0; 
reg [8:0]         tx_rf_pulse_cnt         = 9'd0;
                                         
reg [2:0]         tx_chan_sel             = 3'd0;   
reg [3:0]         tx_lo_en                = 4'd0;      
reg [1:0]         tx_carrier_sel          = 2'd0;

reg [2:0]         tx_chan_sel_in          = 3'd4;   
wire [2:0]        tx_chan_sel_o;  
reg [3:0]         tx_lo_en_in             = 4'd8;      
wire [3:0]        tx_lo_en_o ;   
reg               tx_rf_select            = 1'b0;   

reg               change_pa               = 1'b1;
reg               power_send_r            = 1'b1;    //功放收发
reg               power_slot_r            = 1'b1;    //功放时隙
reg               power_send_in           = 1'b1;    //功放收发
reg               power_slot_in           = 1'b1;    //功放时隙
// wire              power_send_out;    //功放收发
// wire              power_slot_out;    //功放时隙

reg				  change_carrier		  = 1'b0;
reg	[1:0]		  carrier_r				  = 2'b10;
wire[1:0]         carrier_out;
reg [2:0]         io_update_reg           = 3'd0;
reg [2:0]         chan_sel_update;
reg [3:0]         lo_en_update;
//reg [7:0]         tx_feq_mode;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//// parameter define ////
parameter         tx_rf_occupy            = 16'd1679;          //8.4us=8.4*200=1680 clk
parameter         tx_rf_band              = 16'd2599;          //13us=13*200=2600 clk

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//// (0) signals assigment ////
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//// (1) input delay////
// always@(posedge logic_clk_in)(RAM 100ns, sampling error)
// begin
   // if (logic_rst_in)   begin
       // tx_feq_cfg_reg[7:0]                <= 8'd0;                     
   // end
   // else  begin
       // tx_feq_cfg_reg[7:0]                <= tx_feq_cfg[7:0];
   // end
// end

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// (2)  selection timing ////
always@(posedge logic_clk_in)
begin
   if (logic_rst_in)
       tx_feq_cfg_reg     <= 8'h84;                     
   else if(mif_tx_feq_mode[31])
       tx_feq_cfg_reg     <= mif_tx_feq_mode[7:0];
   else
       tx_feq_cfg_reg     <= tx_feq_cfg;
end


always@(posedge logic_clk_in)begin
    io_update_reg[2:0]       <=  {io_update_reg[1:0],dac_io_update};
end
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//// (2)  selection timing ////
always@(posedge logic_clk_in)
begin
   if (logic_rst_in)   begin
       tx_rf_en                           <= 1'b0;                     
   end
  // else if(tx_end_pulse)begin //tx_end_pulse after 4.6us,will pull tx_rf_en at the end
   else if((tx_rf_cnt[15:0] == tx_rf_band[15:0])&&(tx_rf_pulse_cnt[8:0] == (net_tx_pulse_num[8:0] - 1'b1)))begin      
	   tx_rf_en                           <= 1'b0; 
   end   
   else if ((slot_timer[31:0] == net_slot_rfposi[31:0]) && (net_slot_rfposi[31:0] != 32'd0)) begin //!0 prvent intial tx_rf_en =1         
       tx_rf_en                           <= 1'b1;   
   end
end

always@(posedge logic_clk_in)
begin
   if (logic_rst_in)   begin
       tx_rf_cnt[15:0]                    <= 16'd0;                     
   end
   else if(tx_rf_cnt[15:0] == tx_rf_band[15:0])begin
       tx_rf_cnt[15:0]                    <= 16'd0; 
   end   
   else if (tx_rf_en) begin          
       tx_rf_cnt[15:0]                    <= tx_rf_cnt[15:0] + 1'b1;   
   end
end

always@(posedge logic_clk_in)
begin
   if (logic_rst_in)   begin
       tx_rf_pulse_cnt[8:0]                    <= 9'd0;                     
   end
   else if(tx_rf_cnt[15:0] == tx_rf_band[15:0])begin
       if(tx_rf_pulse_cnt[8:0] == (net_tx_pulse_num[8:0] - 1'b1))begin
          tx_rf_pulse_cnt[8:0]                    <= 9'd0; 
       end   
       else begin          
       tx_rf_pulse_cnt[8:0]                    <= tx_rf_pulse_cnt[8:0] + 1'b1;   
       end
   end
end

always@(posedge logic_clk_in)
begin
   if (logic_rst_in)   begin
       tx_rf_ctl                          <= 1'b0;                     
   end
   else if (tx_rf_en && (tx_rf_cnt[15:0] <= tx_rf_occupy[15:0])) begin          
       tx_rf_ctl                          <= 1'b1;   
   end
   else begin
       tx_rf_ctl                          <= 1'b0; 
   end   

end
//*************时隙test引脚***************************************
// always@(posedge logic_clk_in)
// begin
   // if (logic_rst_in)   begin
       // tx_rf_test                         <= 1'b0;                     
   // end
   // else if (tx_rf_en && (tx_rf_cnt[15:0] >= 16'd200) && (tx_rf_cnt[15:0] <= tx_rf_occupy[15:0] - 200)) begin          
       // tx_rf_test                         <= 1'b1;   
   // end
   // else begin
       // tx_rf_test                         <= 1'b0; 
   // end   

// end

assign  tx_rf_test      =           dl_data_dac_en;
//***************************************************************

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//// (3) tx channel selection logic ////
always@(posedge logic_clk_in)
begin
   if (logic_rst_in)   begin
       tx_chan_sel[2:0]                   <= 3'h4;                     
   end
   else if(mif_tx_feq_mode[16] == 1'b0)begin
           if(io_update_reg[2:1] == 2'b01)
             tx_chan_sel[2:0]                   <= tx_feq_cfg_reg[2:0];
           else 
             tx_chan_sel[2:0]                   <= tx_chan_sel[2:0] ;
   end
   else if (tx_rf_ctl)   begin
       tx_chan_sel[2:0]                   <= tx_feq_cfg_reg[2:0];
   end
   else
        ;
end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//// (4) tx local oscillator enable logic ////
always@(posedge logic_clk_in)
begin
   if (logic_rst_in)   begin
       tx_lo_en[3:0]                      <= 4'h8;                      
   end
   else if(mif_tx_feq_mode[16] == 1'b0)begin
           if(io_update_reg[2:1] == 2'b01)
             tx_lo_en[3:0]                   <= tx_feq_cfg_reg[7:4];
           else 
             tx_lo_en[3:0]                   <= tx_lo_en[3:0] ;
   end
   else if (tx_rf_ctl)   begin 
      tx_lo_en[3:0]                      <=  tx_feq_cfg_reg[7:4];
   end
   else
       ;
end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//// (5) tx carrier selection logic ////
always@(posedge logic_clk_in)
begin
   if (logic_rst_in)   begin
       tx_carrier_sel[1:0]                <= 2'b01;                      
   end
   else if (tx_rf_ctl)   begin
       tx_carrier_sel[1:0]                <= 2'b10;   
       // power_send_in                      <= 1'b1;
       power_slot_in                      <= 1'b1;
   end
   else begin
       tx_carrier_sel[1:0]                <= 2'b01; 
       // power_send_in                      <= 1'b0;
       power_slot_in                      <= 1'b0;
   end
end

//串口控制功放的间隙  
//对功放的控制
always@(posedge clk_20mhz ) begin
    //写入收发的状态 power_send_r
	if(rv_uart_vld && (rv_uart_data[63:32] == 32'h1f1a_1f01)) begin
		power_send_r		<=	rv_uart_data[0];
	end
    //写入时隙的状态
	else if(rv_uart_vld && (rv_uart_data[63:32] == 32'h1f1a_1f02)) begin
		power_slot_r		<=	rv_uart_data[0];
	end
    //写入功放开关的状态
	else if(rv_uart_vld && (rv_uart_data[63:32] == 32'h1f1a_1f08)) begin
		power_send_in		<=	rv_uart_data[0];
	end
	//控制功放时隙
    else if(rv_uart_vld && (rv_uart_data[63:32] == 32'h1f1a_1f03)) begin
        change_pa           <=  1'b1;
    end
    else if(rv_uart_vld && (rv_uart_data[63:32] == 32'h1f1a_1f04)) begin
        change_pa           <=  1'b0;
    end
	//
    else if(rv_uart_vld && (rv_uart_data[63:32] == 32'h1f1a_1f05)) begin
        change_carrier      <=  1'b1;
		carrier_r			<=	{rv_uart_data[4],rv_uart_data[0]};
    end
    else if(rv_uart_vld && (rv_uart_data[63:32] == 32'h1f1a_1f06)) begin
        change_carrier      <=  1'b0;
		carrier_r			<=	{rv_uart_data[4],rv_uart_data[0]};
    end
    else if(rv_uart_vld && (rv_uart_data[63:32] == 32'h1f1a_1f09)) begin
        tx_chan_sel_in[2:0] <=  rv_uart_data[2:0];
		tx_lo_en_in[3:0]	<=	rv_uart_data[7:4];
		tx_rf_select    	<=	rv_uart_data[8];
    end
    else begin
		change_carrier		<=	change_carrier;
        change_pa           <=  change_pa;
	end
end
													//power_send_r
assign  power_send_out  =  change_pa    ?    (tx_rx_switch_out ? 1'b1 : 1'b0)  : power_send_in  ;
// assign  power_send_out  =  change_pa    ?    tx_rx_switch_out   : power_send_in  ;
// assign  power_slot_out  =  change_pa    ?    power_slot_r  : power_slot_in  ;
assign  power_slot_out  =  power_slot_r    ;

assign  tx_chan_sel_o[2:0]  =   tx_rf_select ? tx_chan_sel_in[2:0] : tx_chan_sel[2:0];
assign  tx_lo_en_o[3:0]		=	tx_rf_select ? tx_lo_en_in[3:0]    : tx_lo_en[3:0];

assign	carrier_out		=	change_carrier ? tx_carrier_sel[1:0] : carrier_r[1:0];
//将单端输出信号转化为差分信号
   OBUFDS #(
      .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
      .SLEW("SLOW")           // Specify the output slew rate
   ) power_send_u0 (
      .O(power_send_p),     	// Diff_p output (connect directly to top-level port)
      .OB(power_send_n),   	// Diff_n output (connect directly to top-level port)
      .I(power_send_out)     // Buffer input 
   );
    
//将单端输出信号转化为差分信号
   OBUFDS #(
      .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
      .SLEW("SLOW")           // Specify the output slew rate
   ) power_slot_u0 (
      .O(power_slot_p),     	// Diff_p output (connect directly to top-level port)
      .OB(power_slot_n),   	// Diff_n output (connect directly to top-level port)
      .I(power_slot_out)     // Buffer input 
   );
    


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//// (6) single-ended to differential signal ////   

////(6-0)tx channel selection to differential signal	 
genvar n;

generate 
for (n=0;n<3;n=n+1)
begin: tx_chan_sel_dif	 
OBUFDS u0_obufds
     (
	 .I(tx_chan_sel_o[n]),
	 .O(tx_chan_sel_p[n]),
	 .OB(tx_chan_sel_n[n]) 
	 );	
end
endgenerate

////(6-1)tx local oscillator enable to differential signal	 
genvar j;

generate 
for (j=0;j<4;j=j+1)
begin: tx_lo_en_dif
OBUFDS u1_obufds
    (
	 .I(tx_lo_en_o[j]),
	 .O(tx_lo_en_p[j]),
	 .OB(tx_lo_en_n[j]) 
	 );	
end
endgenerate

////(6-2)tx carrier selection to differential signal	 
genvar m;

generate 
for (m=0;m<2;m=m+1)
begin: tx_carrier_sel_dif
OBUFDS u2_obufds
    (
	 .I(carrier_out[m]),  //tx_carrier_sel
	 .O(tx_carrier_sel_p[m]),
	 .OB(tx_carrier_sel_n[m]) 
	 );	
end
endgenerate

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//// (7) debug //// 
assign  debug_signal[31:0]                = slot_timer[31:0];
//assign  debug_signal[39:32]               = tx_feq_cfg[7:0];
assign  debug_signal[39:32]               = tx_feq_cfg_reg;

assign  debug_signal[40]                  = change_pa;
assign  debug_signal[41]                  = tx_rf_ctl;
assign  debug_signal[42]                  = power_send_out;
assign  debug_signal[43]                  = power_slot_out;
assign  debug_signal[44]                  = dl_data_dac_en;
assign  debug_signal[45]                  = tx_rx_switch_out;
assign  debug_signal[57:46]               = 12'd0;


assign  debug_signal[66:58]               = tx_rf_pulse_cnt[8:0];
assign  debug_signal[69:67]               = tx_chan_sel[2:0];
assign  debug_signal[73:70]               = tx_lo_en[3:0];
assign  debug_signal[75:74]               = tx_carrier_sel[1:0];

assign  debug_signal[127:76]              = 52'd0;



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
endmodule
