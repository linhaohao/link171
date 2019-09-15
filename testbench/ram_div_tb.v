`timescale 1ns / 1ps

module ram_div_tb;

//sys_interface;
reg          clk_200M_in = 1'b0;

reg          freq_wr_in = 1'b0;
reg[7:0]     freq_addr_wr = 8'd0;
reg[31:0]    freq_hop_reg = 32'd1023; //32'h5555aaaa;

reg          ram_rd_en   = 1'b0;
reg[9:0]     ram_addr_rd = 10'd0;

wire[7:0]    dsp_freq_hop;

////////////////////////////clock configuration////////////////////////////
parameter CLK_200M_DELAY = 5; //200MHz  cycle=5ns
always #(2.5)      clk_200M_in = ~clk_200M_in;

	
initial begin
	// Initialize Inputs
	clk_200M_in = 0;
end

always @ (posedge clk_200M_in)	begin
if (freq_addr_wr[7:0]  == 8'd255) 
   freq_wr_in             <= 1'b0; 
else 
   freq_wr_in             <= 1'b1; 
end	

always @ (posedge clk_200M_in)	begin
if (freq_addr_wr[7:0]  == 8'd255) 
   freq_addr_wr[7:0]             <= 8'd255;
else if(freq_wr_in) 
   freq_addr_wr[7:0]             <= freq_addr_wr[7:0] + 1'b1; 
end	


always @ (posedge clk_200M_in)	begin
  if(freq_wr_in) 
   freq_hop_reg[31:0]             <= freq_hop_reg[31:0] - 1'b1; 
end	

always @ (posedge clk_200M_in)	begin
if (ram_addr_rd[9:0]   == 10'd1023) 
   ram_rd_en             <= 1'b0; 
else if(freq_addr_wr[7:0]  == 8'd255)
   ram_rd_en             <= 1'b1; 
end	

always @ (posedge clk_200M_in)	begin
if (ram_addr_rd[9:0]   == 10'd1023) 
   ram_addr_rd[9:0]             <= 10'd1023;
else if(ram_rd_en) 
   ram_addr_rd[9:0]             <= ram_addr_rd[9:0]  + 1'b1; 
end	


freq_hop_ram_buffer   u_freq_hop_ram_buffer
   (
	.clka(clk_200M_in),
	.wea(freq_wr_in),
	.addra(freq_addr_wr[7:0]),   //ping-pang depth = 2^10=1024(512*2);A set of 4 number=256
	.dina(freq_hop_reg[31:0]),

	.clkb(clk_200M_in),
	.enb(1'b1),
	.addrb(ram_addr_rd[9:0]),	
	.doutb(dsp_freq_hop[7:0]) //[7:0] [15:8] [23:16] [31:24]
	
	);
	
endmodule