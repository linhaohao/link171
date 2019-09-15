//////////////////////////////////////////////////////////////////////////////////
// Company:         StarPoint
// Engineer:        GUO YAN 
// 
// Create Date:     14:06:14 08/04/2015 
// Module Name:     dsp_fpga_top 
// Project Name:    Link16 dsp interface module;
// Target Devices:  FPGA - XC7K325T - FFG900; 
// Tool versions:   ISE13.2; 
// Description:     
//                  
//
// Revision:        v1.0 - File Created
// Additional Comments: 
// 1. 
//
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

module mcbsp_dsp_if_top (
//// clock interface ////                                         
input               mcbsp_clk_in,           // 20mhz   2015/9/9 10:53:16   发用上沿，收用下沿。
input               mcbsp_rst_in,           // 
                                           
//// port ////
input               mcbsp_slaver_clkx,	 
input               mcbsp_slaver_mosi, 
	
output              mcbsp_master_clkr,	 
output              mcbsp_master_fsr,	 
output              mcbsp_master_miso,	

//// DL data transmit ////
input               tx_mcbsp_interrupt,
input               mcbsp_slaver_fsx,	 

output[31:0]        dsp_tx_data, 
output              tx_vaild_out,
	
//// UL data receive ////
input               rx_mcbsp_interrupt,
input[8:0]          rx_slot_data_length,
input[31:0]         dsp_rx_dina,

output              rx_ram_addr_upd,

//// debug ////
output[127:0]       debug_signal

    );


//////////////////////////////////////////////////////////////////////////////////
//// signals declaration //// 
reg [2:0]           mcbsp_master_en_reg       = 3'd0;  
reg                 mcbsp_master_en           = 1'b0;
reg [7:0]           mcbsp_data_in             = 8'd0;

reg [2:0]           mcbsp_slaver_en_reg       = 3'd0;  
reg                 mcbsp_slaver_en           = 1'b0;

wire [63:0]			debug_signal_slaver;
wire [63:0]			debug_signal_master;

//////////////////////////////////////////////////////////////////////////////////
//// parameters define ////
//parameter           rx_code_length            = 7'd8;
parameter           code_length            = 7'd32;





//////////////////////////////////////////////////////////////////////////////////
//// (0) signals assigment ////



//////////////////////////////////////////////////////////////////////////////////
//// (1)fpga to dsp logic //// FPGA->DSP

//// Cross Clock Domain
always@(negedge mcbsp_clk_in or posedge mcbsp_rst_in)
begin
  if (mcbsp_rst_in)  begin
     mcbsp_master_en_reg[2:0]         <= 3'd0;
  end                               
  else begin                        
     mcbsp_master_en_reg[2:0]         <= {mcbsp_master_en_reg[1:0],rx_mcbsp_interrupt};
  end
end	

always@(negedge mcbsp_clk_in or posedge mcbsp_rst_in)
begin
  if (mcbsp_rst_in)  begin
     mcbsp_master_en                  <= 1'b0;
  end                 
//rx_mcbsp_interrupt一个上升沿，此处保持了一个时钟周期  
  else if(mcbsp_master_en_reg[2:1] == 2'b01)begin                      
     mcbsp_master_en                  <= 1'b1;
  end
  else begin
     mcbsp_master_en                  <= 1'b0;
  end
end	

////mcbsp master logic； msbsp接口送出数据
mcbsp0_master u_mcbsp_master
   (
    // clk/rst
    .mcbsp_clk_in(mcbsp_clk_in),                   
    .mcbsp_rst_in(mcbsp_rst_in),    
	
    //config parameter
    .mcbsp_reg_number(rx_slot_data_length[8:0]),   // rx header+data length    ---dsp读if的返回值，1个32
    .mcbsp_reg_length(code_length),       // code bit length  
	
    //input data
    .mcbsp_master_en(mcbsp_master_en),  
    .mcbsp_data_in(dsp_rx_dina[31:0]),
    
    // output interface
    .mcbsp_master_clkr(mcbsp_master_clkr),	 
    .mcbsp_master_fsr(mcbsp_master_fsr),	 
    .mcbsp_master_miso(mcbsp_master_miso),	 
	
    // state/debug 	
    .mcbsp_update_out(rx_ram_addr_upd),		 
    .debug_signal(debug_signal_master)
    );
	



//////////////////////////////////////////////////////////////////////////////////
//// (2) dsp to fpga logic //// DSP->FPGA

//// Cross Clock Domain
always@(negedge mcbsp_clk_in or posedge mcbsp_rst_in)
begin
  if (mcbsp_rst_in)  begin
     mcbsp_slaver_en_reg[2:0]         <= 3'd0;
  end                               
  else begin                        
     mcbsp_slaver_en_reg[2:0]         <= {mcbsp_slaver_en_reg[1:0],tx_mcbsp_interrupt};
  end
end	

always@(negedge mcbsp_clk_in or posedge mcbsp_rst_in)
begin
  if (mcbsp_rst_in)  begin
     mcbsp_slaver_en                  <= 1'b0;
  end                               
  else if(mcbsp_slaver_en_reg[2:1] == 2'b01)begin                        
     mcbsp_slaver_en                  <= 1'b1;
  end
  else begin
     mcbsp_slaver_en                  <= 1'b0;
  end
end	

////mcbsp slaver logic ；	msbsp接口接受数据
mcbsp0_slaver u_mcbsp_slaver
   (  
    .mcbsp_reg_length(code_length),       // code bit length     
    // input interface
    .mcbsp_slaver_clkx(mcbsp_slaver_clkx),	 
    .mcbsp_slaver_fsx(mcbsp_slaver_fsx),	 
    .mcbsp_slaver_mosi(mcbsp_slaver_mosi), 
    
	  .mcbsp_slaver_rst(mcbsp_rst_in),
    // .mcbsp_slaver_en(mcbsp_slaver_en),      
    //output data
    .mcbsp_data_out(dsp_tx_data[31:0]), 
	.mcbsp_vaild_out(tx_vaild_out),
     	
    // state/debug 		 
    .debug_signal(debug_signal_slaver)	
    );

assign		debug_signal	=	{debug_signal_master,debug_signal_slaver};


//////////////////////////////////////////////////////////////////////////////////
//// (3) RAM read address logic ////

//////////////////////////////////////////////////////////////////////////////////
endmodule
