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
//       。
// Revision:   v1.0 - File Created
// Additional Comments:
//    FPGA所有需要配置器件控制顶层，接口寄存器的读写接口。
////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

module port_cfg_top(
// clock & Reset
input                    clk_10mhz,  
input                    clk_20mhz, 
input 									 clk_20mhz_2,              
input                    sys_rest,    
/////////////////////////////////////////////////////////////
input                    lmk_int2_stat,
//状态信号
input                    dsp_startus_rdy,
input                    lmk_pll_lock,
output                   lmk_stable_lock,

input                    dac_sync_clk,

input                    mif_dac_spi_red,

//// clock chips(LMK04806+LMK04806)

output                   lmk04806_1_spi_clk ,                     
output                   lmk04806_1_spi_sdi ,                     
output                   lmk04806_1_spi_cs  ,                      
input                    lmk04806_1_spi_sdo ,                     
                                                                                                             
output                   lmk04806_2_spi_clk,                       
output                   lmk04806_2_spi_sdi,                       
output                   lmk04806_2_spi_cs,                       
input                    lmk04806_2_spi_sdo,     
///////////////////////////////////////////////////////////
//--TO ADC0                            
output                   adc0_spi_clk, 
output                   adc0_spi_cs , 
input                    adc0_spi_sdo, 
output                   adc0_spi_sdi,  
//--TO ADC1        
output                   adc1_spi_clk ,  
output                   adc1_spi_cs  ,  
input                    adc1_spi_sdo ,  
output                   adc1_spi_sdi ,  
//--TO DAC                                     
input                    mif2dac_frame_stat,
input [31:0]             mif2dac_frame_data,   

input                    freq_en_stat,
input [31:0]             add9957_freq,   
input                    dac_mode_slse,
input [2:0]              mif_dac_rom_mode,
input [31:0]             mif_dac_rom_dl,
input                    mif_rom_stat,
//------
output [2:0]             dac_profile_sel,      
output                   dac_spi_clk,    
output                   dac_spi_cs  ,   
output                   dac_spi_sdi ,   
input                    dac_spi_sdo ,  
output                   dac_io_update, 

input                    dac_stat,
input [31:0]             mif_dac_ioup_time,
///////////////////////////////////////////////////////////
//URT                   
// TO USB PC                   
output                   fpga2usb_uart_txd ,   
input                    usb2fpga_uart_rxd ,   
///////////////////////////////////////////////////////////
//MIF        
// MIF流程:   RS rd -> d_w_p -> mif -> d_r_p -> mif ->RS
//            RS wr -> d_w_p -> spi
output [31:0]            mif_data_in,
output                   mif_en_in,
output [31:0]            mif_rd_data,
output                   mif_rd_valid,
input  [9:0]             mif_addr_out,
input                    mif_rd_stat,
input  [63:0]            mif_data_out,
input                    mif_data_vaild,


//tmp100 i2c
input                    clk_400k,
output 									 dac_spi_end,

output [63:0]            rs_rx_data,  
output                   rs_rx_data_vlde,

///////////////////////////////////////////////////////////

//DEBUG
output                   lmk_failure_led,
output [63:0]            lmk_debug,
output [63:0]            device_rd_debug,   
output [63:0]            device_wr_debug,   
output [63:0]            adc_debug,         
output [63:0]            initial_debug,
output [199:0]           dac_cfg_debug,
output [255:0]           uart_debug

);
 
//////////////////////////////////////////////////////////////////////////////////
//// signal declaration ////
wire[31:0]          if2rf_cfg_wr_data    ;
wire                if2rf_cfg_wr_en      ;
wire                if2rf_cfg_valid      ;
                                               
wire [31:0]         lmk_cfg_data   ;                                             
wire [7:0]          lmk_cfg_addr   ;                                             
wire                lmk_cfg_valid  ;                                             
                                               
wire[7:0]           if2rf_cfg_addr       ;
wire[2:0]           if2rf_cfg_select_mode;
wire[31:0]          rf2if_cfg_rd_data    ;
wire                rf2if_cfg_rd_valid   ;

wire                adc_rd_valid;      
wire                dac_rd_valid;           
wire[31:0]          dac_if_rd_parameter  ;
wire[31:0]          adc_if_rd_parameter  ;
wire                lmk_1_spi_start ;
wire                lmk_2_spi_start ;
wire                adc0_spi_start ;
wire                adc1_spi_start ;
wire                dac_spi_start  ;

wire [31:0]         adc_cfg_data ;
wire [7:0]          adc_cfg_addr ;
wire                adc_cfg_wr   ;
wire                adc_cfg_valid;   
 
wire [31:0]         dac_cfg_data ;
wire [7:0]          dac_cfg_addr ;
wire                dac_cfg_wr   ;
wire                dac_cfg_valid;



wire                dac_rd_en_reg ;  
wire                dac_device_rd_stat;  
wire                adc_rd_en_reg ;  
wire                adc_device_rd_stat;  
wire                lmk_rd_en_reg  ;
wire                lmk_device_rd_stats;   
wire                rf_rd_en_reg ;
wire                rf_device_rd_stat;   
wire                spi_single_en;

wire                initial_en;
wire [31:0]         lmk_if_rd_parameter;
wire                lmk_rd_valid;
wire                i2c_rd_stat;

wire [31:0]         i2c_data_out;
wire                i2c_rd_valid;
wire [31:0]         i2c_rtc_red_data1;
wire                i2c_rtc_valid; 
//----------------------------------
reg [3:0]           freq_en_stat_dl1;
reg                 time_frame_stat;
reg [31:0]          time_frame_data;
//wire                dac_spi_end;
wire                dac_stat_test; 
wire [31:0]         dac_rom_data;      

wire [63:0]            dac_debug;

reg                 dac_cfg_rd_stat;
reg                 dac_rd_en;
//////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////
// DSP TO MCBSP THER
wire                   dsp_red_stat;  
wire                    dsp_wr_en;
wire [31:0]             dsp_wr_data;

wire                   dsp_rd_data_valid;
wire [31:0]            dsp_rd_data; 


///----URAT DEBUG
                     
///////////////////////////////////////////////////////////////////////////////////
//// (*)初始化配置  ////  
initial_ct  U1_initial_ct(
// clock & Reset
        .clk_20mhz                   (clk_20mhz    ),                    
        .sys_rest                     (sys_rest        ),    
       //------
        .dsp_startus_rdy             (dsp_startus_rdy  ),
        .lmk_pll_lock                (lmk_pll_lock     ),
        .initial_en                  (initial_en       ),

        .dsp_rdy_pulse               (dsp_rdy_pulse    ),
        .spi_initial_start           (spi_initial_start),
        .lmk_stable_lock             (lmk_stable_lock  ),
        .repeat_failure_en           (lmk_failure_led  ),
        .debug_signal                (initial_debug    )
);

///////////////////////////////////////////////////////////////////////////////////
//// (*)UART 接口，负责与PC互通  ////  
uart_top  U2_uart_top(
				.clk                         (clk_20mhz        ),
				.rst_n                       (~sys_rest        ),
				.rs232_rx                    (usb2fpga_uart_rxd),
				.rs232_tx                    (fpga2usb_uart_txd),
				.recieve_data                (rs_rx_data       ),
				.recirve_vld                 (rs_rx_data_vlde  ),
				.send_en                     (mif_data_vaild   ),
				.send_data                   (mif_data_out     ),    //保持时间要长
				.send_vld                    (   ),
				.debug_signal                (uart_debug       )
				);


///////////////////////////////////////////////////////////////////////////////////
////(*)读控      ////  
 device_rd_process  U_device_rd_process(
// clk/rst
        .spi_clk_in                  (clk_20mhz          ), 
        .spi_rst_in                  (sys_rest           ),
        //-     -dsp in  frm mcbsp                                           
        .dsp2fpga_dsp_rdy            (lmk_stable_lock    ),  //临时版
        .dsp_rd_stat                 (dsp_red_stat       ),   
        //-     -dsp out to mcbsp               
        .dsp_rd_data                 (dsp_rd_data        ),
        .dsp_rd_data_valid           (dsp_rd_data_valid  ),
         //--mif      in
        .mif_rd_stat                 (mif_rd_stat        ),
        .mif_rd_addr                 (mif_addr_out       ),
        //out mif
        .mif_rd_data                 (mif_rd_data        ),
        .mif_rs_stat                 (mif_rd_valid       ),
         //---- red spi
         //out
        .dac_rd_en_reg               (dac_rd_en_reg      ),
        .dac_device_rd_stat          (dac_device_rd_stat ),  
        .adc_rd_en_reg               (adc_rd_en_reg      ),            
        .adc_device_rd_stat          (adc_device_rd_stat ),   
        .lmk_rd_en_reg               (lmk_rd_en_reg      ),       
        .lmk_device_rd_stat          (lmk_device_rd_stats),               
        .rf_rd_en_reg                (rf_rd_en_reg       ),         
        .rf_device_rd_stat           (rf_device_rd_stat  ),                  
        //in  
        .dac_rd_valid                (dac_rd_valid       ),
        .dac_rd_data                 (dac_if_rd_parameter),
        .adc_rd_valid                (adc_rd_valid       ),
        .adc_rd_data                 (adc_if_rd_parameter),
        .lmk_rd_valid                (lmk_rd_valid       ),
        .lmk_rd_data                 (lmk_if_rd_parameter),   
        .rf2if_cfg_rd_valid          (rf2if_cfg_rd_valid ),  
        .rf2if_cfg_rd_data           (rf2if_cfg_rd_data  ),   
        .i2c_rd_stat                 (i2c_rd_stat        ),
        .i2c_rd_data                 (i2c_data_out       ),
        .i2c_rd_valid                (i2c_rd_valid       ),
        .i2c_rtc_valid               (i2c_rtc_valid      ),
        .i2c_rtc_data                (i2c_rtc_red_data1  ),

        //DEBUG
        .debug_signal                (device_rd_debug    )

);   
///////////////////////////////////////////////////////////////////////////////////
////(*)写控      ////      
device_wr_process  U_device_wr_process(
// clk/rst
        .spi_clk_in                  (clk_20mhz          ), 
        .sys_rest                    (sys_rest           ),
        .rs_clk                      (clk_20mhz          ),
//      IN
        .rs_rx_data_valid            (rs_rx_data_vlde    ),
        .rs_rx_data                  (rs_rx_data         ),     
                                    
        .mcbsp_data                  (dsp_wr_data        ),
        .mcbsp_data_valid            (dsp_wr_en          ),
                              
        .spi_initial_start           (spi_initial_start    ),   
        .dsp_rdy_pulse               (dsp_rdy_pulse        ),
        .initial_en                  (initial_en           ),
//      OUT-------------------------------------
        .dac_cfg_data                (dac_cfg_data         ),
        .dac_cfg_addr                (dac_cfg_addr         ),
        .dac_cfg_valid               (dac_cfg_valid        ),  
        
        .adc_cfg_data                (adc_cfg_data         ),   
        .adc_cfg_addr                (adc_cfg_addr         ),    
        .adc_cfg_valid               (adc_cfg_valid        ), 
          
        .if2rf_cfg_wr_data           (if2rf_cfg_wr_data    ),   
        .if2rf_cfg_addr              (if2rf_cfg_addr       ),   
        .if2rf_cfg_valid             (if2rf_cfg_valid      ),   
        
        .lmk_cfg_data                (lmk_cfg_data         ),    
        .lmk_cfg_addr                (lmk_cfg_addr         ),    
        .lmk_cfg_valid               (lmk_cfg_valid        ),                    
        .spi_single_en               (spi_single_en        ),
        .lmk0_spi_start              (lmk_1_spi_start      ),
        .lmk1_spi_start              (lmk_2_spi_start      ),
        .adc0_spi_start              (adc0_spi_start       ),
        .adc1_spi_start              (adc1_spi_start       ),
        .dac_spi_start               (dac_spi_start        ),
        .adf4351_spi_start           (    ),
        .ads8332_spi_start           (    ),
        .if2rf_cfg_select_mode       (if2rf_cfg_select_mode),
        
        .mif_data_in                 (mif_data_in          ),
        .mif_en_in                   (mif_en_in            ),
        
        .debug_signal	               (device_wr_debug      )  
);    
    
///////////////////////////////////////////////////////////////////////////////////
//// (*)adc 
adc_cfg U2_adc_cfg(
	 // general cfg signals                     
	      .cfg_spi_clk                 (clk_20mhz_2         ), 
	      .cfg_rst_in                  (sys_rest          ),	
       // ADC0 SPI                                      
        .adc0_spi_start              (adc0_spi_start    ),
        .adc0_spi_clk                (adc0_spi_clk      ),
        .adc0_spi_cs                 (adc0_spi_cs       ),	 
        .adc0_spi_sdo                (adc0_spi_sdo      ),	 
        .adc0_spi_sdi                (adc0_spi_sdi      ),	 
       // ADC1 SPI 
        .adc1_spi_start              (adc1_spi_start    ),
        .adc1_spi_clk                (adc1_spi_clk      ),
        .adc1_spi_cs                 (adc1_spi_cs       ),	 
        .adc1_spi_sdo                (adc1_spi_sdo      ),	 
        .adc1_spi_sdi                (adc1_spi_sdi      ),	 
       //-------------------------------------------
       ///dsp mcbsp to adc	        
        .spi_rd_stat                 (adc_device_rd_stat ),
        .spi_rd_en                   (adc_rd_en_reg      ), 
        .spi_single_en               (spi_single_en      ),  
        
        .adc_cfg_valid               (adc_cfg_valid   ),
        .adc_cfg_addr                (adc_cfg_addr    ),  
        .adc_cfg_data                (adc_cfg_data    ), 
        .adc_rd_parameter            (adc_if_rd_parameter),  
        .adc_rd_valid 	             (adc_rd_valid       ),
	      // debug signal	 
	      .debug_signal                (adc_debug          )
	 
	 );
	 
	 
always@(negedge clk_20mhz or posedge sys_rest )
begin
	    if(sys_rest)
	      freq_en_stat_dl1 <= 4'd0; 	
	    else
	      freq_en_stat_dl1 <= {freq_en_stat_dl1[2:0],freq_en_stat}; 	
end	 
//////////////////////////////////////////////////////////////////////////////////
//// (*) 
always@(negedge clk_20mhz or posedge sys_rest )
begin
	    if(sys_rest)
	      time_frame_stat <= 1'd0; 	 	
	  //  else if(dac_mode_slse)
	  //    time_frame_stat <= 1'd0;
	     else if(dac_mode_slse)begin
	            if(mif2dac_frame_stat)
	               time_frame_stat <= 1'd1;
	            else
	               time_frame_stat <= 1'd0;
	     end	            
	   //  else if((freq_en_stat_dl1[3:2] == 2'b01)||mif2dac_frame_stat)
	    else if(freq_en_stat_dl1[3:2] == 2'b01)
	      time_frame_stat <= 1'd1;
	    else
	      time_frame_stat <= 1'd0;	      	
end
//////////////////////////////////////////////////////////////////////////////////
//// (*)
always@(negedge clk_20mhz or posedge sys_rest )
begin	 
	    if(sys_rest)
	      time_frame_data <= 32'd0; 	
	    else if(dac_mode_slse)
	      time_frame_data <= mif2dac_frame_data;//输入0
	    else if(freq_en_stat_dl1[3:2] == 2'b01)
	      time_frame_data <= add9957_freq;//没有输入
	    else
	      time_frame_data <= time_frame_data;
end	 
//////////////////////////////////////////////////////////////////////////////////
//// (*)	
always@(negedge clk_20mhz or posedge sys_rest )
begin	 
	    if(sys_rest)begin
	      dac_cfg_rd_stat <= 1'd0;
	      dac_rd_en       <= 1'd0;
	    end
	    else if(mif_dac_spi_red)begin
	      dac_cfg_rd_stat <= dac_device_rd_stat;
	      dac_rd_en       <= dac_rd_en_reg;
	    end	    
	    else begin
	      dac_cfg_rd_stat <= 1'd0;
	      dac_rd_en       <= 1'd0;
	    end	    
end


///////////////////////////////////////////////////////////////////////////////////
//// (*)dac 
dac_cfg   U3_dac_cfg(
	 // general cfg signals                     	 
	      .cfg_spi_clk              (clk_20mhz         ),
	      .cfg_rst_in                (sys_rest          ),	
	      .dac_sync_clk              (dac_sync_clk      ),
	      .mif_dac_spi_red             (mif_dac_spi_red   ),
	      // DAC SPI configuration     
	      .dac_profile_sel             (dac_profile_sel   ),  
	      .time_frame_stat             (time_frame_stat   ),
        .time_frame_data             (time_frame_data   ),  	 	 
	      .dac_spi_start               (dac_spi_start     ),  
        .dac_io_updte                (dac_io_update     ), 	 
	      .dac_spi_clk                 (dac_spi_clk       ), 
	      .dac_spi_cs                  (dac_spi_cs        ),
	      .dac_spi_sdo                 (dac_spi_sdo       ),
	      .dac_spi_sdi                 (dac_spi_sdi       ), 
        //------------------------------------------
        .mif_dac_ioup_time         (mif_dac_ioup_time),
        
        
     //   .spi_rd_stat                 (dac_device_rd_stat),
         .spi_rd_stat                 (dac_cfg_rd_stat),
      //  .spi_rd_en                   (dac_rd_en_reg), 
         .spi_rd_en                   (dac_rd_en),   
        .spi_single_en               (spi_single_en     ),
                                     
        .dac_cfg_valid               (dac_cfg_valid      ),
        .dac_cfg_addr                (dac_cfg_addr       ),  
        .dac_cfg_data                (dac_cfg_data       ),   
        .dac_rd_parameter            (dac_if_rd_parameter), 
        .dac_rd_valid  	             (dac_rd_valid       ),
        //--------------------------------------------------
      //  .mif_dac_rom_mode            (mif_dac_rom_mode   ),
        .dac_spi_end                 (dac_spi_end        ),
     //   .dac_rom_data                (dac_rom_data       ),
	      // debug signal	             
	      .dac_stat                    (dac_stat           ),
	      .debug_signal                (dac_debug         )
	 );
/////////////////////////////////////////////////////////////////////////////////
//// (*)lmk04806 * 2 
lmk_cfg   U4_lmk_cfg(
	 // general cfg signals                     	 
	      .cfg_spi_clk                 (clk_20mhz),
	      .cfg_rst_in                  (sys_rest),	
        //lmk04806 spi cfg
        .lmk_int2_stat               (lmk_int2_stat),
        .lmk_1_spi_start             (lmk_1_spi_start    ),
        .lmk04806_1_spi_clk          (lmk04806_1_spi_clk ), 
        .lmk04806_1_spi_cs           (lmk04806_1_spi_cs  ), 
        .lmk04806_1_spi_sdo          (lmk04806_1_spi_sdo ), 
        .lmk04806_1_spi_sdi          (lmk04806_1_spi_sdi),  
        .lmk_2_spi_start             (lmk_2_spi_start    ),      
        .lmk04806_2_spi_clk          (lmk04806_2_spi_clk ),       
        .lmk04806_2_spi_cs           (lmk04806_2_spi_cs  ),        
        .lmk04806_2_spi_sdo          (lmk04806_2_spi_sdo ),      
        .lmk04806_2_spi_sdi          (lmk04806_2_spi_sdi ),      
        //--------------------------------------------      
        .spi_rd_stat                 (lmk_device_rd_stats),   
        .spi_rd_en                   (lmk_rd_en_reg  ),  
        .spi_single_en               (spi_single_en      ), 
         
        .lmk_cfg_valid               (lmk_cfg_valid      ),
        .lmk_cfg_addr                (lmk_cfg_addr       ),  
        .lmk_cfg_data                (lmk_cfg_data       ),   
        .lmk_rd_parameter            (lmk_if_rd_parameter), 
        .lmk_rd_valid  	             (lmk_rd_valid       ),
	      // debug signal	 
	      .debug_signal                (lmk_debug          )
	 );
/////////////////////////////////////////////////////////////////////////////////////////////////////////

//-------------------------------------------------------
assign dac_cfg_debug[0]      =  freq_en_stat;
assign dac_cfg_debug[4:1]    =  freq_en_stat_dl1[3:0];
assign dac_cfg_debug[36:5]   =  add9957_freq[31:0];
assign dac_cfg_debug[37]     =  time_frame_stat;
assign dac_cfg_debug[59:38]  =  dac_debug[62:41];
assign dac_cfg_debug[91:60]  =  time_frame_data[31:0];
assign dac_cfg_debug[92]     =  dac_io_update;

















////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////                                                                                                      
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
endmodule                                                                                                                