module rx_decode_cpld16(
input clk,			// 系统主时钟
input rst_n,		//低电平复位信号

input rx_ready,		//为高时表示正在接受状态，为低才进行新的接受
input [7:0] rx_data,		//	RS232接受到的byte数据,直到接受到新的byte，才变化

output [127:0] recieve_data,		//命令串解析后的接受数据
output recirve_vld				//命令接受指示，为高表示接受到一个64位数据
);

parameter 		WAIT_TIME	=	176	;//WAIT_TIME == clk / 波特率 * 11 

parameter		IDLE		=	3'd0,
				RV_DATA		=	3'd1,
				RV_STOP		=	3'd2,
				LENTH_RV	= 	4'd10;

reg [127:0] recieve_data_r = 64'd0;
reg [127:0] recieve_data_g = 64'd0;
reg recirve_vld_r = 1'b0;	
reg [2:0] rv_state = 3'd0;
reg [4:0] rv_cnt = 5'd0;
reg [2:0] c0_cnt = 3'd0;			 //接受c0的个数
/*每接受完一个字节后，下一个字节不一定回来，延时一个字节长度，无正确接受则丢弃；
每次开始接受新的byte字节时，就开始计数*/
reg [31:0] time_cnt = 32'd0;		
reg rx_ready_d1  = 1'b0;
reg ngready_en = 1'b0;

assign recieve_data 	= 	recieve_data_g;
assign recirve_vld		=	recirve_vld_r;

////////////////暂时设定命令串共10个字节，起始c0、结束cf，高字节在前，大端模式///////////////
always @ (posedge clk or negedge rst_n) begin
	if(!rst_n) 	rx_ready_d1 <= 1'b0;			//默认空闲态
	else		rx_ready_d1 <= rx_ready;
end
// assign	ngready_en = rx_ready_d1 & (~rx_ready);	//采集下降沿，表示新接收到1个byte数据
always @ (posedge clk or negedge rst_n) begin
	if(!rst_n) 	
			ngready_en		<= 		1'b0;			//默认空闲态
	else if (rx_ready_d1 && (!rx_ready)) 
			ngready_en		<= 		1'b1;
	else	
			ngready_en		<= 		1'b0;
end

always @ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
			recieve_data_r 	<= 		128'd0;
			recieve_data_g 	<=		128'd0;
			rv_state 		<= 		IDLE;
			rv_cnt			<= 		5'd0;
			c0_cnt			<= 		3'd0;
			recirve_vld_r 	<= 		1'b0;
			time_cnt 		<= 		32'd0;
		end
	else begin
	 case(rv_state)
	 IDLE : begin		//初始态，判断起始命令字节c0
		recirve_vld_r 	<= 		1'b0;
		rv_cnt			<= 		5'd0;
		time_cnt		<=		32'd0;
			if(c0_cnt >= 3'd3) begin
				c0_cnt		<= 		3'd0;
				rv_state 	<= 		RV_DATA;
			end
			else if(ngready_en && (rx_data == 8'hc0)) begin		
				rv_state 	<= 		IDLE;
				c0_cnt		<=		c0_cnt + 1'b1;
			end
			else begin
				rv_state 	<= 		IDLE;
			end
		end
	 RV_DATA : begin	//接受数据信息
			// if(time_cnt > WAIT_TIME) begin
				// time_cnt	<=		32'd0;
				// rv_state 	<= 		IDLE;
			// end 
			// else 
			if(rv_cnt >= 5'd17)	begin	//接受数据数量异常，直接回到初始态
				rv_cnt 			<= 		5'd0;
				recieve_data_r 	<= 		128'd0;////////////********************
				rv_state 		<= 		IDLE;
				time_cnt 		<= 		32'd0;
			end
			else if( ngready_en & (rv_cnt == 5'd15)) begin	//共接受8个数据
				rv_cnt 		<= 		5'd0;
				rv_state 	<= 		RV_STOP;
				time_cnt 	<= 		32'd0;
				recieve_data_r[127:0] <= {recieve_data_r[119:0],rx_data};
			end
			else if(ngready_en) begin
				rv_cnt 		<= 		rv_cnt + 1'b1;
				rv_state 	<= 		RV_DATA;
				time_cnt 	<= 		32'd0;
				recieve_data_r[127:0] <= {recieve_data_r[119:0],rx_data};
			end
			else begin
				rv_state 	<= 		RV_DATA;
				time_cnt	<= 		time_cnt + 1'b1;//一个bit周期延时，无接受就丢弃
			end
		end
	 RV_STOP : begin	//判断命令串的结束字节cf
			// if(time_cnt > WAIT_TIME) begin	//超过一个字节周期延时，无接受就丢弃
				// time_cnt	<=		32'd0;
				// rv_state 	<= 		IDLE;
			// end 
			// else 
			if(ngready_en & (rx_data == 8'hcf)) begin		//1c
				recirve_vld_r 	<= 		1'b1;
				recieve_data_g 	<=		recieve_data_r;
				rv_state 		<= 		IDLE;
			end
			else if(ngready_en)begin	//结束字节不对，则丢弃本次命令
				recirve_vld_r 	<= 		1'b0;
				recieve_data_g 	<=		recieve_data_g;
				rv_state 		<= 		IDLE;
			end
			else begin
				rv_state 	<= 		RV_STOP;
				time_cnt	<= 		time_cnt + 1'b1;
			end
		end
	 default : begin
				recirve_vld_r 	<= 		1'b0;
				rv_cnt			<= 		5'd0;
				recieve_data_g 	<=		recieve_data_g;
				rv_state 		<= 		IDLE;
				time_cnt		<=		32'd0;
	 end
	 endcase
	end
end







endmodule
