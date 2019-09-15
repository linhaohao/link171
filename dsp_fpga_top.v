//////////////////////////////////////////////////////////////////////////////////
// Company:         StarPoint
// Engineer:        GUO YAN 
// 
// Create Date:     14:06:14 08/04/2015 
// Module Name:     dsp_fpga_top 
// Project Name:    Link16 dsp interface module;
// Target Devices:  FPGA - XC7K325T - FFG900; 
// Tool versions:   ISE14.6; 
// Description:     
//                  
//
// Revision:        v1.0 - File Created
// Additional Comments: 
// 1. 
//
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps


module dsp_fpga_top(
//// clock interface ////
input               logic_clk_in,               // 200MHz logic clock
input               logic_rst_in,               // reset
                                                
input               mcbsp_clk_in,               //fpga to dsp clk
input               mcbsp_rst_in,

////mif control
input               mif_dsp_fpga_source_sel,
input[3:0]          mif_work_mode,    

/////////////rtt 
input               tx_data_en_window_in,               
output              nrt_rtt_rsp_ng_out,  

input [31:0]        slot_timer,

//// port ////
////////mcbsp0
input               mcbsp0_slaver_clkx,	               
input               mcbsp0_slaver_fsx,	 
input               mcbsp0_slaver_mosi,          //dsp->fpga
                                                
output              mcbsp0_master_clkr,	        
output              mcbsp0_master_fsr,	        
output              mcbsp0_master_miso,	        //fpga->dsp

//硬件信息上报
output              port_red_stat,				//硬件状态读取使能
input	            port_data_valid,			//接口给数据前的使能
input	[31:0]	    port_red_data,

////////mcbsp1
input               mcbsp_slaver_clkx,	               
input               mcbsp_slaver_fsx,	 
input               mcbsp_slaver_mosi,          //dsp->fpga
                                                
output              mcbsp_master_clkr,	        
output              mcbsp_master_fsr,	        
output              mcbsp_master_miso,	        //fpga->dsp

                                                
////status////
output[3:0]         ju_work_mode,               // work mode 0:normal 1:mcbsp0 loop 2:mcbsp1 loop 3:fpga loop 4: rf loop
output[31:0]        ju_slot_ntrindi,            // '0' - JU; '1' - NTR
output[31:0]        ju_slot_slotmode,           // slot mode 0:rx slot 1:tx slot 2:RTT 3:loop
output[31:0]        ju_slot_posi,               // slot timer adjust based on ahead slot sync result  
output[31:0]        ju_slot_clknum,             // slot clock number for RTT adjust           
output[31:0]        ju_slot_txposi,             // advance time value in tx slot for link delay        
output[31:0]        ju_slot_txnum,              // tx slot real length          
output[31:0]        ju_slot_rxposi,             //        
output[31:0]        ju_slot_rxnum,              // rx slot max length(RTT =72), unknown real length 
output[31:0]        ju_slot_rfposi,             // tx rf ahead timing control position
output[31:0]        ju_unsync_timer,            // unsync timing threshold
output              ju_slot_switch,             // rx and tx slot switch enable


//// DL data transmit ////
input               tx_slot_interrupt,          // start interrupt for every slot,not only for tx
input               tx_rd_en,                   //tx pn/data(from dsp) read enalbe
input [9:0]         tx_addr_in,                 //tx pn/data(from dsp) read address
input               tx_freq_rd_en,              //tx freq(from dsp) read enalbe
input [9:0]         tx_freq_addr_in,            //tx freq read address

output[7:0]         dsp_ccsk_pat,               //tx ccsk data(from dsp)
output[7:0]         dsp_tx_freq_hop,            //tx frequence pattern
output[7:0]         dsp_rx_freq_hop,            //rx frequence pattern
output[31:0]        dsp_tx_pn_scram,            //tx pn scrambling pattern
output[31:0]        dsp_rx_pn_scram,            //rx pn scrambling pattern

//// UL data receive ////
input               rx_slot_interrupt,          //all rx data received to dsp intterrupt
input [9:0]         rx_freq_pn_addr_in,         //rx freq_pn pattern(from dsp) read address
input               rx_freq_pn_rd_in,           //rx freq_pn pattern(from dsp) read enable
output[7:0]         rx_ram_addr_out,            //rx data(to dsp)ram read adress
output              rx_ram_en_out,              //rx data(to dsp)ram read enable
input [31:0]        rx_ram_data_in,             //rx data to dsp(mcbsp master)

////intterupt
output              mcbsp1_loop_int_out,        //mcbsp1 loop(work mode = 2)interrupt to dsp 
//output              rx_rd_interrupt_out,        //observation point  

////////for test
output              dsp_cfg_end_out,
output              rx_chan_end_out,
output              tx_chan_end_out,

//dsp给的控制信号
output              dsp_ctr_uart_en,
output    [63:0]    dsp_ctr_uart_data,

output[199:0]       debug_tx1_signal,
//// debug ////
output[199:0]       debug_tx_signal,
output[199:0]       debug_rx_signal,
output[127:0]       debug_mcbsp0_signal,
output[127:0]       debug_mcbsp_signal

    );


//////////////////////////////////////////////////////////////////////////////////
//// signals declaration //// 
//////work mode signals
reg [3:0]           work_mode_reg              = 4'd1;
reg [2:0]           wokd_mode_pulse_reg        = 3'd0;
        
//////fpga->dsp rx signals
reg                 rx_dsp_rd_interrupt        = 1'b0;
reg                 rx_rd_interrupt            = 1'b0;

reg                 rx_rd_interrupt_gpio       = 1'b0;
reg [8:0]           rd_interrupt_gpio_cnt      = 9'd0;

reg                 rx_mcbsp_interrupt         = 1'b0;
reg [2:0]           rx_ram_en_reg              = 3'd0;
reg                 rx_ram_en                  = 1'b0;
reg [7:0]           rx_ram_addr                = 8'd0;
wire                rx_ram_addr_upd;           
wire[31:0]          dsp_rx_dina;               
  
//////dsp->fpga tx signals  
wire                tx_vaild_out;                  
wire[31:0]          dsp_tx_data;               
reg                 tx_mcbsp_interrupt         = 1'b0; 
reg [2:0]           tx_vaild_reg               = 3'd0;
reg                 tx_vaild                   = 1'b0; 
 
//////freq pattern signals   
reg                 freq_hop_en                = 1'b0;                                                          
reg                 freq_tx_wr                 = 1'b0;
reg                 freq_rx_wr                 = 1'b0;
reg [7:0]           freq_addr_tx_wr            = 8'd0;
reg [7:0]           freq_addr_rx_wr            = 8'd0;
reg [7:0]           freq_addr_tx_wr_dly        = 8'd0;
reg [7:0]           freq_addr_rx_wr_dly        = 8'd0;
reg                 freq_cfg_end               = 1'b0;
reg [5:0]           rtt_freq_num               = 6'd0;
reg [7:0]           loop_freq_num              = 8'd0;
 
//////data(ccsk) pattern signals   
wire                ccsk_pat_wr;               
reg                 ccsk_pat_en                = 1'b0;
reg [7:0]           ccsk_addr_wr               = 8'd0;
reg                 ccsk_pat_end               = 1'b0;
                                               
reg [7:0]           rtt_rsp_ram_ini            = 8'd0;
reg                 ccsk_nrt_rsp_en            = 1'b0;
reg [1:0]           nrt_rsp_en_reg             = 2'b00;

wire[1:0]           slot_slotmode_sel;
wire[7:0]           slot_txnum_div4_sel;
reg[1:0]            tx_data_en_window_dly      = 2'd0;
reg                 nrt_rtt_rsp_ng             = 1'b0;
                                               
//////pn pattern signals                                                  
reg                 pn_pat_en                  = 1'b0;                                                         
reg                 pn_tx_wr                   = 1'b0; 
reg                 pn_rx_wr                   = 1'b0; 
reg [9:0]           pn_addr_tx_wr              = 10'd0;
reg [9:0]           pn_addr_rx_wr              = 10'd0;
reg [9:0]           pn_addr_tx_wr_dly          = 10'd0;
reg [9:0]           pn_addr_rx_wr_dly          = 10'd0;
reg                 pn_cfg_end                 = 1'b0;
reg [7:0]           rtt_pn_num                 = 8'd0;
reg [9:0]           loop_pn_num                = 10'd0;
   
//////config signals       
reg                 ju_status_en               = 1'b0;
reg [3:0]           ju_status_cnt              = 4'd0;
                                               
reg [31:0]          slot_ntrindi               = 32'd0;
reg [31:0]          slot_slotmode              = 32'd0; 
reg [31:0]          slot_posi                  = 32'd0;    
reg [31:0]          slot_clknum                = 32'd1562499;
reg [31:0]          slot_txposi                = 32'd0;  
reg [31:0]          slot_txnum                 = 32'd444;   
reg [31:0]          slot_rxposi                = 32'd0;  
reg [31:0]          slot_rxnum                 = 32'd444; //for initial unsync,only 444 or 72 assigment
reg [31:0]          slot_rfposi                = 32'd0; 
reg [31:0]          slot_unsync                = 32'd1600000;
                                               
reg [31:0]          slot_ntrindi_reg           = 32'd0;
reg [31:0]          slot_slotmode_reg          = 32'd0;
reg [31:0]          slot_posi_reg              = 32'd0;
reg [31:0]          slot_clknum_reg            = 32'd1562499;
reg [31:0]          slot_txposi_reg            = 32'd0;
reg [31:0]          slot_txnum_reg             = 32'd444;
reg [31:0]          slot_rxposi_reg            = 32'd0;
reg [31:0]          slot_rxnum_reg             = 32'd444;
reg [31:0]          slot_rfposi_reg            = 32'd0;
reg [31:0]          slot_unsync_reg            = 32'd1600000;
                                               
reg [7:0]           slot_txnum_div4            = 8'd111;
reg [7:0]           slot_rxnum_div4            = 8'd111;
reg [7:0]           ju_slot_rxnum_div4         = 8'd111;
reg [7:0]           ju_slot_rxnum_cur_div4     = 8'd111;
                                               
reg [7:0]           rx_slot_data_length        = 8'd102;
 
//////slot config switch signals     
reg [31:0]          delay_end_cnt              = 32'd0;
reg                 delay_cnt_en               = 1'b0;      
reg                 rx_chan_end                = 1'b0; 
reg                 tx_chan_end                = 1'b0;
reg                 cur_slot_end               = 1'b1; //considering initial process
reg                 dsp_cfg_end                = 1'b0;
reg                 slot_switch_end            = 1'b0;
reg                 slot_switch_end_dly        = 1'b0;

//////mcbsp1 loop signals   
wire                mcbsp1_loop_wr;
reg [6:0]           mcbsp1_loop_wr_addr        = 7'd0;
reg                 mcbsp1_loop_rx_interrupt   = 1'b0;
reg                 mcbsp1_loop_int            = 1'b0;
reg [8:0]           mcbsp1_loop_int_cnt        = 9'd0;
                    
wire                mcbsp1_loop_rd;
reg [6:0]           mcbsp1_loop_rd_addr        = 7'd0;
wire[31:0]          mcbsp1_loop_rd_data;


//////mcbsp0 signals  
wire [3:0]          rev_work_mode;
wire                work_mode_vld;
// wire                port_red_stat;
wire                port_wr_en;
wire [31:0]         port_wr_data;

//////debug signals 
wire[127:0]         debug_signal_zero_top;
wire[127:0]         debug_mcbsp;

reg                 rx_chan_end_test = 1'b0;
reg [31:0]          rx_chan_end_test_cnt = 32'd0;
reg                 rx_chan_end_test_pulse = 1'b0;

//-------------------------------------2016/1/26 17:40:29
reg                 tx_chan_end_reg = 1'd0;
reg                 tx_chan_end_dlen = 1'd0;
reg [17:0]          tx_end_cnt       = 18'd0;
reg                 ccsk_vs_rtt_en;  



//////////////////////////////////////////////////////////////////////////////////
//// parameters define ////
parameter    DELAY_COUNT                   = 32'd2599; //13us
parameter    SPI_LENTGH                    = 7'd32;


//////////////////////////////////////////////////////////////////////////////////
//// (0) signals assigment ////
assign       rx_ram_addr_out[7:0]          = rx_ram_addr[7:0];
assign       rx_ram_en_out                 = rx_ram_en;

assign       ju_work_mode[3:0]             = work_mode_reg[3:0];
assign       ju_slot_ntrindi[31:0]         = slot_ntrindi_reg[31:0]; 
assign       ju_slot_slotmode[31:0]        = slot_slotmode_reg[31:0];
assign       ju_slot_posi[31:0]            = slot_posi_reg[31:0];      
assign       ju_slot_clknum[31:0]          = slot_clknum_reg[31:0];  
assign       ju_slot_txposi[31:0]          = slot_txposi_reg[31:0];    
assign       ju_slot_txnum[31:0]           = slot_txnum_reg[31:0];     
assign       ju_slot_rxposi[31:0]          = slot_rxposi_reg[31:0];    
assign       ju_slot_rxnum[31:0]           = slot_rxnum_reg[31:0]; 
assign       ju_slot_rfposi[31:0]          = slot_rfposi_reg[31:0];  
assign       ju_unsync_timer[31:0]         = slot_unsync_reg[31:0];  
assign       ju_slot_switch                = slot_switch_end_dly;

assign       ccsk_pat_wr                   = (ccsk_pat_en || ccsk_nrt_rsp_en) && tx_vaild_out;
assign       slot_slotmode_sel[1:0]        = ccsk_nrt_rsp_en ? ju_slot_slotmode[1:0] : slot_slotmode[1:0];
assign       slot_txnum_div4_sel[7:0]      = ccsk_nrt_rsp_en ? 8'd18 : slot_txnum_div4[7:0];  //72/4=18
assign       nrt_rtt_rsp_ng_out            = nrt_rtt_rsp_ng;

assign       dsp_rx_dina[31:0]             = (work_mode_reg[3:0] == 4'd2) ? mcbsp1_loop_rd_data[31:0] : rx_ram_data_in[31:0];
assign       mcbsp1_loop_wr                = (work_mode_reg[3:0] == 4'd2) ? ccsk_pat_wr : 1'b0;
assign       mcbsp1_loop_rd                = (work_mode_reg[3:0] == 4'd2) ? rx_ram_en : 1'b0;
assign       mcbsp1_loop_int_out           =  mcbsp1_loop_rx_interrupt; 

//assign       rx_rd_interrupt_out           =  rx_rd_interrupt_gpio;  
  

//////////for test
assign       dsp_cfg_end_out               =  dsp_cfg_end;
assign       rx_chan_end_out               =  rx_chan_end;
assign       tx_chan_end_out               =  tx_chan_end; 

//////////////////////////////////////////////////////////////////////////////////
//// (1)work mode logic ////
always@(posedge logic_clk_in)
begin
  if (logic_rst_in)  begin
     wokd_mode_pulse_reg[2:0]       <= 3'd0;
  end
  else begin
     wokd_mode_pulse_reg[2:0]       <= {wokd_mode_pulse_reg[1:0],work_mode_vld}; 
  end
end	 

always@(posedge logic_clk_in)
begin
  if (logic_rst_in)  begin
     work_mode_reg[3:0]             <= 4'd1;
  end
  else if(wokd_mode_pulse_reg[1:0] == 2'b01)begin
     work_mode_reg[3:0]             <= rev_work_mode[3:0]; 
  end
  else if(mif_work_mode[3])begin
     work_mode_reg[3:0]             <= {1'b0,mif_work_mode[2:0]}; 
  end
end	


always@(posedge logic_clk_in)
begin
  if (logic_rst_in)  begin
     rx_slot_data_length[7:0]       <= 8'd102; //(444-40+4=408)/4=102
  end
  else if(work_mode_reg[3:0] == 4'd2)begin
     rx_slot_data_length[7:0]       <= slot_rxnum_div4[7:0]; //444/4=111 //not ju_slot_rxnum, ju is current num
  end
  else begin
     rx_slot_data_length[7:0]       <= ju_slot_rxnum_cur_div4[7:0] - 4'd9;//ju_slot_rxnum_div4[7:0] - 4'd9; //(444-40+4=444-36=408)/4  //(rx_data + toa/unsync)/4  ju is current num
  end
end	


//////////////////////////////////////////////////////////////////////////////////
//// (1)mcbsp logic ////
mcbsp_top  u_mcbsp_module
   (
    //// clock interface ////
    .mcbsp_clk_in(mcbsp_clk_in),          // 10MHz logic clock
    .mcbsp_rst_in(mcbsp_rst_in),                  // 

    //// port ////
    .mcbsp_slaver_clkx(mcbsp_slaver_clkx),	 
    .mcbsp_slaver_fsx(mcbsp_slaver_fsx),	 
    .mcbsp_slaver_mosi(mcbsp_slaver_mosi), 

    .mcbsp_master_clkr(mcbsp_master_clkr),	 
    .mcbsp_master_fsr(mcbsp_master_fsr),	 
    .mcbsp_master_miso(mcbsp_master_miso),	

    //// DL data transmit ////
    //.tx_mcbsp_interrupt(tx_mcbsp_interrupt),
    .dsp_tx_data(dsp_tx_data[31:0]), 
	.tx_vaild_out(tx_vaild_out),
	
    //// UL data receive ////
    .rx_mcbsp_interrupt(rx_mcbsp_interrupt), //rd interrupt
    .rx_slot_data_length(rx_slot_data_length[7:0]),
    .dsp_rx_dina(dsp_rx_dina[31:0]),

    .rx_ram_addr_upd(rx_ram_addr_upd),
    
    //// debug ////
    .debug_signal(debug_mcbsp[127:0])
   
    );

//////////////////////////////////////////////////////////////////////////////////
//// (2) DL/TX RAM write address logic ////
////(2-0) mcbsp enable logic according to rx_interrupt
// always@(posedge logic_clk_in)
// begin
  // if (logic_rst_in)  begin
     // tx_mcbsp_interrupt             <= 1'b0; //fpga receive dsp data, only mcbsp_slaver_clkx control not tx_interrupt enable
  // end
  // else if(tx_slot_interrupt)begin
     // tx_mcbsp_interrupt             <= ~tx_mcbsp_interrupt; //pulse->level for sampling in cross clock domain
  // end
// end	

////(2-1) Cross Clock Domain
always@(posedge logic_clk_in)
begin
  if (logic_rst_in)  begin
     tx_vaild_reg[2:0]              <= 3'd0;
  end
  else begin
     tx_vaild_reg[2:0]              <= {tx_vaild_reg[1:0],tx_vaild_out};
  end
end	

always@(posedge logic_clk_in)
begin
  if (logic_rst_in)  begin
     tx_vaild                       <= 1'b0;
  end                               
  else if(tx_vaild_reg[2:1] == 2'b01)begin                        
     tx_vaild                       <= 1'b1; //occupy 1 logic clk
  end
  else begin
     tx_vaild                       <= 1'b0;
  end
end	

////(2-2) tx ccsk data pattern for every time slot (contain tx)
always@(posedge mcbsp_slaver_clkx or posedge mcbsp_rst_in)
begin
  if (mcbsp_rst_in)  begin
     ccsk_pat_en                    <= 1'b0;
  end
  else if(ccsk_pat_end)begin        
     ccsk_pat_en                    <= 1'b0;
  end
  else if((dsp_tx_data[31:0] == 32'h66669999) && tx_vaild_out)begin
     ccsk_pat_en                    <= 1'b1;
  end
end

///////////////////////////////////////////////////////
////////////////test 
reg[7:0] ccsk_pat_en_cnt = 8'd0;
always@(posedge mcbsp_slaver_clkx or posedge mcbsp_rst_in)
begin
  if (mcbsp_rst_in)  begin
     ccsk_pat_en_cnt[7:0]                    <= 8'd0;
  end
  else if((dsp_tx_data[31:0] == 32'h66669999) && tx_vaild_out)begin
     ccsk_pat_en_cnt[7:0]                    <= ccsk_pat_en_cnt[7:0] + 1'b1;
  end
end
//--------------------------------------------------------------
reg[7:0] ccsk_pat_end_cnt = 8'd0;
always@(posedge mcbsp_slaver_clkx or posedge mcbsp_rst_in)
begin
  if (mcbsp_rst_in)  begin
     ccsk_pat_end_cnt[7:0]                    <= 8'd0;
  end
  else if(ccsk_pat_end)begin
     ccsk_pat_end_cnt[7:0]                    <= ccsk_pat_end_cnt[7:0] + 1'b1;
  end
end

reg[7:0] loop_int_cnt = 8'd0;
always@(posedge mcbsp_slaver_clkx or posedge mcbsp_rst_in)
begin
  if (mcbsp_rst_in)  begin
     loop_int_cnt[7:0]                    <= 8'd0;
  end
  else if((mcbsp1_loop_wr_addr[6:0] == (slot_txnum_div4[6:0] - 1'b1)) && mcbsp1_loop_wr)begin
     loop_int_cnt[7:0]                    <= loop_int_cnt[7:0] + 1'b1;
  end
end

/////////////////////////////////////////////////////////////


always@(posedge mcbsp_slaver_clkx or posedge mcbsp_rst_in)
begin
  if (mcbsp_rst_in)  begin //make sure power reset 
       ccsk_addr_wr[7:0]                        <= 8'd0; 
  end
  else begin
        case(slot_slotmode_sel[1:0])	  //区分下一帧和本帧，本帧更新为RTT时隙。
		2'd1: begin	 //next is tx slot
			if((ccsk_addr_wr[7:0] == (slot_txnum_div4[7:0] - 1'b1))&& ccsk_pat_wr) begin  //444 pulse/4=111
               ccsk_addr_wr[7:0]                <= 8'd128; // ping-pang buffer
			   ccsk_pat_end                     <= 1'b1;
            end
			else if((ccsk_addr_wr[7:0] == (slot_txnum_div4[7:0]  + 7'd127))&& ccsk_pat_wr) begin  //444 pulse/4=111
               ccsk_addr_wr[7:0]                <= 8'd0; // ping-pang buffer
			   ccsk_pat_end                     <= 1'b1;
            end
            else if(ccsk_pat_wr)begin
               ccsk_addr_wr[7:0]                <= ccsk_addr_wr[7:0] + 1'b1;
			   ccsk_pat_end                     <= 1'b0;
            end
			else begin
               ccsk_addr_wr[7:0]                <= ccsk_addr_wr[7:0];
			   ccsk_pat_end                     <= 1'b0; //ccsk_pat_end push down
            end
	    end

		2'd2: begin		
			//next is RTT slot
			if((ccsk_addr_wr[7:0] == (slot_txnum_div4_sel[7:0] - 1'b1)) && ccsk_pat_wr)  begin  //72 pulse/4=18
			       if(ccsk_vs_rtt_en)begin
                // ccsk_addr_wr[7:0]             <= 8'd128;
			         ccsk_addr_wr[7:0]             <= 8'd0;
			          //  ccsk_addr_wr[7:0]             <= mif_dap_pip_en ? 8'd0 : 8'd128; // ping-pang buffer
               ccsk_pat_end                  <= 1'b1;
             end
             else begin
               ccsk_addr_wr[7:0]             <= 8'd128;
               ccsk_pat_end                  <= 1'b1;
             end        
       end                       
			else if((ccsk_addr_wr[7:0] == (slot_txnum_div4_sel[7:0] + 7'd127)) && ccsk_pat_wr)  begin
			        if(ccsk_vs_rtt_en)begin
			         ccsk_addr_wr[7:0]             <= 8'd128;
			        // ccsk_addr_wr[7:0]             <= 8'd0; 
              // ccsk_addr_wr[7:0]             <= mif_dap_pip_en ? 8'd128 : 8'd0; //2016/1/28 17:28:29
               ccsk_pat_end                  <= 1'b1;
              end
              else begin
               ccsk_addr_wr[7:0]             <= 8'd0;
               ccsk_pat_end                  <= 1'b1;
              end
      end
			else if(nrt_rsp_en_reg[1:0] == 2'b01)begin //rising update intial ram address
               ccsk_addr_wr[7:0]             <= rtt_rsp_ram_ini[7:0];
               ccsk_pat_end                  <= 1'b0;
            end
			else if(ccsk_pat_wr)begin
               ccsk_addr_wr[7:0]             <= ccsk_addr_wr[7:0] + 1'b1;
               ccsk_pat_end                  <= 1'b0;
            end	
			else begin
               ccsk_addr_wr[7:0]             <= ccsk_addr_wr[7:0];
               ccsk_pat_end                  <= 1'b0;
            end
	    end
		
		2'd3: begin		
			//loop
			if((ccsk_addr_wr[7:0] == (slot_txnum_div4[7:0]  - 1'b1)) && ccsk_pat_wr)  begin  //444 pulse/4=111
               ccsk_addr_wr[7:0]             <= 8'd128; // ping-pang buffer
			   ccsk_pat_end                  <= 1'b1;
            end
			else if((ccsk_addr_wr[7:0] == (slot_txnum_div4[7:0] + 7'd127)) && ccsk_pat_wr)  begin
               ccsk_addr_wr[7:0]             <= 8'd0; 
			   ccsk_pat_end                  <= 1'b1;
            end
			else if(ccsk_pat_wr)begin
               ccsk_addr_wr[7:0]             <= ccsk_addr_wr[7:0] + 1'b1;
			   ccsk_pat_end                  <= 1'b0;
            end
			else begin
               ccsk_addr_wr[7:0]             <= ccsk_addr_wr[7:0];
			   ccsk_pat_end                  <= 1'b0;
            end
		end
				
		default: begin
			ccsk_addr_wr[7:0]                    <= ccsk_addr_wr[7:0];
		end	
	  endcase
  end
end


////(2-3) frequency hopping pattern for every time slot
////(2-3-0)freq pattern preamble detect
always@(posedge mcbsp_slaver_clkx or posedge mcbsp_rst_in)
begin
  if (mcbsp_rst_in)  begin
     freq_hop_en                    <= 1'b0;
  end                               
  else if(freq_cfg_end)begin        
     freq_hop_en                    <= 1'b0;
  end
  else if((dsp_tx_data[31:0] == 32'h4444BBBB)&& tx_vaild_out) begin
     freq_hop_en                    <= 1'b1;
  end
end	
 
////(2-3-1)tx/rx freq pattern
always@(posedge mcbsp_slaver_clkx or posedge mcbsp_rst_in)
begin
  if (mcbsp_rst_in)  begin //make sure power reset 
       freq_addr_rx_wr[7:0]                     <= 8'd0; 
	   freq_addr_tx_wr[7:0]                     <= 8'd0;
	   freq_cfg_end                             <= 1'b0;   
  end
  else if(freq_hop_en) begin
      case(slot_slotmode[1:0])
	    2'd0: begin	 //next is rx slot
			if((freq_addr_rx_wr[7:0] == (slot_rxnum_div4[7:0] - 1'b1)) && tx_vaild_out)  begin  //444 pulse/4=111
               freq_addr_rx_wr[7:0]             <= 8'd128; // ping-pang buffer
			   freq_rx_wr                       <= 1'b1;
			   freq_cfg_end                     <= 1'b1;			   
            end
			else if((freq_addr_rx_wr[7:0] == (slot_rxnum_div4[7:0] + 7'd127)) && tx_vaild_out)  begin
               freq_addr_rx_wr[7:0]             <= 8'd0; 
			   freq_rx_wr                       <= 1'b1;
			   freq_cfg_end                     <= 1'b1;
            end
            else if(tx_vaild_out)begin
               freq_addr_rx_wr[7:0]             <= freq_addr_rx_wr[7:0] + 1'b1;
			   freq_rx_wr                       <= 1'b1;
			   freq_cfg_end                     <= 1'b0;
            end
		    else begin
               freq_addr_rx_wr[7:0]             <= freq_addr_rx_wr[7:0];
			   freq_rx_wr                       <= 1'b0;                
			   freq_cfg_end                     <= 1'b0; //freq_cfg_end push down
            end
	    end
			
		2'd1: begin	 //next is tx slot
			if((freq_addr_tx_wr[7:0] == (slot_txnum_div4[7:0] - 1'b1)) && tx_vaild_out) begin  //444 pulse/4=111
               freq_addr_tx_wr[7:0]             <= 8'd128; // ping-pang buffer
			   freq_tx_wr                       <= 1'b1;
			   freq_cfg_end                     <= 1'b1;
            end
			else if((freq_addr_tx_wr[7:0] == (slot_txnum_div4[7:0] + 7'd127)) && tx_vaild_out) begin
               freq_addr_tx_wr[7:0]             <= 8'd0;
			   freq_tx_wr                       <= 1'b1;
               freq_cfg_end                     <= 1'b1;			   
            end
            else if(tx_vaild_out)begin
               freq_addr_tx_wr[7:0]             <= freq_addr_tx_wr[7:0] + 1'b1;
			   freq_tx_wr                       <= 1'b1;
			   freq_cfg_end                     <= 1'b0;
            end
			else begin
			   freq_addr_tx_wr[7:0]             <= freq_addr_tx_wr[7:0];
			   freq_tx_wr                       <= 1'b0;
			   freq_cfg_end                     <= 1'b0;
			end
	    end
		
		2'd2: begin	
		    //next is RTT slot(any RTT slot first tx then rx)
			if((freq_addr_rx_wr[7:0] == (slot_rxnum_div4[7:0] - 1'b1)) && tx_vaild_out)  begin  //72 pulse/4=18
               freq_addr_rx_wr[7:0]             <= 8'd128; // ping-pang buffer
			   freq_rx_wr                       <= 1'b1;
			   freq_cfg_end                     <= 1'b1;
            end
			else if((freq_addr_rx_wr[7:0] == (slot_rxnum_div4[7:0] + 7'd127)) && tx_vaild_out)  begin
               freq_addr_rx_wr[7:0]             <= 8'd0;
			   freq_rx_wr                       <= 1'b1;
               freq_cfg_end                     <= 1'b1;			   
            end
			else if(tx_vaild_out && (rtt_freq_num[5:0] >= slot_rxnum_div4[7:0]))begin //rtt txnum=rxnum
               freq_addr_rx_wr[7:0]             <= freq_addr_rx_wr[7:0] + 1'b1;
			   freq_rx_wr                       <= 1'b1;
			   freq_cfg_end                     <= 1'b0;
            end
			else begin
			   freq_addr_rx_wr[7:0]             <= freq_addr_rx_wr[7:0];
			   freq_rx_wr                       <= 1'b0;
			   freq_cfg_end                     <= 1'b0;
			end
			
			//next is RTT slot
			if((freq_addr_tx_wr[7:0] == (slot_txnum_div4[7:0] - 1'b1)) && tx_vaild_out)  begin  //72 pulse/4=18
               freq_addr_tx_wr[7:0]             <= 8'd128; // ping-pang buffer
			   freq_tx_wr                       <= 1'b1;
            end
			else if((freq_addr_tx_wr[7:0] == (slot_txnum_div4[7:0] + 7'd127)) && tx_vaild_out)  begin
               freq_addr_tx_wr[7:0]             <= 8'd0; 
			   freq_tx_wr                       <= 1'b1;
            end
			else if(tx_vaild_out && (rtt_freq_num[5:0] < slot_txnum_div4[7:0]))begin
               freq_addr_tx_wr[7:0]             <= freq_addr_tx_wr[7:0] + 1'b1;
			   freq_tx_wr                       <= 1'b1;
            end
			else begin
               freq_addr_tx_wr[7:0]             <= freq_addr_tx_wr[7:0];
			   freq_tx_wr                       <= 1'b0;
            end
	    end
		
		2'd3: begin	
		    //loop rx (first tx then rx) //loop tx_num = rx_num= 444 
			if((freq_addr_rx_wr[7:0] == (slot_rxnum_div4[7:0] - 1'b1)) && tx_vaild_out)  begin  //444 pulse/4=111
               freq_addr_rx_wr[7:0]             <= 8'd128; // ping-pang buffer
			   freq_rx_wr                       <= 1'b1;
			   freq_cfg_end                     <= 1'b1;
            end
			else if((freq_addr_rx_wr[7:0] == (slot_rxnum_div4[7:0] + 7'd127)) && tx_vaild_out)  begin
               freq_addr_rx_wr[7:0]             <= 8'd0;
			   freq_rx_wr                       <= 1'b1;
               freq_cfg_end                     <= 1'b1;			   
            end
			else if(tx_vaild_out && (loop_freq_num[7:0] >= slot_rxnum_div4[7:0]))begin //loop txnum = rxnum = 444
               freq_addr_rx_wr[7:0]             <= freq_addr_rx_wr[7:0] + 1'b1;
			   freq_rx_wr                       <= 1'b1;
			   freq_cfg_end                     <= 1'b0;
            end
			else begin
			   freq_addr_rx_wr[7:0]             <= freq_addr_rx_wr[7:0];
			   freq_rx_wr                       <= 1'b0;
			   freq_cfg_end                     <= 1'b0;
			end
			
			//loop tx 
			if((freq_addr_tx_wr[7:0] == (slot_txnum_div4[7:0] - 1'b1)) && tx_vaild_out)  begin  //444 pulse/4=111
               freq_addr_tx_wr[7:0]             <= 8'd128; // ping-pang buffer
			   freq_tx_wr                       <= 1'b1;
            end
			else if((freq_addr_tx_wr[7:0] == (slot_txnum_div4[7:0] + 7'd127)) && tx_vaild_out)  begin
               freq_addr_tx_wr[7:0]             <= 8'd0; 
			   freq_tx_wr                       <= 1'b1;
            end
			else if(tx_vaild_out && (loop_freq_num[7:0] < slot_txnum_div4[7:0]))begin
               freq_addr_tx_wr[7:0]             <= freq_addr_tx_wr[7:0] + 1'b1;
			   freq_tx_wr                       <= 1'b1;
            end
			else begin
               freq_addr_tx_wr[7:0]             <= freq_addr_tx_wr[7:0];
			   freq_tx_wr                       <= 1'b0;
            end
	    end
				
		default: begin
		    freq_addr_rx_wr[7:0]                <= freq_addr_rx_wr[7:0];
			freq_addr_tx_wr[7:0]                <= freq_addr_tx_wr[7:0];
		end	
	  endcase
  end
end


////(2-3-3)rtt slot freq pattern switch	
always@(posedge mcbsp_slaver_clkx or posedge mcbsp_rst_in)
begin
    if (mcbsp_rst_in)  begin
	    rtt_freq_num[5:0]                <= 6'd0;
	end
    else if(freq_hop_en) begin
      if (slot_slotmode[1:0] == 2'd2) begin
		  if(tx_vaild_out && (rtt_freq_num[5:0] == (slot_txnum_div4[7:0] + slot_rxnum_div4[7:0] - 1'b1))) begin //tx+rx=72+72=144;144/4(32bit)=36=72/2
		    rtt_freq_num[5:0]            <= 6'd0;
		  end
	      else if(tx_vaild_out) begin
	        rtt_freq_num[5:0]            <= rtt_freq_num[5:0] + 1'b1;
		  end                       
		  else begin                
		    rtt_freq_num[5:0]            <= rtt_freq_num[5:0];
		  end
	  end
  end
end

////(2-3-4)loop freq pattern switch	
always@(posedge mcbsp_slaver_clkx or posedge mcbsp_rst_in)
begin
    if (mcbsp_rst_in)  begin
	    loop_freq_num[7:0]                <= 8'd0;
	end
    else if(freq_hop_en) begin
      if (slot_slotmode[1:0] == 2'd3) begin  
		  if(tx_vaild_out && (loop_freq_num[7:0] == (slot_txnum_div4[7:0] + slot_rxnum_div4[7:0] - 1'b1))) begin //tx+rx=444+444=888;888/4(32bit)=222=444/2
		    loop_freq_num[7:0]            <= 8'd0;
		  end
	      else if(tx_vaild_out) begin
	        loop_freq_num[7:0]            <= loop_freq_num[7:0] + 1'b1;
		  end                       
		  else begin                
		    loop_freq_num[7:0]            <= loop_freq_num[7:0];
		  end
	  end
  end
end

////(2-4-5)tx/rx_wr align at tx/rx_addr
always@(posedge mcbsp_slaver_clkx or posedge mcbsp_rst_in)
begin
    if (mcbsp_rst_in)  begin
	    freq_addr_tx_wr_dly[7:0]          <= 8'd0;
		freq_addr_rx_wr_dly[7:0]          <= 8'd0;
	end                                   
    else  begin 
        freq_addr_tx_wr_dly[7:0]          <= freq_addr_tx_wr[7:0];	
		freq_addr_rx_wr_dly[7:0]          <= freq_addr_rx_wr[7:0];
	end
end

////(2-4) pn pattern for every time slot
////(2-4-0)pn pattern preamble detect
always@(posedge mcbsp_slaver_clkx or posedge mcbsp_rst_in)
begin
  if (mcbsp_rst_in)  begin
     pn_pat_en                      <= 1'b0;
  end                               
  else if(pn_cfg_end)begin          
     pn_pat_en                      <= 1'b0;
  end
  else if((dsp_tx_data[31:0] == 32'h2222DDDD) && tx_vaild_out) begin
     pn_pat_en                      <= 1'b1;
  end
end	
 
////(2-4-1)tx/rx pn pattern
always@(posedge mcbsp_slaver_clkx or posedge mcbsp_rst_in)
begin
  if (mcbsp_rst_in)  begin //make sure power reset 
      pn_addr_rx_wr[9:0]                      <= 10'd0; 
	  pn_addr_tx_wr[9:0]                      <= 10'd0;
      pn_cfg_end                              <= 1'b0;	
  end 
  else if(pn_pat_en) begin
      case(slot_slotmode[1:0])
	    2'd0: begin	 //next is rx slot
		    if((pn_addr_rx_wr[9:0] == (slot_rxnum[9:0] - 1'b1)) && tx_vaild_out)  begin  //444 pulse
               pn_addr_rx_wr[9:0]             <= 10'd512; // ping-pang buffer
			   pn_rx_wr                       <= 1'b1;
			   pn_cfg_end                     <= 1'b1;			   
            end
            else if((pn_addr_rx_wr[9:0] == (slot_rxnum[9:0] + 9'd511)) && tx_vaild_out)  begin
               pn_addr_rx_wr[9:0]             <= 10'd0; 
			   pn_rx_wr                       <= 1'b1;
			   pn_cfg_end                     <= 1'b1;
            end
            else if(tx_vaild_out)begin
               pn_addr_rx_wr[9:0]             <= pn_addr_rx_wr[9:0] + 1'b1;
			   pn_rx_wr                       <= 1'b1;
			   pn_cfg_end                     <= 1'b0;
            end
		    else begin
               pn_addr_rx_wr[9:0]             <= pn_addr_rx_wr[9:0];
			   pn_rx_wr                       <= 1'b0;
			   pn_cfg_end                     <= 1'b0; //pn_cfg_end push down
            end
	    end
		
		2'd1: begin	 //next is tx slot
		    if((pn_addr_tx_wr[9:0] == (slot_txnum[9:0] - 1'b1)) && tx_vaild_out)  begin  //444 pulse
               pn_addr_tx_wr[9:0]             <= 10'd512; // ping-pang buffer
			   pn_tx_wr                       <= 1'b1;
			   pn_cfg_end                     <= 1'b1;
            end
            else if((pn_addr_tx_wr[9:0] == (slot_txnum[9:0] + 9'd511)) && tx_vaild_out)  begin
               pn_addr_tx_wr[9:0]             <= 10'd0;
			   pn_tx_wr                       <= 1'b1;
               pn_cfg_end                     <= 1'b1;			   
            end
            else if(tx_vaild_out)begin
               pn_addr_tx_wr[9:0]             <= pn_addr_tx_wr[9:0] + 1'b1;
			   pn_tx_wr                       <= 1'b1;
			   pn_cfg_end                     <= 1'b0;
            end
			else begin
			   pn_addr_tx_wr[9:0]             <= pn_addr_tx_wr[9:0];
			   pn_tx_wr                       <= 1'b0;
			   pn_cfg_end                     <= 1'b0;
			end
	    end
			
		2'd2: begin	
		    //next is RTT slot(any RTT slot first tx then rx)
		    if((pn_addr_rx_wr[9:0] ==  (slot_rxnum[9:0] - 1'b1)) && tx_vaild_out)  begin  //72 pulse
           pn_addr_rx_wr[9:0]             <= 10'd512; // ping-pang buffer
			     pn_rx_wr                       <= 1'b1;
			     pn_cfg_end                     <= 1'b1;
        end
        else if((pn_addr_rx_wr[9:0] == (slot_rxnum[9:0] + 9'd511)) && tx_vaild_out)  begin
                pn_addr_rx_wr[9:0]             <= 10'd0;
			          pn_rx_wr                       <= 1'b1;
                pn_cfg_end                     <= 1'b1;			   
        end
			  else if(tx_vaild_out && (rtt_pn_num[7:0] >= slot_rxnum[7:0]))begin		//RTT接收完毕时
                pn_addr_rx_wr[9:0]             <= pn_addr_rx_wr[9:0] + 1'b1;
			          pn_rx_wr                       <= 1'b1;
			          pn_cfg_end                     <= 1'b0;
             end
			  else begin
			    pn_addr_rx_wr[9:0]             <= pn_addr_rx_wr[9:0];
			    pn_rx_wr                       <= 1'b0;
			    pn_cfg_end                     <= 1'b0;
			  end
			
			//next is RTT slot
		    if((pn_addr_tx_wr[9:0] == (slot_txnum[9:0] - 1'b1)) && tx_vaild_out)  begin  //72 pulse
               pn_addr_tx_wr[9:0]             <= 10'd512; // ping-pang buffer
			   pn_tx_wr                       <= 1'b1;
            end
            else if((pn_addr_tx_wr[9:0] == (slot_txnum[9:0] + 9'd511)) && tx_vaild_out)  begin
               pn_addr_tx_wr[9:0]             <= 10'd0; 
			   pn_tx_wr                       <= 1'b1;
            end
			else if(tx_vaild_out && (rtt_pn_num[7:0] < slot_txnum[7:0]))begin      //RTT发送状态。
               pn_addr_tx_wr[9:0]             <= pn_addr_tx_wr[9:0] + 1'b1;
			   pn_tx_wr                       <= 1'b1;
            end	
            else begin
			   pn_addr_tx_wr[9:0]             <= pn_addr_tx_wr[9:0];
			   pn_tx_wr                       <= 1'b0;
            end			
	    end
		
		2'd3: begin	
		    //loop rx (first tx then rx)
			if((pn_addr_rx_wr[9:0] == (slot_rxnum[9:0] - 1'b1)) && tx_vaild_out)  begin  //444 pulse
               pn_addr_rx_wr[9:0]             <= 10'd512; // ping-pang buffer
			   pn_rx_wr                       <= 1'b1;
			   pn_cfg_end                     <= 1'b1;
            end
		    else if((pn_addr_rx_wr[9:0] == (slot_rxnum[9:0] + 9'd511)) && tx_vaild_out)  begin
               pn_addr_rx_wr[9:0]             <= 10'd0;
			   pn_rx_wr                       <= 1'b1;
               pn_cfg_end                     <= 1'b1;			   
            end
			else if(tx_vaild_out && (loop_pn_num[9:0] >= slot_rxnum[9:0]))begin
               pn_addr_rx_wr[9:0]             <= pn_addr_rx_wr[9:0] + 1'b1;
			   pn_rx_wr                       <= 1'b1;
			   pn_cfg_end                     <= 1'b0;
            end
			else begin
			   pn_addr_rx_wr[9:0]             <= pn_addr_rx_wr[9:0];
			   pn_rx_wr                       <= 1'b0;
			   pn_cfg_end                     <= 1'b0;
			end
			
			//loop tx 
			if((pn_addr_tx_wr[9:0] == (slot_txnum[9:0] - 1'b1)) && tx_vaild_out)  begin  //444 pulse
               pn_addr_tx_wr[9:0]             <= 10'd512; // ping-pang buffer
			   pn_tx_wr                       <= 1'b1;
            end
			else if((pn_addr_tx_wr[9:0] == (slot_txnum[9:0] + 9'd511)) && tx_vaild_out)  begin
               pn_addr_tx_wr[9:0]             <= 10'd0; 
			   pn_tx_wr                       <= 1'b1;
            end
			else if(tx_vaild_out && (loop_pn_num[9:0] < slot_txnum[9:0]))begin
               pn_addr_tx_wr[9:0]             <= pn_addr_tx_wr[9:0] + 1'b1;
			   pn_tx_wr                       <= 1'b1;
            end
            else begin
			   pn_addr_tx_wr[9:0]             <= pn_addr_tx_wr[9:0];
			   pn_tx_wr                       <= 1'b0;
            end			
	    end
		
		default: begin
		    pn_addr_rx_wr[9:0]                <= pn_addr_rx_wr[9:0];
			pn_addr_tx_wr[9:0]                <= pn_addr_tx_wr[9:0];
		end	
	  endcase
  end
end


////(2-4-3)rtt slot pn pattern switch	
always@(posedge mcbsp_slaver_clkx or posedge mcbsp_rst_in)
begin
    if (mcbsp_rst_in)  begin
	    rtt_pn_num[7:0]            <= 8'd0;
	end
    else if(pn_pat_en) begin
      if (slot_slotmode[1:0] == 2'd2) begin  //RTT mode，头尾全部计数，包含接受和发送的时间。
		  if(tx_vaild_out && (rtt_pn_num[7:0] == ((slot_txnum[6:0] + slot_rxnum[6:0])- 1'b1))) begin
		    rtt_pn_num[7:0]        <= 8'd0;
		  end
	      else if(tx_vaild_out) begin
	        rtt_pn_num[7:0]        <= rtt_pn_num[7:0] + 1'b1;
		  end
		  else begin
		    rtt_pn_num[7:0]        <= rtt_pn_num[7:0]; 
		  end
	  end
  end
end

////(2-4-4)loop pn pattern switch	
always@(posedge mcbsp_slaver_clkx or posedge mcbsp_rst_in)
begin
    if (mcbsp_rst_in)  begin
	    loop_pn_num[9:0]            <= 10'd0;
	end
    else if(pn_pat_en) begin
      if (slot_slotmode[1:0] == 2'd3) begin
		  if(tx_vaild_out && (loop_pn_num[9:0] == ((slot_txnum[8:0] + slot_rxnum[8:0])- 1'b1)))begin//tx+rx=444+444=888;
		    loop_pn_num[9:0]        <= 10'd0;
		  end
	      else if(tx_vaild_out) begin
	        loop_pn_num[9:0]        <= loop_pn_num[9:0] + 1'b1;
		  end
		  else begin
		    loop_pn_num[9:0]        <= loop_pn_num[9:0]; 
		  end
	  end
  end
end

////(2-4-5)tx/rx_wr align at tx/rx_addr
always@(posedge mcbsp_slaver_clkx or posedge mcbsp_rst_in)
begin
    if (mcbsp_rst_in)  begin
		pn_addr_rx_wr_dly[9:0]      <= 10'd0;
		pn_addr_tx_wr_dly[9:0]      <= 10'd0;
	end
    else  begin
		pn_addr_rx_wr_dly[9:0]      <= pn_addr_rx_wr[9:0];
		pn_addr_tx_wr_dly[9:0]      <= pn_addr_tx_wr[9:0];
	end
end

//////////////////////////////////////////////////////////////////////////////////
//// (3) DL/TX RAM ////
////tx data
ccsk_pat_ram_buffer   u_ccsk_pat_ram_buffer
   (
	.clka(mcbsp_slaver_clkx),
	.wea(ccsk_pat_wr),
	.addra(ccsk_addr_wr[7:0]),  //ping-pang depth = 2^10=1024(512*2);A set of 4 number=256
	.dina(dsp_tx_data[31:0]),

	.clkb(logic_clk_in),
	.enb(tx_rd_en),
	.addrb(tx_addr_in[9:0]),	
	.doutb(dsp_ccsk_pat[7:0])
	
	);
	
////tx frequence pattern	
freq_hop_ram_buffer   u_tx_freq_hop_ram_buffer
   (
	.clka(mcbsp_slaver_clkx),
	.wea(freq_tx_wr),
	.addra(freq_addr_tx_wr_dly[7:0]),  //ping-pang depth = 2^10=1024(512*2);A set of 4 number=256
	.dina(dsp_tx_data[31:0]),

	.clkb(logic_clk_in),
	.enb(tx_freq_rd_en),
	.addrb(tx_freq_addr_in[9:0]),
	.doutb(dsp_tx_freq_hop[7:0]) //first[7:0]->[15:8]->[23:16]->[31:24]
	
	);
////rx frequence pattern		
freq_hop_ram_buffer   u_rx_freq_hop_ram_buffer
   (
	.clka(mcbsp_slaver_clkx),
	.wea(freq_rx_wr),
	.addra(freq_addr_rx_wr_dly[7:0]),  //ping-pang depth = 2^10=1024(512*2);A set of 4 number=256
	.dina(dsp_tx_data[31:0]),

	.clkb(logic_clk_in),
	.enb(1'b1),
	.addrb(rx_freq_pn_addr_in[9:0]), //ahead real 6.4us	
	.doutb(dsp_rx_freq_hop[7:0]) //first[7:0]->[15:8]->[23:16]->[31:24]
	
	);

////tx pn pattern	
pn_scram_ram_buffer   u_tx_pn_scram_ram_buffer
   (
	.clka(mcbsp_slaver_clkx),
	.wea(pn_tx_wr),
	.addra(pn_addr_tx_wr_dly[9:0]),  //ping-pang depth = 2^10=1024(512*2)
	.dina(dsp_tx_data[31:0]),

	.clkb(logic_clk_in),
	.enb(tx_rd_en),
	.addrb(tx_addr_in[9:0]),	
	.doutb(dsp_tx_pn_scram[31:0])
	
	);

////rx pn pattern	
pn_scram_ram_buffer   u_rx_pn_scram_ram_buffer
   (
	.clka(mcbsp_slaver_clkx),
	.wea(pn_rx_wr),
	.addra(pn_addr_rx_wr_dly[9:0]), //ping-pang depth = 2^10=1024(512*2)
	.dina(dsp_tx_data[31:0]),

	.clkb(logic_clk_in),
	.enb(1'b1), //(rx_freq_pn_rd_in), //rx_freq_pn_rd_in can't align at addr starting--------error
	.addrb(rx_freq_pn_addr_in[9:0]),	
	.doutb(dsp_rx_pn_scram[31:0])
	
	);

//////////////////////////////////////////////////////////////////////////////////
//// (4)  work parameter////
always@(posedge logic_clk_in)
begin
  if (logic_rst_in)  begin
     ju_status_en                        <= 1'b0;
  end
  else if((ju_status_cnt[3:0] == 4'd9) && tx_vaild) begin
     ju_status_en                        <= 1'b0;
  end
  else if((dsp_tx_data[31:0] == 32'h77778888) && tx_vaild)begin
     ju_status_en                        <= 1'b1;
  end
end	

always@(posedge logic_clk_in)
begin
  if (logic_rst_in)  begin
     ju_status_cnt[3:0]                  <= 4'd0;
  end
  else if((ju_status_cnt[3:0] == 4'd9) && tx_vaild) begin
     ju_status_cnt[3:0]                  <= 4'd0; 
  end
  else if(ju_status_en && tx_vaild)begin
     ju_status_cnt[3:0]                  <= ju_status_cnt[3:0] + 1'b1;
  end
end	

////systerm config parameter
always@(posedge logic_clk_in)
begin
  if (logic_rst_in)  begin
    slot_ntrindi[31:0]                   <= 32'd0;
  	slot_slotmode[31:0]                  <= 32'd0;
	slot_posi[31:0]                      <= 32'd0;    
	slot_clknum[31:0]                    <= 32'd1562499;
	slot_txposi[31:0]                    <= 32'd0;  
	slot_txnum[31:0]                     <= 32'd444;  
	slot_rxposi[31:0]                    <= 32'd0;  
	slot_rxnum[31:0]                     <= 32'd444;  
	slot_rfposi[31:0]                    <= 32'd0; 
	slot_unsync[31:0]                    <= 32'd1600000; 
  end
  else if(ju_status_en && tx_vaild)begin
     case(ju_status_cnt[3:0])
	 	4'd0: begin
		   slot_posi[31:0]               <= dsp_tx_data[31:0]; //32'd0; 
		end
		
		4'd1: begin
		   slot_clknum[31:0]             <= dsp_tx_data[31:0]; //32'd1562499; 
		end
		
	 	4'd2: begin
		   slot_ntrindi[31:0]            <= dsp_tx_data[31:0]; //32'd0; 
		end
		
	 	4'd3: begin
		   slot_slotmode[31:0]           <= dsp_tx_data[31:0]; //32'd2; //32'd0; //32'd3;
		end
		
		4'd4: begin
		   slot_txposi[31:0]             <= dsp_tx_data[31:0];//32'd1559528(1x tx_fir)=1562499-2970-1(real test);//32'd1559768(loop,no 1x fir)=1562499-2970+240-1(real test);
		end                                                                  //32'd1559738(tx_2x_fir)=1562499-(2600+160)-1(real test); ++4(modelsim)
		
		4'd5: begin
		   slot_txnum[31:0]              <= dsp_tx_data[31:0]; //32'd72; //32'd222;
		end
		
		4'd6: begin
		   slot_rxposi[31:0]             <= dsp_tx_data[31:0];
		end
		
		4'd7: begin
		   slot_rxnum[31:0]              <= dsp_tx_data[31:0];// //32'd72; //32'd222;
		end	
		
		4'd8: begin
		   slot_rfposi[31:0]             <= dsp_tx_data[31:0];//32'd1562297(no 1x fir)1559768+(2970(txdly)-240(firdly))-200(1us)-2(hardtim_dly)+1=1562297
		end	                                                                //32'd1562297(1x tx_fir)1559528+2970(txdly)-200(1us)-2(hardtim_dly)+1=1562297
		                                                                    //(2x tx_fir)1559738+2760(txdly)-200(1us)-2(hardtim_dly)+1=1562297
		4'd9: begin
		   slot_unsync[31:0]             <= dsp_tx_data[31:0];
		end	  
		
		default: begin
		   slot_ntrindi[31:0]            <= slot_ntrindi[31:0];
		   slot_slotmode[31:0]           <= slot_slotmode[31:0];
		   slot_posi[31:0]               <= slot_posi[31:0];    
		   slot_clknum[31:0]             <= slot_clknum[31:0]; 
		   slot_txposi[31:0]             <= slot_txposi[31:0];  
		   slot_txnum[31:0]              <= slot_txnum[31:0];   
		   slot_rxposi[31:0]             <= slot_rxposi[31:0];  
		   slot_rxnum[31:0]              <= slot_rxnum[31:0];
           slot_rfposi[31:0]             <= slot_rfposi[31:0]; 
		   slot_unsync[31:0]             <= slot_unsync[31:0]; 
		end	
	 endcase
  end
end	

always@(posedge logic_clk_in)
begin
  if(logic_rst_in) begin
    slot_ntrindi_reg[31:0]               <= 32'd0;
  	slot_slotmode_reg[31:0]              <= 32'd0; 
	slot_posi_reg[31:0]                  <= 32'd0;    
	slot_txposi_reg[31:0]                <= 32'd0;  
	slot_txnum_reg[31:0]                 <= 32'd444;
	slot_rxposi_reg[31:0]                <= 32'd0;  
	slot_rxnum_reg[31:0]                 <= 32'd444;
    slot_rfposi_reg[31:0]                <= 32'd0;	
	slot_unsync_reg[31:0]                <= 32'd1600000; 
  end
  else if (slot_switch_end)  begin //current and next slot switch/tx and rx switch //from logic clock
    slot_ntrindi_reg[31:0]               <= slot_ntrindi[31:0];
  	slot_slotmode_reg[31:0]              <= slot_slotmode[31:0];
	slot_posi_reg[31:0]                  <= slot_posi[31:0];    
	slot_txposi_reg[31:0]                <= slot_txposi[31:0];  
	slot_txnum_reg[31:0]                 <= slot_txnum[31:0];   
	slot_rxposi_reg[31:0]                <= slot_rxposi[31:0];  
	slot_rxnum_reg[31:0]                 <= slot_rxnum[31:0];  
	slot_rfposi_reg[31:0]                <= slot_rfposi[31:0];
	slot_unsync_reg[31:0]                <= slot_unsync[31:0]; 
  end
end

always@(posedge logic_clk_in)
begin
  if(logic_rst_in) begin 
	slot_clknum_reg[31:0]                <= 32'd1562499; 
  end
  else if (tx_slot_interrupt)  begin //every slot end,clknum update;otherwise current count is overwirted
	slot_clknum_reg[31:0]                <= slot_clknum[31:0]; 
  end
end

always@(posedge logic_clk_in)
begin
  if(logic_rst_in) begin 
	slot_txnum_div4[7:0]                <= 8'd111; //444/4=111 
  end
  else if(slot_txnum[1:0]!=2'b00)begin // mod 4 !=0 
	slot_txnum_div4[7:0]                <= (slot_txnum[9:0] >> 2'b10) + 1'b1; 
  end
  else begin
  	slot_txnum_div4[7:0]                <= (slot_txnum[9:0] >> 2'b10); 
  end
end

always@(posedge logic_clk_in)
begin
  if(logic_rst_in) begin 
	slot_rxnum_div4[7:0]                <= 8'd111; //444/4=111 
  end
  else if(slot_rxnum[1:0]!=2'b00)begin // mod 4 !=0 even if rxnum only equal 444 or 72 fro consistency
	slot_rxnum_div4[7:0]                <= (slot_rxnum[9:0] >> 2'b10) + 1'b1; 
  end
  else begin
  	slot_rxnum_div4[7:0]                <= (slot_rxnum[9:0] >> 2'b10);  //next rx length
  end
end

always@(posedge logic_clk_in)
begin
  if(logic_rst_in) begin 
	ju_slot_rxnum_div4[7:0]             <= 8'd111; //444/4=111 
  end
  else if(ju_slot_rxnum[1:0]!=2'b00)begin // mod 4 !=0 even if rxnum only equal 444 or 72 fro consistency
	ju_slot_rxnum_div4[7:0]             <= (ju_slot_rxnum[9:0] >> 2'b10) + 1'b1; 
  end
  else begin
  	ju_slot_rxnum_div4[7:0]             <= (ju_slot_rxnum[9:0] >> 2'b10); //current rx length
  end
end

always@(posedge logic_clk_in)
begin
  if(logic_rst_in) begin 
	ju_slot_rxnum_cur_div4[7:0]             <= 8'd111; //444/4=111 
  end
  else if(tx_slot_interrupt)begin 
	ju_slot_rxnum_cur_div4[7:0]             <= ju_slot_rxnum_div4[7:0]; 
  end
end


//// end identifier of dsp transmition
always@(posedge logic_clk_in)
begin
  if (logic_rst_in)  begin
     dsp_cfg_end                         <= 1'b0;
  end 
  else if(delay_end_cnt[31:0] == DELAY_COUNT[31:0])begin                             
     dsp_cfg_end                         <= 1'b0;
  end  
  else if((dsp_tx_data[31:0] == 32'h5A5A5A5A) && tx_vaild)begin
     dsp_cfg_end                         <= 1'b1;
  end                                    
end	


//////////////////////////////////////////////////////////////////////////////////
//// (5) UL/RX RAM read address logic ////
////(5-0) mcbsp enable logic according to rx_interrupt
always@(posedge logic_clk_in)    //test with dsp need uncomment
begin
  if (logic_rst_in)  begin
     rx_dsp_rd_interrupt                 <= 1'b0;
  end
  else if((dsp_tx_data[31:0] == 32'h3C3C3C3C) && tx_vaild)begin
     rx_dsp_rd_interrupt                 <= 1'b1;
  end
  else begin
     rx_dsp_rd_interrupt                 <= 1'b0;
  end
end	

////////////////default fpga send data
// always@(posedge logic_clk_in)    
// begin
  // if (logic_rst_in)  begin
     // rx_rd_interrupt                     <= 1'b0;
  // end
  // else if(mif_dsp_fpga_source_sel == 1'b1)begin
     // rx_rd_interrupt                     <= rx_dsp_rd_interrupt;
  // end
  // else begin
     // rx_rd_interrupt                     <= rx_slot_interrupt;
  // end
// end	

////////////////default dsp send data
always@(posedge logic_clk_in)    
begin
  if (logic_rst_in)  begin
     rx_rd_interrupt                     <= 1'b0;
  end
  else if(mif_dsp_fpga_source_sel == 1'b1)begin
     rx_rd_interrupt                     <= rx_slot_interrupt;
  end
  else begin
     rx_rd_interrupt                     <= rx_dsp_rd_interrupt;
  end
end	

//// observation point ////
// always@(posedge logic_clk_in)
// begin
   // if (logic_rst_in)   begin
	   // rx_rd_interrupt_gpio              <= 1'b0;
   // end
   // else if (rd_interrupt_gpio_cnt[8:0]  == 9'd398)  begin   // 7.8125ms = one dsp slot for last 395ns 
	   // rx_rd_interrupt_gpio              <= 1'b0;
   // end                                   
   // else if(rx_rd_interrupt)begin         
	   // rx_rd_interrupt_gpio              <= 1'b1;
    // end
// end

// always@(posedge logic_clk_in)
// begin
   // if (logic_rst_in)   begin
	   // rd_interrupt_gpio_cnt[8:0]        <= 9'd0;
   // end  
   // else if (rd_interrupt_gpio_cnt[8:0]  == 9'd398)  begin  
	   // rd_interrupt_gpio_cnt[8:0]        <= 9'd0;
   // end
   // else if(rx_rd_interrupt_gpio)begin
	   // rd_interrupt_gpio_cnt[8:0]        <= rd_interrupt_gpio_cnt[8:0]  + 1'b1;
    // end
// end

always@(posedge logic_clk_in)
begin
  if (logic_rst_in)  begin
     rx_mcbsp_interrupt                  <= 1'b0;
  end                                    
  else if(rx_rd_interrupt)begin
     rx_mcbsp_interrupt                  <= ~rx_mcbsp_interrupt; //pulse->level for sampling in cross clock domain
  end                                    
end	                                     
                                         
////(5-1) Cross Clock Domain             
always@(posedge logic_clk_in)            
begin                                    
  if (logic_rst_in)  begin               
     rx_ram_en_reg[2:0]                  <= 3'd0;
  end 
  else begin                             
     rx_ram_en_reg[2:0]                  <= {rx_ram_en_reg[1:0],rx_ram_addr_upd};
  end
end	

////(5-2)  rx ram read en
always@(posedge logic_clk_in)
begin
  if (logic_rst_in)  begin
     rx_ram_en                           <= 1'b0;
  end                               
  else if(rx_ram_en_reg[2:1] == 2'b01)begin                        
     rx_ram_en                           <= 1'b1; //occupy 1 logic clk
  end                                    
  else begin                             
     rx_ram_en                           <= 1'b0;
  end
end	

////(5-3) rx ram read addr
//ping-pang forbiding slot reset
//Receiving length is unknown, according to the maximum length(except sync code) + 4byte(toa/unsync)
always@(posedge logic_clk_in)
begin
  if(logic_rst_in) begin  //make sure power reset 
     rx_ram_addr[7:0]                    <= 8'd0;   
  end
  else if(rx_ram_en && (rx_ram_addr[7:0] == (rx_slot_data_length[7:0] - 1'b1))) begin  ////rx length+ 4byte(toa/unsync),intial process
     rx_ram_addr[7:0]                    <= 8'd128;    
  end
  else if(rx_ram_en && (rx_ram_addr[7:0] == (rx_slot_data_length[7:0] + 8'd127))) begin
     rx_ram_addr[7:0]                    <= 8'd0;
  end                                    
  else if(rx_ram_en)begin                
     rx_ram_addr[7:0]                    <= rx_ram_addr[7:0] + 1'b1; 
  end                                    
end	

//////////////////////////////////////////////////////////////////////////////////
//// (6) slot switch ////
////当前tx时隙数据从tx ram发送完毕
//always@(posedge logic_clk_in)
//begin
//  if(logic_rst_in) begin  
//     tx_chan_end	                     <= 1'b0;  
//  end
//  else if (tx_rd_en && (tx_addr_in[9:0] == {1'b0,(ju_slot_txnum[8:0]  - 1'b1)})) begin
//     tx_chan_end	                     <= 1'b1;	                                
//	end 
//  else if(tx_rd_en &&(tx_addr_in[9:0] == (ju_slot_txnum[8:0]  + 9'd511))) begin
//     tx_chan_end	                     <= 1'b1;	
//  end	                                       
//  else begin                                  
//     tx_chan_end	                     <= 1'b0;	
//  end
//end

always@(posedge logic_clk_in)
begin
  if(logic_rst_in) begin  
     tx_chan_end_reg	                     <= 1'b0;  
  end
  else if (tx_rd_en && (tx_addr_in[9:0] == {1'b0,(ju_slot_txnum[8:0]  - 1'b1)})) begin
     tx_chan_end_reg	                     <= 1'b1;	                                
	end 
  else if(tx_rd_en &&(tx_addr_in[9:0] == (ju_slot_txnum[8:0]  + 9'd511))) begin
     tx_chan_end_reg	                     <= 1'b1;	
  end                  
  else begin                                  
     tx_chan_end_reg	                     <= 1'b0;	
  end
end
///-------------------------------2016/1/26 17:19:15
//--在配置短帧时，FPGA会在4.275MS结束前更新参数，导致下一个RTT时隙错乱，设备即出网。
//故在已知DSP短帧固定为258个13us个数时，对结束信号做延迟处理.
//延迟量为：(71*13)*200Mhz = 184600 clk；
//延迟位置：((71+258)*13)*200mhz = 855400 clk * 5ns = 4.277ms >  4.275
always@(posedge logic_clk_in)
begin
  if(logic_rst_in)
     tx_chan_end_dlen <= 1'd0;
  else if(tx_chan_end)
     tx_chan_end_dlen <= 1'd0;
  else if(ju_slot_txnum == 9'd258)begin
          if(tx_chan_end_reg)
            tx_chan_end_dlen <= 1'd1; 
          else
            tx_chan_end_dlen <= tx_chan_end_dlen;
  end
  else 
     tx_chan_end_dlen <= tx_chan_end_dlen;
end
///-------------------------------    
always@(posedge logic_clk_in)
begin
  if(logic_rst_in)
     tx_end_cnt <= 18'd0;
  else if(tx_chan_end_dlen)
     tx_end_cnt <= tx_end_cnt + 18'd1;
  else
     tx_end_cnt <= 18'd0;
end
///-------------------------------    
always@(posedge logic_clk_in)
begin
  if(logic_rst_in)
     tx_chan_end <= 1'd0;
  else if(ju_slot_txnum == 9'd258 || tx_chan_end_dlen)begin//-----
          if(tx_end_cnt == 18'd184599)
             tx_chan_end <= 1'd1;
          else
             tx_chan_end <= 1'd0;
  end
  else
     tx_chan_end <= tx_chan_end_reg;
end
//----------------------------------------------------
////当前rx时隙数据接收完成至rx ram，给DSP mcbsp发送数据才开始
////对于初始配置考虑，认为处于unsync状态，也会给dsp发送数据上报
//// 若使用上面的逻辑，会出现rx_chan_end持续到下一个时隙中，使得88887777一发送完就时隙切换
////rx_chan_end开始存放数据至rx ram时，认为上行处理完毕；如等所有数据存放至ram，时刻有些晚
always@(posedge logic_clk_in)
begin
  if(logic_rst_in) begin  
     rx_chan_end	                     <= 1'b0; //considering initial process
  end 
  else if(rx_ram_en && (rx_ram_addr[7:0] == 8'd0))begin                
     rx_chan_end	                     <= 1'b1;	 
  end 
  else if(rx_ram_en && (rx_ram_addr[7:0] == 8'd128))begin                
     rx_chan_end	                     <= 1'b1;	 
  end 
  else begin
     rx_chan_end	                     <= 1'b0;
  end  
end	

//////////////for j0.0 and nomal slot combination
always@(posedge logic_clk_in)
begin
  if(logic_rst_in) begin  
     cur_slot_end	                     <= 1'b1; //considering initial process
  end 
  else if(ju_unsync_timer[31:0] == 32'd1600000)begin //j0.0 //32'h00186A00
     cur_slot_end	                     <= 1'b1;
  end  
  else if(ju_unsync_timer[31:0] == 32'd600000)  begin // ntr rtt 3ms //32'h000927C0
     cur_slot_end	                     <= tx_chan_end;
  end
  else if(ju_unsync_timer[31:0] == 32'd1400000)  begin // ju rtt 7ms //32'h00155CC0
     cur_slot_end	                     <= rx_chan_end;
  end
  else if(ju_unsync_timer[31:0] == 32'd855000)  begin // tx/rx 4.275ms //32'h000D0BD8
     cur_slot_end	                     <= (rx_chan_end || tx_chan_end);
  end
end	


////当下一时隙数据下发完成dsp_cfg_end，且当前时隙处理完成后tx/rx_chan_end，才开始生效新时隙参数
always@(posedge logic_clk_in)
begin
  if(logic_rst_in) begin  
     delay_cnt_en                        <= 1'b0;    
  end
  else if(delay_end_cnt[31:0] == DELAY_COUNT[31:0]) begin
     delay_cnt_en                        <= 1'b0;      
  end
  else if(dsp_cfg_end && cur_slot_end)begin
     delay_cnt_en                        <= 1'b1;         
  end
end	

always@(posedge logic_clk_in)
begin
  if(logic_rst_in) begin  
     delay_end_cnt[31:0]                 <= 32'd0;      
  end
  else if(delay_end_cnt[31:0] == DELAY_COUNT[31:0]) begin
     delay_end_cnt[31:0]                 <= 32'd0;      
  end
  else if(delay_cnt_en)begin
     delay_end_cnt[31:0]                 <= delay_end_cnt[31:0] + 1'b1;         
  end
end	

////参数生效
always@(posedge logic_clk_in)
begin
  if(logic_rst_in) begin  
     slot_switch_end                     <= 1'b0;    
  end
  else if(delay_end_cnt[31:0] == DELAY_COUNT[31:0]) begin
     slot_switch_end                     <= 1'b1;      
  end
  else begin
     slot_switch_end                     <= 1'b0;         
  end
end	

always@(posedge logic_clk_in)
begin
  if(logic_rst_in) begin  
     slot_switch_end_dly                 <= 1'b0;    
  end
  else begin
     slot_switch_end_dly                 <= slot_switch_end;         
  end
end	

//////////////////////////////////////////////////////////////////////////////////
//// (7) NTR rtt response ////	
//// No matter JU or RTT，length of tx data from dsp is 72,but NTR RTT response will overwrite 32 header
always@(posedge mcbsp_slaver_clkx or posedge mcbsp_rst_in)
begin
  if (mcbsp_rst_in)  begin
     ccsk_nrt_rsp_en                     <= 1'b0;
  end                                    
  else if(ccsk_pat_end)begin             
     ccsk_nrt_rsp_en                     <= 1'b0;
  end
  else if((dsp_tx_data[31:0] == 32'h5555AAAA) && tx_vaild_out)begin
     ccsk_nrt_rsp_en                     <= 1'b1;
  end
end
//-----------------------------------------------------------------
//always@(posedge mcbsp_slaver_clkx or posedge mcbsp_rst_in)
//begin
//  if (mcbsp_rst_in)  begin
//     rtt_rsp_ram_ini[7:0]                <= 8'd0;
//  end                               
//  else if(ccsk_addr_wr[7:0] == 8'd128)begin  //40 pulse/4=10 && 32 pulse/4=8,sum=18                  
//     rtt_rsp_ram_ini[7:0]                <= 8'd10; 
//  end
//  else if(ccsk_addr_wr[7:0] == 8'd0)begin //40 pulse/4=10 && 32 pulse/4=8,sum=18                  
//     rtt_rsp_ram_ini[7:0]                <= 8'd138; 
//  end
//end
//-------------------------------------------------------------
//---------------------------2016/1/29 14:53:57
always@(posedge mcbsp_slaver_clkx or posedge mcbsp_rst_in)
begin
  if (mcbsp_rst_in)
     ccsk_vs_rtt_en <= 1'd0;
  else if(ju_slot_slotmode[1:0] == 2'd2)begin //RTT  时隙
         if((dsp_tx_data[31:0] == 32'h66669999) && tx_vaild_out)
            ccsk_vs_rtt_en <= 1'b1;
         else 
            ccsk_vs_rtt_en <= ccsk_vs_rtt_en;
  end
  else 
     ccsk_vs_rtt_en <= 1'b0;
end
//----------------------------------------------------------
always@(posedge mcbsp_slaver_clkx or posedge mcbsp_rst_in)
begin
  if (mcbsp_rst_in)
     rtt_rsp_ram_ini[7:0] <= 8'd0;
  else if(ccsk_vs_rtt_en)begin
          if(ccsk_addr_wr[7:0] == 8'd128)
             rtt_rsp_ram_ini[7:0] <= 8'd138;
          else if(ccsk_addr_wr[7:0] == 8'd0)
             rtt_rsp_ram_ini[7:0] <= 8'd10;
          else
             rtt_rsp_ram_ini[7:0] <= rtt_rsp_ram_ini[7:0];
  end
  else if(ccsk_addr_wr[7:0] == 8'd128)
     rtt_rsp_ram_ini[7:0] <= 8'd10;
  else if(ccsk_addr_wr[7:0] == 8'd0)
     rtt_rsp_ram_ini[7:0] <= 8'd138; 
  else
     rtt_rsp_ram_ini[7:0] <= rtt_rsp_ram_ini[7:0];
end  
//--------------------------------------------------------------    

always@(posedge mcbsp_slaver_clkx or posedge mcbsp_rst_in)
begin
  if (mcbsp_rst_in)  begin
     nrt_rsp_en_reg[1:0]                 <= 2'd0;
  end                               
  else begin                  
     nrt_rsp_en_reg[1:0]                 <= {nrt_rsp_en_reg[0],ccsk_nrt_rsp_en}; 
  end
end
//此处判定DSP是否正确收到RTT，错误则发FFFFFFFF，FPGA不用发送。
always@(posedge logic_clk_in)
begin
   if (logic_rst_in)   begin
	  nrt_rtt_rsp_ng                    <= 1'b0;
	end  
	else if(tx_data_en_window_dly[1:0] == 2'b10)begin //falling
	  nrt_rtt_rsp_ng                    <= 1'b0;  
	end	
	else if(dsp_tx_data[31:0] == 32'hFFFFFFFF)begin    //dsp send FFFFFFFF after 5555aaaa  
	  nrt_rtt_rsp_ng                    <= 1'b1;
	end
end

always@(posedge logic_clk_in)
begin
   if (logic_rst_in)   begin
	  tx_data_en_window_dly[1:0]        <= 2'b00;
	end  
	else begin            
	  tx_data_en_window_dly[1:0]        <= {tx_data_en_window_dly[0],tx_data_en_window_in};
	end
end

//////////////////////////////////////////////////////////////////////////////////
//// (8) mcbsp1 loopback  ////
////(8-0) mcbsp1 loopback wr ram logic
always@(posedge mcbsp_slaver_clkx or posedge mcbsp_rst_in)
begin
  if (mcbsp_rst_in)  begin //make sure power reset 
       mcbsp1_loop_wr_addr[6:0]          <= 7'd0; 
  end
  else if((mcbsp1_loop_wr_addr[6:0] == (slot_txnum_div4[6:0] - 1'b1)) && mcbsp1_loop_wr) begin
       mcbsp1_loop_wr_addr[6:0]          <= 7'd0;
  end
  else if(mcbsp1_loop_wr)begin
       mcbsp1_loop_wr_addr[6:0]          <= mcbsp1_loop_wr_addr[6:0] + 1'b1;
  end 
end

always@(posedge logic_clk_in)
begin
  if (logic_rst_in)  begin 
       mcbsp1_loop_int          <= 1'b0; 
  end
  else if((mcbsp1_loop_wr_addr[6:0] == (slot_txnum_div4[6:0] - 1'b1)) && tx_vaild)begin
       mcbsp1_loop_int          <= 1'b1; 
  end
  else begin
       mcbsp1_loop_int          <= 1'b0; 
  end
end

///////////mcbsp1 loop rx slot intterrupt to dsp)
always@(posedge logic_clk_in)
begin
  if (logic_rst_in)  begin 
       mcbsp1_loop_rx_interrupt          <= 1'b0; 
  end
  else if(mcbsp1_loop_int_cnt[8:0] == 9'd398)begin
       mcbsp1_loop_rx_interrupt          <= 1'b0; 
  end
  else if(mcbsp1_loop_int)begin
       mcbsp1_loop_rx_interrupt          <= 1'b1;   
  end
end

always@(posedge logic_clk_in)
begin
  if (logic_rst_in)  begin 
       mcbsp1_loop_int_cnt[8:0]          <= 9'd0; 
  end
  else if(mcbsp1_loop_int_cnt[8:0] == 9'd398)begin
       mcbsp1_loop_int_cnt[8:0]          <= 9'd0; 
  end
  else if(mcbsp1_loop_rx_interrupt)begin
       mcbsp1_loop_int_cnt[8:0]          <= mcbsp1_loop_int_cnt[8:0] + 1'b1; 
  end
end

////(8-1) mcbsp1 loopback wr ram logic
always@(posedge logic_clk_in)
begin
  if(logic_rst_in) begin  
     mcbsp1_loop_rd_addr[6:0]            <= 7'd0;   
  end
  else if(mcbsp1_loop_rd && (mcbsp1_loop_rd_addr[6:0] == (slot_rxnum_div4[6:0] - 1'b1))) begin
       mcbsp1_loop_rd_addr[6:0]          <= 7'd0;
  end                                    
  else if(mcbsp1_loop_rd)begin                
       mcbsp1_loop_rd_addr[6:0]          <= mcbsp1_loop_rd_addr[6:0] + 1'b1; 
  end  
end	


mcbsp1_loop_buffer   u_mcbsp1_loop_buffer
   (
	.clka(mcbsp_slaver_clkx),
	.wea(mcbsp1_loop_wr),
	.addra(mcbsp1_loop_wr_addr[6:0]),  
	.dina(dsp_tx_data[31:0]),

	.clkb(logic_clk_in),
	.enb(mcbsp1_loop_rd),
	.addrb(mcbsp1_loop_rd_addr[6:0]),	
	.doutb(mcbsp1_loop_rd_data[31:0])	
	);
	

	
//////////////////////////////////////////////////////////////////////////////////
////mcbsp0 port////
mcbsp_dsp_zero_top uut 
    (
    .mcbsp_clk_in(mcbsp_clk_in), 
    .mcbsp_rst_in(mcbsp_rst_in), 
    .port_clk_10mhz(mcbsp_clk_in), 
    .mcbsp_slaver_clkx(mcbsp0_slaver_clkx), 
    .mcbsp_slaver_mosi(mcbsp0_slaver_mosi), 
    .mcbsp_slaver_fsx(mcbsp0_slaver_fsx), 
    .mcbsp_master_clkr(mcbsp0_master_clkr), 
    .mcbsp_master_fsr(mcbsp0_master_fsr), 
    .mcbsp_master_miso(mcbsp0_master_miso), 
    .rev_work_mode(rev_work_mode[3:0]), 
	.work_mode_vld(work_mode_vld),
    .port_red_stat    (port_red_stat     ), 
    .port_data_valid  (port_data_valid   ), 					//port_data_valid
    .port_red_data    (port_red_data     ), 						//port_red_data
    
    .port_wr_en       (port_wr_en        ), 
    .port_wr_data     (port_wr_data      ), 
    
    .dsp_ctr_uart_en  (dsp_ctr_uart_en   ),
    .dsp_ctr_uart_data(dsp_ctr_uart_data[63:0]),
    .debug_signal(debug_signal_zero_top)
	);
	

//////////////////////////////////////////////////////////////////////////////////
//// (8) debug ////
//////tx slot
assign  debug_tx_signal[1:0]              = slot_slotmode[1:0];
assign  debug_tx_signal[2]                = rx_rd_interrupt;
assign  debug_tx_signal[3]                = tx_mcbsp_interrupt;
assign  debug_tx_signal[4]                = tx_vaild_out;
assign  debug_tx_signal[5]                = tx_vaild;
assign  debug_tx_signal[37:6]             = dsp_tx_data[31:0]; //dsp_tx_pn_scram[31:0]; delay_end_cnt[31:0]

assign  debug_tx_signal[38]               = ccsk_pat_en;
assign  debug_tx_signal[39]               = ccsk_pat_end;
assign  debug_tx_signal[47:40]            = ccsk_addr_wr[7:0];
assign  debug_tx_signal[48]               = ccsk_pat_wr;
             
assign  debug_tx_signal[49]               = freq_hop_en;
assign  debug_tx_signal[50]               = freq_cfg_end;
assign  debug_tx_signal[58:51]            = freq_addr_tx_wr_dly[7:0];
assign  debug_tx_signal[59]               = freq_tx_wr;
            
assign  debug_tx_signal[60]               = pn_pat_en;
assign  debug_tx_signal[61]               = pn_cfg_end;
assign  debug_tx_signal[71:62]            = pn_addr_tx_wr_dly[9:0]; 
assign  debug_tx_signal[72]               = pn_tx_wr;
          
assign  debug_tx_signal[73]               = tx_rd_en;
assign  debug_tx_signal[83:74]            = tx_addr_in[9:0];
assign  debug_tx_signal[91:84]            = dsp_ccsk_pat[7:0];
assign  debug_tx_signal[99:92]            = dsp_tx_freq_hop[7:0];
             
assign  debug_tx_signal[100]              = ju_status_en;
assign  debug_tx_signal[104:101]          = ju_status_cnt[3:0]; 
assign  debug_tx_signal[105]              = rx_chan_end;//dsp_cfg_end;
              
assign  debug_tx_signal[106]              = slot_switch_end;
assign  debug_tx_signal[107]              = tx_chan_end;
assign  debug_tx_signal[108]              = delay_cnt_en;
assign  debug_tx_signal[109]              = dsp_cfg_end;
          
assign  debug_tx_signal[110]              = ccsk_nrt_rsp_en;
assign  debug_tx_signal[118:111]          = rtt_rsp_ram_ini[7:0];
assign  debug_tx_signal[127:119]          = ju_slot_txnum[8:0];//slot_txnum[8:0];//loop_freq_num[7:0]; //rtt_freq_num[5:0]

assign  debug_tx_signal[159:128]          = dsp_tx_pn_scram[31:0];//ju_slot_txposi[31:0];
assign  debug_tx_signal[160]              = mif_dsp_fpga_source_sel;
assign  debug_tx_signal[164:161]          = mif_work_mode[3:0]; 
assign  debug_tx_signal[172:165]          = ju_unsync_timer[15:8];//ju_unsync_timer[31:0];
assign  debug_tx_signal[173]              = tx_data_en_window_in;
assign  debug_tx_signal[174]              = nrt_rtt_rsp_ng_out;
assign  debug_tx_signal[175]              = cur_slot_end;
assign  debug_tx_signal[177:176]          = ju_slot_slotmode[1:0];
assign  debug_tx_signal[179:178]          = nrt_rsp_en_reg[1:0];
assign  debug_tx_signal[181:180]          = slot_slotmode_sel[1:0];
assign  debug_tx_signal[189:182]          = slot_txnum_div4_sel[7:0];
assign  debug_tx_signal[197:190]          = ccsk_pat_en_cnt[7:0];
assign  debug_tx_signal[198]              = ccsk_vs_rtt_en;
assign  debug_tx_signal[199]              = 1'd0;


assign  debug_tx1_signal[31:0]          = slot_timer[31:0];
assign  debug_tx1_signal[33:32]         = slot_slotmode_sel[1:0];
assign  debug_tx1_signal[35:34]         = ju_slot_slotmode[1:0];
assign  debug_tx1_signal[36]            = tx_rd_en;
assign  debug_tx1_signal[37]            = ccsk_pat_wr;
assign  debug_tx1_signal[38]            = ccsk_pat_en;
assign  debug_tx1_signal[48:39]         = tx_addr_in[9:0];
assign  debug_tx1_signal[49]            = slot_switch_end;
assign  debug_tx1_signal[81:50]         = dsp_tx_data[31:0];
assign  debug_tx1_signal[82]            = tx_vaild;

assign  debug_tx1_signal[90:83]         = rtt_rsp_ram_ini[7:0];
assign  debug_tx1_signal[91]            = ccsk_vs_rtt_en ;
assign  debug_tx1_signal[199:92]        = 150'd0;



//////rx slot
assign  debug_rx_signal[1:0]              = slot_slotmode[1:0];
assign  debug_rx_signal[2]                = tx_slot_interrupt;
assign  debug_rx_signal[3]                = tx_mcbsp_interrupt;
assign  debug_rx_signal[4]                = tx_vaild_out;
assign  debug_rx_signal[5]                = tx_vaild;
assign  debug_rx_signal[37:6]             = dsp_tx_data[31:0]; 
           
assign  debug_rx_signal[38]               = rx_slot_interrupt;
assign  debug_rx_signal[39]               = rx_rd_interrupt;
            
assign  debug_rx_signal[47:40]            = freq_addr_rx_wr_dly[7:0];  
assign  debug_rx_signal[48]               = freq_rx_wr;
             
assign  debug_rx_signal[58:49]            = pn_addr_rx_wr_dly[9:0]; 
assign  debug_rx_signal[59]               = pn_rx_wr;
        
assign  debug_rx_signal[69:60]            = rx_freq_pn_addr_in[9:0];
assign  debug_rx_signal[77:70]            = dsp_rx_freq_hop[7:0];
              
assign  debug_rx_signal[78]               = rx_ram_en;
assign  debug_rx_signal[87:79]            = {1'b0,rx_ram_addr[7:0]}; 
assign  debug_rx_signal[88]               = cur_slot_end;
           
assign  debug_rx_signal[89]               = ju_status_en;
assign  debug_rx_signal[93:90]            = ju_status_cnt[3:0]; 
assign  debug_rx_signal[94]               = tx_chan_end;
                                  
assign  debug_rx_signal[98:95]            = {2'd0,ju_slot_slotmode[1:0]};//work_mode_reg[3:0];
             
assign  debug_rx_signal[108:99]           = slot_rxnum[9:0]; //loop_pn_num[9:0]; //loop_freq_num[7:0]

assign  debug_rx_signal[109]              = slot_switch_end;
assign  debug_rx_signal[110]              = dsp_cfg_end;
assign  debug_rx_signal[111]              = delay_cnt_en;
assign  debug_rx_signal[112]              = logic_rst_in;
assign  debug_rx_signal[113]              = mcbsp_rst_in;

assign  debug_rx_signal[114]              = ccsk_pat_en;
assign  debug_rx_signal[115]              = ccsk_pat_end;
assign  debug_rx_signal[123:116]          = ccsk_addr_wr[7:0];
assign  debug_rx_signal[124]              = ccsk_pat_wr;
                        
assign  debug_rx_signal[125]              = pn_pat_en;
assign  debug_rx_signal[126]              = pn_cfg_end;
assign  debug_rx_signal[136:127]          = pn_addr_tx_wr_dly[9:0]; 
assign  debug_rx_signal[137]              = pn_tx_wr;

assign  debug_rx_signal[169:138]          = dsp_rx_pn_scram[31:0];//delay_end_cnt[31:0]; //dsp_slot_time[31:0];

assign  debug_rx_signal[179:170]          = {2'd0,rx_slot_data_length[7:0]};
assign  debug_rx_signal[189:180]          = {2'd0,ju_slot_rxnum_div4[7:0]};//slot_txnum[9:0];
assign  debug_rx_signal[197:190]          = slot_rxnum_div4[7:0];

assign  debug_rx_signal[198]              = rx_chan_end;
assign  debug_rx_signal[199]              = rx_dsp_rd_interrupt;

//////////////mcbsp1 loop signal
// assign  debug_rx_signal[1:0]              = slot_slotmode[1:0];
// assign  debug_rx_signal[2]                = tx_slot_interrupt;
// assign  debug_rx_signal[3]                = tx_mcbsp_interrupt;
// assign  debug_rx_signal[4]                = tx_vaild_out;
// assign  debug_rx_signal[5]                = tx_vaild;
// assign  debug_rx_signal[37:6]             = dsp_tx_data[31:0]; 
           
// assign  debug_rx_signal[38]               = rx_slot_interrupt;
// assign  debug_rx_signal[39]               = mcbsp1_loop_rx_interrupt;
            
// assign  debug_rx_signal[47:40]            = {1'b0,mcbsp1_loop_wr_addr[6:0]};
// assign  debug_rx_signal[48]               = mcbsp1_loop_wr; 
             
// assign  debug_rx_signal[56:49]            = ccsk_pat_en_cnt[7:0];      
// assign  debug_rx_signal[64:57]            = ccsk_pat_end_cnt[7:0];
// assign  debug_rx_signal[72:65]            = loop_int_cnt[7:0];
// assign  debug_rx_signal[77:73]            = 5'd0;
              
// assign  debug_rx_signal[78]               = rx_ram_en;
// assign  debug_rx_signal[88:79]            = {2'b00,rx_ram_addr[7:0]}; 
           
// assign  debug_rx_signal[89]               = work_mode_vld;
// assign  debug_rx_signal[93:90]            = rev_work_mode[3:0]; 
// assign  debug_rx_signal[94]               = rx_chan_end;
                                  
// assign  debug_rx_signal[98:95]            = work_mode_reg[3:0];
             
// assign  debug_rx_signal[99]               = rx_rd_interrupt;
// assign  debug_rx_signal[100]              = ccsk_pat_en;
// assign  debug_rx_signal[101]              = ccsk_pat_end;
// assign  debug_rx_signal[102]              = ccsk_pat_wr;
// assign  debug_rx_signal[103]              = logic_rst_in;
// assign  debug_rx_signal[104]              = mcbsp_rst_in;
// assign  debug_rx_signal[105]              = mcbsp1_loop_int;
// assign  debug_rx_signal[106]              = 1'b0;
// assign  debug_rx_signal[107]              = 1'b0;
// assign  debug_rx_signal[108]              = 1'b0;


// assign  debug_rx_signal[109]              = mcbsp1_loop_rd;
// assign  debug_rx_signal[118:110]          = {2'b0,mcbsp1_loop_rd_addr[6:0]};
// assign  debug_rx_signal[126:119]          = mcbsp1_loop_rd_data[7:0];

// assign  debug_rx_signal[127]              = 1'b0;

// assign  debug_rx_signal[199:128]          = 40'd0;


/////mcbsp
assign  debug_mcbsp_signal[127:0]         = {rx_rd_interrupt,debug_mcbsp[126:0]};

assign	debug_mcbsp0_signal[127:0]		  =	debug_signal_zero_top[127:0];






//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
endmodule
