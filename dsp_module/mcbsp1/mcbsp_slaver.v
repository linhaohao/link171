//////////////////////////////////////////////////////////////////////////////////
// Company:         StarPoint
// Engineer:        GUO YAN 
// 
// Create Date:     09:35:41 08/05/2011 
// Module Name:     mcbsp_slaver 
// Project Name:    Link16 dsp interface module;
// Target Devices:  FPGA - XC7K325T - FFG900; 
// Tool versions:   ISE14.6; 
// Description:     
//                  
//
// Revision:        v1.0 - File Created
// Additional Comments: 
// 1. negedge receive data 
// 2. operation launched by dsp in slaver mode, so tx_interrupt is only transmitted to dsp not to fpga mcbsp
// 3.  
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

module mcbsp_slaver(
//config parameter
//input [ 8:0]        mcbsp_reg_number,                         // rx frame length   
input [ 6:0]        mcbsp_reg_length,                         // code bit length 

// input interface
input               mcbsp_slaver_clkx,	 
input               mcbsp_slaver_fsx,	 
input               mcbsp_slaver_mosi, 

input               mcbsp_slaver_rst,
//input               mcbsp_slaver_en,  

//output data
output [31:0]       mcbsp_data_out,
output              mcbsp_vaild_out,    

	
// state/debug 		 
output[63:0]        debug_signal	
    );
    
//////////////////////////////////////////////////////////////////////////////////
//// signals declaration //// 
reg                 mcbsp_data_rdy     = 1'b0;
reg                 mcbsp_data_start   = 1'b0;
wire                mcbsp_en;
reg [15:0]          mcbsp_count        = 16'd0;
reg                 mcbsp_vaild_reg    = 1'b0;
reg [1:0]           mcbsp_vaild_reg_dly=2'd0;
                                       
                                       
reg [31:0]          mcbsp_buf          = 32'd0;
reg [31:0]          mcbsp_data_reg     = 32'd0; 

//////////////////////////////////////////////////////////////////////////////////
//// parameters define ////





//////////////////////////////////////////////////////////////////////////////////
//// (0) signals assigment ////
   assign    mcbsp_en                  =  mcbsp_slaver_fsx || mcbsp_data_start; //mcbsp_data_rdy && mcbsp_data_start;
                                       
   assign    mcbsp_data_out[31:0]      =  mcbsp_data_reg[31:0];
   assign    mcbsp_vaild_out           =  mcbsp_vaild_reg_dly[0];
	
	
//////////////////////////////////////////////////////////////////////////////////
//// (2) mcbsp count logic ////
// always@(posedge mcbsp_slaver_clkx or posedge mcbsp_slaver_rst) //tx_interrupt activate ready
// begin
  // if (mcbsp_slaver_rst)  begin
    // mcbsp_data_rdy                  <= 1'b0;    
  // end
  // else if ((mcbsp_count[6:0] == mcbsp_reg_length[6:0] - 1'b1) && (mcbsp_count[15:7] == mcbsp_reg_number[8:0] - 1'b1)) begin
    // mcbsp_data_rdy                  <= 1'b0;   
  // end
  // else if(mcbsp_slaver_en) begin
    // mcbsp_data_rdy                  <= 1'b1;         
  // end
// end	

always@(posedge mcbsp_slaver_clkx or posedge mcbsp_slaver_rst)//fsx activate real start
begin
  if (mcbsp_slaver_rst)  begin
    mcbsp_data_start                <= 1'b0;    
  end
  else if(mcbsp_slaver_fsx) begin
    mcbsp_data_start                <= 1'b1;         
  end
  else if ((mcbsp_count[6:0] == mcbsp_reg_length[6:0] - 1'b1)) begin
    mcbsp_data_start                <= 1'b0;   //防止相邻两个fsx间隔大于32个MCBSP clk
  end
end	

always@(posedge mcbsp_slaver_clkx or posedge mcbsp_slaver_rst)
begin
  if (mcbsp_slaver_rst)  begin 
     mcbsp_count[6:0]               <= 7'd0;
  end
  else if (mcbsp_count[6:0] == mcbsp_reg_length[6:0] - 1'b1)   begin // mcbsp register 32bits 
     mcbsp_count[6:0]               <= 7'd0;	
  end
  else if(mcbsp_data_start)begin
     mcbsp_count[6:0]               <= mcbsp_count[6:0] + 1'b1; 
  end
end

//////////////////////////////////////////////////////////////////////////////////
//// (3) mcbsp register shift transfer logic ////
always@(posedge mcbsp_slaver_clkx or posedge mcbsp_slaver_rst)
begin
  if (mcbsp_slaver_rst)  begin
     mcbsp_buf[31:0]                <= 32'd0;
  end
  else if (mcbsp_en)begin  //keep no.0=fsx sampling
     mcbsp_buf[0]                   <= mcbsp_slaver_mosi;  
     mcbsp_buf[31:1]	            <= mcbsp_buf[30:0]; 
  end
end	

//////////////////////////////////////////////////////////////////////////////////
//// (4) mcbsp Latch data output ////
always@(posedge mcbsp_slaver_clkx or posedge mcbsp_slaver_rst)
begin
  if (mcbsp_slaver_rst)  begin
	 mcbsp_vaild_reg	            <= 1'b0;
  end
  else if (mcbsp_count[6:0] == mcbsp_reg_length[6:0] - 2'b10)  begin
     mcbsp_vaild_reg	            <= 1'b1; 
  end
  else begin
     mcbsp_vaild_reg	            <= 1'b0; 
  end
end	

always@(posedge mcbsp_slaver_clkx or posedge mcbsp_slaver_rst)
begin
  if (mcbsp_slaver_rst)  begin
	 mcbsp_vaild_reg_dly[1:0]	    <= 2'b0;
  end                               
  else begin                        
     mcbsp_vaild_reg_dly[1:0]	    <= {mcbsp_vaild_reg_dly[0],mcbsp_vaild_reg}; 
  end
end	

always@(posedge mcbsp_slaver_clkx or posedge mcbsp_slaver_rst)
begin
  if (mcbsp_slaver_rst)  begin
     mcbsp_data_reg[31:0]           <= 32'd0;
  end
  else if (mcbsp_vaild_reg)  begin
     mcbsp_data_reg[31:0]           <= mcbsp_buf[31:0]; 
  end
end	

//////////////////////////////////////////////////////////////////////////////////
//// debug signal ////
  assign  debug_signal[0]            = mcbsp_slaver_clkx;
  assign  debug_signal[1]            = mcbsp_slaver_fsx;
  assign  debug_signal[2]            = mcbsp_slaver_mosi;
                                     
  assign  debug_signal[3]            = mcbsp_data_start;
  assign  debug_signal[4]            = mcbsp_en;
                                     
  assign  debug_signal[11:5]         = mcbsp_count[6:0];
  assign  debug_signal[43:12]        = mcbsp_buf[31:0]; //mcbsp_data_reg[31:0]
                                     
  assign  debug_signal[44]           = mcbsp_vaild_reg;
  assign  debug_signal[46:45]        = mcbsp_vaild_reg_dly[1:0];
  
  assign  debug_signal[63:47]        =17'd0;


  
  
  
 //////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
endmodule
