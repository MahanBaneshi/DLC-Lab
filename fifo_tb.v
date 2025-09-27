`timescale 1ns / 1ps
`include "fifo.v"


`timescale 1ns / 1ps

module fifo_tb;

    // Inputs
    reg [7:0] Din;
    reg RST;
    reg RD_EN;
    reg WR_EN;
    reg CLK;

    // Outputs
    wire [7:0] DOut;
    wire Empty;
    wire Full;

    // Instantiate the Unit Under Test (UUT)
    fifo uut (
        .Din(Din), 
        .RST(RST), 
        .RD_EN(RD_EN), 
        .WR_EN(WR_EN), 
        .CLK(CLK), 
        .DOut(DOut), 
        .Empty(Empty), 
        .Full(Full)
    );

    // Clock generation
    initial begin
        CLK = 0;
        forever #5 CLK = ~CLK;
    end

    initial begin
        $dumpfile("fifo.vcd");
        $dumpvars(0, fifo_tb);

        // Initialize Inputs
        Din = 0;
        RST = 1;
        RD_EN = 0;
        WR_EN = 0;

        // Wait 100 ns for global reset to finish
        #100;
        RST = 0;
        
        // Test Case 1: Write to FIFO until full
        $display("Test Case 1: Filling the FIFO");
        for (integer i = 1; i <= 128; i = i + 1) begin
            Din = i;
            WR_EN = 1;
            #10;
            WR_EN = 0;
            #10;
            $display("Wrote: %d, Count: %d, Empty: %b, Full: %b", i, uut.count, Empty, Full);
        end
        
        // Test Case 2: Try to write when full
        $display("\nTest Case 2: Attempt to write when full");
        Din = 255;
        WR_EN = 1;
        #10;
        WR_EN = 0;
        #10;
        $display("After write attempt: Full: %b", Full);
        
        // Test Case 3: Read from FIFO until empty
        $display("\nTest Case 3: Emptying the FIFO");
        for (integer i = 1; i <= 128; i = i + 1) begin
            RD_EN = 1;
            #10;
            RD_EN = 0;
            #10;
            $display("Read: %d, Count: %d, Empty: %b, Full: %b", DOut, uut.count, Empty, Full);
        end
        
        // Test Case 4: Try to read when empty
        $display("\nTest Case 4: Attempt to read when empty");
        RD_EN = 1;
        #10;
        RD_EN = 0;
        #10;
        $display("After read attempt: Empty: %b", Empty);
        
        // Test Case 5: Simultaneous read and write
        $display("\nTest Case 5: Simultaneous read and write");
        for (integer i = 1; i <= 10; i = i + 1) begin
            Din = i + 100;
            WR_EN = 1;
            RD_EN = 1;
            #10;
            WR_EN = 0;
            RD_EN = 0;
            #10;
            $display("Wrote: %d, Read: %d, Count: %d", i + 100, DOut, uut.count);
        end
        
        // Test Case 6: Reset test
        $display("\nTest Case 6: Reset test");
        RST = 1;
        #10;
        RST = 0;
        #10;
        $display("After reset: Empty: %b, Full: %b, Count: %d", Empty, Full, uut.count);
        
        $display("\nAll tests completed");
        $finish;
    end

endmodule