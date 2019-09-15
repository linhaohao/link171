//////////////////////////////////////////////////////////////////////////////////
// Company:         StarPoint
// Engineer:        GUO YAN 
// 
// Create Date:     11:14:14 08/04/2015 
// Module Name:     rx_buffer_top 
// Project Name:    Rx buffer module;
// Target Devices:  FPGA - XC7K325T - FFG900; 
// Tool versions:   ISE14.6; 
// Description:     Received data is buffer in this module;
//                  one stationary RAM is as buffer between FPGA and DSP.
//
// Revision:        v1.0 - File Created
// Additional Comments: 
// 1. 
//
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps


module rx_buffer_top(
//// clock interface ////
input               logic_clk_in,                           // 200MHz logic clock
input               logic_rst_in,                           //  reset

//// write ram signals ////
input               data_wr_in,
input [7:0]         data_in,                                // 8bits demodulation data 

//// write TOA value ////
input               toa_wr_in,
input [31:0]        slot_timer_in,
input [31:0]        unsync_timer_in,
input [1:0]         net_slot_mode,
input               tx_slot_interrupt,
	
//// read ram signals ////
input               ram_rd_in,
input [7:0]         addr_rd_in,
output[31:0]        ram_data_out,

//// rx interrupt ////
input [8:0]         rx_slot_length,
output              rx_slot_interrupt_out,
output              rx_dsp_interrupt_out,

//// debug ////
output[127:0]       debug_signal

    );


//////////////////////////////////////////////////////////////////////////////////
//// signals declaration //// 
wire[8:0]           rx_slot_data_length;
reg                 rx_slot_interrupt          = 1'b0;
reg                 rx_dsp_interrupt           = 1'b0;

reg [8:0]           rx_dsp_cnt                 = 9'd0;

reg                 rx_ram_wr                  = 1'b0;
reg[7:0]            ram_data_wr                = 8'd0;
reg[9:0]            ram_addr_wr                = 10'd0;

wire                data_wr_en;
reg [9:0]           data_addr_wr_dly           = 10'd0;
reg [9:0]           data_addr_wr               = 10'd0;
wire[31:0]          ram_data_rd;               
                                                 
reg                 toa_wr_start               = 1'b0; 
reg                 toa_wr_start_dly           = 1'b0;                                   
reg [7:0]           toa_wr_data                = 8'h00;
reg [31:0]          toa_data                   = 32'd0;

reg                 unsync_wr_in               = 1'b0; 
reg                 unsync_wr_start            = 1'b0;                                     
reg [7:0]           unsync_wr_data             = 8'hff;

reg [1:0]           net_slot_mode_cur          = 2'b00;
//////////////////////////////////////////////////////////////////////////////////
//// parameters define ////





//////////////////////////////////////////////////////////////////////////////////
//// (0) signals assigment ////
   assign  rx_slot_data_length[8:0]    = rx_slot_length[8:0] - 6'd40;

   assign  ram_data_out[31:0]          = ram_data_rd[31:0];
   
   assign  rx_slot_interrupt_out       = rx_slot_interrupt;
   assign  rx_dsp_interrupt_out        = rx_slot_interrupt || rx_dsp_interrupt;
   
   assign  data_wr_en                  = toa_wr_start || data_wr_in || unsync_wr_start;
   				  										
//////////////////////////////////////////////////////////////////////////////////
//// (1) RAM buffer module ////
rx_ram_buffer   u1_rx_buffer
   (
	.clka(logic_clk_in),
	.wea(rx_ram_wr),
	.addra(ram_addr_wr[9:0]),  //ping-pang depth = 2^10=1024(512*2)
	.dina(ram_data_wr[7:0]),

	.clkb(logic_clk_in),
	.enb(ram_rd_in),
	.addrb(addr_rd_in[7:0]),	
	.doutb(ram_data_rd[31:0]) //[31:0]=[ram3[7:0],ram2[7:0],ram1[7:0],ram0[7:0]]
	
	);


//////////////////////////////////////////////////////////////////////////////////
//// (2) RAM write address logic ////
// ping-pang ram
// 0x000~0x003	delay TOA/UNSYNC(32'hFFFFFFFF)
// 0x004~0x197	receive data/UNSYNC(32'hFFFFFFFF)
// 0x198~0x1FF	futrue extension
// 0x200~0x203	delay TOA/UNSYNC(32'hFFFFFFFF)
// 0x204~0x397	receive data/UNSYNC(32'hFFFFFFFF)
// 0x398~0x3FF	futrue extension
always@(posedge logic_clk_in)
begin
    if(logic_rst_in) begin
       data_addr_wr[9:0]            <= 10'd0;  
	   rx_slot_interrupt            <= 1'b0;
    end
    else if(data_wr_en && (data_addr_wr[9:0] == {1'b0,(rx_slot_data_length[8:0] + 3'b11)})) begin //4~407(75)
       data_addr_wr[9:0]            <= 10'd512;  
	   rx_slot_interrupt            <= 1'b1;  //receive all data, then generate rx_interrupt
    end
    else if(data_wr_en && (data_addr_wr[9:0] == (rx_slot_data_length[8:0] + 10'd515))) begin //516~919(587)
       data_addr_wr[9:0]            <= 10'd0;  
	   rx_slot_interrupt            <= 1'b1;
    end
    else if(data_wr_en)begin
       data_addr_wr[9:0]            <= data_addr_wr[9:0] + 1'b1; 
	   rx_slot_interrupt            <= 1'b0;	 
    end
    else begin
       data_addr_wr[9:0]            <= data_addr_wr[9:0];  
	   rx_slot_interrupt            <= 1'b0;
    end
end	

//////////////////////////////////////////////////////////////////////////////////
//// (3) TOA write address logic ////
always@(posedge logic_clk_in)
begin
    if(logic_rst_in) begin
	   toa_wr_start                 <= 1'b0;	
	   toa_data[31:0]               <= 32'd0;
    end
    else if((data_addr_wr[9:0]  == 10'd3) || (data_addr_wr[9:0] == 10'd515))begin
	   toa_wr_start                 <= 1'b0;
	   toa_data[31:0]               <= 32'd0;
    end
    else if(toa_wr_in)begin
	   toa_wr_start                 <= 1'b1;
	   toa_data[31:0]               <= slot_timer_in[31:0];
    end
end

always@(posedge logic_clk_in)
begin
    if(logic_rst_in) begin
       toa_wr_data[7:0]             <= 8'd0; 
    end
    else if(toa_wr_start) begin
      case(data_addr_wr[9:0])
	    10'd0:   begin
	      toa_wr_data[7:0]          <= toa_data[31:24];
	  end                           
	    10'd1:   begin                
	  	  toa_wr_data[7:0]          <= toa_data[23:16];
	  end      
	    10'd2:   begin
	  	  toa_wr_data[7:0]          <= toa_data[15:8];
	  end      
	    10'd3:   begin
	  	  toa_wr_data[7:0]          <= toa_data[7:0];
	  end
	    10'd512: begin
	  	  toa_wr_data[7:0]          <= toa_data[31:24];
	  end
	    10'd513: begin
	      toa_wr_data[7:0]          <= toa_data[23:16];
	  end
	    10'd514: begin
	  	  toa_wr_data[7:0]          <= toa_data[15:8];
	  end
	    10'd515: begin
	  	  toa_wr_data[7:0]          <= toa_data[7:0];
	  end
	  default: begin
	      toa_wr_data[7:0]          <= 8'd0;
	  end	
	  endcase
    end
end

always@(posedge logic_clk_in)
begin
    if(logic_rst_in) begin
	   toa_wr_start_dly             <= 1'b0;	
    end
    else begin
	   toa_wr_start_dly             <= toa_wr_start; //toa_wr_data delay toa_data
    end
end

//////////////////////////////////////////////////////////////////////////////////
//// (4) UNSYNC write address logic ////
always@(posedge logic_clk_in)
begin
    if(logic_rst_in) begin
	   net_slot_mode_cur[1:0]       <= 2'b00;	
    end
    else if(tx_slot_interrupt)begin
	   net_slot_mode_cur[1:0]       <= net_slot_mode[1:0];
    end
end

always@(posedge logic_clk_in)
begin
    if(logic_rst_in) begin
	   unsync_wr_in                 <= 1'b0;	
    end
    else if((net_slot_mode_cur[1:0] != 2'b01) && (slot_timer_in[31:0] == unsync_timer_in[31:0]))begin
	   unsync_wr_in                 <= 1'b1;
    end
    else begin
	   unsync_wr_in                 <= 1'b0;
    end
end

always@(posedge logic_clk_in)
begin
    if(logic_rst_in) begin
	   unsync_wr_start              <= 1'b0;	
    end
    else if((data_addr_wr[9:0] == {1'b0,(rx_slot_data_length[8:0] + 3'b11)}) || (data_addr_wr[9:0] == (rx_slot_data_length[8:0] + 10'd515))) begin  
	  unsync_wr_start              <= 1'b0;
    end
    else if(unsync_wr_in)begin
	   unsync_wr_start              <= 1'b1;
    end
end
//////////////////////////////////////////////////////////////////////////////////
//// (5) ram write address logic ////
   //assign  rx_ram_wr                   = toa_wr_start_dly || data_wr_in || unsync_wr_start;
   
   // assign  ram_addr_wr[9:0]            = unsync_wr_start ? unsync_addr_wr[9:0] :
                                         // toa_wr_start_dly? toa_addr_wr_dly[9:0] :
										 // data_addr_wr[9:0];  //未能实现三者地址累计增加
										 
   // assign  ram_data_wr[7:0]            = unsync_wr_start ? unsync_wr_data[7:0] : 
                                         // toa_wr_start_dly? toa_wr_data[7:0] :
										 // data_in[7:0];
always@(posedge logic_clk_in)
begin
    if(logic_rst_in) begin
	   data_addr_wr_dly[9:0]     <= 10'd0;
    end
    else  begin
       data_addr_wr_dly[9:0]     <= data_addr_wr[9:0];  
    end
end	
									
										 
always@(posedge logic_clk_in)
begin
    if(logic_rst_in) begin
	   ram_data_wr[7:0]          <= 8'd0;
	   ram_addr_wr[9:0]          <= 10'd0;
       rx_ram_wr	             <= 1'b0;
    end
    else if(unsync_wr_start) begin
	   ram_data_wr[7:0]          <= unsync_wr_data[7:0];
       ram_addr_wr[9:0]          <= data_addr_wr[9:0];  
	   rx_ram_wr	             <= 1'b1;
    end
    else if(toa_wr_start_dly) begin
	   ram_data_wr[7:0]          <= toa_wr_data[7:0];	
       ram_addr_wr[9:0]          <= data_addr_wr_dly[9:0]; 
       rx_ram_wr	             <= 1'b1;	   
    end                             
    else if(data_wr_in)begin  
	   ram_data_wr[7:0]          <= data_in[7:0];	
	   ram_addr_wr[9:0]          <= data_addr_wr[9:0];
	   rx_ram_wr	             <= 1'b1;
    end                             
	else begin   
	   ram_data_wr[7:0]          <= ram_data_wr[7:0] ;	
	   ram_addr_wr[9:0]          <= ram_addr_wr[9:0];
	   rx_ram_wr	             <= 1'b0;
    end
end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//// (6) rx slot intterrupt to dsp(last 2us high level) ////
always@(posedge logic_clk_in)
begin
   if (logic_rst_in)   begin
	   rx_dsp_interrupt                 <= 1'b0;
   end
   else if (rx_dsp_cnt[8:0] == 9'd398)  begin   
	   rx_dsp_interrupt                 <= 1'b0;
   end
   else if(rx_slot_interrupt)begin
	   rx_dsp_interrupt                 <= 1'b1;
    end
end

always@(posedge logic_clk_in)
begin
   if (logic_rst_in)   begin
	   rx_dsp_cnt[8:0]                  <= 9'd0;
   end
   else if (rx_dsp_cnt[8:0] == 9'd398)  begin   
	   rx_dsp_cnt[8:0]                  <= 9'd0;
   end
   else if(rx_dsp_interrupt)begin
	   rx_dsp_cnt[8:0]                  <= rx_dsp_cnt[8:0] + 1'b1;
    end
end

//////////////////////////////////////////////////////////////////////////////////
////(7) debug ////
assign debug_signal[0]           = rx_ram_wr;
assign debug_signal[10:1]        = ram_addr_wr[9:0]; 
assign debug_signal[18:11]       = ram_data_wr[7:0];
                                 
assign debug_signal[19]          = ram_rd_in;
assign debug_signal[27:20]       = addr_rd_in[7:0];	
assign debug_signal[59:28]       = ram_data_rd[31:0]; //toa_data[31:0];
                                 
assign debug_signal[60]          = rx_slot_interrupt;
assign debug_signal[61]          = data_wr_en;
assign debug_signal[71:62]       = data_addr_wr[9:0];
                                 
assign debug_signal[72]          = toa_wr_in;
assign debug_signal[73]          = toa_wr_start;
assign debug_signal[74]          = unsync_wr_in;
assign debug_signal[75]          = unsync_wr_start;
//assign debug_signal[84:76]       = rx_dsp_cnt[8:0];
assign debug_signal[76]          = tx_slot_interrupt; //113
assign debug_signal[78:77]       = net_slot_mode[1:0]; //114-115
assign debug_signal[80:79]       = net_slot_mode_cur[1:0]; //116-117
assign debug_signal[84:81]       = 4'd0;

assign debug_signal[127:85]      = 43'd0;


//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
endmodule
