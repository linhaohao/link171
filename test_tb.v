`timescale 1ns / 1ps

module data_process_top_tb;

//sys_interface;
reg                 reset = 1'b0;
reg                 clk_200M_in = 1'b0;
reg                 clk_dac50M_in = 1'b1;
                    
reg                 clk_5M_in = 1'b0; 
reg [7:0]           clk_div_cnt = 8'd0;
                    
reg                 clk_25M_in = 1'b0; 
reg [7:0]           clk_25div_cnt = 8'd0;

reg                 clk_50M_in = 1'b0; 
reg [7:0]           clk_50div_cnt = 8'd0;
                    
reg                 cfg_spi_clk = 1'b0; 
reg [7:0]           clk_10div_cnt = 8'd0;
                    
// tx process logic
wire                dl_rd_en;
wire [9:0]          dl_addr_out; 
wire                dl_freq_rd_en;   
wire [9:0]          dl_freq_addr_out; 
wire                dl_data_dac_en;
wire                dac_txenable;
wire                dl_data_dac_window;
wire [31:0]         dl_dsp_to_dac;

wire                dl_add9957_freq_en;
wire [31:0]         dl_add9957_freq;

wire[7:0]           data_to_rf_freq;
wire                tx_end_out;
wire                tx_rx_switch_out;

wire                nrt_rtt_rsp_ng_out;
wire                tx_data_en_window_out;
                   
wire[9:0]           rx_freq_pn_addr_out;
wire                rx_freq_pn_rd_out;
wire[7:0]           rx_ram_addr_out;
wire                rx_ram_rd_en;
wire[31:0]          rx_ram_data_out;

wire[7:0]           dsp_ccsk_pat;
wire[7:0]           dsp_tx_freq_hop;
wire[7:0]           dsp_rx_freq_hop;
wire[31:0]          dsp_tx_pn_scram;
wire[31:0]          dsp_rx_pn_scram;

wire[3:0]           ju_work_mode;
wire[31:0]          ju_slot_ntrindi; 
wire[31:0]          ju_slot_slotmode; 
wire[31:0]          ju_slot_posi;              
wire[31:0]          ju_slot_clknum;                     
wire[31:0]          ju_slot_txposi;            
wire[31:0]          ju_slot_txnum;             
wire[31:0]          ju_slot_rxposi;            
wire[31:0]          ju_slot_rxnum; 
wire[31:0]          ju_slot_rfposi;
wire[31:0]          ju_unsync_timer;
wire                ju_slot_switch;

wire                mcbsp_slaver_clkx;	 
wire                mcbsp_slaver_fsx;	 
wire                mcbsp_slaver_mosi;

wire                mcbsp_master_clkr;	
wire                mcbsp_master_fsr;	
wire                mcbsp_master_miso;

reg [17:0]          slaver_count = 18'd0; //18'b100110100110100011;
reg [31:0]          slaver_reg = 32'd0;
reg                 slaver_data = 1'b0;

wire[31:0]          slaver_out;

wire  [31:0]        ju_net_slot;
wire                tx_slot_interrupt;
wire                tx_slot_dsp_interrupt;
wire                rx_slot_interrupt;
wire                rx_data_dsp_interrupt;
wire                mcbsp1_loop_int_out;

reg                 timing_ctl = 1'b0;
 
reg                 tx_mcbsp_interrupt        = 1'b0;  
reg [2:0]           mcbsp_slaver_en_reg       = 3'd0;  
reg                 mcbsp_slaver_en           = 1'b0;
reg [7:0]           start_en_cnt              = 8'd0; 
reg                 start_en                  = 1'b0;

reg                 spi_cnt_en = 1'b0;
reg [16:0]          spi_count  = 17'd0;
reg [31:0]          spi_reg    = 32'd0;
reg                 spi_data   = 1'b0;
reg                 spi_cs     = 1'b1;

wire[31:0]          spi_out;

wire  [199:0]       debug_dsp_tx;
wire  [199:0]       debug_dsp_rx;
wire  [127:0]       debug_dsp_mcbsp0;
wire  [127:0]       debug_dsp_mcbsp;
wire  [199:0]       debug_txpro_signal;
wire  [199:0]       debug_rxpro_dec; 
wire  [199:0]       debug_rxpro_fsm; 
wire  [199:0]       debug_rxpro_ccsk;
wire  [127:0]       debug_sync_timing;
wire  [127:0]       debug_hard_timing;
wire  [127:0]       debug_bloop_signal;
wire  [199:0]       debug_rxpro_dds;
wire  [199:0]       debug_rxpro_fir;
wire  [199:0]       debug_rxpro_sync;   

wire[2:0]           tx_chan_sel_p; 
wire[2:0]           tx_chan_sel_n; 
                    
wire[3:0]           tx_lo_en_p;
wire[3:0]           tx_lo_en_n;
                    
wire[1:0]           tx_carrier_sel_p;
wire[1:0]           tx_carrier_sel_n;

wire                gpio_int;

wire  [7:0]         slot_statc_cnt_out;
wire                unsync_flag_out;

////////////////////////////clock configuration////////////////////////////
parameter           counter_step        = 8'd1;  // 2*Tclk=10ns

parameter CLK_200M_DELAY = 5; //200MHz  cycle=5ns
always #(2.5)      clk_200M_in = ~clk_200M_in;

parameter CLK_dac50M_DELAY = 20; //25MHz  cycle=20ns
always #(10)      clk_dac50M_in = ~clk_dac50M_in;

	
initial begin
	// Initialize Inputs
	clk_200M_in = 0;
	clk_dac50M_in = 1;
    reset = 0;
	#15;
	reset = 1;
	#5;
	reset = 0;
	#5;
	timing_ctl = 1;
	#5;
	timing_ctl = 0;
end

always @ (posedge clk_200M_in)	begin
if(clk_div_cnt == 8'd39)
   clk_div_cnt <= 8'd0; 
else 
   clk_div_cnt <= clk_div_cnt + 1'b1;  
end	

always @ (posedge clk_200M_in)	begin
if(clk_div_cnt <= 8'd19)
   clk_5M_in <= 1'b1; 
else
   clk_5M_in <= 1'b0; 
end

always @ (posedge clk_200M_in)	begin
if(clk_25div_cnt == 8'd7)
   clk_25div_cnt <= 8'd0; 
else 
   clk_25div_cnt <= clk_25div_cnt + 1'b1;  
end	

always @ (posedge clk_200M_in)	begin
if(clk_25div_cnt <= 8'd3)
   clk_25M_in <= 1'b1; 
else
   clk_25M_in <= 1'b0; 
end

always @ (posedge clk_200M_in)	begin
if(clk_50div_cnt == 8'd3)
   clk_50div_cnt <= 8'd0; 
else 
   clk_50div_cnt <= clk_50div_cnt + 1'b1;  
end	

always @ (posedge clk_200M_in)	begin
if(clk_50div_cnt <= 8'd1)
   clk_50M_in <= 1'b1; 
else
   clk_50M_in <= 1'b0; 
end

always @ (posedge clk_200M_in)	begin
if(clk_10div_cnt == 8'd9) //20M
   clk_10div_cnt <= 8'd0; 
else 
   clk_10div_cnt <= clk_10div_cnt + 1'b1;  
end	

always @ (posedge clk_200M_in)	begin
if(clk_10div_cnt <= 8'd4)
   cfg_spi_clk <= 1'b1; 
else
   cfg_spi_clk <= 1'b0; 
end



////////interrupt mode///////////////////
/////tx intterupt  for constiant send data to fpga
always@(posedge clk_200M_in)
begin
  if (reset)  begin
     tx_mcbsp_interrupt               <= 1'b0;
  end                                 
  else if(tx_slot_interrupt)begin     
     tx_mcbsp_interrupt               <= ~tx_mcbsp_interrupt; //pulse->level for sampling in cross clock domain
  end
end	

always@(negedge cfg_spi_clk)
begin
  if (reset)  begin
     mcbsp_slaver_en_reg[2:0]         <= 3'd0;
  end                               
  else begin                        
     mcbsp_slaver_en_reg[2:0]         <= {mcbsp_slaver_en_reg[1:0],tx_mcbsp_interrupt};
  end
end	

always@(negedge cfg_spi_clk)
begin
  if (reset)  begin
     mcbsp_slaver_en                  <= 1'b0;
  end                               
  else if((mcbsp_slaver_en_reg[2:1] == 2'b01) || (mcbsp_slaver_en_reg[2:1] == 2'b10))begin //rising and falling all work  
     mcbsp_slaver_en                  <= 1'b1;
  end
  else begin
     mcbsp_slaver_en                  <= 1'b0;
  end
end

always@(negedge cfg_spi_clk)
begin
  if (reset)  begin
     start_en_cnt[7:0]                  <= 8'd0;
  end                               
  else if(mcbsp_slaver_en)begin
     start_en_cnt[7:0]                  <= start_en_cnt[7:0] + 1'b1;
  end
end

always@(negedge cfg_spi_clk)
begin
  if (reset)  begin
     start_en                <= 1'b0;
  end                               
  else if(start_en_cnt[7:0] == 8'd1)begin 
     start_en                <= 1'b1;
  end
  else begin
    start_en                 <= 1'b0;
  end
end

      
////////mcbsp slaver source///////////////////
slaver_source_rom slaver_source_rom( //depth = 2048
  .clka(cfg_spi_clk),
  .addra(slaver_count[17:7]),
  .douta(slaver_out[31:0])
);

always@(negedge cfg_spi_clk)
begin
  if(mcbsp_slaver_en) begin 
 //if(start_en) begin 
     slaver_count[17:0]                    <= 18'd0;
  end
  else if (slaver_count[6:0] == 7'd35)   begin 
   // if (slaver_count[16:7] == 10'd712)   begin  //rom real depth (1+9 cfg)+(1+111 freq)*2+(1+444 pn) +(1 end) +(1 + 32rtt rsp) =713
    //if (slaver_count[16:7] == 10'd679)   begin  //rom real depth (1+9 cfg)+(1+111 freq)*2+(1+444 pn) +(1 end)  = 680
	//if (slaver_count[16:7] == 10'd1023)   begin  //for 3c3c3c3c auto send 
	//if (slaver_count[17:7] == 11'd1234)   begin  //rom real depth (1+9 cfg)+(1+111*2freq)+(1+111 ccsk)+(1+444*2 pn) +(1 end)  = 1235
	if (slaver_count[17:7] == 11'd1235)   begin  //rom real depth (1+10 cfg)+(1+111*2freq)+(1+111 ccsk)+(1+444*2 pn) +(1 end)  = 1236
      slaver_count[17:7]                   <= slaver_count[17:7];
      slaver_count[6:0]                    <= slaver_count[6:0];
    end
    else   begin
      slaver_count[17:7]                   <= slaver_count[17:7] + 1'b1;  
      slaver_count[6:0]                    <= 7'd0;	
    end
  end	 
  else begin
    slaver_count[6:0]                      <= slaver_count[6:0] + 1'b1; 
  end
end

always@(negedge cfg_spi_clk)
begin
  if (slaver_count[6:0] == 7'd2)   begin  
    slaver_reg[31:0]                       <= slaver_out[31:0];
  end
  else   begin
    slaver_reg[31:1]                       <= slaver_reg[30:0]; //mcbsp_reg[0] keep
    slaver_data                            <= slaver_reg[31]; //MSB first
  end
end

////////dsp mcbsp_slaver result///////////////////
////mcbsp_slaver logic 
// mcbsp_slaver u_mcbsp_slaver
   // (
    ////config parameter  
    // .mcbsp_reg_length(7'd8), 
    
    ////input interface
    // .mcbsp_slaver_clkx(mcbsp_master_clkr),	 
    // .mcbsp_slaver_fsx(mcbsp_master_fsr),	 
    // .mcbsp_slaver_mosi(mcbsp_master_miso), 
    
	// .mcbsp_slaver_rst(mcbsp_rst_in),
    
    ////output data
    // .mcbsp_data_out(rx_result[31:0]), 
	// .mcbsp_vaild_out(),
     	
    ////state/debug 		 
    // .debug_signal()	
    // );
	

/////////////////////////////////
assign   logic_clk_in   = clk_200M_in;
assign   logic_rst_in   = reset;
                       
assign   mcbsp_clk_in   = cfg_spi_clk;
assign   mcbsp_rst_in   = 1'b0;

assign   mcbsp_slaver_clkx = cfg_spi_clk;
assign   mcbsp_slaver_fsx  = (slaver_count[6:0] == 7'd4) ? 1'b1:1'b0;	 
assign   mcbsp_slaver_mosi = slaver_data;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//// (3) dsp fpga interface////
dsp_fpga_top  U3_dsp_fpga_module
   (
 	 // clock&reset 
	 .logic_clk_in(logic_clk_in),                            // 200MHz logic clock
	 .logic_rst_in(logic_rst_in),
	 
     .mcbsp_clk_in(mcbsp_clk_in),
     .mcbsp_rst_in(mcbsp_rst_in),
     
     	 ////mif control
	 .mif_dsp_fpga_source_sel      (1'b1),
	 .mif_work_mode                (4'b1011 ),
	 ////slot timing config 
	 .tx_data_en_window_in         (tx_data_en_window_out    ),
	 .nrt_rtt_rsp_ng_out           (nrt_rtt_rsp_ng_out       ),		 
 
	// port
		////mcbsp0
     .mcbsp0_slaver_clkx(1'b0),	 
     .mcbsp0_slaver_fsx(1'b0),	 
     .mcbsp0_slaver_mosi(1'b0),
		  
     .mcbsp0_master_clkr(),	 
     .mcbsp0_master_fsr(),	 
     .mcbsp0_master_miso(),
	 
	 .port_red_stat(),			
     .port_data_valid(1'b0),		
     .port_red_data(32'd0),
	
	////mcbsp1
     .mcbsp_slaver_clkx(mcbsp_slaver_clkx),	 
     .mcbsp_slaver_fsx(mcbsp_slaver_fsx),	 
     .mcbsp_slaver_mosi(mcbsp_slaver_mosi),
	 
     .mcbsp_master_clkr(mcbsp_master_clkr),	 
     .mcbsp_master_fsr(mcbsp_master_fsr),	 
     .mcbsp_master_miso(mcbsp_master_miso),	
	  
	 ////pattern & status////
     .dsp_ccsk_pat(dsp_ccsk_pat[7:0]),
	 .dsp_tx_freq_hop(dsp_tx_freq_hop[7:0]),
	 .dsp_rx_freq_hop(dsp_rx_freq_hop[7:0]),
     .dsp_tx_pn_scram(dsp_tx_pn_scram[31:0]),
	 .dsp_rx_pn_scram(dsp_rx_pn_scram[31:0]),

     .ju_work_mode(ju_work_mode[3:0]),
	 .ju_slot_ntrindi(ju_slot_ntrindi[31:0]),
	 .ju_slot_slotmode(ju_slot_slotmode[31:0]), 
     .ju_slot_posi(ju_slot_posi[31:0]),              
     .ju_slot_clknum(ju_slot_clknum[31:0]),                     
     .ju_slot_txposi(ju_slot_txposi[31:0]),            
     .ju_slot_txnum(ju_slot_txnum[31:0]),             
     .ju_slot_rxposi(ju_slot_rxposi[31:0]),            
     .ju_slot_rxnum(ju_slot_rxnum[31:0]), 
	 .ju_slot_rfposi(ju_slot_rfposi[31:0]),
	 .ju_unsync_timer(ju_unsync_timer[31:0]),
	 .ju_slot_switch(ju_slot_switch),  

   
   // DL data transmit
     .tx_slot_interrupt(tx_slot_interrupt), 
     .tx_rd_en(dl_rd_en),	 
     .tx_addr_in(dl_addr_out[9:0]),
	 .tx_freq_rd_en(dl_freq_rd_en),	 
     .tx_freq_addr_in(dl_freq_addr_out[9:0]),
	
   // UL data receive
     .rx_slot_interrupt(rx_slot_interrupt),
	 .rx_freq_pn_addr_in(rx_freq_pn_addr_out[9:0]),
	 .rx_freq_pn_rd_in(rx_freq_pn_rd_out),
	 .rx_ram_addr_out(rx_ram_addr_out[7:0]),
	 .rx_ram_en_out(rx_ram_rd_en),
	 .rx_ram_data_in(rx_ram_data_out[31:0]),

	 .mcbsp1_loop_int_out(mcbsp1_loop_int_out),
	// .rx_rd_interrupt_out          (rx_rd_interrupt_out      ),
	 .dsp_cfg_end_out              (dsp_cfg_end_out          ),
	 .rx_chan_end_out              (rx_chan_end_out          ),
	 .tx_chan_end_out              (tx_chan_end_out          ),

	 
     	                                                     
     // debug                                                
     .debug_tx_signal              (debug_dsp_tx[199:0]      ),
     .debug_rx_signal              (debug_dsp_rx[199:0]      ),
     .debug_mcbsp_signal           (debug_dsp_mcbsp[127:0]   ),
     .debug_mcbsp0_signal          (debug_dsp_mcbsp0[127:0]  )
   
   ); 


//////////////////////////////////////////////////////////////////////////////////
data_process_top U_data_process_top(
     //// clock/reset interface ////
     .clk_msk_in(clk_50M_in), 
     .clk_25M_in(clk_25mhz),
     .logic_clk_in(logic_clk_in),                           // 200MHz logic clock
     .logic_rst_in(logic_rst_in),                           //
	 
	 //// mif control ////
	 .mif_dac_stat_en              (1'b0),
	 .mif_dac_dds_sel              (1'b0),  //signal and double sine switch
	 .mif_dac_msk_sel              (1'b0),  //msk and sine switch 
	 .mif_ad_da_loop_sel           (4'd0),  //adda loop and fpga loop switch 
	 .mif_coarse_dec_th            (12'd0),  //coarse threshold control
     .mif_dds50M_sel               (4'd0 ),  //rx 50M dds ddc and duc control
     
     
     //// control singals //// 
     .slot_timer(ju_net_slot[31:0]),                // slot time count
     .net_work_mode(ju_work_mode[3:0]), 
     .unsync_timer_in(ju_unsync_timer[31:0]),	
     .tx_slot_interrupt_in         (tx_slot_interrupt        ),	 
     
     .net_slot_ntrindi(ju_slot_ntrindi[31:0]),
     .net_slot_mode(ju_slot_slotmode[31:0]), 
     .net_slot_clknum(ju_slot_clknum[31:0]),
     .net_tx_loc(ju_slot_txposi[31:0]),
     .net_tx_pulse_num(ju_slot_txnum[31:0]),
     .net_rx_loc(ju_slot_rxposi[31:0]),    
     .net_rx_pulse_num(ju_slot_rxnum[31:0]),
     .net_slot_switch(ju_slot_switch),  
	 
	 .mcbsp1_loop_int_in(mcbsp1_loop_int_out),
     
     //// data signals ////
     //.data_from_adc(16'd0),                          // 200Mchips/s
     .data_adc_rd_en(1'b0),
	 
	 .adc_0_from                    (16'd0 ),  
     .adc_1_from                    (16'd0 ),
     .adc_2_from                    (16'd0 ),
     .adc_3_from                    (16'd0 ),   
     
     .data_to_dac(dl_dsp_to_dac[31:0]      ),
     .data_to_switch_en(dl_data_dac_en     ), 
	 .data_to_dac_window(dl_data_dac_window),	 
     .data_to_rf_freq(data_to_rf_freq[7:0]),
	 
     .data_to_freq_chan_en(dl_add9957_freq_en), 
     .data_to_ad9957_freq(dl_add9957_freq[31:0]),
	 

     
     //// dsp bufffer signals ////
     .ul_rd_en_in(rx_ram_rd_en),
     .ul_addr_rd_in(rx_ram_addr_out[7:0]),
     .ul_data_out(rx_ram_data_out[31:0]),
     .ul_freq_pn_addr_out(rx_freq_pn_addr_out[9:0]),
	 .ul_freq_pn_rd_out(rx_freq_pn_rd_out),
	 .ul_slot_interrupt(rx_slot_interrupt),
     .rx_data_dsp_interrupt(rx_data_dsp_interrupt),
     
     //// tx module ////	
	 
     .dl_rd_en(dl_rd_en),
     .dl_addr_out(dl_addr_out[9:0]), 
	 .dl_freq_rd_en(dl_freq_rd_en),                       
     .dl_freq_addr_out(dl_freq_addr_out[9:0]),  	 
     .dl_pn_pat(dsp_tx_pn_scram[31:0]),
     .dl_ccsk_pat(dsp_ccsk_pat[7:0]),
     .dl_freq_pat(dsp_tx_freq_hop[7:0]),
	 .tx_end_out(tx_end_out),
	 .tx_rx_switch_out             ( tx_rx_switch_out),
	 
	 .nrt_rtt_rsp_ng_in            (nrt_rtt_rsp_ng_out       ),
	 .tx_data_en_window_out        (tx_data_en_window_out    ),
     
     //// rx module ////	
     .ul_pn_pat(dsp_rx_pn_scram[31:0]),                      
     .ul_freq_pat(dsp_rx_freq_hop[7:0]),    
     
          // syn result output
	   //---------------------------2015/11/16 13:10:36
	   .mif_freq_convert             (32'd0        ),
	   .mif_rx_freq_tim              (32'd0         ),
	//   .mif_freq_convert             (32'd1400        ),
	   .mif_freq_dds                 (32'd0           ),
	   .rx_freq_dds_end              (ju_slot_switch         ),
	   .mif_tx_dds0_cfg              (25'd0),
     .mif_tx_dds1_cfg              (25'd0),  
	   
	   .freq_rd_en                   (           ),

     
     .coarse_status(),    
     .tr_status(), 
     
	 ////////for test
	 .dsp_cfg_end_in(dsp_cfg_end_out),
	 .rx_chan_end_in(rx_chan_end_out),
	 .tx_chan_end_in(tx_chan_end_out),
	 

     // debug signals
     .debug_txpro_signal           (debug_txpro_signal[199:0]),
     .debug_rxpro0_signal          (debug_rxpro_dec[199:0]   ),
     .debug_rxpro1_signal          (debug_rxpro_fsm[199:0]   ),
     .debug_rxpro2_signal          (debug_rxpro_ccsk[199:0]  ),
	 .debug_rxpro3_signal          (debug_rxpro_dds[199:0]   ),
     .debug_rxpro4_signal          (debug_rxpro_fir[199:0]   ),
	 .debug_rxpro5_signal          (debug_rxpro_sync[199:0]  ),
	 .debug_rxpro6_signal           (  ),
     .debug_rxpro7_signal          ( ),
     .debug_rxpro8_signal          ()
    );
	
	
sync_timing_top  U10_sync_module
   (
    // clock&reset signals
     .logic_clk_in(logic_clk_in),                           // 200MHz logic clock
     .logic_rst_in(logic_rst_in),                           // 7.8125ms reset

	 ////work mode
	 .net_work_mode(ju_work_mode[3:0]),
    
	 // time information
     .timing_ctl(ju_slot_switch),
     .timing_slot_posi(ju_slot_posi[31:0]),         //  curret DSP offset according to ahead slot
	 .timing_slot_clknum(ju_slot_clknum[31:0]),           //  clk number in 7.8125ms 
	
	 // output signals
	 .slot_time_out(ju_net_slot[31:0]),
	 .tx_slot_interrupt(tx_slot_interrupt),        // 7.8125ms interruption,occupy 1clk(200M)
	 .tx_slot_dsp_interrupt(tx_slot_dsp_interrupt), // 7.8125ms interruption,last 20ns,high level
	 
	 .slot_statc_cnt_out(),
	 
     // debug
     .debug_signal                 (debug_sync_timing[127:0])
   
   );
   
   
   
// hard_timing_ctl u_hard_timing_ctl
   // (
// clock interface ////
    // .logic_clk_in(logic_clk_in),                 // 200MHz logic clock
    // .logic_rst_in(logic_rst_in),

// time information ////
    // .slot_timer(ju_net_slot[31:0]),
    // .net_slot_rfposi(ju_slot_rfposi[31:0]),
	// .net_tx_pulse_num(ju_slot_txnum[31:0]),

// freq hop information ////
    // .tx_feq_cfg(data_to_rf_freq[7:0]),
	// .tx_end_pulse(tx_end_out),

// output rf tx timing ctl ////
    // .tx_chan_sel_p(tx_chan_sel_p[2:0]), 
    // .tx_chan_sel_n(tx_chan_sel_n[2:0]), 
    
    // .tx_lo_en_p(tx_lo_en_p[3:0]),
    // .tx_lo_en_n(tx_lo_en_n[3:0]),
    
    // .tx_carrier_sel_p(tx_carrier_sel_p[1:0]),
    // .tx_carrier_sel_n(tx_carrier_sel_n[1:0]),

// debug signals ////
    // .debug_signal(debug_hard_timing[127:0])
	 
// );

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//// () data ////
// if_data_process_top  U3_if_data_top
   // (
    ///// clock & Reset
     // .sys_clk                      (clk_200M_in),       //系统钟200                    
     // .sys_rst                      (logic_rst_in),      //系统复位          
     // .clk_25m                      (clk_25mhz),       
     // .clk_50m                      (clk_50M_in),			 
     ////UL signal stream  ADC0 IN  
     // .adc0_data_a_p                (7'd0), 
     // .adc0_data_a_n                (7'd0), 
     // .adc0_data_b_p                (7'd0), 
     // .adc0_data_b_n                (7'd0), 
     // .adc0_or_p                    (1'b0), 
     // .adc0_or_n                    (1'b0), 
     // .adc0_clkout_p                (1'b0), 
     // .adc0_clkout_n                (1'b0), 
     ////-------------ADC1 IN        
     // .adc1_data_a_p                (7'd0), 
     // .adc1_data_a_n                (7'd0), 
     // .adc1_data_b_p                (7'd0), 
     // .adc1_data_b_n                (7'd0), 
     // .adc1_or_p                    (1'b0), 
     // .adc1_or_n                    (1'b0), 
     // .adc1_clkout_p                (1'b0), 
     // .adc1_clkout_n                (1'b0),  
     /////------------ADC OUT         
     // .adc0_data_a_out              ( ),
     // .adc0_data_b_out              ( ),
     // .adc1_data_a_out              ( ),
     // .adc1_data_b_out              ( ),
     ////DL signal stream           
     // .dac_pdclk                    (clk_dac50M_in   ),  //50mhz  = 1/4 sys_clk      
     // .dac_pll_lock                 (1'b1), 
     ////-------------DAC  
	 // .dl_data_dac_window           (dl_data_dac_window),
     // .logic_rst                    (logic_rst_in    ),	 
     // .tx_stat                      (tx_slot_interrupt),
     // .dac_txenable                 (dac_txenable    ),
     // .msk_iq_data                  (dl_dsp_to_dac   ),
     // .msk_data_valid               (dl_data_dac_en  ),
     // .mif_dac_data_mode            (16'd0),
     // .dac_data                     (dac_iq_data),
     ////-------------DEBUG          
     // .adc_debug_signal             (  ),
	 // .dac_debug_signal             (  )
	 
    // );

//////////////////////////wave file save/////////////////////////////////
// initial

// begin

// $dumpfile("jft_1024.vcd");

// $dumpvars(0,data_process_top_tb);

// end

  //////////////////////////write data field to file/////////////////////////////////
/*integer fp_msk_data_in_w;
integer fp_msk_s2p_diff_w;
integer fp_msk_s2p_I_w,fp_msk_s2p_Q_w;
integer fp_msk_phase_I_w,fp_msk_phase_Q_w;

initial begin
    fp_msk_data_in_w          = $fopen("./debug_data/FPGA_out/FPGA_msk_data_in.txt","w");   
	fp_msk_s2p_diff_w         = $fopen("./debug_data/FPGA_out/FPGA_msk_s2p_dif.txt","w"); 
	fp_msk_s2p_I_w            = $fopen("./debug_data/FPGA_out/FPGA_msk_s2p_I.txt","w"); 
	fp_msk_s2p_Q_w            = $fopen("./debug_data/FPGA_out/FPGA_msk_s2p_Q.txt","w"); 
	fp_msk_phase_I_w          = $fopen("./debug_data/FPGA_out/FPGA_msk_phase_i.txt","w"); 
	fp_msk_phase_Q_w          = $fopen("./debug_data/FPGA_out/FPGA_msk_phase_q.txt","w"); 
end	

always @(posedge clk_200M_in) begin	           
	if(debug_data_process[0]) begin
		$fwrite(fp_msk_data_in_w,"%d\n",debug_data_process[1]);
    end 
end	

always @(posedge clk_200M_in) begin	           
	if(debug_data_process[2]) begin
		$fwrite(fp_msk_s2p_diff_w,"%d\n",debug_data_process[3]);
    end 
end	

always @(posedge clk_200M_in) begin	           
	if(debug_data_process[4]) begin
		$fwrite(fp_msk_s2p_I_w,"%d\n",debug_data_process[5]);
    end 
end

always @(posedge clk_200M_in) begin	           
	if(debug_data_process[4]) begin
		$fwrite(fp_msk_s2p_Q_w,"%d\n",debug_data_process[6]);
    end 
end

always @(posedge clk_50M_in) begin	           
	if(debug_data_process[40]) begin
		$fwrite(fp_msk_phase_I_w,"%d\n",$signed(debug_data_process[23:8]));
    end 
end

always @(posedge clk_50M_in) begin	           
	if(debug_data_process[40]) begin
		$fwrite(fp_msk_phase_Q_w,"%d\n",$signed(debug_data_process[39:24]));
    end 
end*/


   
 
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////	
endmodule