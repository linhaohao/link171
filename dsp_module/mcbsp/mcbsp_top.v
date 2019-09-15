`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:42:34 04/13/2017 
// Design Name: 
// Module Name:    mcbsp_top 
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
module mcbsp_top(
		//// clock interface ////                                         
		input               mcbsp_clk_in,           // 20MHz logic clock
		input               mcbsp_rst_in,           // 
		                                           
		//// port ////
		input               mcbsp_slaver_clkx,	 
		input               mcbsp_slaver_fsx,	 
		input               mcbsp_slaver_mosi, 
			
		output              mcbsp_master_clkr,	 
		output              mcbsp_master_fsr,	 
		output              mcbsp_master_miso,	
		
		//// DL data transmit ////
		//input               tx_mcbsp_interrupt, //fpga receive dsp data, only mcbsp_slaver_clkx control not tx_interrupt enable
		
		output[31:0]        dsp_tx_data, 
		output              tx_vaild_out,
			
		//// UL data receive ////
		input               rx_mcbsp_interrupt,
		input[14:0]         rx_slot_data_length,
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

wire[63:0]          debug_slaver_signal;
wire[63:0]          debug_master_signal;
//////////////////////////////////////////////////////////////////////////////////
//// parameters define ////
parameter           rx_code_length            = 7'd32;
parameter           tx_code_length            = 7'd32;





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
  else if(mcbsp_master_en_reg[2:1] == 2'b01)begin   
//  else if((mcbsp_master_en_reg[2:1] == 2'b01) || (mcbsp_master_en_reg[2:1] == 2'b10))begin    
     mcbsp_master_en                  <= 1'b1;
  end
  else begin
     mcbsp_master_en                  <= 1'b0;
  end
end	

////mcbsp master logic 
mcbsp_master u_mcbsp_master
   (
    // clk/rst
    .mcbsp_clk_in(mcbsp_clk_in),                   // 10MHz clock
    .mcbsp_rst_in(mcbsp_rst_in),    
	
    //config parameter
    .mcbsp_reg_number(rx_slot_data_length[14:0]),   // rx data length + TOA/UNSYNC    
    .mcbsp_reg_length(rx_code_length[6:0]),       // code bit length  
	
    //input data
    .mcbsp_master_en(mcbsp_master_en),  
    .mcbsp_data_in(dsp_rx_dina[31:0]),
    
    // output interface
    .mcbsp_master_clkr(mcbsp_master_clkr),	 
    .mcbsp_master_fsr(mcbsp_master_fsr),	 
    .mcbsp_master_miso(mcbsp_master_miso),	 
	
    // state/debug 	
    .mcbsp_update_out(rx_ram_addr_upd),		 
    .debug_signal(debug_master_signal[63:0])
    );
	



//////////////////////////////////////////////////////////////////////////////////
//// (2) dsp to fpga logic //// DSP->FPGA

//// Cross Clock Domain
// always@(negedge mcbsp_clk_in or posedge mcbsp_rst_in)
// begin
  // if (mcbsp_rst_in)  begin
     // mcbsp_slaver_en_reg[2:0]         <= 3'd0;
  // end                               
  // else begin                        
     // mcbsp_slaver_en_reg[2:0]         <= {mcbsp_slaver_en_reg[1:0],tx_mcbsp_interrupt};
  // end
// end	

// always@(negedge mcbsp_clk_in or posedge mcbsp_rst_in)
// begin
  // if (mcbsp_rst_in)  begin
     // mcbsp_slaver_en                  <= 1'b0;
  // end                               
  // else if((mcbsp_slaver_en_reg[2:1] == 2'b01) || (mcbsp_slaver_en_reg[2:1] == 2'b10))begin //rising and falling all work
     // mcbsp_slaver_en                  <= 1'b1;
  // end
  // else begin
     // mcbsp_slaver_en                  <= 1'b0;
  // end
// end	

////mcbsp slaver logic 
mcbsp_slaver u_mcbsp_slaver
   (
    //config parameter
    //.mcbsp_reg_number(tx_slot_data_length[8:0]),   // rx frame length   
    .mcbsp_reg_length(tx_code_length[6:0]),       // code bit length 
    
    // input interface
    .mcbsp_slaver_clkx(mcbsp_slaver_clkx),	 
    .mcbsp_slaver_fsx(mcbsp_slaver_fsx),	 
    .mcbsp_slaver_mosi(mcbsp_slaver_mosi), 
    
	 .mcbsp_slaver_rst(mcbsp_rst_in),
    //.mcbsp_slaver_en(mcbsp_slaver_en),  
    
    //output data
    .mcbsp_data_out(dsp_tx_data[31:0]), 
	 .mcbsp_vaild_out(tx_vaild_out),
     	
    // state/debug 		 
    .debug_signal(debug_slaver_signal[63:0])	
    );



//////////////////////////////////////////////////////////////////////////////////
//// (3) debug ////
    assign  debug_signal[63:0]    = debug_slaver_signal[63:0];
	assign  debug_signal[127:64]  = {rx_mcbsp_interrupt,mcbsp_master_en_reg[2:0],debug_master_signal[59:0]};

//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
endmodule
