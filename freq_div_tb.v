`include "freq_div.v"
module Freq_Div_tb;
    reg [31:0] Div_Fact;
    reg Rst;
    reg Clk_Ref;
    reg Clk_In;
    wire Clk_Out;

    Freq_Div uut (
        .Div_Fact(Div_Fact),
        .Rst(Rst),
        .Clk_Ref(Clk_Ref),
        .Clk_In(Clk_In),
        .Clk_Out(Clk_Out)
    );

    initial begin
        Clk_Ref = 0;
        forever #5 Clk_Ref = ~Clk_Ref;
    end

    initial begin
        Clk_In = 0;
        forever #200 Clk_In = ~Clk_In;
    end

    initial begin
        Div_Fact = 32'd4;
        Rst = 1;
        #10;
        Rst = 0;
    end

endmodule
