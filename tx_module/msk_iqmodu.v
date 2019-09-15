//////////////////////////////////////////////////////////////////////////////////
// Company:         StarPoint
// Engineer:        guoyan
// 
// Create Date:     15:24:00 06/10/2015  
// Module Name:     msk_iqmodu
// Project Name:    
// Target Devices:  FPGA - XC7K325T - FFG900; 
// Tool versions:   ISE14.6;  
// Description:     The module achieves carrier modulation
// 
// Revision:        v1.0 - File Created
// Additional Comments: 
//1¡¢code element contains N*(1/4*Tc),so that 1/5M = N*(1/4*1/fc)->fc=1.25N,  
// 1 code ->
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

module msk_iqmodu(
//// clock/reset ////
input               clk_msk_in, //25MHz
input               logic_rst_in,

//// data signal ////
input               mod_vaild_in,
input [15:0]        mod_i_in,
input [15:0]        mod_q_in,

output              msk_vaild_out,
output[15:0]        msk_mod_out,


//// debug ////
output[127:0]       debug_signal
);

//////////////////////////////////////////////////////////////////////////////////
//// (0) signal assigment ////
wire        [27:0] freq_data; //2^28 = 268435456;
wire        [15:0] sine, cosine;
wire signed [31:0] ii_reg, qq_reg;

reg [32:0]         msk_out_reg = 33'd0;
reg [2:0]          mod_vaild_in_dly = 3'd0;
reg [15:0]         msk_mod = 16'd0;

assign freq_data = 28'd107374183; //  10M*268435456/25M~=107374183->10.000000055; when N=8,fc=10M

//////////////////////////////////////////////////////////////////////////////////
//// (1)generate 10M carrier logic ////
dds_modu dds_modu(
   .clk(clk_msk_in),  //25 is too low for 10M
   .data(freq_data[27:0]),
   .we(1'b1),//(modu_vaild_in),   
   .sine(sine[15:0]),
   .cosine(cosine[15:0])
   );
   
//////////////////////////////////////////////////////////////////////////////////
//// (2)carrier mutiply logic ////
//spectrum shifting
msk_mult U0_msk_mult(
   .clk(clk_msk_in), 
   .a(cosine), 
   .b(mod_i_in), 
   .p(ii_reg)
   );
   
msk_mult U1_msk_mult(
   .clk(clk_msk_in), 
   .a(sine), 
   .b(mod_q_in), 
   .p(qq_reg)
   );
   
//////////////////////////////////////////////////////////////////////////////////
//// (3) I+Q logic ////
//genenrate MSK signal
 always@(posedge clk_msk_in)
 begin
   if(logic_rst_in)  begin
	    msk_out_reg               <= 33'h00000000;
   end
   else begin
        msk_out_reg              <= {ii_reg[31], ii_reg} - {qq_reg[31], qq_reg};
   end
 end	
 
 always@(posedge clk_msk_in)
 begin
  if(logic_rst_in)
    msk_mod[15:0]	               <= 16'h0000;
  else if((msk_out_reg[32]==1'b0)&&(msk_out_reg[31:30]!=2'b00))
    msk_mod[15:0]	               <= 16'h7fff;
  else if((msk_out_reg[32]==1'b1)&&(msk_out_reg[31:30]!=2'b11))
    msk_mod[15:0]	               <= 16'h8000;
  else 
    msk_mod[15:0]	               <= msk_out_reg[30:15];
end

always@(posedge clk_msk_in)
begin
   if (logic_rst_in)   begin
	   mod_vaild_in_dly[2:0]      <= 1'b0;
	end
   else begin
      mod_vaild_in_dly[2:0]     <= {mod_vaild_in_dly[1:0],mod_vaild_in};
   end
end

assign msk_vaild_out        = mod_vaild_in_dly[2];
assign msk_mod_out[15:0]    = msk_mod[15:0];
//////////////////////////////////////////////////////////////////////////////////
//// (4)debug logic ////
endmodule
