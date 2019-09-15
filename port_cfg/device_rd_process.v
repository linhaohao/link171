////////////////////////////////////////////////////////////////////////////////
// Company: <Company Name>
// Engineer: GZY
//
// Create Date: <date>
// Design Name: <name_of_top-csvel_design>
// Moducs Name: <name_of_this_moducs>
// Target Device: <target device>
// Tool versions: <tool_versions>
// Description:
//    
// Dependencies:
//    <Dependencies here>
// Revision:
//    <Code_revision_information>
// Additional Comments:
//    1、完成所有可读器件的定时读操作,对读出器件参数顺序存入ram
//    2、完成ue对器件的灵活读取操作，dsp通过MCBSP读取128位器件参数，mif每次读指定位置参数。
//    3、DSP读出数据送入MCBSP模块进行传输，
//      
////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps


module device_rd_process(
// clk/rst
input               spi_clk_in, 
input               spi_rst_in,
//------------
input               dsp2fpga_dsp_rdy,
input               dsp_rd_stat,
output reg[31:0]    dsp_rd_data,
output reg          dsp_rd_data_valid,

input               mif_rd_stat,
input  [9:0]        mif_rd_addr,
output reg [31:0]   mif_rd_data,     
output reg          mif_rs_stat,

//----spi
output              dac_rd_en_reg ,
output              dac_device_rd_stat,    
input               dac_rd_valid,
input [31:0]        dac_rd_data,
//
output              adc_rd_en_reg  ,
output              adc_device_rd_stat,
input               adc_rd_valid,
input [31:0]        adc_rd_data,
//
output              lmk_rd_en_reg  ,
output              lmk_device_rd_stat,    
input               lmk_rd_valid,
input [31:0]        lmk_rd_data,
//
output              rf_rd_en_reg   ,
output              rf_device_rd_stat ,         
input               rf2if_cfg_rd_valid,  
input [31:0]        rf2if_cfg_rd_data,   
//
output reg          i2c_rd_stat,
input [31:0]        i2c_rd_data,
input               i2c_rd_valid,
input               i2c_rtc_valid,
input [31:0]        i2c_rtc_data,


// starte/debug                    
output [63:0]       debug_signal	 


);

//////////////////////////////////////////////////////////////////////////////////
//// parameter ////
parameter   TIMING = 28'd20000000;//10mhz 1s


//parameter   TIMING = 24'd5000;//test

//////////////////////////////////////////////////////////////////////////////////
//// signal declaration ////

reg [27:0]   timing_cnt;

reg          device_rd_stat;
reg          device_all_end;
reg          ram_wen;
reg [31:0]   ram_wdata;
reg [8:0]    ram_waddr =  9'd0;
reg          ram_rd_en_reg;
reg          ram_rd_en;
reg [8:0]    ram_rd_addr;
wire [31:0]  ram_rd_data;

reg          device_rd_en;
reg          clash_en;
reg          mif_rd_time;
reg [5:0]    mif_rd_time_cnt;     
reg          mif_rs_stat_reg;
reg [3:0]    rd_dl_cnt;
reg [1:0]    rtc_addr_cnt;

//////////////////////////////////////////////////////////////////////////////////
//// signal assignment ////
    
       
       assign  lmk_rd_en_reg        = (ram_waddr < 10'd50) ? device_rd_en   : 1'd0;
       assign  lmk_device_rd_stat   = (ram_waddr < 10'd50) ? device_rd_stat : 1'd0;  
       
       assign  dac_rd_en_reg        = (ram_waddr > 10'd49 && ram_waddr < 10'd53 ) ? device_rd_en   : 1'd0;
       assign  dac_device_rd_stat   = (ram_waddr > 10'd49 && ram_waddr < 10'd53 ) ? device_rd_stat : 1'd0; 
                          
       assign  adc_rd_en_reg        = (ram_waddr > 10'd52 && ram_waddr < 10'd64) ? device_rd_en   : 1'd0;
       assign  adc_device_rd_stat   = (ram_waddr > 10'd52 && ram_waddr < 10'd64) ? device_rd_stat : 1'd0;
       
       assign  rf_rd_en_reg         = (ram_waddr > 10'd63) ? device_rd_en   : 1'd0;
       assign  rf_device_rd_stat    = (ram_waddr > 10'd63) ? device_rd_stat : 1'd0;
       
  //     assign  i2c_rd_stat          = device_all_end;



//////////////////////////////////////////////////////////////////////////////////
//// (0) 1s 读一次，读间隔约1s ////
always@(posedge spi_clk_in or posedge spi_rst_in)
begin
	if (spi_rst_in)
	 timing_cnt <= 28'd0;
	else if(timing_cnt == TIMING - 1'd1)
	 timing_cnt <= 28'd0;
	else if(dsp2fpga_dsp_rdy)
	 timing_cnt <= timing_cnt + 1'd1;
	else 
	 timing_cnt <= 28'd0;
end
//////////////////////////////////////////////////////////////////////////////////
//// (1) device_rd stat////
always@(posedge spi_clk_in or posedge spi_rst_in)
begin
	if (spi_rst_in)
	 device_rd_stat <= 1'd0;
	else if(timing_cnt == TIMING - 1'd1)
	 device_rd_stat <= 1'd1;
	else if(ram_wen)begin
	       if(ram_waddr == 10'd49 || ram_waddr == 10'd52 || ram_waddr == 10'd63)
            device_rd_stat <= 1'd1;
         else		
	          device_rd_stat <= 1'd0;
  end
  else
    device_rd_stat <= 1'd0;
end
//////////////////////////////////////////////////////////////////////////////////
//// (2) device_rd en////
always@(posedge spi_clk_in or posedge spi_rst_in)
begin
	if (spi_rst_in)
	 device_rd_en <= 1'd0;
	else if(timing_cnt == TIMING - 1)	      
	 device_rd_en <= 1'd1;
	else if(device_all_end)
	 device_rd_en <= 1'd0;
	else
	 device_rd_en <= device_rd_en;
end
//////////////////////////////////////////////////////////////////////////////////
//// (3) ram   wen////
always@(posedge spi_clk_in or posedge spi_rst_in)
begin
	if (spi_rst_in)
	 ram_wen <= 1'd0;
	else if(adc_rd_valid || dac_rd_valid || rf2if_cfg_rd_valid || lmk_rd_valid || i2c_rd_valid||i2c_rtc_valid)
	 ram_wen <= 1'd1;
	else 
	 ram_wen <= 1'd0;
end
//////////////////////////////////////////////////////////////////////////////////
//// (4) ram   wdata////
always@(posedge spi_clk_in or posedge spi_rst_in)
begin
	if (spi_rst_in)
	 ram_wdata <= 32'd0;
	else if(adc_rd_valid) 
	 ram_wdata <= adc_rd_data;     
  else if(lmk_rd_valid)
   ram_wdata <= lmk_rd_data;
	else if(dac_rd_valid) 
	 ram_wdata <= dac_rd_data;
	else if(rf2if_cfg_rd_valid) 
	 ram_wdata <= rf2if_cfg_rd_data;	
	else if(i2c_rd_valid)
	 ram_wdata <= i2c_rd_data;   //{16'h22cc,i2c_rd_data[15:0]} ;
	else if(i2c_rtc_valid)
	 ram_wdata <= i2c_rtc_data; 
	else
	 ram_wdata <= 32'd0; 
end
//////////////////////////////////////////////////////////////////////////////////
//// (@) RTC分时器////
always@(posedge spi_clk_in or posedge spi_rst_in)
begin
	if (spi_rst_in)
	   rtc_addr_cnt <= 2'd0;
	else if(device_all_end)
	   rtc_addr_cnt <= 2'd0;
	else if(i2c_rtc_valid)begin
         if(rtc_addr_cnt == 2'd1)
           rtc_addr_cnt <= 2'd0;
         else
           rtc_addr_cnt <=  rtc_addr_cnt + 1'd1;
         end
  else
      rtc_addr_cnt <= rtc_addr_cnt;
end
//////////////////////////////////////////////////////////////////////////////////
//// (5) ram  addr 写地址在每次开始读前会做清0，写到最大器件量也会做清0。////
always@(posedge spi_clk_in or posedge spi_rst_in)
begin
	if (spi_rst_in)
	 ram_waddr <= 9'd1;
	else if(i2c_rd_valid)
	 ram_waddr <= 9'd100;
  else if(i2c_rtc_valid)
   ram_waddr <= 9'd101 + rtc_addr_cnt;
	else if(timing_cnt == TIMING - 1'd1 || ram_waddr == 9'd63)
	 ram_waddr <= 9'd1;
	else if(ram_wen) 
	 ram_waddr <= ram_waddr + 1'd1;
	else
	 ram_waddr <= ram_waddr; 
end
//////////////////////////////////////////////////////////////////////////////////
//// (*) 写完标志////
always@(posedge spi_clk_in or posedge spi_rst_in)
begin
	if (spi_rst_in)
	 device_all_end <= 1'd0;
	else if(ram_waddr == 9'd63)
	 device_all_end <= 1'd1;
	else
	 device_all_end <= 1'd0; 
end
//////////////////////////////////////////////////////////////////////////////////
//// (*)  RAM   读器件信息存储                        ////
ram_32x512 ram_device_info(
  .clka                   (spi_clk_in),
  .ena                    (1'd1),
  .wea                    (ram_wen),
  .addra                  (ram_waddr),
  .dina                   (ram_wdata),
  .clkb                   (spi_clk_in),
  .enb                    (ram_rd_en),
  .addrb                  (ram_rd_addr),
  .doutb                  (ram_rd_data)
);
//////////////////////////////////////////////////////////////////////////////////
//// (*) ////
always@(posedge spi_clk_in or posedge spi_rst_in)
begin
	if(spi_rst_in)
	 ram_rd_en <= 1'd0;
  else if(mif_rd_stat)
	 ram_rd_en <= 1'd1;
	else 
	 ram_rd_en <= 1'd0;
end
//////////////////////////////////////////////////////////////////////////////////
//// (*)  读地址     
always@(posedge spi_clk_in or posedge spi_rst_in)
begin
	if (spi_rst_in)
	 ram_rd_addr <= 9'd0;
	else 
	 ram_rd_addr <= mif_rd_addr;
end
//////////////////////////////////////////////////////////////////////////////////
//// (*)  读出数据有效使能  
always@(posedge spi_clk_in or posedge spi_rst_in)
begin
	if (spi_rst_in)begin
		  mif_rs_stat_reg <= 1'd0;
      mif_rs_stat     <= 1'd0;
  end
  else begin 
      mif_rs_stat_reg <= ram_rd_en;
      mif_rs_stat     <= mif_rs_stat_reg;
  end
end
//////////////////////////////////////////////////////////////////////////////////
//// (*)  mif 读数据 
always@(posedge spi_clk_in or posedge spi_rst_in)
begin
	if (spi_rst_in)
     mif_rd_data <= 32'd0;
  else 
     mif_rd_data <= ram_rd_data;
end
//////////////////////////////////////////////////////////////////////////////////
//// (*)  DSP   RED
reg [31:0]   dsp_rd_data1;
reg [31:0]   dsp_rd_data2;
reg [31:0]   dsp_rd_data3;
reg [31:0]   dsp_rd_data4;
reg          dsp_rd_en;
reg [2:0]    dsp_rd_cnt;



//////////////////////////////////////////////////////////////////////////////////
//// (*) 寄存器刷新方法暂时未定义，I2C等查询接口固定后开始使用，目前只保留接口。2015/10/14 16:54:04  
always@(*)
begin
	if (spi_rst_in)begin
		 dsp_rd_data1  <= 32'd0;
     dsp_rd_data2  <= 32'd0;
     dsp_rd_data3  <= 32'd0;
     dsp_rd_data4  <= 32'd0;         
  end
  else if(ram_wen)begin             
  	dsp_rd_data1  <= 32'd1;
    dsp_rd_data2  <= 32'd2;
    dsp_rd_data3  <= 32'd3;
    dsp_rd_data4  <= 32'd4;   
  end
  else begin
  end
end
//////////////////////////////////////////////////////////////////////////////////
//// (*)  DSP valid
always@(posedge spi_clk_in or posedge spi_rst_in)
begin
	if (spi_rst_in)
     dsp_rd_en <= 1'd0;
  else if(dsp_rd_stat)
     dsp_rd_en <= 1'd1;
  else if(dsp_rd_cnt == 3'd3)
     dsp_rd_en <= 1'd0;
  else
     dsp_rd_en <= dsp_rd_en;
end
//////////////////////////////////////////////////////////////////////////////////
//// (*)  DSP cnt
always@(posedge spi_clk_in or posedge spi_rst_in)
begin
	if (spi_rst_in)
     dsp_rd_cnt <= 3'd0;
  else if(dsp_rd_en)
     dsp_rd_cnt <= dsp_rd_cnt + 3'd1;
  else
     dsp_rd_cnt <= 3'd0;
end
//////////////////////////////////////////////////////////////////////////////////
//// (*)  DSP data
always@(posedge spi_clk_in or posedge spi_rst_in)
begin
	if (spi_rst_in)
     dsp_rd_data <= 31'd0;
  else if(dsp_rd_en)begin
  	 case(dsp_rd_cnt)
  	    3'd0 : dsp_rd_data <= dsp_rd_data1;
  	    3'd1 : dsp_rd_data <= dsp_rd_data2;
  	    3'd2 : dsp_rd_data <= dsp_rd_data3;
  	    3'd3 : dsp_rd_data <= dsp_rd_data4;
  	    default: dsp_rd_data <= 31'd0;
  	 endcase
  end
  else
    dsp_rd_data <= 31'd0;
end
//////////////////////////////////////////////////////////////////////////////////
//// (*)  DSP dsp_rd_data_valid
always@(posedge spi_clk_in or posedge spi_rst_in)
begin
	if (spi_rst_in)
     dsp_rd_data_valid <= 1'd0;
  else 
     dsp_rd_data_valid <= dsp_rd_en;
end

//-------------

//////////////////////////////////////////////////////////////////////////////////
//// (*)  读控制，温度传感器需要扩大读周期。
always@(posedge spi_clk_in or posedge spi_rst_in)
begin
	  if (spi_rst_in)
       rd_dl_cnt <= 5'd0;
    else if(i2c_rd_stat)
       rd_dl_cnt <= 5'd0;
    else if(device_all_end)
       rd_dl_cnt <= rd_dl_cnt + 1'd1;
    else
       rd_dl_cnt <= rd_dl_cnt;
end
//////////////////////////////////////////////////////////////////////////////////
//// (*)  I2C stat
always@(posedge spi_clk_in or posedge spi_rst_in)
begin
	  if (spi_rst_in)
       i2c_rd_stat <= 1'd0;
    else if(rd_dl_cnt== 4'd1)
       i2c_rd_stat <=  device_all_end;
    else
       i2c_rd_stat <= 1'd0;
end








//////////////////////////////////////////////////////////////////////////////////
//// debug signal ////
assign  debug_signal             = {ram_wen,
                                    ram_waddr[8:0],
                                    ram_wdata[31:0],
                                    ram_rd_en,
                                    ram_rd_addr[8:0],
                                    ram_rd_data[10:0],
                                    //
                                    device_rd_stat,
                                    device_all_end,
                                    mif_rd_stat
                                    }; 






 



//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
endmodule






































































