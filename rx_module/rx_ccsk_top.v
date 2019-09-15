//////////////////////////////////////////////////////////////////////////////////
// Company:         StarPoint
// Engineer:        GUO YAN 
// 
// Create Date:     09:41:24 07/31/2015  
// Module Name:     rx_ccsk_top 
// Project Name:    Rx decramble process module;
// Target Devices:  FPGA - XC7K325T - FFG900; 
// Tool versions:   ISE14.6; 
// Description:     The module use defined S0~S31 to disspread data;
//
//
// Revision:        v1.0 - File Created
// Additional Comments: 
// (1) 将接收到的数据和s0~s31依次比较，峰值最大的就判定成对应序列
// (2) 解扩过程为一个流水线：pulse(1)+相关码使能信号(1)->读相关码(1,rom) --> 相关(1) --> 求和(4) --> 求峰值(1) --> 比较峰值判决(1)
// (3)一次相关码比较判决占用10个clk,32次比较占用320个clk,即一次6.4us数据判决需要320个clk(1.6us),在6.4us时间内可完成
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps


module rx_ccsk_top(
//// clock interface ////
input               logic_clk_in,                           // 200MHz logic clock
input               logic_rst_in,                           // 

//// control singals ////
input               data_pulse_in,                         //13us occupy 1clk
                      
//// data signals ////
output[4:0]         ccsk_ram_addr,                       
input [31:0]        data_ccsk_seq,                             

input [31:0]        data_ccsk_in,                       
output[7:0]         data_ccsk_out,
output              buffer_wr_out, 
output [23:0]       decccsk_dbg, 

//// debug ////
output[127:0]       debug_signal

    );


//////////////////////////////////////////////////////////////////////////////////
//// signals declaration //// 
reg [ 7:0]          data_ccsk_reg       = 8'd0;
reg                 data_ccsk_en        = 1'b0;
reg                 data_ccsk_en_dly    = 1'b0;

reg                 bit_cnt_en          = 1'b0;
reg [11:0]          bit_cnt             = 12'd0;
reg [4:0]		    corr_cnt            = 5'd0;  

reg [5:0]           cor_sum[0:10];
reg [31:0]          cor_result          = 32'd0;
reg [5:0]           correlate_peak      = 6'd0;
reg [5:0]           correlate_peak_max  = 6'd0;
reg [4:0]           ccsk_seq_position   = 5'd0;
reg [5:0]           ccsk_code_distance  = 6'd0;

reg [4:0]           ccsk_ram_addr_reg   = 5'h1f;
reg                 ccsk_ram_en         = 1'b0;


//////////////////////////////////////////////////////////////////////////////////
//// parameters define ////



//////////////////////////////////////////////////////////////////////////////////
//// (0) signals assigment ////
   assign  data_ccsk_out[7:0]           = data_ccsk_reg[7:0];
   assign  buffer_wr_out                = data_ccsk_en_dly;
   
   assign  ccsk_ram_addr[4:0]           = ccsk_ram_addr_reg[4:0];
   assign  decccsk_dbg                  = {2'b0,correlate_peak,2'b0,correlate_peak_max,2'b0,ccsk_code_distance};
   
//////////////////////////////////////////////////////////////////////////////////
//// (1) CCSK code(S0~S31) ram logic ////
always@(posedge logic_clk_in)
begin
   if (logic_rst_in)   begin
	  ccsk_ram_en                             <= 1'b0;
	end                                  
	//else if(bit_cnt[11:0]  == 12'd1) begin  
	else if((bit_cnt[11:0]  == 12'd0) && (bit_cnt_en == 1'b1)) begin  
	  ccsk_ram_en                             <= 1'b1;  
    end                                       
	else   begin                              
	  ccsk_ram_en                             <= 1'b0;  	
    end	                                      
end                                           
                                              
always@(posedge logic_clk_in)                 
begin                                         
   if (logic_rst_in)   begin                  
	  ccsk_ram_addr_reg[4:0]                  <= 5'h1f; //make sure no.1 addr =0
	end                                       
	else if(ccsk_ram_en) begin                
	  ccsk_ram_addr_reg[4:0]                  <= ccsk_ram_addr_reg[4:0] + 1'b1;
    end
end

//////////////////////////////////////////////////////////////////////////////////
//// (2) CCSK dis-spread logic ////
//解扩过程为一个流水线：bit_cnt_en(1)+相关码使能信号(1)->相关码地址(1,rom) --> 相关(1) --> 求和(4) --> 求峰值(1) --> 比较峰值判决(1)
//一次相关码比较判决占用10个clk,32次比较占用320个clk,即一次6.4us数据判决需要320个clk,在6.4us时间内可完成
always@(posedge logic_clk_in)
begin
   if (logic_rst_in)   begin
		bit_cnt_en                           <= 1'b0;
	end
    else if(data_pulse_in)begin
		bit_cnt_en                           <= 1'b1;
	end
    else if((bit_cnt[11:0]  == 12'd9) && (corr_cnt[4:0] == 5'd31))begin
		bit_cnt_en                           <= 1'b0;
    end
end

always@(posedge logic_clk_in)
begin
   if (logic_rst_in)   begin
        bit_cnt[11:0]                        <= 12'd0;
		corr_cnt[4:0]                        <= 5'd0;
	end
    else if(bit_cnt[11:0]  == 12'd9) begin
		bit_cnt[11:0]                        <= 12'd0;
		corr_cnt[4:0]                        <= corr_cnt[4:0] + 1'b1;  //计数32次相关
	end
    else if(bit_cnt_en)begin
        bit_cnt[11:0]                        <= bit_cnt[11:0] + 1'b1;
		corr_cnt[4:0]                        <= corr_cnt[4:0];
    end
end

always@(posedge logic_clk_in)
begin
   if (logic_rst_in)   begin:rst_rx_ccsk
        integer k;	  
	    for(k =0; k < 11; k = k + 1)
              cor_sum[k] <= 6'd0;  
	    cor_result[31:0]                      <= 32'd0;
	    correlate_peak[5:0]                   <= 6'd0;
	    correlate_peak_max[5:0]               <= 6'd0;
	    ccsk_seq_position[4:0]                <= 5'd0; 
	    ccsk_code_distance                    <= 6'd0;

	end  
    else if(data_pulse_in)begin                         
	    correlate_peak[5:0]                   <= 6'd0;
	    correlate_peak_max[5:0]               <= 6'd0;
	    ccsk_seq_position[4:0]                <= 5'd0;  
	    ccsk_code_distance                    <= 6'd0;
    end	
	else begin              
       case(bit_cnt[11:0])         	   
	    12'd3: begin                            
            cor_result[31:0]                  <= data_ccsk_in[31:0] ^ data_ccsk_seq[31:0];
		end                                   
		                                      
        12'd4: begin  // 计算1的个数                                          
            cor_sum[0]                        <= cor_result[0]  + cor_result[1]  + cor_result[2]  + cor_result[3];            
            cor_sum[1]                        <= cor_result[4]  + cor_result[5]  + cor_result[6]  + cor_result[7];        
            cor_sum[2]                        <= cor_result[8]  + cor_result[9]  + cor_result[10] + cor_result[11];        
            cor_sum[3]                        <= cor_result[12] + cor_result[13] + cor_result[14] + cor_result[15];           
        end                               
			                                  
        12'd5: begin  // 计算1的个数                                                
            cor_sum[4]                        <= cor_result[16] + cor_result[17] + cor_result[18]  + cor_result[19];     
            cor_sum[5]                        <= cor_result[20] + cor_result[21] + cor_result[22]  + cor_result[23];     
            cor_sum[6]                        <= cor_result[24] + cor_result[25] +  cor_result[26] + cor_result[27];     
            cor_sum[7]                        <= cor_result[28] + cor_result[29] +  cor_result[30] + cor_result[31]; 
        end                               
			                                  
        12'd6: begin  // 计算1的个数                                                  
            cor_sum[8]                        <= cor_sum[0] + cor_sum[1] + cor_sum[2] + cor_sum[3];      
            cor_sum[9]                        <= cor_sum[4] + cor_sum[5] + cor_sum[6] + cor_sum[7];  
        end                               
			                                  
        12'd7: begin // 计算1的个数                                            
            cor_sum[10]                       <= cor_sum[8] + cor_sum[9]; 
        end                               
			                                  
		12'd8: begin  // 计算相关峰                                                  
            correlate_peak[5:0]               <= 6'd32 - cor_sum[10];  
        end                               
			                                  
	    12'd9: begin //比较峰值                                                   
		    if(correlate_peak[5:0] > correlate_peak_max[5:0]) begin
			  correlate_peak_max[5:0]         <= correlate_peak[5:0];
			  ccsk_seq_position[4:0]          <= ccsk_ram_addr_reg[4:0];  //ccsk_ram_addr[4:0];  
			  ccsk_code_distance              <= (correlate_peak == 6'd0 )? 6'd0:correlate_peak - 6'd1; //与算法确定这种方法
			end                               
			else begin                        
		      correlate_peak_max[5:0]         <= correlate_peak_max[5:0];
			  ccsk_seq_position[4:0]          <= ccsk_seq_position[4:0]; 
			  ccsk_code_distance              <= ccsk_code_distance;
			end
		end
			
		default: begin:  rx_ccsk_default
            integer k;
	        for(k =0; k < 11; k = k + 1)
              cor_sum[k] <= 6'd0; 
			cor_result[31:0]                  <= 32'd0;
	        correlate_peak[5:0]               <= correlate_peak[5:0];
	        correlate_peak_max[5:0]           <= correlate_peak_max[5:0];
	        ccsk_seq_position[4:0]            <= ccsk_seq_position[4:0]; 
	        ccsk_code_distance                <= ccsk_code_distance; 
		end		
		endcase
	end
end

//////////////////////////////////////////////////////////////////////////////////
//always@(posedge logic_clk_in)
//begin
//   if (logic_rst_in)   begin
//		ccsk_code_distance                  <= 6'b0;
//	end
//    else if(data_pulse_in == 1'b1) begin
//    	ccsk_code_distance                  <= 6'd0;
//    end
//    else if((bit_cnt[11:0]  == 12'd9) && (correlate_peak[5:0] > correlate_peak_max[5:0]))begin
//    	if( correlate_peak == 6'd0 )
//    	    ccsk_code_distance              <= 6'd0;
//    	else 
//		    ccsk_code_distance              <= correlate_peak - 6'd1;;
//    end
//	else 
//	   ;
//end




//// (3) CCSK output logic ////
always@(posedge logic_clk_in)
begin
   if (logic_rst_in)   begin
		data_ccsk_en                           <= 1'b0;
	end
    else if((bit_cnt[11:0]  == 12'd9) && (corr_cnt[4:0] == 5'd31))begin
		data_ccsk_en                           <= 1'b1;
    end
	else begin
		data_ccsk_en                           <= 1'b0;
	end
end

always@(posedge logic_clk_in)
begin
   if (logic_rst_in)   begin
        data_ccsk_reg[7:0]                     <= 8'd0;
	end
    else if(data_ccsk_en )begin
        data_ccsk_reg[7:0]                     <= {ccsk_code_distance[4:2],ccsk_seq_position[4:0]};
    end
end

always@(posedge logic_clk_in)
begin
   if (logic_rst_in)   begin
		data_ccsk_en_dly                       <= 1'b0;
	end                                        
	else begin                                 
		data_ccsk_en_dly                       <= data_ccsk_en;
	end
end

//////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////
//// (4)deubg signals ////
assign  debug_signal[0]                        = data_pulse_in;
assign  debug_signal[1]                        = bit_cnt_en;
assign  debug_signal[13:2]                     = bit_cnt[11:0];
assign  debug_signal[19:14]                    = correlate_peak[5:0];
assign  debug_signal[24:20]                    = corr_cnt[4:0];
assign  debug_signal[29:25]                    = data_ccsk_reg[4:0];
assign  debug_signal[30]                       = data_ccsk_en_dly;
assign  debug_signal[31]                       = ccsk_ram_en;
assign  debug_signal[36:32]                    = ccsk_ram_addr_reg[4:0];

assign  debug_signal[42:37]                   = ccsk_code_distance;
assign  debug_signal[127:43]                  = 85'd0;





//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
endmodule
