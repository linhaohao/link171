`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:17:09 11/01/2017 
// Design Name: 
// Module Name:    upp_io 
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
module upp_io(

///////////top input///////////////////////
		input clk_40m,
	  input cfg_rst,
		input [31:0] data_20m,
		input [31:0] data_40k,
		input sel,
/////////output to dsp		
		output [15:0] clk_data,
		output clk_dsp1,
		output clk_dsp2,		
/////////  dsp  input /////////////////////
		input clk_emif,
		input [15:0] dsp_data,
		
////////	output to top////////////////////			
		output [31:0] data_out,
		output data_valid,
		output [255:0] debug

    );

assign clk_dsp1 = sel ? clk_80k   : clk_40m;
assign clk_dsp2 = sel ? clk_40k   : clk_20m;
assign clk_data = data_dsp1;

assign data_valid = !fifo_empty;
//reg flag;

wire clk_rec;
reg [9:0] div_40k_count;
reg [9:0] div_80k_count;
reg clk_20m;
reg clk_40k;
reg clk_80k;
reg [31:0] send_dsp_data;
wire [15:0] data_dsp1;
wire [15:0] data_dsp2;
reg [15:0] data_dspI_40k;
reg [15:0] data_dspQ_40k;
reg [15:0] data_dspI_20m;
reg [15:0] data_dspQ_20m;
reg [15:0] send_dsp_dataI;
reg [15:0] send_dsp_dataQ;


wire [15:0] data_i;
wire [15:0] data_q;
reg [15:0] data_rec_i;
reg [15:0] data_rec_q;
wire [31:0] data_rec;
wire fifo_empty;
assign data_rec = {data_rec_q,data_rec_i};
////////////////////data  to  dsp /////////////////////////////////

always@(posedge clk_40m or posedge cfg_rst) begin
		if(cfg_rst) begin
				clk_20m <= 1'b0;
		end
		else begin
				clk_20m <= !clk_20m;
		end
end


always@(posedge clk_40m or posedge cfg_rst) begin
		if(cfg_rst) begin
				div_40k_count <= 10'd0;
		end
		else if(div_40k_count == 10'd499)begin
				div_40k_count <= 10'd0;
		end
		else begin
				div_40k_count <= div_40k_count + 10'd1;
		end
end

always@(posedge clk_40m or posedge cfg_rst) begin
		if(cfg_rst) begin
				clk_40k <= 1'b0;
		end
		else if(div_40k_count == 10'd499) begin
				clk_40k <= !clk_40k;
		end
		else begin
				clk_40k <= clk_40k;
		end
end

always@(posedge clk_40m or posedge cfg_rst) begin
		if(cfg_rst) begin
				div_80k_count <= 10'd0;
		end
		else if(div_80k_count == 10'd249)begin
				div_80k_count <= 10'd0;
		end
		else begin
				div_80k_count <= div_80k_count + 10'd1;
		end
end

always@(posedge clk_40m or posedge cfg_rst) begin
		if(cfg_rst) begin
				clk_80k <= 1'b0;
		end
		else if(div_80k_count == 10'd249) begin
				clk_80k <= !clk_80k;
		end
		else begin
				clk_80k <= clk_80k;
		end
end

//////////////////////////////////////////////////////////////////
always@(posedge clk_40m or posedge cfg_rst) begin
		if(cfg_rst) begin
				data_dspI_40k <= 16'd0;
				data_dspQ_40k <= 16'd0;	
				data_dspI_20m <= 16'd0;
				data_dspQ_20m <= 16'd0;			
		end
		else begin
				data_dspI_40k <= data_40k[15:0];
				data_dspQ_40k <= data_40k[31:16];	
				data_dspI_20m <= data_20m[15:0];
				data_dspQ_20m <= data_20m[31:16];
		end
end			
		
		
		
		
always@(posedge clk_40m or posedge cfg_rst) begin
		if(cfg_rst) begin
				send_dsp_dataI <= 16'd0;
		end
		else if(sel) begin
				send_dsp_dataI <= data_dspI_40k;
		end
		else begin
				send_dsp_dataI <= data_dspI_20m;
		end
end

always@(posedge clk_40m or posedge cfg_rst) begin
		if(cfg_rst) begin
				send_dsp_dataQ <= 16'd0;
		end
		else if(sel) begin
				send_dsp_dataQ <= data_dspQ_40k;
		end
		else begin
				send_dsp_dataQ <= data_dspQ_20m;
		end
end


genvar i;
generate
for(i=0;i<16;i=i+1)
begin:data_send

ODDR#(
.DDR_CLK_EDGE("OPPOSITE_EDGE"),
.INIT(1'b0),
.SRTYPE("SYNC")
)    U1_oddr_dsp_data1 
    (
	  .Q(data_dsp),
	  .C(clk_dsp2),	   
	  .CE(1'b1),
	  .D1(send_dsp_dataI[i]),                  // rising_edge => I
	  .D2(send_dsp_dataQ[i]),                  // falling_edge => Q
	  .R(1'b0),
	  .S(1'b0)	  
	 );
end
endgenerate	 

//////////////////////////////////////////////////////////////////////////////



//////////////////////data  from  dsp/////////////////////////////////////////


IBUFG  u3_bufg
   (
   .I(clk_emif),
   .O(clk_rec) 
   ); 

genvar j;

generate 
for(j=0;j<16;j=j+1)
begin:data_receive
		
IDDR #(
 .DDR_CLK_EDGE("OPPOSITE_EDGE"), 
 .INIT_Q1(1'b0),
 .INIT_Q2(1'b0), 
 .SRTYPE("SYNC") 
 ) IDDR_inst_emif (
 .Q1(data_i[j]), 
 .Q2(data_q[j]),
 .C(clk_rec),
 .CE(1'd1), 
 .D(dsp_data[j]), 
 .R(1'b0), 
 .S(1'd0) 
 );
end
endgenerate


always@(posedge clk_rec or posedge cfg_rst) begin
		if(cfg_rst) begin
				data_rec_i <= 16'd0;
				data_rec_q <= 16'd0;
		end
		else begin
				data_rec_i <= data_i;
				data_rec_q <= data_q;
		end
end


fifo_32x256 fifo_32x256_inst(
  .rst(cfg_rst), // input rst
  .wr_clk(clk_rec), // input wr_clk
  .rd_clk(clk_20m), // input rd_clk
  .din(data_rec), // input [15 : 0] din
  .wr_en(1'b1), // input wr_en
  .rd_en(~fifo_empty), // input rd_en
  .dout(data_out), // output [15 : 0] dout
  .full(), // output full
  .empty(fifo_empty) // output empty
);

////////////////////////////////////////////////////////////////////






endmodule
