module m_creat
(
sys_clk,
sys_rst_n,
out,shift
);
//input
input sys_clk;
input sys_rst_n;

//output
output out;//最终输出
output [ 31:0 ]shift;//4位移位寄存器值的输出
reg [ 3:0 ]rShift;//4位移位寄存器
reg rOut;

/************************************************************************/
wire feedback = rShift[ 0 ]^rShift[ 3 ];
assign out= rOut;
assign shift[31:0] = {rShift[3:0],rShift[3:0],rShift[3:0],rShift[3:0],rShift[3:0],rShift[3:0],rShift[3:0],rShift[3:0]};

/***********************************************************************/
always @( posedge sys_clk or negedge sys_rst_n )
if( sys_rst_n == 0 )begin //初始化
rShift <= 4'b0110;
rOut <= 1'b0;
end
else
begin
rShift <= { feedback,rShift[ 3:1 ] }; //移位运算
rOut <= rShift[ 0 ];
end
endmodule
