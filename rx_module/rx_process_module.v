//////////////////////////////////////////////////////////////////////////////////
// Company:         StarPoint
// Engineer:        GUO YAN 
// 
// Create Date:     13:23:57 01/08/2015 
// Module Name:     rx_process_module 
// Project Name:    Link16 Rx process
// Target Devices:  FPGA - XC7K325T - FFG900; 
// Tool versions:   ISE14.6;
// Description:     The module receives Hop-Frequency singals from others JUs by AD9680 complex sampling.
//                  then, achieve singals specturm moving by DDS and data rate decimation and MSK demodulation.
//                  synchronization is nachieved with received signal(SYNC/TR) for data receieving. 
//
// Revision:        v1.0 - File Created
// Additional Comments: 
// 1. ADC9680 sampling rate: 640MCps, IQ=32bits, complex sampling;
// 2. SYNC+TR(16DP+4DP) Synchronization: 4 receieved links parallel processing; 
// 3. Nocorrelation demodulation, differential code;
// 4. dara rate: 200M->25M ;
// 5. decision rule 
//
//
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps


module rx_process_module(
//// clock interface ////
input               logic_clk_in,                           // 200MHz logic clock
input               logic_rst_in,                           // reset

//// control signals ////
input [3:0]         mif_dds50M_sel,
input [11:0]        mif_dec_th_in,
input [1:0]         source_loop_sel_in,

input [1:0]         net_slot_mode,
input [31:0]        slot_timer,
input [31:0]        unsync_timer,
input               tx_slot_interrupt,


//// data signals ////
input [31:0]        data_from_adc0,                          // 200Mchips/s
input [31:0]        data_from_adc1,                          // 200Mchips/s
input [31:0]        data_from_adc2,                          // 200Mchips/s
input [31:0]        data_from_adc3,                          // 200Mchips/s

input               rx_rd_en_in,
input [7:0]         rx_addr_rd_in,
output[31:0]        rx_data_out,

output              rx_slot_interrupt_out,
output              rx_dsp_interrupt_out,

output              tr_cal_suc_out,

output[9:0]         rx_freq_ram_addr_out,
output              rx_freq_ram_rd_out,
input [9:0]         rx_freq_pn_addr_ini_in,   
input               rx_freq_pn_ini_en_in,

output[4:0]         ccsk_ram_addr,                       
input[31:0]         data_ccsk_seq,  

output              coarse_status,    
output              tr_status,        

//// CVs signals ////
input [8:0]         rx_slot_length,

input [31:0]        rx_dds_phase,

input [31:0]        slot_tr_s0,
input [31:0]        pn_scramble_code,

input [31:0]        link_sync_pn,
input [3:0]         link_sync_hop_chan,
input               link_sync_pn_hop_en,

//// debug ////
//input               dds_rst,
input [31:0]        mif_freq_dds,
input               freq_en,
input               dualPuls_en,
output              rx_dds_rom_stat,



output[23:0]        decccsk_dbg,
output[199:0]       debug_signal0,  
output[199:0]       debug_signal1,  
output[127:0]       debug_signal2,
output[199:0]       debug_signal3,
output[199:0]       debug_signal4,
output[199:0]       debug_signal5,
output[199:0]       debug_signal6

    );


//////////////////////////////////////////////////////////////////////////////////
//// signals declaration //// 
//// dds signals ////
reg [31:0]          rx_dds_phase_reg           = 32'd0;

reg [3:0]           rx_dds_wr_ctl              = 4'd0;

reg [27:0]          rx_dds0_phase              = 28'd0;
reg [27:0]          rx_dds1_phase              = 28'd0;
reg [27:0]          rx_dds2_phase              = 28'd0;
reg [27:0]          rx_dds3_phase              = 28'd0;

wire[31:0]          data_dds0_reg;
wire[31:0]          data_dds1_reg;
wire[31:0]          data_dds2_reg;
wire[31:0]          data_dds3_reg;

//// filter signals ////
wire[31:0]          data_filter0_out;
wire[31:0]          data_filter1_out;
wire[31:0]          data_filter2_out;
wire[31:0]          data_filter3_out;

wire                data_filter0_rdy;
wire                data_filter1_rdy;
wire                data_filter2_rdy;
wire                data_filter3_rdy;

//// MSK signals ////
reg[31:0]           data_msk0_in               = 32'd0;
reg[31:0]           data_msk1_in               = 32'd0;
reg[31:0]           data_msk2_in               = 32'd0;
reg[31:0]           data_msk3_in               = 32'd0;

wire                data_msk0_out;
wire                data_msk1_out;
wire                data_msk2_out;
wire                data_msk3_out;

wire[15:0]          tr_msk0_out;
wire[15:0]          tr_msk1_out;
wire[15:0]          tr_msk2_out;
wire[15:0]          tr_msk3_out;


//// decision signals ////
reg[15:0]           data_tr_in                 = 16'd0;
reg                 de_bit_in                  = 1'b0;

wire                coarse_syn_success_out;
wire[4:0]           coarse_position_out; 
	
wire                tr_syn_success_out;
wire                tr_syn_finish_out;
wire[6:0]           tr_position_out;
wire[31:0]          tr_cal_cnt;
    
wire                tr_syn_en; 
wire                coarse_flag;
wire                tr_flag;

//wire                time_slot_data_en;

wire                rx_data_valid;
wire[31:0]          rx_data; 


//// descrambling signals ////
wire [31:0]         descramble_data;


//// CCSK signals ////
wire [ 7:0]         disspread_data;
wire [ 7:0]         rx_buf_in;
wire                disspread_wr_en;

////rx ram signals ////
wire  [31:0]         ram_data_out;

//// debug signals ////
wire  [199:0]        debug_rx_dds_signal;
wire  [199:0]        debug_rx_filter_signal;

wire  [127:0]        debug_demsk_signal;
wire  [199:0]        debug_decision_signal;
wire  [199:0]        debug_fsm_signal;
wire  [127:0]        debug_descramble_signal;
wire  [127:0]        debug_deccsk_signal;
wire  [127:0]        debug_rxbuf_signal;
wire [199:0]         debug_rx_dds_signal2;

//----------------------------
reg [3:0]    freq_en_dl = 4'd0;








//////////////////////////////////////////////////////////////////////////////////
//// parameters define ////


//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//// (0) signals assigment ////
   assign  rx_data_out[31:0]            = ram_data_out[31:0];

   assign  tr_cal_suc_out               = tr_syn_success_out;
   
   assign  coarse_status                = coarse_flag;
   assign  tr_status                    = tr_flag;
   //------------------------------------------2015/11/30 10:57:47
   assign  rx_dds_rom_stat              = coarse_syn_success_out; 
   assign  rx_buf_in                    = (dualPuls_en == 1'b1)? disspread_data:{3'd0,disspread_data[4:0]};
   
   
   
   

//////////////////////////////////////////////////////////////////////////////////
//// (5) four channel selection for data processing
always @(posedge logic_clk_in)
begin
    if(logic_rst_in) begin    
        rx_dds_phase_reg[31:0]           <= 32'd0;
    end
	else begin
	    rx_dds_phase_reg[31:0]           <= rx_dds_phase[31:0]; //prevent RAM delay ！= 1clk
	end
end


//////////////////////////////////////////////////////////////////////////////////
//// 
always @(posedge logic_clk_in)
begin
    if(logic_rst_in)   
       freq_en_dl <= 4'd0;
	else 
	   freq_en_dl[3:0] <= {freq_en,freq_en_dl[3:1]};
end





always @(posedge logic_clk_in)
begin
    if(logic_rst_in) begin    
        rx_dds0_phase[27:0]              <= 28'd0;			
        rx_dds1_phase[27:0]              <= 28'd0;		
        rx_dds2_phase[27:0]              <= 28'd0;		
        rx_dds3_phase[27:0]              <= 28'd0;		
        data_tr_in[15:0]                 <= 16'd0;
        de_bit_in                        <= 1'b0;
    end
    else begin
        case(rx_dds_phase_reg[31:28])
        4'b0001:  
            begin
                rx_dds0_phase[27:0]      <= rx_dds_phase_reg[27:0];
				rx_dds_wr_ctl[3:0]       <= 4'b0001; 
                data_tr_in[15:0]         <= tr_msk0_out[15:0];
                de_bit_in                <= data_msk0_out;			
            end                                        
                                                       
        4'b0010:                           
            begin 
                rx_dds1_phase[27:0]      <= rx_dds_phase_reg[27:0];	
                rx_dds_wr_ctl[3:0]       <= 4'b0010; 				
                data_tr_in[15:0]         <= tr_msk1_out[15:0];
                de_bit_in                <= data_msk1_out;			
            end                          
			                             
        4'b0100:                            
            begin   
                rx_dds2_phase[27:0]      <= rx_dds_phase_reg[27:0];
                rx_dds_wr_ctl[3:0]       <= 4'b0100; 				
                data_tr_in[15:0]         <= tr_msk2_out[15:0];
                de_bit_in                <= data_msk2_out;				
	        end                          
			                             
        4'b1000:                            
            begin 
                rx_dds3_phase[27:0]      <= rx_dds_phase_reg[27:0];	
                rx_dds_wr_ctl[3:0]       <= 4'b1000; 					
                data_tr_in[15:0]         <= tr_msk3_out[15:0];
                de_bit_in                <= data_msk3_out;				
	        end                          
			                             
        default:                              
        	begin  
                rx_dds0_phase[27:0]      <= rx_dds_phase_reg[27:0];			
                rx_dds1_phase[27:0]      <= rx_dds_phase_reg[27:0];		
                rx_dds2_phase[27:0]      <= rx_dds_phase_reg[27:0];		
                rx_dds3_phase[27:0]      <= rx_dds_phase_reg[27:0];	
                rx_dds_wr_ctl[3:0]       <= rx_dds_wr_ctl[3:0]; 				
                data_tr_in[15:0]         <= tr_msk0_out[15:0];
                de_bit_in                <= data_msk0_out;			
        	end
		endcase
	end
end	

////source selection for loopback ////
 always@(posedge logic_clk_in)
 begin
   if (logic_rst_in)   begin
      data_msk0_in[31:0] <= 32'd0;
	  data_msk1_in[31:0] <= 32'd0;
	  data_msk2_in[31:0] <= 32'd0;
	  data_msk3_in[31:0] <= 32'd0;
	end
	else if (source_loop_sel_in[1:0] == 2'b11)   begin  //loopback vs normal
	  data_msk0_in[31:0] <= data_from_adc0[31:0];
	  data_msk1_in[31:0] <= data_from_adc1[31:0];
	  data_msk2_in[31:0] <= data_from_adc2[31:0];
	  data_msk3_in[31:0] <= data_from_adc3[31:0];
	end
	else   begin 
	  data_msk0_in[31:0] <= data_filter0_out[31:0];
	  data_msk1_in[31:0] <= data_filter1_out[31:0];
	  data_msk2_in[31:0] <= data_filter2_out[31:0];
	  data_msk3_in[31:0] <= data_filter3_out[31:0];
	end
end

//////////////////////////////////////////////////////////////////////////////////
//// (1) DDS spectrum move //// 4 links parallel logic 
rx_dds_top   u1_hop_frequency
   (
	// clock&reset signals
	.logic_clk_in(logic_clk_in),                             // 200MHz
	.logic_rst_in(logic_rst_in),
	
	//mif control
	.mif_dds50M_sel(mif_dds50M_sel[3:0]),
	
	// dds control signals
	.dds_fwr_en(rx_dds_wr_ctl[3:0]),                         // dds FCW enable
	
	.dds_fcw_w0(rx_dds0_phase[27:0]),	                     // DDS frequency control word
	.dds_fcw_w1(rx_dds1_phase[27:0]),	
	.dds_fcw_w2(rx_dds2_phase[27:0]),	
	.dds_fcw_w3(rx_dds3_phase[27:0]),	            
	
	// data signals
	.data_in0(data_from_adc0[15:0]),                         // data from AD
    .data_in1(data_from_adc1[15:0]),                         // 200Mchips/s
    .data_in2(data_from_adc2[15:0]),                         // 200Mchips/s
    .data_in3(data_from_adc3[15:0]),                         // 200Mchips/s

	.data_dds0_out(data_dds0_reg[31:0]),                     // 4-links dds output
	.data_dds1_out(data_dds1_reg[31:0]),
	.data_dds2_out(data_dds2_reg[31:0]),
	.data_dds3_out(data_dds3_reg[31:0]),            
	
	
	
//	.dds_rst_in      (dds_rst),
	.mif_freq_dds (mif_freq_dds),
	// debug
	.debug_signal(debug_rx_dds_signal[199:0]),
	.debug_signal1(debug_rx_dds_signal2[199:0])
	
	);

	
	
//////////////////////////////////////////////////////////////////////////////////
//// (2) decimation process logic //// pulse-shaping logic 
rx_filter_top   u2_filter_module
   (
	// clock&reset signals
	.logic_clk_in(logic_clk_in),                     // 200MHz
	.logic_rst_in(logic_rst_in),	
	
	// data signals
	.data_fir0_in(data_dds0_reg[31:0]),              // 4-links complex data(320Mchips/s)
	.data_fir1_in(data_dds1_reg[31:0]),
	.data_fir2_in(data_dds2_reg[31:0]),
	.data_fir3_in(data_dds3_reg[31:0]),              
	
	.data_fir0_out(data_filter0_out[31:0]),        // 4-links baseband data(25Mchips/s)
	.data_fir1_out(data_filter1_out[31:0]),          
	.data_fir2_out(data_filter2_out[31:0]),
	.data_fir3_out(data_filter3_out[31:0]),            
	
	// data ready
	.fir0_rdy_out(data_filter0_rdy),             // fir data output ready indication
	.fir1_rdy_out(data_filter1_rdy),             // not real data vaild,NO.1 fir nd ==1
	.fir2_rdy_out(data_filter2_rdy),             // not used in project
	.fir3_rdy_out(data_filter3_rdy),
	
	// debug
	.debug_signal(debug_rx_filter_signal[199:0])
	
	);

//////////////////////////////////////////////////////////////////////////////////
//// (3) MSK demodulation process ////
msk_demodulation_top   u3_demodulation_module
   (
	// clock&reset signals
	.logic_clk_in(logic_clk_in),                    // 200MHz
	.logic_rst_in(logic_rst_in),	
	
	// data signals
	.data_msk0_in(data_msk0_in[31:0]),              // IQ code data
	.data_msk1_in(data_msk1_in[31:0]),
	.data_msk2_in(data_msk2_in[31:0]),
	.data_msk3_in(data_msk3_in[31:0]),
        
	.data_msk0_out(data_msk0_out),                  // SYNC/TR is 32bits; Header/data is 32bits
	.data_msk1_out(data_msk1_out),
	.data_msk2_out(data_msk2_out),
	.data_msk3_out(data_msk3_out),
	
	.tr_msk0_out(tr_msk0_out[15:0]),
	.tr_msk1_out(tr_msk1_out[15:0]),
	.tr_msk2_out(tr_msk2_out[15:0]),
	.tr_msk3_out(tr_msk3_out[15:0]),

	.debug_signal(debug_demsk_signal[127:0])	
	
	);
	


//////////////////////////////////////////////////////////////////////////////////
//// (4) SYNC/TR PN code correlation decision logic ////
rx_decision_top   u4_decision_module
   (
	// clock&reset signals
	.logic_clk_in(logic_clk_in),
	.logic_rst_in(logic_rst_in),

	// cvs signals
	.mif_dec_th_in(mif_dec_th_in[11:0]),
	
	.link_sync_pn(link_sync_pn[31:0]),
	.link_sync_hop_chan(link_sync_hop_chan[3:0]),
    .link_sync_pn_hop_en(link_sync_pn_hop_en),

	.link_tr_s0(slot_tr_s0[31:0]),                           // TR(4DP) is S0	
	
	// data signals
	.data_corr0_in(data_msk0_out),
	.data_corr1_in(data_msk1_out),
	.data_corr2_in(data_msk2_out),
	.data_corr3_in(data_msk3_out),
	
    .tr_syn_en(tr_syn_en),
    .data_tr_in(data_tr_in[15:0]),//(tr_msk0_out[15:0]),
	
	// decision 
	.coarse_position_out(coarse_position_out[4:0]),
    .coarse_syn_success_out(coarse_syn_success_out), 
	
    .tr_position_out(tr_position_out[6:0]),
    .tr_syn_success_out(tr_syn_success_out),
    .tr_syn_finish_out(tr_syn_finish_out),

	.debug_signal(debug_decision_signal[199:0])	
	
	);
	

//////////////////////////////////////////////////////////////////////////////////
//// (5)rx fsm
rx_fsm_ctrl u_rx_fsm_ctrl
    (
	.logic_clk_in(logic_clk_in),
	.logic_rst_in(logic_rst_in),
		
    .coarse_syn_success(coarse_syn_success_out),
    .coarse_position(coarse_position_out[4:0]), 
	
    .tr_syn_success(tr_syn_success_out),
    .tr_syn_finish(tr_syn_finish_out),
    .tr_position(tr_position_out[6:0]),
	
	.de_bit_in(de_bit_in),
	.rx_slot_length(rx_slot_length[8:0]),
    
    .tr_syn_en_out(tr_syn_en), 
	.coarse_flag_out(coarse_flag),
    .tr_flag_out(tr_flag),
	
	.rx_data_valid_out(rx_data_valid),
    .rx_data_out(rx_data[31:0]),                   
	
    //.time_slot_data_en(time_slot_data_en),
    .rx_freq_ram_addr_out(rx_freq_ram_addr_out[9:0]),
    .rx_freq_ram_rd_out(rx_freq_ram_rd_out),
	.rx_freq_pn_addr_ini_in(rx_freq_pn_addr_ini_in[9:0]),     
    .rx_freq_pn_ini_en_in(rx_freq_pn_ini_en_in), 
	
	.debug_signal(debug_fsm_signal[199:0])	
    );


//////////////////////////////////////////////////////////////////////////////////
//// (5) data descrambling logic ////
rx_descramble_top   u5_descramble_module
   (
	// clock&reset signals
	.logic_clk_in(logic_clk_in),
	.logic_rst_in(logic_rst_in),		
	
	// control signals
	.data_pulse_in(rx_data_valid),//应该有一个脉冲指示码元中间位置进行XOR，否则容易出现很多毛刺
	
	// data signals                      
	.pn_descramble_in(pn_scramble_code[31:0]),               // 32bits descramble PN code
	.data_descramble_in(rx_data[31:0]),                      // demodulation data
	
	.data_descramble_vaild(data_descramble_vaild),
	.data_descramble_out(descramble_data[31:0]),
	
	// debug signals
	.debug_signal(debug_descramble_signal[127:0])
	
	);
	
	
//////////////////////////////////////////////////////////////////////////////////
//// (6) data CCSK logic //// 32bits => 5bits
rx_ccsk_top   u6_ccsk_module
   (
	// clock&reset signals
	.logic_clk_in(logic_clk_in),
	.logic_rst_in(logic_rst_in),		
	
	// control signals
	.data_pulse_in(data_descramble_vaild),

	// data signals
    .ccsk_ram_addr(ccsk_ram_addr[4:0]),                       
    .data_ccsk_seq(data_ccsk_seq[31:0]),  

	.data_ccsk_in(descramble_data[31:0]),
	.data_ccsk_out(disspread_data[7:0]),
	.buffer_wr_out(disspread_wr_en),
	
	// debug signals
	.decccsk_dbg(decccsk_dbg),
	.debug_signal(debug_deccsk_signal[127:0])
		
	);



//////////////////////////////////////////////////////////////////////////////////
//// (7) data buffer to DSP //// 
rx_buffer_top   u7_rx_buffer_module
   (
	// clock&reset signals
	.logic_clk_in(logic_clk_in),
	.logic_rst_in(logic_rst_in),		
	
	// write ram signals
    .data_wr_in(disspread_wr_en),
	.data_in(rx_buf_in),
	
	// write TOA/unsync value
	.toa_wr_in(tr_syn_success_out),
	.slot_timer_in(slot_timer[31:0]),
	.unsync_timer_in(unsync_timer[31:0]),
	.net_slot_mode(net_slot_mode[1:0]),
	.tx_slot_interrupt(tx_slot_interrupt),
	
	// read ram signals
	.ram_rd_in(rx_rd_en_in),
	.addr_rd_in(rx_addr_rd_in[7:0]),
	.ram_data_out(ram_data_out[31:0]),
	
	.rx_slot_length(rx_slot_length[8:0]),
	.rx_slot_interrupt_out(rx_slot_interrupt_out),
	.rx_dsp_interrupt_out(rx_dsp_interrupt_out),
	
	// debug signals
	.debug_signal(debug_rxbuf_signal[127:0])

	);




//////////////////////////////////////////////////////////////////////////////////







//////////////////////////////////////////////////////////////////////////////////
//// (10) debug singals ////
assign  debug_signal0[199:0]                 = debug_decision_signal[199:0];
assign  debug_signal1[199:0]                 = debug_fsm_signal[199:0];
assign  debug_signal2[127:0]                 = {debug_deccsk_signal[42:37],debug_rxbuf_signal[84:0],debug_deccsk_signal[36:0]};
assign  debug_signal3[199:0]                 = debug_rx_dds_signal[199:0];
assign  debug_signal4[199:0]                 = debug_rx_filter_signal[199:0];
assign  debug_signal5[199:0]                 = debug_rx_dds_signal2;   
//--------------------2015/11/28 17:43:46
assign  debug_signal6[27:0]                   =   rx_dds0_phase[27:0]; 
assign  debug_signal6[55:28]                  =   rx_dds1_phase[27:0]; 
assign  debug_signal6[83:56]                  =   rx_dds2_phase[27:0]; 
assign  debug_signal6[111:84]                 =   rx_dds3_phase[27:0];  
assign  debug_signal6[143:112]                =   rx_dds_phase_reg[31:0];
assign  debug_signal6[199:144]                = 55'd0;


//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
endmodule
