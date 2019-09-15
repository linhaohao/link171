`timescale 1ns / 1ps

module board_loop_test(
//// clock/reset ////
input            cfg_spi_clk,
input            clk_200M_in,
input            tx_slot_interrupt,

output           mcbsp_slaver_clkx,
output           mcbsp_slaver_fsx, 
output           mcbsp_slaver_mosi,

output[127:0]    debug_signal

);


//////////////////////////////////////////////////////////////////////////////////
//// (0) signal assigment ////
reg [17:0]          slaver_count = 18'd0;//18'b100110100110100011;
reg [31:0]          slaver_reg = 32'd0;
reg                 slaver_data = 1'b0;
wire[31:0]          slaver_out;

reg                 tx_mcbsp_interrupt        = 1'b0;  
reg [2:0]           mcbsp_slaver_en_reg       = 3'd0;  
reg                 mcbsp_slaver_en           = 1'b0;


////////mcbsp slaver source///////////////////
slaver_source_rom slaver_source_rom( //depth = 2048
  .clka(cfg_spi_clk),
  .addra(slaver_count[17:7]),
  .douta(slaver_out[31:0])
);

always@(negedge cfg_spi_clk)
begin
  if(mcbsp_slaver_en) begin 
     slaver_count[17:0]                    <= 18'd0;
  end
  else if (slaver_count[6:0] == 7'd35)   begin 
   // if (slaver_count[16:7] == 10'd712)   begin  //rom real depth (1+9 cfg)+(1+111 freq)*2+(1+444 pn) +(1 end) +(1 + 32rtt rsp) =713
    //if (slaver_count[16:7] == 10'd679)   begin  //rom real depth (1+9 cfg)+(1+111 freq)*2+(1+444 pn) +(1 end)  = 680
	//if (slaver_count[16:7] == 10'd1023)   begin  //for 3c3c3c3c auto send 
	//if (slaver_count[17:7] == 11'd1234)   begin  //rom real depth (1+9 cfg)+(1+111*2freq)+(1+111 ccsk)+(1+444*2 pn) +(1 end)  = 1235
    if (slaver_count[17:7] == 11'd1235)   begin  //rom real depth (1+10 cfg)+(1+111*2freq)+(1+111 ccsk)+(1+444*2 pn) +(1 end)  = 1236 
	 slaver_count[17:7]                   <= slaver_count[17:7];
      slaver_count[6:0]                    <= slaver_count[6:0];
    end
    else   begin
      slaver_count[17:7]                   <= slaver_count[17:7] + 1'b1;  
      slaver_count[6:0]                    <= 7'd0;	
    end
  end	 
  else begin
    slaver_count[6:0]                      <= slaver_count[6:0] + 1'b1; 
  end
end

always@(negedge cfg_spi_clk)
begin
  if (slaver_count[6:0] == 7'd2)   begin  
    slaver_reg[31:0]                       <= slaver_out[31:0];
  end
  else   begin
    slaver_reg[31:1]                       <= slaver_reg[30:0]; //mcbsp_reg[0] keep
    slaver_data                            <= slaver_reg[31]; //MSB first
  end
end

always@(posedge clk_200M_in)
begin
  if(tx_slot_interrupt)begin     
     tx_mcbsp_interrupt               <= ~tx_mcbsp_interrupt; //pulse->level for sampling in cross clock domain
  end
end	

always@(negedge cfg_spi_clk)
begin                      
     mcbsp_slaver_en_reg[2:0]         <= {mcbsp_slaver_en_reg[1:0],tx_mcbsp_interrupt};
end	

always@(negedge cfg_spi_clk)
begin
  if((mcbsp_slaver_en_reg[2:1] == 2'b01) || (mcbsp_slaver_en_reg[2:1] == 2'b10))begin //rising and falling all work  
     mcbsp_slaver_en                  <= 1'b1;
  end
  else begin
     mcbsp_slaver_en                  <= 1'b0;
  end
end

assign   mcbsp_slaver_clkx = cfg_spi_clk;
assign   mcbsp_slaver_fsx  = (slaver_count[6:0] == 7'd4) ? 1'b1:1'b0;	 
assign   mcbsp_slaver_mosi = slaver_data;

//////////////////////////////////////////////////////////////////////////////////
///////////debug
assign  debug_signal[0]            = mcbsp_slaver_clkx;
assign  debug_signal[1]            = mcbsp_slaver_fsx;
assign  debug_signal[2]            = mcbsp_slaver_mosi;

assign  debug_signal[3]            = tx_slot_interrupt;                                   
assign  debug_signal[4]            = tx_mcbsp_interrupt;
assign  debug_signal[5]            = mcbsp_slaver_en;
                                   
assign  debug_signal[12:6]         = slaver_count[6:0];
assign  debug_signal[22:13]        = slaver_count[16:7];

assign  debug_signal[54:23]        = slaver_out[31:0]; 
assign  debug_signal[86:55]        = slaver_reg[31:0];

assign  debug_signal[127:87]       = 41'd0;
                                   

//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////	
endmodule