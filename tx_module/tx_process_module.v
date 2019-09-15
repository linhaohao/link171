//////////////////////////////////////////////////////////////////////////////////
// Company:         StarPoint
// Engineer:        GUO YAN  
// 
// Create Date:     11:43:20 12/30/2014 
// Module Name:     tx_process_module 
// Project Name:    Link16 Tx process
// Target Devices:  FPGA - XC7K325T - FFG900; 
// Tool versions:   ISE14.6;
// Description:     The module achieve data slot constitute, MSK moduletion and Pulse filter;
//                  data rate is from 5Mcps to 200Mcps, then sampled by DAC complex sampling.
// 
// Revision:        v1.0 - File Created
// Additional Comments: 
// 1. 7.8125ms slot: jitter + SYNC(16DP) + TR(4DP) + Header(16DP) + Data(93*N) + Propagation
// 2. Mudulation: MSK, Pulse Filter: RRC, DAC sample: Complex sample(200Msps/(B=60MHz));
// 3. data rate: 5M => 25M(DDS), (DA inter)200Mcps
// 4. DDS hop-frequency: 9MHz ~ 246MHz
//
//
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

module tx_process_module(
//// clock&reset interface ////
input               clk_msk_in,                             // 50MHz
input               logic_clk_in,                           // 200MHz logic clock
input               logic_rst_in,                           //  reset


//// control signals ////   
input [ 1:0]        net_slot_mode,                          //
input               tx_end_level,                           //txnum ending
input [2:0]         mif_tx_fir_sel,

//// data signals ////
input               tx_data_pulse,                          // 13us one pulse 
input [31:0]        pn_scramble_code,
input [31:0]        tx_ccsk_data,

output              tx_data_en_window_out,
output              tx_data_en,                           // 6.4&6.6 control
output[31:0]        tx_data_out,                          // data to DAC
output              tx_freq_chan_en,                       // ahead of tx_data_en 6.4&6.6 control

output              msk_precode_reg_out,     
output              msk_precode_reg_en_out,
   
//// debug ////
output[127:0]       debug_signal 
	 
   );


//////////////////////////////////////////////////////////////////////////////////
//// signals declaration //// 
reg [63:0]          ccsk_data_reg      = 64'd0;
reg [31:0]          scramble_data      = 32'd0;
reg [ 3:0]          data_pulse_reg     = 4'h0;
                                 
//// MSK signals ////               
reg [11:0]          chip_count         = 12'd0;
reg [31:0]          msk_precode        = 32'd0;
reg                 msk_precode_reg    = 1'b0;
reg                 msk_precode_reg_en = 1'b0;
reg [7:0]           div_5M_cnt         = 8'd0;
reg                 valid_5M_en        = 1'b0;
reg                 vaild_5M_start     = 1'b0;
reg [6:0]           chip_5M_cnt        = 7'd0;

wire                msk_vaild_ahead;
wire                msk_vaild_out;
wire[15:0]          msk_i_out;
wire[15:0]          msk_q_out;
//wire[15:0]          msk_mod_out;

//// filter signals ////
// wire [32:0]         dout_shape_i;
// wire [32:0]         dout_shape_q;

wire [34:0]         dout_shape_i;
wire [34:0]         dout_shape_q;

wire                pulse_rdy_out;
reg [16:0]          fir0_dreg_i        = 17'd0;
reg [16:0]          fir0_dreg_q        = 17'd0;
reg                 pulse_rdy_reg      = 1'b0;

reg [31:0]          tx_filter_out      = 32'd0;
reg                 tx_filter_en       = 1'b0;
                                       
reg[12:0]           tx_data_en_cnt     = 13'd0;
reg                 tx_data_en_reg     = 1'b0;
reg[31:0]           tx_data_reg        = 32'd0;

reg                 tx_data_en_window  = 1'b0;

reg                 tx_filter_en_sel   = 1'b0;  
reg [31:0]          tx_filter_out_sel  = 32'd0; 

reg                 tx_half_filter_en  = 1'b0;
reg  [31:0]         tx_half_filter_out = 32'd0;
wire [31:0]         dout_rc_i;
wire [31:0]         dout_rc_q;

wire                tx_nd;

////debug data
wire[127:0]        debug_msk_signal;


//////////////////////////////////////////////////////////////////////////////////
//// parameters define ////
parameter           s0                  = 32'h7CE90AEC;     // 32bits ccsk code word
//parameter           tx_6_4us_length     = 13'd159;         // 25M*6.4us=160
parameter           tx_6_4us_length     = 13'd319;         // 50M*6.4us=320


//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//// (0) signals assigment //// 
    assign  tx_freq_chan_en              = msk_vaild_ahead;

    assign  tx_data_en_window_out        = tx_data_en_window;
    assign  tx_data_en                   = tx_data_en_reg;
    assign  tx_data_out[31:0]            = tx_data_reg[31:0];
	
	assign msk_precode_reg_out           = msk_precode_reg;   
    assign msk_precode_reg_en_out        = msk_precode_reg_en;
//////////////////////////////////////////////////////////////////////////////////


  

//////////////////////////////////////////////////////////////////////////////////
//// (1) PN code Scrambling ////
always@(posedge logic_clk_in)
begin
   if (logic_rst_in)   begin
      scramble_data[31:0]                <= s0[31:0];
   end
   else if (tx_data_pulse)   begin
      scramble_data[31:0]                <= tx_ccsk_data[31:0] ^ pn_scramble_code[31:0]; //// align at data_pulse_reg[0]
   end
end


always@(posedge logic_clk_in)
begin
   if (logic_rst_in)   begin
      data_pulse_reg[3:0]                <= 4'd0;
   end
   else    begin
      data_pulse_reg[3:0]                <= {data_pulse_reg[2:0],tx_data_pulse};
   end
end


//////////////////////////////////////////////////////////////////////////////////
//// (2) 5M data rate into MSK ////
////200M clk output 5M data //// 
always@(posedge logic_clk_in)
begin
   if (logic_rst_in)   begin
      msk_precode[31:0]                  <= 32'd0;
   end
   else if(data_pulse_reg[0])begin
      msk_precode[31:0]                  <= scramble_data[31:0]; 
   end
   else if(vaild_5M_start && (div_5M_cnt[7:0] == 8'd0)) begin
      msk_precode[31:0]                  <= {msk_precode[30:0],1'b0}; //5M only bit into MSK
   end
end

always@(posedge logic_clk_in)
begin
   if (logic_rst_in)   begin  //slot reset
       vaild_5M_start                    <= 1'b0; 
       div_5M_cnt[7:0]                   <= 8'd0;
   end                                   
   else if(data_pulse_reg[0])  begin   
       vaild_5M_start                    <= 1'b1;   
       div_5M_cnt[7:0]                   <= 8'd0;
   end
   else if(div_5M_cnt[7:0] == 8'd39)begin  
       div_5M_cnt[7:0]                   <= 8'd0; //5M rate = 40/200clk
   end                                   
   else if(vaild_5M_start)begin     
       div_5M_cnt[7:0]                   <= div_5M_cnt[7:0] + 1'b1;
   end
end

always@(posedge logic_clk_in)
begin
   if (logic_rst_in)   begin  //slot reset
       valid_5M_en                       <= 1'b0; 
   end                                   
   else if(vaild_5M_start && (div_5M_cnt[7:0] == 8'd39))begin  
       valid_5M_en                       <= 1'b1; ////align at 5M end
   end                                   
   else begin     
       valid_5M_en                       <= 1'b0; 
   end
end

// always@(posedge logic_clk_in)
// begin
   // if (logic_rst_in)   begin
      // msk_precode_reg                    <= 1'b0;
   // end
   // else if(vaild_5M_start && (div_5M_cnt[7:0] == 8'd0))begin 
     ////msk_precode[31:0]                  <= {1'b0,msk_precode[31:1]}; //5M only bit into MSK
	  ////msk_precode_reg                    <= msk_precode[0]; //LSB first, MSB later
       // msk_precode[31:0]                  <= {msk_precode[30:0],1'b0}; //5M only bit into MSK
	   // msk_precode_reg                    <= msk_precode[31]; // MSB first,LSB later	  
   // end
// end

always@(posedge logic_clk_in)
begin
   if (logic_rst_in)   begin
      msk_precode_reg                     <= 1'b0;
   end
   else if(vaild_5M_start && (div_5M_cnt[7:0] == 8'd0))begin 
	   msk_precode_reg                    <= msk_precode[31]; // MSB first,LSB later	  
   end
end

/////(13us:6.4us/32bits = 200ns/bit)
always@(posedge logic_clk_in)
begin
   if (logic_rst_in)   begin
      chip_5M_cnt[6:0]                 <= 7'd0;
   end
   else if(valid_5M_en && (chip_5M_cnt[6:0] == 7'd64)) begin
      chip_5M_cnt[6:0]                 <= 7'd0;  
   end
   else if(valid_5M_en) begin  //from 0-31 6.4us, 32-64 6.6us
      chip_5M_cnt[6:0]                 <= chip_5M_cnt[6:0] + 1'b1; 
   end
end

always@(posedge logic_clk_in)
begin
   if (logic_rst_in)   begin
      msk_precode_reg_en                <= 1'b0;
   end
   else if(data_pulse_reg[1:0] == 2'b10) begin
      msk_precode_reg_en                <= 1'b1; //start begin (chip_5M_cnt[6:0] == 7'd0)
   end
   else if(valid_5M_en && (chip_5M_cnt[6:0] < 7'd31)) begin 
      msk_precode_reg_en                <= 1'b1; //6.4&6.6us
   end
   else if(valid_5M_en && (chip_5M_cnt[6:0] >= 7'd31)) begin
      msk_precode_reg_en                <= 1'b0;
   end
end



//////////////////////////////////////////////////////////////////////////////////
//// (3) MSK modulation ////
msk_top u_msk_top(
         .clk_msk_in(clk_msk_in),
		 .logic_clk_in(logic_clk_in),
         .logic_rst_in(logic_rst_in),
		 .msk_data_in_pulse(msk_precode_reg_en),
		 .msk_data_in_5M(valid_5M_en),
         .msk_data_in(msk_precode_reg), 
		 .msk_data_cnt(chip_5M_cnt[6:0]),
	     //.msk_vaild_out(msk_vaild_out),
         //.msk_mod_out(msk_mod_out[15:0]),
		 .msk_vaild_ahead(msk_vaild_ahead),
		 .msk_vaild_out(msk_vaild_out), //6.4&6.6us
         .msk_i_out(msk_i_out[15:0]),
         .msk_q_out(msk_q_out[15:0]),
         .debug_msk_signal(debug_msk_signal[127:0])
        ); 

//////////////////////////////////////////////////////////////////////////////////
//// (4) Pulse-shape Filter(1x) ////    MSK output 25M sample which 5M data rate
assign tx_nd = mif_tx_fir_sel[2] ? msk_vaild_out : 1'b1;

tx_half_band_shape   tx_half_band_shape //tx coe same with rx half_band1_filter
   (
	.clk(clk_msk_in),
	.sclr(logic_rst_in), 	
	.ce(1'b1),
	//.nd(msk_vaild_out),   //6.4us&6.6us,continuous 1 in 6.4us           // 50Mchip/s
	.nd(tx_nd),
	.din_1(msk_i_out[15:0]),
	.din_2(msk_q_out[15:0]),
	.dout_1(dout_shape_i[34:0]),
	.dout_2(dout_shape_q[34:0]),
	.rfd(),                                                             // core is ready for new data
	.rdy(pulse_rdy_out)   //delay 15clk(50M),every rdy occupy 6.4us     // filter out is ready	
	);
	
//// pulse-shaping filter data truncation ////
always@(posedge clk_msk_in)
begin
   if (logic_rst_in)   begin
	  tx_half_filter_en                        <= 1'b0;
	  tx_half_filter_out[31:0]                 <= 32'd0;
	end
	else    begin
     if (!dout_shape_i[34] && dout_shape_i[33])   begin
	    tx_half_filter_out[15:0]               <= 16'h7FFE;	  
	  end
	  else if (dout_shape_i[34] && !dout_shape_i[33])   begin
	    tx_half_filter_out[15:0]               <= 16'h8001;	  
	  end
	  else   begin
	    tx_half_filter_out[15:0]               <= dout_shape_i[33:18];
	  end

     if (!dout_shape_q[34] && dout_shape_q[33])   begin
	    tx_half_filter_out[31:16]              <= 16'h7FFE;	  
	  end
	  else if (dout_shape_q[34] && !dout_shape_q[33])   begin
	    tx_half_filter_out[31:16]              <= 16'h8001;	  
	  end
	  else   begin
	    tx_half_filter_out[31:16]              <= dout_shape_q[33:18];
	  end
	  
	  tx_half_filter_en                        <= pulse_rdy_out;
   end
end
	
/////RC shape fir ////////////////////////////////////////////////////////
tx_rc_shape   tx_rc_shape 
   (
	.clk(clk_msk_in),
	.sclr(logic_rst_in), 	
	.ce(1'b1),
	.nd(tx_half_filter_en),   //6.4us&6.6us,continuous 1 in 6.4us           // 25Mchip/s
	.din_1(tx_half_filter_out[15:0]),
	.din_2(tx_half_filter_out[31:16]),
	.dout_1(dout_rc_i[31:0]),
	.dout_2(dout_rc_q[31:0]),
	.rfd(),                                                             // core is ready for new data
	.rdy(rc_rdy_out)   //delay 19clk,every rdy occupy 6.4us     // filter out is ready	
	);

//// pulse-shaping filter data truncation ////
always@(posedge clk_msk_in)
begin
   if (logic_rst_in)   begin
	  tx_filter_en                        <= 1'b0;
	  tx_filter_out[31:0]                 <= 32'd0;
	end
	else    begin
     if (!dout_rc_i[31] && dout_rc_i[30])   begin
	    tx_filter_out[15:0]               <= 16'h7FFE;	  
	  end
	  else if (dout_rc_i[31] && !dout_rc_i[30])   begin
	    tx_filter_out[15:0]               <= 16'h8001;	  
	  end
	  else   begin
	    tx_filter_out[15:0]               <= dout_rc_i[30:15];
	  end

     if (!dout_rc_q[31] && dout_rc_q[30])   begin
	    tx_filter_out[31:16]              <= 16'h7FFE;	  
	  end
	  else if (dout_rc_q[31] && !dout_rc_q[30])   begin
	    tx_filter_out[31:16]              <= 16'h8001;	  
	  end
	  else   begin
	    tx_filter_out[31:16]              <= dout_rc_q[30:15];
	  end
	  
	  tx_filter_en                        <= rc_rdy_out;
   end
end

/////////////////////////////////////////////////////////////////////////////
always@(posedge clk_msk_in)
begin
   if (logic_rst_in)   begin
	 	tx_filter_en_sel                 <= 1'b0;
		tx_filter_out_sel[31:0]          <= 32'd0;
	end
	else begin
	     case(mif_tx_fir_sel[1:0])	  
		   2'd0: begin
		         tx_filter_en_sel        <= tx_filter_en;
		         tx_filter_out_sel[31:0] <= tx_filter_out[31:0];
		   end
		   2'd1: begin
		         tx_filter_en_sel        <= tx_half_filter_en;
		         tx_filter_out_sel[31:0] <= tx_half_filter_out[31:0];
		   end
		   default: begin
		   		 tx_filter_en_sel        <= tx_filter_en;
		         tx_filter_out_sel[31:0] <= tx_filter_out[31:0];
		   end
		endcase
   end
end

//////////////////////////////////////////////////////////////////////////
//// output logic ////
always@(posedge clk_msk_in)
begin
   if (logic_rst_in)   begin
	 tx_data_en_cnt[12:0]               <= 13'd0;
	end
	else if(tx_data_en_cnt[12:0] == tx_6_4us_length)begin
	 tx_data_en_cnt[12:0]               <= 13'd0;
	end
	else if(tx_data_en_reg)begin
	 tx_data_en_cnt[12:0]               <= tx_data_en_cnt[12:0] + 1'b1;
   end
end

always@(posedge clk_msk_in)
begin
   if (logic_rst_in)   begin
	 tx_data_en_reg                     <= 1'b0;
	end
	else if(tx_data_en_cnt[12:0] == tx_6_4us_length)begin
	 tx_data_en_reg                     <= 1'b0;
	end
	else if(tx_filter_en_sel)begin
	 tx_data_en_reg                     <= 1'b1; //6.4us && 6.6us
   end
end

always@(posedge clk_msk_in)
begin
   if (logic_rst_in)   begin
	 tx_data_reg[31:0]                  <= 32'd0;
	end
	else   begin  
     tx_data_reg[31:0]                  <= tx_filter_out_sel[31:0];//tx_filter_out[31:0];
   end
end

always@(posedge clk_msk_in)
begin
   if (logic_rst_in)   begin
	 tx_data_en_window                  <= 1'b0;
	end                                 
	else if(tx_end_level)begin                      
	 tx_data_en_window                  <= 1'b0;
	end                                 
	else if(tx_filter_en_sel)begin  
	 tx_data_en_window                  <= 1'b1; //txnum en 
   end
end

//////////////////////////////////////////////////////////////////////////////////
//// (10) debug signals ////
assign  debug_signal[0]                 = data_pulse_reg[0];
assign  debug_signal[1]                 = vaild_5M_start;
assign  debug_signal[9:2]               = div_5M_cnt[7:0];
assign  debug_signal[10]                = valid_5M_en;
assign  debug_signal[11]                = msk_precode_reg;
assign  debug_signal[12]                = msk_precode_reg_en;
                                      
assign  debug_signal[13]                = pulse_rdy_out;
assign  debug_signal[14]                = tx_half_filter_en;       
assign  debug_signal[30:15]             = tx_half_filter_out[15:0];
assign  debug_signal[46:31]             = tx_data_out[31:16];

//assign  debug_signal[46:15]             =scramble_data[31:0];

assign  debug_signal[47]                = tx_filter_en_sel; 
assign  debug_signal[50:48]             = mif_tx_fir_sel[2:0]; 
assign  debug_signal[51]                = rc_rdy_out;
assign  debug_signal[52]                = 1'd0; //lp_rdy_out;
assign  debug_signal[53]                = tx_nd;
assign  debug_signal[55:54]             = 2'd0; 

assign  debug_signal[87:56]             = tx_filter_out[31:0];

assign  debug_signal[103:88]             = msk_i_out[15:0];
assign  debug_signal[119:104]            = dout_shape_i[15:0];

//assign  debug_signal[119:88]            = scramble_data[31:0];
assign  debug_signal[127:120]           = 8'd0;
//assign  debug_signal[127:56]            = debug_msk_signal[127:56];
//-------------------------------------------------------------------



//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
endmodule
