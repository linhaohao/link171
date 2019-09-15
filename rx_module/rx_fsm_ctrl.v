//////////////////////////////////////////////////////////////////////////////////
// Company:         StarPoint
// Engineer:        GUO YAN 
// 
// Create Date:     16:17:12 07/27/2015 
// Module Name:     rx_fsm_ctrl 
// Project Name:    Rx synchronization correlation process;
// Target Devices:  FPGA - XC7K325T - FFG900; 
// Tool versions:   ISE14.6;   
// Description:
//                  
//
// Revision:        v1.0 - File Created
// Additional Comments: 
// 1. 
// 2.
// 3. 
//
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

module rx_fsm_ctrl(
//// clock/reset ////
input               logic_clk_in,               // 200MHz logic clock
input               logic_rst_in, 

//sync signals
input               coarse_syn_success,
input[4:0]          coarse_position,		   //这个值一直在变，因此只有数据在粗同步状态成功之后将数值存入，其余时刻均不采用。故将这个值的赋值定在粗同步检测到粗同步成功的位置

input               tr_syn_finish,
input               tr_syn_success,
input[6:0]          tr_position,

//input data 
input               de_bit_in,
input[8:0]          rx_slot_length,

//output syn signals
output              tr_syn_en_out,              // 启动精同步的使能信号
output              coarse_flag_out,           // 用来指示粗同步状态
output              tr_flag_out,               // 用来指示精同步状态

//output hop frequence signals
//output              time_slot_data_en,         // 1: 表明为当前时隙的数据段   0： 表明为当前时隙的同步段
output[9:0]         rx_freq_ram_addr_out,        // 读接收频率表地址信号
output              rx_freq_ram_rd_out,
input [9:0]         rx_freq_pn_addr_ini_in,     //ul freq and pn ram pattern initial addr
input               rx_freq_pn_ini_en_in,       //ul freq and pn ram pattern initial addr update enable

//output hop frequence signals
output              rx_data_valid_out,         // 数据使能信号
output[31:0]        rx_data_out,               // 输出32-bit数据调比特输出

output[199:0]       debug_signal
);
//////////////////////////////////////////////////////////////////////////////////
//// signals declaration ////
reg [8:0]            rx_fh_counter            = 9'd0;      // 跳频数计数器
reg [11:0]           rx_fh_period_counter     = 12'd0;     // 计数周期为一个跳频周期
reg [6:0]            tr_position_reg          = 7'd0;
       		                                  
reg [1:0]            rx_fh_ctrl_state;  
//wire[31:0]         coarse_cal_cnt_out;      
reg [31:0]           coarse_delay_count       = 32'd0;
reg [31:0]           tr_delay_count           = 32'd0;
reg [31:0]           delay_counter_1          = 32'd0;
reg [31:0]           delay_counter_2          = 32'd0;


reg [9:0]            rx_freq_ram_addr         = 10'd32;
reg                  rx_freq_ram_rd           = 1'b0;
                                              
reg                  rx_data_valid            = 1'b0;
reg [31:0]           rx_data                  = 32'd0;
wire[12:0]           bit_counter; 

reg                  coarse_freq_dly_en       = 1'b0;
reg[15:0]            coarse_freq_dly_cnt      = 16'd0;
reg                  coarse_freq_dly_pulse    = 1'b0;  

reg                  rx_13us_start            = 1'b0;                  
reg[15:0]            rx_13us_cnt              = 16'd0;

reg                  tr_syn_en                = 1'b0;  
reg                  coarse_flag              = 1'b0;
reg                  tr_flag                  = 1'b0;    

//////////////////////////////////////////////////////////////////////////////////
//// parameter defination ////
parameter            syn_code_num             = 8'd40;         //同步脉冲个数，即40个同步脉冲（32个粗同步+8个精同步脉冲）
parameter            tr_code_position         = 9'd32;         //tr位置
parameter            data_position            = 9'd40;         //数据位置
parameter            rx_13us_length           = 16'd2599;      //13us更新一次频率控制字 // 200M*13us=2600
parameter            rx_6_4us_length          = 13'd1279;      //13us更新一次频率控制字 // 200M*6.4us=1280
                                              
parameter            rx_freq_upd_delay        = 16'd98;        //freq update after coarse_sucess 100clk


//parameter            tr_position_length    = 24'd41599;   //tr绝对位置clk数 32pulse*65bit*20clk(10ns)=41600; 13us*32pulse/10ns=41600
//parameter            data_position_length  = 24'd51999;      //绝对位置clk数   40pulse*65bit*20clk(10ns)=52000; 13us*40pulse/10ns=52000


// 当检测到粗同步头后，需要延时的时钟周期数。
//parameter   coarse_delay_count          = (((tr_code_position - coarse_position - 1)*65 + 33)*40 - 18 - 20);	//delay counter
// -1  : coarse_position从0开始计数，tr_code_position从1~32来计算32个pulse
// 65  : 每个数据对应65bit; 13us/200ns=65
// 40  : 对于200MHz采样时钟，每个码元(1个bit)占200/5=40个时钟
// 33  : 粗同步码结束后还有6.6us的时间(33bit)
// 18  : 从第4个粗同步码实际移入后到真正产生粗同步信号需要10个clk延迟
// 20  : 将粗同步产生的定时时刻提前半个码元，即在以粗同步定时时刻为中心前后各半个码元中最佳采样时刻，保证不错过相关峰，保证tr_syn_en早于tr信号
// 无论粗同步的处理符号速率为5M还是25M，一个脉冲的13us是固定的


// 当完成精通同步头后，到接收数据需要延时的时钟周期数（注意这里要考虑进精同步的延时）。
//parameter tr_delay_count                =(((data_position - tr_code_position -1 ) * 65 + 32 - 4) * 40 - 38); 	
// -1  : 精同步计算会占用一个pulse
// 65  : 每个数据对应65bit; 
// 32  : 滑动两个bit窗, 
// 4   : 将DDC的NCO提前4个码元时间准备好。考虑可以去除(待定)，因为NCO的值，是通过coarse_success启动的计数器，因为粗同步保证误差在一个码元内
// 38  : tr同步，5个采样点选出最佳采样点延迟38clk
// 40  : 对于200MHz采样时钟，每个码元(1个bit)占200/5=40个时钟


//////////////////////////////////////////////////////////////////////////////////
//// (0) signal assigment ////
// 产生time_slot_data_en信号，1: 当前处于时隙的数据段； 0：当前处于时隙的同步段，实际测试阶段为FPGA数据接收模块产生的数据。
 //assign   time_slot_data_en             = (( rx_fh_ctrl_state == 2'd2 ) && (delay_counter_2[31:0] == tr_delay_count + tr_position_reg)) ? 1'b1 : 1'b0;
                                        
 assign   rx_data_valid_out             = rx_data_valid;
 assign   rx_data_out[31:0]             = rx_data[31:0];
                                        
 assign   rx_freq_ram_addr_out[9:0]     = rx_freq_ram_addr[9:0];
 assign   rx_freq_ram_rd_out            = rx_freq_ram_rd;    

 assign   tr_syn_en_out                 = tr_syn_en;    
 assign   coarse_flag_out               = coarse_flag;
 assign   tr_flag_out                   = tr_flag;    
//////////////////////////////////////////////////////////////////////////////////
//// (1)keep tr position 
always @(posedge logic_clk_in)
begin
    if(logic_rst_in)
        tr_position_reg[6:0]                <= 7'd0;
    else                                    
        begin                               
        if(tr_syn_success)                  
			begin                           
				tr_position_reg[6:0]        <= tr_position[6:0];
			end                             
		else                                
            tr_position_reg[6:0]            <= tr_position_reg[6:0];
        end
end


//////////////////////////////////////////////////////////////////////////////////
//// (2) FSM 
always @(posedge logic_clk_in)
begin
    if(logic_rst_in)
        begin
        rx_fh_counter[8:0]                          <= 9'd0;
        rx_fh_period_counter[11:0]                  <= 12'd0;
        rx_fh_ctrl_state                            <= 2'd0;
        delay_counter_1[31:0]                       <= 32'd0;
        delay_counter_2[31:0]                       <= 32'd0;
        tr_syn_en                                   <= 1'b0;
		coarse_flag                                 <= 1'b0;
		tr_flag                                     <= 1'b0;
        end
    else
        begin
        case(rx_fh_ctrl_state)
        2'd0:  // 粗同步状态
            begin
            rx_fh_counter[8:0]                      <= 9'd0;
            rx_fh_period_counter[11:0]              <= 12'd0;
            delay_counter_1[31:0]                   <= 32'd0;
            delay_counter_2[31:0]                   <= 32'd0;
            tr_syn_en                               <= 1'b0;
            if(coarse_syn_success == 1'b1)// 粗同步成功
                begin
					rx_fh_ctrl_state                <= 2'd1; // 转入精同步状态
					coarse_delay_count[31:0]        <= 32'd1282;//(((tr_code_position - coarse_position[4:0] - 1)*65 + 33)*40 - 18 - 20);	
				end                                 
			else                                    
                rx_fh_ctrl_state                    <= 2'd0;
            end                                     
                                                    
        2'd1:  // 精同步状态                        
            begin                                   
            if(delay_counter_1[31:0] <= coarse_delay_count[31:0]) //delay_counter_1用于粗同步成功后，帮助精同步找到开始位置
                delay_counter_1[31:0]               <= delay_counter_1[31:0] + 1'b1;
            else
                delay_counter_1[31:0]               <= delay_counter_1[31:0]; 
                
            if(delay_counter_1[31:0] == coarse_delay_count[31:0] )
				begin
					tr_syn_en                       <= 1'b1;
					coarse_flag                     <= ~coarse_flag; 
				end                                 
			else                                    
                tr_syn_en                           <= 1'b0;
				
			       
            if(tr_syn_finish == 1'b1)
                begin
                if(tr_syn_success == 1'b1)
                    begin
					tr_flag                         <= ~tr_flag; 
					tr_delay_count[31:0]            <= 32'd19282;//(((data_position - tr_code_position -1 ) * 65 + 32 - 4) * 40 - 38); 
                    rx_fh_ctrl_state                <= 2'd2;   // 精同步成功，则转入数据接收状态
                    end                             
                else                                
                    begin                           
                    rx_fh_ctrl_state                <= 2'd0;   // 精同步失败，则重新回到粗同步状态
                    end                             
                end                                 
            else                                    
                rx_fh_ctrl_state                    <= 2'd1;
            end                                     
                                                    
        2'd2:  // 接收数据状态                      
            begin                                       
            if(delay_counter_2[31:0] == (tr_delay_count[31:0] + tr_position_reg[6:0]))     // 当延迟tr_delay_count后，启动两个计数器rx_fh_counter和                                                                        
		    begin                                                            // rx_fh_period_counter，控制接收数据的频率切换和数据接收
                delay_counter_2[31:0]               <= delay_counter_2[31:0];  				
               // if(rx_fh_counter[8:0] >= (rx_slot_length[8:0] - syn_code_num + 9'd12) ) // 数据部分跳频计数完成,多增加12跳的解扩时间，保证后面的寄存器能够正确写完再开始读取
			    if(rx_fh_counter[8:0] >= (rx_slot_length[8:0] - syn_code_num ) ) //每一扩(耗费1.6us)在6.6us空闲时间内可完成，增加后使得rx_buffer的wr多移动12
                    begin                       				
                    rx_fh_period_counter[11:0]      <= 12'd0;
                    rx_fh_counter[8:0]              <= 9'd0;
                    rx_fh_ctrl_state                <= 1'b0;  //设定的fh_num - syn_code_num,接收完一个时隙的数据后，回到状态机的初始状态				
				   end
                else  //(1)
                    begin
                    if(rx_fh_period_counter[11:0] == rx_13us_length)//13us更新一次频率控制字 // 200M*13us=2600
                        begin
                        rx_fh_period_counter[11:0]  <= 12'd0;  
                        rx_fh_counter[8:0]          <= rx_fh_counter[8:0] + 1'b1; 						
                        end
                    else //(2)
                        begin
						rx_fh_period_counter[11:0]  <= rx_fh_period_counter[11:0] + 1'b1;
						rx_fh_counter[8:0]          <= rx_fh_counter[8:0];
                        end //end else(2)
						
                    rx_fh_ctrl_state                           <= 2'd2;
                    end //end else(1)
                end //end if(delay_counter_2 == tr_delay_count + tr_position_reg)  
           else
                begin
                delay_counter_2[31:0]                          <= delay_counter_2[31:0] + 1'b1;
                rx_fh_counter[8:0]                             <= 9'd0;
                rx_fh_period_counter[11:0]                     <= 12'd0;
                rx_fh_ctrl_state                               <= 2'd2;
                end                                            
            tr_syn_en                                          <= 1'b0;
            end                                          
        default:                                         
            begin                                        
            rx_fh_counter[8:0]                                 <= 9'd0;
            rx_fh_period_counter[11:0]                         <= 12'd0;
            rx_fh_ctrl_state                                   <= 2'd0;
            delay_counter_1[31:0]                              <= 32'd0;
            delay_counter_2[31:0]                              <= 32'd0;
            tr_syn_en                                          <= 1'b0;
            end
        endcase
        end

end

//////////////////////////////////////////////////////////////////////////////////
//// (3)控制跳频频率产生模块
//(3-0)freq/pn update start after coarse_sucess 100clk
always @(posedge logic_clk_in)
begin
    if(logic_rst_in) begin
        coarse_freq_dly_en                <= 1'b0;
    end 
    else if(coarse_freq_dly_cnt[15:0] == rx_freq_upd_delay)    begin
	    coarse_freq_dly_en                <= 1'b0;	   
    end	
	else if(coarse_syn_success == 1'b1) begin    
	    coarse_freq_dly_en                <= 1'b1;	
    end                              
end

always @(posedge logic_clk_in)
begin
    if(logic_rst_in) begin
        coarse_freq_dly_cnt[15:0]         <= 16'd0;
    end 
    else if(coarse_freq_dly_cnt[15:0] == rx_freq_upd_delay)   begin 
	   coarse_freq_dly_cnt[15:0]          <= 16'd0;   
    end	
	else if(coarse_freq_dly_en) begin             
	    coarse_freq_dly_cnt[15:0]         <= coarse_freq_dly_cnt[15:0] + 1'b1;	
    end                              
end

always @(posedge logic_clk_in)
begin
    if(logic_rst_in) begin
        coarse_freq_dly_pulse             <= 1'b0;
    end 
    else if(coarse_freq_dly_cnt[15:0] == rx_freq_upd_delay)   begin 
	    coarse_freq_dly_pulse             <= 1'b1;	   
    end	
	else  begin    
	    coarse_freq_dly_pulse             <= 1'b0;	
    end                              
end

//(3-1)13us update control
always @(posedge logic_clk_in)
begin
    if(logic_rst_in) begin
        rx_13us_start                     <= 1'b0;
    end 
    else if((rx_fh_counter[8:0] == (rx_slot_length[8:0] - syn_code_num - 1'b1)) && (rx_13us_cnt[15:0] == rx_13us_length))   begin //在接受最后一个数据前停止(-1)
	    rx_13us_start                     <= 1'b0;	   
    end	
	//else if(coarse_syn_success == 1'b1) begin  
    else if(coarse_freq_dly_pulse == 1'b1) begin 	
	    rx_13us_start                     <= 1'b1;	//rx_13us is ahead real 13us, 这个粗同步成功为止在6.6空闲中产生
    end                              
end

always @(posedge logic_clk_in)
begin
    if(logic_rst_in) begin
        rx_13us_cnt[15:0]                 <= 16'd0;
    end 
    else if(rx_13us_cnt[15:0] == rx_13us_length)   begin 
	   rx_13us_cnt[15:0]                  <= 16'd0;   
    end	
	else if(rx_13us_start) begin                  
	    rx_13us_cnt[15:0]                 <= rx_13us_cnt[15:0] + 1'b1;	
    end                              
end

always @(posedge logic_clk_in)
begin
    if(logic_rst_in) begin
        rx_freq_ram_rd                    <= 1'b0;
    end 
    else if(rx_13us_cnt[15:0] == rx_13us_length)   begin 
	   rx_freq_ram_rd                     <= 1'b1;   
    end	
	else begin                  
	   rx_freq_ram_rd                     <= 1'b0;
    end                              
end

//(3-2)freq/pn ping-pang ram
always @(posedge logic_clk_in)
begin
    if(logic_rst_in) begin  //makesure power reset intial
        rx_freq_ram_addr[9:0]             <= 10'd32;
    end 
	else if(rx_freq_pn_ini_en_in) begin
	    rx_freq_ram_addr[9:0]             <= rx_freq_pn_addr_ini_in[9:0]; //prevent ping-pang error when unsync
	end
	else if(rx_freq_ram_rd && (rx_freq_ram_addr[9:0] == {1'b0,(rx_slot_length[8:0] - 1'b1)})) begin //4~443(71)
	    rx_freq_ram_addr[9:0]             <= 10'd544; //ping-pang ram
	end
	else if(rx_freq_ram_rd && (rx_freq_ram_addr[9:0] == (rx_slot_length[8:0] + 9'd511))) begin //516~955(587)
	    rx_freq_ram_addr[9:0]             <= 10'd32; 	//no.0~31 for coarse syn in other process
    end
	else if(rx_freq_ram_rd)begin
	    rx_freq_ram_addr[9:0]             <= rx_freq_ram_addr[9:0] + 1'b1;
    end		
end


//////////////////////////////////////////////////////////////////////////////////
//// (4)output freq ctl and rx data 
assign  bit_counter[12:0] = rx_fh_period_counter[11:0] - 12'd160;  //数据和rx_fh_period_counter[11:0]对齐//一个跳频周期13us开始rx_fh_period_counter计数，提前4个bit发送跳频控制字, 4*200/5=160

always @(posedge logic_clk_in)
begin
    if(logic_rst_in)
        begin
        rx_data_valid                     <= 1'b0;
        end
    else
        begin
        if(rx_fh_period_counter[11:0] == 12'd1440)  //接收完32-bit数据(1280+160=1440)，配合bit_counter计数，产生数据有效信号
            rx_data_valid                 <= 1'b1;
        else                              
            rx_data_valid                 <= 1'b0;
        end
end

////(4-1)接收32-bit数据，存入rx_data寄存器中
// always @(posedge logic_clk_in)
// begin
    // if(logic_rst_in)
        // begin
        // rx_data[31:0]                     <= 32'd0;
        // end
    // else
        // begin          
        // if((bit_counter[12:0] >= 13'd0) && (bit_counter[12:0] <= rx_6_4us_length))  
            // begin
            // case(bit_counter[12:0])        //LSB first at tx module
            // 13'd0:      rx_data[0]        <= de_bit_in;  //1bit=200ns=200ns*200MZ=40clk
            // 13'd40:     rx_data[1]        <= de_bit_in;
            // 13'd80:     rx_data[2]        <= de_bit_in;  
            // 13'd120:    rx_data[3]        <= de_bit_in;
            // 13'd160:    rx_data[4]        <= de_bit_in;
            // 13'd200:    rx_data[5]        <= de_bit_in;  
            // 13'd240:    rx_data[6]        <= de_bit_in;
            // 13'd280:    rx_data[7]        <= de_bit_in;
            // 13'd320:    rx_data[8]        <= de_bit_in;  
            // 13'd360:    rx_data[9]        <= de_bit_in;
            // 13'd400:    rx_data[10]       <= de_bit_in;
            // 13'd440:    rx_data[11]       <= de_bit_in;  
            // 13'd480:    rx_data[12]       <= de_bit_in;
            // 13'd520:    rx_data[13]       <= de_bit_in;
            // 13'd560:    rx_data[14]       <= de_bit_in;  
            // 13'd600:    rx_data[15]       <= de_bit_in;
            // 13'd640:    rx_data[16]       <= de_bit_in;
            // 13'd680:    rx_data[17]       <= de_bit_in;  
            // 13'd720:    rx_data[18]       <= de_bit_in;
            // 13'd760:    rx_data[19]       <= de_bit_in;
            // 13'd800:    rx_data[20]       <= de_bit_in; 
            // 13'd840:    rx_data[21]       <= de_bit_in;  
            // 13'd880:    rx_data[22]       <= de_bit_in;
            // 13'd920:    rx_data[23]       <= de_bit_in;
            // 13'd960:    rx_data[24]       <= de_bit_in;  
            // 13'd1000:   rx_data[25]       <= de_bit_in;
            // 13'd1040:   rx_data[26]       <= de_bit_in;
            // 13'd1080:   rx_data[27]       <= de_bit_in;  
            // 13'd1120:   rx_data[28]       <= de_bit_in;
            // 13'd1160:   rx_data[29]       <= de_bit_in;
            // 13'd1200:   rx_data[30]       <= de_bit_in; 
            // 13'd1240:   rx_data[31]       <= de_bit_in;  
            // default:    rx_data[31:0]     <= rx_data[31:0];
            // endcase
            // end
        // else
            // rx_data[31:0]                 <= rx_data[31:0];
        // end
// end

always @(posedge logic_clk_in)
begin
    if(logic_rst_in)
        begin
        rx_data[31:0]                     <= 32'd0;
        end
    else
        begin          
        if((bit_counter[12:0] >= 13'd0) && (bit_counter[12:0] <= rx_6_4us_length))  
            begin
            case(bit_counter[12:0])        //MSB first at tx module
            13'd0:      rx_data[31]       <= de_bit_in;  //1bit=200ns=200ns*200MZ=40clk
            13'd40:     rx_data[30]       <= de_bit_in;
            13'd80:     rx_data[29]       <= de_bit_in;  
            13'd120:    rx_data[28]       <= de_bit_in;
            13'd160:    rx_data[27]       <= de_bit_in;
            13'd200:    rx_data[26]       <= de_bit_in;  
            13'd240:    rx_data[25]       <= de_bit_in;
            13'd280:    rx_data[24]       <= de_bit_in;
            13'd320:    rx_data[23]       <= de_bit_in;  
            13'd360:    rx_data[22]       <= de_bit_in;
            13'd400:    rx_data[21]       <= de_bit_in;
            13'd440:    rx_data[20]       <= de_bit_in;  
            13'd480:    rx_data[19]       <= de_bit_in;
            13'd520:    rx_data[18]       <= de_bit_in;
            13'd560:    rx_data[17]       <= de_bit_in;  
            13'd600:    rx_data[16]       <= de_bit_in;
            13'd640:    rx_data[15]       <= de_bit_in;
            13'd680:    rx_data[14]       <= de_bit_in;  
            13'd720:    rx_data[13]       <= de_bit_in;
            13'd760:    rx_data[12]       <= de_bit_in;
            13'd800:    rx_data[11]       <= de_bit_in; 
            13'd840:    rx_data[10]       <= de_bit_in;  
            13'd880:    rx_data[9]        <= de_bit_in;
            13'd920:    rx_data[8]        <= de_bit_in;
            13'd960:    rx_data[7]        <= de_bit_in;  
            13'd1000:   rx_data[6]        <= de_bit_in;
            13'd1040:   rx_data[5]        <= de_bit_in;
            13'd1080:   rx_data[4]        <= de_bit_in;  
            13'd1120:   rx_data[3]        <= de_bit_in;
            13'd1160:   rx_data[2]        <= de_bit_in;
            13'd1200:   rx_data[1]        <= de_bit_in; 
            13'd1240:   rx_data[0]        <= de_bit_in;  
            default:    rx_data[31:0]     <= rx_data[31:0];
            endcase
            end
        else
            rx_data[31:0]                 <= rx_data[31:0];
        end
end

//////////////////////////////////////////////////////////////////////////////////
////(5) debug ////
assign  debug_signal[0]                  = de_bit_in;
assign  debug_signal[2:1]                = rx_fh_ctrl_state[1:0];
assign  debug_signal[3]                  = coarse_syn_success;
assign  debug_signal[4]                  = tr_syn_en;
//assign  debug_signal[5]                  = tr_syn_success;
assign  debug_signal[11:5]               = tr_position_reg[6:0];
assign  debug_signal[16:12]              = 5'd0;

assign  debug_signal[28:17]              = rx_fh_period_counter[11:0];
assign  debug_signal[37:29]              = rx_fh_counter[8:0]; 
assign  debug_signal[38]                 = tr_syn_success;//rx_13us_start;
assign  debug_signal[48:39]              = rx_freq_ram_addr[9:0];
assign  debug_signal[61:49]              = bit_counter[12:0];
assign  debug_signal[62]                 = rx_data_valid;
assign  debug_signal[94:63]              = rx_data[31:0]; 

assign  debug_signal[95]                 = coarse_flag;
assign  debug_signal[96]                 = tr_flag;


                 
// assign  debug_signal[128:97]             = delay_counter_2[31:0];//coarse_delay_count[31:0]; 
// assign  debug_signal[160:129]            = delay_counter_1[31:0]; 
// assign  debug_signal[192:161]            = tr_delay_count[31:0];
// assign  debug_signal[193]                = rx_13us_start;//tr_syn_success;
//assign  debug_signal[199:194]            = 6'd0;

assign  debug_signal[199:97]            = 103'd0;



//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////

endmodule
