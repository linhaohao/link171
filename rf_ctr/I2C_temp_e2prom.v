//////////////////////////////////////////////////////////////////////////////////
// Company:        StarPoint
// Engineer:       YanFei 
// 
// Create Date:     09/09/2015
// Module Name:    I2C_WR_RD 
// Project Name:   Common I2C design
// Tool versions:  ISE14.6
// Description:    随机读、写i2c设备的一个寄存器值
//
// Additional Comments:每次读或者写一个i2c寄存器的值，读、写操作时，同时给定要设置的寄存器地址和
//操作得而数据；读或者写操作进行时，直到完成本次读或写流程，才会响应下一次的读、写操作；i2c_ready为
//指示信号，为低时表示正在读、写操作中；为高才会响应外部使能控制。	
//tmp100器件I2C读取时，连续读2个字节，此模块将读取的bit个数设为可设
//		如 ：2byte时 RD_BIT_LENTH = 16
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps


module I2C_temp_e2prom(
// clock & reset
input               i2c_scl_in,                             // 400KHz 2倍于SCL
// input               i2c_scl_div2,                           // i2c_scl_in 2分频
input               i2c_rst_in,
input				i2c_eprom,								//“1”为eprom写入

// operation & register
input               i2c_wr_rd,                              // '1'-read, '0'-write需要i2c_wp_enable同时使能
input               i2c_wp_enable,                          // '1' enable
input [ 31:0]       i2c_reg_in,								//[15:8]高8位写入地址，低8位写入数据；
															//读操作时低8位数据值无效
output[ 15:0]       i2c_reg_out,                            // I2C 读取的数据
output				i2c_rd_valid,							//I2C读取上升沿时有效

// I2C interface
output              i2c_scl_out,
inout               i2c_sda_out,
output				i2c_sda_slect,


output              i2c_ready,                             // I2C 空闲标识，高为空闲态

// debug
output[31:0]        debug_signal

    );


//////////////////////////////////////////////////////////////////////////////////
//// signal declaration ////
reg [ 3:0]          i2c_state = 4'd0;

reg [ 15:0]         i2c_sda_data = 16'd0;			//I2C读取的数据
reg [ 15:0]         i2c_sda_data_r = 16'd0;			//I2C读取的数据
reg					i2c_rd_valid_r = 1'b0;			

reg                 i2c_sda = 1'd1;
reg	[7:0]			i2c_rd_lenth = 8'd16;

reg					i2c_ready_r = 1'b1 ;

reg                 i2c_scl_div2 = 1'd0;
reg                 i2c_sda_flag = 1'd0;    		//低进行发送，默认为发送
wire                i2c_sda_din;
reg [ 7:0]          i2c_count = 8'd0;
reg                 i2c_rd_first = 1'b0;

reg			uart_rd_ctr		=	1'b0;	//用来区分定时读和命令读取，1为命令读取

reg [7:0]			conf_data_in = 8'h0;			//i2c_reg_in[15:8]高8位写入的地址
													
reg [15:0]			conf_addr_in = 16'h0;			//i2c_reg_in[15:8]高8位写入的地址
													//读操作时低8位数据值无效
reg [ 7:0]          byte_command = 8'd0;			//实时需要发送的byte数据

reg [2:0]			conf_byte_cnt = 3'd0;			//配置的读、写byte个数
reg [3:0]			stop_delay_cnt = 4'd0;			//停止标志前的拉低SCL个数
													
//////////////////////////////////////////////////////////////////////////////////
//// parameter ////
// I2C state machine
parameter           i2c_state_rst       = 4'h0;              
parameter           i2c_state_start     = 4'h1;              
parameter           i2c_state_byte_wr   = 4'h2;              
parameter           i2c_state_byte_rd   = 4'h3;              
parameter           i2c_state_sack      = 4'h4;              
parameter           i2c_state_mack      = 4'h5;              
parameter           i2c_state_stop      = 4'h6;              
parameter           i2c_state_idle      = 4'h7;    
parameter           i2c_temp_rd_mack    = 4'h8;  

parameter			RD_DEVICE			= 8'h91,         
					WR_DEVICE			= 8'h90,        
					E2C_WR_DEVICE		= 8'ha0,        
					E2C_RD_DEVICE		= 8'ha1;      

parameter			RD_BIT_LENTH		= 8'd16;	//一次读操作，读取的bit个数

//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
///// signal assigment ////
   assign  i2c_scl_out                 	= i2c_scl_div2;						//I2C速率是输入速率的2分频
   assign  i2c_ready					= i2c_ready_r;
	
	// assign  i2c_sda_out                 = i2c_sda_flag ? 1'bZ : i2c_sda;	//双向口输出数据
	// assign  i2c_sda_din                 = i2c_sda_out;	 					//双向口输入数据

    assign  i2c_reg_out[15:0]           = i2c_sda_data_r[15:0];
	assign	i2c_rd_valid				=	i2c_rd_valid_r;
	
	assign	i2c_sda_slect	=			i2c_sda_flag;	//为1时，SDA为输入
//**********调用3态原语
   IOBUF #(
      .DRIVE(12), // Specify the output drive strength
      .IBUF_LOW_PWR("TRUE"),  // Low Power - "TRUE", High Performance = "FALSE" 
      .IOSTANDARD("DEFAULT"), // Specify the I/O standard
      .SLEW("SLOW") // Specify the output slew rate
   ) IOBUF_inst (
      .O(i2c_sda_din),      // Buffer output
      .IO(i2c_sda_out),     // Buffer inout port (connect directly to top-level port)
      .I(i2c_sda),      	// Buffer input
      .T(i2c_sda_flag)      // 3-state enable input, high=input, low=output
   );						// T = 1 则inout为输入，否则为输出
  
//////////////////////////////////////////////////////////////////////////////////
//// (1) I2C timing count ////
always@(posedge i2c_scl_in or posedge i2c_rst_in)
begin
  if (i2c_rst_in)   begin
    i2c_scl_div2                        <= 1'b1;
  end
  else   begin
    i2c_scl_div2                        <= !i2c_scl_div2;   // divider=2
  end
end
//////////////////////////////////////////////////////////////////////////////////
//// (2) WCR read/write logic ////
always@(negedge i2c_scl_in or posedge i2c_rst_in)
begin
  if (i2c_rst_in)   begin
	 i2c_sda                             <= 1'b1;
	 i2c_sda_flag                        <= 1'b0;
     i2c_state[3:0]                      <= 4'd0;	 
	 i2c_sda_data[15:0]                   <= 16'd0;
	 i2c_sda_data_r[15:0]                   <= 16'd0;
	 i2c_rd_valid_r						<=	1'b0;
	 i2c_count[7:0]                      <= 8'd0;
	 i2c_ready_r						 <= 1'b1;
	 
	 byte_command						 <= 8'd0;
	 conf_byte_cnt 						 <= 3'd0;
	 stop_delay_cnt						 <= 4'd0;
	 
	 conf_data_in[7:0]					 <= 8'd0;
	 conf_addr_in[15:0]					 <= 16'd0;
	 i2c_rd_lenth[7:0]					 <=	8'd16;
  end
  else   begin
    case(i2c_state[3:0])
	 
	 // reset state(0)  
	   i2c_state_rst:   begin  
		  i2c_sda                         <= 1'b1;	
	      i2c_sda_flag                    <= 1'b0;				//低，SDA输出  
		  i2c_sda_data[15:0]               <= 16'd0;
		  i2c_rd_valid_r						<=	1'b0;
		  i2c_count[7:0]                  <= 8'd0;
		  conf_byte_cnt 				  <= 3'd0;
		  byte_command				  	  <= 8'd0;
		  stop_delay_cnt				  <= 4'd0;
		  
		  if(i2c_eprom)
			i2c_rd_lenth[7:0]					 <=	8'd8;
		  else
			i2c_rd_lenth[7:0]					 <=	8'd16;
		  
		  if (!i2c_wr_rd && i2c_wp_enable && !i2c_scl_div2)   begin  	//i2c_wr_rd高读低写
			i2c_ready_r					  <= 1'b0;				//一旦进入读、写状态即进入忙状态
		    i2c_state[3:0]                <= i2c_state_start;
			
			conf_data_in[7:0]		 	  <= i2c_reg_in[7:0];
			conf_addr_in[15:0]		 	  <= i2c_reg_in[31:16];
		  end
		  else if(i2c_wr_rd && i2c_wp_enable && i2c_scl_div2) begin	//读取操作
			i2c_ready_r					  <= 1'b0;				//一旦进入读、写状态即进入忙状态
		    i2c_state[3:0]                <= i2c_state_start;
			// conf_data_in[7:0]		  <= i2c_reg_in[15:8];	//无用数据
			conf_addr_in[15:0]		 	  <= i2c_reg_in[31:16];
		  end
		  else   begin
			i2c_ready_r					  <= 1'b1;				
		    i2c_state[3:0]                <= i2c_state_rst;
			conf_data_in[7:0]		 	  <= 8'd0;
			conf_addr_in[15:0]		 	  <= 16'd0;
		  end
	   end
      
	 // I2C start state(1)		写起始
	   i2c_state_start:   begin
		  i2c_sda_flag                    <= 1'b0;     		//I2C发送
		  i2c_state[3:0]                  <= i2c_state_byte_wr;
		  i2c_count[7:0]                  <= 8'd0;
		  if (i2c_scl_div2)   begin
		    i2c_sda                       <= 1'b0;			//拉低，产生起始位
		    if((!i2c_eprom) && (conf_byte_cnt > 3'd1))
				byte_command	  <= RD_DEVICE;		//此时表示读操作的重复起始状态
			else if((i2c_eprom) && (conf_byte_cnt > 3'd2))
				byte_command	  <= E2C_RD_DEVICE;
			else if(i2c_eprom)				
				byte_command	  <= E2C_WR_DEVICE;
			else
				byte_command	  <= WR_DEVICE;
		  end
		  else	i2c_state[3:0]            <= i2c_state_start;
	   end
    
	 // I2C write dev state(2)	写byte数据
	   i2c_state_byte_wr:   begin
	     if (i2c_count[7:0] == 8'd8 && !i2c_scl_div2)   begin
		    i2c_count[7:0]                <= 8'd0;
		    // conf_byte_cnt[2:0]                <= conf_byte_cnt[2:0] + 1'b1;	
			conf_byte_cnt[2:0]			   <= conf_byte_cnt[2:0] + 1'b1;
			 i2c_sda                       <= byte_command[7];
			 i2c_state[3:0]                <= i2c_state_sack;
			 i2c_sda_flag                  <= 1'b1;            // SDA input，此处没有对反馈进行判断
			//根据读、写状态，发送的byte个数来判断下一个byte的值
			if(conf_byte_cnt[2:0] == 3'd0)	//写完设备地址，准备写地址
				byte_command[7:0]           <= conf_addr_in[15:8];
			else if((!i2c_eprom) && (conf_byte_cnt[2:0] == 3'd1) && (!i2c_wr_rd) ) //已经写了2byte，在写模式下则再写一次数据
				byte_command[7:0]           <= conf_data_in[7:0];
			else if((i2c_eprom) && (conf_byte_cnt[2:0] == 3'd1)) //已经写了2byte，在写模式下则再写一次数据
				byte_command[7:0]           <= conf_addr_in[7:0];
			else if((i2c_eprom) && (conf_byte_cnt[2:0] == 3'd2) && (!i2c_wr_rd) ) //已经写了2byte，在写模式下则再写一次数据
				byte_command[7:0]           <= conf_data_in[7:0];
			else
				byte_command[7:0]           <= 8'd0;
		 end
		 else if(!i2c_scl_div2)  begin
		     i2c_sda                       <= byte_command[7];
			 byte_command[7:1]             <= byte_command[6:0];
			 i2c_count[7:0]                <= i2c_count[7:0] + 1'b1;
			 i2c_state[3:0]                <= i2c_state_byte_wr;
			 i2c_sda_flag                  <= 1'b0;
		 end
	   end
	// I2C slave ack state(3) 判断反馈后的下一状态
	   i2c_state_sack:   begin
	      if (!i2c_scl_div2)   begin
			  // i2c_sda                      <= 1'b1;
			  // i2c_sda_flag                 <= 1'b0;			
			  byte_command[7:1]            <= byte_command[6:0];
			  i2c_count[7:0]               <= i2c_count[7:0] + 1'b1;
			  
			  if (conf_byte_cnt[2:0] >= 3'd6 )  begin		//异常态，直接进入停止态
			     i2c_state[3:0]             <= i2c_state_stop;
				 i2c_sda                    <= 1'b0;		//先拉低，STOP时拉高即停止
				 i2c_sda_flag                 <= 1'b0; 
			  end
			  else if (conf_byte_cnt[2:0] == 3'd1)   begin	//配置完设备地址，再配寄存器地址
			     i2c_state[3:0]             <= i2c_state_byte_wr;
				 i2c_sda                    <= byte_command[7];
				 i2c_sda_flag                 <= 1'b0;
			  end
			  else if ((i2c_eprom) && (conf_byte_cnt[2:0] == 3'd2)) begin
			     i2c_state[3:0]             <= i2c_state_byte_wr;
				 i2c_sda                    <= byte_command[7];
				 i2c_sda_flag                 <= 1'b0;
			  end
			  else if((!i2c_eprom) && (conf_byte_cnt[2:0] == 3'd2)) begin
				 if (!i2c_wr_rd)   begin	//写入数据
				    i2c_state[3:0]           <= i2c_state_byte_wr;
					i2c_sda                  <= byte_command[7];
					i2c_sda_flag                 <= 1'b0;
				 end				 
				 else   begin
				   i2c_state[3:0]           <= i2c_state_start;	//重复起始标志
                   i2c_sda_flag             <= 1'b0;
				   i2c_sda                  <= 1'b1;  
				 end
			  end
			  else if((i2c_eprom) && (conf_byte_cnt[2:0] == 3'd3)) begin
				 if (!i2c_wr_rd)   begin	//写入数据
				    i2c_state[3:0]           <= i2c_state_byte_wr;
					i2c_sda                  <= byte_command[7];
					i2c_sda_flag                 <= 1'b0;
				 end				 
				 else   begin
				   i2c_state[3:0]           <= i2c_state_start;	//重复起始标志
                   i2c_sda_flag             <= 1'b0;
				   i2c_sda                  <= 1'b1;  
				 end
			  end
			  else   begin		//i2c_count== 3'd3，即发送完3个byte后，根据读、写判断下一状态
				 if (!i2c_wr_rd)   begin	//写入数据
				    i2c_state[3:0]           <= i2c_state_stop;	//写入I2C操作结束
					i2c_sda                  <= 1'b0;
					i2c_sda_flag                 <= 1'b0;
				 end				 
				 else   begin
				   i2c_state[3:0]           <= i2c_state_byte_rd;	//此处在下降沿转移状态，在下一次上升沿读取数据
                   i2c_sda_flag             <= 1'b1;
                   i2c_rd_first             <= 1'b1;
				   i2c_sda                  <= 1'b1;  
				 end
			  end
			end 
	   end
    // I2C write dev state(4)	读操作:读取寄存器地址
	   i2c_state_byte_rd:   begin
		    i2c_sda                        <= 1'b1;
			i2c_sda_flag                   <= 1'b1;			//SDA读取
	      if (i2c_scl_div2)   begin  
           i2c_sda_data[15:0]           <= {i2c_sda_data[14:0],i2c_sda_din};
		  end
 		  else   begin  //下降沿下
			  if (i2c_count[7:0] == i2c_rd_lenth[7:0])   begin	//8'd8
			     i2c_count[7:0]             <= 8'd0;
				 conf_byte_cnt[2:0]         <= conf_byte_cnt[2:0] + 1'b1;
				 i2c_sda_data_r[15:0] 		<=	i2c_sda_data[15:0] ;
				 i2c_rd_valid_r				<=	1'b1;		//一次读取完毕置高
				 i2c_state[3:0]             <= i2c_state_mack;
				 i2c_sda                    <= 1'b0;
				 i2c_sda_flag               <= 1'b0;
			  end
              else if((!i2c_eprom) && (i2c_count[7:0] == 8'd8) && i2c_rd_first) begin
                 i2c_sda_flag               <= 1'b0;
                 i2c_sda                    <= 1'b0;
                 i2c_rd_first               <= 1'b0;
                 i2c_count[7:0]             <= i2c_count[7:0] + 1'b1;
                 i2c_state[3:0]             <= i2c_temp_rd_mack;
              end
			  else   begin
                 i2c_sda_flag               <= 1'b1;			//SDA读取
                 i2c_sda                    <= 1'b1;
			     i2c_count[7:0]             <= i2c_count[7:0] + 1'b1;
				 i2c_state[3:0]             <= i2c_state_byte_rd;				 
			  end
         end			
		end
	   i2c_temp_rd_mack:   begin 
	      if (!i2c_scl_div2)   begin
			  	//此处设计单字节读取，读完后直接结束；加上上一状态的拉低，共拉低了2个时钟周期
			     i2c_state[3:0]             <= i2c_state_byte_rd;
				 i2c_sda                    <= 1'b0;
				 i2c_sda_flag               <= 1'b1;
         end			  
		end
    // I2C master ack state(5)
	   i2c_state_mack:   begin 
	      if (!i2c_scl_div2)   begin
			  // i2c_sda                      <= 1'b1;
			  // i2c_sda_flag                 <= 1'b1;
			  // i2c_count[7:0]               <= i2c_count[7:0] + 1'b1;			  
			  // if (conf_byte_cnt[2:0] <= 3'd3)   begin      // NACK 读取完1byte应为4
			     // i2c_state[3:0]             <= i2c_state_byte_rd;
			  // end
			  // else   
			  begin	//此处设计单字节读取，读完后直接结束；加上上一状态的拉低，共拉低了2个时钟周期
			     i2c_state[3:0]             <= i2c_state_stop;
				 i2c_sda                    <= 1'b0;
				 i2c_sda_flag               <= 1'b0;
			  end 
         end			  
		end

    // I2C stop(6)
	   i2c_state_stop:   begin
	     if (i2c_scl_div2)   begin
		    i2c_sda                       <= 1'b1;
		    i2c_sda_flag                  <= 1'b0;
			 i2c_state[3:0]               <= i2c_state_rst;
			 i2c_rd_valid_r				  <=	1'b0;	//一次传输完毕读取标识清零
			 i2c_ready_r				  <= 1'b1;	
			 i2c_count[7:0]               <= 8'd0;
			 byte_command[7:0]            <= 8'd0;
		  end
	   end

	   default:   begin
		  i2c_sda                         <= 1'b1;	
	      i2c_sda_flag                    <= 1'b0;				//低，SDA输出  
		  i2c_sda_data[15:0]               <= 16'd0;
		  i2c_count[7:0]                  <= 8'd0;
		  conf_byte_cnt 				  <= 3'd0;
		  byte_command				  	  <= 8'd0;
		  i2c_ready_r				      <= 1'b1;	
	   end		 
	 endcase
  end
end


//////////////////////////////////////////////////////////////////////////////////



//////////////////////////////////////////////////////////////////////////////////
//// debug ////
    assign  debug_signal[6:0]           = i2c_count[6:0];
    assign  debug_signal[7]             = i2c_sda_flag;
    assign  debug_signal[11:8]          = i2c_state[3:0];
    assign  debug_signal[19:12]         = byte_command[7:0];
    assign  debug_signal[22:20]         = conf_byte_cnt[2:0];
    assign  debug_signal[23]            = i2c_sda;
    assign  debug_signal[24]            = i2c_sda_din;
    assign  debug_signal[25]            = i2c_scl_div2;
	 

//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
endmodule
