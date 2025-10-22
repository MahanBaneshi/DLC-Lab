`timescale 1ns/1ps
`include "ev.v"

module ev_tb;

`ifdef FAST_TB
  localparam integer TCLK_HALF = 1;   
  localparam integer GAP_S = 2;
  localparam integer GAP_M = 4;
  localparam integer GAP_L = 6;
`else
  localparam integer TCLK_HALF = 5;
  localparam integer GAP_S = 8;
  localparam integer GAP_M = 20;
  localparam integer GAP_L = 30;
`endif

  // ==== Inputs
  reg        clk     = 1'b0;
  reg        rst     = 1'b1;
  reg  [5:0] f       = 6'b0;    // F1..F6
  reg  [9:0] du      = 10'b0;   // [D6 D5 D4 D3 D2 U5 U4 U3 U2 U1]
  reg  [5:0] sensors = 6'b0;    // one-hot S1..S6
  reg        emg     = 1'b0;

  // ==== Outputs
  wire [1:0] ac;     // 00 idle, 01 up, 10 down
  wire [2:0] disp;   // 1..6 (0=unknown)
  wire       open;

  // ==== DUT
  elevator_control dut (
    .clk(clk), .rst(rst),
    .f(f), .du(du), .sensors(sensors),
    .emg(emg),
    .ac(ac), .disp(disp), .open(open)
  );

  // ==== Clock
  always #TCLK_HALF clk = ~clk;

  // ==== Helpers
  integer i;

  task set_floor; input integer fl;
    begin sensors = 6'b0; if (fl>=1 && fl<=6) sensors[fl-1] = 1'b1; end
  endtask

  task press_f; input integer fl;
    begin f=6'b0; if (fl>=1 && fl<=6) begin f[fl-1]=1'b1; # (2*TCLK_HALF); f=6'b0; end end
  endtask

  task press_u; input integer fl; integer bitidx;
    begin if (fl>=1 && fl<=5) begin bitidx=fl-1; du=10'b0; du[bitidx]=1'b1; # (2*TCLK_HALF); du=10'b0; end end
  endtask

  task press_d; input integer fl; integer bitidx;
    begin if (fl>=2 && fl<=6) begin bitidx=5+(fl-2); du=10'b0; du[bitidx]=1'b1; # (2*TCLK_HALF); du=10'b0; end end
  endtask

  // بین‌طبقات چند سیکل صبر کن (فقط وقتی open=0 است از این استفاده می‌کنیم)
  task travel_gap; input integer cycles;
    begin sensors=6'b0; for (i=0;i<cycles;i=i+1) @(posedge clk); end
  endtask

  // صبر تا باز شدن در (با timeout)
  task wait_until_open;
    integer guard;
    begin
      guard = 0;
      while (!open && guard < 10000) begin @(posedge clk); guard = guard + 1; end
      if (!open) begin
        $display("[FAIL] Timeout waiting for OPEN @ %0t", $time);
        $finish;
      end
    end
  endtask

  // صبر تا بسته شدن در (با timeout)
  task wait_until_close;
    integer guard;
    begin
      guard = 0;
      while (open && guard < 10000) begin @(posedge clk); guard = guard + 1; end
      if (open) begin
        $display("[FAIL] Timeout waiting for CLOSE @ %0t", $time);
        $finish;
      end
    end
  endtask

  // assert-like helper
  task must; input cond; input [2047:0] msg;
    begin if (!cond) begin $display("[FAIL] %0s @ %0t", msg,$time); $finish; end
         else $display("[OK]   %0s @ %0t", msg,$time); end
  endtask

  // ==== Checks عمومی (همان قبلی؛ با سناریوی جدید دیگر تریگر نمی‌شود)
  always @(posedge clk) begin
    if (open && sensors==6'b0) begin
      $display("[CHK][FAIL] Door OPEN while not at floor @%0t",$time); $finish;
    end
    if ((ac==2'b01 || ac==2'b10) && sensors!=6'b0) begin
      $display("[CHK][FAIL] Moving while sensor ON @%0t",$time); $finish;
    end
  end

  // ==== Test Scenarios
  initial begin
    $dumpfile("ele6.vcd");
    $dumpvars(0, ev_tb);

    // Reset & start at floor 1
    set_floor(1); repeat(4) @(posedge clk); rst=0; repeat(4) @(posedge clk);

    // A) FIFO: F6 then U3 (اول 3 بعد 6)
    press_f(6);
    # (6*TCLK_HALF) press_u(3);
    // حرکت به 2 سپس 3
    travel_gap(GAP_S); set_floor(2);
    travel_gap(GAP_S); set_floor(3);
    // منتظر باز شدن و بسته شدن در روی 3
    wait_until_open();  must(open, "OPEN at floor 3");
    must(ac==2'b00, "Motor idle while OPEN at 3");
    // تا وقتی بسته نشده، سنسور را دست نزن
    wait_until_close();

    // ادامه به سمت 6
    travel_gap(GAP_M); set_floor(4);
    travel_gap(GAP_S); set_floor(5);
    travel_gap(GAP_S); set_floor(6);
    wait_until_open();  must(open, "OPEN at floor 6");
    wait_until_close();

    // B) Limit top
    repeat(5) @(posedge clk); must(ac!=2'b01, "No UP at top floor");

    // C) Emergency mid-move
    press_f(2);
    travel_gap(GAP_S);
    emg=1;
    travel_gap(GAP_S); set_floor(5);
    wait_until_open(); must(open, "EMG: OPEN at next floor");
    repeat(GAP_M) @(posedge clk); must(open, "EMG hold");
    emg=0; wait_until_close(); must(!open, "EMG released (closed)");

    // D) multi demand F2, F4, U1
    press_f(2); # (2*TCLK_HALF) press_f(4); # (2*TCLK_HALF) press_u(1);
    travel_gap(GAP_S); set_floor(4); wait_until_open(); must(open,"Serve F4"); wait_until_close();
    travel_gap(GAP_M); set_floor(2); wait_until_open(); must(open,"Serve F2"); wait_until_close();
    travel_gap(GAP_M); set_floor(1); wait_until_open(); must(open,"Serve U1"); wait_until_close();

    // E) Limit bottom
    repeat(5) @(posedge clk); must(ac!=2'b10, "No DOWN at bottom");

    // F) De-dup (همان طبقه چندبار)
    set_floor(3); repeat(2) @(posedge clk);
    press_f(3); #10 press_f(3); #10 press_u(3);
    wait_until_open(); must(open, "De-dup served once (floor 3)"); wait_until_close();
    repeat(50) @(posedge clk); must(ac==2'b00, "No extra move after de-dup");

    // G) Overflow ملایم
    for (i=1;i<=6;i=i+1) press_f(i);
    for (i=1;i<=5;i=i+1) press_u(i);
    press_d(6);
    $display("[INFO] Queue overflow poke done");

    // H) EMG on floor
    set_floor(4); repeat(2) @(posedge clk); emg=1;
    wait_until_open(); must(open, "EMG on floor → OPEN hold");
    emg=0; wait_until_close(); must(!open, "EMG release on floor");

    // I) EMG while OPEN
    set_floor(2); press_f(2);
    wait_until_open(); must(open,"Door OPEN for EMG test");
    emg=1; repeat(10) @(posedge clk); must(open && ac==2'b00, "EMG while OPEN");
    emg=0; wait_until_close(); must(!open, "EMG released from OPEN");

    // J) Reset mid-move
    press_f(6); travel_gap(4); rst=1; repeat(4) @(posedge clk); rst=0;
    repeat(6) @(posedge clk); must(ac==2'b00,"Reset mid-move → idle");

    // K) Hall extremes: U5, D6
    set_floor(4); press_u(5);
    travel_gap(GAP_S); set_floor(5); wait_until_open(); must(open,"U5 served at 5"); wait_until_close();
    travel_gap(GAP_S); set_floor(6); press_d(6); wait_until_open(); must(open,"D6 served at 6"); wait_until_close();

    $display("\n[TB] All scenarios completed successfully.");
    # (20*TCLK_HALF) $finish;
  end

endmodule
