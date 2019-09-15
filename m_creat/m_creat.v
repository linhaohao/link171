module m_sequence(
	input sclk,
	input rst_n,
	output m_seq
);
parameter POLY = 8'b10001110;//由本原多项式得到
reg [7:0] shift_reg;
always@(posedge sclk or posedge rst_n)
begin
	if(rst_n)begin
		shift_reg <= 8'b11111111;//初值不可为全零
	end
	else begin
		shift_reg[7] <= (shift_reg[0] & POLY[7])^
						    (shift_reg[1] & POLY[6])^
						    (shift_reg[2] & POLY[5])^
						    (shift_reg[3] & POLY[4])^
						    (shift_reg[4] & POLY[3])^
						    (shift_reg[5] & POLY[2])^
						    (shift_reg[6] & POLY[1])^
						    (shift_reg[7] & POLY[0]);
		shift_reg[6:0] <= shift_reg[7:1];				 
	end
end
 
assign m_seq = shift_reg[0];
 
endmodule
