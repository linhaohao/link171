//*********************************************
//            面板LED灯控�
//  LED-0   开机长� 低长�           V22 
//  LED-2   入网信号   V21 
//  LED-1   DSP工作后，�S闪一�      V20
//  LED-3   告警
//  SW-sig  开关控制大、小信号切换      T20
//**********************************************
module panel_ctr(
input               clk_20mhz,
input               panel_sw,
input               dsp_net_in,
input               waring_led,
output  [3:0]       panel_led,

output  [4:0]       panel_debug

);

parameter       TIMER_1S_CNT        =   25'd20000000,
                TIMER_1S_CNT_2      =   25'd10000000;

reg     [3:0]       panel_led_r     =   4'b1111;

reg     [24:0]      led_1s_cnt      =   25'd0;

//1s计数�
always@(posedge clk_20mhz) begin
    if(led_1s_cnt[24:0] >= TIMER_1S_CNT)
        led_1s_cnt[24:0]            <=  25'd0;
    else
        led_1s_cnt[24:0]            <=  led_1s_cnt[24:0] + 1'b1;
end

//led3 0.5s反转控制
always@(posedge clk_20mhz) begin
    if(led_1s_cnt[23:0] == TIMER_1S_CNT_2)
        panel_led_r[2]              <=  ~panel_led_r[2];
    else
        panel_led_r[2]              <=  panel_led_r[2];
end

//led2 1s反转控制
always@(posedge clk_20mhz) begin
    if(led_1s_cnt[24:0] == TIMER_1S_CNT)
        panel_led_r[1]              <=  ~panel_led_r[1];
    else
        panel_led_r[1]              <=  panel_led_r[1];
end 
        
assign  panel_led[0]        =   1'b0;             //开机长亮
assign  panel_led[1]        =   ~dsp_net_in;	  //panel_led_r[2];   //FPGA 0.5s反转
assign  panel_led[2]        =   panel_led_r[1];   //dsp  0.5s反转
// assign  panel_led[3]        =   1'b1;
assign  panel_led[3]        =   waring_led;

assign  panel_debug[3:0]    =   panel_led[3:0];
assign  panel_debug[4]      =   panel_sw;

endmodule
