module Freq_Div (
    input  wire [31:0] Div_Fact,
    input  wire Rst,
    input  wire Clk_Ref,
    input  wire Clk_In,
    output reg  Clk_Out
);

    reg [31:0] counter;

    always @(posedge Clk_In or posedge Rst) begin
        if (Rst) begin
            counter <= 32'd0;
            Clk_Out <= 1'b0;
        end else begin
            if (counter == Div_Fact - 1) begin
                counter <= 32'd0;
                Clk_Out <= ~Clk_Out;
            end else begin
                counter <= counter + 1;
            end
        end
    end

endmodule
