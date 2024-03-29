`timescale 1 ns/ 1ns
module m_creat_tb();

reg sys_clk,sys_rst_n;
wire out;
wire [ 3:0 ]shift;
initial
begin
sys_clk = 1'b0;
sys_rst_n = 1'b0;
#100
sys_rst_n = 1'b1;
#100;
sys_rst_n = 1'b0;
forever #20 sys_clk = ~sys_clk;
end

m_sequence m_sequence(
.sclk(sys_clk),
.rst_n(sys_rst_n),
.m_seq(out)
);
endmodule