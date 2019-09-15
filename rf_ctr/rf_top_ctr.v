/**************************************************************
                      模块描述
    此模块包含了关于射频接受、发射板的所有IO控制、芯片的读、写�
其中关于LVDS差分信号的控制暂时用串口发命令的方式来进行实时控制，
后续需要将差分信号和算法、时隙结合起来进行实时控制�
***************************************************************/
module rf_top_ctr(
input				clk_20mhz,
input				sys_rest,
input				clk_40mhz,
input               clk_50m,
//关于FPGA UART的控制信�
input				rv_uart_vld,		//串口输入命令数据标识
input	[63:0]		rv_uart_data,		//串口输入命令数据
input               tx_rx_switch_out,
input   [35:0]      rf_freq_data,
input   [31:0]      mif_rv_pbr,

output	reg			send_en,			//返给CPU的串口命�
output	reg  [63:0] send_data,
//与射频板接受板间的控�***********************************
input				rfrv_cpld_rxd,
output				rfrv_cpld_txd,
output	[1:0]		sig_mode,			//大小信号切换
output				power_low_en,		//功率衰减使能
//SPI总线	只读�884功率值，不进行写操作
input				spi_di_two,
output				spi_clk_two,
output				spi_cs_two,
//i2c总线
output				i2c_scl_out,
inout				i2c_sda_out,
output				i2c_sda_slect,
output				i2c_device_select,	//为高时进行e2prom的读�
//********************************************************************
//与射频板发射板间的控�
//i2c总线,切换控制tmp和e2prom
output				luch_i2c_scl_out,
inout				luch_i2c_sda_out,
output				luch_i2c_sda_slect,
output				lunch_i2c_tmp_e2p_en,
//发射板MCU控制
input				lunch_cpld_rxd,
output				lunch_cpld_txd,
//射频增益和大小端控制
output	[3:0]		sd_power_low_en,	//衰减增益控制
output				sd_sig_mode,		//信号大小端选择,1--大端
//*****************************************************************
//射频io口测�下面的信号最终由外面进行直接控制，不与cpld相连的信�
/////  RF射频发射�   
output				tx_lo_c1p,
output				tx_lo_c1n,
output				tx_lo_c2p,			//发送时隙接�
output				tx_lo_c2n,
output	[2:0]		pe_slect_p,			//本振选择开�—�
output	[2:0]		pe_slect_n,
output	[3:0]		pdbrf_en_p,			//本振使能
output	[3:0]		pdbrf_en_n,
///////////////  RF射频接受�
output	[3:0]		rv_pdbrf_en_p,		//本振使能
output	[3:0]		rv_pdbrf_en_n,
//*****************dsp上报的寄存器******************
//接收�
output	[15:0]		rv_tmp_data,		//温度�
output	[63:0]		ad_collect,			//ad8332
output	[15:0]		power_collect,		//ad7884
//发射�
output	[15:0]		lunch_i2c_data,		//温度�
output	[63:0]		lunch_ad_collect,	//ad8332
//上报给DSP的数�数字版温�
output  [15:0]      i2c_tmp_one,
output  [15:0]      i2c_tmp_two,
//tmp100 i2c数字�个温度传感器
output              tmp100_scl0,
inout               tmp100_sda0,
output              tmp100_scl1,
inout               tmp100_sda1,
//功放控制
input               rs232_rx,	// RS232接收数据信号
output              rs232_tx,	// RS232发送数据信�
input               power_en,    // 功放静默开�
output              power_send_p,       //功放收发P,高发低收
output              power_send_n,       //功放收发n
output              power_slot_p,       //功放时隙p
output              power_slot_n,       //功放时隙n

output  [3:0]       power_std_collect,  //送给DSP的功放状�
output  [7:0]       pa_temp_collect,    //送给功放的温度�//设备前面板控�
output  [3:0]       panel_led,          //面板led
input               dsp_net_in,         
output  [3:0]		rv_pll,
output  [3:0]		lunch_pll,
//手动控制射频控制�
output  [43:0]      freq_rf_ctr,
output              freq_rf_ctr_stat,
//DA输出数据的增益控�
input   [31:0]      data_da_in,
input               din_stat0,  
input               din_stat1,  
output              dout_stat0, 
output              dout_stat1, 
output  [31:0]      data_da_out,

//dsp给的控制信号
input               dsp_ctr_uart_en,
input    [63:0]     dsp_ctr_uart_data,

output  [84:0]      debug_rf
);

parameter			TIMER_1S_CN		=	25'd20000000;//	25'd20000000;


wire				uart_send_en,luch_i2c_uart_send_en,i2c_uart_send_en,digt_uart_send_en,power_send_en,agc_uart_send_en;
wire	[63:0]		sd_uart_data,luch_sd_uart_data,i2c_uart_data,luch_i2c_uart_data,digt_uart_data,power_uart_data,ags_uart_data;   
reg		[24:0]		time_1s_cnt = 25'd0;
reg					time_1s_en	= 1'b1;

reg     [43:0]      freq_rf_ctr_r      =   44'h08432E147AE;
wire    [35:0]      freq_rf_ctr_slc;
reg                 freq_rf_flag       =   1'b0;
reg                 freq_rf_ctr_stat_r = 1'b0;

wire                panel_led_3;
wire    [7:0]       power_wr_adr;
wire    [7:0]       power_wr_data;
wire    [3:0]	    lunch_att_io;
wire    [1:0]       choose_temp;
wire                waring_led;

//***********产生1s的计数器*************************
always@(posedge clk_20mhz or posedge sys_rest) begin
	if (sys_rest) begin
		time_1s_cnt[24:0]		<=		25'd0;
		time_1s_en				<=		1'b1;
	end
	else if(time_1s_cnt >= TIMER_1S_CN) begin
		time_1s_cnt[24:0]		<=		25'd0;
		time_1s_en				<=		1'b1;
	end
	else begin
		time_1s_cnt[24:0]		<=		time_1s_cnt[24:0] + 1'b1;
		time_1s_en				<=		1'b0;
	end
end
//***************************************************
//射频io口测�
	io_ctr_rf uut (
		.clk_20mhz					(clk_20mhz), 
		.rv_uart_vld				(rv_uart_vld), 
		.rv_uart_data				(rv_uart_data), 
		.tx_rx_switch_out			(tx_rx_switch_out), 
		.mif_rv_pbr     			(mif_rv_pbr), 
        .power_en                   (power_en),
		.tx_lo_c1p					(tx_lo_c1p), 
		.tx_lo_c1n					(tx_lo_c1n), 
		.tx_lo_c2p					(tx_lo_c2p), 
		.tx_lo_c2n					(tx_lo_c2n), 
		.pe_slect_p					(pe_slect_p), 
		.pe_slect_n					(pe_slect_n), 
		.pdbrf_en_p					(pdbrf_en_p), 
		.pdbrf_en_n					(pdbrf_en_n), 
		.lunch_att_io				(lunch_att_io[3:0]	 ),
		//	sd_power_low_en==	{7,8,9,10}
		.sd_power_low_en			(sd_power_low_en[3:0]),	//{luch_spi_di_one,luch_spi_clk_one,luch_spi_do_one,luch_spi_cs_one}), 
		.sd_sig_mode				(sd_sig_mode),		//11		//luch_spi_di_two), 
		.sd_temp_test				(), 
		.sd_levl_en					(), 
		.rv_pdbrf_en_p				(rv_pdbrf_en_p), 
		.rv_pdbrf_en_n				(rv_pdbrf_en_n), 
		.tmp100_e2prom				(), 
		.rs232_rx					(), 
		.rs232_tx					(), 
		// .sig_mode({rv_power_low_en,ini_ctr}), 
		.sig_mode					(sig_mode[1:0]),	//{spi_do_one,spi_cs_one}), 
		.rv_power_low_en			(), //power_low_en
		.i2c_test					()
	);
	
//FPGA与接收板CPLD间的控制************************************
//i2c控制温度 接收�
	i2c_tmp uut_rf1 (
		.sys_clk					(clk_20mhz), 
		.rst						(sys_rest), 
		.time_1s_en					(time_1s_en),
		.rv_uart_vld				(rv_uart_vld), 
		.rv_uart_data				(rv_uart_data), 
		.i2c_uart_send_en			(i2c_uart_send_en), 
		.i2c_uart_data				(i2c_uart_data), 
		.i2c_tmp_data				(rv_tmp_data),
		.i2c_scl_out				(i2c_scl_out), 			//rv_9--i2c_scl_out
		.i2c_sda_out				(i2c_sda_out), 			//rv_10--i2c_sda_out
		.i2c_sda_slect				(i2c_sda_slect),		//rv_11--i2c_sda_slect
		.i2c_tmp_e2p_en				(i2c_device_select),	//rv_12--rv_power_low_en
		.debug_signal				()
	);
	
//spi控制7884，功率检�
//spi1控制  接收�
	rf_ctr_rv uut_u1 (
		.sys_clk					(clk_20mhz), 
		.rst						(sys_rest), 
		.clk_40mhz					(clk_40mhz),
		.time_1s_en					(time_1s_en),
		.rv_uart_vld				(rv_uart_vld), 
		.rv_uart_data				(rv_uart_data), 
		.uart_send_en				(uart_send_en), 
		.sd_uart_data				(sd_uart_data), 
		.ad_collect					(ad_collect),	//ad8332
		.rv_pll						(rv_pll   ),
		.power_collect				(power_collect),
		.rfrv_cpld_rxd				(rfrv_cpld_rxd), //rv_1--spi_di_one
		.rfrv_cpld_txd				(rfrv_cpld_txd), //rv_2--spi_clk_one
		// .spi_do_one					(spi_do_one),//rv_3--spi_do_one 
		// .spi_cs_one					(spi_cs_one),//rv_4--spi_cs_one     
		.spi_di_two					(spi_di_two), 	 //rv_5--spi_di_two
		.spi_clk_two				(spi_clk_two), 	 //rv_6--spi_clk_two
		.spi_cs_two					(spi_cs_two), 	 //rv_7--spi_cs_two
		.ini_ctr					(),				 //rv_8--ini_ctr
		.rv_power_att               (power_low_en),
        .debug_rf					(debug_rf)
	);

	
//**********************************************************
//FPGA与接收板CPLD间的控制************************************
//  发射� 温度控制和MCU状态的接受
	luch_i2c_tmp uut_rf2 (
		.sys_clk					(clk_20mhz), 
		.rst						(sys_rest), 
		.time_1s_en					(time_1s_en),
		.lunch_i2c_data				(lunch_i2c_data),
		.lunch_ad_collect			(lunch_ad_collect),		//ad8332
		.lunch_pll					(lunch_pll),
		.rv_uart_vld				(rv_uart_vld), 
		.rv_uart_data				(rv_uart_data), 
        .pa_temp_collect            (pa_temp_collect),
		.i2c_uart_send_en			(luch_i2c_uart_send_en), 
		.i2c_uart_data				(luch_i2c_uart_data), 
		.i2c_scl_out				(luch_i2c_scl_out), 	//1--luch_spi_di_one
		.i2c_sda_out				(luch_i2c_sda_out), 	//2--luch_spi_clk_one
		.i2c_sda_slect				(luch_i2c_sda_slect),	//3--luch_spi_do_one
		.i2c_tmp_e2p_en				(lunch_i2c_tmp_e2p_en),	//4--luch_spi_cs_one
		.rfrv_cpld_rxd				(lunch_cpld_rxd), 		//5--luch_spi_di_two
		.rfrv_cpld_txd				(lunch_cpld_txd), 		//6--luch_spi_clk_two
        .power_wr_adr               (power_wr_adr        ),
        .power_wr_data              (power_wr_data       ),
        .choose_temp                (choose_temp         ),
		.lunch_att_io				(lunch_att_io[3:0]	 ),
		.debug_signal				()
	);

//数字版温度传感器例化
	digt_i2c_tmp digt_i2c_tmp_u0 (
		.sys_clk                    (clk_20mhz), 
		.rst                        (sys_rest), 
		.time_1s_en					(time_1s_en),
		.rv_uart_vld                (rv_uart_vld), 
		.rv_uart_data               (rv_uart_data), 
		.i2c_uart_send_en           (digt_uart_send_en), 
		.i2c_uart_data              (digt_uart_data), 
		.i2c_scl_out_one            (tmp100_scl0), 
		.i2c_sda_out_one            (tmp100_sda0), 
		.i2c_scl_out_two            (tmp100_scl1), 
		.i2c_sda_out_two            (tmp100_sda1), 
        .i2c_tmp_one                (i2c_tmp_one ),
        .i2c_tmp_two                (i2c_tmp_two ),
		.i2c_sda_slect              (), 
		.debug_signal               ()
	);
//*********功放控制**************************************************
	power_ctr_top power_ctr_top_uut (
		.clk                        (clk_20mhz), 
		.rst_n                      (!sys_rest), 
		.time_1s_en					(time_1s_en),
		.rs232_rx                   (rs232_rx), 
		.rs232_tx                   (rs232_tx), 
        .power_send_p               (power_send_p),
        .power_send_n               (power_send_n),
        .power_slot_p               (power_slot_p),
        .power_slot_n               (power_slot_n),
        .power_en                   (power_en),
        .power_std_collect          (power_std_collect),
        .pa_temp_collect            (pa_temp_collect),
		.rv_uart_vld                (rv_uart_vld), 
		.rv_uart_data               (rv_uart_data), 
        
        .dsp_ctr_uart_en            (dsp_ctr_uart_en          ),
        .dsp_ctr_uart_data          (dsp_ctr_uart_data[63:0]  ),
    
		.uart_send_en               (power_send_en), 
		.sd_uart_data               (power_uart_data)
	);
////////前面板控�

assign  waring_led  =   ((power_std_collect[3:0] == 4'd0) && (rv_pll == 4'd0) && (lunch_pll == 4'd0)) ? 1'b1 : 1'b0;

panel_ctr panel_ctr_u0(
        .clk_20mhz                  (  clk_20mhz           ),
        .panel_sw                   (  1'b0                ),  //panel_sw
        .waring_led                 (waring_led            ),  //有告警信息，则红灯亮
        .panel_led                  (  panel_led[3:0]      ),
        .dsp_net_in                 (  dsp_net_in          ),
        .panel_debug                (                      )  //panel_debug

);
///////DA输出前的增益调节
	att_ctr_top att_ctr_top_u0 (
		.clk_50m                    (clk_50m               ), 
		.clk_20m                    (clk_20mhz             ), 
		.rv_uart_vld                (rv_uart_vld           ), 
		.rv_uart_data               (rv_uart_data          ), 
        .choose_temp                (choose_temp           ),
        .power_en                   (power_en              ),
        .power_wr_adr               (power_wr_adr          ),
        .power_wr_data              (power_wr_data         ),
        .freq_rf_ctr_slc            (freq_rf_ctr_slc[35:0] ),
		.uart_send_en               (agc_uart_send_en      ), 
		.sd_uart_data               (ags_uart_data         ), 
		.data_aa                    (data_da_in            ), 
		.din_stat0                  (din_stat0             ), 
		.din_stat1                  (din_stat1             ), 
		.dout_stat0                 (dout_stat0            ), 
		.dout_stat1                 (dout_stat1            ), 
		.data_out                   (data_da_out           )
	);

assign  freq_rf_ctr_slc[35:0]   =   freq_rf_flag ? freq_rf_ctr_r[35:0]  : rf_freq_data[35:0];
//**********************************************************
//**********************************************************
//得到各个模块更新的数据，放在寄存器中，等待接口模块读�
always@(posedge clk_20mhz) begin
	if (uart_send_en) begin
		send_en		<=	1'b1;
		send_data	<=	sd_uart_data;
        freq_rf_ctr_stat_r  <=  1'b0;
	end
	// else if(luch_uart_send_en) begin
		// send_en		<=	1'b1;
		// send_data	<=	luch_sd_uart_data;
	// end
	else if(i2c_uart_send_en) begin
		send_en		<=	1'b1;
		send_data	<=	i2c_uart_data;
	end
	else if(luch_i2c_uart_send_en) begin
		send_en		<=	1'b1;
		send_data	<=	luch_i2c_uart_data;
	end	
    else if(digt_uart_send_en) begin
		send_en		<=	1'b1;
		send_data	<=	digt_uart_data;
	end    
    else if(power_send_en) begin
		send_en		<=	1'b1;
		send_data	<=	power_uart_data;
	end   
    else if(agc_uart_send_en) begin
		send_en		<=	1'b1;
		send_data	<=	ags_uart_data;
	end
    //得到射频控制字，由串口来控制
	else if(rv_uart_vld && (rv_uart_data[63:48] == 16'hcbbc)) begin
        freq_rf_ctr_r[43:0] <=  rv_uart_data[43:0];
        freq_rf_ctr_stat_r  <=  1'b1;
        freq_rf_flag        <=  rv_uart_data[44];
	end
    //读出接受板的大小信号状态
	else if(rv_uart_vld && (rv_uart_data[63:0] == 64'hbbbb_111a_a222_0000)) begin
		send_en		<=	1'b1;
		send_data	<=	{32'hbbbb_bbbb,30'd0,sig_mode[1:0]};  
	end
	else begin
        freq_rf_ctr_r[43:0] <=  freq_rf_ctr_r[43:0];
		send_en		<=	1'b0;
        freq_rf_ctr_stat_r  <=  1'b0;
    end
end

assign      freq_rf_ctr[43:0]   =   freq_rf_ctr_r[43:0];
assign      freq_rf_ctr_stat    =   freq_rf_ctr_stat_r;
endmodule

