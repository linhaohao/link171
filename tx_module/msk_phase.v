//////////////////////////////////////////////////////////////////////////////////
// Company:         StarPoint
// Engineer:        guoyan
// 
// Create Date:     10:19:00 06/11/2015  
// Module Name:     msk_iqsin
// Project Name:    
// Target Devices:  FPGA - XC7K325T - FFG900; 
// Tool versions:   ISE14.6;  
// Description:     The module achieves phase weighting
// 
// Revision:        v1.0 - File Created
// Additional Comments: 
// 1、fout = 1/(4Tb).
// 2、0->-1,1->1.Ik*cosine((pi/2Tb)*t) = cosine(when Ik=1);-cosine(when Ik=0).
// 3、phase_i/q_in have two same code which delay 0.4us (1/2.5M) = 1/2 cosine/sine period(4/fb=0.8us)
// 4、phase_i_in/phase_q_in align at cosine/sine, so that phase jump at pi/0.(跳变点一定在sine/cosine的零点，否则出现相位不连续)
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

module msk_phase(
//// clock/reset ////
input               clk_msk_in,
//input               logic_clk_in,
input               logic_rst_in,

//// data signal ////
input               phase_pulse_in,
input               phase_vaild_in,
input               phase_i_in,
input               phase_q_in,

output              phase_vaild_ahead,
output              phase_vaild_out,
output[15:0]        phase_cos_out,
output[15:0]        phase_sin_out,

//// debug ////
output[63:0]       debug_signal
);

//////////////////////////////////////////////////////////////////////////////////
//// signals declaration //// 
wire[27:0]             data_freq;
//wire[25:0]               data_freq;
wire[15:0]               sine;
wire[15:0]               cosine;
// wire signed[15:0]               sine;
// wire signed[15:0]               cosine;

// wire signed[15:0]              phase_cos_out1;
// wire signed[15:0]              phase_sin_out1;          
               
reg[15:0]                phase_pulse_in_dly = 16'd0;
                                               
reg[15:0]                phase_i_in_dly     = 16'd0;
reg[15:0]                phase_q_in_dly     = 16'd0;

wire[15:0]               phase_cos_cov;
wire[15:0]               phase_sin_cov;
wire                     phase_vaild_cov;

reg[15:0]                phase_cos_reg      = 16'd0;
reg[15:0]                phase_sin_reg      = 16'd0;
reg                      phase_vaild_reg    = 1'b0;


//////////////////////////////////////////////////////////////////////////////////
//// (0) signals assigment ////
//assign data_freq        = 28'd13421773;  //1/4fb= 1/4*5 = 1.25M  1.25M*2^28/25M~=13421773->1.250000018
assign data_freq        = 26'd1677722;  //1/4fb= 1/4*5 = 1.25M  1.25M*2^26/50M~=1677722->1.25000029

//////////////////////////////////////////////////////////////////////////////////
//// (1)dds cosine((pi/2Tb)*t) ////	
always@(posedge clk_msk_in)
begin
   if (logic_rst_in)   begin
	  phase_pulse_in_dly[15:0]     <= 16'd0;
	end
   else begin
      phase_pulse_in_dly[15:0]     <= {phase_pulse_in_dly[14:0],phase_pulse_in};
   end
end

// dds_phase_25M dds_phase_25M(
   // .clk(clk_msk_in),
   ////.sclr(1'b0),
   // .sclr(~phase_pulse_in_dly[2]),
   ////.ce(phase_pulse_in_dly[2]), //rf switcher control 6.4us&6.6us,[2]crosee domain
   // .ce(1'b1), //不能用ce来使能，会出现第一次延迟时间和other延迟时间不一致
   // .data(data_freq[27:0]), 
   // .we(1'b1), //不能用we来使能，会出现第一次延迟时间和other延迟时间不一致
   // .cosine(cosine[15:0]), //2pi occupy 50/1.25= 40clk(50M)
   // .sine(sine[15:0])
   // );


dds_phase dds_phase(
   .clk(clk_msk_in),
   //.sclr(1'b0),
   .sclr(~phase_pulse_in_dly[2]),
   //.ce(phase_pulse_in_dly[2]), //rf switcher control 6.4us&6.6us,[2]crosee domain
   .ce(1'b1), //不能用ce来使能，会出现第一次延迟时间和other延迟时间不一致
   .data(data_freq[25:0]), 
   .we(1'b1), //不能用we来使能，会出现第一次延迟时间和other延迟时间不一致
   .cosine(cosine[15:0]), //2pi occupy 50/1.25= 40clk(50M)
   .sine(sine[15:0])
   );
  
////////////////////////////////////////////////////////////////////////////////
// (2)phase_in align at dds out logic ////
always@(posedge clk_msk_in)
begin
   if (logic_rst_in)   begin
	  phase_i_in_dly[15:0]         <= 16'd0;
	end                            
   else begin                      
      phase_i_in_dly[15:0]         <= {phase_i_in_dly[14:0],phase_i_in};
   end                             
end                                
                                   
always@(posedge clk_msk_in)        
begin                              
   if (logic_rst_in)   begin       
	  phase_q_in_dly[15:0]         <= 16'd0;
	end                            
   else begin                      
      phase_q_in_dly[15:0]         <= {phase_q_in_dly[14:0],phase_q_in};
   end
end

////////////////////////////////////////////////////////////////////////////////
// (3)phase adjust ////
//0->“1”，1->“-1” BPSK map
//dds .ce(phase_pulse_in_dly[2]),6.6us no wave
 assign phase_cos_cov[15:0] = phase_i_in_dly[10] ? cosine[15:0] : (cosine[15] ? {1'b0,~cosine[14:0] + 1'b1}:{1'b1,~cosine[14:0] + 1'b1});
 assign phase_sin_cov[15:0] = phase_q_in_dly[10] ? sine[15:0]   : (sine[15] ? {1'b0,~sine[14:0] + 1'b1}:{1'b1,~sine[14:0] + 1'b1});
 // assign phase_cos_out1[15:0] = phase_i_in_dly[10] ? cosine[15:0] : -cosine[15:0];
 // assign phase_sin_out1[15:0] = phase_q_in_dly[10] ? sine[15:0]   : -sine[15:0];
 assign phase_vaild_cov     = phase_pulse_in_dly[10]; //6.4us && 6.6us
 assign phase_vaild_ahead   = phase_pulse_in_dly[5]; //ahead 5/25M =200ns 1bit //5/50M=100ns
 
 ////////////////////////////////////////////////////////////////////////////////
// (4)6.6us fill zero ////
always@(posedge clk_msk_in)
begin
   if (logic_rst_in)   begin
	  phase_cos_reg[15:0]         <= 16'd0;
	end                            
   else if(phase_vaild_cov)begin                      
      phase_cos_reg[15:0]         <= phase_cos_cov[15:0];
   end 
   else begin
      phase_cos_reg[15:0]         <= 16'd0;
   end       
end                                
                                   
 always@(posedge clk_msk_in)
begin
   if (logic_rst_in)   begin
	  phase_sin_reg[15:0]         <= 16'd0;
	end                            
   else if(phase_vaild_cov)begin                      
      phase_sin_reg[15:0]         <= phase_sin_cov[15:0];
   end 
   else begin
      phase_sin_reg[15:0]         <= 16'd0;
   end       
end 

 always@(posedge clk_msk_in)
begin
   if (logic_rst_in)   begin
	  phase_vaild_reg             <= 1'b0;
	end                                
   else begin                     
      phase_vaild_reg             <= phase_vaild_cov;
   end       
end

 ////////////////////////////////////////////////////////////////////////////////
// (4)output ////
 assign phase_cos_out[15:0] = phase_cos_reg[15:0];
 assign phase_sin_out[15:0] = phase_sin_reg[15:0];
 assign phase_vaild_out     = phase_vaild_reg;

 
//////////////////////////////////////////////////////////////////////////////////
//// (5)debug logic ////
assign debug_signal[0]      = clk_msk_in;
assign debug_signal[1]      = phase_pulse_in;
assign debug_signal[2]      = phase_pulse_in_dly[10];
assign debug_signal[3]      = phase_i_in;
assign debug_signal[4]      = phase_i_in_dly[10];
assign debug_signal[20:5]   = cosine[15:0];
assign debug_signal[21]     = phase_q_in;
assign debug_signal[22]     = phase_q_in_dly[10];
assign debug_signal[38:23]  = phase_cos_out[15:0];
assign debug_signal[54:39]  = phase_sin_out[15:0];
assign debug_signal[55]     = phase_vaild_out;
assign debug_signal[56]     = phase_vaild_ahead;
                            
assign debug_signal[63:57]  = 7'd0;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
endmodule
