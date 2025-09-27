`timescale 1ns / 1ps
module ram (
    input wire [7:0] Addr,     // 8-bit address for 128 locations
    input wire [7:0] Din,      // 8-bit data input
    input wire EN,             // Enable signal
    input wire WE,             // Write Enable signal
    input wire CLK,            // Clock signal
    output reg [7:0] DOut      // 8-bit data output
);

    // Declare 128x8-bit memory
    reg [7:0] memory [127:0];

    always @(posedge CLK) begin
        if (EN) begin
            if (WE) begin
                // Write operation
                memory[Addr] <= Din;
            end else begin
                // Read operation
                DOut <= memory[Addr];
            end
        end
    end

endmodule