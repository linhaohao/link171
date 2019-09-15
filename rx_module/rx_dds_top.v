//////////////////////////////////////////////////////////////////////////////////
// Company:         StarPoint
// Engineer:        GUO YAN 
// 
// Create Date:     15:05:15 07/30/2015  
// Module Name:     rx_dds_top 
// Project Name:    Link16 Rx process
// Target Devices:  FPGA - XC7K325T - FFG900; 
// Tool versions:   ISE14.6 
// Description:     The  module achieves data spectrum moving by DDS.
//                  Avoid frequency obstruct, 4 links is processed parallel.
//
// Revision:        v1.0 - File Created
// Additional Comments: 
// 1. data rate: 200Mchips/s, BW=60MHz;
// 2. two-stage dds ddc; first stage: 50M(center freq) -> zero freq(center freq), BW=60MHz
//                       second stage: -30Mhz ~ 30MHz  -> zero freq,signal BW(25M or 5M??)
// 3.
//
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps


module rx_dds_top(
//// clock/reset ////
input               logic_clk_in,      // 200MHz logic clock
input               logic_rst_in,

	//mif control
input [3:0]         mif_dds50M_sel,

//// control signal ////
input [ 3:0]        dds_fwr_en,        // 4 links dds frequency control word

input [27:0]        dds_fcw_w0,
input [27:0]        dds_fcw_w1,
input [27:0]        dds_fcw_w2,
input [27:0]        dds_fcw_w3,

//// data signal ////
input [31:0]        data_in0,          // data from AD(16'd0,adc data) or tx msk(msk_q,msk_i)
input [31:0]        data_in1,          // 200Mchips/s
input [31:0]        data_in2,          // 200Mchips/s
input [31:0]        data_in3,          // 200Mchips/s
	
output reg[31:0]        data_dds0_out, 
output reg[31:0]        data_dds1_out, 
output reg[31:0]        data_dds2_out, 
output reg[31:0]        data_dds3_out, 

//// debug ////
input [31:0]        mif_freq_dds,
input               dds_rst_in,

output[199:0]       debug_signal,
output[199:0]       debug_signal1

    );


//////////////////////////////////////////////////////////////////////////////////
//// signals declaration ////
wire signed[15:0]   dds_50M_cos;
wire signed[15:0]   dds_50M_sin;

wire signed [31:0]  multi0_50M_i;                               
wire signed [31:0]  multi1_50M_i;
wire signed [31:0]  multi2_50M_i;
wire signed [31:0]  multi3_50M_i;

wire signed [31:0]  multi0_50M_q;
wire signed [31:0]  multi1_50M_q;
wire signed [31:0]  multi2_50M_q;
wire signed [31:0]  multi3_50M_q;

reg signed[31:0]    dds_50M_multi0_i   = 32'd0;                               
reg signed[31:0]    dds_50M_multi1_i   = 32'd0;
reg signed[31:0]    dds_50M_multi2_i   = 32'd0;
reg signed[31:0]    dds_50M_multi3_i   = 32'd0;
                    
reg signed[31:0]    dds_50M_multi0_q   = 32'd0;
reg signed[31:0]    dds_50M_multi1_q   = 32'd0;
reg signed[31:0]    dds_50M_multi2_q   = 32'd0;
reg signed[31:0]    dds_50M_multi3_q   = 32'd0;
                          
wire      [15:0]    dds_50M_out0_i ;
wire      [15:0]    dds_50M_out1_i ;
wire      [15:0]    dds_50M_out2_i ;                                
wire      [15:0]    dds_50M_out3_i ;
                                    
wire      [15:0]    dds_50M_out0_q ;
wire      [15:0]    dds_50M_out1_q ;
wire      [15:0]    dds_50M_out2_q ;
wire      [15:0]    dds_50M_out3_q ;

wire signed[15:0]   dds0_sin;
wire signed[15:0]   dds1_sin;
wire signed[15:0]   dds2_sin;
wire signed[15:0]   dds3_sin;

wire signed[15:0]   dds0_cos;
wire signed[15:0]   dds1_cos;
wire signed[15:0]   dds2_cos;
wire signed[15:0]   dds3_cos;

wire signed[31:0]   dds_mult0_ii; 
wire signed[31:0]   dds_mult0_qi;
wire signed[31:0]   dds_mult0_qq;
wire signed[31:0]   dds_mult0_iq;

wire signed[31:0]   dds_mult1_ii; 
wire signed[31:0]   dds_mult1_qi; 
wire signed[31:0]   dds_mult1_qq;
wire signed[31:0]   dds_mult1_iq;
  
wire signed[31:0]   dds_mult2_ii;
wire signed[31:0]   dds_mult2_qi;
wire signed[31:0]   dds_mult2_qq;
wire signed[31:0]   dds_mult2_iq;
     
wire signed[31:0]   dds_mult3_ii; 
wire signed[31:0]   dds_mult3_qi; 
wire signed[31:0]   dds_mult3_qq;
wire signed[31:0]   dds_mult3_iq;
     
reg  signed[32:0]   dds_multi0_i       = 33'd0;
reg  signed[32:0]   dds_multi1_i       = 33'd0;
reg  signed[32:0]   dds_multi2_i       = 33'd0;
reg  signed[32:0]   dds_multi3_i       = 33'd0;
                          
reg  signed[32:0]   dds_multi0_q       = 33'd0;
reg  signed[32:0]   dds_multi1_q       = 33'd0;
reg  signed[32:0]   dds_multi2_q       = 33'd0;
reg  signed[32:0]   dds_multi3_q       = 33'd0;
   
wire        [15:0]   ddcout0i;
wire        [15:0]   ddcout1i;
wire        [15:0]   ddcout2i;
wire        [15:0]   ddcout3i;
            
wire        [15:0]   ddcout0q; 
wire        [15:0]   ddcout1q; 
wire        [15:0]   ddcout2q; 
wire        [15:0]   ddcout3q; 

reg [31:0]          data_baseband0     = 32'd0;
reg [31:0]          data_baseband1     = 32'd0;
reg [31:0]          data_baseband2     = 32'd0;
reg [31:0]          data_baseband3     = 32'd0;
wire  [20:0]     dds_50M_out0_i_rnd;
wire  [20:0]     dds_50M_out0_q_rnd; 
wire  [20:0]     dds_50M_out1_i_rnd;
wire  [20:0]     dds_50M_out1_q_rnd;
wire  [20:0]     dds_50M_out2_i_rnd;
wire  [20:0]     dds_50M_out2_q_rnd;
wire  [20:0]     dds_50M_out3_i_rnd;
wire  [20:0]     dds_50M_out3_q_rnd;

wire  [18:0]     dds_multi0_i_rnd; 
wire  [18:0]     dds_multi0_q_rnd; 
wire  [18:0]     dds_multi1_i_rnd; 
wire  [18:0]     dds_multi1_q_rnd; 
wire  [18:0]     dds_multi2_i_rnd; 
wire  [18:0]     dds_multi2_q_rnd; 
wire  [18:0]     dds_multi3_i_rnd; 
wire  [18:0]     dds_multi3_q_rnd; 


//////////////////////////////////////////////////////////////////////////////////
//// parameter defination ////


//////////////////////////////////////////////////////////////////////////////////
//// (0) signal assigment ////
   // 4 links dds output
   //assign  data_dds0_out[31:0]          = {dds_50M_out0_q[15:0],dds_50M_out0_i[15:0]};//data_baseband0[31:0];
   //assign  data_dds1_out[31:0]          = {dds_50M_out1_q[15:0],dds_50M_out1_i[15:0]};//data_baseband1[31:0];
   //assign  data_dds2_out[31:0]          = {dds_50M_out2_q[15:0],dds_50M_out2_i[15:0]};//data_baseband2[31:0];
   //assign  data_dds3_out[31:0]          = {dds_50M_out3_q[15:0],dds_50M_out3_i[15:0]};//data_baseband3[31:0];
//	 assign  data_dds0_out[31:0]          =  data_baseband0[31:0];  
//   assign  data_dds1_out[31:0]          =  data_baseband1[31:0];  
//   assign  data_dds2_out[31:0]          =  data_baseband2[31:0];  
//   assign  data_dds3_out[31:0]          =  data_baseband3[31:0];  
 
////////////////////////////////////////////////////////////////////
always@(*)
begin
	  if(mif_freq_dds[30])begin
	  	data_dds0_out[31:0]          =  {dds_50M_out0_q[15:0],dds_50M_out0_i[15:0]};
	    data_dds1_out[31:0]          =  {dds_50M_out1_q[15:0],dds_50M_out1_i[15:0]};
      data_dds2_out[31:0]          =  {dds_50M_out2_q[15:0],dds_50M_out2_i[15:0]};
      data_dds3_out[31:0]          =  {dds_50M_out3_q[15:0],dds_50M_out3_i[15:0]};
    end
    else begin
	  	data_dds0_out[31:0]          =  data_baseband0[31:0];     	
	    data_dds1_out[31:0]          =  data_baseband1[31:0]; 
      data_dds2_out[31:0]          =  data_baseband2[31:0]; 
      data_dds3_out[31:0]          =  data_baseband3[31:0]; 
    end
end









//////////////////////////////////////////////////////////////////////////////////
//// (1) DDS module for 50M IF
//// (1-0) DDS module ////
hop_frequency_rx   u_rx_dds_50M
   (
	.clk(logic_clk_in),
	.sclr(logic_rst_in),
	.we(1'b1),                                          
	.data(28'd67108864), // 50M*2^28/200M = 2^26
	.sine(dds_50M_sin[15:0]),
	.cosine(dds_50M_cos[15:0])			
	);

//// (1-1) frequency move ///
////  dds(50M,ddc) for channel1-2        data*(cos-isin)     = (data*cos)  + i(-data*sin)
////     (50M,duc) for channel3-4        data*(cos+isin)     = (data*cos)  + i(data*sin)

////channel0
s_mult_16x16 dds_50M_mult0_i(
    .clk(logic_clk_in),
    .a(data_in0[15:0]),        //16-bit
    .b(dds_50M_cos[15:0]),     //16-bit
    .p(multi0_50M_i[31:0])  // 32-bit
);

s_mult_16x16 dds_50M_mult0_q(
    .clk(logic_clk_in),
    .a(data_in0[15:0]),        //16-bit
    .b(dds_50M_sin[15:0]),     //16-bit
    .p(multi0_50M_q[31:0])  // 32-bit
);

////channel1
s_mult_16x16 dds_50M_mult1_i(
    .clk(logic_clk_in),
    .a(data_in1[15:0]),        //16-bit
    .b(dds_50M_cos[15:0]),     //16-bit
    .p(multi1_50M_i[31:0])  // 32-bit
);

s_mult_16x16 dds_50M_mult1_q(
    .clk(logic_clk_in),
    .a(data_in1[15:0]),        //16-bit
    .b(dds_50M_sin[15:0]),     //16-bit
    .p(multi1_50M_q[31:0])  // 32-bit
);

////channel2
s_mult_16x16 dds_50M_mult2_i(
    .clk(logic_clk_in),
    .a(data_in2[15:0]),        //16-bit
    .b(dds_50M_cos[15:0]),     //16-bit
    .p(multi2_50M_i[31:0])  // 32-bit
);

s_mult_16x16 dds_50M_mult2_q(
    .clk(logic_clk_in),
    .a(data_in2[15:0]),        //16-bit
    .b(dds_50M_sin[15:0]),     //16-bit
    .p(multi2_50M_q[31:0])  // 32-bit
);

////channel3
s_mult_16x16 dds_50M_mult3_i(
    .clk(logic_clk_in),
    .a(data_in3[15:0]),        //16-bit
    .b(dds_50M_cos[15:0]),     //16-bit
    .p(multi3_50M_i[31:0])  // 32-bit
);

s_mult_16x16 dds_50M_mult3_q(
    .clk(logic_clk_in),
    .a(data_in3[15:0]),        //16-bit
    .b(dds_50M_sin[15:0]),     //16-bit
    .p(multi3_50M_q[31:0])  // 32-bit
);

/////////50MHz ddc/duc
// always@(posedge logic_clk_in)
// begin
    // if(logic_rst_in) begin 
	  // dds_50M_multi0_i[31:0]   <= 32'd0;
	  // dds_50M_multi0_q[31:0]   <= 32'd0;
	                              
	  // dds_50M_multi1_i[31:0]   <= 32'd0;
	  // dds_50M_multi1_q[31:0]   <= 32'd0;
	                              
	  // dds_50M_multi2_i[31:0]   <= 32'd0;
	  // dds_50M_multi2_q[31:0]   <= 32'd0;
	                              
	  // dds_50M_multi3_i[31:0]   <= 32'd0;
	  // dds_50M_multi3_q[31:0]   <= 32'd0;
    // end
    // else begin
      // dds_50M_multi0_i[31:0]   <= multi0_50M_i[31:0];
      // dds_50M_multi0_q[31:0]   <= multi0_50M_q[31:0];//-multi0_50M_q[31:0]; //daad LOOP
      
      // dds_50M_multi1_i[31:0]   <= multi1_50M_i[31:0];
      // dds_50M_multi1_q[31:0]   <= multi1_50M_q[31:0];//-multi1_50M_q[31:0];
      
      // dds_50M_multi2_i[31:0]   <= multi2_50M_i[31:0];
      // dds_50M_multi2_q[31:0]   <= multi2_50M_q[31:0];
      
      // dds_50M_multi3_i[31:0]   <= multi3_50M_i[31:0];
      // dds_50M_multi3_q[31:0]   <= multi3_50M_q[31:0];
    // end
// end

////////////////////////////////////////////////////////////////////
always@(posedge logic_clk_in)
begin
    if(logic_rst_in) begin 
	  dds_50M_multi0_i[31:0]   <= 32'd0;
	  dds_50M_multi0_q[31:0]   <= 32'd0;	  
    end
    else if(mif_dds50M_sel[0])begin
      dds_50M_multi0_i[31:0]   <= multi0_50M_i[31:0];
      dds_50M_multi0_q[31:0]   <= -multi0_50M_q[31:0];
    end
	else begin
	  dds_50M_multi0_i[31:0]   <= multi0_50M_i[31:0];
      dds_50M_multi0_q[31:0]   <= multi0_50M_q[31:0]; 
	end
end

always@(posedge logic_clk_in)
begin
    if(logic_rst_in) begin 	                              
	  dds_50M_multi1_i[31:0]   <= 32'd0;
	  dds_50M_multi1_q[31:0]   <= 32'd0;
    end
    else if(mif_dds50M_sel[1])begin   
	  dds_50M_multi1_i[31:0]   <= multi1_50M_i[31:0];
      dds_50M_multi1_q[31:0]   <= -multi1_50M_q[31:0];	
    end
	else begin
	  dds_50M_multi1_i[31:0]   <= multi1_50M_i[31:0];
      dds_50M_multi1_q[31:0]   <= multi1_50M_q[31:0];
	end
end

always@(posedge logic_clk_in)
begin
    if(logic_rst_in) begin 	                              
	  dds_50M_multi2_i[31:0]   <= 32'd0;
	  dds_50M_multi2_q[31:0]   <= 32'd0;
    end
	else if(mif_dds50M_sel[2])begin
	  dds_50M_multi2_i[31:0]   <= multi2_50M_i[31:0];
      dds_50M_multi2_q[31:0]   <= -multi2_50M_q[31:0];
	end
    else begin  
      dds_50M_multi2_i[31:0]   <= multi2_50M_i[31:0];
      dds_50M_multi2_q[31:0]   <= multi2_50M_q[31:0];
    end
end

always@(posedge logic_clk_in)
begin
    if(logic_rst_in) begin 
	  dds_50M_multi3_i[31:0]   <= 32'd0;
	  dds_50M_multi3_q[31:0]   <= 32'd0;
    end
	else if(mif_dds50M_sel[3])begin
	  dds_50M_multi3_i[31:0]   <= multi3_50M_i[31:0];
	  dds_50M_multi3_q[31:0]   <= -multi3_50M_q[31:0];
	end
    else begin     
      dds_50M_multi3_i[31:0]   <= multi3_50M_i[31:0];
      dds_50M_multi3_q[31:0]   <= multi3_50M_q[31:0];
    end
end



//// (1-2)Amplitude limiting////
////channel0		
 rnd #
  (     
    .IN_WIDTH                          ( 32                 ),  //32
    .RND_WIDTH                         ( 11                 )   //14
 ) u0_rnd (                                                   
    .clk                               ( logic_clk_in       ),
    .rst                               ( logic_rst_in       ),
    .din_i                             ( dds_50M_multi0_i   ),
    .din_q                             ( dds_50M_multi0_q   ),
                                       
    .dout_i                            ( dds_50M_out0_i_rnd ),
    .dout_q                            ( dds_50M_out0_q_rnd )
   );
   
   
  sat #
   (     
     .IN_WIDTH                          ( 21                 ),//18
     .SAT_WIDTH                         ( 5                  ) //2
   ) u0_sat(                                                    
     .clk                               ( logic_clk_in       ),
     .rst                               ( logic_rst_in       ),
     .din_i                             ( dds_50M_out0_i_rnd ),
     .din_q                             ( dds_50M_out0_q_rnd ),
            
     .dout_i                            ( dds_50M_out0_i     ),
     .dout_q                            ( dds_50M_out0_q     )
    );   

rnd #
  (     
    .IN_WIDTH                          ( 32                 ),
    .RND_WIDTH                         ( 11                 )
  ) u1_rnd (                                                   
    .clk                               ( logic_clk_in       ),
    .rst                               ( logic_rst_in       ),
    .din_i                             ( dds_50M_multi1_i   ),
    .din_q                             ( dds_50M_multi1_q   ),
                                       
    .dout_i                            ( dds_50M_out1_i_rnd ),
    .dout_q                            ( dds_50M_out1_q_rnd )
   );
   
   
sat #
 (     
   .IN_WIDTH                          ( 21                 ),
   .SAT_WIDTH                         ( 5                  )
 ) u1_sat(                                                    
   .clk                               ( logic_clk_in       ),
   .rst                               ( logic_rst_in       ),
   .din_i                             ( dds_50M_out1_i_rnd ),
   .din_q                             ( dds_50M_out1_q_rnd ),
          
   .dout_i                            ( dds_50M_out1_i     ),
   .dout_q                            ( dds_50M_out1_q     )
  );   


rnd #
  (     
    .IN_WIDTH                          ( 32                 ),
    .RND_WIDTH                         ( 11                 )
  ) u2_rnd (                                                   
    .clk                               ( logic_clk_in       ),
    .rst                               ( logic_rst_in       ),
    .din_i                             ( dds_50M_multi2_i   ),
    .din_q                             ( dds_50M_multi2_q   ),
                                       
    .dout_i                            ( dds_50M_out2_i_rnd ),
    .dout_q                            ( dds_50M_out2_q_rnd )
   );
   
   
sat #
 (     
   .IN_WIDTH                          ( 21                 ),
   .SAT_WIDTH                         ( 5                  )
 ) u2_sat(                                                    
   .clk                               ( logic_clk_in       ),
   .rst                               ( logic_rst_in       ),
   .din_i                             ( dds_50M_out2_i_rnd ),
   .din_q                             ( dds_50M_out2_q_rnd ),
          
   .dout_i                            ( dds_50M_out2_i     ),
   .dout_q                            ( dds_50M_out2_q     )
  );   

rnd #
  (     
    .IN_WIDTH                          ( 32                 ),
    .RND_WIDTH                         ( 11                 )
  ) u3_rnd (                                                   
    .clk                               ( logic_clk_in       ),
    .rst                               ( logic_rst_in       ),
    .din_i                             ( dds_50M_multi3_i   ),
    .din_q                             ( dds_50M_multi3_q   ),
                                       
    .dout_i                            ( dds_50M_out3_i_rnd ),
    .dout_q                            ( dds_50M_out3_q_rnd )
   );
   
   
sat #
 (     
   .IN_WIDTH                          ( 21                 ),
   .SAT_WIDTH                         ( 5                  )
 ) u3_sat(                                                    
   .clk                               ( logic_clk_in       ),
   .rst                               ( logic_rst_in       ),
   .din_i                             ( dds_50M_out3_i_rnd ),
   .din_q                             ( dds_50M_out3_q_rnd ),
          
   .dout_i                            ( dds_50M_out3_i     ),
   .dout_q                            ( dds_50M_out3_q     )
  );   
//always@(posedge logic_clk_in) 
//begin
//   if(logic_rst_in)
//      dds_50M_out0_i[15:0]	       <= 16'h0000;
//   else if(!dds_50M_multi0_i[31] && dds_50M_multi0_i[30])
//      dds_50M_out0_i[15:0]	       <= 16'h7ffe;
//   else if(dds_50M_multi0_i[31] && !dds_50M_multi0_i[30])
//      dds_50M_out0_i[15:0]	       <= 16'h8001;
//   else 
//      dds_50M_out0_i[15:0]	       <= dds_50M_multi0_i[30:15];
//end
//
//
//always@(posedge logic_clk_in) 
//begin
//   if(logic_rst_in)
//      dds_50M_out0_q[15:0]	       <= 16'h0000;
//   else if(!dds_50M_multi0_q[31] && dds_50M_multi0_q[30])
//      dds_50M_out0_q[15:0]	       <= 16'h7ffe;
//   else if( dds_50M_multi0_q[31] && !dds_50M_multi0_q[30])
//      dds_50M_out0_q[15:0]	       <= 16'h8001;
//   else 
//      dds_50M_out0_q[15:0]	       <= dds_50M_multi0_q[30:15];
//end
//
//////channel1	
//always@(posedge logic_clk_in) 
//begin
//   if(logic_rst_in)
//      dds_50M_out1_i[15:0]	       <= 16'h0000;
//   else if(!dds_50M_multi1_i[31] && dds_50M_multi1_i[30])
//      dds_50M_out1_i[15:0]	       <= 16'h7ffe;
//   else if(dds_50M_multi1_i[31] && !dds_50M_multi1_i[30])
//      dds_50M_out1_i[15:0]	       <= 16'h8001;
//   else 
//      dds_50M_out1_i[15:0]	       <= dds_50M_multi1_i[30:15];
//end
//
//always@(posedge logic_clk_in) 
//begin
//   if(logic_rst_in)
//      dds_50M_out1_q[15:0]	       <= 16'h0000;
//   else if(!dds_50M_multi1_q[31] && dds_50M_multi1_q[30])
//      dds_50M_out1_q[15:0]	       <= 16'h7ffe;
//   else if( dds_50M_multi1_q[31] && !dds_50M_multi1_q[30])
//      dds_50M_out1_q[15:0]	       <= 16'h8001;
//   else 
//      dds_50M_out1_q[15:0]	       <= dds_50M_multi1_q[30:15];
//end
//
//////channel2
//always@(posedge logic_clk_in) 
//begin
//   if(logic_rst_in)
//      dds_50M_out2_i[15:0]	       <= 16'h0000;
//   else if(!dds_50M_multi2_i[31] && dds_50M_multi2_i[30])
//      dds_50M_out2_i[15:0]	       <= 16'h7ffe;
//   else if(dds_50M_multi2_i[31] && !dds_50M_multi2_i[30])
//      dds_50M_out2_i[15:0]	       <= 16'h8001;
//   else 
//      dds_50M_out2_i[15:0]	       <= dds_50M_multi2_i[30:15];
//end
//
//always@(posedge logic_clk_in) 
//begin
//   if(logic_rst_in)
//      dds_50M_out2_q[15:0]	       <= 16'h0000;
//   else if(!dds_50M_multi2_q[31] && dds_50M_multi2_q[30])
//      dds_50M_out2_q[15:0]	       <= 16'h7ffe;
//   else if( dds_50M_multi2_q[31] && !dds_50M_multi2_q[30])
//      dds_50M_out2_q[15:0]	       <= 16'h8001;
//   else 
//      dds_50M_out2_q[15:0]	       <= dds_50M_multi2_q[30:15];
//end
//
//////channel3
//always@(posedge logic_clk_in) 
//begin
//   if(logic_rst_in)
//      dds_50M_out3_i[15:0]	       <= 16'h0000;
//   else if(!dds_50M_multi3_i[31] && dds_50M_multi3_i[30])
//      dds_50M_out3_i[15:0]	       <= 16'h7ffe;
//   else if(dds_50M_multi3_i[31] && !dds_50M_multi3_i[30])
//      dds_50M_out3_i[15:0]	       <= 16'h8001;
//   else 
//      dds_50M_out3_i[15:0]	       <= dds_50M_multi3_i[30:15];
//end
//
//always@(posedge logic_clk_in) 
//begin
//   if(logic_rst_in)
//      dds_50M_out3_q[15:0]	       <= 16'h0000;
//   else if(!dds_50M_multi3_q[31] && dds_50M_multi3_q[30])
//      dds_50M_out3_q[15:0]	       <= 16'h7ffe;
//   else if( dds_50M_multi3_q[31] && !dds_50M_multi3_q[30])
//      dds_50M_out3_q[15:0]	       <= 16'h8001;
//   else 
//      dds_50M_out3_q[15:0]	       <= dds_50M_multi3_q[30:15];
//end


//-----------------------2015/11/23 16:20:50---------------------------
reg [27:0] dds_data_in0 = 28'd0;
reg [27:0] dds_data_in1 = 28'd0;
reg [27:0] dds_data_in2 = 28'd0;
reg [27:0] dds_data_in3 = 28'd0;    
reg dds_rst;
//--------------------------------------
always@(posedge logic_clk_in) 
begin
   if(mif_freq_dds[31])begin
   	dds_data_in0 <= mif_freq_dds[27:0];
   	dds_data_in1 <= mif_freq_dds[27:0];
   	dds_data_in2 <= mif_freq_dds[27:0];
   	dds_data_in3 <= mif_freq_dds[27:0];
   end
   else begin
    dds_data_in0 <= dds_fcw_w0;
    dds_data_in1 <= dds_fcw_w1;
    dds_data_in2 <= dds_fcw_w2;
    dds_data_in3 <= dds_fcw_w3;
   end
end
//--------------------------------------
always@(posedge logic_clk_in) 
begin
   if(logic_rst_in )
     dds_rst = 1'd1;
   else if(mif_freq_dds[30])
     dds_rst = 1'd0;
   else
     dds_rst = 1'd0;
end


//////////////////////////////////////////////////////////////////////////////////
//// (2) DDS module for hopping//// 4 links parallel logic 
//// (2-0) DDS module ////
	 hop_frequency_rx   u_rx_dds0
	    (
		 .clk(logic_clk_in),
		 .sclr(dds_rst),
		 .we(dds_fwr_en[0]),                                          
	//	 .data(dds_fcw_w0[27:0]),
	   .data(dds_data_in0[27:0]),
		 .sine(dds0_sin[15:0]),
		 .cosine(dds0_cos[15:0])		
		 );
	
//	 (2-1) DDS module////
	 hop_frequency_rx   u_rx_dds1
	    (
		 .clk(logic_clk_in),
		 .sclr(dds_rst),
		 .we(dds_fwr_en[1]),                                          
	//	 .data(dds_fcw_w1[27:0]),
		 .data(dds_data_in1[27:0]),
		 .sine(dds1_sin[15:0]),
		 .cosine(dds1_cos[15:0])		
		 );
	
//	 (2-2) DDS module ////
	 hop_frequency_rx   u_rx_dds2
	    (
		 .clk(logic_clk_in),
		 .sclr(dds_rst),
		 .we(dds_fwr_en[2]),                                          
		// .data(dds_fcw_w2[27:0]),
		 .data(dds_data_in2[27:0]),  
		 .sine(dds2_sin[15:0]),
		 .cosine(dds2_cos[15:0])	
		 );
	
//	 (2-3) DDS module ////
	 hop_frequency_rx   u_rx_dds3
	    (
		 .clk(logic_clk_in),
		 .sclr(dds_rst),
		 .we(dds_fwr_en[3]),                                          
		// .data(dds_fcw_w3[27:0]),  
		  .data(dds_data_in3[27:0]), 
		 .sine(dds3_sin[15:0]),
		 .cosine(dds3_cos[15:0])	
		 );
		
//	 (2-4) frequency move ///
//	  dds(dynamic,ddc) for four channel (data_I+idata_Q)*(cos-isin)  = (data_I*cos + data_Q*sin) + i(data_Q*cos - data_I*sin)
//	dds0 ddc
	 s_mult_16x16 rx_dds_mult0_ii(
	     .clk(logic_clk_in),
	     .a(dds_50M_out0_i[15:0]),        //16-bit
	     .b(dds0_cos[15:0]),     //16-bit
	     .p(dds_mult0_ii[31:0])  // 32-bit
	 );
	
	 s_mult_16x16 rx_dds_mult0_iq(
	     .clk(logic_clk_in),
	     .a(dds_50M_out0_i[15:0]),        //16-bit
	     .b(dds0_sin[15:0]),     //16-bit
	     .p(dds_mult0_iq[31:0])  // 32-bit
	 );
	
	 s_mult_16x16 rx_dds_mult0_qi(
	     .clk(logic_clk_in),
	     .a(dds_50M_out0_q[15:0]),        //16-bit
	     .b(dds0_cos[15:0]),     //16-bit
	     .p(dds_mult0_qi[31:0])  // 32-bit
	 );
	
	 s_mult_16x16 rx_dds_mult0_qq(
	     .clk(logic_clk_in),
	     .a(dds_50M_out0_q[15:0]),        //16-bit
	     .b(dds0_sin[15:0]),     //16-bit
	     .p(dds_mult0_qq[31:0])  // 32-bit
	 );
	
//	dds1 ddc
	 s_mult_16x16 rx_dds_mult1_ii(
	     .clk(logic_clk_in),
	     .a(dds_50M_out1_i[15:0]),        //16-bit
	     .b(dds1_cos[15:0]),     //16-bit
	     .p(dds_mult1_ii[31:0])  // 32-bit
	 );
	
	 s_mult_16x16 rx_dds_mult1_iq(
	     .clk(logic_clk_in),
	     .a(dds_50M_out1_i[15:0]),        //16-bit
	     .b(dds1_sin[15:0]),     //16-bit
	     .p(dds_mult1_iq[31:0])  // 32-bit
	 );
	
	 s_mult_16x16 rx_dds_mult1_qi(
	     .clk(logic_clk_in),
	     .a(dds_50M_out1_q[15:0]),        //16-bit
	     .b(dds1_cos[15:0]),     //16-bit
	     .p(dds_mult1_qi[31:0])  // 32-bit
	 );
	
	 s_mult_16x16 rx_dds_mult1_qq(
	     .clk(logic_clk_in),
	     .a(dds_50M_out1_q[15:0]),        //16-bit
	     .b(dds1_sin[15:0]),     //16-bit
	     .p(dds_mult1_qq[31:0])  // 32-bit
	 );
	
//	dds2 ddc
	 s_mult_16x16 rx_dds_mult2_ii(
	     .clk(logic_clk_in),
	     .a(dds_50M_out2_i[15:0]),        //16-bit
	     .b(dds2_cos[15:0]),     //16-bit
	     .p(dds_mult2_ii[31:0])  // 32-bit
	 );
	
	 s_mult_16x16 rx_dds_mult2_iq(
	     .clk(logic_clk_in),
	     .a(dds_50M_out2_i[15:0]),        //16-bit
	     .b(dds2_sin[15:0]),     //16-bit
	     .p(dds_mult2_iq[31:0])  // 32-bit
	 );
	
	 s_mult_16x16 rx_dds_mult2_qi(
	     .clk(logic_clk_in),
	     .a(dds_50M_out2_q[15:0]),        //16-bit
	     .b(dds2_cos[15:0]),     //16-bit
	     .p(dds_mult2_qi[31:0])  // 32-bit
	 );
	
	 s_mult_16x16 rx_dds_mult2_qq(
	     .clk(logic_clk_in),
	     .a(dds_50M_out2_q[15:0]),        //16-bit
	     .b(dds2_sin[15:0]),     //16-bit
	     .p(dds_mult2_qq[31:0])  // 32-bit
	 );
	
//	dds3 ddc
	 s_mult_16x16 rx_dds_mult3_ii(
	     .clk(logic_clk_in),
	     .a(dds_50M_out3_i[15:0]),        //16-bit
	     .b(dds3_cos[15:0]),     //16-bit
	     .p(dds_mult3_ii[31:0])  // 32-bit
	 );
	
	 s_mult_16x16 rx_dds_mult3_iq(
	     .clk(logic_clk_in),
	     .a(dds_50M_out3_i[15:0]),        //16-bit
	     .b(dds3_sin[15:0]),     //16-bit
	     .p(dds_mult3_iq[31:0])  // 32-bit
	 );
	
	 s_mult_16x16 rx_dds_mult3_qi(
	     .clk(logic_clk_in),
	     .a(dds_50M_out3_q[15:0]),        //16-bit
	     .b(dds3_cos[15:0]),     //16-bit
	     .p(dds_mult3_qi[31:0])  // 32-bit
	 );
	
	 s_mult_16x16 rx_dds_mult3_qq(
	     .clk(logic_clk_in),
	     .a(dds_50M_out3_q[15:0]),        //16-bit
	     .b(dds3_sin[15:0]),     //16-bit
	     .p(dds_mult3_qq[31:0])  // 32-bit
	 );
	
	
	//ddc
	 always@(posedge logic_clk_in)
	 begin
	     if(logic_rst_in) begin
		   dds_multi0_i[32:0]       <= 33'd0;
		   dds_multi0_q[32:0]       <= 33'd0;
		                             
		   dds_multi1_i[32:0]       <= 33'd0;
		   dds_multi1_q[32:0]       <= 33'd0;
		                              
		   dds_multi2_i[32:0]       <= 33'd0;
		   dds_multi2_q[32:0]       <= 33'd0;
		                              
		   dds_multi3_i[32:0]       <= 33'd0;
		   dds_multi3_q[32:0]       <= 33'd0;
	     end
		 else begin
	       dds_multi0_i[32:0]       <= {dds_mult0_ii[31],dds_mult0_ii[31:0]} + {dds_mult0_qq[31],dds_mult0_qq[31:0]};
	       dds_multi0_q[32:0]       <= {dds_mult0_qi[31],dds_mult0_qi[31:0]} - {dds_mult0_iq[31],dds_mult0_iq[31:0]};	                               
	       dds_multi1_i[32:0]       <= {dds_mult1_ii[31],dds_mult1_ii[31:0]} + {dds_mult1_qq[31],dds_mult1_qq[31:0]};
	       dds_multi1_q[32:0]       <= {dds_mult1_qi[31],dds_mult1_qi[31:0]} - {dds_mult1_iq[31],dds_mult1_iq[31:0]};	                               
	       dds_multi2_i[32:0]       <= {dds_mult2_ii[31],dds_mult2_ii[31:0]} + {dds_mult2_qq[31],dds_mult2_qq[31:0]};
	       dds_multi2_q[32:0]       <= {dds_mult2_qi[31],dds_mult2_qi[31:0]} - {dds_mult2_iq[31],dds_mult2_iq[31:0]};	                               
	       dds_multi3_i[32:0]       <= {dds_mult3_ii[31],dds_mult3_ii[31:0]} + {dds_mult3_qq[31],dds_mult3_qq[31:0]};
	       dds_multi3_q[32:0]       <= {dds_mult3_qi[31],dds_mult3_qi[31:0]} - {dds_mult3_iq[31],dds_mult3_iq[31:0]};
	     end
	 end
rnd #
  (     
    .IN_WIDTH                          ( 33                 ), //33
    .RND_WIDTH                         ( 14                 )  //14
  ) u10_rnd (                                                   
    .clk                               ( logic_clk_in       ),
    .rst                               ( logic_rst_in       ),
    .din_i                             ( dds_multi0_i       ),
    .din_q                             ( dds_multi0_q       ),
                                       
    .dout_i                            ( dds_multi0_i_rnd    ),
    .dout_q                            ( dds_multi0_q_rnd    )
   );
   
   
sat #
 (     
   .IN_WIDTH                          ( 19                 ),//19
   .SAT_WIDTH                         ( 3                  ) //3
 ) u10_sat(                                                    
   .clk                               ( logic_clk_in       ),
   .rst                               ( logic_rst_in       ),
   .din_i                             ( dds_multi0_i_rnd   ),
   .din_q                             ( dds_multi0_q_rnd   ),
          
   .dout_i                            ( ddcout0i           ),
   .dout_q                            ( ddcout0q           )
  );   


rnd #
  (     
    .IN_WIDTH                          ( 33                 ),
    .RND_WIDTH                         ( 14                 )
  ) u11_rnd (                                                   
    .clk                               ( logic_clk_in       ),
    .rst                               ( logic_rst_in       ),
    .din_i                             ( dds_multi1_i       ),
    .din_q                             ( dds_multi1_q       ),
                                       
    .dout_i                            ( dds_multi1_i_rnd    ),
    .dout_q                            ( dds_multi1_q_rnd    )
   );
   
   
sat #
 (     
   .IN_WIDTH                          ( 19                 ),
   .SAT_WIDTH                         ( 3                  )
 ) u11_sat(                                                    
   .clk                               ( logic_clk_in       ),
   .rst                               ( logic_rst_in       ),
   .din_i                             ( dds_multi1_i_rnd   ),
   .din_q                             ( dds_multi1_q_rnd   ),
          
   .dout_i                            ( ddcout1i           ),
   .dout_q                            ( ddcout1q           )
  );   


rnd #
  (     
    .IN_WIDTH                          ( 33                 ),
    .RND_WIDTH                         ( 14                 )
  ) u12_rnd (                                                   
    .clk                               ( logic_clk_in       ),
    .rst                               ( logic_rst_in       ),
    .din_i                             ( dds_multi2_i       ),
    .din_q                             ( dds_multi2_q       ),
                                       
    .dout_i                            ( dds_multi2_i_rnd    ),
    .dout_q                            ( dds_multi2_q_rnd    )
   );
   
   
sat #
 (     
   .IN_WIDTH                          ( 19                 ),
   .SAT_WIDTH                         ( 3                  )
 ) u12_sat(                                                    
   .clk                               ( logic_clk_in       ),
   .rst                               ( logic_rst_in       ),
   .din_i                             ( dds_multi2_i_rnd   ),
   .din_q                             ( dds_multi2_q_rnd   ),
          
   .dout_i                            ( ddcout2i           ),
   .dout_q                            ( ddcout2q           )
  ); 


rnd #
  (     
    .IN_WIDTH                          ( 33                 ),
    .RND_WIDTH                         ( 14                 )
  ) u13_rnd (                                                   
    .clk                               ( logic_clk_in       ),
    .rst                               ( logic_rst_in       ),
    .din_i                             ( dds_multi3_i       ),
    .din_q                             ( dds_multi3_q       ),
                                       
    .dout_i                            ( dds_multi3_i_rnd    ),
    .dout_q                            ( dds_multi3_q_rnd    )
   );
   
   
sat #
 (     
   .IN_WIDTH                          ( 19                 ),
   .SAT_WIDTH                         ( 3                  )
 ) u13_sat(                                                    
   .clk                               ( logic_clk_in       ),
   .rst                               ( logic_rst_in       ),
   .din_i                             ( dds_multi3_i_rnd   ),
   .din_q                             ( dds_multi3_q_rnd   ),
          
   .dout_i                            ( ddcout3i           ),
   .dout_q                            ( ddcout3q           )
  ); 



	

////	 (2-5)Amplitude limiting////
////	dds0		
//	 always@(posedge logic_clk_in) 
//	 begin                         
//	    if(logic_rst_in)
//	       ddcout0i[15:0]	       <= 16'h0000;
//	  //  else if((dds_multi0_i[32]==1'b0)&&(dds_multi0_i[31:30]!=2'b00))
//	    else if(!dds_multi0_i[31] && dds_multi0_i[30])
//	       ddcout0i[15:0]	       <= 16'h7ffe;
//	 //   else if((dds_multi0_i[32]==1'b1)&&(dds_multi0_i[31:30]!=2'b11))
//	    else if(dds_multi0_i[31] && !dds_multi0_i[30])
//	       ddcout0i[15:0]	       <= 16'h8001;
//	    else 
//	       ddcout0i[15:0]	       <= dds_multi0_i[30:15];
//	 end
//	
//	 always@(posedge logic_clk_in) 
//	 begin
//	    if(logic_rst_in)
//	       ddcout0q[15:0]	       <= 16'h0000;
//	 //   else if((dds_multi0_q[32]==1'b0)&&(dds_multi0_q[31:30]!=2'b00))
//	   else if(!dds_multi0_q[31] && dds_multi0_q[30])
//	       ddcout0q[15:0]	       <= 16'h7ffe;
//	 //   else if((dds_multi0_q[32]==1'b1)&&(dds_multi0_q[31:30]!=2'b11))
//	   else if(dds_multi0_q[31] && !dds_multi0_q[30])
//	       ddcout0q[15:0]	       <= 16'h8001;
//	    else 
//	       ddcout0q[15:0]	       <= dds_multi0_q[30:15];
//	 end	
//	
////	dds1
//	 always@(posedge logic_clk_in) 
//	 begin
//	    if(logic_rst_in)
//	       ddcout1i[15:0]	       <= 16'h0000;
//	 //   else if((dds_multi1_i[32]==1'b0)&&(dds_multi1_i[31:30]!=2'b00))
//	    else if(!dds_multi1_i[31] && dds_multi1_i[30])
//	       ddcout1i[15:0]	       <= 16'h7ffe;
//	 //   else if((dds_multi1_i[32]==1'b1)&&(dds_multi1_i[31:30]!=2'b11))
//	    else if(dds_multi1_i[31] && !dds_multi1_i[30])
//	       ddcout1i[15:0]	       <= 16'h8001;
//	    else 
//	       ddcout1i[15:0]	       <= dds_multi1_i[30:15];
//	 end
//	
//	 always@(posedge logic_clk_in) 
//	 begin
//	    if(logic_rst_in)
//	       ddcout1q[15:0]	       <= 16'h0000;
//	 //   else if((dds_multi1_q[32]==1'b0)&&(dds_multi1_q[31:30]!=2'b00))
//	    else if(!dds_multi1_q[31] && dds_multi1_q[30])
//	       ddcout1q[15:0]	       <= 16'h7ffe;
//	 //   else if((dds_multi1_q[32]==1'b1)&&(dds_multi1_q[31:30]!=2'b11))
//	   else if(dds_multi1_q[31] && !dds_multi1_q[30]) 
//	       ddcout1q[15:0]	       <= 16'h8001;
//	    else 
//	       ddcout1q[15:0]	       <= dds_multi1_q[30:15];
//	 end	
//	
////	dds2
//	 always@(posedge logic_clk_in) 
//	 begin
//	    if(logic_rst_in)
//	       ddcout2i[15:0]	       <= 16'h0000;
//	 //   else if((dds_multi2_i[32]==1'b0)&&(dds_multi2_i[31:30]!=2'b00))
//	    else if(!dds_multi2_i[31] && dds_multi2_i[30])
//	       ddcout2i[15:0]	       <= 16'h7ffe;
//	 //   else if((dds_multi2_i[32]==1'b1)&&(dds_multi2_i[31:30]!=2'b11))
//	    else if(dds_multi2_i[31] && !dds_multi2_i[30])
//	       ddcout2i[15:0]	       <= 16'h8001;
//	    else 
//	       ddcout2i[15:0]	       <= dds_multi2_i[30:15];
//	 end
//	
//	 always@(posedge logic_clk_in) 
//	 begin
//	    if(logic_rst_in)
//	       ddcout2q[15:0]	       <= 16'h0000;
//	 //   else if((dds_multi2_q[32]==1'b0)&&(dds_multi2_q[31:30]!=2'b00))
//	    else if(!dds_multi2_q[31] && dds_multi2_q[30])
//	       ddcout2q[15:0]	       <= 16'h7ffe;
//	  //  else if((dds_multi2_q[32]==1'b1)&&(dds_multi2_q[31:30]!=2'b11))
//	   else if(dds_multi2_q[31] && !dds_multi2_q[30])
//	       ddcout2q[15:0]	       <= 16'h8001;
//	    else 
//	       ddcout2q[15:0]	       <= dds_multi2_q[30:15];
//	 end	
//	
//	//dds3
//	 always@(posedge logic_clk_in) 
//	 begin
//	    if(logic_rst_in)
//	       ddcout3i[15:0]	       <= 16'h0000;
//	 //   else if((dds_multi3_i[32]==1'b0)&&(dds_multi3_i[31:30]!=2'b00))
//	    else if(!dds_multi3_i[31] && dds_multi3_i[30])
//	       ddcout3i[15:0]	       <= 16'h7ffe;
//	 //   else if((dds_multi3_i[32]==1'b1)&&(dds_multi3_i[31:30]!=2'b11))
//	    else if(dds_multi3_i[31] && !dds_multi3_i[30])
//	       ddcout3i[15:0]	       <= 16'h8001;
//	    else 
//	       ddcout3i[15:0]	       <= dds_multi3_i[30:15];
//	 end
//	
//	 always@(posedge logic_clk_in) 
//	 begin
//	    if(logic_rst_in)
//	       ddcout3q[15:0]	       <= 16'h0000;
//	 //   else if((dds_multi3_q[32]==1'b0)&&(dds_multi3_q[31:30]!=2'b00))
//	    else if(!dds_multi3_q[31] && dds_multi3_q[30])
//	       ddcout3q[15:0]	       <= 16'h7ffe;
//	 //   else if((dds_multi3_q[32]==1'b1)&&(dds_multi3_q[31:30]!=2'b11))
//	    else if(dds_multi3_q[31] && !dds_multi3_q[30])
//	       ddcout3q[15:0]	       <= 16'h8001;
//	    else 
//	       ddcout3q[15:0]	       <= dds_multi3_q[30:15];
//	 end	
	
	//////////////////////////////////////////////////////////////////////////////
	// (3) dds output logic//// 
	 always@(posedge logic_clk_in)
	 begin
	    if (logic_rst_in) begin
	         data_baseband0[31:0]   <= 32'd0;
	    end
	    else if(dds_fwr_en[0] && (dds_fcw_w0[27:0] == 28'd0))begin
	         data_baseband0[31:0]   <= {dds_50M_out0_q[15:0], dds_50M_out0_i[15:0]};	
	    end  
	    else begin
		     data_baseband0[31:0]   <= {ddcout0q[15:0], ddcout0i[15:0]};
	    end
	 end
	 	 
//--------------2015/11/20 9:49:25	 
	 /*
	    else if(dds_fwr_en[0])begin 
	          if (dds_fcw_w0[27:0] == 28'd0)
	             data_baseband0[31:0]   <= {dds_50M_out0_q[15:0], dds_50M_out0_i[15:0]};	
	          else 	          
		           data_baseband0[31:0]   <= {ddcout0q[15:0], ddcout0i[15:0]};		    
	    end
	    else
	      data_baseband0 <= data_baseband0;	    
	 end
	*/
	
	
	
	
	
	
	
	
	
	
	 always@(posedge logic_clk_in)
	 begin
	    if (logic_rst_in) begin
	         data_baseband1[31:0]   <= 32'd0;
	    end
	    else if(dds_fwr_en[1] && (dds_fcw_w1[27:0] == 28'd0))begin
	         data_baseband1[31:0]   <= {dds_50M_out1_q[15:0], dds_50M_out1_i[15:0]};	
	    end  
	    else begin
		     data_baseband1[31:0]   <= {ddcout1q[15:0], ddcout1i[15:0]};
	    end
	 end
	
	 always@(posedge logic_clk_in)
	 begin
	    if (logic_rst_in) begin
	         data_baseband2[31:0]   <= 32'd0;
	    end
	    else if(dds_fwr_en[2] && (dds_fcw_w2[27:0] == 28'd0))begin
	         data_baseband2[31:0]   <= {dds_50M_out2_q[15:0], dds_50M_out2_i[15:0]};	
	    end  
	    else begin
		     data_baseband2[31:0]   <= {ddcout2q[15:0], ddcout2i[15:0]};
	    end
	 end
	
	 always@(posedge logic_clk_in)
	 begin
	    if (logic_rst_in) begin
	         data_baseband3[31:0]   <= 32'd0;
	    end
	    else if(dds_fwr_en[3] && (dds_fcw_w3[27:0] == 28'd0))begin
	         data_baseband3[31:0]   <= {dds_50M_out3_q[15:0], dds_50M_out3_i[15:0]};	
	    end  
	    else begin
		     data_baseband3[31:0]   <= {ddcout3q[15:0], ddcout3i[15:0]};
	    end
	 end



//////////////////////////////////////////////////////////////////////////////////
//// (4) debug ////
assign  debug_signal[15:0]     = data_in0[15:0];        
assign  debug_signal[31:16]    = dds_50M_out0_i[15:0];        
assign  debug_signal[47:32]    = dds_50M_out0_q[15:0]; 
assign  debug_signal[63:48]    = ddcout0i[15:0];       
assign  debug_signal[79:64]    = ddcout0q[15:0];    
assign  debug_signal[107:80]   = dds_data_in0[27:0];

   
assign  debug_signal[199:108]   = 120'd0;



 
 
      
     
     
                 
//---------------DDS2 OUT             
assign  debug_signal1[15:0]     = ddcout0i[15:0];    
assign  debug_signal1[31:16]    = ddcout0q[15:0];     
assign  debug_signal1[48:32]    = dds_50M_out0_i[15:0];    
assign  debug_signal1[63:49]    = dds_50M_out0_q[15:0];  
assign  debug_signal1[79:64]    = ddcout1i[15:0];    
assign  debug_signal1[95:80]    = ddcout1q[15:0]; 
assign  debug_signal1[111:96]   = ddcout2i[15:0];    
assign  debug_signal1[127:112]  = ddcout2q[15:0]; 
assign  debug_signal1[143:128]  = ddcout3i[15:0];    
assign  debug_signal1[159:144]  = ddcout3q[15:0];  
assign  debug_signal1[187:160]  = dds_data_in0[27:0];
assign  debug_signal1[191:188]  = dds_fwr_en[3:0];

   
assign  debug_signal1[199:192]  = 11'd0;       
                      
                      
                      
                      
                      
                      
                      
             
             
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
endmodule
