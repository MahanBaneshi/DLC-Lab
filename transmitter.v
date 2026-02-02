module transmitter
#( parameter ADDR_W = 12,
   parameter WIDTH  = 16
 )
(
  input                   clk,       
  input                   rst,

  input      [ADDR_W-1:0] src_start,

  output reg [ADDR_W-1:0] src_addr,
  input      [WIDTH-1:0]  src_dout,

  output reg              req,
  input                   ack,
  input                   full,

  output reg [14:0]       bus_d14_0,  
  output reg              d15_raw,      
  output reg              parity_even,  

  output reg              done
);
  localparam [WIDTH-1:0] SENTINEL = 16'hFFFF;
  localparam [ADDR_W-1:0] LAST_ADDR = (1<<ADDR_W) - 1;

  reg [ADDR_W-1:0] rd_addr;
  reg have_word;           

  reg [WIDTH-1:0] cur_word;

  function parity_even16;
    input [15:0] x;
    begin
      parity_even16 = ~(^x);
    end
  endfunction

  // start
  always @(negedge clk or posedge rst) begin
    if (rst) begin
      rd_addr   <= src_start;
      src_addr  <= src_start;
      have_word <= 1'b0;
      req       <= 1'b0;
      done      <= 1'b0;
    end else begin
      if (done || full) begin
        req <= 1'b0;
      end
      else begin
        if (have_word && !ack) begin
          req <= 1'b1; 
        end
        else if (have_word && ack) begin
          have_word <= 1'b0;
          req       <= 1'b0;
          if (cur_word == SENTINEL || rd_addr == LAST_ADDR) begin
            done <= 1'b1;
          end else begin
            src_addr <= rd_addr + 1'b1;
            rd_addr  <= rd_addr + 1'b1;
          end
        end
        else if (!have_word) begin
          cur_word   <= src_dout;
          bus_d14_0  <= src_dout[14:0];
          d15_raw    <= src_dout[15];
          parity_even<= parity_even16(src_dout);
          have_word  <= 1'b1;
          req        <= 1'b1;
        end
      end
    end
  end
endmodule