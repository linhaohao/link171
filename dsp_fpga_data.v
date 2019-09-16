`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:06:06 04/13/2017 
// Design Name: 
// Module Name:    dsp_fpga_data 
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
module dsp_fpga_data(
	
		input clk_200m,
		input clk_50m,
		input clk_20m,
		input clk_25kHz,
		input cfg_rst, 

////////////mcbsp0/////////////////
		input   mcbsp0_slaver_clkx,	 
		input   mcbsp0_slaver_fsx,	 
		input   mcbsp0_slaver_mosi, 
			
		output  mcbsp0_master_clkr,	 
		output  mcbsp0_master_fsr,	 
		output  mcbsp0_master_miso,
	
		
		output reg     tx_send_start,//每接收完一个时隙的数据给出一个脉宽50ns脉冲
		input  [13:0]  read_addr,
		output [31:0]  send_data,
		input  slot_interrupt,
/////////////////mcbsp1/////////////
		input   mcbsp1_slaver_clkx,	 
		input   mcbsp1_slaver_fsx,	 
		input   mcbsp1_slaver_mosi, 
			
		output  mcbsp1_master_clkr,	 
		output  mcbsp1_master_fsr,	 
		output  mcbsp1_master_miso,
		
		output data_updated,
		output start_send,
		output [16:0] send_step,
		input [31:0] data_dsp,
		
		
		input  part_syn_en,
		output reg part_syn_start,
		
		output reg corase_end,
		output reg fine_end,
		output reg [31:0] corase_syn_pos,
		output reg [31:0] fine_syn_pos,
		output reg lose,
		output reg dsp_start_send,
		input  send40k_en,
		input  send10k_en,

		output reg flag_croase,
	   output reg flag_fine,
		output reg fine_data_flag,
		output reg decode_data_flag,
		output reg croase_data_flag,
		output reg tx_data_flag,

		output [255:0]  debug
    );

wire [31:0] dsp_tx_data;
wire tx_vaild_out;
reg  dsp_send_end;
reg  dsp_send_en;
wire dsp_data_en;
reg [2:0]  tx_vaild_reg               = 3'd0;
reg        tx_vaild                   = 1'b0; 
wire [14:0] rx_slot_data_length;
wire [31:0] doutb;
reg [13:0] ccsk_addr_wr;
reg [2:0] rx_ram_en_reg;
reg [13:0] rd_addr;
reg send_start;
reg testt;
reg send_start_reg;
wire [31:0] dsp_tx_data_1;
reg [3:0] send_start_dl;
reg [16:0] send_step_reg;
wire tx_vaild_out_1;
wire [127:0] debug_mcbsp0;
wire [127:0] debug_mcbsp1;
reg corase_syn_en;
reg tx_valid4_en;
reg tx_valid3_en;
reg fine_syn_en;
reg send_fine_en;


////////////////////////////////////////////////////////////////////////////////////

assign start_send = send_start || send_start_reg;
assign send_step = send_step_reg;

////////////////////////////test//////////////////////////////////////////////////
reg [31:0]dsp_dina_tb;
reg mcbsp_master_en_tb;
reg [31:0]mcbsp_data_counter;
reg [3:0]mcbsp_data_byte;

reg slot_interrupt_reg;
reg [31:0]slot_interrupt_delay_count;
always@(posedge clk_50m or posedge cfg_rst)//用于标志时隙的到来，当促发MCBSP发送数据之后就置0，等待下一次的时隙
begin
	if(cfg_rst)begin
		slot_interrupt_reg <= 1'b0;
	end
	else if(slot_interrupt)begin
		slot_interrupt_reg <= 1'b1;
	end
	else if(mcbsp_master_en_tb)begin//当使能MCBSP发送的脉冲来了之后就将其置零，等待下一次的时隙中断到来
		slot_interrupt_reg <= 1'b0;
	end
end

always@(posedge clk_50m or posedge cfg_rst)
begin
	if(cfg_rst)begin
		slot_interrupt_delay_count[31:0] <= 32'd0;
	end
	else if(mcbsp_master_en_tb)begin//当使能MCBSP发送的脉冲来了之后就将其置零，等待下一次的时隙中断到来再开始计时
		slot_interrupt_delay_count[31:0] <= 32'd0;
	end
	else if(slot_interrupt_delay_count[31:0] == 32'd24999)begin
		slot_interrupt_delay_count[31:0] <= 32'd0;
	end
	else if(slot_interrupt_reg)begin
		slot_interrupt_delay_count[31:0] <= slot_interrupt_delay_count[31:0] + 31'd1;
	end
end

always@(posedge clk_50m or posedge cfg_rst)//产生50/3M脉宽的脉冲mcbsp_master_en_tb
begin
	if(cfg_rst)begin
		mcbsp_master_en_tb <= 1'b0;
	end
	else if((dsp_tx_data[31:0] == 32'h88887777) && tx_vaild_out)begin//DSP主动发起接受数据指令
		mcbsp_master_en_tb <= 1'b1;
	end
	else if(slot_interrupt_delay_count[31:0] == 32'd24999)begin//时隙中断来了之后延迟500us后发送数据
		mcbsp_master_en_tb <= 1'b1;
	end
	else if(dsp_dina_tb[31:0] == 32'd2)begin
		mcbsp_master_en_tb <= 1'b0;
	end
end
always@(posedge clk_50m or posedge cfg_rst)//该计数器用于拓宽mcbsp_master_en_tb脉冲的脉宽
begin
	if(cfg_rst)begin
		dsp_dina_tb[31:0] <= 32'd0;
	end
	else if(dsp_dina_tb[31:0] == 32'd2)begin
		dsp_dina_tb[31:0] <= 32'd0;
	end
	else if(mcbsp_master_en_tb)begin	
		dsp_dina_tb[31:0] <= dsp_dina_tb[31:0] + 32'd1;
	end
end
///////////////////////////////////////////////////////////////////////发送的640BIT数据
always@(posedge clk_50m or posedge cfg_rst)
begin
	if(cfg_rst)begin
		mcbsp_data_counter[31:0] <= 32'd0;
		mcbsp_data_byte[3:0] <= 4'd0;
	end
	else if(slot_interrupt)begin
		mcbsp_data_counter[31:0] <= {mcbsp_data_byte,mcbsp_data_byte,mcbsp_data_byte,mcbsp_data_byte,mcbsp_data_byte,mcbsp_data_byte,mcbsp_data_byte,mcbsp_data_byte};
		mcbsp_data_byte[3:0] <= mcbsp_data_byte[3:0] + 4'd1;
	end
end
////////////////////////////////////////////////////////////////////////////////////
//一帧数据存储ROM表
reg [4:0]rom_addr;
reg [4:0]data_updated_counter;
wire [31:0]rom_dout;
always@(posedge clk_20m or posedge cfg_rst)
begin
	if(cfg_rst)begin
		data_updated_counter[4:0] <= 5'd0;
	end
	else if(data_updated_counter[4:0] == 5'd20)begin
		data_updated_counter[4:0] <= 5'd0;
	end
	else if(data_updated)begin
		data_updated_counter[4:0] <= data_updated_counter[4:0] + 5'd1;
	end
end
always@(posedge clk_20m or posedge cfg_rst)
begin
	if(cfg_rst)begin
		rom_addr[4:0] <= 5'd0;
	end
	else if(data_updated_counter[4:0] == 5'd0)begin
		rom_addr[4:0] <= 5'd0;
	end
	else if(data_updated)begin
		rom_addr[4:0] <= rom_addr[4:0] + 5'd1;
	end
end

//one_640bit one_640bit_rom(
//  .clka(clk_20m),//input clka
//  .addra(rom_addr[4:0]),//input [4 : 0] addra
//  .douta(rom_dout[31:0])//output [31 : 0] douta
//);

////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////

assign dsp_data_en = dsp_send_en && tx_vaild_out;//
assign rx_slot_data_length = part_syn_en ? 15'd4800: 15'd6500;

mcbsp_top(                                        //6个引脚 2个数据引脚，2个时钟引脚，2个帧起始引脚
		
    //// clock interface ////
    .mcbsp_clk_in(clk_20m),          // 20MHz logic clock
    .mcbsp_rst_in(cfg_rst),                  // 

    //// port ////
    .mcbsp_slaver_clkx(mcbsp0_slaver_clkx),	 
    .mcbsp_slaver_fsx(mcbsp0_slaver_fsx),	 
    .mcbsp_slaver_mosi(mcbsp0_slaver_mosi), 

    .mcbsp_master_clkr(mcbsp0_master_clkr),	 
    .mcbsp_master_fsr(mcbsp0_master_fsr),	 
    .mcbsp_master_miso(mcbsp0_master_miso),	

    //// DL data transmit ////
    //.tx_mcbsp_interrupt(tx_mcbsp_interrupt),
    .dsp_tx_data(dsp_tx_data[31:0]), 
	 .tx_vaild_out(tx_vaild_out),//标志dsp_tx_data[31:0]是有效的
	
    //// UL data receive ////
    .rx_mcbsp_interrupt(mcbsp_master_en_tb/*send_start_dl[3]*/), //rd interrupt
    .rx_slot_data_length(15'd20/*rx_slot_data_length*/),
    .dsp_rx_dina(mcbsp_data_counter[31:0]/*data_dsp*/),

    .rx_ram_addr_upd(data_updated),
    
    
    //// debug ////
    .debug_signal(debug_mcbsp0)

);


always@(posedge mcbsp0_slaver_clkx or posedge cfg_rst)   
begin
  if (cfg_rst)  begin
     send_start_reg                 <= 1'b0;
  end
  else begin
     send_start_reg                 <= send_start;
  end
end

always@(posedge mcbsp0_slaver_clkx or posedge cfg_rst)   
begin
  if (cfg_rst)  begin
     send_start                 <= 1'b0;
     lose                       <= 1'b0;
     send_step_reg				  <= 17'd0;
     part_syn_start             <= 1'b0;

  end  
///////////////////////8路数据/////////////////////////////////
  else if((dsp_tx_data[31:0] == 32'hAAAA0000) && tx_vaild_out)begin
     send_start                 <= 1'b1;
     send_step_reg				  <= 17'd0;
  end
  else if((dsp_tx_data[31:0] == 32'hAAAA1111) && tx_vaild_out)begin
     send_start                 <= 1'b1;
     send_step_reg				  <= 17'd1;
  end
	else if((dsp_tx_data[31:0] == 32'hAAAA2222) && tx_vaild_out)begin
     send_start                 <= 1'b1;
     send_step_reg				  <= 17'd2;
  end
  else if((dsp_tx_data[31:0] == 32'hAAAA3333) && tx_vaild_out)begin
     send_start                 <= 1'b1;
     send_step_reg				  <= 17'd3;
  end
  else if((dsp_tx_data[31:0] == 32'hAAAA4444) && tx_vaild_out)begin
     send_start                 <= 1'b1;
     send_step_reg				  <= 17'd4;
  end
  else if((dsp_tx_data[31:0] == 32'hAAAA5555) && tx_vaild_out)begin
     send_start                 <= 1'b1;
     send_step_reg				  <= 17'd5;
  end
	else if((dsp_tx_data[31:0] == 32'hAAAA6666) && tx_vaild_out)begin
     send_start                 <= 1'b1;
     send_step_reg				  <= 17'd6;
  end
  else if((dsp_tx_data[31:0] == 32'hAAAA7777) && tx_vaild_out)begin
     send_start                 <= 1'b1;
     send_step_reg				  <= 17'd7;
  end
  else if((dsp_tx_data[31:0] == 32'hAAAAAAAA) && tx_vaild_out)begin
  		send_start                 <= 1'b1;
  		part_syn_start 			   <= 1'b1;
  		send_step_reg			<= 17'd0;         
  		
  end
/////////////////////////////////////////////////////////////////////
  else if((dsp_tx_data[31:0] == 32'h66666666) && tx_vaild_out)begin
    send_start              <= 1'b1;
//    send_step_reg							<= 16'd2;
  end
  else if((dsp_tx_data[31:0] == 32'h55555555) && tx_vaild_out)begin
    send_start              <= 1'b1;
//     send_step_reg							<= 16'd0;
  end
  else if((dsp_tx_data[31:0] == 32'h11111111) && tx_vaild_out)begin
    lose                    <= 1'b1;
  end
  else begin
  	lose                    <= 1'b0;
    send_start              <= 1'b0;
    part_syn_start 			<= 1'b0;  
    send_step_reg			<= send_step_reg;
    
  end
end
///////////////////////////////////////////////////////////////////////////////
//接收到调整时隙中断的指令，进行时隙调整，指令之后接收的数据是用于调整时隙所用的数据
always@(posedge mcbsp0_slaver_clkx or posedge cfg_rst)   
begin
  if (cfg_rst)  begin
    corase_syn_en                 <= 1'b0;
  end
  else if(corase_end) begin
  	corase_syn_en 								<= 1'b0;
  end
  else if((dsp_tx_data[31:0] == 32'h44444444) && tx_vaild_out)begin
  	corase_syn_en 								<=1'b1;
  end
  else begin
    corase_syn_en                 <= corase_syn_en;
  end
end	


always@(posedge mcbsp0_slaver_clkx or posedge cfg_rst)  
begin
		if(cfg_rst) begin
				corase_syn_pos							<= 32'd0;
				corase_end                  <= 1'b0;
		end	
		else if(corase_syn_en && tx_vaild_out)begin
				corase_syn_pos             <= dsp_tx_data;
				corase_end                  <= 1'b1;
		end
		else begin
				corase_syn_pos             <= corase_syn_pos;
				corase_end                  <= 1'b0;
		end
end

////////////////////////////////////////////////////////////////////////////
always@(posedge mcbsp0_slaver_clkx or posedge cfg_rst)   
begin
  if (cfg_rst)  begin
     fine_syn_en                 <= 1'b0;     
     testt                        <=1'b0;
  end
  else if(fine_end) begin
  		fine_syn_en 								<= 1'b0;
  end
  else if((dsp_tx_data[31:0] == 32'h33333333) && tx_vaild_out )begin
  		fine_syn_en 								<=1'b1;  		
  		testt                       <=1'b1;
  end
  else begin
     fine_syn_en                  <= fine_syn_en;    
     testt												<= testt;
  end
end	

always@(posedge mcbsp0_slaver_clkx or posedge cfg_rst)  
begin
		if(cfg_rst) begin
				fine_syn_pos							<= 32'd0;
				fine_end                   <= 1'b0;
		end		
		else if(fine_syn_en && tx_vaild_out)begin
				fine_syn_pos              <= dsp_tx_data;
				fine_end                   <= 1'b1;
		end
		else begin
				fine_syn_pos              <= fine_syn_pos;
				fine_end                   <= 1'b0;
		end
end



////////////////////////////////////////////////////////////////////////////

always@(posedge mcbsp0_slaver_clkx or posedge cfg_rst)   
begin
  if (cfg_rst)  begin
     send_start_dl                 <= 4'b0;
  end
  else begin
     send_start_dl                 <= {send_start_dl[2:0],start_send};
  end
end

/////////////////////////////////////////////////////////////////////////////////////////////
////(2-1) Cross Clock Domain
always@(posedge clk_200m or posedge cfg_rst)
begin
  if (cfg_rst)  begin
     tx_vaild_reg[2:0]              <= 3'd0;
  end
  else begin
     tx_vaild_reg[2:0]              <= {tx_vaild_reg[1:0],tx_vaild_out};
  end
end	

always@(posedge clk_200m or posedge cfg_rst)
begin
  if (cfg_rst)  begin
     tx_vaild                       <= 1'b0;
  end                               
  else if(tx_vaild_reg[2:1] == 2'b01)begin                        
     tx_vaild                       <= 1'b1; //occupy 1 logic clk
  end
  else begin
     tx_vaild                       <= 1'b0;
  end
end	

//////////////////////////////////////////////////////////////////////////////////////////////

always@(posedge mcbsp0_slaver_clkx or posedge cfg_rst) begin
		if(cfg_rst) begin
				dsp_send_en <= 1'b0;
				dsp_start_send <= 1'b0;
		end
		else if(dsp_send_end) begin
				dsp_send_en <= 1'b0;
				dsp_start_send <= dsp_start_send;
		end
		else if((dsp_tx_data[31:0] == 32'h66669999) && tx_vaild_out)begin//MCBSB0口接收到32bit数据符合32'h66669999就开始接收数据
				dsp_send_en <= 1'b1;
				dsp_start_send <= 1'b1;//置1之后一直为1
		end
		else begin
				dsp_send_en <= dsp_send_en;
				dsp_start_send <= dsp_start_send;
		end
end


parameter ram_addr_length =14'd39;//40个32bit储存空间可以放1280bit
always@(posedge mcbsp0_slaver_clkx or posedge cfg_rst)
begin
	if (cfg_rst)  begin //make sure power reset 
       ccsk_addr_wr[13:0]                        <= 14'd0;
       dsp_send_end                              <= 1'b0; 
	end
	else if((ccsk_addr_wr[13:0] == ram_addr_length)&& dsp_data_en) begin  //444 pulse/4=111
       ccsk_addr_wr[13:0]                <= 14'd6000; // ping-pang buffer
       dsp_send_end                      <= 1'b1;
	end
	else if((ccsk_addr_wr[13:0] == (14'd6000+ram_addr_length))&& dsp_data_en) begin  //444 pulse/4=111
       ccsk_addr_wr[13:0]                <= 14'd0; // ping-pang buffer
       dsp_send_end                      <= 1'b1;
	end
	else if(dsp_data_en)begin
			 ccsk_addr_wr <= ccsk_addr_wr + 14'd1;
			 dsp_send_end <= 1'b0;
	end
	else begin
  		 ccsk_addr_wr <= ccsk_addr_wr;
  		 dsp_send_end <= 1'b0;
	end
end

mcbsp_rx_data rx_data_inst (
  .clka(mcbsp0_slaver_clkx), // input clka
  .wea(dsp_data_en), // input [0 : 0] wea
  .addra(ccsk_addr_wr), // input [13 : 0] addra
  .dina(dsp_tx_data[31:0]), // input [31 : 0] dina
  .clkb(clk_25kHz), // input clkb
  .enb(1'b1), // input enb
  .addrb(read_addr[13:0]), // input [13 : 0] addrb
  .doutb(send_data[31:0]) // output [31 : 0] doutb
);
//测试//////////////////////////////////////////////////////////////////////////////////////////
//m_creat I1(
//.sys_clk( clk_25kHz ),
//.sys_rst_n( ~cfg_rst ),
//.out(),
//.shift( send_data[31:0] )
//);
////////////////////////////////
reg [31:0] send_data_reg;
//assign send_data[31:0] = send_data_reg[31:0];
always@(posedge clk_25kHz or posedge cfg_rst)
begin
	if(cfg_rst) begin
		send_data_reg[31:0] <= 32'd0;
	end
	else if(read_addr[13:0]<14'd6000)begin
		send_data_reg[31:0] <= 32'hf0f0f0f0; 
	end
	else begin
		send_data_reg[31:0] <= 32'hff00ff00;
	end
end
////////////////////////////////////////////////////////////////////////////////////////////////
always@(posedge clk_20m or posedge cfg_rst)
begin
	if(cfg_rst) begin
			tx_send_start <= 1'b0;
	end
	else if((ccsk_addr_wr[13:0] == ram_addr_length)&& tx_vaild_out)begin
			tx_send_start <= 1'b1;
	end
	else if((ccsk_addr_wr[13:0] == (ram_addr_length+14'd6000))&& tx_vaild_out)begin
			tx_send_start <= 1'b1;
	end 
	else begin
			tx_send_start <= 1'b0;
	end
end

////////////////////////////////////////////////////////////////////////////////////////////////////
mcbsp_top mcbsp_inst1(
		
    //// clock interface ////
    .mcbsp_clk_in(clk_20m),          // 10MHz logic clock
    .mcbsp_rst_in(cfg_rst),                  // 

    //// port ////
    .mcbsp_slaver_clkx(mcbsp1_slaver_clkx),	 
    .mcbsp_slaver_fsx(mcbsp1_slaver_fsx),	 
    .mcbsp_slaver_mosi(mcbsp1_slaver_mosi), 

    .mcbsp_master_clkr(mcbsp1_master_clkr),	 
    .mcbsp_master_fsr(mcbsp1_master_fsr),	 
    .mcbsp_master_miso(mcbsp1_master_miso),	

    //// DL data transmit ////
    //.tx_mcbsp_interrupt(tx_mcbsp_interrupt),
    .dsp_tx_data(dsp_tx_data_1), 
	.tx_vaild_out(tx_vaild_out_1),
	
    //// UL data receive ////
    .rx_mcbsp_interrupt(), //rd interrupt
    .rx_slot_data_length(),
    .dsp_rx_dina(32'h87654321),

    .rx_ram_addr_upd(),
    
    //// debug ////
    .debug_signal(debug_mcbsp1[127:0])

);

reg [8:0] count_tx;
always@(posedge mcbsp0_slaver_clkx or posedge cfg_rst)   
begin
  if (cfg_rst)  begin
     count_tx <= 9'd0;
  end
  else if(count_tx == 9'd511) begin
  		count_tx <= count_tx;
  end
  else if((dsp_tx_data[31:0] == 32'h88888888) && tx_vaild_out)begin
     count_tx                 <= count_tx + 9'b1;
  end
  else begin
     count_tx <= count_tx;
  end
end	

reg [8:0] count_slot;
always@(posedge clk_50m or posedge cfg_rst) begin
	if(cfg_rst) begin
			count_slot <= 9'd0;
	end
	else if(slot_interrupt) begin
			count_slot <= count_slot + 9'd1;
	end
	else begin
			count_slot <= count_slot;
	end
end

always@(posedge mcbsp0_slaver_clkx or posedge cfg_rst)   
begin
  if (cfg_rst)  begin
     croase_data_flag                 <= 1'b0;
  end
  else if((dsp_tx_data[31:0] == 32'hAAAAAAAA) && tx_vaild_out)begin
  	  croase_data_flag 								<=1'b1;
  end
  else begin
     croase_data_flag                 <= 1'b0;
  end
end	
always@(posedge mcbsp0_slaver_clkx or posedge cfg_rst)   
begin
  if (cfg_rst)  begin
     flag_croase                 <= 1'b0;
  end
  else if((dsp_tx_data[31:0] == 32'h44444444) && tx_vaild_out)begin
  	  flag_croase 								<=1'b1;
  end
  else begin
     flag_croase                 <= 1'b0;
  end
end	
always@(posedge mcbsp0_slaver_clkx or posedge cfg_rst)   
begin
  if (cfg_rst)  begin
     flag_fine                 <= 1'b0;
  end
  else if((dsp_tx_data[31:0] == 32'h33333333) && tx_vaild_out)begin
  	  flag_fine 								<=1'b1;
  end
  else begin
     flag_fine                 <= 1'b0;
  end
end	
always@(posedge mcbsp0_slaver_clkx or posedge cfg_rst)   
begin
  if (cfg_rst)  begin
     fine_data_flag                 <= 1'b0;
  end
  else if((dsp_tx_data[31:0] == 32'h66666666) && tx_vaild_out)begin
  	  fine_data_flag 								<=1'b1;
  end
  else begin
     fine_data_flag                 <= 1'b0;
  end
end	
always@(posedge mcbsp0_slaver_clkx or posedge cfg_rst)   
begin
  if (cfg_rst)  begin
     decode_data_flag                 <= 1'b0;
  end
  else if((dsp_tx_data[31:0] == 32'h55555555) && tx_vaild_out)begin
  	  decode_data_flag 								<=1'b1;
  end
  else begin
     decode_data_flag                 <= 1'b0;
  end
end	

always@(posedge mcbsp0_slaver_clkx or posedge cfg_rst)   
begin
  if (cfg_rst)  begin
     tx_data_flag                 <= 1'b0;
  end
  else if((dsp_tx_data[31:0] == 32'h66669999) && tx_vaild_out)begin
  	  tx_data_flag 								<=1'b1;
  end
  else begin
     tx_data_flag                 <= 1'b0;
  end
end	


///////////////////////////////////////////////////////////////////////////独立模块，与外界没有关系
reg count_time_start;
reg [15:0] count_400us;
reg [14:0] count_interrupt;
always@(posedge mcbsp0_slaver_clkx or posedge cfg_rst)   
begin
  if (cfg_rst)  begin
     count_time_start                 <= 1'b0;
  end
  else begin
     count_time_start                 <= 1'b1;
  end
end	


always@(posedge clk_50m or posedge cfg_rst)begin
	if(cfg_rst) begin
			count_400us <= 16'd0;
	end
	else if((dsp_tx_data[31:0] == 32'hAAAAAAAA) && tx_vaild_out)begin
		  count_400us <= 16'd0;
	end 	
	else if(count_400us == 16'd19999)begin
			count_400us <= 16'd0;
	end
	else if(count_time_start)begin
			count_400us <= count_400us + 16'd1;
	end
	else begin
			count_400us <= count_400us;
	end
end

always@(posedge clk_50m or posedge cfg_rst) begin
	if(cfg_rst) begin
			count_interrupt <= 15'd0;
	end
	else if((dsp_tx_data[31:0] == 32'hAAAAAAAA) && tx_vaild_out)begin
		  count_interrupt <= 15'd0;
		  count_interrupt <= 15'd0;
	end 
	else if(count_400us == 16'd19999) begin
		  count_interrupt <= count_interrupt + 15'd1;
	end
	else begin
		  count_interrupt <= count_interrupt;
	end
end

//////////////////////////////////////////////////debug//////////////////////////////////////////////
assign debug[127:0] = debug_mcbsp0[127:0];
assign debug[128] = clk_25kHz;
assign debug[160:129] = send_data[31:0];
assign debug[174:161] = read_addr[13:0];
endmodule
