//////////////////////////////////////////////////////////////////////////////////
// Company:        StarPoint
// Engineer:       GZY
// 
// Create Date:   
// Module Name:    
// Project Name:   
// Target Devices:  
// Tool versions:  
// Description:    
//                 
//
// Revision:       v1.0 - File Created
// Additional Comments: 
//                    完成LMK 上电初始配置
//                    支持回读   
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps


module adc_cfg(
// Clock & Reset    
input               cfg_spi_clk,	                           // 10MHz SPI cfg clk
input               cfg_rst_in,
// ADC0 SPI mapping
input                   adc0_spi_start,
output wire             adc0_spi_clk,
output wire             adc0_spi_cs,
output wire             adc0_spi_sdi,
input                   adc0_spi_sdo,
// ADC1 SPI mapping      
input                   adc1_spi_start,
output wire             adc1_spi_clk,
output wire             adc1_spi_cs,
output wire             adc1_spi_sdi,
input                   adc1_spi_sdo,
//  DSP  wr    
//----------------------
input               spi_rd_stat,
input               spi_rd_en,

input               spi_single_en      ,
input               adc_cfg_valid   ,
input [7:0]         adc_cfg_addr    ,      
input [31:0]        adc_cfg_data    ,
output reg[31:0]    adc_rd_parameter   ,
output reg          adc_rd_valid       ,
// debug
output[63:0]       debug_signal

	 );

//////////////////////////////////////////////////////////////////////////////////
//// parameter //// 
parameter ADCS_LENGTH     = 7'd16;



//////////////////////////////////////////////////////////////////////////////////
//// Signal declration ////
reg [31:0]          adc_board_ctl = 32'h00000000;


reg [15:0]          adc0_data_reg = 16'd0;
reg [15:0]          adc1_data_reg = 16'd0;


wire[ 6:0]          adc0_count_reg;
wire[ 6:0]          adc1_count_reg;


wire[ 1:0]          adc_rst_ctl;
//// ADC(adc0_spi_cs) register ////(8bits WR+address + 8bits data) 
parameter  adc0_data_reg0     = 16'h0080;
parameter  adc0_data_reg1     = 16'h0100;
parameter  adc0_data_reg2     = 16'h0200;
parameter  adc0_data_reg3     = 16'h0300;
parameter  adc0_data_reg4     = 16'h0481;        // 


parameter  adc1_data_reg0     = 16'h0080;
parameter  adc1_data_reg1     = 16'h0100;
parameter  adc1_data_reg2     = 16'h0200;
parameter  adc1_data_reg3     = 16'h0300;
parameter  adc1_data_reg4     = 16'h0481;        // 

///-------------
reg [6:0]            ad_spi_number;
reg                  spi_wr_en;      
wire                 spi_1_end;
wire                 spi_2_end;
wire[31:0]           adc0_data_out;
wire                 adc0_data_valid;
wire[31:0]           adc1_data_out;
wire                 adc1_data_valid;
wire                 spi_all_end;
reg                  dsp_if_rd_en;
reg                  spi_1_stat;
reg                  spi_0_stat;
reg [7:0]            red_addr_cnt;



//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//// (0) signal assignment ////
    assign  adc_rst_ctl[0]              = cfg_rst_in ; 
    assign  adc_rst_ctl[1]              = cfg_rst_in ;    
//////////////////////////////////////////////////////////////////////////////////
//// (*) red  返回一个读出数据地址。
 always@(negedge cfg_spi_clk or posedge cfg_rst_in)
begin
	  if(cfg_rst_in) 
	     red_addr_cnt <= 8'd0;
	  else if(red_addr_cnt == 8'd5)
	     red_addr_cnt <= 8'd0;
	  else if(adc0_data_valid || adc1_data_valid)
       red_addr_cnt <= red_addr_cnt + 1'd1;
    else
       red_addr_cnt <= red_addr_cnt;
end    
//////////////////////////////////////////////////////////////////////////////////
//// (*) spi red
always@(negedge cfg_spi_clk or posedge cfg_rst_in)
begin    
	if(cfg_rst_in) begin
  	adc_rd_valid     <= 1'd0;
    adc_rd_parameter <= 32'd0; 
  end  	
  else if(adc0_data_valid)begin
  	adc_rd_valid     <= 1'd1;
    adc_rd_parameter <= {16'h0adc,red_addr_cnt,adc0_data_out[7:0]};  
  end
  else if(adc1_data_valid)begin
  	adc_rd_valid      <= 1'd1;
    adc_rd_parameter  <= {16'h1adc,red_addr_cnt,adc1_data_out[7:0]};  
  end  
  else begin
  	adc_rd_valid     <= 1'd0;
    adc_rd_parameter <= 32'd0; 
  end  	
end
//////////////////////////////////////////////////////////////////////////////////
//// (*) SPI操作次数，
always@(negedge cfg_spi_clk or posedge cfg_rst_in)
begin
	    if(cfg_rst_in)
	       ad_spi_number <= 6'd0;	    
	    else if(spi_single_en && (adc0_spi_start || adc1_spi_start))
         ad_spi_number <= 6'd1;
      else if(adc0_spi_start || adc1_spi_start || spi_rd_stat)
         ad_spi_number <= 6'd5;
      else
         ad_spi_number <= ad_spi_number;
end
//////////////////////////////////////////////////////////////////////////////////
//// (*) 单写使能
always@(negedge cfg_spi_clk )
begin
	    if(spi_single_en && (adc0_spi_start || adc1_spi_start))
         spi_wr_en <= 1'd1;
      else if(spi_1_end||spi_2_end)
         spi_wr_en <= 1'd0;
      else
         spi_wr_en <= spi_wr_en;
end  
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
////(1) SPI stat select ////
always@(negedge cfg_spi_clk )
begin
    if(adc0_spi_start || spi_rd_stat)      
      spi_0_stat <= 1'd1;
    else
      spi_0_stat <= 1'd0;
end
//////////////////////////////////////////////////////////////////////////////////
////(1) SPI stat select ////
always@(negedge cfg_spi_clk )
begin
    if(adc1_spi_start || (spi_rd_en && spi_all_end))      
      spi_1_stat <= 1'd1;
    else
      spi_1_stat <= 1'd0;
end
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
////(2) SPI w   r   select ////
always@(negedge cfg_spi_clk  or posedge cfg_rst_in)
begin
	  if(cfg_rst_in)
	    dsp_if_rd_en <= 1'd0;
	  else if(spi_rd_stat)
	    dsp_if_rd_en <= 1'd1;
    else if(spi_2_end)      
      dsp_if_rd_en <= 1'd0;
    else
      dsp_if_rd_en <= dsp_if_rd_en;
end

//////////////////////////////////////////////////////////////////////////////////
//// (3) ADC(adc0_spi_cs) SPI configuration ////
//// (3-1) Link1 ADC SPI configuration ////
jft_spi   U2_adc0
    (
	 .spi_clk_in        (cfg_spi_clk       ),
	 .spi_rst_in        (cfg_rst_in        ),
	 .spi_start         (spi_0_stat        ),   //可以控制一下复位后加载时间
	 .spi_wr            (dsp_if_rd_en      ),
	 .spi_end           (spi_1_end         ),
    .spi_all_end      (spi_all_end       ),
	 .spi_start_number  (ad_spi_number     ),
	 .spi_cs_length     (ADCS_LENGTH       ),
	 .spi_data_in       ({adc0_data_reg,24'd0}),
	 
   .spi_clk           (adc0_spi_clk),	 
   .spi_cs            (adc0_spi_cs ),	 
   .spi_sdi           (adc0_spi_sdi),	 
   .spi_sdo           (adc0_spi_sdo),	
   
   .spi_data_out      (adc0_data_out),
   .spi_data_valid    (adc0_data_valid),	 
   
	 .spi_count_starte   (adc0_count_reg[6:0]),
	 .debug_signal()	 	 
	 );

//// (3-2) Link2 ADC SPI configuration ////
jft_spi   U3_adc1 
    (
	 .spi_clk_in        (cfg_spi_clk ),
	 .spi_rst_in        (cfg_rst_in  ),
	 .spi_start         (spi_1_stat  ),   //可以控制一下复位后加载时间
	 .spi_wr            (dsp_if_rd_en),
	 .spi_end           (),
   .spi_all_end       (spi_2_end    ),
	 .spi_start_number  (ad_spi_number),
	 .spi_cs_length     (ADCS_LENGTH),
	 .spi_data_in       ({adc1_data_reg,24'd0}),
	 
   .spi_clk           (adc1_spi_clk),	 
   .spi_cs            (adc1_spi_cs ),	 
   .spi_sdi           (adc1_spi_sdi),	 
   .spi_sdo           (adc1_spi_sdo),	
   
   .spi_data_out      (adc1_data_out),
   .spi_data_valid    (adc1_data_valid),	 
   
	 .spi_count_starte   (adc1_count_reg[6:0]),
	 .debug_signal()	 	 
	 );

////////////////////////////////////////////////////
//// Link1-ADC-adc0_spi_cs Register mapping 
always@(negedge cfg_spi_clk or posedge cfg_rst_in)
begin
  if (cfg_rst_in)   begin
    adc0_data_reg[15:0]                <= 16'd0;
  end
  else if(spi_wr_en && adc_cfg_valid) //URAT|DSP写数据                
     adc0_data_reg[15:0] <= {adc_cfg_data[15:0]};    
  else if(spi_rd_en)begin
  	     case(adc0_count_reg[6:0])
  	     7'd0: adc0_data_reg[15:0]    <= 16'h8000;
  	     7'd1: adc0_data_reg[15:0]    <= 16'h8100;
  	     7'd2: adc0_data_reg[15:0]    <= 16'h8200;
         7'd3: adc0_data_reg[15:0]    <= 16'h8300;
         7'd4: adc0_data_reg[15:0]    <= 16'h8400;
         default: adc0_data_reg[15:0] <= 16'd0;
       endcase
  end                      
  else   begin
    case(adc0_count_reg[6:0])
	      7'd0: adc0_data_reg[15:0]    <= adc0_data_reg0[15:0];
	      7'd1: adc0_data_reg[15:0]    <= adc0_data_reg1[15:0]; 
	      7'd2: adc0_data_reg[15:0]    <= adc0_data_reg2[15:0];
	      7'd3: adc0_data_reg[15:0]    <= adc0_data_reg3[15:0];
	      7'd4: adc0_data_reg[15:0]    <= adc0_data_reg4[15:0];
	      default:adc0_data_reg[15:0]  <= adc0_data_reg0[15:0];	
	  endcase
  end
end
/////////////////////////////////////////////////////////////
//// Link2-ADC-adc0_spi_cs Register mapping //// 12 register
always@(negedge cfg_spi_clk or posedge cfg_rst_in)
begin
  if (cfg_rst_in)
    adc1_data_reg[15:0]                <= 16'd0;
  else if(spi_wr_en && adc_cfg_valid) //URAT|DSP写数据                                  
    adc1_data_reg[15:0] <= {adc_cfg_data[15:0]};          
  else if(spi_rd_en)begin
  	     case(adc1_count_reg[6:0])
  	         7'd0: adc1_data_reg[15:0] <= 16'h8000;
  	         7'd1: adc1_data_reg[15:0] <= 16'h8100;
  	         7'd2: adc1_data_reg[15:0] <= 16'h8200;
             7'd3: adc1_data_reg[15:0] <= 16'h8300;
             7'd4: adc1_data_reg[15:0] <= 16'h8400;
             default: adc1_data_reg[15:0] <= 16'd0;
         endcase
  end  
  else   begin
    case(adc1_count_reg[6:0])
	      7'd0:adc1_data_reg[15:0]     <= adc1_data_reg0[15:0];
	      7'd1:adc1_data_reg[15:0]     <= adc1_data_reg1[15:0];	 
	      7'd2:adc1_data_reg[15:0]     <= adc1_data_reg2[15:0];
	      7'd3:adc1_data_reg[15:0]     <= adc1_data_reg3[15:0];
	      7'd4:adc1_data_reg[15:0]     <= adc1_data_reg4[15:0];
	      default:adc1_data_reg[15:0]  <= adc1_data_reg0[15:0];	
	  endcase
  end
end


//////////////////////////////////////////////////////////////////////////////////
//// debug signal ////
assign  debug_signal[63:0]              = {spi_1_stat,
                                           dsp_if_rd_en,
                                           adc1_spi_clk,
                                           adc1_spi_cs,
                                           adc1_spi_sdi,
                                           adc1_spi_sdo,
                                           adc1_data_reg, //16
                                           adc1_data_out,
                                           adc1_data_valid,
                                           adc1_count_reg,
                                           spi_wr_en,
                                           adc1_spi_start
                                           };



//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
endmodule





















