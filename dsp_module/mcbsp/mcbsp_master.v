`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:11:28 04/13/2017 
// Design Name: 
// Module Name:    mcbsp_master 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module mcbsp_master(
// clk/rst
input               mcbsp_clk_in,                             // 20MHz clock  
input               mcbsp_rst_in,    

//config parameter
input [14:0]        mcbsp_reg_number,                         // rx frame length   
input [6:0]         mcbsp_reg_length,                         // code bit length  

//input data
input               mcbsp_master_en,  
input [31:0]        mcbsp_data_in,    

// output interface
output              mcbsp_master_clkr,	 
output              mcbsp_master_fsr,	 
output              mcbsp_master_miso,	 

// state/debug 	
output              mcbsp_update_out,		 
output[63:0]        debug_signal	
    );
    
//////////////////////////////////////////////////////////////////////////////////
//// signals declaration //// 
reg                 mcbsp_data_start = 1'b0;
reg [21:0]          mcbsp_count      = 22'd0;

reg [31:0]          mcbsp_reg       = 32'd0;
reg                 mcbsp_update     = 1'b0;

reg [31:0]          mcbsp_clk_data  = 32'd0;

reg                 mcbsp_data       = 1'b1;
reg                 mcbsp_data_syn   = 1'b0;



//////////////////////////////////////////////////////////////////////////////////
//// parameters define ////





//////////////////////////////////////////////////////////////////////////////////
//// (0) signals assigment ////
    assign  mcbsp_master_clkr              = mcbsp_data_start ? mcbsp_clk_in : 1'b0;  // mcbsp_clk_in;  
    assign  mcbsp_master_fsr               = mcbsp_data_syn; 
    assign  mcbsp_master_miso              = mcbsp_data;
	                                       
	 assign  mcbsp_update_out               = mcbsp_update;
	
//////////////////////////////////////////////////////////////////////////////////
//// (1)  update mcbsp transmit data from rx ram in cross clk domain////
always@(negedge mcbsp_clk_in or posedge mcbsp_rst_in)
begin
  if (mcbsp_rst_in)  begin
     mcbsp_clk_data[31:0]                  <= 32'd0;
  end
  else if(mcbsp_count[6:0] == mcbsp_reg_length[6:0] - 2'd3)   begin
     mcbsp_clk_data[31:0]                  <= mcbsp_data_in[31:0];         
  end
end	


//////////////////////////////////////////////////////////////////////////////////
//// (2) mcbsp count logic ////
always@(negedge mcbsp_clk_in or posedge mcbsp_rst_in)
begin
  if (mcbsp_rst_in)  begin
    mcbsp_data_start                      <= 1'b0;    
  end
  else if ((mcbsp_count[6:0] == mcbsp_reg_length[6:0] - 1'b1) && (mcbsp_count[21:7] == (mcbsp_reg_number[14:0] + 1'b1))) begin ////update->rx rd_en,NO.1 update could't rd data
    mcbsp_data_start                      <= 1'b0;   
  end
  else if(mcbsp_master_en) begin
    mcbsp_data_start                      <= 1'b1;         
  end
end	

always@(negedge mcbsp_clk_in or posedge mcbsp_rst_in)
begin
  if (mcbsp_rst_in)   begin      //时隙rst,但长度1clk,20M采不到
    mcbsp_count[21:0]                     <= 22'd0;
  end
  else if (mcbsp_count[6:0] == (mcbsp_reg_length[6:0] - 1'b1))   begin // mcbsp register 8bits 
    if (mcbsp_count[21:7] == (mcbsp_reg_number[14:0] + 1'b1))   begin   //NO.3-11 shift(NO.0 data from ram NO.1 mcbsp_clk_data update,NO.2 mcbsp_clk_data->spi reg)
      mcbsp_count[21:0]                   <= 22'd0;
    end
    else   begin
      mcbsp_count[21:7] 				  <= mcbsp_count[21:7] + 1'b1;  
      mcbsp_count[6:0]  				  <= 7'd0;	
    end
  end	 
  else if(mcbsp_data_start)
	  mcbsp_count[6:0]    				  <= mcbsp_count[6:0] + 1'b1; 
end

always@(negedge mcbsp_clk_in or posedge mcbsp_rst_in)
begin
  if (mcbsp_rst_in)   begin      //时隙rst,但长度1clk,20M采不到
	  mcbsp_update                        <= 1'b0;
  end																	
  else if ((mcbsp_count[21:7] < mcbsp_reg_number[14:0]) && (mcbsp_count[6:0] == mcbsp_reg_length[6:0] - 3'd4)) begin   //发送完前提前给外部标识，是的外部能及时变化数据
	  mcbsp_update                        <= 1'b1;
  end	                                  
  else begin                              
	  mcbsp_update                        <= 1'b0;
  end
end

//////////////////////////////////////////////////////////////////////////////////
//// (3) mcbsp register shift transfer logic ////
always@(negedge mcbsp_clk_in or posedge mcbsp_rst_in)
begin
  if (mcbsp_rst_in)   begin
    mcbsp_reg[31:0]                       <= 32'd0;  	
    mcbsp_data                            <= 1'b0;
  end
  else if (mcbsp_count[6:0] == 	mcbsp_reg_length[6:0] - 2'd2)   begin
  	 mcbsp_reg[31:0]    		              <= mcbsp_data_in[31:0]; 
    mcbsp_data         		              <= mcbsp_reg[31]; 		//update data_in same with transmit mosi	
  end
  else if(mcbsp_data_start)  begin
    mcbsp_reg[31:1]    		              <= mcbsp_reg[30:0]; 	//mcbsp_reg[0] default 1(sim)
    mcbsp_data         		              <= mcbsp_reg[31]; 		//MSB first
  end
end

/////////////////////////////////////////////
//// (5) mcbsp Latch enable ////	
always@(negedge mcbsp_clk_in or posedge mcbsp_rst_in)
begin
  if (mcbsp_rst_in) begin
    mcbsp_data_syn                        <= 1'b0;
  end
  else if ((mcbsp_count[6:0] == mcbsp_reg_length[6:0] - 1'b1) && (mcbsp_count[21:7] < mcbsp_reg_number[14:0]))  begin
	 mcbsp_data_syn                        <= 1'b1;  
  end
  else begin
    mcbsp_data_syn                        <= 1'b0;  	  
  end
end

//////////////////////////////////////////////////////////////////////////////////
//// debug signal ////
  assign  debug_signal[0]                 = mcbsp_clk_in;
  assign  debug_signal[1]                 = mcbsp_master_en;
  assign  debug_signal[2]                 = mcbsp_master_clkr;//mcbsp_data_start;
  assign  debug_signal[3]                 = mcbsp_update;

  assign  debug_signal[4]                 = mcbsp_data_syn;
  assign  debug_signal[5]                 = mcbsp_data;

  assign  debug_signal[12:6]              = mcbsp_count[6:0];
  assign  debug_signal[27:13]             = mcbsp_count[21:7]; 

  assign  debug_signal[59:28]             = mcbsp_clk_data[31:0];
  assign  debug_signal[60]                = mcbsp_data_start;//mcbsp_master_clkr;
  
  assign  debug_signal[63:61]             = 9'd0;
endmodule
