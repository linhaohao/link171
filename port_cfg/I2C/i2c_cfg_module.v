////////////////////////////////////////////////////////////////////////////////
// Company: <Company Name>
// Engineer: GZY
//
// Create Date: <date>
// Design Name: <name_of_top-level_design>
// Module Name: <name_of_this_module>
// Target Device: <target device>
// Tool versions: <tool_versions>
// Description:
//    <Description here>
// Dependencies:
//    <Dependencies here>
// Revision:
//    <Code_revision_information>
// Additional Comments:
//    完成对TMP100温度传感器，RTC器件的I2C配置控制工作。
//   
////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps
module i2c_cfg_module(
//clk rst
input                   i2c_sys_clk,    
input                   i2c_clk    ,    
input                   i2c_rst    ,     
//data in
input                   lmk_stable_lock,
input                   i2c_rd_en,
input                   i2c_rd_stat,
////
input                   mif_wrtc_stat,
input      [31:0]       mif_wrtc_data_in,
//--datat out                
output reg [31:0]       i2c_reg_out  ,  
output reg              i2c_rd_valid ,  

output reg [31:0]       i2c_rtc_red_data1,
output reg              i2c_rtc_valid,


//--parot                
output                  i2c_0_scl_out  ,  
inout                   i2c_0_sda_out  ,  
output                  i2c_1_scl_out  ,  
inout                   i2c_1_sda_out  ,     

output                  rtc_i2c_scl,
inout                   rtc_i2c_sda,

///--DEBUG                
output[63:0]            debug_signal

);



//////////////////////////////////////////////////////////////////////////////////
//// parameter ////


//////////////////////////////////////////////////////////////////////////////////
//// Signal declration ////
reg [4:0]  i2c_int_stat;
reg [4:0]  i2c_rd_addr;
reg [15:0] i2c_data_in;
reg        i2c_rd_end;
reg        i2c_mode_en;
reg        i2c_wen_stat;
wire       i2c_wend;
reg        i2c_int_en;
wire[63:0] i2c_debug;
reg        i2c_stat;
reg        i2c_stat_dl;
reg        i2c_stat_pulse;
reg [7:0]  i2c_odata_cnt;
reg [7:0]  group_number;
reg [7:0]  i2c_rtc_gnumber;
reg        i2c_rtc_mode_en;
reg        rtc_stat_pulse;
reg        rtc_stat_tmp;
reg        rtc_stat_tmp_dl;
reg [15:0]  rtc_data_in;
reg [1:0]  data_sw;
reg [3:0]  rtc_rd_cnt;
//reg [31:0] i2c_rtc_red_data1;
reg [31:0] i2c_rtc_red_data2;
reg        rtc_wr_en;
//reg        i2c_rtc_valid;
wire       i2c_tt_end;
//wire       rtc_i2c_scl;
wire       i2c_tx_io;
wire       i2c_rx_io;


reg        i2c_clk_dvi2;
wire       i2c_clk_out;
wire[15:0] i2c_0_out_data;
wire[15:0] i2c_1_out_data;
wire       i2c_0_rd_valid;
wire       i2c_1_rd_valid;
wire [7:0] rtc_count;
wire [7:0] i2c_rtc_out_data;
wire       i2c_rtc_rd_valid;
wire       i2c_rtc_clk;


////////////////////////////////////////////////////////////////////////////////////////////
///(*)
always@(negedge i2c_sys_clk or posedge i2c_rst)
begin
	    if(i2c_rst)
	      i2c_int_en <= 1'd1; 
	    else if(i2c_int_stat[1]&& !i2c_int_stat[0]) 
	      i2c_int_en <= 1'd0; 
	    else
	      i2c_int_en <= i2c_int_en; 
end

////////////////////////////////////////////////////////////////////////////////////////////
///(*)时钟锁定后初始化
always@(negedge i2c_sys_clk or posedge i2c_rst)
begin
	    if(i2c_rst)
	      i2c_int_stat <= 5'd0; 
	    else
	      i2c_int_stat <= {lmk_stable_lock,i2c_int_stat[4:1]}; 
end

////////////////////////////////////////////////////////////////////////////////////////////
///(*) 读写使能
always@(negedge i2c_sys_clk or posedge i2c_rst)
begin
	    if(i2c_rst)
	      i2c_mode_en <= 1'd0; 
	    else if(!i2c_int_en && i2c_rd_stat) //初始化写完,全为读
	      i2c_mode_en <=  1'd1;
	    else
	      i2c_mode_en <= i2c_mode_en;
end
////////////////////////////////////////////////////////////////////////////////////////////
///(*)group_number  读写数量
 always@(negedge i2c_sys_clk or posedge i2c_rst)
 begin
	    if(i2c_rst)
        group_number <= 8'd0;
      else if(i2c_mode_en)
        group_number <= 8'd2;
      else
        group_number <= 8'd4;
 end 
////////////////////////////////////////////////////////////////////////////////////////////
///(*)
always@(negedge i2c_sys_clk or posedge i2c_rst)
begin
	    if(i2c_rst)
	      i2c_stat <= 1'd0;
	    else if(i2c_stat_dl)
	      i2c_stat <= 1'd0;
	    else if(i2c_int_en && (i2c_int_stat[1]&& !i2c_int_stat[0]))
	      i2c_stat <= 1'd1;
	    else if(!i2c_int_en && i2c_rd_stat)
	      i2c_stat <= 1'b1;
	    else 
	      i2c_stat <= i2c_stat;
end
////////////////////////////////////////////////////////////////////////////////////////////
///(*) 将stat信号展宽，确保I2C可以采集到
always@(negedge i2c_clk_out or posedge i2c_rst)
begin
	    if(i2c_rst)
	      i2c_stat_dl <= 1'd0;
	    else 
	      i2c_stat_dl <= i2c_stat;
end
////////////////////////////////////////////////////////////////////////////////////////////
///(*)
always@(negedge i2c_clk_out or posedge i2c_rst)
begin
	    if(i2c_rst)
	      i2c_stat_pulse <= 1'd0;
	    else if(i2c_stat && !i2c_stat_dl)
	      i2c_stat_pulse <= 1'd1;
	    else
	      i2c_stat_pulse <= 1'd0;
end
////////////////////////////////////////////////////////////////////////////////////////////
///(*)400K降速，低速器件，时钟要求不严格。
always@(negedge i2c_clk or posedge i2c_rst)
begin
	    if(i2c_rst)
       i2c_clk_dvi2 <= 1'd0;
      else
       i2c_clk_dvi2 <= ~i2c_clk_dvi2;
end
// temperature
i2c_tmp100   U1_TT1(
      .i2c_clk_in              (i2c_clk_dvi2),     
      .i2c_rst_in              (i2c_rst),
      .i2c_wr_rd               (i2c_mode_en   ), 
      .group_number            (group_number  ),
		  .i2c_stat                (i2c_stat_pulse), 
      .i2c_wend                (i2c_tt_end),										
      				                 	   
      .i2c_reg_out             (i2c_0_out_data    ),             
      .i2c_rd_valid            (i2c_0_rd_valid    ),		
      					      
      .i2c_scl_out             (i2c_0_scl_out     ),
      .i2c_sda_out             (i2c_0_sda_out     ),
      .i2c_clk_out             (i2c_clk_out       ),
      
      .debug_signal            ()           
    );
//---------------------
// temperature
i2c_tmp100   U2_TT2(
      .i2c_clk_in              (i2c_clk_dvi2),     
      .i2c_rst_in              (i2c_rst),
      .i2c_wr_rd               (i2c_mode_en   ), 
      .group_number            (group_number  ),
		  .i2c_stat                (i2c_stat_pulse), 
      .i2c_wend                (),	
      													                 	   
      .i2c_reg_out             (i2c_1_out_data     ),   
      .i2c_rd_valid            (i2c_1_rd_valid     ),		
      					      
      .i2c_scl_out             (i2c_1_scl_out      ),
      .i2c_sda_out             (i2c_1_sda_out      ),
      
      .debug_signal            ()           
    );

////////////////////////////////////////////////////////////////////////////////////////////
///(*)data out
 always@(negedge i2c_sys_clk or posedge i2c_rst)
 begin
	    if(i2c_rst)
        i2c_reg_out <= 32'd0;
      else if(i2c_0_rd_valid)
        i2c_reg_out <= {i2c_0_out_data,i2c_1_out_data};
      else
        i2c_reg_out <= i2c_reg_out;
 end
////////////////////////////////////////////////////////////////////////////////////////////
///(*)确保两个器件反应时间对齐。
 always@(negedge i2c_sys_clk or posedge i2c_rst)
 begin
	    if(i2c_rst)
        i2c_odata_cnt <= 8'd0;
      else if(i2c_0_rd_valid)
        i2c_odata_cnt <= i2c_odata_cnt + 1'd1;
      else
        i2c_odata_cnt <= 8'd0;
 end       
////////////////////////////////////////////////////////////////////////////////////////////
///(*)data out   en
 always@(negedge i2c_sys_clk or posedge i2c_rst)
 begin
	    if(i2c_rst)
        i2c_rd_valid <= 1'd0;
      else if(i2c_odata_cnt == 8'd50)
        i2c_rd_valid <= 1'd1;
      else
        i2c_rd_valid <= 1'd0;
 end 
//---------------------
// RTC
i2c_rtc   U3_RTC(
      .i2c_clk_in              (i2c_clk              ),     
      .i2c_rst_in              (i2c_rst              ),
      .i2c_wen                 (i2c_rtc_mode_en      ), 
      .group_number            (i2c_rtc_gnumber      ),
		  .i2c_stat                (rtc_stat_pulse       ),
      .i2c_wend                (i2c_rtc_wend         ),

      .i2c_reg_out             (i2c_rtc_out_data     ),             
      .i2c_rd_valid            (i2c_rtc_rd_valid     ),

      .rtc_count               (rtc_count            ),
      .rtc_data                (rtc_data_in          ),
      .i2c_rtc_clk             (i2c_rtc_clk          ),
      .i2c_tx_io               (i2c_tx_io            ),
      .i2c_rx_io               (i2c_rx_io            ),
      
      .i2c_scl_out             (rtc_i2c_scl          ),
      .i2c_sda_out             (rtc_i2c_sda          ),

      .debug_signal            ()           
    );
////////////////////////////////////////////////////////////////////////////////////////////
///(*)i2c_rtc_gnumber  读写数量
 always@(negedge i2c_sys_clk or posedge i2c_rst)
 begin
	    if(i2c_rst)
        i2c_rtc_gnumber <= 8'd11;
      else if(rtc_wr_en)
        i2c_rtc_gnumber <= 8'd1;
      else if(!i2c_rtc_mode_en)
        i2c_rtc_gnumber <= 8'd8;
      else 
        i2c_rtc_gnumber <= i2c_rtc_gnumber;
 end 
////////////////////////////////////////////////////////////////////////////////////////////
///(*)温度读完即读RTC，初始化全写一次，URAT操控单写一次 //20MHZ采样时钟
 always@(negedge i2c_sys_clk or posedge i2c_rst)
 begin
	    if(i2c_rst)
        rtc_stat_tmp       <= 1'd0;
      else if(rtc_stat_tmp_dl)
        rtc_stat_tmp       <= 1'd0;
      else if(mif_wrtc_stat)
        rtc_stat_tmp <= 1'd1;
		  else if(!i2c_rtc_mode_en)begin		     
            if(i2c_rd_valid)
              rtc_stat_tmp <= 1'd1;
            else
              rtc_stat_tmp <= rtc_stat_tmp;
		  end
      else if(i2c_int_stat[1] && !i2c_int_stat[0])
		       rtc_stat_tmp <= 1'd1;
		  else
           rtc_stat_tmp <= rtc_stat_tmp;
 end 
 ////////////////////////////////////////////////////////////////////////////////////////////
///(*)读写启动脉冲  //更换RTC时钟采样
 always@(negedge i2c_rtc_clk or posedge i2c_rst)
 begin
	    if(i2c_rst)
        rtc_stat_tmp_dl       <= 1'd0;
      else
        rtc_stat_tmp_dl <= rtc_stat_tmp;
 end
 ////////////////////////////////////////////////////////////////////////////////////////////
///(*)读写启动脉冲
 always@(negedge i2c_rtc_clk or posedge i2c_rst)
 begin
	    if(i2c_rst)
        rtc_stat_pulse       <= 1'd0;
      else if(rtc_stat_tmp && !rtc_stat_tmp_dl)
        rtc_stat_pulse       <= 1'd1;
      else
        rtc_stat_pulse       <= 1'd0; 
 end 
////////////////////////////////////////////////////////////////////////////////////////////
///(*)写状态
 always@(negedge i2c_sys_clk or posedge i2c_rst)
 begin
	    if(i2c_rst)
        i2c_rtc_mode_en <= 1'd1;
      else if(i2c_rtc_wend)
        i2c_rtc_mode_en <= 1'd0;
      else if(mif_wrtc_stat)
        i2c_rtc_mode_en <= 1'd1;
      else if(i2c_int_stat[1] && !i2c_int_stat[0])
       i2c_rtc_mode_en <= 1'd1;
      else
        i2c_rtc_mode_en <= i2c_rtc_mode_en;
 end 
////////////////////////////////////////////////////////////////////////////////////////////
///(*)单写状态
 always@(negedge i2c_sys_clk or posedge i2c_rst)
 begin
	    if(i2c_rst)
        rtc_wr_en <= 1'd0;
      else if(i2c_rtc_wend)
        rtc_wr_en <= 1'd0;
      else if(mif_wrtc_stat)
        rtc_wr_en <= 1'd1;
      else
        rtc_wr_en <= rtc_wr_en;
 end  
////////////////////////////////////////////////////////////////////////////////
///(*)读数据组合
 always@(posedge i2c_rtc_clk or posedge i2c_rst)
 begin
	    if(i2c_rst)
        rtc_rd_cnt <= 4'd0;
      else if(rtc_rd_cnt == 4'd4 || rtc_stat_pulse)
        rtc_rd_cnt <= 4'd0;
      else if(i2c_rtc_rd_valid)
        rtc_rd_cnt <= rtc_rd_cnt + 1'd1;
      else
        rtc_rd_cnt <= rtc_rd_cnt;
 end
////////////////////////////////////////////////////////////////////////////////
///(*)data_sw_en
 always@(posedge i2c_rtc_clk or posedge i2c_rst)
 begin
	    if(i2c_rst)
        data_sw <= 2'd0;
      else if(data_sw == 2'd2)
        data_sw <= 2'd0;
      else if(rtc_rd_cnt == 4'd4)
        data_sw <= data_sw + 1'd1;
      else
        data_sw <= data_sw;
 end
////////////////////////////////////////////////////////////////////////////////////////////
///(*)读数据
 always@(posedge i2c_sys_clk or posedge i2c_rst)
 begin
	    if(i2c_rst)
        i2c_rtc_red_data1 <= 32'd0;
    //  else if(!i2c_rtc_mode_en && i2c_rtc_rd_valid && data_sw < 2'd1)begin      
      else if(!i2c_rtc_mode_en && i2c_rtc_rd_valid)begin   
      	     case(rtc_rd_cnt)
      	      7'd0:i2c_rtc_red_data1 <= {i2c_rtc_red_data1[31:8],i2c_rtc_out_data};
              7'd1:i2c_rtc_red_data1 <= {i2c_rtc_red_data1[31:16],i2c_rtc_out_data,i2c_rtc_red_data1[7:0]};
              7'd2:i2c_rtc_red_data1 <= {i2c_rtc_red_data1[31:24],i2c_rtc_out_data,i2c_rtc_red_data1[15:0]};
              7'd3:i2c_rtc_red_data1 <= {i2c_rtc_out_data,i2c_rtc_red_data1[23:0]};
              default: i2c_rtc_red_data1 <= i2c_rtc_red_data1;
             endcase
		 end
      else
       i2c_rtc_red_data1 <= i2c_rtc_red_data1;
 end 
//////////////////////////////////////////////////////////////////////////////////////////////
/////(*)读数据
// always@(negedge i2c_sys_clk or posedge i2c_rst)
// begin
//	    if(i2c_rst)
//        i2c_rtc_red_data2 <= 32'd0;
//      else if(!i2c_rtc_mode_en && i2c_rtc_rd_valid && data_sw > 2'd0)begin
//      	     case(rtc_rd_cnt)
//      	      7'd0:i2c_rtc_red_data2 <= {i2c_rtc_red_data2[31:8],i2c_rtc_out_data};
//              7'd1:i2c_rtc_red_data2 <= {i2c_rtc_red_data2[31:16],i2c_rtc_out_data,i2c_rtc_red_data2[7:0]};
//              7'd2:i2c_rtc_red_data2 <= {i2c_rtc_red_data2[31:24],i2c_rtc_out_data,i2c_rtc_red_data2[15:0]};
//              7'd3:i2c_rtc_red_data2 <= {i2c_rtc_out_data,i2c_rtc_red_data2[23:0]};
//              default: i2c_rtc_red_data2 <= i2c_rtc_red_data2;
//             endcase
//      end
//      else
//       i2c_rtc_red_data2 <= i2c_rtc_red_data2;
// end 
////////////////////////////////////////////////////////////////////////////////////////////
///(*)data valid
 always@(negedge i2c_sys_clk or posedge i2c_rst)
 begin
	    if(i2c_rst)
        i2c_rtc_valid <= 1'd0;
      else if(!i2c_rtc_mode_en && rtc_rd_cnt == 7'd4)
        i2c_rtc_valid <= 1'd1;
      else
        i2c_rtc_valid <= 1'd0;
 end
// RTC
always@(negedge i2c_sys_clk or posedge i2c_rst)
begin
  if (i2c_rst)   begin
    rtc_data_in[15:0]               <= 16'd0;
  end
  else if(rtc_wr_en && i2c_rtc_mode_en)begin
      rtc_data_in[15:0]     <= mif_wrtc_data_in[15:0];
  end  
  else if(!i2c_rtc_mode_en)begin
    case(rtc_count)   
	   7'd0:rtc_data_in[15:0]     <= {8'b00000110,8'd0};
	   7'd1:rtc_data_in[15:0]     <= {8'b00000101,8'd0};
	   7'd2:rtc_data_in[15:0]     <= {8'b00000100,8'd0};
	   7'd3:rtc_data_in[15:0]     <= {8'b00000011,8'd0};
	   7'd4:rtc_data_in[15:0]     <= {8'b00000010,8'd0};
	   7'd5:rtc_data_in[15:0]     <= {8'b00000001,8'd0};
	   7'd6:rtc_data_in[15:0]     <= {8'b00000000,8'd0};	   
	   7'd7:rtc_data_in[15:0]     <= {8'b00000111,8'd0};	 	   
	   default: rtc_data_in[15:0] <= {8'b00000000,8'd0}; 
	  endcase
	end  
  else if(i2c_rtc_mode_en)  begin
    case(rtc_count)   
	   7'd0 : rtc_data_in[15:0] <= {8'b00000000,8'h91}; 
	   7'd1 : rtc_data_in[15:0] <= {8'b00000000,8'h11}; 
	   7'd2 : rtc_data_in[15:0] <= {8'b00000001,8'h11}; 
	   7'd3 : rtc_data_in[15:0] <= {8'b00000010,8'h11}; 
	   7'd4 : rtc_data_in[15:0] <= {8'b00000011,8'h06}; 
	   7'd5 : rtc_data_in[15:0] <= {8'b00000100,8'h16};
	   7'd6 : rtc_data_in[15:0] <= {8'b00000101,8'h11};
	   7'd7 : rtc_data_in[15:0] <= {8'b00000110,8'h15};
	   7'd8 : rtc_data_in[15:0] <= {8'b00000111,8'hc0};
	   7'd9 : rtc_data_in[15:0] <= {8'b00001000,8'h00}; 
	   7'd10: rtc_data_in[15:0] <= {8'b00001001,8'h00};    	   
     default: rtc_data_in[7:0] <= 8'b00000000; 			
    endcase
  end
end 



 ////////////////////////////////////////////////////////////////////////////////////////////
///(*)
     assign   debug_signal   = {2'd0,
                                i2c_clk_dvi2,
                                i2c_mode_en,
                                i2c_stat_pulse,
                                i2c_0_scl_out,
                                i2c_clk_out,
                                i2c_0_rd_valid,
                                i2c_0_out_data,
                                i2c_clk,
                                i2c_1_out_data,
                                i2c_1_rd_valid,
                                mif_wrtc_stat,
                                i2c_rx_io,
                                i2c_rd_valid,    
                                //-------------
                                rtc_i2c_scl,
                                i2c_tx_io,
                                i2c_rtc_rd_valid,
                                i2c_rtc_out_data,
                                i2c_rtc_clk, 
                                rtc_rd_cnt                                                                                                                                                         
                                };


















//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
endmodule



