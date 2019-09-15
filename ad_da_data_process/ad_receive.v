////////////////////////////////////////////////////////////////////////////////
// Company:  StarPoint
// Engineer: <Engineer Name>
//
// Create Date: <date>
// Design Name: <name_of_top-level_design>
// Module Name: <name_of_this_module>
// Target Device: FPGA XC7K325T-2FFG900 
// Tool versions: <tool_versions>
// Description:
//    <Description here>
// Dependencies:
//    <Dependencies here>
// Revision:
//    <Code_revision_information>
// Additional Comments:
//    <Additional_comments>
////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

module ad_receive(
// clk/rst
input                    sys_clk,          //200
input                    sys_rst,
input                    mif_adc_fifo_rst,
input [15:0]             mif_adc_mode,
//-------------cfg  signal----------------
input [1:0]              adc_switch,       //ad         


//-------------ADC0 IN--------------------
input [6:0]              adc0_data_a_p,
input [6:0]              adc0_data_a_n,
input [6:0]              adc0_data_b_p,
input [6:0]              adc0_data_b_n,
input                    adc0_or_p,
input                    adc0_or_n,
// input                    adc0_clkout_p,   //200
// input                    adc0_clkout_n,
input                    adc0_clk,
//-------------ADC1 IN--------------------
input [6:0]              adc1_data_a_p,
input [6:0]              adc1_data_a_n,
input [6:0]              adc1_data_b_p,
input [6:0]              adc1_data_b_n,
input                    adc1_or_p,
input                    adc1_or_n,
// input                    adc1_clkout_p,   //200
// input                    adc1_clkout_n,
input                    adc1_clk,
//-------------ADC OUT--------------------
output reg [15:0]            adc0_data_a_out,
output reg [15:0]            adc0_data_b_out,
output reg [15:0]            adc1_data_a_out,
output reg [15:0]            adc1_data_b_out,
//-------------DEBUG     -----------------
output [199:0]            debug_signal		

);


//////////////////////////////////////////////////////////////////////////////////
//// signal declaration ////

wire [6:0] adc0_data_a;
wire [6:0] adc0_data_b;
wire [6:0] adc1_data_a;
wire [6:0] adc1_data_b;
// wire adc0_clk;
// wire adc1_clk;
wire adc0_or;
wire adc1_or;
wire [6:0] adc0_data_a_even;
wire [6:0] adc0_data_a_odd;
wire [6:0] adc0_data_b_even;
wire [6:0] adc0_data_b_odd;
wire [6:0] adc1_data_a_even;
wire [6:0] adc1_data_a_odd;
wire [6:0] adc1_data_b_even;
wire [6:0] adc1_data_b_odd;


reg [6:0] adc0_data_a_even_reg;
reg [6:0] adc0_data_a_odd_reg;
reg [6:0] adc0_data_b_even_reg;
reg [6:0] adc0_data_b_odd_reg;
reg [6:0] adc1_data_a_even_reg;
reg [6:0] adc1_data_a_odd_reg;
reg [6:0] adc1_data_b_even_reg;
reg [6:0] adc1_data_b_odd_reg;




//fifo
reg  signed[31:0]adc0_fifo_in;
reg  signed[31:0]adc1_fifo_in;

reg        adc0_fifo_wr;
reg        adc1_fifo_wr;

reg        fifo_rst;

wire       adc0_fifo_full;
wire       adc1_fifo_full;
wire       adc0_fifo_empty;
wire       adc1_fifo_empty;
wire [31:0]adc0_fifo_out;
wire [31:0]adc1_fifo_out;

reg signed[15:0] adc0_data_a_reg;
reg signed[15:0] adc0_data_b_reg;
reg signed[15:0] adc1_data_a_reg;
reg signed[15:0] adc1_data_b_reg;

reg signed[15:0] adc0_data_a_reg4;
reg signed[15:0] adc0_data_b_reg4;
reg signed[15:0] adc0_data_a_reg0;
reg signed[15:0] adc0_data_b_reg0;

reg signed[15:0] adc1_data_a_reg4;
reg signed[15:0] adc1_data_b_reg4;
reg signed[15:0] adc1_data_a_reg0;
reg signed[15:0] adc1_data_b_reg0;

//wire [15:0] adc0_data_a_reg;
//wire [15:0] adc0_data_b_reg;
//wire [15:0] adc1_data_a_reg;
//wire [15:0] adc1_data_b_reg;

//////////////////////////////////////////////////////////////////////////////////
//// signal assignment ////
//
//    even  1 3 5 7 9 11 13          
//    odd   0 2 4 6 8 10 12
//    data  13 downto 0    
//////////////////////////////////////////////////////////////////////////////////
//---------------------ADC0   A-----------------------------------
//   // assign  adc0_data_a_reg[15]  = adc0_data_a_odd_reg[6];
//   // assign  adc0_data_a_reg[14]  = adc0_data_a_odd_reg[6];
//	  assign  adc0_data_a_reg[15]  = adc0_data_a_odd_reg[6];   
//	                                    
//    assign  adc0_data_a_reg[13]  = adc0_data_a_odd_reg[5];
//    assign  adc0_data_a_reg[11]  = adc0_data_a_odd_reg[4];
//    assign  adc0_data_a_reg[9]   = adc0_data_a_odd_reg[3];
//    assign  adc0_data_a_reg[7]   = adc0_data_a_odd_reg[2];
//    assign  adc0_data_a_reg[5]   = adc0_data_a_odd_reg[1];
//    assign  adc0_data_a_reg[3]   = adc0_data_a_odd_reg[0];
//    assign  adc0_data_a_reg[1]   = 1'd0;//adc0_data_a_odd_reg[0];
//    
//    assign  adc0_data_a_reg[14]  = adc0_data_a_even_reg[6];	
//    assign  adc0_data_a_reg[12]  = adc0_data_a_even_reg[5];
//    assign  adc0_data_a_reg[10]  = adc0_data_a_even_reg[4];
//    assign  adc0_data_a_reg[8]   = adc0_data_a_even_reg[3];
//    assign  adc0_data_a_reg[6]   = adc0_data_a_even_reg[2];
//    assign  adc0_data_a_reg[4]   = adc0_data_a_even_reg[1];
//    assign  adc0_data_a_reg[2]   = adc0_data_a_even_reg[0];
//    assign  adc0_data_a_reg[0]   = 1'd0;//adc0_data_a_even_reg[0];
////---------------------ADC0   B-----------------------------------
//    assign  adc0_data_b_reg[15]  = adc0_data_b_odd_reg[6];
//    assign  adc0_data_b_reg[14]  = adc0_data_b_even_reg[6];   
//    
//    assign  adc0_data_b_reg[13]  = adc0_data_b_odd_reg[5];
//    assign  adc0_data_b_reg[11]  = adc0_data_b_odd_reg[4];
//    assign  adc0_data_b_reg[9]   = adc0_data_b_odd_reg[3];
//    assign  adc0_data_b_reg[7]   = adc0_data_b_odd_reg[2];
//    assign  adc0_data_b_reg[5]   = adc0_data_b_odd_reg[1];
//    assign  adc0_data_b_reg[3]   = adc0_data_b_odd_reg[0];
//    assign  adc0_data_b_reg[1]   = 1'd0;//adc0_data_b_odd_reg[0];
//                                                      
//    assign  adc0_data_b_reg[12]  = adc0_data_b_even_reg[5]; 
//    assign  adc0_data_b_reg[10]  = adc0_data_b_even_reg[4]; 
//    assign  adc0_data_b_reg[8]   = adc0_data_b_even_reg[3]; 
//    assign  adc0_data_b_reg[6]   = adc0_data_b_even_reg[2]; 
//    assign  adc0_data_b_reg[4]   = adc0_data_b_even_reg[1]; 
//    assign  adc0_data_b_reg[2]   = adc0_data_b_even_reg[0]; 
//    assign  adc0_data_b_reg[0]   = 1'd0;//adc0_data_b_even_reg[0]; 
////---------------------ADC1   A-----------------------------------
//    assign  adc1_data_a_reg[15]  = adc1_data_a_odd_reg[6];
//    assign  adc1_data_a_reg[14]  = adc1_data_a_even_reg[6];
//	                                   
//    assign  adc1_data_a_reg[13]  = adc1_data_a_odd_reg[5]; 
//    assign  adc1_data_a_reg[11]  = adc1_data_a_odd_reg[4]; 
//    assign  adc1_data_a_reg[9]   = adc1_data_a_odd_reg[3]; 
//    assign  adc1_data_a_reg[7]   = adc1_data_a_odd_reg[2]; 
//    assign  adc1_data_a_reg[5]   = adc1_data_a_odd_reg[1]; 
//    assign  adc1_data_a_reg[3]   = adc1_data_a_odd_reg[0]; 
//    assign  adc1_data_a_reg[1]   = 1'd0;//adc1_data_a_odd_reg[0]; 
//                                    
//    assign  adc1_data_a_reg[12]  = adc1_data_a_even_reg[5];
//    assign  adc1_data_a_reg[10]  = adc1_data_a_even_reg[4];
//    assign  adc1_data_a_reg[8]   = adc1_data_a_even_reg[3];
//    assign  adc1_data_a_reg[6]   = adc1_data_a_even_reg[2];
//    assign  adc1_data_a_reg[4]   = adc1_data_a_even_reg[1];
//    assign  adc1_data_a_reg[2]   = adc1_data_a_even_reg[0];
//    assign  adc1_data_a_reg[0]   = 1'd0;//adc1_data_a_even_reg[0];
////---------------------ADC1   B----------------------------------- 
//    assign  adc1_data_b_reg[15]  = adc1_data_b_odd_reg[6]; 
//    assign  adc1_data_b_reg[14]  = adc1_data_b_even_reg[6]; 
//	                                                   
//    assign  adc1_data_b_reg[13]  = adc1_data_b_odd_reg[5]; 
//    assign  adc1_data_b_reg[11]  = adc1_data_b_odd_reg[4]; 
//    assign  adc1_data_b_reg[9]   = adc1_data_b_odd_reg[3]; 
//    assign  adc1_data_b_reg[7]   = adc1_data_b_odd_reg[2]; 
//    assign  adc1_data_b_reg[5]   = adc1_data_b_odd_reg[1]; 
//    assign  adc1_data_b_reg[3]   = adc1_data_b_odd_reg[0]; 
//    assign  adc1_data_b_reg[1]   = 1'd0;//adc1_data_b_odd_reg[0]; 
//                                                     
//    assign  adc1_data_b_reg[12]  = adc1_data_b_even_reg[5];  
//    assign  adc1_data_b_reg[10]  = adc1_data_b_even_reg[4];  
//    assign  adc1_data_b_reg[8]   = adc1_data_b_even_reg[3];  
//    assign  adc1_data_b_reg[6]   = adc1_data_b_even_reg[2];  
//    assign  adc1_data_b_reg[4]   = adc1_data_b_even_reg[1];  
//    assign  adc1_data_b_reg[2]   = adc1_data_b_even_reg[0];  
//    assign  adc1_data_b_reg[0]   = 1'd0;//adc1_data_b_even_reg[0];  
////---------------------ADC   FIFO out---------------------------------     
//    assign  adc0_data_a_out     =  adc0_fifo_out[31:16];
//    assign  adc0_data_b_out     =  adc0_fifo_out[15:0];
//    assign  adc1_data_a_out     =  adc1_fifo_out[31:16];
//    assign  adc1_data_b_out     =  adc1_fifo_out[15:0];    
//---------------------assign   end-----------------------------------                                                                 
//////////////////////////////////////////////////////////////////////////////////
//// IDDR DL
always@(posedge adc0_clk or posedge sys_rst)
begin
     if(sys_rst)begin
        adc0_data_a_even_reg  <= 7'd0; 
        adc0_data_a_odd_reg   <= 7'd0;  
        adc0_data_b_even_reg  <= 7'd0; 
        adc0_data_b_odd_reg   <= 7'd0;  

     end
     else begin
        adc0_data_a_even_reg  <= adc0_data_a_even;        	
        adc0_data_a_odd_reg   <= adc0_data_a_odd;         	
        adc0_data_b_even_reg  <= adc0_data_b_even;        	
        adc0_data_b_odd_reg   <= adc0_data_b_odd;         	 
     end
end  
//////////////////////////////////////////////////////////////////////////////////
//// IDDR DL
always@(posedge adc1_clk or posedge sys_rst)
begin
     if(sys_rst)begin
        adc1_data_a_even_reg  <= 7'd0; 
        adc1_data_a_odd_reg   <= 7'd0;  
        adc1_data_b_even_reg  <= 7'd0; 
        adc1_data_b_odd_reg   <= 7'd0;  
     end
     else begin      	
        adc1_data_a_even_reg  <= adc1_data_a_even;        	
        adc1_data_a_odd_reg   <= adc1_data_a_odd;         	
        adc1_data_b_even_reg  <= adc1_data_b_even;        	
        adc1_data_b_odd_reg   <= adc1_data_b_odd;   
     end
end  
        
//////////////////////////////////////////////////////////////////////////////////
//// mif_adc_mode 
//////////////////////////shift register 2 bit
always@(posedge adc0_clk or posedge sys_rst)
begin
     if(sys_rst)begin
     	 adc0_data_a_reg <= 16'd0;
     	 adc0_data_b_reg <= 16'd0;
     end
     else begin
//---------------------ADC0   A---------------------------------   
	   adc0_data_a_reg[15]  <= adc0_data_a_odd_reg[6];          
	   adc0_data_a_reg[14]  <= adc0_data_a_even_reg[6];	
	                                                         
       adc0_data_a_reg[13]  <= adc0_data_a_odd_reg[5];          
       adc0_data_a_reg[11]  <= adc0_data_a_odd_reg[4];          
       adc0_data_a_reg[9]   <= adc0_data_a_odd_reg[3];          
       adc0_data_a_reg[7]   <= adc0_data_a_odd_reg[2];          
       adc0_data_a_reg[5]   <= adc0_data_a_odd_reg[1];          
       adc0_data_a_reg[3]   <= adc0_data_a_odd_reg[0];          
       adc0_data_a_reg[1]   <= 1'd0;//adc0_data_a_odd_reg[0];   
                                                                   
       adc0_data_a_reg[12]  <= adc0_data_a_even_reg[5];         
       adc0_data_a_reg[10]  <= adc0_data_a_even_reg[4];         
       adc0_data_a_reg[8]   <= adc0_data_a_even_reg[3];         
       adc0_data_a_reg[6]   <= adc0_data_a_even_reg[2];         
       adc0_data_a_reg[4]   <= adc0_data_a_even_reg[1];         
       adc0_data_a_reg[2]   <= adc0_data_a_even_reg[0];         
       adc0_data_a_reg[0]   <= 1'd0;//adc0_data_a_even_reg[0];  
//---------------------ADC0   B---------------------------------
       adc0_data_b_reg[15]  <= adc0_data_b_odd_reg[6];          
       adc0_data_b_reg[14]  <= adc0_data_b_even_reg[6];         
                                                          
       adc0_data_b_reg[13]  <= adc0_data_b_odd_reg[5];          
       adc0_data_b_reg[11]  <= adc0_data_b_odd_reg[4];          
       adc0_data_b_reg[9]   <= adc0_data_b_odd_reg[3];          
       adc0_data_b_reg[7]   <= adc0_data_b_odd_reg[2];          
       adc0_data_b_reg[5]   <= adc0_data_b_odd_reg[1];          
       adc0_data_b_reg[3]   <= adc0_data_b_odd_reg[0];          
       adc0_data_b_reg[1]   <= 1'd0;//adc0_data_b_odd_reg[0];   
                                                           
       adc0_data_b_reg[12]  <= adc0_data_b_even_reg[5];         
       adc0_data_b_reg[10]  <= adc0_data_b_even_reg[4];         
       adc0_data_b_reg[8]   <= adc0_data_b_even_reg[3];         
       adc0_data_b_reg[6]   <= adc0_data_b_even_reg[2];         
       adc0_data_b_reg[4]   <= adc0_data_b_even_reg[1];         
       adc0_data_b_reg[2]   <= adc0_data_b_even_reg[0];         
       adc0_data_b_reg[0]   <= 1'd0;//adc0_data_b_even_reg[0];  
     end
end

//////////////////////////////////////////////////////////////////////////////////
//// mif_adc_mode
always@(posedge adc1_clk or posedge sys_rst)
begin
     if(sys_rst)begin
     	 adc1_data_a_reg <= 16'd0;
     	 adc1_data_b_reg <= 16'd0;
     end
     else begin
//---------------------ADC1   A---------------------------------
       adc1_data_a_reg[15]  <= adc1_data_a_odd_reg[6];          
       adc1_data_a_reg[14]  <= adc1_data_a_even_reg[6];         
	                                                        
       adc1_data_a_reg[13]  <= adc1_data_a_odd_reg[5];          
       adc1_data_a_reg[11]  <= adc1_data_a_odd_reg[4];          
       adc1_data_a_reg[9]   <= adc1_data_a_odd_reg[3];          
       adc1_data_a_reg[7]   <= adc1_data_a_odd_reg[2];          
       adc1_data_a_reg[5]   <= adc1_data_a_odd_reg[1];          
       adc1_data_a_reg[3]   <= adc1_data_a_odd_reg[0];          
       adc1_data_a_reg[1]   <= 1'd0; 
                                                          
       adc1_data_a_reg[12]  <= adc1_data_a_even_reg[5];         
       adc1_data_a_reg[10]  <= adc1_data_a_even_reg[4];         
       adc1_data_a_reg[8]   <= adc1_data_a_even_reg[3];         
       adc1_data_a_reg[6]   <= adc1_data_a_even_reg[2];         
       adc1_data_a_reg[4]   <= adc1_data_a_even_reg[1];         
       adc1_data_a_reg[2]   <= adc1_data_a_even_reg[0];         
       adc1_data_a_reg[0]   <= 1'd0;
//---------------------ADC1   B---------------------------------
       adc1_data_b_reg[15]  <= adc1_data_b_odd_reg[6];          
       adc1_data_b_reg[14]  <= adc1_data_b_even_reg[6];         
	                                                        
       adc1_data_b_reg[13]  <= adc1_data_b_odd_reg[5];          
       adc1_data_b_reg[11]  <= adc1_data_b_odd_reg[4];          
       adc1_data_b_reg[9]   <= adc1_data_b_odd_reg[3];          
       adc1_data_b_reg[7]   <= adc1_data_b_odd_reg[2];          
       adc1_data_b_reg[5]   <= adc1_data_b_odd_reg[1];          
       adc1_data_b_reg[3]   <= adc1_data_b_odd_reg[0];          
       adc1_data_b_reg[1]   <= 1'd0;
                                                          
       adc1_data_b_reg[12]  <= adc1_data_b_even_reg[5];         
       adc1_data_b_reg[10]  <= adc1_data_b_even_reg[4];         
       adc1_data_b_reg[8]   <= adc1_data_b_even_reg[3];         
       adc1_data_b_reg[6]   <= adc1_data_b_even_reg[2];         
       adc1_data_b_reg[4]   <= adc1_data_b_even_reg[1];         
       adc1_data_b_reg[2]   <= adc1_data_b_even_reg[0];         
       adc1_data_b_reg[0]   <= 1'd0;    
     end
end

//////////////////////////shift register 4 bit
always@(posedge adc0_clk or posedge sys_rst)
begin
     if(sys_rst)begin
     	 adc0_data_a_reg4 <= 16'd0;
     	 adc0_data_b_reg4 <= 16'd0;
     end
     else begin
//---------------------ADC0   A---------------------------------   
	   adc0_data_a_reg4[15]  <= adc0_data_a_odd_reg[6]; 
	   adc0_data_a_reg4[14]  <= adc0_data_a_even_reg[5];
	   
       adc0_data_a_reg4[13]  <= adc0_data_a_odd_reg[4];          
       adc0_data_a_reg4[11]  <= adc0_data_a_odd_reg[3];          
       adc0_data_a_reg4[9]   <= adc0_data_a_odd_reg[2];          
       adc0_data_a_reg4[7]   <= adc0_data_a_odd_reg[1];          
       adc0_data_a_reg4[5]   <= adc0_data_a_odd_reg[0];          
       adc0_data_a_reg4[3]   <= 1'b0;          
       adc0_data_a_reg4[1]   <= 1'b0;  
        
       adc0_data_a_reg4[12]  <= adc0_data_a_even_reg[4];         
       adc0_data_a_reg4[10]  <= adc0_data_a_even_reg[3];         
       adc0_data_a_reg4[8]   <= adc0_data_a_even_reg[2];         
       adc0_data_a_reg4[6]   <= adc0_data_a_even_reg[1];         
       adc0_data_a_reg4[4]   <= adc0_data_a_even_reg[0];         
       adc0_data_a_reg4[2]   <= 1'b0;         
       adc0_data_a_reg4[0]   <= 1'b0;
//---------------------ADC0   B---------------------------------
       adc0_data_b_reg4[15]  <= adc0_data_b_odd_reg[6];
	   adc0_data_b_reg4[14]  <= adc0_data_b_even_reg[5];	   
	   
       adc0_data_b_reg4[13]  <= adc0_data_b_odd_reg[4];          
       adc0_data_b_reg4[11]  <= adc0_data_b_odd_reg[3];          
       adc0_data_b_reg4[9]   <= adc0_data_b_odd_reg[2];          
       adc0_data_b_reg4[7]   <= adc0_data_b_odd_reg[1];          
       adc0_data_b_reg4[5]   <= adc0_data_b_odd_reg[0];          
       adc0_data_b_reg4[3]   <= 1'b0;          
       adc0_data_b_reg4[1]   <= 1'b0;  
         
       adc0_data_b_reg4[12]  <= adc0_data_b_even_reg[4];         
       adc0_data_b_reg4[10]  <= adc0_data_b_even_reg[3];         
       adc0_data_b_reg4[8]   <= adc0_data_b_even_reg[2];         
       adc0_data_b_reg4[6]   <= adc0_data_b_even_reg[1];         
       adc0_data_b_reg4[4]   <= adc0_data_b_even_reg[0];         
       adc0_data_b_reg4[2]   <= 1'b0;         
       adc0_data_b_reg4[0]   <= 1'b0;  
     end
end


always@(posedge adc1_clk or posedge sys_rst)
begin
     if(sys_rst)begin
     	 adc1_data_a_reg4 <= 16'd0;
     	 adc1_data_b_reg4 <= 16'd0;
     end
     else begin
//---------------------ADC1   A---------------------------------
       adc1_data_a_reg4[15]  <= adc1_data_a_odd_reg[6];  
	   adc1_data_a_reg4[14]  <= adc1_data_a_even_reg[5]; 
   
       adc1_data_a_reg4[13]  <= adc1_data_a_odd_reg[4];          
       adc1_data_a_reg4[11]  <= adc1_data_a_odd_reg[3];          
       adc1_data_a_reg4[9]   <= adc1_data_a_odd_reg[2];          
       adc1_data_a_reg4[7]   <= adc1_data_a_odd_reg[1];          
       adc1_data_a_reg4[5]   <= adc1_data_a_odd_reg[0];          
       adc1_data_a_reg4[3]   <= 1'b0;          
       adc1_data_a_reg4[1]   <= 1'b0;  
          
       adc1_data_a_reg4[12]  <= adc1_data_a_even_reg[4];         
       adc1_data_a_reg4[10]  <= adc1_data_a_even_reg[3];         
       adc1_data_a_reg4[8]   <= adc1_data_a_even_reg[2];         
       adc1_data_a_reg4[6]   <= adc1_data_a_even_reg[1];         
       adc1_data_a_reg4[4]   <= adc1_data_a_even_reg[0];         
       adc1_data_a_reg4[2]   <= 1'b0;         
       adc1_data_a_reg4[0]   <= 1'b0;
//---------------------ADC1   B---------------------------------
       adc1_data_b_reg4[15]  <= adc1_data_b_odd_reg[6]; 
       adc1_data_b_reg4[14]  <= adc1_data_b_even_reg[5]; 
	   
       adc1_data_b_reg4[13]  <= adc1_data_b_odd_reg[4];          
       adc1_data_b_reg4[11]  <= adc1_data_b_odd_reg[3];          
       adc1_data_b_reg4[9]   <= adc1_data_b_odd_reg[2];          
       adc1_data_b_reg4[7]   <= adc1_data_b_odd_reg[1];          
       adc1_data_b_reg4[5]   <= adc1_data_b_odd_reg[0];          
       adc1_data_b_reg4[3]   <= 1'b0;          
       adc1_data_b_reg4[1]   <= 1'b0; 
         	 
       adc1_data_b_reg4[12]  <= adc1_data_b_even_reg[4];         
       adc1_data_b_reg4[10]  <= adc1_data_b_even_reg[3];         
       adc1_data_b_reg4[8]   <= adc1_data_b_even_reg[2];         
       adc1_data_b_reg4[6]   <= adc1_data_b_even_reg[1];         
       adc1_data_b_reg4[4]   <= adc1_data_b_even_reg[0];         
       adc1_data_b_reg4[2]   <= 1'b0;         
       adc1_data_b_reg4[0]   <= 1'b0;     
     end
end

//////////////////////////shift register 0 bit
always@(posedge adc0_clk or posedge sys_rst)
begin
     if(sys_rst)begin
     	 adc0_data_a_reg0 <= 16'd0;
     	 adc0_data_b_reg0 <= 16'd0;
     end
     else begin
//---------------------ADC0   A---------------------------------   
	   adc0_data_a_reg0[15]  <= adc0_data_a_odd_reg[6];
	   adc0_data_a_reg0[14]  <= adc0_data_a_odd_reg[6];
	   
       adc0_data_a_reg0[13]  <= adc0_data_a_odd_reg[6];          
       adc0_data_a_reg0[11]  <= adc0_data_a_odd_reg[5];          
       adc0_data_a_reg0[9]   <= adc0_data_a_odd_reg[4];          
       adc0_data_a_reg0[7]   <= adc0_data_a_odd_reg[3];          
       adc0_data_a_reg0[5]   <= adc0_data_a_odd_reg[2];          
       adc0_data_a_reg0[3]   <= adc0_data_a_odd_reg[1];          
       adc0_data_a_reg0[1]   <= adc0_data_a_odd_reg[0];  
        		
       adc0_data_a_reg0[12]  <= adc0_data_a_even_reg[6];         
       adc0_data_a_reg0[10]  <= adc0_data_a_even_reg[5];         
       adc0_data_a_reg0[8]   <= adc0_data_a_even_reg[4];         
       adc0_data_a_reg0[6]   <= adc0_data_a_even_reg[3];         
       adc0_data_a_reg0[4]   <= adc0_data_a_even_reg[2];         
       adc0_data_a_reg0[2]   <= adc0_data_a_even_reg[1];         
       adc0_data_a_reg0[0]   <= adc0_data_a_even_reg[0];
//---------------------ADC0   B---------------------------------
       adc0_data_b_reg0[15]  <= adc0_data_b_odd_reg[6]; 
       adc0_data_b_reg0[14]  <= adc0_data_b_odd_reg[6]; 
	   
       adc0_data_b_reg0[13]  <= adc0_data_b_odd_reg[6];          
       adc0_data_b_reg0[11]  <= adc0_data_b_odd_reg[5];          
       adc0_data_b_reg0[9]   <= adc0_data_b_odd_reg[4];          
       adc0_data_b_reg0[7]   <= adc0_data_b_odd_reg[3];          
       adc0_data_b_reg0[5]   <= adc0_data_b_odd_reg[2];          
       adc0_data_b_reg0[3]   <= adc0_data_b_odd_reg[1];          
       adc0_data_b_reg0[1]   <= adc0_data_b_odd_reg[0];  
           
       adc0_data_b_reg0[12]  <= adc0_data_b_even_reg[6];         
       adc0_data_b_reg0[10]  <= adc0_data_b_even_reg[5];         
       adc0_data_b_reg0[8]   <= adc0_data_b_even_reg[4];         
       adc0_data_b_reg0[6]   <= adc0_data_b_even_reg[3];         
       adc0_data_b_reg0[4]   <= adc0_data_b_even_reg[2];         
       adc0_data_b_reg0[2]   <= adc0_data_b_even_reg[1];         
       adc0_data_b_reg0[0]   <= adc0_data_b_even_reg[0];  
     end
end


always@(posedge adc1_clk or posedge sys_rst)
begin
     if(sys_rst)begin
     	 adc1_data_a_reg0 <= 16'd0;
     	 adc1_data_b_reg0 <= 16'd0;
     end
     else begin
//---------------------ADC1   A---------------------------------
       adc1_data_a_reg0[15]  <= adc1_data_a_odd_reg[6];
       adc1_data_a_reg0[14]  <= adc1_data_a_odd_reg[6]; 
	   
       adc1_data_a_reg0[13]  <= adc1_data_a_odd_reg[6];          
       adc1_data_a_reg0[11]  <= adc1_data_a_odd_reg[5];          
       adc1_data_a_reg0[9]   <= adc1_data_a_odd_reg[4];          
       adc1_data_a_reg0[7]   <= adc1_data_a_odd_reg[3];          
       adc1_data_a_reg0[5]   <= adc1_data_a_odd_reg[2];          
       adc1_data_a_reg0[3]   <= adc1_data_a_odd_reg[1];          
       adc1_data_a_reg0[1]   <= adc1_data_a_odd_reg[0];  
       	   
       adc1_data_a_reg0[12]  <= adc1_data_a_even_reg[6];         
       adc1_data_a_reg0[10]  <= adc1_data_a_even_reg[5];         
       adc1_data_a_reg0[8]   <= adc1_data_a_even_reg[4];         
       adc1_data_a_reg0[6]   <= adc1_data_a_even_reg[3];         
       adc1_data_a_reg0[4]   <= adc1_data_a_even_reg[2];         
       adc1_data_a_reg0[2]   <= adc1_data_a_even_reg[1];         
       adc1_data_a_reg0[0]   <= adc1_data_a_even_reg[0];
//---------------------ADC1   B---------------------------------
       adc1_data_b_reg0[15]  <= adc1_data_b_odd_reg[6];
       adc1_data_b_reg0[14]  <= adc1_data_b_odd_reg[6];  	   
	   
       adc1_data_b_reg0[13]  <= adc1_data_b_odd_reg[6];          
       adc1_data_b_reg0[11]  <= adc1_data_b_odd_reg[5];          
       adc1_data_b_reg0[9]   <= adc1_data_b_odd_reg[4];          
       adc1_data_b_reg0[7]   <= adc1_data_b_odd_reg[3];          
       adc1_data_b_reg0[5]   <= adc1_data_b_odd_reg[2];          
       adc1_data_b_reg0[3]   <= adc1_data_b_odd_reg[1];          
       adc1_data_b_reg0[1]   <= adc1_data_b_odd_reg[0]; 
          
       adc1_data_b_reg0[12]  <= adc1_data_b_even_reg[6];         
       adc1_data_b_reg0[10]  <= adc1_data_b_even_reg[5];         
       adc1_data_b_reg0[8]   <= adc1_data_b_even_reg[4];         
       adc1_data_b_reg0[6]   <= adc1_data_b_even_reg[3];         
       adc1_data_b_reg0[4]   <= adc1_data_b_even_reg[2];         
       adc1_data_b_reg0[2]   <= adc1_data_b_even_reg[1];         
       adc1_data_b_reg0[0]   <= adc1_data_b_even_reg[0];     
     end
end


//////////////////////////////////////////////////////////////////////////////////
//// 2015/11/24 11:45:15 
always@(posedge sys_clk or posedge sys_rst)
begin
	if(sys_rst)begin
	adc0_data_a_out <= 16'd0;
    adc0_data_b_out <= 16'd0;
    adc1_data_a_out <= 16'd0;
    adc1_data_b_out <= 16'd0;
  end
  else begin
    adc0_data_a_out <= adc0_fifo_out[31:16]; 
    adc0_data_b_out <= adc0_fifo_out[15:0];  
    adc1_data_a_out <= adc1_fifo_out[31:16]; 
    adc1_data_b_out <= adc1_fifo_out[15:0]; 
  end
end 

//////////////////////////////////////////////////////////////////////////////////
//// (0) clk ibufgds 
// IBUFGDS u0_adc0_CLK( 
             // .O (adc0_clk  ), 
             // .I (adc0_clkout_p), 
             // .IB(adc0_clkout_n)              
// ); 

// IBUFGDS u1_adc1_CLK( 
             // .I (adc1_clkout_p), 
             // .IB(adc1_clkout_n), 
             // .O (adc1_clk  ) 
// );

//////////////////////////////////////////////////////////////////////////////////
//// (1) or IBUFDS 

IBUFDS u30_adc0_or ( 
            .I (adc0_or_p), 
            .IB(adc0_or_n), 
            .O (adc0_or) 
            ); 
IBUFDS u31_adc1_or ( 
            .I (adc1_or_p), 
            .IB(adc1_or_n), 
            .O (adc1_or) 
            );




//////////////////////////////////////////////////////////////////////////////////
//// (2) data  IDDR            
genvar i;

generate 
for (i=0;i<7;i=i+1)
begin: adc_data
//--------------------------adc0a	
IBUFDS   #(
    .DIFF_TERM("TRUE"),    
    .IOSTANDARD("DEFAULT")  
   )adc0a_data
    (
	 .O (adc0_data_a[i]),
	 .I (adc0_data_a_p[i]),
	 .IB(adc0_data_a_n[i]) 
	 );	 
IDDR #(
 .DDR_CLK_EDGE("OPPOSITE_EDGE"), 
 .INIT_Q1(1'b0),
 .INIT_Q2(1'b0), 
 .SRTYPE("SYNC") 
 ) IDDR_inst_adc0a (
 .Q1(adc0_data_a_even[i]), 
 .Q2(adc0_data_a_odd[i]),
 .C(adc0_clk),
 .CE(1'd1), 
 .D(adc0_data_a[i]), 
 .R(sys_rst), 
 .S(1'd0) 
 );
//--------------------------adc0b
IBUFDS   #(
    .DIFF_TERM("TRUE"),    
    .IOSTANDARD("DEFAULT")  
   )adc0b_data
    (
	 .O (adc0_data_b[i]),
	 .I (adc0_data_b_p[i]),
	 .IB(adc0_data_b_n[i]) 
	 );	 
IDDR #(
 .DDR_CLK_EDGE("OPPOSITE_EDGE"), 
 .INIT_Q1(1'b0),
 .INIT_Q2(1'b0), 
 .SRTYPE("SYNC") 
 ) IDDR_inst_adc0b (
 .Q1(adc0_data_b_even[i]), 
 .Q2(adc0_data_b_odd[i]),
 .C(adc0_clk),
 .CE(1'd1), 
 .D(adc0_data_b[i]), 
 .R(sys_rst), 
 .S(1'd0) 
 );
 //-----------------------------adc1a
IBUFDS   #(
    .DIFF_TERM("TRUE"),    
    .IOSTANDARD("DEFAULT")  
   )adc1a_data
    (
	 .O (adc1_data_a[i]),
	 .I (adc1_data_a_p[i]),
	 .IB(adc1_data_a_n[i]) 
	 );	 
IDDR #(
 .DDR_CLK_EDGE("OPPOSITE_EDGE"), 
 .INIT_Q1(1'b0),
 .INIT_Q2(1'b0), 
 .SRTYPE("SYNC") 
 ) IDDR_inst_adc1a (
 .Q1(adc1_data_a_even[i]), 
 .Q2(adc1_data_a_odd[i]),
 .C(adc1_clk),
 .CE(1'd1), 
 .D(adc1_data_a[i]), 
 .R(sys_rst), 
 .S(1'd0) 
 );
//--------------------------adc1b
IBUFDS   #(
    .DIFF_TERM("TRUE"),    
    .IOSTANDARD("DEFAULT")  
   )adc1b_data
    (
	 .O (adc1_data_b[i]),
	 .I (adc1_data_b_p[i]),
	 .IB(adc1_data_b_n[i]) 
	 );	 
IDDR #(
 .DDR_CLK_EDGE("OPPOSITE_EDGE"), 
 .INIT_Q1(1'b0),
 .INIT_Q2(1'b0), 
 .SRTYPE("SYNC") 
 ) IDDR_inst_adc1b (
 .Q1(adc1_data_b_even[i]), 
 .Q2(adc1_data_b_odd[i]),
 .C(adc1_clk),
 .CE(1'd1), 
 .D(adc1_data_b[i]), 
 .R(sys_rst), 
 .S(1'd0) 
 );
end
endgenerate

//////////////////////////////////////////////////////////////////////////////////
//// (2) data  fifo  
// always@(posedge adc0_clk or posedge sys_rst)
// begin
	// if(sys_rst)
	   // adc0_fifo_in <= 32'd0;
	// else 
	   // adc0_fifo_in <= {adc0_data_a_reg,adc0_data_b_reg};
// end

// always@(posedge adc1_clk or posedge sys_rst)
// begin 
		// if(sys_rst)
		  // adc1_fifo_in <= 32'd0;
		// else
	    // adc1_fifo_in <= {adc1_data_a_reg,adc1_data_b_reg}; 
// end	

////////////////////////////////////////////////////////
always@(posedge adc0_clk or posedge sys_rst)
begin
	if(sys_rst)
	   adc0_fifo_in <= 32'd0;
    else if(mif_adc_mode[15:0] == 16'h0002)
       adc0_fifo_in <= {adc0_data_a_reg,adc0_data_b_reg};
	else if(mif_adc_mode[15:0] == 16'h0008)
	   adc0_fifo_in <= {adc0_data_a_reg0,adc0_data_b_reg0};
    else 
	   adc0_fifo_in <= {adc0_data_a_reg4,adc0_data_b_reg4};
	end

always@(posedge adc1_clk or posedge sys_rst)
begin 
	if(sys_rst)
	  adc1_fifo_in <= 32'd0;
	else if(mif_adc_mode[15:0] == 16'h0002)
	  adc1_fifo_in <= {adc1_data_a_reg,adc1_data_b_reg}; 
	else if(mif_adc_mode[15:0] == 16'h0008)
	  adc1_fifo_in <= {adc1_data_a_reg0,adc1_data_b_reg0};
	else
	  adc1_fifo_in <= {adc1_data_a_reg4,adc1_data_b_reg4}; 
end

//////////////////////////////////////////////////////////////////////////////////
//// adc 
always@(posedge adc0_clk or posedge sys_rst)
begin
     if(sys_rst)begin
     	  adc0_fifo_wr <= 1'd0;
	   end
     else begin
	      adc0_fifo_wr <= adc_switch[0];
	   end
end
//////////////////////////////////////////////////////////////////////////////////
//// adc 
always@(posedge adc1_clk or posedge sys_rst)
begin
     if(sys_rst)begin
	      adc1_fifo_wr <= 1'd0;
	   end
     else begin
	      adc1_fifo_wr <= adc_switch[1];
	   end
end
//------------------------------------------------
always@(posedge sys_clk or posedge sys_rst)
begin 
		if(sys_rst)
		  fifo_rst <= 1'd1;
		else if(mif_adc_fifo_rst)
		  fifo_rst <= 1'd1;
		else 
		  fifo_rst <= 1'd0;
end


//////////////////////////////////////////////////////////////////////////////////
//// adc0  
fifo_32x512  u_ad2fpga_fifo0(
  .rst           (fifo_rst         ),
  .wr_clk        (adc0_clk        ),              //adc 200
  .rd_clk        (sys_clk         ),               //sys 200
  .din           (adc0_fifo_in    ),
  .wr_en         (adc0_fifo_wr    ),
  .rd_en         (~adc0_fifo_empty),
  .dout          (adc0_fifo_out   ),
  .full          (adc0_fifo_full  ),
  .empty         (adc0_fifo_empty )
);
//// adc1 
fifo_32x512  u_ad2fpga_fifo1(
  .rst           (fifo_rst),
  .wr_clk        (adc1_clk) ,              //adc 200
  .rd_clk        (sys_clk) ,               //sys 200
  .din           (adc1_fifo_in) ,
  .wr_en         (adc1_fifo_wr) ,
  .rd_en         (~adc1_fifo_empty) ,
  .dout          (adc1_fifo_out)    ,
  .full          (adc1_fifo_full)   ,
  .empty         (adc1_fifo_empty)
);


//////////////////////////////////////////////////////////////////////////////////
//// debug signal ////
assign  debug_signal[63:0]    = {adc0_fifo_out,adc1_fifo_out};//{adc0_fifo_in,adc1_fifo_in};//
assign  debug_signal[127:64]  = {adc0_fifo_in,adc1_fifo_in};
assign  debug_signal[199:128] = 72'd0;







//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
endmodule















