module top_copy
#( parameter ADDR_W = 12, parameter WIDTH = 16 )
(
  input                   clk,
  input                   rst,

  input      [ADDR_W-1:0] src_start,
  input      [ADDR_W-1:0] dst_start,

  output                  done,
  output                  full
);
  wire [WIDTH-1:0] src_dout;
  reg              src_we = 1'b0; 
  wire [ADDR_W-1:0] src_addr;

  mem16x4k #(ADDR_W, WIDTH) SRC_MEM (
    .clk(clk), .we(src_we), .addr(src_addr), .din({WIDTH{1'b0}}), .dout(src_dout)
  );

  wire [ADDR_W-1:0] dst_addr;
  wire               dst_we;
  wire [WIDTH-1:0]   dst_din;
  mem16x4k #(ADDR_W, WIDTH) DST_MEM (
    .clk(clk), .we(dst_we), .addr(dst_addr), .din(dst_din), .dout() 
  );

  
  wire [14:0] bus_d14_0;
  wire        d15_raw, d15_after_err;
  wire        parity_even;
  wire        req, ack;

  transmitter #(ADDR_W, WIDTH) TX (
    .clk(clk), .rst(rst),
    .src_start(src_start),
    .src_addr(src_addr), .src_dout(src_dout),
    .req(req), .ack(ack), .full(full),
    .bus_d14_0(bus_d14_0), .d15_raw(d15_raw), .parity_even(parity_even),
    .done(done)
  );

  err_inject ERR (.clk(clk), .in_bit(d15_raw), .out_bit(d15_after_err));

  receiver #(ADDR_W, WIDTH) RX (
    .clk(clk), .rst(rst),
    .dst_start(dst_start),
    .bus_d14_0(bus_d14_0), .d15_after_err(d15_after_err),
    .parity_even(parity_even), .req(req),
    .ack(ack), .full(full),
    .dst_addr(dst_addr), .dst_we(dst_we), .dst_din(dst_din)
  );
endmodule