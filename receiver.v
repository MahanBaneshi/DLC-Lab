module receiver
#( parameter ADDR_W = 12,
   parameter WIDTH  = 16
 )
(
  input                   clk,     // RX > 0
  input                   rst,

  input      [ADDR_W-1:0] dst_start,

  input      [14:0]       bus_d14_0,
  input                   d15_after_err, 
  input                   parity_even,
  input                   req,

  output reg              ack,
  output reg              full,

  output reg [ADDR_W-1:0] dst_addr,
  output reg              dst_we,
  output reg [WIDTH-1:0]  dst_din
);
  localparam [ADDR_W-1:0] LAST_ADDR = (1<<ADDR_W) - 1;

  function parity_even16;
    input [15:0] x;
    begin
      parity_even16 = ~(^x);
    end
  endfunction

  reg [ADDR_W-1:0] wr_addr;

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      ack     <= 1'b0;
      full    <= 1'b0;
      wr_addr <= dst_start;
      dst_addr<= dst_start;
      dst_we  <= 1'b0;
      dst_din <= {WIDTH{1'b0}};
    end else begin
      dst_we <= 1'b0; 

      if (full) begin
        ack <= 1'b0; 
      end
      else if (req) begin
        
        reg [15:0] word_rx;
        word_rx = {d15_after_err, bus_d14_0};

      
        if (parity_even16(word_rx) == parity_even) begin
          
          dst_din  <= word_rx;
          dst_addr <= wr_addr;
          dst_we   <= 1'b1;
          ack      <= 1'b1;

          if (wr_addr == LAST_ADDR) begin
            full <= 1'b1;
          end else begin
            wr_addr <= wr_addr + 1'b1;
          end
        end else begin
          ack <= 1'b0;
        end
      end else begin
        ack <= 1'b0; 
      end
    end
  end
endmodule