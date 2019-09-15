//////////////////////////////////////////////////////////////////////////////////
// Company:        StarPoint
// Engineer:       GZY
// 
// Create Date:    
// Module Name:    
// Project Name:   Common I2C design
// Tool versions:  ISE14.6
// Description:    
//
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps




module i2c_rtc(
// clock & reset
input               i2c_clk_in,                              // 400KHz 2倍于SCL
input               i2c_rst_in,
// operation & register
input               i2c_wen,                              // '0'-read, '1'-write
input [7:0]         group_number,
input               i2c_stat,                               // '1' 启动

input [15:0]        rtc_data,
output [7:0]        rtc_count,
output              i2c_rtc_clk,
output              i2c_wend,
														                 	              //读操作时低8位数据值无效
output reg [7:0]    i2c_reg_out,                            // I2C 读取的数据
output reg			    i2c_rd_valid,							              //I2C读取上升沿时有效
// I2C interface
output  reg         i2c_scl_out,
inout               i2c_sda_out,
output              i2c_clk_out,
output              i2c_tx_io,
output              i2c_rx_io,
output              debug_signal

    );



reg       i2c_scl_div2;
reg       i2c_scl_div3;
reg       i2c_en;
reg [7:0] i2c_en_cnt;
reg [7:0] i2c_wcnt;
reg [7:0] i2c_group_number;
reg [7:0] i2c_tx_data_reg;
reg       i2c_tx_data;
reg [7:0] i2c_rx_data;
reg [15:0]i2c_sda_data_reg;
reg       i2c_io_en;
reg       i2c_end;
wire      i2c_sda_din;
reg       i2c_stat_dl;
reg [2:0] i2c_number;
reg [3:0] repeat_cnt;
reg       i2c_repeat_stat;
reg       i2c_all_end;
reg       red_en_stat;
reg [3:0] red_en_cnt ;
reg       red_ct_txd; 
reg       i2c_stat_en;
reg [2:0] i2c_stat_en_cnt;





//-------------------------------------------------------------------
  //  assign  i2c_reg_out[15:0]           = i2c_sda_data[15:0];
    assign  i2c_rtc_clk                = i2c_scl_div2;
    assign  i2c_wend                    = i2c_all_end;//i2c_end;
    assign  rtc_count                   = i2c_group_number;
    assign  i2c_tx_io            = i2c_tx_data;
    assign  i2c_rx_io            = i2c_sda_din;





 ////////////////////////////////////////////////////////////////////////////////
 // (0) I2C data out ////

   IOBUF #(
      .DRIVE(4),                     // Specify the output drive strength
      .IBUF_LOW_PWR("TRUE"),         // Low Power - "TRUE", High Performance = "FALSE" 
      .IOSTANDARD("DEFAULT"),        // Specify the I/O standard
      .SLEW("SLOW")                  // Specify the output slew rate
   ) IOBUF_inst (                    
      .O   (i2c_sda_din),            // Buffer output
      .IO  (i2c_sda_out),            // Buffer inout port (connect directly to top-level port)
      .I   (i2c_tx_data),            // Buffer input
      .T   (~i2c_io_en)              // 3-state enable input, high=input, low=output
   );

 ////////////////////////////////////////////////////////////////////////////////
 // (0) I2C timing count ////
 always@(posedge i2c_clk_in or posedge i2c_rst_in)
 begin
      if (i2c_rst_in)
         i2c_scl_div2 <= 1'b1;
      else
         i2c_scl_div2 <= ~i2c_scl_div2;
 end   
  ////////////////////////////////////////////////////////////////////////////////
 // (0) I2C timing count ////
 always@(posedge i2c_scl_div2 or posedge i2c_rst_in)
 begin
      if (i2c_rst_in)
        i2c_stat_dl <= 1'd0;
      else 
        i2c_stat_dl <= i2c_stat_en;
 end
 
   ////////////////////////////////////////////////////////////////////////////////
 // (0) I2C timing count ////
 always@(posedge i2c_scl_div2 or posedge i2c_rst_in)
 begin
      if (i2c_rst_in)
        i2c_stat_en <= 1'd0;
      else if(i2c_stat_en_cnt == 3'd3)
        i2c_stat_en <= 1'd0; 
      else if(i2c_stat)
        i2c_stat_en <= 1'd1;
 end
   ////////////////////////////////////////////////////////////////////////////////
 // (0) I2C timing count ////
 always@(posedge i2c_scl_div2 or posedge i2c_rst_in)
 begin
      if (i2c_rst_in)
        i2c_stat_en_cnt <= 3'd0;
      else if(i2c_stat_en)
        i2c_stat_en_cnt <= i2c_stat_en_cnt + 1'd1;
      else
        i2c_stat_en_cnt <= 3'd0;
 end 
 
 
 
 ////////////////////////////////////////////////////////////////////////////////
 // (0) I2C timing count ////
 always@(posedge i2c_scl_div2 or posedge i2c_rst_in)
 begin
      if (i2c_rst_in)
         i2c_en <= 1'd0;
     else if(i2c_end || i2c_all_end || red_en_stat||i2c_stat_en)
		     i2c_en <= 1'b0;		   
      else if((i2c_stat_dl && !i2c_stat_en) || i2c_repeat_stat || red_en_cnt == 4'd5)
         i2c_en <= 1'd1;
      else 
         i2c_en <= i2c_en;
 end
 

 ////////////////////////////////////////////////////////////////////////////////
 // (0) red_en_stat ////
 always@(posedge i2c_scl_div2 or posedge i2c_rst_in)
 begin
      if (i2c_rst_in) 
        red_en_stat <= 1'd0;
      else if(red_en_cnt == 4'd4 )
        red_en_stat <= 1'd0;
      else if(!i2c_wen && i2c_wcnt == 8'd8 && i2c_number == 3'd1)
        red_en_stat <= 1'd1;
      else
        red_en_stat <= red_en_stat;
 end
      
 ////////////////////////////////////////////////////////////////////////////////
 // (0) red_en_cnt ////
 always@(posedge i2c_scl_div2 or posedge i2c_rst_in)
 begin
      if (i2c_rst_in) 
        red_en_cnt <= 4'd0;
      else if(red_en_stat)
        red_en_cnt <= red_en_cnt + 1'd1;
      else
        red_en_cnt <= 4'd0;
 end 
  ////////////////////////////////////////////////////////////////////////////////
 // (0) red_en_cnt ////
 always@(posedge i2c_scl_div2 or posedge i2c_rst_in)
 begin
      if (i2c_rst_in) 
        red_ct_txd <= 1'd0;
      else if(!i2c_wen && i2c_wcnt == 8'd8 && i2c_number == 3'd1)
        red_ct_txd <= 1'd1;
      else if(red_en_cnt == 4'd4)
        red_ct_txd <= 4'd1;
      else
        red_ct_txd <= 1'd0;
 end 
  ////////////////////////////////////////////////////////////////////////////////
 // (0) I2C repeat count ////
 always@(posedge i2c_scl_div2 or posedge i2c_rst_in)
 begin
      if (i2c_rst_in)
         i2c_repeat_stat <= 1'd0;
	  else if(i2c_group_number == group_number)
	      i2c_repeat_stat <= 1'd0;
     else if(repeat_cnt == 3'd4)
	      i2c_repeat_stat <= 1'd1;
	  else
	      i2c_repeat_stat <= 1'd0;
 end
  ////////////////////////////////////////////////////////////////////////////////
 // (0) I2C repeat count ////
 always@(posedge i2c_scl_div2 or posedge i2c_rst_in)
 begin
      if (i2c_rst_in)
         repeat_cnt <= 3'd0;
	  else if(repeat_cnt == 3'd4 || i2c_all_end)
	      repeat_cnt <= 3'd0;
     else if(i2c_wen)begin
	         if(i2c_number == 4'd3)
				   repeat_cnt <= repeat_cnt + 1'd1;
			   else
				   repeat_cnt <= repeat_cnt;
	  end
	  else if(i2c_number == 4'd4)
	     repeat_cnt <= repeat_cnt + 1'd1;
	  else
	     repeat_cnt <= repeat_cnt;   				
 end 
 

 
 ////////////////////////////////////////////////////////////////////////////////
 // (0) I2C timing count ////
 always@(posedge i2c_scl_div2 or posedge i2c_rst_in)
 begin
      if (i2c_rst_in)
         i2c_en_cnt <= 8'd0;
      else if(i2c_en)
         i2c_en_cnt <= i2c_en_cnt + 1'b1;
      else 
         i2c_en_cnt <= 8'd0;
 end 
 ////////////////////////////////////////////////////////////////////////////////
 // (0) I2C timing count ////
 always@(posedge i2c_scl_div2 or posedge i2c_rst_in)
 begin
      if (i2c_rst_in)
         i2c_wcnt <= 8'd0;
      else if(i2c_wcnt == 8'd8 ||i2c_stat)
         i2c_wcnt <= 8'd0;
      else if(i2c_en)
         i2c_wcnt <= i2c_wcnt + 1'b1;
      else 
         i2c_wcnt <= 8'd0;
 end  
 ////////////////////////////////////////////////////////////////////////////////
 // (0) I2C  Group number////
 always@(posedge i2c_scl_div2 or posedge i2c_rst_in)
 begin
      if (i2c_rst_in)
         i2c_group_number <= 8'd0;
      else if(i2c_end && i2c_group_number == group_number ||i2c_stat)
         i2c_group_number <= 8'd0;
      else if(i2c_wcnt == 8'd8 && i2c_number == 8'd2)
         i2c_group_number <= i2c_group_number + 1'd1;
      else
         i2c_group_number <= i2c_group_number;
 end
 ////////////////////////////////////////////////////////////////////////////////
 // (0) I2C                     number////i2c_wen
 always@(posedge i2c_scl_div2 or posedge i2c_rst_in)
 begin
      if (i2c_rst_in)
         i2c_number <= 3'd0;
	   else if(i2c_repeat_stat || i2c_stat||i2c_all_end)
		    i2c_number <= 3'd0;
      else if(i2c_wcnt == 8'd8)begin
            if(i2c_wen && i2c_number == 3'd3)
              i2c_number <= 3'd0;
            else if(i2c_number == 3'd4)
              i2c_number <= 3'd0;
            else
              i2c_number <= i2c_number + 1'd1;
      end
      else
         i2c_number <= i2c_number;      
 end 
 
 //////////////////////////////////////////////////////////////////////////////// 
 // (0) I2C  Group number////                                                     
 always@(*)                                                                       
 begin                         
      if (i2c_rst_in)                                                             
         i2c_tx_data_reg = 8'd0;                                                                  	                                                                                     
      else if(i2c_wen)begin     //写
      	      if(i2c_number == 3'd0)
      	        i2c_tx_data_reg = 8'b11010000; 
      	      else if(i2c_number == 3'd1)
      	        i2c_tx_data_reg = rtc_data[15:8]; 
			    		else if(i2c_number == 3'd2)
					      i2c_tx_data_reg = rtc_data[7:0]; 
					    else
					      i2c_tx_data_reg = 8'b00000000;
      end
      else if(i2c_number == 3'd0)
              i2c_tx_data_reg = 8'b11010000; 
	    else if(i2c_number == 3'd1)
		          i2c_tx_data_reg = rtc_data[15:8]; 
      else if(i2c_number == 3'd2 )
              i2c_tx_data_reg = 8'b11010001;
	  	else
		          i2c_tx_data_reg = 8'b00000000; 	                                        
 end                                                                              
 
 ////////////////////////////////////////////////////////////////////////////////
 // (0) I2C timing count ////
 always@(posedge i2c_scl_div2 or posedge i2c_rst_in)
 begin
      if (i2c_rst_in)
         i2c_tx_data <= 1'b1;
      else if(i2c_stat_dl || (!i2c_wen && i2c_wcnt == 8'd8)||i2c_repeat_stat||red_ct_txd)
         i2c_tx_data <= 1'b0;
      else if(i2c_en)begin
      	     case(i2c_wcnt)
     	         4'd0 : i2c_tx_data <= i2c_tx_data_reg[7];
     	         4'd1 : i2c_tx_data <= i2c_tx_data_reg[6];
     	         4'd2 : i2c_tx_data <= i2c_tx_data_reg[5];
     	         4'd3 : i2c_tx_data <= i2c_tx_data_reg[4];
     	         4'd4 : i2c_tx_data <= i2c_tx_data_reg[3];
     	         4'd5 : i2c_tx_data <= i2c_tx_data_reg[2];
     	         4'd6 : i2c_tx_data <= i2c_tx_data_reg[1];
     	         4'd7 : i2c_tx_data <= i2c_tx_data_reg[0];
     	         default: i2c_tx_data <= 1'b1;
     	       endcase
      end
      else
        i2c_tx_data <= 1'b1;
 end
  ////////////////////////////////////////////////////////////////////////////////
 // (0) I2C timing count ////
 always@(posedge i2c_scl_div2 or posedge i2c_rst_in)
 begin
      if (i2c_rst_in)   
        i2c_end <= 1'd0;        
      else if( i2c_wen && i2c_wcnt == 8'd8 && i2c_number == 4'd2)
		    i2c_end <= 1'd1;
		else if(i2c_wcnt == 8'd7 && i2c_number == 4'd3)
        i2c_end <= 1'd1;
      else
        i2c_end <= 1'd0;
 end 
 
   ////////////////////////////////////////////////////////////////////////////////
 // (0) I2C timing count ////
 always@(posedge i2c_scl_div2 or posedge i2c_rst_in)
 begin
      if (i2c_rst_in)   
        i2c_all_end <= 1'd0;
//      else if(i2c_stat)		
//		    i2c_all_end <= 1'd0;
      else if(i2c_end && i2c_group_number == group_number )
		    i2c_all_end <= 1'd1;
		else 
        i2c_all_end <= 1'd0;
 end 
 ////////////////////////////////////////////////////////////////////////////////
 // (0) I2C timing count ////
 always@(posedge i2c_scl_div2 or posedge i2c_rst_in)
 begin
      if (i2c_rst_in)   
        i2c_io_en <= 1'd1;        
      else if(!i2c_wen && i2c_number > 8'd2)begin
      	     if(i2c_wcnt == 8'd8)
      	        i2c_io_en <= 1'd1; 
      	     else
                 i2c_io_en <= i2c_io_en;
      end
      else if(i2c_wcnt == 8'd8)
        i2c_io_en <= 1'd0;
      else
        i2c_io_en <= 1'd1;
 end
 ////////////////////////////////////////////////////////////////////////////////
 // (0) I2C i2c_scl_out  ////
 always@(negedge i2c_clk_in or posedge i2c_rst_in)
 begin
      if (i2c_rst_in)   
        i2c_scl_out <= 1'd1;
      else if(i2c_en)
        i2c_scl_out <= i2c_scl_div2;
      else
        i2c_scl_out <= 1'd1;
 end      

 //-------------------------red--------------------------------------------------
 ////////////////////////////////////////////////////////////////////////////////
 // (*) I2C rx--data////
  always@(posedge  i2c_scl_div2 or posedge i2c_rst_in)
  begin
  	   if(i2c_rst_in)
  	     i2c_rx_data <= 8'd0;
  	   else 
  	   	 i2c_rx_data <= {i2c_rx_data[6:0],i2c_sda_din};
  end   
 ////////////////////////////////////////////////////////////////////////////////
 // (*) I2C flag ////
  always@(posedge  i2c_scl_div2 or posedge i2c_rst_in)
  begin
  	   if(i2c_rst_in)
  	     i2c_reg_out  <= 8'd0;
  	   else if(!i2c_wen && i2c_number == 4'd3) begin
  	          if(i2c_en_cnt == 8'd17) 
  	             i2c_reg_out <= i2c_rx_data;
  	          else
  	             i2c_reg_out <= i2c_reg_out;
  	   end 
  	   else
  	    i2c_reg_out <= i2c_reg_out;
  end
 ////////////////////////////////////////////////////////////////////////////////
 // (*) I2C flag ////
  always@(posedge  i2c_scl_div2 or posedge i2c_rst_in)
  begin
  	   if(i2c_rst_in)
  	     i2c_rd_valid  <= 1'd0; 	     
  	   else if(!i2c_wen && i2c_number == 4'd4 && i2c_en_cnt == 8'd18)
  	     i2c_rd_valid  <= 1'd1; 
  	   else
  	     i2c_rd_valid  <= 1'd0; 
  end



//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
endmodule