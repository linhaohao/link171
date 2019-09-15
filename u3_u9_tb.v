`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   10:01:26 02/21/2017
// Design Name:   dsp_fpga_top
// Module Name:   F:/new_projects/JFT_K7_top_1/u3_u9_tb.v
// Project Name:  JFT_K7_top_1
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: dsp_fpga_top
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module u3_u9_tb;

	// Inputs
	reg logic_clk_in;
	reg logic_rst_in;
	reg mcbsp_clk_in;
	reg mcbsp_rst_in;
	reg mif_dsp_fpga_source_sel;
	reg [3:0] mif_work_mode;
	reg tx_data_en_window_in;
	reg [31:0] slot_timer;
	reg mcbsp0_slaver_clkx;
	reg mcbsp0_slaver_fsx;
	reg mcbsp0_slaver_mosi;
	reg port_data_valid;
	reg [31:0] port_red_data;
	reg mcbsp_slaver_clkx;
	reg mcbsp_slaver_fsx;
	reg mcbsp_slaver_mosi;
	reg tx_slot_interrupt;
	reg tx_rd_en;
	reg [9:0] tx_addr_in;
	reg tx_freq_rd_en;
	reg [9:0] tx_freq_addr_in;
	reg rx_slot_interrupt;
	reg [9:0] rx_freq_pn_addr_in;
	reg rx_freq_pn_rd_in;
	reg [31:0] rx_ram_data_in;

	// Outputs
	wire nrt_rtt_rsp_ng_out;
	wire mcbsp0_master_clkr;
	wire mcbsp0_master_fsr;
	wire mcbsp0_master_miso;
	wire port_red_stat;
	wire mcbsp_master_clkr;
	wire mcbsp_master_fsr;
	wire mcbsp_master_miso;
	wire [3:0] ju_work_mode;
	wire [31:0] ju_slot_ntrindi;
	wire [31:0] ju_slot_slotmode;
	wire [31:0] ju_slot_posi;
	wire [31:0] ju_slot_clknum;
	wire [31:0] ju_slot_txposi;
	wire [31:0] ju_slot_txnum;
	wire [31:0] ju_slot_rxposi;
	wire [31:0] ju_slot_rxnum;
	wire [31:0] ju_slot_rfposi;
	wire [31:0] ju_unsync_timer;
	wire ju_slot_switch;
	wire [7:0] dsp_ccsk_pat;
	wire [7:0] dsp_tx_freq_hop;
	wire [7:0] dsp_rx_freq_hop;
	wire [31:0] dsp_tx_pn_scram;
	wire [31:0] dsp_rx_pn_scram;
	wire [7:0] rx_ram_addr_out;
	wire rx_ram_en_out;
	wire mcbsp1_loop_int_out;
	wire dsp_cfg_end_out;
	wire rx_chan_end_out;
	wire tx_chan_end_out;
	wire dsp_ctr_uart_en;
	wire [63:0] dsp_ctr_uart_data;
	wire [199:0] debug_tx1_signal;
	wire [199:0] debug_tx_signal;
	wire [199:0] debug_rx_signal;
	wire [127:0] debug_mcbsp0_signal;
	wire [127:0] debug_mcbsp_signal;

	// Instantiate the Unit Under Test (UUT)
	dsp_fpga_top uut (
		.logic_clk_in(logic_clk_in), 
		.logic_rst_in(logic_rst_in), 
		.mcbsp_clk_in(mcbsp_clk_in), 
		.mcbsp_rst_in(mcbsp_rst_in), 
		.mif_dsp_fpga_source_sel(mif_dsp_fpga_source_sel), 
		.mif_work_mode(mif_work_mode), 
		.tx_data_en_window_in(tx_data_en_window_in), 
		.nrt_rtt_rsp_ng_out(nrt_rtt_rsp_ng_out), 
		.slot_timer(slot_timer), 
		.mcbsp0_slaver_clkx(mcbsp0_slaver_clkx), 
		.mcbsp0_slaver_fsx(mcbsp0_slaver_fsx), 
		.mcbsp0_slaver_mosi(mcbsp0_slaver_mosi), 
		.mcbsp0_master_clkr(mcbsp0_master_clkr), 
		.mcbsp0_master_fsr(mcbsp0_master_fsr), 
		.mcbsp0_master_miso(mcbsp0_master_miso), 
		.port_red_stat(port_red_stat), 
		.port_data_valid(port_data_valid), 
		.port_red_data(port_red_data), 
		.mcbsp_slaver_clkx(mcbsp_slaver_clkx), 
		.mcbsp_slaver_fsx(mcbsp_slaver_fsx), 
		.mcbsp_slaver_mosi(mcbsp_slaver_mosi), 
		.mcbsp_master_clkr(mcbsp_master_clkr), 
		.mcbsp_master_fsr(mcbsp_master_fsr), 
		.mcbsp_master_miso(mcbsp_master_miso), 
		.ju_work_mode(ju_work_mode), 
		.ju_slot_ntrindi(ju_slot_ntrindi), 
		.ju_slot_slotmode(ju_slot_slotmode), 
		.ju_slot_posi(ju_slot_posi), 
		.ju_slot_clknum(ju_slot_clknum), 
		.ju_slot_txposi(ju_slot_txposi), 
		.ju_slot_txnum(ju_slot_txnum), 
		.ju_slot_rxposi(ju_slot_rxposi), 
		.ju_slot_rxnum(ju_slot_rxnum), 
		.ju_slot_rfposi(ju_slot_rfposi), 
		.ju_unsync_timer(ju_unsync_timer), 
		.ju_slot_switch(ju_slot_switch), 
		.tx_slot_interrupt(tx_slot_interrupt), 
		.tx_rd_en(tx_rd_en), 
		.tx_addr_in(tx_addr_in), 
		.tx_freq_rd_en(tx_freq_rd_en), 
		.tx_freq_addr_in(tx_freq_addr_in), 
		.dsp_ccsk_pat(dsp_ccsk_pat), 
		.dsp_tx_freq_hop(dsp_tx_freq_hop), 
		.dsp_rx_freq_hop(dsp_rx_freq_hop), 
		.dsp_tx_pn_scram(dsp_tx_pn_scram), 
		.dsp_rx_pn_scram(dsp_rx_pn_scram), 
		.rx_slot_interrupt(rx_slot_interrupt), 
		.rx_freq_pn_addr_in(rx_freq_pn_addr_in), 
		.rx_freq_pn_rd_in(rx_freq_pn_rd_in), 
		.rx_ram_addr_out(rx_ram_addr_out), 
		.rx_ram_en_out(rx_ram_en_out), 
		.rx_ram_data_in(rx_ram_data_in), 
		.mcbsp1_loop_int_out(mcbsp1_loop_int_out), 
		.dsp_cfg_end_out(dsp_cfg_end_out), 
		.rx_chan_end_out(rx_chan_end_out), 
		.tx_chan_end_out(tx_chan_end_out), 
		.dsp_ctr_uart_en(dsp_ctr_uart_en), 
		.dsp_ctr_uart_data(dsp_ctr_uart_data), 
		.debug_tx1_signal(debug_tx1_signal), 
		.debug_tx_signal(debug_tx_signal), 
		.debug_rx_signal(debug_rx_signal), 
		.debug_mcbsp0_signal(debug_mcbsp0_signal), 
		.debug_mcbsp_signal(debug_mcbsp_signal)
	);

	initial begin
		// Initialize Inputs
		logic_clk_in = 0;
		logic_rst_in = 0;
		mcbsp_clk_in = 0;
		mcbsp_rst_in = 0;
		mif_dsp_fpga_source_sel = 0;
		mif_work_mode = 0;
		tx_data_en_window_in = 0;
		slot_timer = 0;
		mcbsp0_slaver_clkx = 0;
		mcbsp0_slaver_fsx = 0;
		mcbsp0_slaver_mosi = 0;
		port_data_valid = 0;
		port_red_data = 0;
		mcbsp_slaver_clkx = 0;
		mcbsp_slaver_fsx = 0;
		mcbsp_slaver_mosi = 0;
		tx_slot_interrupt = 0;
		tx_rd_en = 0;
		tx_addr_in = 0;
		tx_freq_rd_en = 0;
		tx_freq_addr_in = 0;
		rx_slot_interrupt = 0;
		rx_freq_pn_addr_in = 0;
		rx_freq_pn_rd_in = 0;
		rx_ram_data_in = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here

	end
      
endmodule

