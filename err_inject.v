module err_inject(
  input  clk,
  input  in_bit,
  output out_bit
);
  reg [2:0] lfsr = 3'b101;
  always @(posedge clk) begin
    lfsr <= {lfsr[1:0], lfsr[2]^lfsr[0]}; 
  end

  wire flip = (lfsr == 3'b111); 
  assign out_bit = in_bit ^ flip;
endmodule