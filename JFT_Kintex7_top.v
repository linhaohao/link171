////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Company:         StarPoint
// Engineer:        Guoyan
// 
// Create Date:     2015/09/06 13:39:03   
// Module Name:     JFT_Kintex7_top
// Project Name:    JFT Kintex7 Top Module
// Target Devices:  FPGA - XC7K325T - FFG900; DSP - TMS320C6670;
// Tool Versions:   ISE14.6
// Description:     FPGA(K7) is mainly used to data tranfer processing between DAC/ADC and DSP, also achieve data physical 
//                  layer process which includes many algorithms and encryption and DDS hop frequency.
//                  meantimes, for RF TX/RX links, FPGA(K7) is as RF controller for PLL, power, and compensation...
//
//
// Revision:        v1.0 - File Created
// Additional Comments:
// 1. external interface
// 1.1. clock pins - two LMK04806(FPGA/CPLD configuration);
// 1.2. DSP pins - mcbsp spi
// 1.3. GTX pins - SRIO/PCIE/AIF2(reserved);
// 1.4. ADC pins - LTC2158(double channel);
// 1.5. DAC pins - AD99957;
// 1.6. RF TX/RX pins - FMC inreface;
// 1.7. Timing pins - RTC;
// 
// 2. Logic module
// 2.1. mcbsp/spi data transmission logic;
// 2.2. AD/DA, RF control logic;
// 2.3. data physical layer TX/RX logic;
// 2.4. Timing & synchronization logic;
// 
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps


module JFT_Kintex7_top(
//// clock interface ////
input               clk_10mhz_in,                        // 10MHz refclk from AD9552 chip
input               sys_rest,                             // reset by key control
input               clk_200mhz_in_p,
input               clk_200mhz_in_n,                         // 200MHz clock from LMK03000C

//// dsp rdy signal////
input               dsp2fpga_dsp_rdy,
output              fpga2cpld_dsp_rdy,
input  [1:0]        dsp_mode,                      //来自 拨码开关。



//// clock chips(LMK04806+LMK04806)
output              lmk04806_1_spi_clk,                       
output              lmk04806_1_spi_data,                       
output              lmk04806_1_spi_le,                       
input               lmk04806_1_spi_sync,                    //read back

output[1:0]         lmk04806_1_clk_sel,  
input               lmk04806_1_locked_in,
input               lmk04806_1_holdover,

output              lmk04806_2_spi_clk,                       
output              lmk04806_2_spi_data,                       
output              lmk04806_2_spi_le,                       
input               lmk04806_2_spi_sync,                   //read back
input               lmk04806_2_holdover,


input               dsp_mcbsp0_txclk,	 
input               dsp_mcbsp0_fst,	 
input               dsp_mcbsp0_tx, //dsp->fpga, tx based on dsp
	                
output              dsp_mcbsp0_rxclk,	 
output              dsp_mcbsp0_fsr,	 
output              dsp_mcbsp0_rx, //fpga->dsp, rx based on dsp

input               dsp_mcbsp1_txclk,	 
input               dsp_mcbsp1_fst,	 
input               dsp_mcbsp1_tx, //dsp->fpga, tx based on dsp
	                
output              dsp_mcbsp1_rxclk,	 
output              dsp_mcbsp1_fsr,	 
output              dsp_mcbsp1_rx, //fpga->dsp, rx based on dsp

//-------------------------adc
output              adc1_spi_clk ,
output              adc1_spi_cs  ,
input               adc1_spi_sdo ,
output              adc1_spi_sdi ,
          
output              adc0_spi_clk,
output              adc0_spi_cs ,
input               adc0_spi_sdo,
output              adc0_spi_sdi,

//// DAC - AD9957 
//spi                           
output              dac_io_update,
output              dac_spi_clk,
output              dac_spi_cs  ,
output              dac_spi_sdi ,
input               dac_spi_sdo ,

input               dac_pll_lock,
input               dac_sync_clk,
input               dac_pdclk   ,
// tx on off
output              dac_txenable,

output[2:0]         dac_profile_sel, 
output              dac_master_reset,
output              dac_io_reset,
output              dac_ext_pwr_dwn,

//adc dac   data  bus----------------
input [6:0]         adc0_data_a_p,
input [6:0]         adc0_data_a_n,
input [6:0]         adc0_data_b_p,
input [6:0]         adc0_data_b_n,
input               adc0_or_p    ,
input               adc0_or_n    ,
input               adc0_clkout_p,
input               adc0_clkout_n,
                                 
input [6:0]         adc1_data_a_p,
input [6:0]         adc1_data_a_n,
input [6:0]         adc1_data_b_p,
input [6:0]         adc1_data_b_n,
input               adc1_or_p    ,
input               adc1_or_n    ,
input               adc1_clkout_p,
input               adc1_clkout_n,


//////////////////////////////////////////////////////////////////////
inout [6:0]         dsp_bootmode,
inout               dsp_enddian,

output              fpga2cpld_dsp_mode,
output              fpga_clk_div24,      //心跳信号
output              fpga_2cpld_dspen,     //DSP电源使能
output              fpga_2cpld_rst1,      //DSP复位1
output              fpga_2cpld_rst2,      //DSP复位2
output              fpga_2cpld_rst3,      //DSP复位3
output              fpga_load,
//--pc              
output              fpga2usb_uart_txd ,
input               usb2fpga_uart_rxd ,
//---phy 
output              phy_rst,
input               phy_int,

output [17:0]       dac_iq_data,


output[7:0]        led_startus                              // 8 led display
);



//assign dac_txenable = 1'b1; 
//assign dac_iq_data = 18'b011101010101010101;   
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//// signal declaration /////
//// clock signals ////
wire                gloal_clk_buf;
wire                clk_10MHz_buf;
wire                dac_data_clk_buf;
wire                adc0_clk;
wire                adc1_clk;

wire                clk_200mhz;
wire                clk_20mhz_2;
wire                clk_50mhz;
wire                clk_10mhz;
wire                clk_5mhz;  
wire                clk_20mhz;   
wire                clk_100mhz;
wire                clk_400k;
wire 								clk_2500Hz;

wire                clk_dcm0_pll;
wire                clk_dcm1_pll;



//// reset signals ////
wire                logic_rst_n;             
reg [15:0]          rst_count          = 16'hffff;

  
wire                lmk_stable_lock;        
wire                lmk_pll_lock ;     

wire [7:0]          led_startus_out;  

    
wire [31:0]         mif2dac_frame_data = 0;
wire                mif2dac_frame_stat = 0;
wire                dac_stat;
wire [15:0]         adc0_data_a;
wire [15:0]         adc0_data_b;
wire [15:0]         adc1_data_a;
wire [15:0]         adc1_data_b;

//// debug signal ////

wire [255:0]      uart_debug;
wire [199:0]      dac_cfg_debug;
wire              dac_sync_clk_buf;  
wire              lmk_int2_stat;
wire [2:0]        dsp_int_state;
wire [63:0]       sys_debug;
wire              rx_data_dsp_interrupt;
wire              tx_slot_dsp_interrupt;
wire              coarse_status = 0;    
wire              tr_status = 0; 
wire [31:0]       mif_dac_int_cfg = 32'd0;
wire              dsp_ctr_uart_en;
wire [63:0]       dsp_ctr_uart_data;
wire              lmk_failure_led;
wire [63:0]       rv_uart_data;
wire              rv_uart_vld;   

wire [63:0]         lmk_debug;
wire [63:0]         device_rd_debug;   
wire [63:0]         device_wr_debug;   
wire [63:0]         adc_debug;        
//output [63:0]            dac_debug,  
wire [63:0]         rf_debug;
wire [63:0]         initial_debug;
wire [63:0]         i2c_debug;
wire [63:0]         urat_debug;


wire                rf_cpld_spi_clk;
wire                rf_cpld_spi_cs;
wire                rf_cpld_spi_sdi;
  
wire [3:0]          cpld_select_mode; 
wire                dsp_rd_data_valid;
wire [31:0]         dsp_rd_data; 

wire [31:0]         mif_data_in;
wire                mif_en_in;

wire [63:0]         uart_demsk_data;
wire                uart_demsk_data_valid;

wire                mif_rd_stat = 0;
wire [9:0]          mif_addr_out = 0; 
wire                device_rd_vaild;
wire [31:0]         device_rd_data ;

wire [31:0]         mif_dac_data_mode = 0;
wire  [31:0]        mif_dac_rom_dl;  
wire                mif_rom_stat;
wire [31:0]         mif_dac_ioup_time = 32'd3;    


wire dac_spi_end;
wire slot_interrupt;
wire init_rx_slot;
wire slot_rx_interrupt;
wire rx_data_interrupt;
wire cancel_interrupt;
assign rx_data_dsp_interrupt = cancel_interrupt ? 1'b0 : rx_data_interrupt;
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
assign  led_startus[7:0]             = led_startus_out[7:0];

assign  logic_rst_n                  = ~clk_dcm1_pll; 
    assign  fpga_load                    = 1'd0;
always@(posedge clk_200mhz or posedge logic_rst_n) //异步变同步复位
begin
   if (logic_rst_n)   begin
	  rst_count[15:0]                     <= 16'hFFFF;
	end
	else   begin
	  rst_count[15:0]                     <= {rst_count[14:0], 1'b0};	 //考虑rst持续时间应该拉长，保证慢时钟也能采集到，需修改???
	end
end	

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//// (2) clock module ////
//// global clock bufg  
IBUFGDS  u0_bufg
   (
   .I(clk_200mhz_in_p),
   .IB(clk_200mhz_in_n),
   .O(gloal_clk_buf) 
   );

// 10MHz from crystal
IBUFG  u1_bufg
   (
   .I(clk_10mhz_in),
   .O(clk_10MHz_buf) 
   );
   
// 50MHz from da
IBUFG   U_dac_clk_buf
    (
	 .I(dac_pdclk), 
	 .O(dac_data_clk_buf)
	 );	
	 
// 200MHz from ad
IBUFGDS u0_adc0_CLK( 
             .I (adc0_clkout_p), 
             .IB(adc0_clkout_n),  
             .O (adc0_clk  ) 			 
); 

IBUFGDS u1_adc1_CLK( 
             .I (adc1_clkout_p), 
             .IB(adc1_clkout_n), 
             .O (adc1_clk  ) 
);	 
// 200MHz from crystal
IBUFG  u3_bufg
   (
   .I(dac_sync_clk),
   .O(dac_sync_clk_buf) 
   );  
  
//// Clock DCM configuration////
clk_module_top   U0_clk_module
    (
	 .clk_gloal_in                 (gloal_clk_buf        ),     // 200MHz clock from LMK04806
	 .clk_10MHz_in                 (clk_10MHz_buf        ),     // 10MHz crystal clock
	 .clk_rst_in                   (sys_rest             ),     // 
	 .hardware_rst_in              (sys_rest             ),     // reset key
	 
	 .clk_logic_out                (clk_200mhz           ),     // 200MHz logic clock
	 .clk_20MHz              		 (clk_20mhz_2          ),     // 20MHz clock
	 .clk_50MHz_out                (clk_50mhz            ),     // 50MHz da clock
	 
	 .clk_400KHz_out               (clk_400k             ),     // For I2C interface clock = 400KHz
	 .clk_100MHz_out               (clk_100mhz           ),     // 100MHz
	 .clk_5MHz_out                 (clk_5mhz             ),     // For SPI interface clock = 5MHz 
	 .clk_20MHz_out                (clk_20mhz            ),     // For dsp mcbsp/spi interface clock = 20MHz 
	 .clk_10MHz_out                (clk_10mhz            ),     // For SPI interface clock = 10MHz 
 
	 .mmcm0_locked_out             (clk_dcm0_pll         ),     // 10MHz crystal mmcm locked
	 .mmcm1_locked_out             (clk_dcm1_pll         )      // logic clk mmcm locked
    
	 );
 

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//// (3) System state control ////
sys_state_crl   U0_sys_state_crl
    (
     .clk_20mhz                    (clk_20mhz           ),
     .clk_200mhz                   (clk_200mhz          ),
     .clk_20mhz_2						  (clk_20mhz_2			  ),
     .clk_10mhz                    (clk_10MHz_buf       ),
     .clk_dcm1_pll                 (clk_dcm1_pll        ),
     .clk_dcm0_pll                 (clk_dcm0_pll        ),     
     .sys_rest                     (sys_rest            ),      
     
     .rs_rx_data_vlde              (rv_uart_vld         ),
     .rs_rx_data                   (rv_uart_data        ),
     .dsp_ctr_uart_en              (dsp_ctr_uart_en          ),
     .dsp_ctr_uart_data            (dsp_ctr_uart_data[63:0]  ),
   
     .lmk04806_2_holdover          (lmk04806_2_holdover ),
     .lmk04806_1_holdover          (lmk04806_1_holdover ),
     .lmk04806_1_locked_in         (lmk04806_1_locked_in),
     .lmk_pll_lock                 (lmk_pll_lock        ),
     .lmk_stable_lock              (lmk_stable_lock     ),
     .dsp2fpga_dsp_rdy             (dsp2fpga_dsp_rdy    ),
     
     .lmk_failure_led              (lmk_failure_led     ),      
     .led_startus                  (led_startus_out     ),
     .lmk_clk_sel                  (lmk04806_1_clk_sel  ),
	   .dsp_net_in				  				 (          ),
     .dac_master_reset             (dac_master_reset    ),
     .dac_io_reset                 (dac_io_reset        ),
     .dac_ext_pwr_dwn              (dac_ext_pwr_dwn     ),
     .dsp_mode                     (dsp_mode[1:0]       ),
     
     .phy_rst                      (phy_rst             ),                 
     .phy_int                      (phy_int             ),  

     .dac_stat                     (dac_stat            ),
     
     .lmk_int2_stat                (lmk_int2_stat), 
     
		 .fpga2cpld_dsp_mode         (fpga2cpld_dsp_mode  ),
     .fpga_clk_div24               ( fpga_clk_div24     ),      //心跳信号
     .fpga_2cpld_dspen             ( fpga_2cpld_dspen   ),     //DSP电源使能
     .fpga_2cpld_rst1              ( fpga_2cpld_rst1    ),      //DSP复位1
     .fpga_2cpld_rst2              ( fpga_2cpld_rst2    ),      //DSP复位2
     .fpga_2cpld_rst3              ( fpga_2cpld_rst3    ),      //DSP复位3
     
     .dsp_rst_in                   (          ),      //mode[6]共用
                      
     
     .dsp_enddian                  (dsp_enddian         ),
     .dsp_bootmode                 (dsp_bootmode        ),
     .fpga_dsp_cfgok               ( ),
     .fpga2cpld_dsp_rdy            (fpga2cpld_dsp_rdy   ),
					 
     .dsp_int_state                (dsp_int_state),
    //interrupt
     .gpio_tx_interrupt            (tx_slot_dsp_interrupt),//
     .gpio_rx_interrupt            (rx_data_dsp_interrupt), 
 
     .debug_signal                 (sys_debug           )  
	 
    );


port_cfg_top   U2_port_cfg_top
   (
    // clk/rst
     .clk_20mhz                    (clk_20mhz          ),  
     .clk_20mhz_2						  (clk_20mhz_2			 ),        
     .clk_10mhz                    (clk_10mhz          ),
     .sys_rest                     (sys_rest           ),
     
     .lmk_int2_stat               (lmk_int2_stat),
     //--STARTUS                   
     .dsp_startus_rdy              (dsp2fpga_dsp_rdy   ),
     .lmk_pll_lock                 (lmk_pll_lock       ), 
     .lmk_stable_lock              (lmk_stable_lock    ),
     .lmk_failure_led              (lmk_failure_led    ),                            
     //--UART
     .usb2fpga_uart_rxd            (usb2fpga_uart_rxd),
     .fpga2usb_uart_txd            (fpga2usb_uart_txd),
     //--MIF
     .mif_data_in                  (mif_data_in        ),   
     .mif_en_in                    (mif_en_in          ),     
     .mif_addr_out                 (mif_addr_out       ),  
     .mif_rd_stat                  (mif_rd_stat        ),  
     .mif_data_out                 (uart_demsk_data[63:0]),	//mif_data_out
     .mif_data_vaild               (uart_demsk_data_valid),	//mif_data_vaild
     .mif_rd_valid                 (device_rd_vaild    ),
     .mif_rd_data                  (device_rd_data     ),
     
     //--I2C         
     .clk_400k                     (clk_400k           ),
     
       
     .lmk04806_1_spi_clk           (lmk04806_1_spi_clk ),               
     .lmk04806_1_spi_cs            (lmk04806_1_spi_le  ),               
     .lmk04806_1_spi_sdo           (lmk04806_1_spi_sync),               
     .lmk04806_1_spi_sdi           (lmk04806_1_spi_data),     
     .lmk04806_2_spi_clk           (lmk04806_2_spi_clk ),          
     .lmk04806_2_spi_cs            (lmk04806_2_spi_le  ),          
     .lmk04806_2_spi_sdo           (lmk04806_2_spi_sync),          
     .lmk04806_2_spi_sdi           (lmk04806_2_spi_data),                              
//-------------DAC ---------------------------------------------   
     .freq_en_stat                 (),
     .add9957_freq                 (),
     .dac_mode_slse                (mif_dac_data_mode[14]),
     .mif_dac_spi_red              (mif_dac_data_mode[0]),
 
     .mif2dac_frame_stat           (mif2dac_frame_stat),
     .mif2dac_frame_data           (mif2dac_frame_data),//输入0
     .dac_stat                     (dac_stat          ),   
     .mif_dac_rom_dl               (),
     .mif_rom_stat                 ( ),
     .mif_dac_rom_mode             (mif_dac_data_mode[13:11] ),    
     

     .dac_sync_clk                 (dac_sync_clk_buf),
     .mif_dac_ioup_time            (mif_dac_ioup_time),
             
     
     .dac_profile_sel              (dac_profile_sel  ),       
     .dac_io_update                (dac_io_update    ), 
     .dac_spi_clk                  (dac_spi_clk      ),    
     .dac_spi_cs                   (dac_spi_cs       ),     
     .dac_spi_sdo                  (dac_spi_sdo      ),    
     .dac_spi_sdi                  (dac_spi_sdi      ), 
     .dac_spi_end						  (dac_spi_end      ),   
//-------------ADC ---------------------------------------------
     .adc0_spi_clk                 (adc0_spi_clk     ),   
     .adc0_spi_cs                  (adc0_spi_cs      ),	 
     .adc0_spi_sdo                 (adc0_spi_sdo     ),	 
     .adc0_spi_sdi                 (adc0_spi_sdi     ),	 
     .adc1_spi_clk                 (adc1_spi_clk     ),  
     .adc1_spi_cs                  (adc1_spi_cs      ),	
     .adc1_spi_sdo                 (adc1_spi_sdo     ),	
     .adc1_spi_sdi                 (adc1_spi_sdi     ),	 
//------------UART CTR--------------------------------------------
     .rs_rx_data                   (rv_uart_data      ),
     .rs_rx_data_vlde              (rv_uart_vld       ),
//-------------DEBUG-------------------------------------------
     .lmk_debug                    (lmk_debug      ),          
     .device_rd_debug              (device_rd_debug),  
     .device_wr_debug              (device_wr_debug),  
     .adc_debug                    (adc_debug      ),              
     .initial_debug                (initial_debug  ),    
     .dac_cfg_debug                (dac_cfg_debug),
	  .uart_debug						  (uart_debug)
	 
    );	 

wire [255:0] mcbsp_debug;
wire tx_send_start;
wire [31:0] send_data;
wire [13:0] read_addr;
wire [31:0] data_dsp;
wire start_send;
wire [16:0] send_step;
wire [31:0] corase_syn_pos;
wire [31:0] fine_syn_pos;
wire part_syn_en;
wire part_syn_start;
wire fine_syn_en;
wire corase_syn_en;
wire lose;
wire dsp_start_send;
wire flag_croase;
wire flag_fine;
wire fine_data_flag;
wire decode_data_flag;
wire croase_data_flag;
wire tx_data_flag;
dsp_fpga_data(
	
		.clk_200m(clk_200mhz),
		.clk_20m(clk_20mhz_2),
		.clk_50m(clk_50mhz),
		.clk_25kHz(clk_25kHz),
		.cfg_rst(rst_count[15]),

		.mcbsp0_slaver_clkx(dsp_mcbsp0_txclk),	 
		.mcbsp0_slaver_fsx(dsp_mcbsp0_fst),	 
		.mcbsp0_slaver_mosi(dsp_mcbsp0_tx), 
			
		.mcbsp0_master_clkr(dsp_mcbsp0_rxclk),	 
		.mcbsp0_master_fsr(dsp_mcbsp0_fsr),	 
		.mcbsp0_master_miso(dsp_mcbsp0_rx),
		.tx_send_start(tx_send_start),//目前接收完数据就发送，以后添加了时隙概念后可以用时隙起始值控制发送使能 
		.read_addr(read_addr),
		.send_data(send_data),
		.slot_interrupt(slot_interrupt),

		.mcbsp1_slaver_clkx(dsp_mcbsp1_txclk),	 
		.mcbsp1_slaver_fsx(dsp_mcbsp1_fst),	 
		.mcbsp1_slaver_mosi(dsp_mcbsp1_tx), 
			
		.mcbsp1_master_clkr(dsp_mcbsp1_rxclk),	 
		.mcbsp1_master_fsr(dsp_mcbsp1_fsr),	 
		.mcbsp1_master_miso(dsp_mcbsp1_rx),
		
		.data_updated(data_updated),
		.start_send(start_send),
		.send_step(send_step),
		.data_dsp(data_dsp),
		.lose(lose),
		////////////////////////
		.part_syn_en(part_syn_en),
	  .part_syn_start(part_syn_start),
	  ////////////////////////////
		.corase_end(corase_syn_en),
		.fine_end(fine_syn_en),
		.dsp_start_send(dsp_start_send),
		.corase_syn_pos(corase_syn_pos),
		.fine_syn_pos(fine_syn_pos),
		.send40k_en(send40k_en),
	  .send10k_en(send10k_en),
	  
		.flag_croase(flag_croase),
		.flag_fine(flag_fine),
		.fine_data_flag(fine_data_flag),
		.decode_data_flag(decode_data_flag),
		.croase_data_flag(croase_data_flag),	 
		.tx_data_flag(tx_data_flag), 

		.debug(mcbsp_debug)
);

wire [255:0] debug_data_dsp;
wire [255:0] tx_debug;
wire [255:0] tx_debug_2;
wire [255:0] tx_debug_3;
wire [31:0] loop_data;
reg  slot_start_count;
always@(posedge clk_50mhz) begin
		if(rst_count[15]) begin
				slot_start_count <= 1'b0;
		end
		else if(dac_spi_end)begin//接收到dac返回的SPI结束信号，就将slot_start_count置1，且之后一直是1
				slot_start_count <= 1'b1;
		end
		else begin
				slot_start_count <= slot_start_count;
		end
end
wire rx_dds_en;
tx_top_new tx_top_inst(
				//input clk
            .clk_msk_in(clk_50mhz),
				.clk_5m(clk_5mhz),
				.clk_50m(clk_50mhz),
				.clk_200m(clk_200mhz),
				.cfg_rst(rst_count[15]),
				//IN
				.dac_data_clk_buf(dac_data_clk_buf),
				.slot_interrupt(slot_interrupt),
				.slot_start_count(slot_start_count),

				.send_start(tx_send_start),
				.dac_spi_end(dac_spi_end),
				.dsp_start_send(1'b1/*dsp_start_send*/),
				.send_data(send_data),
				
				//OUT			
				.clk_64_96khz(clk_25kHz),
				.read_addr(read_addr),

				.loop_data(loop_data),
				
				.dac_tx_en(dac_txenable),
				.dac_out(dac_iq_data),
				
				.debug_1(tx_debug),
				.debug_2(tx_debug_2),
				.debug_3(tx_debug_3)
);
wire [255:0] ddc_iq_debug;
wire [255:0] debug_adc;
wire [255:0] debug_adc_2;
wire [255:0] debug_dec_1;
wire [255:0] debug_dec_2;
wire [255:0] debug_decode;
wire store10k_en_posedge;
wire store10k_en_negedge;

rx_top  rx_top_inst(
		 .clk_200m(clk_200mhz),
		 .clk_5m(clk_5mhz),
		 .clk_50m(clk_50mhz),
		 .clk_20m(clk_20mhz_2),
		 .cfg_rst(rst_count[15]),
		 
     //  ADC0 IN  
     .adc0_data_a_p                (adc0_data_a_p), 
     .adc0_data_a_n                (adc0_data_a_n), 
     .adc0_data_b_p                (adc0_data_b_p), 
     .adc0_data_b_n                (adc0_data_b_n), 
     .adc0_or_p                    (adc0_or_p    ), 
     .adc0_or_n                    (adc0_or_n    ), 
	   .adc0_clk                    (adc0_clk     ),
	 
     //ADC1 IN        
     .adc1_data_a_p                (adc1_data_a_p), 
     .adc1_data_a_n                (adc1_data_a_n), 
     .adc1_data_b_p                (adc1_data_b_p), 
     .adc1_data_b_n                (adc1_data_b_n), 
     .adc1_or_p                    (adc1_or_p    ), 
     .adc1_or_n                    (adc1_or_n    ),  
	 	 .adc1_clk                   (adc1_clk     ),
	 	 
	 	 .dac_txenable								(dac_txenable),
	 	 .data_updated								(data_updated),
		 .start_send								(start_send),
		 .send_step									(send_step), 
		 .dsp_receive_interrupt				   (rx_data_interrupt),
	 	 .data_dsp									(data_dsp),	 	
	 	 .loop_data									(loop_data), 
       .slot_interrupt							(slot_interrupt),
		 .slot_start_count						(slot_start_count),
       .init_rx_slot								(init_rx_slot),
	 	 .rx_dds_en									(rx_dds_en),
	 	 ////////////////////////////////////////
	 	 .part_syn_en								(part_syn_en),
	    .part_syn_start							(part_syn_start),
		 ////////////////////////////////////////
		 .uart_demsk_data_valid             (uart_demsk_data_valid),
		 .uart_demsk_data                   (uart_demsk_data[63:0]),
/////////////////////////////////////////////////////


		 .debug_decode								(debug_decode),
	 	 .debug_data_dsp							(debug_data_dsp),
	 	 .debug_iq								   (ddc_iq_debug),
	 	 .sync_con_debug							(debug_adc),
	 	 .debug_adc_2								(debug_adc_2),
	 	 .debug_dec_1								(debug_dec_1),
	 	 .debug_dec_2								(debug_dec_2)
//	 	 
//     //------------ADC OUT         
//     .adc0_data_a_out              (adc0_data_a  ),
//     .adc0_data_b_out              (adc0_data_b  ),
//     .adc1_data_a_out              (adc1_data_a  ),
//     .adc1_data_b_out              (adc1_data_b  )	 	 

);
wire [255:0] slot_debug;
wire [58:0]  store10k_debug;
slot_timer slot_timer_inst(
		.clk_5mhz(clk_5mhz),
		.clk_50mhz(clk_50mhz),
		.cfg_rst(rst_count[15]),
		.slot_start_count(slot_start_count),
		//////////////////////////////
		.adjust_pos_en(corase_syn_en),
		.adjust_pos(corase_syn_pos),
    /////////////////////////////////
		.cancel_interrupt(cancel_interrupt),
		.rx_dds_en(rx_dds_en),
		.init_rx_slot(init_rx_slot),
		.slot_interrupt_out(slot_interrupt),
		.slot_rx_interrupt(slot_rx_interrupt),
		.slot_dsp_interrupt(tx_slot_dsp_interrupt),
		.debug(slot_debug)
    );
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//// (10) debug signal logic ////   
debug U_debug
    ( 
     .sys_rst                   (sys_rest                ), 

     .clk_400k						  (clk_400k						),
     .clk_5mhz  					  (clk_5mhz						),
     .clk_50mhz  					  (clk_50mhz					),
     .clk_10mhz                 (clk_10mhz               ),
     .clk_20mhz                 (clk_20mhz_2             ),   
     .clk_100mhz                (clk_100mhz              ),  
     .clk_200mhz                (clk_200mhz              ),
     .dac_data_clk				  (dac_data_clk_buf        ),

     
     .dsp2fpga_dsp_rdy          (dsp2fpga_dsp_rdy        ),   
     .lmk04806_1_locked_in      (lmk04806_1_locked_in    ),  
     .lmk04806_1_holdover       (lmk04806_1_holdover     ),
     .lmk04806_2_holdover       (lmk04806_2_holdover     ),
     .tx_slot_dsp_interrupt     (tx_slot_dsp_interrupt   ),
     .rx_data_dsp_interrupt	  (rx_data_dsp_interrupt	),

	  .tx_debug						  (tx_debug                ),
	  .tx_debug_2					  (tx_debug_2              ),
	  .tx_debug_3					  (tx_debug_3              ),
	  .adc_debug					  (debug_adc               ),
	  .adc_debug_2					  (debug_adc_2             ),
	  .ddc_iq_debug				  (ddc_iq_debug            ),
	  .debug_decode				  (debug_decode            ),
	  .debug_data_dsp				  (debug_data_dsp          ),
	  .dec_debug_1					  (debug_dec_1             ),	
	  .dec_debug_2					  (debug_dec_2             ),
	  .mcbsp_debug					  (mcbsp_debug             ),
	  .store10k_debug				  (store10k_debug          ),
	  .slot_debug					  (slot_debug              ),
	  .dac_cfg_debug             (dac_cfg_debug           ),
	  .sys_debug                 (sys_debug               ),
	   //--UART
     .uart_debug                (uart_debug              )
    ); 




////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
endmodule
