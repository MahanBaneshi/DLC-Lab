`timescale 1ns / 1ps
`include "ram.v"

module ram_tb;

    // ورودی‌ها
    reg [7:0] Addr;
    reg [7:0] Din;
    reg EN;
    reg WE;
    reg CLK;

    // خروجی
    wire [7:0] DOut;

    // نمونه‌سازی از ماژول ram
    ram uut (
        .Addr(Addr),
        .Din(Din),
        .EN(EN),
        .WE(WE),
        .CLK(CLK),
        .DOut(DOut)
    );

    // تولید کلاک
    initial begin
        $dumpfile("ram.vcd");
        $dumpvars(0, ram_tb);


        CLK = 0;
        forever #5 CLK = ~CLK;  // پریود 10ns
    end

    // روال تست
    initial begin
        // مقداردهی اولیه
        Addr = 0;
        Din = 0;
        EN = 0;
        WE = 0;

        #10;

        // نوشتن در حافظه
        EN = 1;
        WE = 1;

        Addr = 8'h01;
        Din = 8'hA5;
        #10;

        Addr = 8'h02;
        Din = 8'h3C;
        #10;

        Addr = 8'h03;
        Din = 8'hFF;
        #10;

        // خواندن از حافظه
        WE = 0;

        Addr = 8'h01;
        #10;

        Addr = 8'h02;
        #10;

        Addr = 8'h03;
        #10;

        // پایان شبیه‌سازی
        $stop;
    end

endmodule