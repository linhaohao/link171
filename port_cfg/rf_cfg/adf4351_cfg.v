////////////////////////////////////////////////////////////////////////////////
// Company: StarPoint
// Engineer: guanzheye
//
// Create Date: 
// Design Name: 
// Module Name: 
// Target Device: FPGA XC7K325T-2FFG900 
// Tool versions: ISE 14.6
// Description:
//             
// Revision:   v1.0 - File Created
// Additional Comments:
//    
////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

module adf4351_cfg(
//-- clk rst
input                          sys_rest,      
input                          spi_clk,     
//---------------------------------------------------                              
input[31:0]                    adf_in_data        ,
input                          adf_data_valid    ,
input                          adf_wr_en          ,
input [7:0]                    adf_cfg_rddr       ,
output [31:0]                  adf_rd_parameter   ,
output                         adf_out_valid      ,
output wire                    spi_all_end       ,
//------spi   --------------------------------------
input                          adf4351_spi_start ,                                      
output  wire                   adf_spi_clk  ,
output  wire                   adf_spi_cs   ,
output  wire                   adf_spi_sdi  ,
input   wire                   adf_spi_sdo  ,
//------debug   -----------------------------------                                   
output [63:0]                  adf_debug    

);

//////////////////////////////////////////////////////////////////////////////////
//// signal declaration ////
reg [31:0]          adf4351_reg;
reg [31:0]          adf4351_reg0;// = 32'h00648C80;  //2011M
reg [31:0]          adf4351_reg1;// = 32'h0800fd01;                              
reg [31:0]          adf4351_reg2;// = 32'h1A004E42;
reg [31:0]          adf4351_reg3;// = 32'h000004B3;
reg [31:0]          adf4351_reg4;// = 32'h009A003C;
reg [31:0]          adf4351_reg5;// = 32'h00580005;

wire [6:0]          adf4351_count;
wire [31:0]         spi_data_out;
wire                spi_data_valid;

reg [6:0]           spi_number;



//////////////////////////////////////////////////////////////////////////////////
//// parameter ////
parameter CS_LENGTH = 7'd32;
 


//////////////////////////////////////////////////////////////////////////////////
//// (0) signal assignment ////
         assign   adf_rd_parameter = spi_data_out;
         assign   adf_out_valid    = spi_data_valid;








//////////////////////////////////////////////////////////////////////////////////
//// (0) adf4351 register mapping ///
always@(posedge spi_clk or posedge sys_rest)
begin
  if (sys_rest)   begin
	 adf4351_reg[31:0]                   <= 32'd0;
  end
  else   begin
    case(adf4351_count[6:0])
	   7'd0:   begin
		  adf4351_reg[31:0]               <= adf4351_reg5[31:0];
		end
	   7'd1:   begin
		  adf4351_reg[31:0]               <= adf4351_reg4[31:0];
		end
	   7'd2:   begin
		  adf4351_reg[31:0]               <= adf4351_reg3[31:0];
		end
	   7'd3:   begin
		  adf4351_reg[31:0]               <= adf4351_reg2[31:0];
		end
	   7'd4:   begin
		  adf4351_reg[31:0]               <= adf4351_reg1[31:0];
		end
	   7'd5:   begin
		  adf4351_reg[31:0]               <= adf4351_reg0[31:0];
		end
	   default:   begin
		  adf4351_reg[31:0]               <= adf4351_reg5[31:0];
		end		
	 endcase
  end
end

//////////////////////////////////////////////////////////////////////////////////
//// (1) spi ctl //每次都会对6个寄存器重配置，芯片如果支持单次生效这里可以改变。
always@(*)
begin
  if (adf_wr_en)
    spi_number = 7'd1;   //读，每次读一个
  else
    spi_number = 7'd6;   //写，每次写5个。
end

//////////////////////////////////////////////////////////////////////////////////
//// (2) ADF4351 SPI ////
jft_spi   U0_adf4351_spi 
    (
	 .spi_clk_in        (spi_clk),
	 .spi_rst_in        (sys_rest),
	 .spi_start          (adf4351_spi_start),   //可以控制一下复位后加载时间
	 .spi_wr            (adf_wr_en),
	 .spi_end           (),
   .spi_all_end       (spi_all_end ),
	 .spi_start_number  (spi_number),         
	 .spi_cs_length     (CS_LENGTH),
	 .spi_data_in       (adf4351_reg),
	 
   .spi_clk           (adf_spi_clk),	 
   .spi_cs            (adf_spi_cs ),	 
   .spi_sdi           (adf_spi_sdi),	 
   .spi_sdo           (adf_spi_sdo),	
   
   .spi_data_out      (spi_data_out),
   .spi_data_valid    (spi_data_valid),	 
   
	 .spi_count_starte   (adf4351_count[6:0]),
	 .debug_signal()	 	 
	 );

//////////////////////////////////////////////////////////////////////////////////
//// (3) receive register from DSP MCBSP write ////
always@(posedge spi_clk or posedge sys_rest)
begin
  if (sys_rest)   begin
    adf4351_reg0[31:0]                <=   32'h00648C80;
    adf4351_reg1[31:0]                <=   32'h0800fd01;
    adf4351_reg2[31:0]                <=   32'h1A004E42;              
    adf4351_reg3[31:0]                <=   32'h000004B3; 
    adf4351_reg4[31:0]                <=   32'h009A003C; 
    adf4351_reg5[31:0]                <=   32'h00580005; 
  end
  // write register from DSP
  else if (adf_data_valid)   begin
          case(adf_cfg_rddr[7:0])
	         // adf4351 register
		          8'hA0:   begin
		                adf4351_reg0[31:0]    <= adf_in_data[31:0];
		          end
	            8'hA1:   begin
		                adf4351_reg1[31:0]    <= adf_in_data[31:0];		     
		          end			  
	            8'hA2:   begin
		                adf4351_reg2[31:0]    <= adf_in_data[31:0];		     
		          end		
	            8'hA3:   begin
		                adf4351_reg3[31:0]    <= adf_in_data[31:0];		     
		          end		
	            8'hA4:   begin
		                adf4351_reg4[31:0]    <= adf_in_data[31:0];		     
		          end		
	            8'hA5:   begin
		                adf4351_reg5[31:0]    <= adf_in_data[31:0];		     
		          end	
		          default:   begin
		                adf4351_reg0[31:0]    <=   adf4351_reg0[31:0];
                    adf4351_reg1[31:0]    <=   adf4351_reg1[31:0];
                    adf4351_reg2[31:0]    <=   adf4351_reg2[31:0];              
                    adf4351_reg3[31:0]    <=   adf4351_reg3[31:0]; 
                    adf4351_reg4[31:0]    <=   adf4351_reg4[31:0]; 
                    adf4351_reg5[31:0]    <=   adf4351_reg5[31:0]; 		     
		          end		
		      endcase
  end
  else begin
		          adf4351_reg0[31:0]    <=   adf4351_reg0[31:0];
              adf4351_reg1[31:0]    <=   adf4351_reg1[31:0];
              adf4351_reg2[31:0]    <=   adf4351_reg2[31:0];              
              adf4351_reg3[31:0]    <=   adf4351_reg3[31:0]; 
              adf4351_reg4[31:0]    <=   adf4351_reg4[31:0]; 
              adf4351_reg5[31:0]    <=   adf4351_reg5[31:0]; 		   	
  end
end














//////////////////////////////////////////////////////////////////////////////////
//// debug signal ////
assign  adf_debug[32:0]              = {spi_data_valid,spi_data_out};




//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
endmodule
