`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    09:33:14 03/28/2017 
// Design Name: 
// Module Name:    ad_receive 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module ad_receive(

		input clk_200m,
		input cfg_rst,
		
		//-------------ADC0 IN--------------------
		input [6:0]              adc0_data_a_p,
		input [6:0]              adc0_data_a_n,
		input [6:0]              adc0_data_b_p,
		input [6:0]              adc0_data_b_n,
		input                    adc0_or_p,
		input                    adc0_or_n,
		input                    adc0_clk,
		//-------------ADC1 IN--------------------
		input [6:0]              adc1_data_a_p,
		input [6:0]              adc1_data_a_n,
		input [6:0]              adc1_data_b_p,
		input [6:0]              adc1_data_b_n,
		input                    adc1_or_p,
		input                    adc1_or_n,
		input                    adc1_clk,
		//-------------ADC OUT--------------------
		output reg [15:0]            adc0_data_a_out,
		output reg [15:0]            adc0_data_b_out,
		output reg [15:0]            adc1_data_a_out,
		output reg [15:0]            adc1_data_b_out,
		
		output [199:0] debug_signal
    );

wire [6:0] adc0_data_a;
wire [6:0] adc0_data_b;
wire [6:0] adc1_data_a;
wire [6:0] adc1_data_b;

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






//always@(posedge clk_200m or posedge cfg_rst)
//begin
//	if(cfg_rst)begin
//	adc0_data_a_out <= 16'd0;
////    adc0_data_b_out <= 16'd0;
////    adc1_data_a_out <= 16'd0;
////    adc1_data_b_out <= 16'd0;
//  end
//  else begin
//    adc0_data_a_out <= adc0_fifo_out_a; 
////    adc0_data_b_out <= adc0_fifo_out_b;  
////    adc1_data_a_out <= adc1_fifo_out_a; 
////    adc1_data_b_out <= adc1_fifo_out_b; 
//  end
//end 
//////////////////////////////////////////////////////////////////////////////////
//// IDDR DL
always@(posedge adc0_clk or posedge cfg_rst)
begin
     if(cfg_rst)begin
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
// IDDR DL
always@(posedge adc1_clk or posedge cfg_rst)
begin
     if(cfg_rst)begin
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
always@(posedge adc0_clk or posedge cfg_rst)
begin
     if(cfg_rst)begin
     	 adc0_data_a_reg <= 16'd0;
//     	 adc0_data_b_reg <= 16'd0;
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
always@(posedge adc1_clk or posedge cfg_rst)
begin
     if(cfg_rst)begin
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

always@(posedge clk_200m or posedge cfg_rst)
begin
	if(cfg_rst)begin
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
 .R(cfg_rst), 
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
 .R(cfg_rst), 
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
 .R(cfg_rst), 
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
 .R(cfg_rst), 
 .S(1'd0) 
 );
end
endgenerate

////////////////////////////////////////////////////////
always@(posedge adc0_clk or posedge cfg_rst)
begin
	if(cfg_rst)
	   adc0_fifo_in <= 32'd0;
    else 
	   adc0_fifo_in <= {adc0_data_a_reg,adc0_data_b_reg};
	end

always@(posedge adc1_clk or posedge cfg_rst)
begin 
	if(cfg_rst)
	  adc1_fifo_in <= 32'd0;
	else
	  adc1_fifo_in <= {adc1_data_a_reg,adc1_data_b_reg}; 
end  


always@(posedge adc0_clk or posedge cfg_rst)
begin
     if(cfg_rst)begin
     	  adc0_fifo_wr <= 1'd0;
	   end
     else begin
	      adc0_fifo_wr <= 1'b1;
	   end
end
////////////////////////////////////////////////////////////////////////////////
// adc 
always@(posedge adc1_clk or posedge cfg_rst)
begin
     if(cfg_rst)begin
	      adc1_fifo_wr <= 1'd0;
	   end
     else begin
	      adc1_fifo_wr <= 1'b1;
	   end
end
//------------------------------------------------
always@(posedge clk_200m or posedge cfg_rst)
begin 
		if(cfg_rst)
		  fifo_rst <= 1'd1;
		else 
		  fifo_rst <= 1'd0;
end

//////////////////////////////////////////////////////////////////////////////////
//// adc0  
fifo_32x512  u_ad2fpga_fifo0(
  .rst           (fifo_rst         ),
  .wr_clk        (adc0_clk        ),              //adc 200
  .rd_clk        (clk_200m         ),               //sys 200
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
  .rd_clk        (clk_200m) ,               //sys 200
  .din           (adc1_fifo_in) ,
  .wr_en         (adc1_fifo_wr ) ,
  .rd_en         (~adc1_fifo_empty) ,
  .dout          (adc1_fifo_out)    ,
  .full          (adc1_fifo_full)   ,
  .empty         (adc1_fifo_empty)
);

//
//fifo_16x256 u_ad2fpga_fifo0 (
//  .rst(fifo_rst), // input rst
//  .wr_clk(adc0_clk), // input wr_clk
//  .rd_clk(clk_200m), // input rd_clk
//  .din(adc0_fifo_in_a), // input [15 : 0] din
//  .wr_en(adc0_fifo_wr), // input wr_en
//  .rd_en(~adc0_fifo_empty_a), // input rd_en
//  .dout(adc0_fifo_out_a), // output [15 : 0] dout
//  .full(adc0_fifo_full_a), // output full
//  .empty(adc0_fifo_empty_a) // output empty
//);

//fifo_16x256 u_ad2fpga_fifo1 (
//  .rst(fifo_rst), // input rst
//  .wr_clk(adc0_clk), // input wr_clk
//  .rd_clk(clk_200m), // input rd_clk
//  .din(adc0_fifo_in_b), // input [15 : 0] din
//  .wr_en(adc0_fifo_wr), // input wr_en
//  .rd_en(~adc0_fifo_empty_b), // input rd_en
//  .dout(adc0_fifo_out_b), // output [15 : 0] dout
//  .full(adc0_fifo_full_b), // output full
//  .empty(adc0_fifo_empty_b) // output empty
//);
//
//fifo_16x256 u_ad2fpga_fifo2 (
//  .rst(fifo_rst), // input rst
//  .wr_clk(adc1_clk), // input wr_clk
//  .rd_clk(clk_200m), // input rd_clk
//  .din(adc1_fifo_in_a), // input [15 : 0] din
//  .wr_en(adc1_fifo_wr), // input wr_en
//  .rd_en(~adc1_fifo_empty_a), // input rd_en
//  .dout(adc1_fifo_out_a), // output [15 : 0] dout
//  .full(adc1_fifo_full_a), // output full
//  .empty(adc1_fifo_empty_a) // output empty
//);
//
//fifo_16x256 u_ad2fpga_fifo3 (
//  .rst(fifo_rst), // input rst
//  .wr_clk(adc1_clk), // input wr_clk
//  .rd_clk(clk_200m), // input rd_clk
//  .din(adc1_fifo_in_b), // input [15 : 0] din
//  .wr_en(adc1_fifo_wr), // input wr_en
//  .rd_en(~adc1_fifo_empty_b), // input rd_en
//  .dout(adc1_fifo_out_b), // output [15 : 0] dout
//  .full(adc1_fifo_full_b), // output full
//  .empty(adc1_fifo_empty_b) // output empty
//);


assign  debug_signal[63:0]    = {adc0_fifo_out,adc1_fifo_out};//{adc0_fifo_in,adc1_fifo_in};//
assign  debug_signal[127:64]  = {adc0_fifo_in,adc1_fifo_in};
assign  debug_signal[134:128] = adc0_data_a_odd_reg;
assign  debug_signal[141:135] = adc0_data_a_even_reg;
assign  debug_signal[157:142] = adc0_data_a_reg;
assign  debug_signal[199:158] = 72'd0;

endmodule
