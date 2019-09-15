//////////////////////////////////////////////////////////////////////////////////
// Company:         StarPoint
// Engineer:        GUO YAN 
// 
// Create Date:     10:16:25 07/27/2015  
// Module Name:     digital_correlate 
// Project Name:    Rx synchronization correlation process;
// Target Devices:  FPGA - XC7K325T - FFG900; 
// Tool versions:   ISE14.6;  
// Description:     The module achieves SYNC data of slot message correlation.
//                 
//
// Revision:        v1.0 - File Created
// Additional Comments: 
// 1. 32个bit(5M)数据移入寄存器后，需要17个clk延迟找出求和 + 1个clk延迟输出digital_success信号
// 
//
//
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps


module digital_correlate(
//// clock/reset ////
input               logic_clk_in,             // 200MHz
input               logic_rst_in,

//// data signals ////
input               bit_in_1,                  //25M rate
input               bit_in_2,                  //25M rate
input               bit_in_3,                  //25M rate
input               bit_in_4,                  //25M rate
input[127:0]        pattern_reg_buffer,

input[31:0]         sync_pn_in,
input               sync_pn_hop_en_in,

input[10:0]         threshold,             

//// output signals ////
output              correlate_success_out,    // 1：success   
output[10:0]        correlate_peak_out, 

output[199:0]       debug_signal 

);

//////////////////////////////////////////////////////////////////////////////////
//// signals declaration ////
reg [10:0]          correlate_peak        = 11'd0;    // 相关峰
reg                 correlate_success_t   = 1'b0;
reg                 correlate_success     = 1'b0; 
reg [10:0]          correlate_peak_reg    = 11'd0;

reg [5:0]           bit_count             = 6'd0;    // 计时周期为一个码元周期，即200ns
reg [4:0]           pn_cnt                = 5'd0;

reg [31:0]          cor_result[0:31];   // 异或相关结果

reg [5:0]           cor_sum0[0:31];     //每跳异或结果求和中间值
reg [5:0]           cor_sum1[0:31];
reg [5:0]           cor_sum2[0:31];
reg [5:0]           cor_sum3[0:31];
reg [5:0]           cor_sum4[0:31];
reg [5:0]           cor_sum5[0:31];
reg [5:0]           cor_sum6[0:31];
reg [5:0]           cor_sum7[0:31];
reg [5:0]           cor_sum8[0:31];
reg [5:0]           cor_sum9[0:31];
reg [5:0]           cor_unit_sum[0:31]; //每跳异或结果最终值

reg [10:0]          cor_pulse_sum[0:31]; //32跳6bit求和中间值,实际只用了14个

reg [64:0]			rega[0:31];
reg [64:0]			regb[0:31];
reg [64:0]			regc[0:31];
reg [64:0]			regd[0:31];
reg [64:0]			rega_s[0:31];
reg [64:0]			regb_s[0:31];
reg [64:0]			regc_s[0:31];
reg [64:0]			regd_s[0:31];

reg [31:0]			data_reg[0:31];  // 最高位data_reg[31][31],最低位data_reg[0][0]
wire[3:0]			pattern_reg[0:31];

reg[31:0]           correlate_code[0:31];

reg                 coarse_state          = 1'b0;
reg [6:0]           delay_cnt             = 7'd0;
//////////////////////////////////////////////////////////////////////////////////
//// parameter defination ////



//////////////////////////////////////////////////////////////////////////////////
//// (0) signal assigment ////
assign   correlate_success_out     = correlate_success;
assign   correlate_peak_out[10:0]  = correlate_peak_reg[10:0];

//////////////////hop channel selection
assign	pattern_reg[0] 			 = pattern_reg_buffer[127:124];
assign	pattern_reg[1] 			 = pattern_reg_buffer[123:120];
assign	pattern_reg[2] 			 = pattern_reg_buffer[119:116];
assign	pattern_reg[3] 			 = pattern_reg_buffer[115:112];
assign	pattern_reg[4] 			 = pattern_reg_buffer[111:108];
assign	pattern_reg[5] 			 = pattern_reg_buffer[107:104];
assign	pattern_reg[6] 			 = pattern_reg_buffer[103:100];
assign	pattern_reg[7] 			 = pattern_reg_buffer[99:96];
assign	pattern_reg[8] 			 = pattern_reg_buffer[95:92];
assign	pattern_reg[9] 			 = pattern_reg_buffer[91:88];
assign	pattern_reg[10] 		 = pattern_reg_buffer[87:84];
assign	pattern_reg[11] 		 = pattern_reg_buffer[83:80];
assign	pattern_reg[12] 		 = pattern_reg_buffer[79:76];
assign	pattern_reg[13] 		 = pattern_reg_buffer[75:72];
assign	pattern_reg[14] 		 = pattern_reg_buffer[71:68];
assign	pattern_reg[15] 		 = pattern_reg_buffer[67:64];
assign	pattern_reg[16] 		 = pattern_reg_buffer[63:60];
assign	pattern_reg[17] 		 = pattern_reg_buffer[59:56];
assign	pattern_reg[18] 		 = pattern_reg_buffer[55:52];
assign	pattern_reg[19] 		 = pattern_reg_buffer[51:48];
assign	pattern_reg[20] 		 = pattern_reg_buffer[47:44];
assign	pattern_reg[21] 		 = pattern_reg_buffer[43:40];
assign	pattern_reg[22] 		 = pattern_reg_buffer[39:36];
assign	pattern_reg[23] 		 = pattern_reg_buffer[35:32];
assign	pattern_reg[24] 		 = pattern_reg_buffer[31:28];
assign	pattern_reg[25] 		 = pattern_reg_buffer[27:24];
assign	pattern_reg[26] 		 = pattern_reg_buffer[23:20];
assign	pattern_reg[27] 		 = pattern_reg_buffer[19:16];
assign	pattern_reg[28] 		 = pattern_reg_buffer[15:12];
assign	pattern_reg[29] 		 = pattern_reg_buffer[11:8];
assign	pattern_reg[30] 		 = pattern_reg_buffer[7:4];
assign	pattern_reg[31] 		 = pattern_reg_buffer[3:0];

///////////////////////pn 
always @(posedge logic_clk_in)
begin
    if(logic_rst_in) begin:rst_correlate_code
	   integer t; 
	   for(t =0; t < 32; t = t + 1) 
        correlate_code[t]           <= 32'hf0f0f0f0; //prevent initial value nxor
    end
    else if(sync_pn_hop_en_in) begin	
	    correlate_code[pn_cnt]      <= sync_pn_in[31:0];
	end
end

always @(posedge logic_clk_in)
begin
    if(logic_rst_in) begin
        pn_cnt[4:0]                      <= 5'd0;
    end
    else if(sync_pn_hop_en_in) begin	
	    pn_cnt[4:0]                      <= pn_cnt[4:0]  + 1'b1;
	end
end
//////////////////////////////////////////////////////////////////////////////////
//// (1) ^ correlate ////
always @(posedge logic_clk_in)
begin
    if(logic_rst_in) begin
        bit_count[5:0]                <= 6'd0;
    end
    else if(bit_count[5:0] == 6'd39) begin// 200MHz*200ns=40  //7.8125ms mod 200ns !=0
	    bit_count[5:0]                <= 6'd0;
	end
	else begin
        bit_count[5:0]                <= bit_count[5:0] + 6'd1;
    end
end

always @(posedge logic_clk_in)
begin
    if(logic_rst_in)
        begin:  rst_digital_correlated
        integer k;
        for(k =0; k < 32; k = k + 1) begin
			cor_result[k]    <= 32'd0;
					         
            cor_sum0[k]      <= 6'd0;
			cor_sum1[k]      <= 6'd0;
			cor_sum2[k]      <= 6'd0;
			cor_sum3[k]      <= 6'd0;
			cor_sum4[k]      <= 6'd0;
			cor_sum5[k]      <= 6'd0;
			cor_sum6[k]      <= 6'd0;
			cor_sum7[k]      <= 6'd0;
			cor_sum8[k]      <= 6'd0;
			cor_sum9[k]      <= 6'd0;
			cor_unit_sum[k]  <= 6'd0;
			              
            cor_pulse_sum[k] <= 11'd0;
	    
	    	rega[k]  		 <= 65'd0;
			regb[k]  		 <= 65'd0;
			regc[k] 		 <= 65'd0;
			regd[k] 		 <= 65'd0;
			rega_s[k]  		 <= 65'd0;
			regb_s[k]  		 <= 65'd0;
			regc_s[k] 		 <= 65'd0;
			regd_s[k] 		 <= 65'd0;
			
			data_reg[k] 	 <= 32'd0;
		end
            
        correlate_peak[10:0] <= 11'd0;
        correlate_success_t  <= 1'b0;
        end
    
	else
       begin
       case(bit_count[5:0]) // 计算一次相关需要8个时钟周期，产生定时信号时，需考虑这部分的延时
		6'd3: 
			begin: shift_reg
				integer i;
				rega[0][64:0]      		  <= {rega[0][63:0],bit_in_1}; //first MSB
				regb[0][64:0]      		  <= {regb[0][63:0],bit_in_2}; //first MSB
				regc[0][64:0]      		  <= {regc[0][63:0],bit_in_3}; //first MSB
				regd[0][64:0]      		  <= {regd[0][63:0],bit_in_4}; //first MSB
				for(i = 1; i < 32; i = i + 1)
					begin
						rega[i][64:0] <= {rega[i][63:0],rega[i-1][64]};
						regb[i][64:0] <= {regb[i][63:0],regb[i-1][64]};
						regc[i][64:0] <= {regc[i][63:0],regc[i-1][64]};
						regd[i][64:0] <= {regd[i][63:0],regd[i-1][64]};
					end
			end
		6'd4: 
			begin: data_reg_process
				integer j;
				for(j = 0; j < 32; j = j + 1)
					begin
						case(pattern_reg[31-j])
							4'b0001: data_reg[j][31:0] <= rega[j][31:0];
							4'b0010: data_reg[j][31:0] <= regb[j][31:0];
							4'b0100: data_reg[j][31:0] <= regc[j][31:0];
							4'b1000: data_reg[j][31:0] <= regd[j][31:0];
							default: data_reg[j][31:0] <= 32'd0;
						endcase	
					end
			end					
			
        6'd5:   // 每跳并行异或
            begin:   xor_digital_correlated
			integer m;			
            for(m = 0; m < 32; m = m + 1) begin
                cor_result[m]            <= data_reg[31-m] ^~ correlate_code[m];  
			end
            correlate_success_t          <= 1'b0;  
            correlate_peak[10:0]         <= 11'd0; 
            end
			
        6'd6:   //并行计算每跳1的个数
            begin: bitsum1_digital_correlated
			integer n;
			for(n = 0; n < 32; n = n + 1) begin
                cor_sum0[n] <= cor_result[n][0]  + cor_result[n][1]  + cor_result[n][2]  + cor_result[n][3];            
                cor_sum1[n] <= cor_result[n][4]  + cor_result[n][5]  + cor_result[n][6]  + cor_result[n][7];        
                cor_sum2[n] <= cor_result[n][8]  + cor_result[n][9]  + cor_result[n][10] + cor_result[n][11];        
                cor_sum3[n] <= cor_result[n][12] + cor_result[n][13] + cor_result[n][14] + cor_result[n][15];      
            end			      
            correlate_success_t          <= 1'b0;
            correlate_peak[10:0]         <= 11'd0;    
            end
			
        6'd7:   //并行计算每跳1的个数
            begin: bitsum2_digital_correlated
			integer p;
            for(p = 0; p < 32; p = p + 1) begin		
                cor_sum4[p] <= cor_result[p][16] + cor_result[p][17] + cor_result[p][18] + cor_result[p][19];     
                cor_sum5[p] <= cor_result[p][20] + cor_result[p][21] + cor_result[p][22] + cor_result[p][23];     
                cor_sum6[p] <= cor_result[p][24] + cor_result[p][25] + cor_result[p][26] + cor_result[p][27];     
                cor_sum7[p] <= cor_result[p][28] + cor_result[p][29] + cor_result[p][30] + cor_result[p][31]; 
            end		
            correlate_success_t          <= 1'b0;
            correlate_peak[10:0]         <= 11'd0; 
            end
			
        6'd8:   //并行计算每跳1的个数
            begin: bitsum3_digital_correlated
			integer q;
			for(q = 0; q < 32; q = q + 1) begin	
                cor_sum8[q] <= cor_sum0[q] + cor_sum1[q] + cor_sum2[q] + cor_sum3[q];      
                cor_sum9[q] <= cor_sum4[q] + cor_sum5[q] + cor_sum6[q] + cor_sum7[q];  
            end
            correlate_success_t          <= 1'b0;
            correlate_peak[10:0]         <= 11'd0;
            end
			
        6'd9:   //并行计算每跳1的个数
            begin: bitsum4_digital_correlated
			integer r;
			for(r = 0; r < 32; r = r + 1) begin	
                cor_unit_sum[r] <= cor_sum8[r] + cor_sum9[r];
            end					
            correlate_success_t          <= 1'b0;
            correlate_peak[10:0]         <= 11'd0;
            end      
			
        6'd10:   //求和32个6bit数据      
            begin
               cor_pulse_sum[0]  <= cor_unit_sum[3]  + cor_unit_sum[2]  + cor_unit_sum[1]  + cor_unit_sum[0];
			   cor_pulse_sum[1]  <= cor_unit_sum[7]  + cor_unit_sum[6]  + cor_unit_sum[5]  + cor_unit_sum[4];
               cor_pulse_sum[2]  <= cor_unit_sum[11] + cor_unit_sum[10] + cor_unit_sum[9]  + cor_unit_sum[8];
			   cor_pulse_sum[3]  <= cor_unit_sum[15] + cor_unit_sum[14] + cor_unit_sum[13] + cor_unit_sum[12];
			   
			   correlate_success_t       <= 1'b0;  
               correlate_peak[10:0]      <= 11'd0; 
            end
			
        6'd11:  //求和32个6bit数据
            begin
			   cor_pulse_sum[4]  <= cor_unit_sum[19] + cor_unit_sum[18] + cor_unit_sum[17] + cor_unit_sum[16];
			   cor_pulse_sum[5]  <= cor_unit_sum[23] + cor_unit_sum[22] + cor_unit_sum[21] + cor_unit_sum[20];
               cor_pulse_sum[6]  <= cor_unit_sum[27] + cor_unit_sum[26] + cor_unit_sum[25] + cor_unit_sum[24];
			   cor_pulse_sum[7]  <= cor_unit_sum[31] + cor_unit_sum[30] + cor_unit_sum[29] + cor_unit_sum[28];
			   
			   correlate_success_t       <= 1'b0;  
               correlate_peak[10:0]      <= 11'd0; 
            end
			
		6'd12:  //求和32个6bit数据
            begin
			   cor_pulse_sum[8]  <= cor_pulse_sum[1] + cor_pulse_sum[0];
			   cor_pulse_sum[9]  <= cor_pulse_sum[3] + cor_pulse_sum[2];
			   
			   correlate_success_t       <= 1'b0;  
               correlate_peak[10:0]      <= 11'd0; 
            end
			
        6'd13:  //求和32个6bit数据
            begin
			   cor_pulse_sum[10]  <= cor_pulse_sum[5] + cor_pulse_sum[4];
			   cor_pulse_sum[11]  <= cor_pulse_sum[7] + cor_pulse_sum[6];
			   
			   correlate_success_t       <= 1'b0;  
               correlate_peak[10:0]      <= 11'd0; 
            end
			
        6'd14:  //求和32个6bit数据
            begin
			   cor_pulse_sum[12]  <= cor_pulse_sum[9]  + cor_pulse_sum[8];
			   cor_pulse_sum[13]  <= cor_pulse_sum[11] + cor_pulse_sum[10];
			   
			   correlate_success_t       <= 1'b0;  
               correlate_peak[10:0]      <= 11'd0; 
            end
			
        6'd15:  //求和32个6bit数据,得出相关峰
            begin 
			  correlate_peak[10:0] <= cor_pulse_sum[13] + cor_pulse_sum[12];				  
			  correlate_success_t  <= 1'b0;  
           end
		   
        6'd16:   // 比较相关峰与相关阈值
            begin
            if(threshold[10:0] <= correlate_peak[10:0])     
                correlate_success_t      <= 1'b1;
            else                         
                correlate_success_t      <= 1'b0;  
            end
			
		6'd23: 
			begin: shift_reg_2
				integer ii;
				rega_s[0][64:0]      		  <= {rega_s[0][63:0],bit_in_1}; //first MSB
				regb_s[0][64:0]      		  <= {regb_s[0][63:0],bit_in_2}; //first MSB
				regc_s[0][64:0]      		  <= {regc_s[0][63:0],bit_in_3}; //first MSB
				regd_s[0][64:0]      		  <= {regd_s[0][63:0],bit_in_4}; //first MSB
				for(ii = 1; ii < 32; ii = ii + 1)
					begin
						rega_s[ii][64:0] <= {rega_s[ii][63:0],rega_s[ii-1][64]};
						regb_s[ii][64:0] <= {regb_s[ii][63:0],regb_s[ii-1][64]};
						regc_s[ii][64:0] <= {regc_s[ii][63:0],regc_s[ii-1][64]};
						regd_s[ii][64:0] <= {regd_s[ii][63:0],regd_s[ii-1][64]};
					end
			end
		6'd24: 
			begin: data_reg_process_2
				integer jj;
				for(jj = 0; jj < 32; jj = jj + 1)
					begin
						case(pattern_reg[31-jj])
							4'b0001: data_reg[jj][31:0] <= rega_s[jj][31:0];
							4'b0010: data_reg[jj][31:0] <= regb_s[jj][31:0];
							4'b0100: data_reg[jj][31:0] <= regc_s[jj][31:0];
							4'b1000: data_reg[jj][31:0] <= regd_s[jj][31:0];
							default: data_reg[jj][31:0] <= 32'd0;
						endcase	
					end
			end					
			
        6'd25:   // 每跳并行异或
            begin:   xor_digital_correlated_2
			integer mm;			
            for(mm = 0; mm < 32; mm = mm + 1) begin
                cor_result[mm]            <= data_reg[31-mm] ^~ correlate_code[mm];  
			end
            correlate_success_t          <= 1'b0;  
            correlate_peak[10:0]         <= 11'd0; 
            end
			
        6'd26:   //并行计算每跳1的个数
            begin: bitsum1_digital_correlated_2
			integer nn;
			for(nn = 0; nn < 32; nn = nn + 1) begin
                cor_sum0[nn] <= cor_result[nn][0]  + cor_result[nn][1]  + cor_result[nn][2]  + cor_result[nn][3];            
                cor_sum1[nn] <= cor_result[nn][4]  + cor_result[nn][5]  + cor_result[nn][6]  + cor_result[nn][7];        
                cor_sum2[nn] <= cor_result[nn][8]  + cor_result[nn][9]  + cor_result[nn][10] + cor_result[nn][11];        
                cor_sum3[nn] <= cor_result[nn][12] + cor_result[nn][13] + cor_result[nn][14] + cor_result[nn][15];      
            end			      
            correlate_success_t          <= 1'b0;
            correlate_peak[10:0]         <= 11'd0;    
            end
			
        6'd27:   //并行计算每跳1的个数
            begin: bitsum2_digital_correlated_2
			integer pp;
            for(pp = 0; pp < 32; pp = pp + 1) begin		
                cor_sum4[pp] <= cor_result[pp][16] + cor_result[pp][17] + cor_result[pp][18] + cor_result[pp][19];     
                cor_sum5[pp] <= cor_result[pp][20] + cor_result[pp][21] + cor_result[pp][22] + cor_result[pp][23];     
                cor_sum6[pp] <= cor_result[pp][24] + cor_result[pp][25] + cor_result[pp][26] + cor_result[pp][27];     
                cor_sum7[pp] <= cor_result[pp][28] + cor_result[pp][29] + cor_result[pp][30] + cor_result[pp][31]; 
            end		
            correlate_success_t          <= 1'b0;
            correlate_peak[10:0]         <= 11'd0; 
            end
			
        6'd28:   //并行计算每跳1的个数
            begin: bitsum3_digital_correlated_2
			integer qq;
			for(qq = 0; qq < 32; qq = qq + 1) begin	
                cor_sum8[qq] <= cor_sum0[qq] + cor_sum1[qq] + cor_sum2[qq] + cor_sum3[qq];      
                cor_sum9[qq] <= cor_sum4[qq] + cor_sum5[qq] + cor_sum6[qq] + cor_sum7[qq];  
            end
            correlate_success_t          <= 1'b0;
            correlate_peak[10:0]         <= 11'd0;
            end
			
        6'd29:   //并行计算每跳1的个数
            begin: bitsum4_digital_correlated_2
			integer rr;
			for(rr = 0; rr < 32; rr = rr + 1) begin	
                cor_unit_sum[rr] <= cor_sum8[rr] + cor_sum9[rr];
            end					
            correlate_success_t          <= 1'b0;
            correlate_peak[10:0]         <= 11'd0;
            end      
			
        6'd30:   //求和32个6bit数据      
            begin
               cor_pulse_sum[0]  <= cor_unit_sum[3]  + cor_unit_sum[2]  + cor_unit_sum[1]  + cor_unit_sum[0];
			   cor_pulse_sum[1]  <= cor_unit_sum[7]  + cor_unit_sum[6]  + cor_unit_sum[5]  + cor_unit_sum[4];
               cor_pulse_sum[2]  <= cor_unit_sum[11] + cor_unit_sum[10] + cor_unit_sum[9]  + cor_unit_sum[8];
			   cor_pulse_sum[3]  <= cor_unit_sum[15] + cor_unit_sum[14] + cor_unit_sum[13] + cor_unit_sum[12];
			   
			   correlate_success_t       <= 1'b0;  
               correlate_peak[10:0]      <= 11'd0; 
            end
			
        6'd31:  //求和32个6bit数据
            begin
			   cor_pulse_sum[4]  <= cor_unit_sum[19] + cor_unit_sum[18] + cor_unit_sum[17] + cor_unit_sum[16];
			   cor_pulse_sum[5]  <= cor_unit_sum[23] + cor_unit_sum[22] + cor_unit_sum[21] + cor_unit_sum[20];
               cor_pulse_sum[6]  <= cor_unit_sum[27] + cor_unit_sum[26] + cor_unit_sum[25] + cor_unit_sum[24];
			   cor_pulse_sum[7]  <= cor_unit_sum[31] + cor_unit_sum[30] + cor_unit_sum[29] + cor_unit_sum[28];
			   
			   correlate_success_t       <= 1'b0;  
               correlate_peak[10:0]      <= 11'd0; 
            end
			
		6'd32:  //求和32个6bit数据
            begin
			   cor_pulse_sum[8]  <= cor_pulse_sum[1] + cor_pulse_sum[0];
			   cor_pulse_sum[9]  <= cor_pulse_sum[3] + cor_pulse_sum[2];
			   
			   correlate_success_t       <= 1'b0;  
               correlate_peak[10:0]      <= 11'd0; 
            end
			
        6'd33:  //求和32个6bit数据
            begin
			   cor_pulse_sum[10]  <= cor_pulse_sum[5] + cor_pulse_sum[4];
			   cor_pulse_sum[11]  <= cor_pulse_sum[7] + cor_pulse_sum[6];
			   
			   correlate_success_t       <= 1'b0;  
               correlate_peak[10:0]      <= 11'd0; 
            end
			
        6'd34:  //求和32个6bit数据
            begin
			   cor_pulse_sum[12]  <= cor_pulse_sum[9]  + cor_pulse_sum[8];
			   cor_pulse_sum[13]  <= cor_pulse_sum[11] + cor_pulse_sum[10];
			   
			   correlate_success_t       <= 1'b0;  
               correlate_peak[10:0]      <= 11'd0; 
            end
			
        6'd35:  //求和32个6bit数据,得出相关峰
            begin 
			  correlate_peak[10:0] <= cor_pulse_sum[13] + cor_pulse_sum[12];				  
			  correlate_success_t  <= 1'b0;  
           end
		   
        6'd36:   // 比较相关峰与相关阈值
            begin
            if(threshold[10:0] <= correlate_peak[10:0])     
                correlate_success_t      <= 1'b1;
            else                         
                correlate_success_t      <= 1'b0;  
            end
        default:
            begin:  digital_correlated_default
            integer s;
            for(s =0; s < 32; s = s + 1) begin
                cor_result[s]    <= 32'd0;
					         
                cor_sum0[s]      <= 6'd0;
			    cor_sum1[s]      <= 6'd0;
			    cor_sum2[s]      <= 6'd0;
			    cor_sum3[s]      <= 6'd0;
			    cor_sum4[s]      <= 6'd0;
			    cor_sum5[s]      <= 6'd0;
			    cor_sum6[s]      <= 6'd0;
			    cor_sum7[s]      <= 6'd0;
			    cor_sum8[s]      <= 6'd0;
			    cor_sum9[s]      <= 6'd0;
			    cor_unit_sum[s]  <= 6'd0;
			                  
                cor_pulse_sum[s] <= 11'd0;
				data_reg[s] 	 <= 32'd0;
			end
				
            correlate_peak[10:0]         <= 11'd0;
            correlate_success_t          <= 1'b0;
            end
        endcase
        end
end


//////////////////////////////////////////////////////////////////////////////////
//// (2)selec success from two success_t,make coarse_position constiant////
always @(posedge logic_clk_in)
begin
    if(logic_rst_in)
        begin
            coarse_state                  <= 1'b0;
			correlate_success             <= 1'b0;
			delay_cnt[6:0]                <= 7'd0;
		end
	else
	    case(coarse_state)
		1'b0:
		    begin
			    if(correlate_success_t) //two correlate_success_t in 200ns
				    begin
				    coarse_state          <= 1'b1;
				    correlate_success     <= 1'b1; //NO.1 success_t output correlate_success
					delay_cnt[6:0]        <= 7'd0;
				    end                   
				else                      
				    begin                 
				    coarse_state          <= coarse_state;
				    correlate_success     <= 1'b0;
					delay_cnt[6:0]        <= 7'd0;
					end
			end
		1'b1:
		    begin
				if(delay_cnt[6:0] == 7'd79)
				    begin
					coarse_state          <= 1'b0;
					correlate_success     <= 1'b0;
					delay_cnt[6:0]        <= 7'd0;
					end
				else
				    begin
					coarse_state          <= coarse_state;
					correlate_success     <= 1'b0;
					delay_cnt[6:0]        <= delay_cnt[6:0] + 7'd1;
				    end
			end
		endcase
end

////makesure correlate_success align at peak_reg
always @(posedge logic_clk_in)
begin
    if(logic_rst_in) begin
        correlate_peak_reg[10:0]     <= 11'd0;
    end                              
	else begin                       
        correlate_peak_reg[10:0]     <= correlate_peak[10:0];
    end
end



//////////////////////////////////////////////////////////////////////////////////
//// debug ////
assign debug_signal[5:0]                  = bit_count[5:0];
assign debug_signal[16:6]                 = correlate_peak_out[10:0];
assign debug_signal[17]                   = correlate_success_out;
assign debug_signal[18]                   = bit_in_1;
assign debug_signal[24:19]                = cor_unit_sum[0]; //6bit
assign debug_signal[56:25]                = data_reg[31]; //32bit
assign debug_signal[88:57]                = data_reg[0]; //32bit
assign debug_signal[120:89]               = correlate_code[0];//cor_result[31]; //32bit
//assign debug_signal[152:121]              = cor_result[0]; //32bit
assign debug_signal[121]                  = bit_in_2; 
assign debug_signal[122]                  = bit_in_3; 
assign debug_signal[123]                  = bit_in_4; 
assign debug_signal[127:124]              = pattern_reg[0];//4bit
assign debug_signal[131:128]              = pattern_reg[31];//4bit
assign debug_signal[147:132]              = correlate_code[31][15:0]; 
assign debug_signal[152:148]              = 5'd0;

assign debug_signal[158:153]              = cor_unit_sum[31]; //6bit
// assign debug_signal[169:159]              = threshold[10:0]; 
// assign debug_signal[199:170]              = 30'd0; 
assign debug_signal[190:159]              = cor_result[31]; //32bit
assign debug_signal[199:191]              = 9'd0;
/////////////////////////////////////////////////////////////////////////////////
/////////////modelsim memory observation
/*wire [31:0]data_reg0  ;
wire [31:0]data_reg1  ;
wire [31:0]data_reg2  ;
wire [31:0]data_reg3  ;
wire [31:0]data_reg4  ;
wire [31:0]data_reg5  ;
wire [31:0]data_reg6  ;
wire [31:0]data_reg7  ;
wire [31:0]data_reg8  ;
wire [31:0]data_reg9  ;
wire [31:0]data_reg10 ;
wire [31:0]data_reg11 ;
wire [31:0]data_reg12 ;
wire [31:0]data_reg13 ;
wire [31:0]data_reg14 ;
wire [31:0]data_reg15 ;
wire [31:0]data_reg16 ;
wire [31:0]data_reg17 ;
wire [31:0]data_reg18 ;
wire [31:0]data_reg19 ;
wire [31:0]data_reg20 ;
wire [31:0]data_reg21 ;
wire [31:0]data_reg22 ;
wire [31:0]data_reg23 ;
wire [31:0]data_reg24 ;
wire [31:0]data_reg25 ;
wire [31:0]data_reg26 ;
wire [31:0]data_reg27 ;
wire [31:0]data_reg28 ;
wire [31:0]data_reg29 ;
wire [31:0]data_reg30 ;
wire [31:0]data_reg31 ;



wire [31:0]correlate_code0  ;
wire [31:0]correlate_code1  ;
wire [31:0]correlate_code2  ;
wire [31:0]correlate_code3  ;
wire [31:0]correlate_code4  ;
wire [31:0]correlate_code5  ;
wire [31:0]correlate_code6  ;
wire [31:0]correlate_code7  ;
wire [31:0]correlate_code8  ;
wire [31:0]correlate_code9  ;
wire [31:0]correlate_code10 ;
wire [31:0]correlate_code11 ;
wire [31:0]correlate_code12 ;
wire [31:0]correlate_code13 ;
wire [31:0]correlate_code14 ;
wire [31:0]correlate_code15 ;
wire [31:0]correlate_code16 ;
wire [31:0]correlate_code17 ;
wire [31:0]correlate_code18 ;
wire [31:0]correlate_code19 ;
wire [31:0]correlate_code20 ;
wire [31:0]correlate_code21 ;
wire [31:0]correlate_code22 ;
wire [31:0]correlate_code23 ;
wire [31:0]correlate_code24 ;
wire [31:0]correlate_code25 ;
wire [31:0]correlate_code26 ;
wire [31:0]correlate_code27 ;
wire [31:0]correlate_code28 ;
wire [31:0]correlate_code29 ;
wire [31:0]correlate_code30 ;
wire [31:0]correlate_code31 ;

wire [31:0]cor_result0 ;
wire [31:0]cor_result1 ;
wire [31:0]cor_result2 ;
wire [31:0]cor_result3 ;
wire [31:0]cor_result4 ;
wire [31:0]cor_result5 ;
wire [31:0]cor_result6 ;
wire [31:0]cor_result7 ;
wire [31:0]cor_result8 ;
wire [31:0]cor_result9 ;
wire [31:0]cor_result10;
wire [31:0]cor_result11;
wire [31:0]cor_result12;
wire [31:0]cor_result13;
wire [31:0]cor_result14;
wire [31:0]cor_result15;
wire [31:0]cor_result16;
wire [31:0]cor_result17;
wire [31:0]cor_result18;
wire [31:0]cor_result19;
wire [31:0]cor_result20;
wire [31:0]cor_result21;
wire [31:0]cor_result22;
wire [31:0]cor_result23;
wire [31:0]cor_result24;
wire [31:0]cor_result25;
wire [31:0]cor_result26;
wire [31:0]cor_result27;
wire [31:0]cor_result28;
wire [31:0]cor_result29;
wire [31:0]cor_result30;
wire [31:0]cor_result31;


wire [5:0] cor_unit_sum0  ;
wire [5:0] cor_unit_sum1  ;
wire [5:0] cor_unit_sum2  ;
wire [5:0] cor_unit_sum3  ;
wire [5:0] cor_unit_sum4  ;
wire [5:0] cor_unit_sum5  ;
wire [5:0] cor_unit_sum6  ;
wire [5:0] cor_unit_sum7  ;
wire [5:0] cor_unit_sum8  ;
wire [5:0] cor_unit_sum9  ;
wire [5:0] cor_unit_sum10 ;
wire [5:0] cor_unit_sum11 ;
wire [5:0] cor_unit_sum12 ;
wire [5:0] cor_unit_sum13 ;
wire [5:0] cor_unit_sum14 ;
wire [5:0] cor_unit_sum15 ;
wire [5:0] cor_unit_sum16 ;
wire [5:0] cor_unit_sum17 ;
wire [5:0] cor_unit_sum18 ;
wire [5:0] cor_unit_sum19 ;
wire [5:0] cor_unit_sum20 ;
wire [5:0] cor_unit_sum21 ;
wire [5:0] cor_unit_sum22 ;
wire [5:0] cor_unit_sum23 ;
wire [5:0] cor_unit_sum24 ;
wire [5:0] cor_unit_sum25 ;
wire [5:0] cor_unit_sum26 ;
wire [5:0] cor_unit_sum27 ;
wire [5:0] cor_unit_sum28 ;
wire [5:0] cor_unit_sum29 ;
wire [5:0] cor_unit_sum30 ;
wire [5:0] cor_unit_sum31 ;

wire [10:0]cor_pulse_sum0  ;
wire [10:0]cor_pulse_sum1  ;
wire [10:0]cor_pulse_sum2  ;
wire [10:0]cor_pulse_sum3  ;
wire [10:0]cor_pulse_sum4  ;
wire [10:0]cor_pulse_sum5  ;
wire [10:0]cor_pulse_sum6  ;
wire [10:0]cor_pulse_sum7  ;
wire [10:0]cor_pulse_sum8  ;
wire [10:0]cor_pulse_sum9  ;
wire [10:0]cor_pulse_sum10 ;
wire [10:0]cor_pulse_sum11 ;
wire [10:0]cor_pulse_sum12 ;
wire [10:0]cor_pulse_sum13 ;

assign data_reg0[31:0]  = data_reg[31];
assign data_reg1[31:0]  = data_reg[30];
assign data_reg2[31:0]  = data_reg[29];
assign data_reg3[31:0]  = data_reg[28];
assign data_reg4[31:0]  = data_reg[27];
assign data_reg5[31:0]  = data_reg[26];
assign data_reg6[31:0]  = data_reg[25];
assign data_reg7[31:0]  = data_reg[24];
assign data_reg8[31:0]  = data_reg[23];
assign data_reg9[31:0]  = data_reg[22]; 
assign data_reg10[31:0]  = data_reg[21];
assign data_reg11[31:0]  = data_reg[20];
assign data_reg12[31:0]  = data_reg[19];
assign data_reg13[31:0]  = data_reg[18];
assign data_reg14[31:0]  = data_reg[17];
assign data_reg15[31:0]  = data_reg[16];
assign data_reg16[31:0]  = data_reg[15];
assign data_reg17[31:0]  = data_reg[14];
assign data_reg18[31:0]  = data_reg[13];
assign data_reg19[31:0]  = data_reg[12];
assign data_reg20[31:0]  = data_reg[11];
assign data_reg21[31:0]  = data_reg[10];
assign data_reg22[31:0]  = data_reg[9];
assign data_reg23[31:0]  = data_reg[8];
assign data_reg24[31:0]  = data_reg[7];
assign data_reg25[31:0]  = data_reg[6];
assign data_reg26[31:0]  = data_reg[5];
assign data_reg27[31:0]  = data_reg[4];
assign data_reg28[31:0]  = data_reg[3];
assign data_reg29[31:0]  = data_reg[2];
assign data_reg30[31:0]  = data_reg[1];
assign data_reg31[31:0]  = data_reg[0];

          
assign correlate_code0[31:0] = correlate_code[0];
assign correlate_code1[31:0] = correlate_code[1];
assign correlate_code2[31:0] = correlate_code[2];
assign correlate_code3[31:0] = correlate_code[3];
assign correlate_code4[31:0] = correlate_code[4];
assign correlate_code5[31:0] = correlate_code[5];
assign correlate_code6[31:0] = correlate_code[6];
assign correlate_code7[31:0] = correlate_code[7];
assign correlate_code8[31:0] = correlate_code[8];
assign correlate_code9[31:0] = correlate_code[9];
assign correlate_code10[31:0] = correlate_code[10];
assign correlate_code11[31:0] = correlate_code[11];
assign correlate_code12[31:0] = correlate_code[12];
assign correlate_code13[31:0] = correlate_code[13];
assign correlate_code14[31:0] = correlate_code[14];
assign correlate_code15[31:0] = correlate_code[15];
assign correlate_code16[31:0] = correlate_code[16];
assign correlate_code17[31:0] = correlate_code[17];
assign correlate_code18[31:0] = correlate_code[18];
assign correlate_code19[31:0] = correlate_code[19];
assign correlate_code20[31:0] = correlate_code[20];
assign correlate_code21[31:0] = correlate_code[21];
assign correlate_code22[31:0] = correlate_code[22];
assign correlate_code23[31:0] = correlate_code[23];
assign correlate_code24[31:0] = correlate_code[24];
assign correlate_code25[31:0] = correlate_code[25];
assign correlate_code26[31:0] = correlate_code[26];
assign correlate_code27[31:0] = correlate_code[27];
assign correlate_code28[31:0] = correlate_code[28];
assign correlate_code29[31:0] = correlate_code[29];
assign correlate_code30[31:0] = correlate_code[30];
assign correlate_code31[31:0] = correlate_code[31];
                     
assign cor_result0[31:0] = cor_result[0];
assign cor_result1[31:0] = cor_result[1];
assign cor_result2[31:0] = cor_result[2];
assign cor_result3[31:0] = cor_result[3];
assign cor_result4[31:0] = cor_result[4];
assign cor_result5[31:0] = cor_result[5];
assign cor_result6[31:0] = cor_result[6];
assign cor_result7[31:0] = cor_result[7];
assign cor_result8[31:0] = cor_result[8];
assign cor_result9[31:0] = cor_result[9];
assign cor_result10[31:0] = cor_result[10];
assign cor_result11[31:0] = cor_result[11];
assign cor_result12[31:0] = cor_result[12];
assign cor_result13[31:0] = cor_result[13];
assign cor_result14[31:0] = cor_result[14];
assign cor_result15[31:0] = cor_result[15];
assign cor_result16[31:0] = cor_result[16];
assign cor_result17[31:0] = cor_result[17];
assign cor_result18[31:0] = cor_result[18];
assign cor_result19[31:0] = cor_result[19];
assign cor_result20[31:0] = cor_result[20];
assign cor_result21[31:0] = cor_result[21];
assign cor_result22[31:0] = cor_result[22];
assign cor_result23[31:0] = cor_result[23];
assign cor_result24[31:0] = cor_result[24];
assign cor_result25[31:0] = cor_result[25];
assign cor_result26[31:0] = cor_result[26];
assign cor_result27[31:0] = cor_result[27];
assign cor_result28[31:0] = cor_result[28];
assign cor_result29[31:0] = cor_result[29];
assign cor_result30[31:0] = cor_result[30];
assign cor_result31[31:0] = cor_result[31];


assign cor_unit_sum0[5:0] = cor_unit_sum[0];
assign cor_unit_sum1[5:0] = cor_unit_sum[1];
assign cor_unit_sum2[5:0] = cor_unit_sum[2];
assign cor_unit_sum3[5:0] = cor_unit_sum[3];
assign cor_unit_sum4[5:0] = cor_unit_sum[4];
assign cor_unit_sum5[5:0] = cor_unit_sum[5];
assign cor_unit_sum6[5:0] = cor_unit_sum[6];
assign cor_unit_sum7[5:0] = cor_unit_sum[7];
assign cor_unit_sum8[5:0] = cor_unit_sum[8];
assign cor_unit_sum9[5:0] = cor_unit_sum[9];
assign cor_unit_sum10[5:0] = cor_unit_sum[10];
assign cor_unit_sum11[5:0] = cor_unit_sum[11];
assign cor_unit_sum12[5:0] = cor_unit_sum[12];
assign cor_unit_sum13[5:0] = cor_unit_sum[13];
assign cor_unit_sum14[5:0] = cor_unit_sum[14];
assign cor_unit_sum15[5:0] = cor_unit_sum[15];
assign cor_unit_sum16[5:0] = cor_unit_sum[16];
assign cor_unit_sum17[5:0] = cor_unit_sum[17];
assign cor_unit_sum18[5:0] = cor_unit_sum[18];
assign cor_unit_sum19[5:0] = cor_unit_sum[19];
assign cor_unit_sum20[5:0] = cor_unit_sum[20];
assign cor_unit_sum21[5:0] = cor_unit_sum[21];
assign cor_unit_sum22[5:0] = cor_unit_sum[22];
assign cor_unit_sum23[5:0] = cor_unit_sum[23];
assign cor_unit_sum24[5:0] = cor_unit_sum[24];
assign cor_unit_sum25[5:0] = cor_unit_sum[25];
assign cor_unit_sum26[5:0] = cor_unit_sum[26];
assign cor_unit_sum27[5:0] = cor_unit_sum[27];
assign cor_unit_sum28[5:0] = cor_unit_sum[28];
assign cor_unit_sum29[5:0] = cor_unit_sum[29];
assign cor_unit_sum30[5:0] = cor_unit_sum[30];
assign cor_unit_sum31[5:0] = cor_unit_sum[31];


assign cor_pulse_sum0[10:0] = cor_pulse_sum[0];
assign cor_pulse_sum1[10:0] = cor_pulse_sum[1];
assign cor_pulse_sum2[10:0] = cor_pulse_sum[2];
assign cor_pulse_sum3[10:0] = cor_pulse_sum[3];
assign cor_pulse_sum4[10:0] = cor_pulse_sum[4];
assign cor_pulse_sum5[10:0] = cor_pulse_sum[5];
assign cor_pulse_sum6[10:0] = cor_pulse_sum[6];
assign cor_pulse_sum7[10:0] = cor_pulse_sum[7];
assign cor_pulse_sum8[10:0] = cor_pulse_sum[8];
assign cor_pulse_sum9[10:0] = cor_pulse_sum[9];
assign cor_pulse_sum10[10:0] = cor_pulse_sum[10];
assign cor_pulse_sum11[10:0] = cor_pulse_sum[11];
assign cor_pulse_sum12[10:0] = cor_pulse_sum[12];
assign cor_pulse_sum13[10:0] = cor_pulse_sum[13];*/




//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
										    				    
endmodule
