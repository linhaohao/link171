////////////////////////////////////////////////////////////////////////////////
// Company: StarPoint
// Engineer: guanzheye
//
// Create Date: 
// Design Name: rf_cfg_top
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

module rf_cfg_top(
// clock & Reset
input                    sys_clk,                    
input                    sys_rest,    
input                    spi_clk,
//-- 
input [2:0]              rf_cfg_select_mode,
input                    initial_startus_en,    //  1 = initial ,  0 = initial end;

input                    spi_rd_stat,
input                    spi_rd_en,
//--
input                    rf_cfg_start,
input [31:0]             rf_cfg_wr_data,
input                    rf_cfg_wr_en,
input                    rf_cfg_valid,
input [7:0]              rf_cfg_addr,

//--
output reg [31:0]        rf_cfg_rd_data,  
output reg               rf_cfg_rd_valid,
//--spi  
input                    spi_single_en   ,  //4351不支持回读，8332不支持写操作。暂不启用此操作。2015/9/29 17:04:43



input                    adf4351_spi_start ,  
input                    ads8332_spi_start ,
output reg               rf_spi_clk,
output reg               rf_spi_cs,
output reg               rf_spi_sdi,
input                    rf_spi_sdo,
output [3:0]             cpld_select_mode,
//debug
output [127:0]           debug_signal



);
//////////////////////////////////////////////////////////////////////////////////
//// signal declaration ////
wire [63:0] adf_debug;         
wire [31:0] ads_rd_parameter;
wire        ads_out_valid;          
wire [31:0] adf_rd_parameter;    
wire        adf_out_valid;       
wire        spi_all_end;                                  
                                  
reg                adf_start        ;                               
reg [31:0]         adf_in_data      ;                               
reg                adf_data_valid   ;                               
reg                adf_wr_en        ;                               
reg [7:0]          adf_cfg_rddr     ;   
reg                adf_spi_sdo      ;
//-------------                                                         
reg                ads_start        ;                               
reg [31:0]         ads_in_data      ;                               
reg                ads_data_valid   ;                               
reg                ads_wr_en        ;                               
reg [7:0]          ads_cfg_rddr     ;   
reg                ads_spi_sdo      ;
//             
reg                adf4351_spi_start_reg;
reg                ads8332_spi_start_reg;

reg [6:0]          spi_number;


wire               adf_spi_cs;
wire               adf_spi_sdi;
wire               ads_spi_cs;
wire               ads_spi_sdi;




//////////////////////////////////////////////////////////////////////////////////
//// parameter ////




//////////////////////////////////////////////////////////////////////////////////
//// signal assignment ////  
  
     assign cpld_select_mode = 4'd0;
  
////////////////////////////////////////////////////////////////////////////////////
////// (*) SPI操作次数，
//always@(posedge cfg_spi_clk )
//begin
//	    if(spi_single_en && adf4351_spi_start)
//         spi_number <= 6'd1;
//      else if(adf4351_spi_start || spi_rd_stat)
//         spi_number <= 6'd29;
//      else
//         spi_number <= spi_number;
//end 

//////////////////////////////////////////////////////////////////////////////////
////(*1) SPI stat select ////
always@(posedge spi_clk )
begin
    if(adf4351_spi_start || spi_rd_stat)      
      adf4351_spi_start_reg <= 1'd1;
    else
      adf4351_spi_start_reg <= 1'd0;
end     
//////////////////////////////////////////////////////////////////////////////////
////(*2) SPI stat select ////
always@(posedge spi_clk )
begin
    if(ads8332_spi_start || (spi_rd_en && spi_all_end))    
      ads8332_spi_start_reg <= 1'd1;
    else
      ads8332_spi_start_reg <= 1'd0;
end   
  
  
  
  
  
  

//////////////////////////////////////////////////////////////////////////////////
//// (0) red  write  select  adf4351 or   ads8332 ////
always@(posedge spi_clk or posedge sys_rest)
begin
	if(sys_rest)begin

     adf_in_data          <= 32'd0;
     adf_data_valid       <= 1'd0;
     adf_wr_en            <= 1'd0;
     adf_cfg_rddr         <= 8'd0;
     //======

     ads_in_data          <= 32'd0;
     ads_data_valid  		  <= 1'd0; 
     ads_wr_en       		  <= 1'd0; 
     ads_cfg_rddr         <= 8'd0; 
     //     
     rf_cfg_rd_data       <= 32'd0;
     rf_cfg_rd_valid      <= 1'd0;
  end
  else if(rf_cfg_select_mode == 3'd0)begin     
 
  	 adf_in_data          <= rf_cfg_wr_data; 
     adf_data_valid       <= rf_cfg_valid;  
     adf_wr_en            <= rf_cfg_wr_en;  
     adf_cfg_rddr         <= rf_cfg_addr;  
     rf_cfg_rd_data       <= adf_rd_parameter ; 
     rf_cfg_rd_valid      <= adf_out_valid;
  end
  else if(rf_cfg_select_mode == 3'd1)begin                     
      
     ads_in_data          <= rf_cfg_wr_data;    
     ads_data_valid  		  <= rf_cfg_valid;      
     ads_wr_en       		  <= rf_cfg_wr_en;      
     ads_cfg_rddr         <= rf_cfg_addr;                                     
     rf_cfg_rd_data       <= ads_rd_parameter ; 
     rf_cfg_rd_valid      <= ads_out_valid;
  end
  else begin
     	                              
     adf_in_data          <= 32'd0;                                     
     adf_data_valid       <= 1'd0;                                      
     adf_wr_en            <= 1'd0;                                      
     adf_cfg_rddr         <= 8'd0;                                      
     //======                                                           
                                     
     ads_in_data          <= 32'd0;                                     
     ads_data_valid  		  <= 1'd0;                                     
     ads_wr_en       		  <= 1'd0;                                     
     ads_cfg_rddr         <= 8'd0;                                      
     //                                                                 
     rf_cfg_rd_data       <= 32'd0;    
     rf_cfg_rd_valid      <= 1'd0; 
  end
end                                  
                                   
//////////////////////////////////////////////////////////////////////////////////
//// (1)SPI select  adf4351 or   ads8332 ////
always@(rf_cfg_select_mode)
begin
	if(rf_cfg_select_mode == 3'd0)begin
	    rf_spi_clk     =  spi_clk ;
	    rf_spi_cs      =  adf_spi_cs  ;
	    rf_spi_sdi     =  adf_spi_sdi ;
	    adf_spi_sdo    =  rf_spi_sdo ;
	    ads_spi_sdo    =  1'd0 ;
	end
	else if(rf_cfg_select_mode == 3'd1)begin   
	    rf_spi_clk     =  ~spi_clk ;        
	    rf_spi_cs      =  ads_spi_cs  ;  
	    rf_spi_sdi     =  ads_spi_sdi ;  
	    adf_spi_sdo    =  1'd0 ;                                   
	    ads_spi_sdo    =  rf_spi_sdo ;   
	end             
	else begin  
		  rf_spi_clk     =  1'd0 ;   
		  rf_spi_cs      =  1'd0 ;   
		  rf_spi_sdi     =  1'd0 ;   
		  adf_spi_sdo    =  1'd0 ; 
		  ads_spi_sdo    =  1'd0 ;
	end
end
		  
	                                
                                   
//////////////////////////////////////////////////////////////////////////////////
//// (2) ADF5351 ////
adf4351_cfg   u0_adf4351_cfg(
                .sys_rest                    (sys_rest         ),    
                .spi_clk                    (spi_clk         ),    
                .spi_all_end                (spi_all_end     ),   
                                                          
                .adf_in_data                (adf_in_data     ),
                .adf_data_valid             (adf_data_valid  ),
                .adf_wr_en                  (adf_wr_en       ),
                .adf_cfg_rddr               (adf_cfg_rddr    ),
                .adf_rd_parameter           (adf_rd_parameter),
                .adf_out_valid              (adf_out_valid)   ,   
                
                .adf4351_spi_start          (adf4351_spi_start_reg  ),                                                                                                                     
                .adf_spi_clk                (adf_spi_clk     ),                        // < 10MHz    
                .adf_spi_cs                 (adf_spi_cs      ),                                       
                .adf_spi_sdi                (adf_spi_sdi     ),
                .adf_spi_sdo                (adf_spi_sdo     ),
                                                             
                .adf_debug                  (adf_debug       )
                                                   
                );
                

//////////////////////////////////////////////////////////////////////////////////
//// (3) ADS8332    monitoring////
ads8332_cfg   u0_ads8332_cfg(
                .sys_rest                    (sys_rest         ),    
                .spi_clk                    (spi_clk         ),    
                                                                                                            
                .ads_in_data                (ads_in_data     ),  
                .ads_data_valid             (ads_data_valid  ),
                .ads_wr_en                  (ads_wr_en       ),
                .ads_cfg_rddr               (ads_cfg_rddr    ),
                .ads_rd_parameter           (ads_rd_parameter),
                .ads_out_valid              (ads_out_valid   ),
                                                             
                .ads8332_spi_start          (ads8332_spi_start_reg  ), 
                .ads_spi_clk                (ads_spi_clk     ),                        // < 10MHz    
                .ads_spi_cs                 (ads_spi_cs      ),                                       
                .ads_spi_sdi                (ads_spi_sdi     ),
                .ads_spi_sdo                (ads_spi_sdo     ),
                                                             
                .ads_debug                  (ads_debug       )
                                                   
                );


//////////////////////////////////////////////////////////////////////////////////
//// debug signal ////
assign  debug_signal[32:0]    = adf_debug;




//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
endmodule






































