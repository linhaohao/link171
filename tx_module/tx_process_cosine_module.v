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

module tx_process_cosine_module(
//// clock&reset interface ////
input               clk_msk_in,                            // 50MHz
input               logic_rst_in,                          //  reset

output              double_out_vaild,                     // 6.4&6.6 control
output[15:0]        double_out_i,                        // data to DAC
output[15:0]        double_out_q,                       // ahead of tx_data_en 6.4&6.6 control

input               mif_dac_stat_en,
input               mif_dac_dds_sel,

//// debug ////
output[127:0]       debug_signal 
	 
   );
   
   


//////////////////////////////////////////////////////////////////////////////////
//// signals declaration //// 
wire[15:0]  cosine0;
wire[15:0]  sine0;
wire[15:0]  cosine1;
wire[15:0]  sine1;

reg [16:0]  cosine0_reg       = 17'd0;
reg [16:0]  sine0_reg         = 17'd0;
reg [16:0]  cosine1_reg       = 17'd0;
reg [16:0]  sine1_reg         = 17'd0;
reg [17:0]  double_out_i_tmp  = 18'd0;
reg [17:0]  double_out_q_tmp  = 18'd0;
reg [15:0]  double_out_i_reg  = 16'd0;
reg [15:0]  double_out_q_reg  = 16'd0;

reg         dds_en            = 1'b0;
reg [15:0]  dds_en_dly        = 16'd0;
reg [2:0]   mif_dac_stat_en_dly = 3'd0;


wire[24:0]  data_freq0;
wire[24:0]  data_freq1;

assign data_freq0[24:0]        = 25'd1342177;  //1M*2^25/25M
assign data_freq1[24:0]        = 25'd2684354;  //2M*2^25/25M

//////////////////////////////////////////////////////////////////////////////////
//// dds //// 
dds_da1_phase u0_dds_phase(
   .clk(clk_msk_in),
   .sclr(~dds_en),
   .ce(1'b1), 
   .data(data_freq0[24:0]), 
   .we(1'b1), 
   .cosine(cosine0[15:0]), 
   .sine(sine0[15:0])
   );
   
dds_da1_phase u1_dds_phase(
   .clk(clk_msk_in),
   .sclr(~dds_en),
   .ce(1'b1), 
   .data(data_freq1[24:0]), 
   .we(1'b1),
   .cosine(cosine1[15:0]), 
   .sine(sine1[15:0])
   );


////////////amplitude   
always@(posedge clk_msk_in)
begin
   if (logic_rst_in)   begin
	  cosine0_reg[16:0]         <= 17'd0;
	end                            
   else begin                      
      cosine0_reg[16:0]         <= {cosine0[15],cosine0[15:0]};
   end                             
end                                
                                   
always@(posedge clk_msk_in)        
begin                              
   if (logic_rst_in)   begin       
	  sine0_reg[16:0]         <= 17'd0;
	end                              
   else begin                        
      sine0_reg[16:0]         <= {sine0[15],sine0[15:0]};
   end
end
   
   
always@(posedge clk_msk_in)
begin
   if (logic_rst_in)   begin
	  cosine1_reg[16:0]         <= 17'd0;
	end                            
   else if(mif_dac_dds_sel)begin                      
      cosine1_reg[16:0]         <= cosine1[15:0]*2'd2; //cosine1[15:0]*2'd0;
   end
   else begin
      cosine1_reg[16:0]         <= 17'd0;
   end                            
end                                
                                   
always@(posedge clk_msk_in)        
begin                              
   if (logic_rst_in)   begin       
	  sine1_reg[16:0]         <= 17'd0;
	end                              
   else if(mif_dac_dds_sel)begin                        
      sine1_reg[16:0]         <= sine1[15:0]*2'd2;//sine1[15:0]*2'd0;
   end
   else begin                        
      sine1_reg[16:0]         <= 17'd0;
   end
end

////////////merge  
always@(posedge clk_msk_in)
begin
   if (logic_rst_in)   begin
	  double_out_i_tmp[17:0]         <= 18'd0;
	end                            
   else begin                      
      double_out_i_tmp[17:0]         <= {cosine0_reg[16],cosine0_reg[16:0]} + {cosine1_reg[16],cosine1_reg[16:0]};
   end                             
end                                
                                   
always@(posedge clk_msk_in)        
begin                              
   if (logic_rst_in)   begin       
	  double_out_q_tmp[17:0]         <= 17'd0;
	end                              
   else begin                        
      double_out_q_tmp[17:0]         <= {sine0_reg[16],sine0_reg[16:0]} + {sine1_reg[16],sine1_reg[16:0]};
   end
end


///////////data_out rounding
// always@(posedge clk_msk_in)
// begin
   // if (logic_rst_in)   begin
	  // double_out_i_reg[15:0]         <= 16'd0;
   // end                            
   // else if((double_out_i_tmp[17] == 1'b0) && ( double_out_i_tmp[16:15] != 2'b00))begin                      
      // double_out_i_reg[15:0]         <= 16'h7fff;
   // end   
   // else if ((double_out_i_tmp[17] == 1'b1 ) && ( double_out_i_tmp[16:15] != 2'b11))begin
      // double_out_i_reg[15:0]         <= 16'h8000;
   // end
   // else begin 
      // double_out_i_reg[15:0]         <= double_out_i_tmp[15:0];
   // end   
// end                                
                                   
// always@(posedge clk_msk_in)
// begin
   // if (logic_rst_in)   begin
	  // double_out_q_reg[15:0]         <= 16'd0;
   // end                            
   // else if((double_out_q_tmp[17] == 1'b0) && ( double_out_q_tmp[16:15] != 2'b00))begin                      
      // double_out_q_reg[15:0]         <= 16'h7fff;
   // end   
   // else if ((double_out_q_tmp[17] == 1'b1 ) && ( double_out_q_tmp[16:15] != 2'b11))begin
      // double_out_q_reg[15:0]         <= 16'h8000;
   // end
   // else begin 
      // double_out_q_reg[15:0]         <= double_out_q_tmp[15:0];
   // end   
// end  

always@(posedge clk_msk_in)
begin
   if (logic_rst_in)   begin
	  double_out_i_reg[15:0]         <= 16'd0;
   end                            
   else begin 
      double_out_i_reg[15:0]         <= double_out_i_tmp[17:0]>>2'd2;
   end   
end                                
                                   
always@(posedge clk_msk_in)
begin
   if (logic_rst_in)   begin
	  double_out_q_reg[15:0]         <= 16'd0;
   end                            
   else begin 
      double_out_q_reg[15:0]         <= double_out_q_tmp[17:0]>>2'd2;
   end   
end  


assign double_out_i[15:0] = double_out_i_reg[15:0];
assign double_out_q[15:0] = double_out_q_reg[15:0];


///////////data_out vaild
always@(posedge clk_msk_in)
begin
   if (logic_rst_in)   begin
	  mif_dac_stat_en_dly[2:0]          <= 3'd0;
	end                            
   else begin                      
      mif_dac_stat_en_dly[2:0]         <= {mif_dac_stat_en_dly[1:0],mif_dac_stat_en};
   end                             
end 

always@(posedge clk_msk_in)
begin
   if (logic_rst_in)   begin
	  dds_en         <= 1'b0;
	end                            
   else if(mif_dac_stat_en_dly[2])begin                      
      dds_en         <= 1'b1;
   end                             
end 

always@(posedge clk_msk_in)
begin
   if (logic_rst_in)   begin
	  dds_en_dly[15:0]          <= 16'd0;
	end                            
   else begin                      
      dds_en_dly[15:0]         <= {dds_en_dly[14:0],dds_en};
   end                             
end 


assign double_out_vaild = dds_en_dly[13];


//////////////////////////////////////////////////////////////////////////////////
//// (10) debug signals ////
assign  debug_signal[15:0]              = double_out_i[15:0];
assign  debug_signal[31:16]             = double_out_q[15:0];
assign  debug_signal[32]                = double_out_vaild;

assign  debug_signal[127:33]            = 95'd0;



//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
endmodule
