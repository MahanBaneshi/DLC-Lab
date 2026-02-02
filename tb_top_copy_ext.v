`timescale 1ns/1ps

module tb_top_copy_ext;
  localparam ADDR_W=12, WIDTH=16;

  reg clk=0, rst=1;
  always #5 clk = ~clk; // 100MHz

  reg [ADDR_W-1:0] src_start = 12'd0;
  reg [ADDR_W-1:0] dst_start = 12'd100;

  wire done, full;

  // DUT
  top_copy #(ADDR_W, WIDTH) DUT (
    .clk(clk), .rst(rst),
    .src_start(src_start), .dst_start(dst_start),
    .done(done), .full(full)
  );

  integer i;

  // ===== VCD dump for GTKWave =====
  initial begin
    $dumpfile("copy.vcd");
    $dumpvars(0, tb_top_copy_ext);
  end

  task print_dst(input integer a0, input integer a1);
    integer k;
    begin
      $display("== DST @%0d..%0d ==", a0, a1);
      for (k=a0; k<=a1; k=k+1)
        $display("%0d : %h", k, DUT.DST_MEM.mem[k]);
    end
  endtask

  task clear_dst_range(input integer a0, input integer a1);
    integer k;
    begin
      for (k=a0; k<=a1; k=k+1) DUT.DST_MEM.mem[k] = 16'h0000;
    end
  endtask

  task wait_done_or_full(input integer cycles, input [8*32-1:0] tag);
    integer c;
    begin
      c = 0;
      while (!(done || full) && c < cycles) begin
        @(posedge clk);
        c = c + 1;
      end
      if (done) $display("[%s] DONE asserted at t=%0t", tag, $time);
      if (full) $display("[%s] FULL asserted at t=%0t", tag, $time);
      if (!(done || full)) $display("[%s] TIMEOUT after %0d cycles", tag, cycles);
      repeat (5) @(posedge clk);
    end
  endtask

  initial begin
    rst = 1;
    src_start = 12'd0;
    dst_start = 12'd100;

    DUT.SRC_MEM.mem[0] = 16'h1234;
    DUT.SRC_MEM.mem[1] = 16'hABCD;
    DUT.SRC_MEM.mem[2] = 16'h0ACE;
    DUT.SRC_MEM.mem[3] = 16'hFFFF; // Sentinel
    for (i=4; i<32; i=i+1) DUT.SRC_MEM.mem[i] = 16'hDEAD; 

    clear_dst_range(  0, 200);
    @(posedge clk); @(posedge clk);
    rst = 0;

    $display("\n--- Scenario 1: Normal + Sentinel ---");
    wait_done_or_full(200, "S1");
    print_dst(100, 108);

    rst = 1;
    @(posedge clk);
    src_start = 12'd10;
    dst_start = 12'd200;

    DUT.SRC_MEM.mem[10] = 16'h55AA; 
    DUT.SRC_MEM.mem[11] = 16'hFFFF; 
    clear_dst_range(190, 220);
    @(posedge clk); rst = 0;

    $display("\n--- Scenario 2: Controlled Error Injection on D15 ---");
    repeat (6) @(posedge clk); 
    force DUT.ERR.lfsr = 3'b111;
    @(posedge clk); 
    release DUT.ERR.lfsr;

    wait_done_or_full(300, "S2");
    print_dst(198, 205);

    rst = 1;
    @(posedge clk);
    src_start = 12'd20;
    dst_start = 12'd4094;

    DUT.SRC_MEM.mem[20] = 16'h1111;
    DUT.SRC_MEM.mem[21] = 16'h2222;
    DUT.SRC_MEM.mem[22] = 16'hFFFF; 
    @(posedge clk); rst = 0;

    $display("\n--- Scenario 3: Destination FULL ---");
    wait_done_or_full(200, "S3");
    print_dst(4092, 4095);

    rst = 1;
    @(posedge clk);
    src_start = 12'd4093;
    dst_start = 12'd300;

    DUT.SRC_MEM.mem[4093] = 16'hA001;
    DUT.SRC_MEM.mem[4094] = 16'hA002;
    DUT.SRC_MEM.mem[4095] = 16'hA003; 
    clear_dst_range(290, 310);
    @(posedge clk); rst = 0;

    $display("\n--- Scenario 4: Source reaches LAST_ADDR (no Sentinel) ---");
    wait_done_or_full(300, "S4");
    print_dst(300, 306);

    $display("\nAll scenarios finished at t=%0t", $time);
    $finish;
  end
endmodule
