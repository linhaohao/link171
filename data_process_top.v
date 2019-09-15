//////////////////////////////////////////////////////////////////////////////////
// Company:         StarPoint
// Engineer:        GUO YAN 
// 
// Create Date:     10:33:58 01/19/2015 
// Module Name:     data_process_top 
// Project Name:    Link16 TX/RX process module;
// Target Devices:  FPGA - XC7K325T - FFG900; 
// Tool versions:   ISE14.6;
// Description:     TX module achieves data spread, scramble, modulation and hop-frequency; 
//                  Rx module achieves data spectrum move, correlation and demodulation; 
//
// Revision:        v1.0 - File Created
// Additional Comments: 
// 1 from tx_rd_en rising edge to tx_rd_en rising edge delay 370 clk(200M)
// 2 from net_tx_loc falling edge to tx_data_en rising edge delay 13us = 2600 clk(200M)
// 3 net_tx_loc[31:0] = SLOT_LENGTH(7.8125ms) - (370+2600) = 1559529
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps


module data_process_top(
//// clock/reset interface ////
input               clk_msk_in,                             // 50MHz
input               clk_25M_in,
input               logic_clk_in,                           // 200MHz logic clock
input               logic_rst_in,                           // reset

input               freq_out_select,
//// mif control ////
input               mif_dac_stat_en,
input               mif_dac_dds_sel,
input               mif_dac_msk_sel,
input [3:0]         mif_ad_da_loop_sel,
input [11:0]        mif_coarse_dec_th, 
input [3:0]         mif_dds50M_sel,
input [2:0]         mif_tx_fir_sel,


//// control singals //// 
input [31:0]        slot_timer,                             // slot time count
input [3:0]         net_work_mode,                          // work mode 0:normal 1:mcbsp0 loop 2:mcbsp1 loop 3:fpga loop 4: rf loop
input [31:0]        unsync_timer_in,
input               tx_slot_interrupt_in,

input [31:0]        net_slot_ntrindi,                       // '0' - JU; '1' - NTR
input [31:0]        net_slot_mode,                          // slot mode 0:rx slot 1:tx slot 2:RTT 3:loop(work with workmode 3/4)
input [31:0]        net_slot_clknum,
input [31:0]        net_tx_loc,                             // tx start location from dsp
input [31:0]        net_tx_pulse_num,                       // tx slot real length 
input [31:0]        net_rx_loc,                             // rx start location from dsp
input [31:0]        net_rx_pulse_num,                       // rx slot max length(rtt real), unknown real length
input               net_slot_switch,                        // rx and tx slot switch enable

input               mcbsp1_loop_int_in,                     //dsp loop rx interrupt

//// data signals ////
input [15:0]        adc_0_from,                          // 200Mchips/s
input [15:0]        adc_1_from, 
input [15:0]        adc_2_from, 
input [15:0]        adc_3_from, 

input [31:0]        mif_rx_adc_select,

input               data_adc_rd_en,

output[31:0]        data_to_dac,                           // tx data to RF
output              data_to_switch_en,                     //6.4&6.6 RF switcher control
output              data_to_dac_window,                    //
output[7:0]         data_to_rf_freq,                       // RF hop local oscillator and channel config

output              data_to_freq_chan_en,                  //ad9957 freq factor enable
output[31:0]        data_to_ad9957_freq,                   //ad9957 freq factor

//// dsp signals ////
input               ul_rd_en_in,                           //ul data buffer read enable
input[7:0]          ul_addr_rd_in,                         //ul data buffer read address
output[31:0]        ul_data_out,                           //ul data buffer read data
output[9:0]         ul_freq_pn_addr_out,                   //ul freq and pn ram pattern addr
output              ul_freq_pn_rd_out,                     //ul freq and pn ram pattern enable
output              ul_slot_interrupt,                
output              rx_data_dsp_interrupt,

//// tx module ////	  
output              dl_rd_en,                              //tx ccsk/pn ram rd
output[9:0]         dl_addr_out,                           //tx ccsk/pn ram addr
output              dl_freq_rd_en,                         //tx freq ram rd
output[9:0]         dl_freq_addr_out,                      //tx freq ram addr

input [31:0]        dl_pn_pat,                             //tx PN sequence
input [7:0]         dl_ccsk_pat,                           //tx data
input [7:0]         dl_freq_pat,                           //tx freq pattern

output              tx_end_out,                            //tx ending pulse
output              tx_rx_switch_out,                      //tx/rx contorl output

//////rttt
input               nrt_rtt_rsp_ng_in,                     //
output              tx_data_en_window_out,

//// rx module ////	
input [31:0]        ul_pn_pat,                            //rx pn sequence
input [7:0]         ul_freq_pat,                          //rx freq pattern

input [24:0]        mif_tx_dds0_cfg,
input [24:0]        mif_tx_dds1_cfg,
input               dualPuls_en,


//// sync result ////
// output              tr_syn_suc_out,
// output[31:0]        tr_offest_out,

output              coarse_status,    
output              tr_status,   
//------------------------------------------------2015/11/16 13:08:39
input [31:0]        mif_freq_convert,
input [31:0]        mif_rx_freq_tim,
input [31:0]        mif_freq_dds,
input               rx_freq_dds_end,

input               dsp_cfg_end_in,  
input               rx_chan_end_in,  
input               tx_chan_end_in,  

output   reg        freq_rd_en,
//// debug ////
output[23:0]        decccsk_dbg,
output[199:0]       debug_txpro_signal,
output[199:0]       debug_rxpro0_signal,
output[199:0]       debug_rxpro1_signal,
output[199:0]       debug_rxpro2_signal,
output[199:0]       debug_rxpro3_signal,
output[199:0]       debug_rxpro4_signal,
output[199:0]       debug_rxpro5_signal,
output[199:0]       debug_rxpro6_signal,
output[199:0]       debug_rxpro7_signal,
output[199:0]       debug_rxpro8_signal

    );


//////////////////////////////////////////////////////////////////////////////////
//// signals declaration //// 
//// TX signals ////
wire[31:0]          tx_ccsk_data;
wire[31:0]          tx_pn_scramble;
wire[39:0]          tx_dds_freq;
                                      
reg [31:0]          dl_pn_out1            = 32'd0;
wire[31:0]          dl_ccsk_out;
wire[39:0]          dl_freq_out;
wire[39:0]          old_dl_freq_out;

wire[31:0]          tx_data_dac;

wire[31:0]          tx_jitter;
wire[31:0]          tx_delay;

wire                tx_data_en_window_sel ;
wire                tx_data_en_window;

wire                tx_data_en;
wire                tx_freq_chan_en;

reg                 tx_rd_en            = 1'b0;

wire                msk_precode_reg_out;    
wire                msk_precode_reg_en_out;


//// RX signals ////
reg signed[31:0]    data_from_adc0 = 32'd0;
reg signed[31:0]    data_from_adc1 = 32'd0;
reg signed[31:0]    data_from_adc2 = 32'd0;
reg signed[31:0]    data_from_adc3 = 32'd0;
                    
wire[31:0]          rx_dds_phase; 
                    
wire[31:0]          rx_data_out; 
wire                rx_sync_state;
                    
wire                tr_cal_suc_out;
                    
wire[4:0]           ccsk_ram_addr;                       
wire[31:0]          data_ccsk_seq; 


//// Control signals ////
wire                tx_enable;
reg                 tx_rx_switch              = 1'b0;
reg                 tx_enable_start           = 1'b0;
reg                 tx_end_dly                = 1'b0;
reg [15:0]          tx_end_count              = 16'd0;
                                              
reg [1:0]           tx_end_dly_reg            = 2'b00;                        
reg                 tx_end_pulse              = 1'b0; 
                                              
reg [7:0]           tx_end_level_cnt          = 8'd0;
reg                 tx_end_level              = 1'b0;                        
                                              
reg [15:0]          tx_13us_count             = 16'd0;
reg [ 7:0]          tx_data_pulse             = 1'b0;
reg [ 9:0]          tx_addr_reg               = 10'd0;
                                              
reg                 tx_freq_rd_en             = 1'b0;
reg [9:0]           tx_freq_addr_reg          = 10'd0;
                    
wire [9:0]          freq_pn_addr_reg;
wire                freq_pn_rd_reg;
reg [9:0]           freq_pn_addr_ini          = 10'd32;       //ul freq and pn ram pattern initial addr
reg                 freq_pn_ini_en            = 1'b0;        //ul freq and pn ram pattern initial addr update enable 
                    
reg                 sync_freq_pn_rd_en        = 1'b0;
reg [9:0]           sync_freq_pn_addr         = 10'd0;
reg [1:0]           sync_freq_pn_rd_en_dly    = 2'd0;
reg                 rx_sync_enable            = 1'b0;
                    
wire[9:0]           rx_freq_ram_addr_out;
wire                rx_freq_ram_rd_out;
                    
reg [ 4:0]          ju_work_reg[31:0];
reg [ 1:0]          rf_tx_rx_ctl;
reg [29:0]          rf_power_ctl;
                    
reg [31:0]          link_sync_pn              = 32'hEB96C660;
reg [3:0]           link_sync_hop_chan        = 4'd0;
reg                 link_sync_pn_hop_en       = 1'b0;
                                              
reg [31:0]          tr_sync_code              = 32'd0;
                                              
reg [31:0]          unsync_timer              = 32'd1600000;

wire                ul_dsp_interrupt;
                    
//// others signals  ////
wire [127:0]        debug_tx_process;
                  
wire [199:0]        debug_rxdec_signal; 
wire [199:0]        debug_rxfsm_signal;
wire [127:0]        debug_rxccsk_signal;
wire [199:0]        debug_rxdds_signal;
wire [199:0]        debug_rxfir_signal;
wire [199:0]        debug_rxdds_signal2;

wire [15:0]         double_out_i;
wire [15:0]         double_out_q;
wire                double_out_vaild;

reg  [1:0]          source_loop_sel         = 2'd0;
reg [5:0]           rx_freq_cnt;

//----------------------2015/11/16 20:47:47
//reg [3:0]  tx_freq_rd_cnt;
reg [5:0]  rom_addr;
reg        rx_rom_rd_en;
//reg        rx_rom_rd;
reg [31:0] rx_rom_rd_tim;
reg        rx_rom_stat_en;
reg        tx_enable_start_dl;
reg [15:0] test_en_cnt;
reg       test_en;
reg       freq_en;   
wire [199:0] dds_debug_freq;
wire       rx_dds_rom_stat;
reg        sync_freq_pn_rd_en_dly2    = 1'b0;
reg [31:0] ul_pn_pat_reg;

reg [7:0] dl_freq_rd_cnt;


//////////////////////////////////////////////////////////////////////////////////
//// parameters define ////
parameter           COUNTER_13US        = 16'd2599;         // 13us/5ns
parameter           FREQ_CONVERT        = 16'd2399;         // 12us/5ns freq ahead ram data read 1us,that is ahead tx data 1.85us 
//parameter           SLOT_LENGTH         = 32'd1562499;       // 7.8125ms/5ns //slot length in a slot may vary
//parameter           TR_SYNC_CODE        = 32'h7CE90AEC;        //S0

//////////////////////////////////////////////////////////////////////////////////
//// (0) signals assigment ////
   assign  data_to_dac_window           = mif_dac_msk_sel ? double_out_vaild : tx_data_en_window_sel;
   assign  data_to_dac[31:0]            = mif_dac_msk_sel ? {double_out_q[15:0],double_out_i[15:0]} : tx_data_dac[31:0];
   assign  data_to_switch_en            = mif_dac_msk_sel ? double_out_vaild : tx_data_en;             
	
	
   assign  data_to_freq_chan_en         = tx_freq_chan_en;        
   assign  data_to_ad9957_freq[31:0]    = tx_dds_freq[31:0];
   assign  data_to_rf_freq[7:0]         = tx_dds_freq[39:32];
	
   assign  dl_addr_out[9:0]             = tx_addr_reg[9:0];
   assign  dl_rd_en                     = tx_rd_en;
   
   assign  dl_freq_rd_en                = tx_freq_rd_en;
   assign  dl_freq_addr_out[9:0]        = tx_freq_addr_reg[9:0];
	
   assign  ul_freq_pn_addr_out[9:0]     = freq_pn_addr_reg[9:0]; 
   assign  ul_freq_pn_rd_out            = freq_pn_rd_reg;
   
   assign  ul_data_out[31:0]            = rx_data_out[31:0];
                                        
   assign  tx_enable                    = tx_enable_start || tx_end_dly;
   assign  tx_end_out                   = tx_end_pulse;
   assign  tx_rx_switch_out             = tx_rx_switch;
   
   assign  tx_pn_scramble[31:0]         = dl_pn_pat[31:0];
   assign  tx_ccsk_data[31:0]           = dl_ccsk_out[31:0];
   assign  tx_dds_freq[39:0]            = freq_out_select ? old_dl_freq_out[39:0] : dl_freq_out[39:0];  //align tx_data_pulse[0] 

   assign  rx_data_dsp_interrupt        = (net_work_mode[3:0] == 4'd2) ? mcbsp1_loop_int_in : ul_dsp_interrupt;   
     
   assign  tx_data_en_window_sel        = nrt_rtt_rsp_ng_in ? 1'b0 : tx_data_en_window;
   assign  tx_data_en_window_out        = tx_data_en_window;
   
//////////////////////////////////////////////////////////////////////////////////
//// (1) source selcetion  ////  
always@(posedge logic_clk_in)
begin
    if (logic_rst_in)   
      freq_rd_en <= 1'd0;
    else if(dl_freq_rd_cnt == 8'd39)
      freq_rd_en <= 1'd0;
    else if(tx_freq_rd_en)  
      freq_rd_en <= 1'd1;
    else
      freq_rd_en <= freq_rd_en;
end
//----------------------------------------------  
always@(posedge logic_clk_in)
begin
    if (logic_rst_in)   
      dl_freq_rd_cnt <= 8'd0;
    else if(freq_rd_en)  
      dl_freq_rd_cnt <= dl_freq_rd_cnt + 1'd1;
    else
      dl_freq_rd_cnt <= 8'd0;
end   
//////////////////////////////////////////////////////////////////////////////////
//// (1) source selcetion  ////  
always@(posedge logic_clk_in)
begin
    if (logic_rst_in)   begin
	  source_loop_sel[1:0]                    <= 2'b00;
	end
	else if(net_work_mode[1:0] != 2'b00)begin  //1/2/3
	  source_loop_sel[1:0]                    <= 2'b11;
	end
	else begin  //normal0 and rf loop4 = da out ,ad in
	  source_loop_sel[1:0]                    <= 2'b00;
	end
end

//////////////////////////////////////////////////////////////////////////////////
//// (2) Tx logic module  ////
 tx_process_module   u1_tx_module
    (
	//clock&reset signals
	 .clk_msk_in(clk_msk_in),                               // 50MHz msk modulation 
	 .logic_clk_in(logic_clk_in),                           // 200MHz logic clock
	 .logic_rst_in(!tx_enable),                             // 7.8125ms Sync reset
	
	//control signals 
	 .net_slot_mode(net_slot_mode[1:0]),                    // Tx data source test control
	 .tx_end_level(tx_end_level),                           // 0.06us level
	 .mif_tx_fir_sel(mif_tx_fir_sel[2:0]),
	
	//data signals
	 .tx_data_pulse(tx_data_pulse[0]),                      // 13us symbol pulse
	 .pn_scramble_code(tx_pn_scramble[31:0]),               // 32bits Scramble
	 .tx_ccsk_data(tx_ccsk_data[31:0]),                     // 32bits header+data ccsk 
	
	 .tx_data_en_window_out(tx_data_en_window),
	 .tx_data_en(tx_data_en),	                           // data write enable
	 .tx_data_out(tx_data_dac[31:0]),                       // data to DAC
	 .tx_freq_chan_en(tx_freq_chan_en),
	 
     .msk_precode_reg_out(msk_precode_reg_out),     
     .msk_precode_reg_en_out(msk_precode_reg_en_out),
	 		
	//debug signals
	 .debug_signal(debug_tx_process[127:0])	 
	
	 );
	
tx_process_cosine_module   u_tx_process_cosine_module
   (
	// clock&reset signals
	.clk_msk_in(clk_25M_in),    	// 50MHz msk modulation 
	.logic_rst_in(logic_rst_in),
	
	.mif_dac_stat_en(mif_dac_stat_en),
	.mif_dac_dds_sel(mif_dac_dds_sel),
	.double_out_i(double_out_i[15:0]),
	.double_out_q(double_out_q[15:0]),
	.double_out_vaild(double_out_vaild),

    .debug_signal()		
	
	);
	

	
	
//////////////////////////////////////////////////////////////////////////////////
//// (3) tx slot control logic ////
//// (3-0) tx Slot read start logic ////
always@(posedge logic_clk_in)
begin
    if (logic_rst_in)   begin
	  tx_enable_start                    <= 1'b0;
	end
	else if((net_work_mode[3:0] == 4'd1) || (net_work_mode[3:0] == 4'd2))begin //mcbsp loopback
	  tx_enable_start                    <= 1'b0;
	end
	else if(net_slot_mode[1:0] != 2'd0) begin
	   // if (slot_timer[31:0] == (net_slot_clknum[31:0] +(tx_jitter[31:0] - tx_delay[31:0])) mod net_slot_clknum[31:0]  begin  //consider tx process delay and delay>jitter
	    if (slot_timer[31:0] == net_tx_loc[31:0])   begin
	        tx_enable_start                <= 1'b1;	
	    end
	    else if (tx_rd_en &&((tx_addr_reg[9:0] == {1'b0,(net_tx_pulse_num[8:0] - 1'b1)}) || 
	             (tx_addr_reg[9:0] == (net_tx_pulse_num[8:0] + 9'd511)))) begin // RAM full //last tx code can't be tramsmitted
	        tx_enable_start                <= 1'b0;	
	    end
	end
end

always@(posedge logic_clk_in)
begin
    if (logic_rst_in)   begin
	  tx_end_dly                         <= 1'b0;
	end
	else if(net_slot_mode[1:0] != 2'd0) begin //rx slot, tx process stop working
	  	if (tx_rd_en &&((tx_addr_reg[9:0] == {1'b0,(net_tx_pulse_num[8:0] - 1'b1)}) || 
	           (tx_addr_reg[9:0] == (net_tx_pulse_num[8:0] + 9'd511)))) begin 
	      tx_end_dly                     <= 1'b1;	
	    end
	    //else if(tx_end_count[31:0] == (net_slot_clknum[31:0] - net_tx_loc[31:0] - 2'd2)) begin //keep enough time for last code //370(delay)+2600(13us)=2970 clk(200M) from rd_en to 6.6us end
		else if(tx_end_count[15:0] == COUNTER_13US[15:0]) begin //keep enough time for last code //2600(13us)clk(200M) prevent msk_precode_reg_en reoperated and 6.6us could occupy ilde
		  tx_end_dly                     <= 1'b0;	
	    end
	end
end

// always@(posedge logic_clk_in)
// begin
   // if (logic_rst_in)   begin
	  // tx_end_count[31:0]                <= 32'd0;
	// end
	// else if(tx_end_count[31:0] == (net_slot_clknum[31:0] - net_tx_loc[31:0] - 2'd2)) begin // 13us
	  // tx_end_count[31:0]                <= 32'd0;
	// end
	// else if(tx_end_dly) begin
	  // tx_end_count[31:0]                <= tx_end_count[31:0] + 1'b1;
	// end
// end

always@(posedge logic_clk_in)
begin
   if (logic_rst_in)   begin
	  tx_end_count[15:0]                <= 16'd0;
	end
	else if(tx_end_count[15:0] == COUNTER_13US[15:0]) begin // 13us
	  tx_end_count[15:0]                <= 16'd0;
	end
	else if(tx_end_dly) begin
	  tx_end_count[15:0]                <= tx_end_count[15:0] + 1'b1;
	end
end

//// (3-1) tx Slot read start logic ////
always@(posedge logic_clk_in)
begin
   if (!tx_enable_start)   begin
      tx_13us_count[15:0]                <= 16'd0;
	  tx_rd_en                           <= 1'b0;
	end
	else if (tx_13us_count[15:0] == COUNTER_13US[15:0])   begin // 13us
	  tx_13us_count[15:0]                <= 16'd0;
	  tx_rd_en                           <= 1'b1;
	end
	else   begin
	  tx_13us_count[15:0]                <= tx_13us_count[15:0] + 1'b1;
	  tx_rd_en                           <= 1'b0;
	end
end

always@(posedge logic_clk_in)
begin
    if (logic_rst_in)   begin
	  tx_addr_reg[9:0]                   <= 10'd0;    //power reset,not tx_enable_start reset
	end
    else if (tx_rd_en && (tx_addr_reg[9:0] == {1'b0,(net_tx_pulse_num[8:0] - 1'b1)})) begin
	  tx_addr_reg[9:0]                   <= 10'd512;   //tx ccsk ram addr                                 
	end 
    else if(tx_rd_en && (tx_addr_reg[9:0] == (net_tx_pulse_num[8:0] + 9'd511))) begin
	  tx_addr_reg[9:0]                   <= 10'd0;    //no sync reset for ping-pang
    end	
    else if (tx_rd_en)   begin // 13us        
	  tx_addr_reg[9:0]                   <= tx_addr_reg[9:0] + 1'b1;
	end                                  
	else begin                           
	  tx_addr_reg[9:0]                   <= tx_addr_reg[9:0];
	end
end


always@(posedge logic_clk_in)
begin
    if (!tx_enable_start)  begin
	  	tx_data_pulse[7:0]                <= 8'd0;
	end
	else begin
	  	tx_data_pulse[7:0]                <= {tx_data_pulse[6:0],tx_rd_en}; //delay 8clk, every occupy 1 clk
	end
end


//// (3-2) freq factor read logic //// tx_link_dly = 0.8us< rf hop timing ctl = 1us
                                  ////freq ahead ram data read 1us,that is ahead tx data 1.8us 
always@(posedge logic_clk_in)
begin
   if (!tx_enable_start)   begin
	  tx_freq_rd_en                           <= 1'b0;
	end
	else if (tx_13us_count[15:0] == mif_freq_convert[15:0])   begin 
	  tx_freq_rd_en                           <= 1'b1;
	end
	else   begin
	  tx_freq_rd_en                           <= 1'b0;
	end
end

always@(posedge logic_clk_in)
begin
    if (logic_rst_in)   begin
	  tx_freq_addr_reg[9:0]                   <= 10'd0;    //power reset,not tx_enable_start reset
	end
    else if (tx_freq_rd_en && (tx_freq_addr_reg[9:0] == {1'b0,(net_tx_pulse_num[8:0] - 1'b1)})) begin
	  tx_freq_addr_reg[9:0]                   <= 10'd512;   //tx ccsk ram addr                                 
	end 
    else if(tx_freq_rd_en && (tx_freq_addr_reg[9:0] == (net_tx_pulse_num[8:0] + 9'd511))) begin
	  tx_freq_addr_reg[9:0]                   <= 10'd0;    //no sync reset for ping-pang
    end	
    else if (tx_freq_rd_en)   begin // 13us        
	  tx_freq_addr_reg[9:0]                   <= tx_freq_addr_reg[9:0] + 1'b1;
	end                                  
	else begin                           
	  tx_freq_addr_reg[9:0]                   <= tx_freq_addr_reg[9:0];
	end
end


//// (3-3) tx pattern index logic module ////
ccsk_rom U_tx_ccsk_rom(
       .a(dl_ccsk_pat[5:0]),  //depth = 36(32 tr+data, 4 coarse_syn)
       .spo(dl_ccsk_out[31:0])
);

//// ////
tx_freq_cfg_rom U_tx_freq_cfg_rom(            
      .clka   (logic_clk_in),
      .addra(dl_freq_pat[5:0]),  //depth = 51
      .douta(dl_freq_out[39:0])
);

old_tx_freq_cfg_rom U_old_tx_freq_cfg_rom (          
      .clka   (logic_clk_in),
      .addra(dl_freq_pat[5:0]),  //depth = 51
      .douta(old_dl_freq_out[39:0])
);

////(3-4)source selection for loopback ////
 always@(posedge logic_clk_in)
 begin
   if (logic_rst_in)   begin
      data_from_adc0[31:0]               <= 32'd0;
	  data_from_adc1[31:0]               <= 32'd0;
	  data_from_adc2[31:0]               <= 32'd0;
	  data_from_adc3[31:0]               <= 32'd0;
	end
	else if (source_loop_sel[1:0] == 2'b11)   begin  //FPGA LOOP
	  data_from_adc0[31:0]              <= tx_data_dac[31:0];
	  data_from_adc1[31:0]              <= tx_data_dac[31:0];
	  data_from_adc2[31:0]              <= tx_data_dac[31:0];
	  data_from_adc3[31:0]              <= tx_data_dac[31:0];
	end  
	else if(mif_ad_da_loop_sel[3:0] == 4'b0001)begin   //BASE CONNECT                     	  
	  data_from_adc0[31:0]              <= {16'd0,adc_0_from[15:0]}; 
	  data_from_adc1[31:0]              <= {16'd0,adc_0_from[15:0]}; 
	  data_from_adc2[31:0]              <= {16'd0,adc_0_from[15:0]}; 
	  data_from_adc3[31:0]              <= {16'd0,adc_0_from[15:0]}; 	  
	end		                       
	else   begin                        	  
	  data_from_adc0[31:0]              <= {16'd0,adc_0_from[15:0]};  
	  data_from_adc1[31:0]              <= {16'd0,adc_1_from[15:0]};  
	  data_from_adc2[31:0]              <= {16'd0,adc_2_from[15:0]};  
	  data_from_adc3[31:0]              <= {16'd0,adc_3_from[15:0]};  	  
	end
end

////(3-5)tx ending pulse output for tx rf timing ctl 
always@(posedge logic_clk_in)
begin
   if (logic_rst_in)   begin
	  tx_end_dly_reg[1:0]               <= 1'b0;
	end                                 
	else  begin                         
	  tx_end_dly_reg[1:0]               <= {tx_end_dly_reg[0],tx_end_dly};
	end
end

always@(posedge logic_clk_in)
begin
   if (logic_rst_in)   begin
	  tx_end_pulse                      <= 1'b0;
	end                                 
	else  if (tx_end_dly_reg[1:0] == 2'b10)begin                        
	  tx_end_pulse                      <= 1'b1;
	end
	else begin
	  tx_end_pulse                      <= 1'b0;  //one 200M clock
	end
end

////(3-6)tx ending pulse output for da enabel window ending
always@(posedge logic_clk_in)
begin
   if (logic_rst_in)   begin
	  tx_end_level_cnt[7:0]             <= 8'd0;
	end  
	else if(tx_end_level_cnt[7:0] == 8'd19)begin
	  tx_end_level_cnt[7:0]             <= 8'd0;  //5/50M=20/200M
	end	
	else if(tx_end_level)begin                        
	  tx_end_level_cnt[7:0]             <= tx_end_level_cnt[7:0] + 1'b1;
	end
end

always@(posedge logic_clk_in)
begin
   if (logic_rst_in)   begin
	  tx_end_level                      <= 1'b0;
	end  
	else if(tx_end_level_cnt[7:0] == 8'd19)begin
	  tx_end_level                      <= 1'b0;  //5/50M=20/200M
	end	
	else if(tx_end_pulse)begin                        
	  tx_end_level                      <= 1'b1;
	end
end

//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//// (4) Rx logic module ////
rx_process_module   u2_rx_module
   (
	// clock&reset signals
	.logic_clk_in(logic_clk_in),                             // 200MHz logic clock
	.logic_rst_in(logic_rst_in),                             // reset	
	
	// control signals 
	.mif_dds50M_sel(mif_dds50M_sel[3:0]),
	.mif_dec_th_in(mif_coarse_dec_th[11:0]),
	.source_loop_sel_in(source_loop_sel[1:0]),
	
	.net_slot_mode(net_slot_mode[1:0]),
	.slot_timer(slot_timer[31:0]),
	.unsync_timer(unsync_timer[31:0]),
	.tx_slot_interrupt(tx_slot_interrupt_in),
	
	// data signals
    .data_from_adc0(data_from_adc0[31:0]), 	                // data from ADC9680
    .data_from_adc1(data_from_adc1[31:0]),
	.data_from_adc2(data_from_adc2[31:0]),
	.data_from_adc3(data_from_adc3[31:0]),
	
	.rx_rd_en_in(ul_rd_en_in),
	.rx_addr_rd_in(ul_addr_rd_in[7:0]),
	.rx_data_out(rx_data_out[31:0]),                             // data to dsp
	.rx_slot_interrupt_out(ul_slot_interrupt),
	.rx_dsp_interrupt_out(ul_dsp_interrupt),
	
	//syn offset 
	.tr_cal_suc_out(tr_cal_suc_out),
	.rx_freq_ram_addr_out(rx_freq_ram_addr_out[9:0]),
	.rx_freq_ram_rd_out(rx_freq_ram_rd_out),
    .rx_freq_pn_addr_ini_in(freq_pn_addr_ini[9:0]),   
    .rx_freq_pn_ini_en_in(freq_pn_ini_en),
    
    .coarse_status(coarse_status),    
    .tr_status(tr_status),   
	  
	 //ccsk disspread
    .ccsk_ram_addr(ccsk_ram_addr[4:0]),                       
    .data_ccsk_seq(data_ccsk_seq[31:0]), 

	// CVs signals
	.rx_slot_length(net_rx_pulse_num[8:0]),
	
	.rx_dds_phase(rx_dds_phase[31:0]),                    // Rx dds frequency control word
	
	.slot_tr_s0(tr_sync_code[31:0]),                      // 8*1 S0(TR)
	.pn_scramble_code(ul_pn_pat[31:0]),                    // RX TDD mode
		
	.link_sync_pn(link_sync_pn[31:0]),
    .link_sync_hop_chan(link_sync_hop_chan[3:0]),
    .link_sync_pn_hop_en(link_sync_pn_hop_en),
	
	.mif_freq_dds      (mif_freq_dds),
	.freq_en           (freq_en),  
	.dualPuls_en       (dualPuls_en),
	.rx_dds_rom_stat    (rx_dds_rom_stat),
	
	// debug signals
	.decccsk_dbg   (decccsk_dbg),
    .debug_signal0(debug_rxdec_signal[199:0]),  
    .debug_signal1(debug_rxfsm_signal[199:0]),  
    .debug_signal2(debug_rxccsk_signal[127:0]),
	.debug_signal3(debug_rxdds_signal[199:0]),
    .debug_signal4(debug_rxfir_signal[199:0]),
    .debug_signal5(debug_rxdds_signal2[199:0]),
    .debug_signal6(dds_debug_freq[199:0])
	
	
	);

//////////////////////////////////////////////////////////////////////////////////
//// (5) rx slot control logic ////	
//// (5-0) rx pattern index logic module ////	
assign freq_pn_addr_reg[9:0] = sync_freq_pn_rd_en ? sync_freq_pn_addr[9:0] : rx_freq_ram_addr_out[9:0]; //coarse sync and other sync

assign freq_pn_rd_reg        = sync_freq_pn_rd_en || rx_freq_ram_rd_out;

//// (5-1) The first four coarse sync index logic ////	
always@(posedge logic_clk_in)
begin
   if (logic_rst_in)  begin 
      sync_freq_pn_addr[9:0]                  <= 10'd0; 
	  freq_pn_addr_ini[9:0]                   <= 10'd32; 
  end
  else if(sync_freq_pn_addr[9:0] == 10'd31) begin
	 sync_freq_pn_addr[9:0]                   <= 10'd512;
	 freq_pn_addr_ini[9:0]                    <= 10'd32;                     
  end
  else if(sync_freq_pn_addr[9:0] == 10'd543) begin
	 sync_freq_pn_addr[9:0]                   <= 10'd0; 
	 freq_pn_addr_ini[9:0]                    <= 10'd544; 
  end                                         
  else if(sync_freq_pn_rd_en) begin    //read no.0~31 coarse rx pn/freq       
     sync_freq_pn_addr[9:0]                   <= sync_freq_pn_addr[9:0] + 1'b1;
	 freq_pn_addr_ini[9:0]                    <= freq_pn_addr_ini[9:0]; 
  end
end	

always@(posedge logic_clk_in)
begin
  if (logic_rst_in)  begin
      sync_freq_pn_rd_en                      <= 1'b0;
  end
  else if((sync_freq_pn_addr[9:0] == 10'd31) || (sync_freq_pn_addr[9:0] == 10'd543)) begin
     sync_freq_pn_rd_en                       <= 1'b0;
  end                                         
  else if((net_slot_mode[1:0] != 2'b01) && net_slot_switch)begin  //保证了非接收时隙，读取的同步字符不正确则同步不成功，间接保证接收链路不工作
     sync_freq_pn_rd_en                       <= 1'b1;  //at start point every rx/rtt slot 
  end
end

always@(posedge logic_clk_in)
begin
  if (logic_rst_in)  begin                   
      sync_freq_pn_rd_en_dly[1:0]             <= 2'b00;
  end                                      
  else begin                               
      sync_freq_pn_rd_en_dly[1:0]             <= {sync_freq_pn_rd_en_dly[0],sync_freq_pn_rd_en};
  end
end

always@(posedge logic_clk_in)
begin
  if (logic_rst_in)  begin                   
      freq_pn_ini_en                          <= 1'b0;
  end                                      
  else if(sync_freq_pn_rd_en_dly[1:0] == 2'b10)begin                            
      freq_pn_ini_en                          <= 1'b1;
  end
  else begin
      freq_pn_ini_en                          <= 1'b0;
  end
end	
	

always@(posedge logic_clk_in)
begin
  if (logic_rst_in)  begin                   
      ul_pn_pat_reg[31:0]                  <= 32'd0;
  end                                      
  else begin                               
      ul_pn_pat_reg[31:0]                  <= ul_pn_pat[31:0];
  end
end

always@(posedge logic_clk_in)
begin
  if (logic_rst_in)  begin                   
      link_sync_pn_hop_en                  <= 1'b0;
  end                                      
  else begin                               
      link_sync_pn_hop_en                  <= sync_freq_pn_rd_en_dly[1];//sync_freq_pn_rd_en_dly2;     
  end
end	

always@(posedge logic_clk_in)
begin
  if (logic_rst_in)  begin
       link_sync_pn[31:0]                  <= 32'hEB96C660; //forbiding 32'd0/all f,for 0/f could syn with data 0/f
  end
  else if(sync_freq_pn_rd_en_dly[1]) begin
       link_sync_pn[31:0]                  <= ul_pn_pat_reg[31:0];     
  end
end	

////syn hop channel selection ////
always@(posedge logic_clk_in)
begin
  if (logic_rst_in)  begin
       link_sync_hop_chan[3:0]             <= 4'd0; 
  end
    else if(sync_freq_pn_rd_en_dly[1]) begin
       link_sync_hop_chan[3:0]             <= rx_dds_phase[31:28];
  end
end	

//// (5-2) Tr sync code logic ////	
always@(posedge logic_clk_in)
begin
  if (logic_rst_in)  begin
      tr_sync_code[31:0]                   <= 32'd0;
  end                                         
  else if((rx_freq_ram_addr_out[9:0] == 10'd32) || (rx_freq_ram_addr_out[9:0] == 10'd544))begin  //NO.32 Pulse
      tr_sync_code[31:0]                   <= ul_pn_pat[31:0];  
  end
  else if(net_slot_switch)begin
      tr_sync_code[31:0]                   <= 32'd0; 
  end
end	

//// (5-2) rx work enable logic ////
//// unsync timer logic////
always@(posedge logic_clk_in)
begin
    if(logic_rst_in) begin
	   unsync_timer[31:0]           <= 32'd1600000;	 //32'd855000;	 //initial 
    end
    else if(tr_cal_suc_out)begin
	   unsync_timer[31:0]           <= 32'd1600000;	 //slot_timer max 32'd1562499
    end
	else if(slot_timer[31:0] == net_slot_clknum[31:0])begin 
	   unsync_timer[31:0]           <= unsync_timer_in[31:0];//32'd855000; //4.275ms/5ns = 855000(NTR RTT rx)
	end
end

//// (5-3) rx pattern index logic module ////
//synthesis attribute box_type <U_rx_ccsk_rom> "black_box" 
ccsk_rom U_rx_ccsk_rom(
    .a({1'b0,ccsk_ram_addr[4:0]}),  //depth = 36(32 tr+data, 4 coarse_syn)
    .spo(data_ccsk_seq[31:0])       //rom output no register
);

rx_freq_cfg_rom U_rx_freq_cfg_rom(
    .a(rom_addr[5:0]),
    .spo(rx_dds_phase[31:0])
);
//---------------------------------------------------------2015/12/15 19:18:02
//---------------------------------------------------------
always@(posedge logic_clk_in)
begin
    if(logic_rst_in)
       rom_addr <= 6'd0;
    else if(sync_freq_pn_rd_en_dly[0] || rx_rom_stat_en)
       rom_addr <= ul_freq_pat[5:0];              
    else
       rom_addr <= rom_addr;
end
////---------------------------------      rx_dds_rom_stat    rx_freq_dds_end
always@(posedge logic_clk_in)
begin	
   if(logic_rst_in)     
      rx_rom_stat_en <= 1'd0; 
  else if(rx_dds_rom_stat)
  	     rx_rom_stat_en <= 1'd1;
  else if(rx_freq_dds_end)
       rx_rom_stat_en <= 1'd0;  	  	  	
   else 
     rx_rom_stat_en <= rx_rom_stat_en;
end
////----------------------------------------------

//////////////////////////////////////////////////////////////////////////////////
//// (6) tx/rx control switch for PA ////
always@(posedge logic_clk_in)
begin
    if(logic_rst_in) begin
	   tx_rx_switch           <= 1'b0;	 
    end
    else begin
	   tx_rx_switch           <= tx_enable;	//ahead logic data 13.8us(2760clk),delay last logic data 6.6us 
    end
end

//////////////////////////////////////////////////////////////////////////////////
//// (7) debug signals ////
//////tx slot 
assign  debug_txpro_signal[127:0]             = debug_tx_process[127:0];

assign  debug_txpro_signal[128]               = tx_enable;
assign  debug_txpro_signal[129]               = tx_enable_start;
assign  debug_txpro_signal[131:130]           = net_slot_mode[1:0];
assign  debug_txpro_signal[132]               = tx_rd_en;
assign  debug_txpro_signal[142:133]           = tx_addr_reg[9:0];
assign  debug_txpro_signal[143]               = nrt_rtt_rsp_ng_in;//tx_end_dly;
assign  debug_txpro_signal[144]               = tx_data_en_window_sel;//tx_end_pulse;
assign  debug_txpro_signal[176:145]           = slot_timer[31:0];
assign  debug_txpro_signal[177]               = tx_data_en;
assign  debug_txpro_signal[193:178]           = tx_data_dac[15:0];
assign  debug_txpro_signal[197:194]           = net_work_mode[3:0];

assign  debug_txpro_signal[198]               = tx_data_en_window;
assign  debug_txpro_signal[199]               = 1'b0;


//////rx slot 
///(0) rx sync
// assign  debug_rxpro0_signal[127:0]            = debug_rxdec_signal[127:0];
// assign  debug_rxpro0_signal[128]              = sync_freq_pn_rd_en;
// assign  debug_rxpro0_signal[138:129]          = sync_freq_pn_addr[9:0];
// assign  debug_rxpro0_signal[148:139]          = freq_pn_addr_reg[9:0];
// assign  debug_rxpro0_signal[149]              = link_sync_en;
// assign  debug_rxpro0_signal[151:150]          = link_sync_cnt[1:0];
// assign  debug_rxpro0_signal[183:152]          = link0_sync_pn[31:0]; //unsync_timer[31:0];    
// assign  debug_rxpro0_signal[184]              = msk_precode_out;  
// assign  debug_rxpro0_signal[185]              = msk_precode_en_out;    
// assign  debug_rxpro0_signal[188:186]          = mif_ad_da_loop_sel[2:0];    
// assign  debug_rxpro0_signal[199:189]          = 11'd0;

//assign  debug_rxpro0_signal[174:0]            = debug_rxdec_signal[174:0];

// assign  debug_rxpro0_signal[127:0]            = debug_rxdec_signal[127:0];
// assign  debug_rxpro0_signal[137:128]          = rx_freq_ram_addr_out[9:0];
// assign  debug_rxpro0_signal[147:138]          = sync_freq_pn_addr[9:0];
// assign  debug_rxpro0_signal[148]              = dsp_cfg_end_in; 
// assign  debug_rxpro0_signal[149]              = rx_chan_end_in; 
// assign  debug_rxpro0_signal[150]              = tx_chan_end_in; 
// assign  debug_rxpro0_signal[151]              = rx_freq_ram_rd_out;
// assign  debug_rxpro0_signal[152]              = freq_pn_rd_reg;
// assign  debug_rxpro0_signal[162:153]          = freq_pn_addr_reg[9:0];
// assign  debug_rxpro0_signal[174:163]          = 12'd0;

////assign  debug_rxpro0_signal[182:175]          = link0_sync_pn[7:0];    
////assign  debug_rxpro0_signal[190:183]          = link1_sync_pn[7:0];  
//////assign  debug_rxpro0_signal[198:191]          = link2_sync_pn[7:0];  
////assign  debug_rxpro0_signal[191]              = sync_freq_pn_rd_en; 
////assign  debug_rxpro0_signal[192]              = link_sync_en;
////assign  debug_rxpro0_signal[194:193]          = link_sync_cnt[1:0];
////assign  debug_rxpro0_signal[195]              = net_slot_switch;
////assign  debug_rxpro0_signal[197:196]          = source_loop_sel[1:0]; //add new
////assign  debug_rxpro0_signal[198]              = mif_ad_da_loop_sel[2];
////assign  debug_rxpro0_signal[199]              = 1'b0;

//assign  debug_rxpro0_signal[190:0]           = debug_rxdec_signal[190:0];
assign  debug_rxpro0_signal[158:0]           = debug_rxdec_signal[158:0];
assign  debug_rxpro0_signal[190:159]         = debug_tx_process[46:15];
assign  debug_rxpro0_signal[191]             = sync_freq_pn_rd_en; 
assign  debug_rxpro0_signal[192]             = link_sync_pn_hop_en;
assign  debug_rxpro0_signal[193]             = net_slot_switch;
assign  debug_rxpro0_signal[194]             = msk_precode_reg_out;
assign  debug_rxpro0_signal[195]             = msk_precode_reg_en_out;
assign  debug_rxpro0_signal[196]             = tx_enable;
assign  debug_rxpro0_signal[198:197]         = debug_rxfsm_signal[2:1];
assign  debug_rxpro0_signal[199]             = 1'b0;


///(1) rx fsm
assign  debug_rxpro1_signal[96:0]            = debug_rxfsm_signal[96:0];
assign  debug_rxpro1_signal[128:97]          = debug_tx_process[46:15];//link_sync_pn[31:0]; 
assign  debug_rxpro1_signal[129]             = sync_freq_pn_rd_en; 
assign  debug_rxpro1_signal[130]             = link_sync_pn_hop_en;
assign  debug_rxpro1_signal[132:131]         = net_slot_mode[1:0];
assign  debug_rxpro1_signal[133]             = net_slot_switch;
assign  debug_rxpro1_signal[165:134]         = debug_rxdec_signal[127:96];

assign  debug_rxpro1_signal[175:166]         = freq_pn_addr_reg[9:0];//sync_freq_pn_addr[9:0];
assign  debug_rxpro1_signal[181:176]         = dl_freq_pat[5:0];//freq_pn_addr_ini[9:0];//18'd0;
assign  debug_rxpro1_signal[187:182]         = ul_freq_pat[5:0];//18'd0;
assign  debug_rxpro1_signal[188]             = rx_rom_stat_en;
assign  debug_rxpro1_signal[192:189]         = link_sync_hop_chan[3:0];
assign  debug_rxpro1_signal[193]             = freq_pn_ini_en;

assign  debug_rxpro1_signal[194]             = msk_precode_reg_out;
assign  debug_rxpro1_signal[195]             = msk_precode_reg_en_out;
assign  debug_rxpro1_signal[197:196]         = sync_freq_pn_rd_en_dly[1:0];
assign  debug_rxpro1_signal[199:198]         = 2'd0;

///(2) rx deccsk
assign  debug_rxpro2_signal[127:0]            = debug_rxccsk_signal[127:0];
assign  debug_rxpro2_signal[159:128]          = slot_timer[31:0];
assign  debug_rxpro2_signal[161:160]          = net_slot_mode[1:0];
assign  debug_rxpro2_signal[165:162]          = mif_ad_da_loop_sel[3:0];
assign  debug_rxpro2_signal[181:166]          = data_from_adc0[15:0];
assign  debug_rxpro2_signal[197:182]          = data_from_adc1[15:0]; 
assign  debug_rxpro2_signal[199:198]          = 2'd0;                                           
												
///(3) rx dds
//assign  debug_rxpro3_signal[199:0]            = debug_rxdds_signal[199:0];
assign  debug_rxpro3_signal[107:0]              = debug_rxdds_signal[107:0];
//assign  debug_rxpro3_signal[123:108]            = data_from_adc[15:0];       
assign  debug_rxpro3_signal[123:108]            = adc_0_from[15:0];   
assign  debug_rxpro3_signal[199:124]            = 76'd0;   

///(4) rx fir
assign  debug_rxpro4_signal[199:0]            = debug_rxfir_signal[199:0];

///(5) syn combine
assign  debug_rxpro8_signal[199:0]            = {41'd0,debug_rxfsm_signal[94:0],debug_rxdec_signal[176:128],debug_rxdec_signal[14:0]};
///(5) rx test
assign  debug_rxpro5_signal[31:0]              = rx_dds_phase;
assign  debug_rxpro5_signal[63:32]             = tx_dds_freq;
assign  debug_rxpro5_signal[69:64]             = rom_addr;
//assign  debug_rxpro5_signal[70]                = rx_rom_rd;
assign  debug_rxpro5_signal[71]                = tx_freq_rd_en;
assign  debug_rxpro5_signal[72]                = data_to_switch_en;
assign  debug_rxpro5_signal[78:73]             = dl_freq_pat[5:0];
assign  debug_rxpro5_signal[79]                = rx_rom_stat_en;
assign  debug_rxpro5_signal[111:80]            = data_from_adc0;    
assign  debug_rxpro5_signal[127:112]           = adc_0_from; 
assign  debug_rxpro5_signal[128]               = rx_dds_rom_stat;    
assign  debug_rxpro5_signal[129]               = rx_freq_dds_end;
assign  debug_rxpro5_signal[135:130]           = ul_freq_pat[5:0];
assign  debug_rxpro5_signal[136]               = sync_freq_pn_rd_en_dly[0];
assign  debug_rxpro5_signal[140:137]           = link_sync_hop_chan[3:0];

assign  debug_rxpro5_signal[199:141]           = 73'd0;




 

assign  debug_rxpro6_signal[199:0]            = debug_rxdds_signal2; 




assign  debug_rxpro7_signal[143:0]            = dds_debug_freq[143:0];
//assign  debug_rxpro7_signal[149:144]          = rom_addr[5:0];
assign  debug_rxpro7_signal[147:144]          = link_sync_hop_chan[3:0];
assign  debug_rxpro7_signal[155:150]          = dl_freq_pat[5:0];     
assign  debug_rxpro7_signal[161:156]          = ul_freq_pat[5:0];
assign  debug_rxpro7_signal[162]              = sync_freq_pn_rd_en_dly;
assign  debug_rxpro7_signal[163]              = tx_enable_start;
assign  debug_rxpro7_signal[164]              = rx_dds_rom_stat;    
assign  debug_rxpro7_signal[165]              = rx_freq_dds_end;
assign  debug_rxpro7_signal[171:166]              = rx_freq_cnt[5:0];

assign  debug_rxpro7_signal[199:172]          = 35'd0;



//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
endmodule
