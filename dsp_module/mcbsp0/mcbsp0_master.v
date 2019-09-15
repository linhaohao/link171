//////////////////////////////////////////////////////////////////////////////////
// Company:         StarPoint
// Engineer:        GUO YAN 
// 
// Create Date:     15:40:41 08/04/2011 
// Module Name:     mcbsp_master 
// Project Name:    Link16 dsp interface module;
// Target Devices:  FPGA - XC7K325T - FFG900; 
// Tool versions:   ISE13.2; 
// Description:     
//                  
//
// Revision:        v1.0 - File Created
// Additional Comments: 
// 1.  negedge send data
// 2.  adjecent fsr sync is not 13us, next data transmit after ahead data transmit 
// 3.  data_in from RAM has delay
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

module mcbsp0_master(
// clk/rst
input               mcbsp_clk_in,                             // 20MHz clock  2015/9/9 10:52:56
input               mcbsp_rst_in,    

//config parameter
input [ 8:0]        mcbsp_reg_number,                         // rx frame length   
input [ 6:0]        mcbsp_reg_length,                         // code bit length  

//input data
input               mcbsp_master_en,  						  //一个clk
input [31:0]        mcbsp_data_in,    

// output interface
output              mcbsp_master_clkr,	 
output              mcbsp_master_fsr,	 
output              mcbsp_master_miso,	 

input				send_flag_dsp,

// state/debug 	
output              mcbsp_update_out,		 
output[63:0]        debug_signal	
    );
    
//////////////////////////////////////////////////////////////////////////////////
//// signals declaration //// 
reg                 mcbsp_data_start = 1'b0;
reg [15:0]          mcbsp_count      = 16'd0;
reg [31:0]          mcbsp_reg        = 32'd0;
reg                 mcbsp_update     = 1'b0;

reg [31:0]          mcbsp_clk_data   = 31'd0;

reg                 mcbsp_data       = 1'b1;
reg                 mcbsp_data_syn   = 1'b0;

reg			        mcbsp_master_en_r0 = 1'b0,mcbsp_master_en_r1 = 1'b0;		//将mcbsp_master_en延时一拍
reg					first_byte		 = 1'b0;

reg		[7:0]		mcbsp_count_delay	=	8'd0;
reg 				mcbsp_clk_start		=	1'b0;
reg					cnt_flag			=	1'b0;
reg					half_clk			=	1'b0;

reg					half_clk_flag		=	1'b0;
//////////////////////////////////////////////////////////////////////////////////
//// parameters define ////





//////////////////////////////////////////////////////////////////////////////////
//// (0) signals assigment ////				mcbsp_data_start
    assign  mcbsp_master_clkr           = mcbsp_clk_start ? mcbsp_clk_in : 1'b0;//()? 1'b0 : mcbsp_clk_in;         
    assign  mcbsp_master_fsr            = mcbsp_data_syn;	//half_clk_flag ? (mcbsp_data_syn && half_clk) : mcbsp_data_syn; 
    assign  mcbsp_master_miso           = mcbsp_data;
	
	assign  mcbsp_update_out            = mcbsp_update;
	
//////////////////////////////////////////////////////////////////////////////////
//// (1)  update mcbsp transmit data from rx ram in cross clk domain////
// always@(negedge mcbsp_clk_in or posedge mcbsp_rst_in)
// begin
  // if (mcbsp_rst_in)  begin
     // mcbsp_clk_data[31:0]   <= 8'd0;
  // end
  // else if(mcbsp_count[6:0] == 7'd1)  begin
     // mcbsp_clk_data[31:0]   <= mcbsp_data_in[31:0];         
  // end
// end	

//////////////////////////////////////////////////////////////////////////////////
//// (2) mcbsp count logic ////
always@(negedge mcbsp_clk_in or posedge mcbsp_rst_in)
begin
  if (mcbsp_rst_in)  begin
    mcbsp_data_start  			<= 1'b0;    
	half_clk_flag	 			<= 1'b0; 
  end
  else if ((mcbsp_count[6:0] == mcbsp_reg_length[6:0] - 1 ) && (mcbsp_count[15:7] == mcbsp_reg_number[8:0])) begin
    mcbsp_data_start            <= 1'b0;   
	half_clk_flag	 			<= 1'b1; 
  end
  else if(mcbsp_master_en) begin
    mcbsp_data_start            <= 1'b1;    
	half_clk_flag	 			<= 1'b0; 	
  end
  else	
	half_clk_flag	 			<= 1'b0; 
end	

///////////延时mcbsp_data_start 32个clk
always@(negedge mcbsp_clk_in or posedge mcbsp_rst_in)
begin
  if (mcbsp_rst_in)  begin
    mcbsp_clk_start  			<= 	1'b0;   
	cnt_flag		 			<=	1'b0;
	mcbsp_count_delay[7:0]		<=	8'd0;
  end
  else if(mcbsp_master_en) begin	///send_flag_dsp
    mcbsp_clk_start            	<= 	1'b1;    
	cnt_flag		 			<=	1'b0;
	mcbsp_count_delay[7:0]		<=	8'd0;
  end
  else if(mcbsp_count_delay[7:0] >= 8'd32 ) begin
    mcbsp_clk_start            	<= 	1'b0;    
	cnt_flag		 			<=	1'b0;
	mcbsp_count_delay[7:0]		<=	8'd0;
  end
  else if ((mcbsp_count[6:0] == mcbsp_reg_length[6:0] - 1 ) && (mcbsp_count[15:7] == mcbsp_reg_number[8:0])) begin
	cnt_flag		 			<=	1'b1;
	mcbsp_count_delay[7:0]		<=	8'd0;
  end
  else if(cnt_flag)
	mcbsp_count_delay[7:0]		<=	mcbsp_count_delay[7:0] + 1'b1;
  
end	



always@(negedge mcbsp_clk_in or posedge mcbsp_rst_in)
begin
  if (mcbsp_rst_in)   begin      //时隙rst,但长度1clk,10M采不到
    mcbsp_count[15:0]                     	<= 16'd0;
	first_byte							  	<= 1'b0;	//第一个32bit
  end
  else if (mcbsp_count[6:0] == mcbsp_reg_length[6:0] - 1'b1)   begin // mcbsp register 8bits 
												//- 1'b1
	if (mcbsp_count[15:7] == mcbsp_reg_number[8:0] )   begin   //NO.3-11 shift(NO.0 data from ram NO.1 mcbsp_clk_data update,NO.2 mcbsp_clk_data->spi reg)
      mcbsp_count[15:0]                     <= 16'd0;
	  first_byte							<= 1'b0;
    end
    else   begin
      mcbsp_count[15:7] 					<= mcbsp_count[15:7] + 1'b1;  
      mcbsp_count[6:0]  					<= 7'd0;	
    end
  end	 
  else if(mcbsp_master_en_r1 && (!first_byte))begin
	  first_byte		  					<= 1'b1;
	  mcbsp_count[6:0]    					<= mcbsp_count[6:0] + 1'b1; 
  end
  else if(first_byte && mcbsp_data_start)
	  mcbsp_count[6:0]    					<= mcbsp_count[6:0] + 1'b1; 
end

always@(negedge mcbsp_clk_in or posedge mcbsp_rst_in)
begin
  if (mcbsp_rst_in)   begin      //时隙rst,但长度1clk,10M采不到
	  mcbsp_update                          <= 1'b0;
  end													//发送完前提前给外部标识，是的外部能及时变化数据	+ 2'b11					
		////(mcbsp_count[15:7] != mcbsp_reg_number[8:0]) && 
  else if ((mcbsp_count[6:0] == mcbsp_reg_length[6:0] - 6 )) begin   
	  mcbsp_update                        <= 1'b1;
  end	 
  else begin
	  mcbsp_update                        <= 1'b0;
  end
end
wire [6:0] test_ln;
wire [8:0] hig_cn;
assign test_ln	=	mcbsp_count[6:0];
assign hig_cn	=	mcbsp_count[15:7];




//////////////////////////////////////////////////////////////////////////////////
//// (3) mcbsp register shift transfer logic ////
always@(negedge mcbsp_clk_in or posedge mcbsp_rst_in)
begin
  if (mcbsp_rst_in)   begin
    mcbsp_reg[31:0]    		<= 31'd0;  	
    mcbsp_data         		<= 1'b0;
  end
  //////////提前mcbsp_data_syn一个时钟更新需要发出的数据
  else if (mcbsp_master_en )   begin
	mcbsp_reg[31:0]    		<= 	mcbsp_data_in[31:0]; 
	mcbsp_clk_data[31:0]   	<= 	mcbsp_data_in[31:0];   
  end
  else if (mcbsp_count[6:0] == 	mcbsp_reg_length[6:0] - 7'd2)   begin
	mcbsp_clk_data[31:0]   	<= 	mcbsp_data_in[31:0];   
	mcbsp_data         		<= 	mcbsp_reg[31];		//更新同时，也要送出数据
	mcbsp_reg[31:0]    		<= 	mcbsp_data_in[31:0];
  end
  else if(mcbsp_data_start)  begin
    mcbsp_reg[31:1]    		<= 	mcbsp_reg[30:0]; 	//mcbsp_reg[0] keep
    mcbsp_data         		<= 	mcbsp_reg[31]; 		//MSB first
  end
end


//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//// (4) mcbsp_master_en 延时一拍
always@(negedge mcbsp_clk_in or posedge mcbsp_rst_in)
begin
  if (mcbsp_rst_in) begin
    mcbsp_master_en_r0					  <= 1'b0;
    mcbsp_master_en_r1					  <= 1'b0;
  end
  else begin
    mcbsp_master_en_r0                    <= mcbsp_master_en;  
	mcbsp_master_en_r1					  <= mcbsp_master_en_r0;	
  end
end
/////////////////////////////////////////////
//// (5) mcbsp Latch enable ////	
always@(negedge mcbsp_clk_in or posedge mcbsp_rst_in)
begin
  if (mcbsp_rst_in) begin
    mcbsp_data_syn                        <= 1'b0;
  end
  // else if (mcbsp_master_en_r0)   begin
    // mcbsp_data_syn                      <= 	1'b1;  
  // end
  ///////////////(mcbsp_count[15:7] != mcbsp_reg_number[8:0]) && 
  else if ((mcbsp_count[15:7] != mcbsp_reg_number[8:0]) && (mcbsp_count[6:0] == mcbsp_reg_length[6:0] - 1))   begin
    mcbsp_data_syn                      <= 	1'b1;  
  end
  else begin
    mcbsp_data_syn                        <= 1'b0;  	  
  end
end

//生成半个时钟标识
always@(posedge mcbsp_clk_in or posedge mcbsp_rst_in)
begin
  if (mcbsp_rst_in) begin
    half_clk                        	<= 1'b0;
  end
  else if ((mcbsp_count[6:0] == mcbsp_reg_length[6:0] - 1 ) && (mcbsp_count[15:7] == mcbsp_reg_number[8:0])) begin
    half_clk            				<= 1'b1;   
  end
  else
	half_clk                        	<= 1'b0;
end

//////////////////////////////////////////////////////////////////////////////////
//// debug signal ////


// state/debug 	


assign	debug_signal[63]	=	mcbsp_master_clkr;
assign	debug_signal[62]	=	mcbsp_master_fsr;
assign	debug_signal[61]	=	mcbsp_master_miso;
assign	debug_signal[60]	=	mcbsp_data_start;
assign	debug_signal[59]	=	mcbsp_data_syn;
assign	debug_signal[58:27]	=	mcbsp_clk_data[31:0];
assign	debug_signal[26]	=	send_flag_dsp;
assign	debug_signal[25:1]	=	25'd0;
assign	debug_signal[0]		=	send_flag_dsp;
//////////////////////////////////////////////////////////////////////////////////
endmodule
