////////////////////////////////////////////////////////////////////////////////
// Company:    StarPoint
// Engineer:   guanzheye 
//
// Create Date: <date>
// Design Name: da_send_out
// Module Name: da_send_out
// Target Device: FPGA XC7K325T-2FFG900 
// Tool versions: ISE14.6 
// Description:
//            DAC DATA OUT 
// Revision:
//     v1.0 - File Created
// Additional Comments:
//    2015/11/4 11:42:43  ADD MIF_MODE
////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

module da_send_out(

input                    clk_50m,
input                    sys_rst,
input                    clk_25m,
input                    logic_rst,
//------------------------------------
input [15:0]             mif_dac_data_mode,
output   reg             dac_tx_en,
input                    dl_data_dac_window,



input [31:0]             msk_iq_data,
input                    msk_data_valid,

input                    dac_data_clk_buf,     
input                    dac_pll_lock,     
//-------------DAC OUT---------------------
output [17:0]            dac_data,          
//-------------DEBUG     -----------------
output [199:0]           debug_signal
);
//////////////////////////////////////////////////////////////////////////////////
//// signal declaration ////
//reg [1:0] ram_wr_pip;


reg [8:0] ram_waddr;
reg [9:0] ram_raddr;
reg       ram_wr_en;
reg       ram_red_en;
reg  [31:0] ram_wr_data;
wire [15:0] ram_red_data;
reg [4:0] ram_wr_en_dl;
reg [4:0] ram_rd_en_dl;
reg [17:0]fpga_dac_data_reg;
reg [17:0]fpga_dac_data_reg_dl;
 


//////////////////////////////////////////////////////////////////////////////////
//// signal assignment ////
assign   dac_data   =   fpga_dac_data_reg_dl;


//////////////////////////////////////////////////////////////////////////////////
// (0) clock&data buffer ////  ////
// IBUFG   U_dac_clk_buf
    // (
	 // .O(dac_data_clk_buf),
	 // .I(dac_pdclk) 
	 // );	 
	 
////////////////////////////////////////////////////////////////////////////////
// (1) RAM W                          ////	   
  always @(posedge clk_50m or posedge sys_rst) begin
  	   if(sys_rst)
  	   	  ram_wr_en <= 1'd0;  
	   else if(mif_dac_data_mode[15])begin
  	          if(msk_data_valid)
			     ram_wr_en <= ~ram_wr_en;
		      else 
			     ram_wr_en <= 1'd0;
	   end			  			  
	   else if(dl_data_dac_window)
  	      ram_wr_en <= ~ram_wr_en;
  	   else
  	      ram_wr_en <= 1'd0; 
  end	 
////////////////////////////////////////////////////////////////////////////////
// (2) ram data                         ////	   
  always @(posedge clk_50m or posedge sys_rst) begin
  	   if(sys_rst)
  	   	  ram_wr_data <= 1'd0;  
  	   else
  	      ram_wr_data <= msk_iq_data;
  end	

////////////////////////////////////////////////////////////////////////////////
// (3) w addr                         ////	   
  always @(posedge clk_50m or posedge sys_rst) begin
  	   if(sys_rst)
  	      ram_waddr <= 9'd0;
	   else if(mif_dac_data_mode[15])begin
	           if(msk_data_valid)begin
			     if(ram_wr_en)
  	               ram_waddr <= ram_waddr + 1'd1;
  	             else
  	               ram_waddr <= ram_waddr;
  	             end
			   else
			     ram_waddr <= 9'd0;
		end   
  	//   else if(msk_data_valid)begin
	    else if(dl_data_dac_window)begin
              if(ram_wr_en)
  	             ram_waddr <= ram_waddr + 1'd1;
  	          else
  	             ram_waddr <= ram_waddr;
  	   end
  	   else
  	      ram_waddr <= 9'd0;
  end
 ////////////////////////////////////////////////////////////////////////////////
// (4) w en     dl                    ////	   
  always @(posedge clk_50m or posedge sys_rst) begin
  	   if(sys_rst)  
  	     ram_wr_en_dl <= 5'd0;
  	   else if(mif_dac_data_mode[15])	   
         ram_wr_en_dl <= {msk_data_valid,ram_wr_en_dl[4:1]};
	   else
		 ram_wr_en_dl <= {dl_data_dac_window,ram_wr_en_dl[4:1]};
  end     
//////////////////////////////////////////////////////////////////////////////////
//// (5) ram隔离，使用dac时钟输出。  		
ram_i32_o16X512      u_ram_i32_o16X512(
  .clka           (clk_50m         ),
  .ena            (1'd1            ),
  .wea            (ram_wr_en       ),
  .addra          (ram_waddr       ),
  .dina           (ram_wr_data     ),

  .clkb           (dac_data_clk_buf),
  .enb            (ram_red_en      ),
  .addrb          (ram_raddr       ),
  .doutb          (ram_red_data    )
); 
////////////////////////////////////////////////////////////////////////////////
// (*) red en                        ////	   
  always @(posedge dac_data_clk_buf or posedge sys_rst) begin
  	   if(sys_rst)  
  	     ram_red_en <= 1'd0;
  	   else
         ram_red_en <= ram_wr_en_dl[0];
  end 
////////////////////////////////////////////////////////////////////////////////
// (6) R addr                         ////	   
  always @(posedge dac_data_clk_buf or posedge sys_rst) begin
  	   if(sys_rst)
  	     ram_raddr <= 10'd0;
  	   else if(ram_red_en)
  	     ram_raddr <= ram_raddr + 1'd1;
  	   else
  	     ram_raddr <= 10'd0;
  end	

////////////////////////////////////////////////////////////////////////////////
// (7) red en                        ////	   
  always @(posedge dac_data_clk_buf or posedge sys_rst) begin
  	   if(sys_rst)  
  	     ram_rd_en_dl <= 5'd0;
  	   else
         ram_rd_en_dl <= {ram_red_en,ram_rd_en_dl[4:1]};
  end   
//////////////////////////////////////////////////////////////////////////////////
//// (8) ////
 always @(posedge dac_data_clk_buf or posedge logic_rst) begin
 	   if(logic_rst)
        dac_tx_en <= 1'd0;
    else if(mif_dac_data_mode[15])begin
	       if(dl_data_dac_window)begin
		      if(ram_rd_en_dl[3])
			   dac_tx_en <= 1'd1;
              else
               dac_tx_en <= dac_tx_en;
		   end
		   else
		   dac_tx_en <= 1'd0; 
    end		   
	else
     	dac_tx_en <= ram_rd_en_dl[3];
 end	
  //  else if(dl_data_dac_window)begin
  //         if(ram_rd_en_dl[3])
  //           dac_tx_en <= 1'd1;
  //         else
  //           dac_tx_en <= dac_tx_en;
  //  end
  //  else
   //   dac_tx_en <= 1'd0;
   //  else 
	//     dac_tx_en <= ram_rd_en_dl[3];
// end
/////////////////////////////////////////////////////////////////////////////////
/// (9) data I Q 调整，正交                           ////	 
 always @(posedge dac_data_clk_buf or posedge sys_rst) begin
 	   if(sys_rst)
 	   	  fpga_dac_data_reg <= 18'd0;
	   else if(mif_dac_data_mode[15])begin
 	         if(ram_rd_en_dl[4])
                 fpga_dac_data_reg <= {ram_red_data,2'd0}; 
             else
                 fpga_dac_data_reg <= 18'd0;
	    end
		else if(ram_rd_en_dl[4])
		     fpga_dac_data_reg <= {ram_red_data,2'd0}; 
		else
             fpga_dac_data_reg <= fpga_dac_data_reg;
 end 

/////////////////////////////////////////////////////////////////////////////////
/// (9) data I Q DL                          ////	 
 always @(posedge dac_data_clk_buf or posedge sys_rst) begin
 	   if(sys_rst)
 	   	  fpga_dac_data_reg_dl <= 18'd0;
 	   else 
        fpga_dac_data_reg_dl <= fpga_dac_data_reg; 
 end 



 




//----------------------------------------------2015/11/18 14:13:59----------------------------//
 
 ////////////////////for test
 reg[15:0] clk_50m_cnt    = 16'd0;
 reg[15:0] clk_dacclk_cnt = 16'd0;
 
  always @(posedge clk_50m or posedge sys_rst) begin
 	   if(sys_rst)
 	   	  clk_50m_cnt[15:0] <= 16'd0;
       else
 	      clk_50m_cnt[15:0] <= clk_50m_cnt[15:0] + 1'b1;
 end
 
   always @(posedge dac_data_clk_buf or posedge sys_rst) begin
 	   if(sys_rst)
 	   	  clk_dacclk_cnt[15:0] <= 16'd0;
       else
 	      clk_dacclk_cnt[15:0] <= clk_dacclk_cnt[15:0] + 1'b1;
 end



 //-----------------------DEBUG    	        
      
   
//assign  debug_signal[199:162]  = 38'd0;	
//assign  debug_signal[161]      = fifo_full;
//assign  debug_signal[160:145]  = clk_50m_cnt[15:0];	
//assign  debug_signal[144:129]  = clk_dacclk_cnt[15:0];	
//	
//assign  debug_signal[128]      = msk_data_valid;					
//assign  debug_signal[127:96]   = msk_iq_data[31:0];						
//assign  debug_signal[95:64]    = fifo_data_in[31:0];							
//assign  debug_signal[63]       = dl_data_dac_window;						
//assign  debug_signal[62]       = clk_50m;
//assign  debug_signal[61]       = clk_25m;
//assign  debug_signal[60]       = data_split_pip;
//assign  debug_signal[59:42]    = fpga_dac_data_reg[17:0]; // 21
//assign  debug_signal[41]       = dac_data_clk_buf;           //22
//assign  debug_signal[40:9]     = fifo_data_out[31:0];     //54
//assign  debug_signal[8]        = dac_tx_en;
//assign  debug_signal[7]        = fifo_data_rd[9];
//assign  debug_signal[6]        = fifo_empty;
//assign  debug_signal[5]        = fifo_data_wr;
//assign  debug_signal[4:0]      = fifo_data_rd[12:8];

assign  debug_signal[199:166]  = 76'd0;

assign  debug_signal[123]      = msk_data_valid;
assign  debug_signal[122:91]   = msk_iq_data[31:0];
assign  debug_signal[90:75]    = ram_red_data[15:0];
assign  debug_signal[74]       = dl_data_dac_window;
assign  debug_signal[73:56]    = fpga_dac_data_reg_dl[17:0];
assign  debug_signal[55]       = dac_tx_en;
assign  debug_signal[54:45]    = ram_raddr[9:0];
assign  debug_signal[44]       = ram_red_en;
assign  debug_signal[43:12]    = ram_wr_data[31:0];
assign  debug_signal[11:3]     = ram_waddr[8:0];
assign  debug_signal[2]        = ram_wr_en;
assign  debug_signal[1]        = dac_data_clk_buf;
assign  debug_signal[0]        = clk_25m;





                        
                        
                        
                      //  fifo_empty,
                      //  fifo_data_wr,
                      //  fifo_data_rd[9],
                      //  msk_data_valid,
                      //  fifo_data_in,
                      //  dac_data_clk_buf,
                      //  dac_tx_en,
                      //  fifo_data_out,
                      //  20'd0
                      //  };



	 
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////	 
endmodule	 