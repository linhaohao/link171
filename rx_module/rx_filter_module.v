//////////////////////////////////////////////////////////////////////////////////
// Company:         StarPoint
// Engineer:        GUO YAN  
// 
// Create Date:     14:16:06 09/11/2015  
// Module Name:     rx_filter_module 
// Project Name:    Rx filter process module;
// Target Devices:  FPGA - XC7K325T - FFG900; 
// Tool versions:   ISE14.6;   
// Description: 
//
//
// Revision:        v1.0 - File Created
// Additional Comments: 
// 1. data rate: 200M -> 100M -> 50M -> 25M;
// 2. 3 halfband filter + 1 pulse-shaping filter;
//
//
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps


module rx_filter_module(
//// clock/reset ////
input               logic_clk_in,                           // 200MHz logic clock
input               logic_rst_in,

//// data signal ////
input [31:0]        data_fir_in,
output[31:0]        data_fir_out,

output              fir_rdy_out,

//// debug ////
output[199:0]       debug_signal

    );


//////////////////////////////////////////////////////////////////////////////////
//// signals declaration ////
wire[33:0]          fir0_dout_i;
wire[33:0]          fir0_dout_q;
wire                fir0_rdy_out;
reg                 fir0_rdy_reg;
reg [16:0]          fir0_dreg_i;
reg [16:0]          fir0_dreg_q;

reg                 fir1_nd_in;
wire [31:0]         fir1_data_in;
wire [34:0]         fir1_dout_i;
wire [34:0]         fir1_dout_q;
wire                fir1_rdy_out;
reg                 fir1_rdy_reg;
reg [16:0]          fir1_dreg_i;
reg [16:0]          fir1_dreg_q;

reg                 fir2_nd_in;
wire [31:0]         fir2_data_in;
wire [36:0]         fir2_dout_i;
wire [36:0]         fir2_dout_q;
wire                fir2_rdy_out;
reg                 fir2_rdy_reg;
reg [16:0]          fir2_dreg_i;
reg [16:0]          fir2_dreg_q;

reg                 fir3_nd_in;
wire [31:0]         fir3_data_in;
wire [32:0]         fir3_dout_i;
wire [32:0]         fir3_dout_q;
wire                fir3_rdy_out;
reg                 fir3_rdy_reg;
reg [16:0]          fir3_dreg_i;
reg [16:0]          fir3_dreg_q;

reg                 fir_rdy_reg;
wire [31:0]          data_fir_reg;


//////////////////////////////////////////////////////////////////////////////////
//// parameter defination ////


//////////////////////////////////////////////////////////////////////////////////
//// (0) signal assigment ////
assign              fir_rdy_out             = fir_rdy_reg;
assign              data_fir_out[31:0]      = data_fir_reg[31:0];


//////////////////////////////////////////////////////////////////////////////////
//// (1) halfband filter-0 ////
half_band0_filter   u0_hf0_filter  
    (
	.clk(logic_clk_in),
	.sclr(logic_rst_in),	
	.ce(1'b1),
	.nd(1'b1),                                               // 200Mchips/s
	
	.din_1(data_fir_in[15:0]),
	.din_2(data_fir_in[31:16]),
	.dout_1(fir0_dout_i[33:0]),
	.dout_2(fir0_dout_q[33:0]),//16bit*18bit=34bit
	
	.rfd(),
	.rdy(fir0_rdy_out)	 
	  
	 );   

//// data truncation ////
//always@(posedge logic_clk_in)
//begin
//   if (logic_rst_in)   begin
//	  fir1_nd_in                         <= 1'b0;
//	  fir1_data_in[31:0]                 <= 32'd0;
//	end
//	else    begin
//     if (!fir0_dout_i[33] && fir0_dout_i[32])   begin
//	    fir1_data_in[15:0]               <= 16'h7FFE;	  
//	  end
//	  else if (fir0_dout_i[33] && !fir0_dout_i[32])   begin
//	    fir1_data_in[15:0]               <= 16'h8001;	  
//	  end
//	  else   begin
//	    fir1_data_in[15:0]               <= fir0_dout_i[32:17];
//	  end
//
//     if (!fir0_dout_q[33] && fir0_dout_q[32])   begin
//	    fir1_data_in[31:16]              <= 16'h7FFE;	  
//	  end
//	  else if (fir0_dout_q[33] && !fir0_dout_q[32])   begin
//	    fir1_data_in[31:16]              <= 16'h8001;	  
//	  end
//	  else   begin
//	    fir1_data_in[31:16]              <= fir0_dout_q[32:17];
//	  end
//	  
//	  fir1_nd_in                         <= fir0_rdy_out;
//   end
//end


wire   [17 :0]      fir0_dout_i_rnd;
wire   [17 :0]      fir0_dout_q_rnd; 
wire   [17 :0]      fir1_dout_i_rnd;
wire   [17 :0]      fir1_dout_q_rnd;
wire   [17 :0]      fir2_dout_i_rnd; 
wire   [17 :0]      fir2_dout_q_rnd; 
wire   [17 :0]      fir3_dout_i_rnd; 
wire   [17 :0]      fir3_dout_q_rnd; 
reg                 fir0_rdy_out_dly; 
reg                 fir1_rdy_out_dly;
reg                 fir2_rdy_out_dly;
reg                 fir3_rdy_out_dly;
rnd #
  (     
    .IN_WIDTH                          ( 34                 ),//34
    .RND_WIDTH                         ( 16                 ) //16
  ) u0_rnd (                                                   
    .clk                               ( logic_clk_in       ),
    .rst                               ( logic_rst_in       ),
    .din_i                             ( fir0_dout_i        ),
    .din_q                             ( fir0_dout_q        ),
                                       
    .dout_i                            ( fir0_dout_i_rnd    ),
    .dout_q                            ( fir0_dout_q_rnd    )
   );
   
   
sat #
 (     
   .IN_WIDTH                          ( 18                 ),//18
   .SAT_WIDTH                         ( 2                  ) //2
 ) u0_sat(                                                    
   .clk                               ( logic_clk_in       ),
   .rst                               ( logic_rst_in       ),
   .din_i                             ( fir0_dout_i_rnd    ),
   .din_q                             ( fir0_dout_q_rnd    ),
          
   .dout_i                            ( fir1_data_in[15:0]  ),
   .dout_q                            ( fir1_data_in[31:16] )
  );   

always@(posedge logic_clk_in)
begin
	fir0_rdy_out_dly  <= fir0_rdy_out;
	fir1_nd_in        <= fir0_rdy_out_dly;
end





//////////////////////////////////////////////////////////////////////////////////
//// (2) halfband filter-1 ////
half_band1_filter   u1_hf1_filter
    (
	.clk(logic_clk_in),
	.sclr(logic_rst_in),	
	.ce(1'b1),
	.nd(fir1_nd_in),                                         // 100Mchips/s
	
	.din_1(fir1_data_in[15:0]),
	.din_2(fir1_data_in[31:16]),
	.dout_1(fir1_dout_i[34:0]),
	.dout_2(fir1_dout_q[34:0]),//16bit*19bit=35bit
	
	.rfd(),
	.rdy(fir1_rdy_out)	 
	  
	 );   

//// data truncation ////
//always@(posedge logic_clk_in)
//begin
//   if (logic_rst_in)   begin
//	  fir2_nd_in                         <= 1'b0;
//	  fir2_data_in[31:0]                 <= 32'd0;
//	end
//	else    begin
//     if (!fir1_dout_i[34] && fir1_dout_i[33])   begin
//	    fir2_data_in[15:0]               <= 16'h7FFE;	  
//	  end
//	  else if (fir1_dout_i[34] && !fir1_dout_i[33])   begin
//	    fir2_data_in[15:0]               <= 16'h8001;	  
//	  end
//	  else   begin
//	    fir2_data_in[15:0]               <= fir1_dout_i[33:18];
//	  end
//
//     if (!fir1_dout_q[34] && fir1_dout_q[33])   begin
//	    fir2_data_in[31:16]              <= 16'h7FFE;	  
//	  end
//	  else if (fir1_dout_q[34] && !fir1_dout_q[33])   begin
//	    fir2_data_in[31:16]              <= 16'h8001;	  
//	  end
//	  else   begin
//	    fir2_data_in[31:16]              <= fir1_dout_q[33:18];
//	  end
//	  
//	  fir2_nd_in                         <= fir1_rdy_out;
//   end
//end


rnd #
  (     
    .IN_WIDTH                          ( 35                 ), //35
    .RND_WIDTH                         ( 17                 )  //17
  ) u1_rnd (                                                   
    .clk                               ( logic_clk_in       ),
    .rst                               ( logic_rst_in       ),
    .din_i                             ( fir1_dout_i        ),
    .din_q                             ( fir1_dout_q        ),
                                       
    .dout_i                            ( fir1_dout_i_rnd    ),
    .dout_q                            ( fir1_dout_q_rnd    )
   );
   
   
sat #
 (     
   .IN_WIDTH                          ( 18                 ), //18
   .SAT_WIDTH                         ( 2                  )  //2
 ) u1_sat(                                                    
   .clk                               ( logic_clk_in       ),
   .rst                               ( logic_rst_in       ),
   .din_i                             ( fir1_dout_i_rnd    ),
   .din_q                             ( fir1_dout_q_rnd    ),
          
   .dout_i                            ( fir2_data_in[15:0]  ),
   .dout_q                            ( fir2_data_in[31:16] )
  ); 
  
always@(posedge logic_clk_in)
begin
	fir1_rdy_out_dly  <= fir1_rdy_out;
	fir2_nd_in        <= fir1_rdy_out_dly;
end


//////////////////////////////////////////////////////////////////////////////////
//// (3) halfband filter-2 ////
half_band2_filter   u2_hf2_filter
    (
	.clk(logic_clk_in),
	.sclr(logic_rst_in),	
	.ce(1'b1),
	.nd(fir2_nd_in),                                         // 50Mchips/s
	
	.din_1(fir2_data_in[15:0]),
	.din_2(fir2_data_in[31:16]),
	.dout_1(fir2_dout_i[36:0]),
	.dout_2(fir2_dout_q[36:0]),//16bit*21bit=37bit
	
	.rfd(),
	.rdy(fir2_rdy_out)	 
	  
	 );   

//// data truncation ////
//always@(posedge logic_clk_in)
//begin
//   if (logic_rst_in)   begin
//	  fir3_nd_in                         <= 1'b0;
//	  fir3_data_in[31:0]                 <= 32'd0;
//	end
//	else    begin
//     if (!fir2_dout_i[36] && fir2_dout_i[35])   begin
//	    fir3_data_in[15:0]               <= 16'h7FFE;	  
//	  end
//	  else if (fir2_dout_i[36] && !fir2_dout_i[35])   begin
//	    fir3_data_in[15:0]               <= 16'h8001;	  
//	  end
//	  else   begin
//	    fir3_data_in[15:0]               <= fir2_dout_i[35:20];
//	  end
//
//     if (!fir2_dout_q[36] && fir2_dout_q[35])   begin
//	    fir3_data_in[31:16]              <= 16'h7FFE;	  
//	  end
//	  else if (fir2_dout_q[36] && !fir2_dout_q[35])   begin
//	    fir3_data_in[31:16]              <= 16'h8001;	  
//	  end
//	  else   begin
//	    fir3_data_in[31:16]              <= fir2_dout_q[35:20];
//	  end
//	  
//	  fir3_nd_in                         <= fir2_rdy_out;
//   end
//end
 
rnd #
  (     
    .IN_WIDTH                          ( 37                 ),   //37
    .RND_WIDTH                         ( 19                 )    //19
  ) u2_rnd (                                                   
    .clk                               ( logic_clk_in       ),
    .rst                               ( logic_rst_in       ),
    .din_i                             ( fir2_dout_i        ),
    .din_q                             ( fir2_dout_q        ),
                                       
    .dout_i                            ( fir2_dout_i_rnd    ),
    .dout_q                            ( fir2_dout_q_rnd    )
   );
   
   
sat #
 (     
   .IN_WIDTH                          ( 18                 ), //18
   .SAT_WIDTH                         ( 2                  ) //2
 ) u2_sat(                                                    
   .clk                               ( logic_clk_in       ),
   .rst                               ( logic_rst_in       ),
   .din_i                             ( fir2_dout_i_rnd    ),
   .din_q                             ( fir2_dout_q_rnd    ),
          
   .dout_i                            ( fir3_data_in[15:0]  ),
   .dout_q                            ( fir3_data_in[31:16] )
  );

always@(posedge logic_clk_in)
begin
	fir2_rdy_out_dly  <= fir2_rdy_out;
	fir3_nd_in        <= fir2_rdy_out_dly;
end


//////////////////////////////////////////////////////////////////////////////////
//// (4) lowpass filter ////
pulse_shape   u3_pulse_shaping_filter
    (
	.clk(logic_clk_in),
	.sclr(logic_rst_in),	
	.ce(1'b1),
	.nd(fir3_nd_in),                                         // 25Mchips/s
	
	.din_1(fir3_data_in[15:0]),
	.din_2(fir3_data_in[31:16]),
	.dout_1(fir3_dout_i[32:0]),
	.dout_2(fir3_dout_q[32:0]),//16bit*16bit=32bit
	
	.rfd(),
	.rdy(fir3_rdy_out)	 
	  
	 );  

//// data truncation ////
//always@(posedge logic_clk_in)
//begin
//   if (logic_rst_in)   begin
//	  fir_rdy_reg                        <= 1'b0;
//	  data_fir_reg[31:0]                 <= 32'd0;
//	end
//	else    begin
//     if (!fir3_dout_i[32] && fir3_dout_i[31])   begin
//	    data_fir_reg[15:0]               <= 16'h7FFE;	  
//	  end
//	  else if (fir3_dout_i[32] && !fir3_dout_i[31])   begin
//	    data_fir_reg[15:0]               <= 16'h8001;	  
//	  end
//	  else   begin
//	    data_fir_reg[15:0]               <= fir3_dout_i[31:16];
//	  end
//
//     if (!fir3_dout_q[32] && fir3_dout_q[31])   begin
//	    data_fir_reg[31:16]              <= 16'h7FFE;	  
//	  end
//	  else if (fir3_dout_q[32] && !fir3_dout_q[31])   begin
//	    data_fir_reg[31:16]              <= 16'h8001;	  
//	  end
//	  else   begin
//	    data_fir_reg[31:16]              <= fir3_dout_q[31:16];
//	  end
//	  
//	  fir_rdy_reg                         <= fir3_rdy_out;
//   end
//end  


rnd #
  (     
    .IN_WIDTH                          ( 33                 ), //33
    .RND_WIDTH                         ( 15                 )  //15
  ) u3_rnd (                                                   
    .clk                               ( logic_clk_in       ),
    .rst                               ( logic_rst_in       ),
    .din_i                             ( fir3_dout_i        ),
    .din_q                             ( fir3_dout_q        ),
                                       
    .dout_i                            ( fir3_dout_i_rnd    ),
    .dout_q                            ( fir3_dout_q_rnd    )
   );
   
   
sat #
 (     
   .IN_WIDTH                          ( 18                 ), //18
   .SAT_WIDTH                         ( 2                  )  //2
 ) u3_sat(                                                    
   .clk                               ( logic_clk_in       ),
   .rst                               ( logic_rst_in       ),
   .din_i                             ( fir3_dout_i_rnd    ),
   .din_q                             ( fir3_dout_q_rnd    ),
          
   .dout_i                            ( data_fir_reg[15:0] ),
   .dout_q                            ( data_fir_reg[31:16])
  );

always@(posedge logic_clk_in)
begin
	fir3_rdy_out_dly  <= fir3_rdy_out;
	fir_rdy_reg       <= fir3_rdy_out_dly;
end

//////////////////////////////////////////////////////////////////////////////////



//////////////////////////////////////////////////////////////////////////////////
//// () debug signals ////
assign  debug_signal[15:0]             = data_fir_out[15:0];
assign  debug_signal[31:16]            = data_fir_out[31:16];

assign  debug_signal[47:32]            = data_fir_in[15:0];
assign  debug_signal[81:48]            = fir0_dout_i[33:0];
assign  debug_signal[97:82]            = fir1_data_in[15:0];

assign  debug_signal[134:98]           = fir2_dout_i[36:0];
assign  debug_signal[150:135]          = fir3_data_in[15:0];

//assign  debug_signal[183:151]          = fir3_dout_i[32:0];

assign  debug_signal[166:151]          = data_fir_in[31:16];
assign  debug_signal[199:167]          = 33'd0;







//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
endmodule
