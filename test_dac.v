`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   10:39:55 03/02/2017
// Design Name:   dac_cfg
// Module Name:   F:/new_projects/JFT_K7_top_1/test_dac.v
// Project Name:  JFT_K7_top_1
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: dac_cfg
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module test_dac;

	// Inputs
	reg cfg_spi_clk;
	reg dac_sync_clk;
	reg cfg_rst_in;
	reg mif_dac_spi_red;
	reg time_frame_stat;
	reg [31:0] time_frame_data;
	reg spi_rd_stat;
	reg spi_rd_en;
	reg dac_spi_start;
	reg dac_spi_sdo;
	reg spi_single_en;
	reg dac_cfg_valid;
	reg [7:0] dac_cfg_addr;
	reg [31:0] dac_cfg_data;
	reg [31:0] mif_dac_ioup_time;
	reg dac_stat;

	// Outputs
	wire [2:0] dac_profile_sel;
	wire dac_spi_clk;
	wire dac_spi_cs;
	wire dac_spi_sdi;
	wire dac_io_updte;
	wire [31:0] dac_rd_parameter;
	wire dac_rd_valid;
	wire dac_spi_end;
	wire [63:0] debug_signal;

	// Instantiate the Unit Under Test (UUT)
	dac_cfg uut (
		.cfg_spi_clk(cfg_spi_clk), 
		.dac_sync_clk(dac_sync_clk), 
		.cfg_rst_in(cfg_rst_in), 
		.mif_dac_spi_red(mif_dac_spi_red), 
		.time_frame_stat(time_frame_stat), 
		.time_frame_data(time_frame_data), 
		.dac_profile_sel(dac_profile_sel), 
		.spi_rd_stat(spi_rd_stat), 
		.spi_rd_en(spi_rd_en), 
		.dac_spi_start(dac_spi_start), 
		.dac_spi_clk(dac_spi_clk), 
		.dac_spi_cs(dac_spi_cs), 
		.dac_spi_sdi(dac_spi_sdi), 
		.dac_spi_sdo(dac_spi_sdo), 
		.dac_io_updte(dac_io_updte), 
		.spi_single_en(spi_single_en), 
		.dac_cfg_valid(dac_cfg_valid), 
		.dac_cfg_addr(dac_cfg_addr), 
		.dac_cfg_data(dac_cfg_data), 
		.dac_rd_parameter(dac_rd_parameter), 
		.dac_rd_valid(dac_rd_valid), 
		.dac_spi_end(dac_spi_end), 
		.mif_dac_ioup_time(mif_dac_ioup_time), 
		.dac_stat(dac_stat), 
		.debug_signal(debug_signal)
	);

	initial begin
		// Initialize Inputs
		cfg_spi_clk = 0;
		dac_sync_clk = 0;
		cfg_rst_in = 1;
		mif_dac_spi_red = 0;
		time_frame_stat = 0;
		time_frame_data = 32'h0a0b0c0d;
		spi_rd_stat = 0;
		spi_rd_en = 0;
		dac_spi_start = 0;
		dac_spi_sdo = 0;
		spi_single_en = 0;
		dac_cfg_valid = 0;
		dac_cfg_addr = 0;
		dac_cfg_data = 0;
		mif_dac_ioup_time = 0;
		dac_stat = 0;

		// Wait 100 ns for global reset to finish
		#100;
    		cfg_rst_in = 0; 
    		#75;
    time_frame_stat =1;
    #50;	
        time_frame_stat =0;			   
		// Add stimulus here

	end
 always #25   cfg_spi_clk = !cfg_spi_clk;
 always #5    dac_sync_clk = !dac_sync_clk;
endmodule

