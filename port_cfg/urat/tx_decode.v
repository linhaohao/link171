module tx_decode(
input clk,					// 系统主时钟
input rst_n,				//低电平复位信号

input tx_ready,				//为高时表示正在接受状态，为低才进行新的接受
input [63:0] tx_data,		//	RS232接受到的byte数据,直到接受到新的byte，才变化
input send_en,		//发送64位数据的使能
output send_en_valid,		//用来标识FPGA内部使能发送时期,高为发送时
output [7:0] comnd_data,	//命令串解析后的接受数据
output comnd_en,			//给发送字节模块的使能信号，高使能
output send_vld				//命令发送指示，为高表示正在发送送入的一个64位数据
);

parameter		IDLE		=	3'd0,
				SD_START	=	3'd1,
				SD_DATA		=	3'd2,
				SD_STOP		=	3'd3,
				LENTH_RV	= 	4'd10;

reg [7:0] comnd_data_r = 8'd0;
reg [2:0] sd_state = 3'd0;
reg [3:0] sd_cnt = 4'd0;
reg send_vld_r = 1'b0;
reg comnd_en_r = 1'b0;
reg send_en_valid_r = 1'b0;
				
reg tx_ready_d1 = 1'b0;
reg [63:0] tx_data_r = 64'd0;
reg send_en_d1 = 1'b0,send_en_d2 = 1'b0;
reg ngready_en = 1'b0;		//采集发送一个字节后的下降沿
reg pgsend_en = 1'b0;			//采集需要发送数据的起始沿

assign comnd_data 	= 	comnd_data_r;
assign comnd_en		= 	comnd_en_r;
assign send_vld 	= 	send_vld_r;
assign send_en_valid	= 		send_en_valid_r;


////////////////暂时设定命令串共10个字节，起始c0、结束cf，高字节在前，大端模式///////////////
always @ (posedge clk or negedge rst_n) begin
	if(!rst_n) 	begin
		send_en_d1 		<=		1'b0;			//默认空闲态
		send_en_d2 		<=		1'b0;
	end
	else if(~send_vld_r & ~tx_ready)	begin
			send_en_d1		<=		send_en;
			send_en_d2		<=		send_en_d1;
	end
end

always @ (posedge clk or negedge rst_n) begin
	if(!rst_n) 	tx_ready_d1		<= 		1'b0;			//默认空闲态
	else		tx_ready_d1		<=		tx_ready;
end

// assign	ngready_en = tx_ready_d1 & (~tx_ready);		//采集下降沿，表示发送完1个byte数据
always @ (posedge clk or negedge rst_n) begin
	if(!rst_n) 	
			ngready_en		<= 		1'b0;			//默认空闲态
	else if (tx_ready_d1 && (!tx_ready)) 
			ngready_en		<= 		1'b1;
	else	
			ngready_en		<= 		1'b0;
end
// assign	pgsend_en  = send_en_d1  & (~send_en_d2);	//采集上升沿，表示开始发送64位的数据
always @ (posedge clk or negedge rst_n) begin
	if(!rst_n) 	
			pgsend_en		<= 		1'b0;			//默认空闲态
	else if (send_en_d1 && (!send_en_d2)) 
			pgsend_en		<= 		1'b1;
	else	
			pgsend_en		<= 		1'b0;
end

always @ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
			comnd_data_r 	<= 		8'd0;
			sd_state 		<= 		IDLE;
			sd_cnt			<= 		4'd0;
			send_vld_r	 	<= 		1'b0;
			comnd_en_r		<=		1'b0;
			tx_data_r		<=		64'd0;
			send_en_valid_r <= 		1'b0;
		end
	else begin
	 case(sd_state)
	 IDLE : begin		//初始态，判断发送起始沿
			comnd_data_r 	<= 		8'd0;
			sd_cnt			<= 		4'd0;
			// send_vld_r	 	<= 		1'b0;
			comnd_en_r		<=		1'b0;
		
			if(pgsend_en) begin
				sd_state 		<= 		SD_START;
				send_vld_r	 	<= 		1'b1;
				send_en_valid_r <= 		1'b1;
				tx_data_r		<=		tx_data;
			end
			else begin
				sd_state 		<= 		IDLE;
				send_vld_r	 	<= 		1'b0;
				send_en_valid_r <= 		1'b0;
			end
	 end
	 SD_START : begin	//启动后会发送完一整条命令串
			if( (~tx_ready_d1) & (~tx_ready)) begin		//空闲态
				comnd_en_r		<=		1'b1;
				comnd_data_r	<=		8'hc0;
				sd_state 		<= 		SD_DATA;
			end
			else begin
				comnd_en_r		<=		1'b0;
				comnd_data_r	<=		8'h00;
				sd_state 		<= 		SD_START;
			end
	 end
	 SD_DATA : begin
			if(sd_cnt >= 4'd9)	begin	//发送数据数量异常，直接回到初始态
				comnd_en_r		<=		1'b0;
				comnd_data_r	<=		8'h00;
				sd_state 		<= 		IDLE;
			end
			else if( ngready_en & (sd_cnt == 4'd8)) begin	//共发送完8个数据，发送结束字节cf
				sd_cnt 			<= 		4'd0;
				sd_state 		<= 		SD_STOP;
				comnd_en_r		<=		1'b1;
				comnd_data_r	<=		8'hcf;   
			//	comnd_data_r	<=		8'h0a; 
				// tx_data_r[63:0] <= {8'h0,tx_data_r[63:7]};
			end
			else if(ngready_en) begin	//上一个字节发送完毕
				sd_cnt 			<= 		sd_cnt + 1'b1;
				sd_state 		<= 		SD_DATA;
				comnd_en_r		<=		1'b1;
				comnd_data_r	<=		tx_data_r[63:56];
				tx_data_r[63:0] <= 		{tx_data_r[55:0],8'h0};
			end
			else begin
				comnd_en_r		<=		1'b0;
				// comnd_data_r	<=		8'h00;
				sd_state 		<= 		SD_DATA;
			end
	 
	 end
	 SD_STOP : begin
			if(ngready_en) begin		//发送完结束字节，回到IDLE
				comnd_en_r		<=		1'b0;
				comnd_data_r	<=		8'h00;
				sd_state 		<= 		IDLE;
				send_vld_r	 	<= 		1'b0;
			end
			else begin
				comnd_en_r		<=		1'b0;
				sd_state 		<= 		SD_STOP;
			end
	 end
	 default : begin
			comnd_data_r 	<= 		8'd0;
			sd_state 		<= 		IDLE;
			sd_cnt			<= 		4'd0;
			send_vld_r	 	<= 		1'b0;
			tx_data_r		<=		64'd0;
			comnd_en_r		<=		1'b0;
	 end
	 endcase 
	end
end



endmodule 

