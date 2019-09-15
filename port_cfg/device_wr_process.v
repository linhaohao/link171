////////////////////////////////////////////////////////////////////////////////
// Company: <Company Name>
// Engineer: GZY
//
// Create Date: <date>
// Design Name:
// Moducs Name:
// Target Device: 
// Tool versions: 
// Description:
//    
// Dependencies:
//    <Dependencies here>
// Revision:
//    <Code_revision_information>
// Additional Comments:
//                    mcbsp || urt 写器件功能实现，分发和选择对应器件。
////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps


module device_wr_process(
// clk/rst
input               spi_clk_in, 
input               sys_rest,
input               rs_clk,
//IN
input                        rs_rx_data_valid,
input [63:0]                 rs_rx_data,     
                             
input [31:0]                 mcbsp_data,
input                        mcbsp_data_valid,
//----------------
input                        dsp_rdy_pulse,
input                        initial_en,
input                        spi_initial_start,
//OUT-----------------------------------------
output reg [31:0]            dac_cfg_data  ,
output reg [7:0]             dac_cfg_addr  ,
output reg                   dac_cfg_valid ,
output reg [31:0]            adc_cfg_data  ,   
output reg [7:0]             adc_cfg_addr  ,   
output reg                   adc_cfg_valid ,   
output reg [31:0]            if2rf_cfg_wr_data,   
output reg [7:0]             if2rf_cfg_addr   ,   
output reg                   if2rf_cfg_valid  ,   
output reg [31:0]            lmk_cfg_data ,    
output reg [7:0]             lmk_cfg_addr ,    
output reg                   lmk_cfg_valid,       
output reg                   lmk0_spi_start    ,
output reg                   lmk1_spi_start    ,
output reg                   adc0_spi_start    ,
output reg                   adc1_spi_start    ,
output reg                   dac_spi_start     ,
output reg                   adf4351_spi_start ,
output reg                   ads8332_spi_start ,
output reg                   if2rf_cfg_select_mode,
output reg                   spi_single_en,

output  [31:0]               mif_data_in,
output                       mif_en_in,

output [63:0]                debug_signal	    
);

//////////////////////////////////////////////////////////////////////////////////
//// signal declaration ////
reg                   rs_rx_data_valid_dl;
reg                   rs_rx_data_valid_dl2;
reg [31:0]            rs_rx_data_l;
reg [31:0]            rs_fifo_wr_data;
reg                   rs_fifo_write;
//reg                   rs_fifo_rd_en;
//wire [31:0]            fifo_data_out;

//wire                  fifo_empty;
//reg [2:0]             rs_rd_stat_cnt;
reg [5:0]             rs_unpack_en_cnt;
reg                   rs_rx_data_unpack_en;
//reg                   rs_fifo_rd_en_dl;
reg [31:0]            cfg_data_dl;
reg [31:0]            cfg_data;
reg                   cfg_data_valid;
reg [7:0]             if_config_addr;
reg [7:0]             cfg_select;

reg [31:0]            if_config_data;
reg                   if_config_data_rdy;
reg                   cfg_data_valid_dl;



//////////////////////////////////////////////////////////////////////////////////
//// signal assignment ////
  assign mif_data_in  = cfg_data;
  assign mif_en_in    = cfg_data_valid;




//////////////////////////////////////////////////////////////////////////////////
////(*) PC - RS - FPGA  
//-----------------------------------------
always@(posedge rs_clk or posedge sys_rest)
begin    
	if(sys_rest)begin
		rs_rx_data_valid_dl   <= 1'd0;
		rs_rx_data_valid_dl2  <= 1'd0;
	end
	else begin
		rs_rx_data_valid_dl  <= rs_rx_data_valid;
		rs_rx_data_valid_dl2 <= rs_rx_data_valid_dl;
	end
end
//------------------------------	  
always@(posedge rs_clk or posedge sys_rest)
begin    
	if(sys_rest)
	   rs_rx_data_l <= 32'd0;
	else if(rs_rx_data_valid)
	   rs_rx_data_l <= rs_rx_data[31:0];
	else if(!rs_rx_data_valid_dl)
	   rs_rx_data_l <= 32'd0;
	else
	   rs_rx_data_l <= rs_rx_data_l;
end		
//-----------------------------------------			
always@(posedge rs_clk or posedge sys_rest)
begin    
	if(sys_rest)
	  rs_fifo_wr_data <= 32'd0;
	else if(rs_rx_data_valid)
	   rs_fifo_wr_data <= rs_rx_data[63:32];
	else if(rs_rx_data_valid_dl)
	   rs_fifo_wr_data <= rs_rx_data_l;
	else
	  rs_fifo_wr_data <= 32'd0;
end	

always@(*)
begin
	 rs_fifo_write =   rs_rx_data_valid_dl|rs_rx_data_valid_dl2;
end 
////------------------------------------	
//always@(posedge spi_clk_in or posedge sys_rest)
//begin
//	    if(sys_rest)
//	      rs_rd_stat_cnt <= 3'd0;
//	    else if(!fifo_empty)
//	      rs_rd_stat_cnt <= rs_rd_stat_cnt + 1'd1;
//	    else
//	      rs_rd_stat_cnt <= 3'd0;
//end
////-----------------------------------------	
//always@(posedge spi_clk_in or posedge sys_rest)
//begin
//	    if(sys_rest)
//	      rs_fifo_rd_en <= 1'd0;
//      else if(rs_rd_stat_cnt > 3'd2)
//	      rs_fifo_rd_en <= ~fifo_empty;
//	    else
//	      rs_fifo_rd_en <= 1'd0;
//end
//////////////////////////////////////////////////////////////////////////////////
////(*-1) 时钟隔离，隔离来自 串口数据		
//fifo_32x512  U_urt2fpga_fifo(
//  .rst           (sys_rest       ),
//  .wr_clk        (rs_clk         ),           //7.832....7.832时钟取消。目前时钟同源，不需要时钟隔离fifo 2015/10/13 16:52:38
//  .rd_clk        (spi_clk_in     ),           //10mhz fpga
//  .din           (rs_fifo_wr_data),
//  .wr_en         (rs_fifo_write  ),
//  .rd_en         (rs_fifo_rd_en  ),
//  .dout          (fifo_data_out  ),
//  .full          (fifo_full      ),
//  .empty         (fifo_empty     )
//);	 
//-----------------------------------------		 	
always@(posedge spi_clk_in or posedge sys_rest)
begin  
	   if(sys_rest)
	     rs_unpack_en_cnt <= 6'd0;
	   else if(rs_rx_data_unpack_en)
	     rs_unpack_en_cnt <= rs_unpack_en_cnt + 1'd1;
	   else
	     rs_unpack_en_cnt <= 6'd0;
end

//-----------------------------------------		 	
always@(posedge spi_clk_in or posedge sys_rest)
begin  
	   if(sys_rest)
	     cfg_data_valid_dl <= 1'd0;
	   else 
	     cfg_data_valid_dl <= cfg_data_valid;
end
//------------------------------------------
always@(posedge spi_clk_in or posedge sys_rest)
begin    
	     if(sys_rest)
	        rs_rx_data_unpack_en <= 2'd0;
	     else if(rs_unpack_en_cnt == 6'd5)
	        rs_rx_data_unpack_en <= 2'd0;
	 //    else if((cfg_data_valid && !cfg_data_valid_dl)&& cfg_data[15:0] != 16'hFFFF)
	     else if((cfg_data_valid && !cfg_data_valid_dl)&& cfg_data[31:16] == 16'hABAB)
	        rs_rx_data_unpack_en <=  1'd1;
	     else 
	        rs_rx_data_unpack_en <= rs_rx_data_unpack_en;
end	    
/////////////////////////////////////////////////////////////
//DL
always@(posedge spi_clk_in or posedge sys_rest)
begin 
       if(sys_rest)begin
          cfg_data_dl      <= 32'd0;
//          rs_fifo_rd_en_dl2 <= 1'd0;
       end
       else begin      
//       	  rs_fifo_rd_en_dl2 <= rs_fifo_rd_en_dl;
          cfg_data_dl       <= cfg_data;                 
       end          
end
//-----------
//reg rs_fifo_rd_en_dl2;
//always@(posedge spi_clk_in or posedge sys_rest)
//begin 
//       if(sys_rest)
//          rs_fifo_rd_en_dl <= 1'd0;         
//       else if(rs_fifo_rd_en)
//          rs_fifo_rd_en_dl <= 1'd1;          
//       else
//          rs_fifo_rd_en_dl <= 1'd0;                      
//end

//////////////////////////////////////////////////////////////
//-----mcbsp || urt 数据选择，dsp优先级高
always@(posedge spi_clk_in or posedge sys_rest)
begin 
       if(sys_rest)begin
          cfg_data       <= 32'd0;
          cfg_data_valid <= 1'd0;
       end
//       else if(rs_fifo_rd_en_dl)begin
//          cfg_data       <= fifo_data_out;
//          cfg_data_valid <= rs_fifo_rd_en_dl;    //时钟同源同频，取消时钟隔离。2015/10/13 16:57:21
//       end       
       else if(rs_fifo_write)begin
          cfg_data       <= rs_fifo_wr_data;
          cfg_data_valid <= rs_fifo_write;
       end         
       else if(mcbsp_data_valid)begin
          cfg_data       <= mcbsp_data;
          cfg_data_valid <= mcbsp_data_valid;
       end         	   
       else begin
          cfg_data       <= 32'd0;
          cfg_data_valid <= 1'd0;
       end   
end
////////////////////////////////////////////////////////////////////////////////////
////(1-2) 配置地址，根据解析DSP包信息分配对应设备地址。
//暂定为：
//AD0                 1
//AD1                 2
//DA                  3
//LMK0                4
//LMK1                5
//ADF4351             6
//ADS8332  只读       7
always@(negedge spi_clk_in or posedge sys_rest)
begin
  if (sys_rest)
     if_config_addr[7:0]    <= 32'd0;
  else if(rs_rx_data_unpack_en && rs_unpack_en_cnt == 6'd0)
     if_config_addr <= cfg_data_dl[7:0];
  else
     if_config_addr[7:0]  <= if_config_addr[7:0];
  end 
//////////////////////////////////////////////////////////////////////////////////
////(1-3) 根据包内容区分 配置目标
always@(posedge spi_clk_in or posedge sys_rest)begin
  if (sys_rest)
     cfg_select <= 8'd0;
 else if(rs_unpack_en_cnt == 8'd0 && rs_rx_data_unpack_en)
  //	 cfg_select <= cfg_data_dl[21:16];    
  	 cfg_select <= cfg_data_dl[15:8];    	 
 else
     cfg_select <= cfg_select;
  end 
//////////////////////////////////////////////////////////////////////////////////
////(1-3-1) 根据包内容选择 配置目标
always@(posedge spi_clk_in or posedge sys_rest)begin
  if (sys_rest)begin
  	dac_cfg_data     <= 31'd0;    
    dac_cfg_addr     <= 8'd0;       
    dac_cfg_valid    <= 1'd0;       
    //------------------
    adc_cfg_data     <= 31'd0; 
    adc_cfg_addr     <= 8'd0;  
    adc_cfg_valid    <= 1'd0;    
    //------------------
    if2rf_cfg_wr_data   <= 31'd0;
    if2rf_cfg_addr      <= 8'd0; 
    if2rf_cfg_valid     <= 1'd0;    
    //------------------
    lmk_cfg_data     <= 31'd0; 
    lmk_cfg_addr     <= 8'd0;   
    lmk_cfg_valid    <= 1'd0;  
    //--------------------------    
  end
  else if(cfg_select == 8'd5 || cfg_select == 8'd4)begin
    adc_cfg_data     <= if_config_data;      
    adc_cfg_addr     <= if_config_addr;           
    adc_cfg_valid    <= if_config_data_rdy;  
  end
  else if(cfg_select == 8'd1 || cfg_select == 8'd2) begin   
    lmk_cfg_data     <= if_config_data;         	
    lmk_cfg_addr     <= if_config_addr;         	      	
    lmk_cfg_valid    <= if_config_data_rdy;    
  end	 
  else if(cfg_select == 8'd3) begin
  	dac_cfg_data     <= if_config_data;         
    dac_cfg_addr     <= if_config_addr;                  
    dac_cfg_valid    <= if_config_data_rdy;       

  end
  else if(cfg_select == 8'd6 || cfg_select == 8'd7) begin
    if2rf_cfg_wr_data   <= if_config_data;      
    if2rf_cfg_addr      <= if_config_addr;                
    if2rf_cfg_valid     <= if_config_data_rdy;            
  end
  else begin
    dac_cfg_data     <= dac_cfg_data   ; 
    dac_cfg_addr     <= dac_cfg_addr   ; 
    dac_cfg_valid    <= dac_cfg_valid  ;   
    //------------------   //--------------- 
    adc_cfg_data     <= adc_cfg_data   ;
    adc_cfg_addr     <= adc_cfg_addr   ;
    adc_cfg_valid    <= adc_cfg_valid  ;
    //------------------   //--------------- 
    if2rf_cfg_wr_data   <= if2rf_cfg_wr_data ;  
    if2rf_cfg_addr      <= if2rf_cfg_addr    ;  
    if2rf_cfg_valid     <= if2rf_cfg_valid   ;       
  end  	
end
//////////////////////////////////////////////////////////////////////////////////
////(1-7)采集配置参数
always@(posedge spi_clk_in or posedge sys_rest)begin
  if (sys_rest)
     if_config_data                  <= 32'd0;      
  else if(rs_unpack_en_cnt == 6'd1 && rs_rx_data_unpack_en)
     if_config_data                  <= cfg_data_dl;
  else
     if_config_data                  <= if_config_data;
end	

//////////////////////////////////////////////////////////////////////////////////
////(1-8)产生配置参数生效使能
always@(posedge spi_clk_in or posedge sys_rest)begin
  if (sys_rest)
     if_config_data_rdy                  <= 1'd0;
  else if(rs_unpack_en_cnt >= 6'd2)
     if_config_data_rdy                  <= 1'd1;    
  else
     if_config_data_rdy                  <= 1'd0;
end	  
//////////////////////////////////////////////////////////////////////////////////
////(3) spi start
always@(posedge spi_clk_in or posedge sys_rest)begin
    if (sys_rest)begin
      lmk0_spi_start    <= 1'd0;
      lmk1_spi_start    <= 1'd0;
      adc0_spi_start    <= 1'd0;
      adc1_spi_start    <= 1'd0;
      dac_spi_start     <= 1'd0;
      adf4351_spi_start <= 1'd0;
      ads8332_spi_start <= 1'd0;
    end
    else if(initial_en)begin
      lmk0_spi_start <= spi_initial_start;
      lmk1_spi_start <= spi_initial_start; 
      adc0_spi_start <= 1'd0;
      adc1_spi_start <= 1'd0;
      dac_spi_start  <= 1'd0;
      adf4351_spi_start <= 1'd0;
      ads8332_spi_start <= 1'd0;
    end
    else if(dsp_rdy_pulse)begin 
    	lmk0_spi_start <= 1'd0;
      lmk1_spi_start <= 1'd0; 
      adc0_spi_start <= 1'd1;
      adc1_spi_start <= 1'd1;
      dac_spi_start  <= 1'd0;
      adf4351_spi_start <= 1'd1;
      ads8332_spi_start <= 1'd0;
    end     	
   else if(rs_unpack_en_cnt == 6'd3 ) begin        
    	case(cfg_select)
    //	6'd1:begin
    //		adc0_spi_start <= 1'd1;
    //	end
    //	6'd2:begin
    //		adc1_spi_start <= 1'd1;
    //	end  
    //	6'd3:begin
    //		dac_spi_start <= 1'd1;
    //	end   	
    //	6'd4:begin
    //		lmk0_spi_start <= 1'd1;
    //	end 
    //	6'd5:begin
    //		lmk1_spi_start <= 1'd1;
    //	end    	
    //	6'd6:begin
    //		adf4351_spi_start <= 1'd1;
    //	end      	
    //	6'd7:begin
    //		ads8332_spi_start <= 1'd1;
    //	end
    	 6'd1:begin                       
		     lmk0_spi_start <= 1'd1;        
	     end                              
	     6'd2:begin   
	     	 lmk1_spi_start <= 1'd1;                    	     	       
	     end                              
	     6'd3:begin  
	       dac_spi_start <= 1'd1;                     	     	        
	     end   	                         
	     6'd4:begin                       
	       adc0_spi_start <= 1'd1;   	  
	     end                              
	     6'd5:begin                       
	     	 adc1_spi_start <= 1'd1;          
	     end    	                         
	     6'd6:begin                       
	     	adf4351_spi_start <= 1'd1;     
	     end      	                       
	     6'd7:begin                       
	     	ads8332_spi_start <= 1'd1;     
	     end                              
    
     default:   begin
      lmk0_spi_start <= 1'd0;
      lmk1_spi_start <= 1'd0;
      adc0_spi_start <= 1'd0;
      adc1_spi_start <= 1'd0;
      dac_spi_start  <= 1'd0;
      adf4351_spi_start <= 1'd0;
      ads8332_spi_start <= 1'd0;     	
     end
    endcase
	 end
   else begin
     lmk0_spi_start       <= 1'd0;
     lmk1_spi_start       <= 1'd0;
     adc0_spi_start       <= 1'd0;
     adc1_spi_start       <= 1'd0;
     dac_spi_start        <= 1'd0;
     adf4351_spi_start    <= 1'd0;
     ads8332_spi_start    <= 1'd0;
   end
end     	
//////////////////////////////////////////////////////////////////////////////////
////(4)  RF spi select mode
always@(posedge spi_clk_in or posedge sys_rest)
begin
    if (sys_rest)
       if2rf_cfg_select_mode <= 3'd0;
    else if(cfg_select == 8'd7)    //8332
       if2rf_cfg_select_mode <= 3'd1;
    else 
       if2rf_cfg_select_mode <= 3'd0; //4351
end

//////////////////////////////////////////////////////////////////////////////////
////(5)  SPI single  单次写SPI区分使能。
always@(posedge spi_clk_in or posedge sys_rest)
begin
    if (sys_rest)
       spi_single_en <= 1'd0;
    else if(rs_unpack_en_cnt >= 6'd2 )
       spi_single_en <= 1'd1;
    else 
       spi_single_en <= 1'd0;
end







//////////////////////////////////////////////////////////////////////////////////
//// debug signal ////
assign  debug_signal             = {lmk0_spi_start   ,
                                    lmk1_spi_start   ,
                                    adc0_spi_start   ,
                                    adc1_spi_start   ,
                                    dac_spi_start    ,
                                    adf4351_spi_start,
                                    ads8332_spi_start,                                        
                                    //7
                               //     rs_fifo_rd_en_dl, 
                                    cfg_data_valid,
                                    cfg_data[31:0],  //41
                                    spi_single_en,   //42 
                                    if2rf_cfg_select_mode ,//43
                                    dsp_rdy_pulse ,        // 44     
                                 //   fifo_full,     
                                 //   fifo_empty,    
                                    rs_rx_data_unpack_en,    
                                    20'd0                                                                  
                                    };  










//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
endmodule


