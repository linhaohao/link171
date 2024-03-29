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
//    完成DA 上电初始配置，跳频时根据提供图案进行DA SPI写操作。
//    支持定时读操作。
////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps


module dac_cfg(
// Clock & Reset    
input               cfg_spi_clk,	
input               dac_sync_clk,
input               cfg_rst_in,

input               mif_dac_spi_red,
//--------
input               time_frame_stat,
input [31:0]        time_frame_data,      
//------
output reg [2:0]        dac_profile_sel,        
//----------------------
input               spi_rd_stat,
input               spi_rd_en,
// DAC SPI interface 	 
input               dac_spi_start,
output              dac_spi_clk,
output              dac_spi_cs,	 
output              dac_spi_sdi,	 
input               dac_spi_sdo,	
output  reg         dac_io_updte,

// mcbsp register controlled by DSP      2015/9/7 10:11:04

input               spi_single_en   , 
input               dac_cfg_valid    ,
input [7:0]         dac_cfg_addr     ,  
input [31:0]        dac_cfg_data     ,   
output reg[31:0]    dac_rd_parameter,   
output reg          dac_rd_valid    ,
// debug

output               dac_spi_end ,// 
//input [31:0]         dac_rom_data ,
//input                mif_dac_rom_mode,

input [31:0]       mif_dac_ioup_time,


input              dac_stat,
output[63:0]       debug_signal

	 );

//////////////////////////////////////////////////////////////////////////////////
//// parameter ////
parameter NUMBER        = 7'd3;    
parameter CS_LENGTH     = 7'd40; 

//////////////////////////////////////////////////////////////////////////////////
//// Signal declration ////
reg [6:0]           spi_number;
reg                 spi_wr_en;
reg                 spi_stat;
reg                 dac_cfg_rd_en = 1'd0;
wire[6:0]           dac9957_count;
wire[31:0]          dac_spi_data_out;
wire                dac_spi_data_valid;
wire                dac9957_rst_ctl;
wire                dac_io_updte_reg;
//--------------------------------------------
wire                frame_end;
wire                frame_clk;
wire                frame_cs ;
wire                frame_sdi;       
reg                 spi_select_en;

wire                dac_spi_clk_reg;
wire                dac_spi_cs_reg ;
wire                dac_spi_sdi_reg;
//----------------------------------------------
reg [31:0]          frame_spi_data;
reg                 frame_spi_stat;
reg                 frame_int_en;
reg [2:0]           frame_int_cnt;

reg [2:0]           dac_ioupdata_dl;
reg [7:0]           dac_ioupdata_cnt;
reg                 dac_ioupdata_en;
reg                 dac_ioupdata_spi;

reg                 dac_io_updte_puls ; 
reg                 dac_io_updte_puls_dl ; 
//dac9957 configuration register(7)
reg [39:0]          dac9957_data_reg;
reg [31:0]          dac9957_cfg_reg0 = 32'd0;
reg [31:0]          dac9957_cfg_reg1 = 32'd0;
reg [31:0]          dac9957_cfg_reg2 = 32'd0;


wire                spi_all_end;

//// DAC(dac9957) register ////(8bits (wr(1)address(7)) + 32bits data) 
//parameter           dac9957_data_reg0      = 32'h00202002;
parameter           dac9957_data_reg0      = 32'h00602002;
parameter           dac9957_data_reg1      = 32'h00400820;
parameter           dac9957_data_reg2      = 32'h0f3fc000;





//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//// Signal assignment ////
//    assign  dac_profile_sel     = 3'd0;
    assign  dac9957_rst_ctl     = cfg_rst_in;    
//    assign  dac_io_updte        = spi_select_en ? frame_end : dac_io_updte_reg;      
    assign  dac_spi_clk         = spi_select_en ? frame_clk : dac_spi_clk_reg;
    assign  dac_spi_cs          = spi_select_en ? frame_cs  : dac_spi_cs_reg;
    assign  dac_spi_sdi         = spi_select_en ? frame_sdi : dac_spi_sdi_reg;       
    assign  dac_spi_end        =   frame_end;
//////////////////////////////////////////////////////////////////////////////////


//-------------------------------------------------------------------------------
//IO UPDATA
always@(posedge cfg_spi_clk or posedge cfg_rst_in)
begin
    if(cfg_rst_in)
         dac_ioupdata_en <= 1'd0;
     else if(dac_ioupdata_cnt == mif_dac_ioup_time[7:0])
         dac_ioupdata_en <= 1'd0;
     else if(frame_end || dac_io_updte_reg)
         dac_ioupdata_en <= 1'd1;
     else
         dac_ioupdata_en <= dac_ioupdata_en;
     end
//-------------------------------------------------------------------------------
//IO UPDATA
always@(posedge cfg_spi_clk or posedge cfg_rst_in)
begin
    if(cfg_rst_in)
         dac_ioupdata_cnt <= 8'd0;
     else if(dac_ioupdata_en)
         dac_ioupdata_cnt <= dac_ioupdata_cnt + 1'd1;
     else 
         dac_ioupdata_cnt <= 8'd0; 
     end
//-------------------------------------------------------------------------------
//IO UPDATA
always@(posedge cfg_spi_clk or posedge cfg_rst_in)
begin
    if(cfg_rst_in)
         dac_ioupdata_spi <= 1'd0;
    else if(dac_ioupdata_en && dac_ioupdata_cnt == mif_dac_ioup_time[7:0])
         dac_ioupdata_spi <= 1'd1;
     else 
         dac_ioupdata_spi <= 1'd0;
     end

//-------------------------------------------------------------------------------
//IO UPDATA
always@(posedge dac_sync_clk or posedge cfg_rst_in)
begin
    if(cfg_rst_in)
         dac_ioupdata_dl <= 3'd0;
     else
         dac_ioupdata_dl <= {dac_ioupdata_dl[1:0],dac_ioupdata_spi};
     end
////-------------------------------------------------------------------------------
////IO UPDATA
always@(posedge dac_sync_clk or posedge cfg_rst_in)
begin
    if(cfg_rst_in)
         dac_io_updte_puls <= 1'd0;
     else if(dac_io_updte_puls_dl)
         dac_io_updte_puls <= 1'd0;
     else if(dac_ioupdata_dl[2:1] == 2'b01)
         dac_io_updte_puls <= 1'd1;
     else 
         dac_io_updte_puls <= dac_io_updte_puls;
     end 
////-------------------------------------------------------------------------------
////IO DL
always@(posedge dac_sync_clk or posedge cfg_rst_in)
begin
    if(cfg_rst_in)
         dac_io_updte_puls_dl <= 1'd0;
     else
         dac_io_updte_puls_dl <= dac_io_updte_puls; 
     end     
//-------------------------------------------------------------------------------
//IO UPDATA  使用DAC同步时钟更新UP DATA
//-------------------------------------------------------------------------------
always@(posedge dac_sync_clk or posedge cfg_rst_in)      
begin 
	    if(cfg_rst_in)
	      dac_io_updte <= 1'd0;
	    else if(dac_io_updte_puls)                             
	      dac_io_updte <= 1'd0;           
	    else   
	      dac_io_updte <= 1'd0;                            
end
//////////////////////////////////////////////////////////////////////////////////
//// (*) SPI操作次数，
always@(negedge cfg_spi_clk or posedge cfg_rst_in)
begin
	    if(cfg_rst_in)
	      spi_number <= 7'd0; 
	    else if(spi_single_en && dac_spi_start)
         spi_number <= 7'd1;
      else if(dac_stat || (mif_dac_spi_red && spi_rd_stat))
         spi_number <= 7'd3;
      else
         spi_number <= spi_number;
end
//////////////////////////////////////////////////////////////////////////////////
//// (*) 单写使能
always@(negedge cfg_spi_clk or posedge cfg_rst_in )
begin
	    if(cfg_rst_in)
	       spi_wr_en <= 1'd0; 	
	    else if(spi_single_en && dac_spi_start)
         spi_wr_en <= 1'd1;
      else if(dac_io_updte_reg)
         spi_wr_en <= 1'd0;
      else
         spi_wr_en <= spi_wr_en;
end  
//////////////////////////////////////////////////////////////////////////////////
////(0) SPI OUT SELECT ////
always@(negedge cfg_spi_clk or posedge cfg_rst_in)
begin
	  if(cfg_rst_in)
	    spi_select_en <= 1'd0;
	  else if(frame_end)
	    spi_select_en <= 1'd0;
    else if(frame_spi_stat)
      spi_select_en <= 1'd1;
    else
      spi_select_en <= spi_select_en;
end
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
////(1) SPI stat select   公用一组SPI总线，帧定时配置优先级高    ////
always@(negedge cfg_spi_clk )
begin
	  if(spi_select_en)
	    spi_stat <= 1'd0;
 //  else if(dac_spi_start||dac_stat)
   else if(mif_dac_spi_red && spi_rd_stat)
      spi_stat <= 1'd1;
   else if(dac_spi_start||dac_stat)
      spi_stat <= 1'd1;
    else
      spi_stat <= 1'd0;
end
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
////(2) SPI w   r   select ////
always@(negedge cfg_spi_clk  or posedge cfg_rst_in)
begin
    if(cfg_rst_in)
       dac_cfg_rd_en <= 1'd0;
	  else if(mif_dac_spi_red && spi_rd_stat)
	    dac_cfg_rd_en <= 1'd1;
  //  else if(dac_spi_start)      
  // else if(dac_spi_start || dac_stat) 
   else if(dac_spi_start || dac_stat ||time_frame_stat) 
      dac_cfg_rd_en <= 1'd0;
    else
      dac_cfg_rd_en <= dac_cfg_rd_en;
end
//////////////////////////////////////////////////////////////////////////////////
//// (*) spi red
always@(negedge cfg_spi_clk )
begin

  if(dac_spi_data_valid)begin
  	dac_rd_valid     = 1'd1;
    dac_rd_parameter = dac_spi_data_out;  
  end
  else begin
  	dac_rd_valid     = 1'd0;
    dac_rd_parameter = 32'd0; 
  end  	
end

//////////////////////////////////////////////////////////////////////////////////
//// (2) DAC(dac9957) SPI configuration ////
//DAC_spi_top   U2_DAC_dac9957 
jft_spi   U1_dac_cfg_spi 
    (
	 .spi_clk_in        (cfg_spi_clk           ),
	 .spi_rst_in        (dac9957_rst_ctl       ),
	 .spi_start         (spi_stat              ),   //可以控制一下复位后加载时间
	 .spi_wr            (dac_cfg_rd_en          ),
	 .spi_end           (dac_io_updte_reg      ),   
//	 .microwire_mode    (1'd0),
   .spi_all_end       (spi_all_end           ),

	 .spi_start_number  (spi_number            ),
	 .spi_cs_length     (CS_LENGTH             ),
	 .spi_data_in       (dac9957_data_reg[39:0]),
	 
   .spi_clk           (dac_spi_clk_reg       ),	 
   .spi_cs            (dac_spi_cs_reg        ),	 
   .spi_sdi           (dac_spi_sdi_reg       ),	 
   .spi_sdo           (dac_spi_sdo           ),	
   
   .spi_data_out      (dac_spi_data_out      ),
   .spi_data_valid    (dac_spi_data_valid    ),	 
   
	 .spi_count_starte   (dac9957_count[6:0]),
	 .debug_signal()	 	 
	 );

// DAC-dac9957 cfg register
always@(negedge cfg_spi_clk or posedge dac9957_rst_ctl)
begin
  if (dac9957_rst_ctl)   begin
    dac9957_data_reg[39:0]               <= 40'd0;
  end
  else if(spi_rd_en)begin
    case(dac9957_count[6:0])   
	   7'd0:dac9957_data_reg[39:0]     <= {8'h80,32'd0};
	   7'd1:dac9957_data_reg[39:0]     <= {8'h81,32'd0};
	   7'd2:dac9957_data_reg[39:0]     <= {8'h82,32'd0};
	   default: dac9957_data_reg[39:0] <= {8'h80,32'd0}; 
	  endcase
	end
	else if(spi_wr_en && dac_cfg_valid) //URAT|DSP写数据                                  
     dac9957_data_reg[39:0] <= {dac_cfg_addr[7:0],dac_cfg_data[31:0]} ; 
  else   begin
    case(dac9957_count[6:0])   
	   7'd0:   begin
		  dac9957_data_reg[39:0]  <= {8'd0,dac9957_data_reg0[31:0]};
		end
	   7'd1:   begin
		  dac9957_data_reg[39:0]  <= {8'd1,dac9957_data_reg1[31:0]};
		end
	   7'd2:   begin
		  dac9957_data_reg[39:0]  <= {8'd2,dac9957_data_reg2[31:0]};
		end
	   default:   begin
		  dac9957_data_reg[39:0]  <= 40'd0;
		end				
    endcase
  end
end 

////////////////////////////////////////////////////////////////////////////////////
////// (*) spi red
//always@(negedge cfg_spi_clk or posedge cfg_rst_in)
//begin
//	 if(cfg_rst_in)
//	   frame_int_cnt <= 3'd0;	  
//	 else if(frame_int_en)
//	   frame_int_cnt <= 3'd0;	
//   else if(dac_io_updte_reg)
//     frame_int_cnt <= frame_int_cnt + 3'd1;
//   else 
//     frame_int_cnt <= frame_int_cnt;
//end


//////////////////////////////////////////////////////////////////////////////////
//// (*) 初始化DAC跳频配置
always@(negedge cfg_spi_clk or posedge cfg_rst_in)
begin
	 if(cfg_rst_in)
	   frame_int_en <= 1'd1;
	 else if(frame_spi_stat)
	   frame_int_en <= 1'd0;
	 else
	   frame_int_en <= frame_int_en;
end
//////////////////////////////////////////////////////////////////////////////////
//// (*)
always@(negedge cfg_spi_clk or posedge cfg_rst_in)
begin
  if(cfg_rst_in)
  	frame_spi_stat  <= 1'd0;
  else if(frame_int_en && spi_all_end)
    frame_spi_stat  <= 1'd1;
  else if(time_frame_stat)
    frame_spi_stat  <= 1'd1;
  else
    frame_spi_stat  <= 1'd0;
end
//////////////////////////////////////////////////////////////////////////////////
//// (*) spi red
always@(negedge cfg_spi_clk or posedge cfg_rst_in)
begin
  if(cfg_rst_in)
  	frame_spi_data  <= 32'd0;
   else if(frame_int_en && spi_all_end)
//    frame_spi_data  <= 32'h14CCCCCC;//公式：fout=(fclk * FTW)/(2^N),fclk=800mhz,N=32
//    frame_spi_data  <= 32'h30000000;//配置DAC的输出频率为150Mhz
	 frame_spi_data  <= 32'h10000000;//配置DAC的输出频率为50Mhz
   else if(time_frame_stat)
    frame_spi_data  <= time_frame_data;
  else
    frame_spi_data  <= frame_spi_data;	
end


//////////////////////////////////////////////////////////////////////////////////
//// () 6.64us 发72bit ////frame
always@(negedge cfg_spi_clk  or posedge cfg_rst_in)
begin
    if(cfg_rst_in)
       dac_profile_sel <= 3'd1;
	  else if(frame_end)
	    dac_profile_sel <= 3'd0;
    else
      dac_profile_sel <= dac_profile_sel;
end

dac_spi  U2_dac_frame_spi(
// clk/rst
    .clk_20mhz_in      (cfg_spi_clk) , 
    .spi_rst_in        (cfg_rst_in),
    .spi_start         (frame_spi_stat),
    .spi_data_in       ({40'h0E20f00000,frame_spi_data}),
    .spi_end           (frame_end),
    .spi_clk           (frame_clk),
    .spi_cs            (frame_cs ),	 
    .spi_sdi           (frame_sdi),	 
    .spi_sdo           (),	
    .debug_signal	     ()

);





















//////////////////////////////////////////////////////////////////////////////////
//// debug signal ////
assign  debug_signal[63]   = dac_sync_clk;
assign  debug_signal[62]   = spi_stat;
assign  debug_signal[61]   = frame_end;
assign  debug_signal[60]   = frame_cs;
assign  debug_signal[59]   = frame_sdi;
assign  debug_signal[58:56]   = dac_ioupdata_dl;
assign  debug_signal[55]   = dac_ioupdata_spi;
assign  debug_signal[54]   = dac_ioupdata_en;
assign  debug_signal[53:46]   = dac_ioupdata_cnt[7:0];
assign  debug_signal[45]   = frame_spi_stat;
assign  debug_signal[44]   = dac_io_updte;
assign  debug_signal[43:41]   = dac_profile_sel;



//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
endmodule
