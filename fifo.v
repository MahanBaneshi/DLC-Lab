`timescale 1ns / 1ps

module fifo (
    input wire [7:0] Din,     // 8-bit data input
    input wire RST,           // Reset signal
    input wire RD_EN,         // Read Enable signal
    input wire WR_EN,         // Write Enable signal
    input wire CLK,           // Clock signal
    output reg [7:0] DOut,    // 8-bit data output
    output reg Empty,         // Empty flag
    output reg Full           // Full flag
);

// Declare FIFO memory
reg [7:0] memory [127:0];     // FIFO memory array
reg [6:0] head = 0;           // Read pointer
reg [6:0] tail = 0;           // Write pointer
reg [7:0] count = 0;          // Element count

always @(posedge CLK or posedge RST) begin
    if (RST) begin
        // Reset the FIFO
        head <= 0;
        tail <= 0;
        count <= 0;
        Empty <= 1;
        Full <= 0;
    end else begin
        // Write operation
        if (WR_EN && !Full) begin
            memory[tail] <= Din;
            tail <= (tail + 1) % 128;
            count <= count + 1;
        end

        // Read operation
        if (RD_EN && !Empty) begin
            DOut <= memory[head];
            head <= (head + 1) % 128;
            count <= count - 1;
        end

        // Update status flags
        Empty <= (count == 0);
        Full <= (count == 128);
    end
end

endmodule