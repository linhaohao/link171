////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Company:         StarPoint
// Engineer:        GUO YAN 
// 
// Create Date:     15:26:30 07/26/2015   
// Module Name:     sync_timing_top 
// Project Name:    timing synchronization module
// Target Devices:  FPGA - XC7K325T - FFG900; 
// Tool versions:   ISE14.6;
// Description:     The module achieves three timing synchronization process,including:
//                  First, extern/GPS time synchronization;
//                  Second, coarse synchronization with NTR;
//                  Third, precise synchronization with NTR;
// 
// Revision:        v1.0 - File Created
// Additional Comments: 
// 1. one day = 112.5 epoch = 112.5*64 frame = 112.5*64*3*512 slot(7.8125ms); 
// 
//
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps


module sync_timing_top(
//// clock interface ////
input               logic_clk_in,                 // 200MHz logic clock
input               logic_rst_in,

////work mode
input [3:0]         net_work_mode,               // work mode 0:normal 1:mcbsp0 loop 2:mcbsp1 loop 3:fpga loop 4: rf loop

//// time information ////
input               timing_ctl,
input [31:0]        timing_slot_posi,            //  curret DSP offset according to ahead slot
input [31:0]        timing_slot_clknum,

//// time and status ////
output[31:0]        slot_time_out,                // slot timer
output              tx_slot_interrupt,            // 7.8125ms interrupt
output              tx_slot_dsp_interrupt,

output[7:0]         slot_statc_cnt_out,

//// debug signals ////
output[127:0]       debug_signal
	 
);


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//// signals declaration ////
//reg [31:0]        slot_length        = 32'd1562499; 
wire [31:0]       slot_length; 
reg [31:0]        slot_base_count    = 32'd0;
reg               slot_cnt_en        = 1'b0;
reg               slot_interrupt     = 1'b0;
                                     
reg [31:0]        slot_posi_count    = 32'd0;
reg [31:0]        slot_posi          = 32'd0;                     
reg               slot_posi_en       = 1'b0;
                                     
reg               slot_dsp_interrupt = 1'b0;
reg [8:0]         slot_dsp_cnt       = 9'd0;     


reg [7:0]         slot_statc_cnt     = 8'd0;
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//// parameter define ////
//parameter           SLOT_LENGTH         = 32'd1562499;       // 7.8125ms/5ns=1562500


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//// (0) signals assigment ////
	assign  tx_slot_interrupt             = slot_interrupt;
    assign  slot_time_out[31:0]           = slot_base_count[31:0];  // one slot time=7.8125ms
	
    assign  tx_slot_dsp_interrupt         = slot_interrupt || slot_dsp_interrupt; //last 20ns,align at slottimer =0;
	
	assign  slot_length[31:0]             = timing_slot_clknum[31:0];
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//// (1) config update ////
always@(posedge logic_clk_in)
begin
   if (logic_rst_in)   begin
       slot_posi[31:0]                    <= 32'd0;                     
      // slot_length[31:0]                  <= 32'd1562499; 
   end
	//offset from dsp adjust
   else if (timing_ctl)   begin
       slot_posi[31:0]                    <= timing_slot_posi[31:0]; 
       //slot_length[31:0]                  <= timing_slot_clknum[31:0]; 
   end
end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//// (2) slot_posi(TOA) adjust ////
always@(posedge logic_clk_in)
begin
   if (logic_rst_in)   begin
       slot_posi_en                       <= 1'b0;                     
   end
   else if (timing_ctl)   begin
       slot_posi_en                       <= 1'b1;   
   end
   else if(slot_posi_count[31:0]  == slot_posi[31:0]) begin
       slot_posi_en                       <= 1'b0;  //timing_ctl may same with slot_posi_cnt=slot_posi=32'd0
   end
end

always@(posedge logic_clk_in)
begin
   if (logic_rst_in)   begin
       slot_posi_count[31:0]              <= 32'd0;                    
   end
   else if(slot_posi_count[31:0]  == slot_posi[31:0]) begin
       slot_posi_count[31:0]              <= 32'd0;  
   end
   else if (slot_posi_en && (slot_base_count[31:0] == 32'd0))   begin
       slot_posi_count[31:0]              <= slot_posi_count[31:0] + 1'b1;   
   end
end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//// (3) slot counter enable ////
always@(posedge logic_clk_in)
begin
   if (logic_rst_in) begin
       slot_cnt_en                        <= 1'b0;                    
   end
   else if(net_work_mode[3:0] == 4'd1)begin
       slot_cnt_en                        <= 1'b0;    
   end
   else begin
       if(slot_posi_count[31:0] == slot_posi[31:0]) begin
           slot_cnt_en                    <= 1'b1;  
       end
       else if(slot_base_count[31:0] == slot_length[31:0]) begin
           slot_cnt_en                    <= 1'b0;  
       end
   end
end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//// (4) time counter ////
always@(posedge logic_clk_in)
begin
   if (logic_rst_in)   begin
       slot_base_count[31:0]              <= 32'd0;
   end
   else if (slot_base_count[31:0]  == slot_length[31:0])   begin   // 7.8125ms = one slot
	   slot_base_count[31:0]              <= 32'd0;
   end
   else if(slot_cnt_en)begin
	   slot_base_count[31:0]              <= slot_base_count[31:0] + 1'b1;
    end
end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//// (5) slot interrrupt to fpga////
always@(posedge logic_clk_in)
begin
   if (logic_rst_in)   begin
	   slot_interrupt                     <= 1'b0;
   end
   else if((slot_base_count[31:0]  == slot_length[31:0]) && (slot_posi[31:0] == 32'd0))  begin   // 7.8125ms = one slot
       slot_interrupt                     <= 1'b1;
   end
   else if ((slot_posi_count[31:0]  == slot_posi[31:0]) && (slot_posi[31:0] != 32'd0))  begin   // 7.8125ms = one slot
	   slot_interrupt                     <= 1'b1;
   end
   else begin
	   slot_interrupt                     <= 1'b0;
   end
end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//// (6) slot intterrupt to dsp(last 2us high level) ////
always@(posedge logic_clk_in)
begin
   if (logic_rst_in)   begin
	   slot_dsp_interrupt                 <= 1'b0;
   end
   else if (slot_dsp_cnt[8:0]  == 9'd398)  begin   // 7.8125ms = one dsp slot for last 395ns 
	   slot_dsp_interrupt                 <= 1'b0;
   end
   else if(slot_interrupt)begin
	   slot_dsp_interrupt                 <= 1'b1;
    end
end

always@(posedge logic_clk_in)
begin
   if (logic_rst_in)   begin
	   slot_dsp_cnt[8:0]                   <= 9'd0;
   end  
   else if (slot_dsp_cnt[8:0]  == 9'd398)  begin  
	   slot_dsp_cnt[8:0]                   <= 9'd0;
   end
   else if(slot_dsp_interrupt)begin
	   slot_dsp_cnt[8:0]                   <= slot_dsp_cnt[8:0]  + 1'b1;
    end
end


///////////slot interrupt statics test
always@(posedge logic_clk_in)
begin
   if (logic_rst_in)   begin
	   slot_statc_cnt[7:0]                   <= 8'd0;
   end  
   else if(slot_interrupt)begin
	   slot_statc_cnt[7:0]                   <= slot_statc_cnt[7:0]  + 1'b1;
    end
end

assign  slot_statc_cnt_out[7:0]              = slot_statc_cnt[7:0];





////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//// (7) debug signal /////
assign  debug_signal[31:0]                = slot_base_count[31:0];
assign  debug_signal[63:32]               = slot_posi[31:0];
assign  debug_signal[95:64]               = slot_posi_count[31:0];
assign  debug_signal[96]                  = slot_cnt_en;
assign  debug_signal[97]                  = slot_posi_en;
assign  debug_signal[98]                  = slot_interrupt;
assign  debug_signal[99]                  = tx_slot_dsp_interrupt;
assign  debug_signal[100]                 = timing_ctl;
assign  debug_signal[127:101]             = slot_length[26:0];


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
endmodule
