// elevator_control_6f.v
`timescale 1ns/1ps
module elevator_control (
    input        clk,
    input        rst,
    input  [5:0] f,          // F1..F6
    input  [9:0] du,         // [D6 D5 D4 D3 D2 U5 U4 U3 U2 U1]  (total 10 bits)
    input  [5:0] sensors,    // one-hot S1..S6
    input        emg,        // emergency stop
    output reg [1:0] ac,     // 00 idle, 01 up, 10 down
    output reg [2:0] disp,   // 1..6 (0=unknown)
    output reg    open
);
    localparam integer FLOORS     = 6;
    localparam integer QDEPTH     = 12;
    localparam integer DOOR_TICKS = 50;

    // ---------- sensor → index & display ----------
    reg [2:0] cur_idx;
    wire at_any = |sensors;

    function [2:0] sens_to_idx(input [FLOORS-1:0] s);
        integer i; begin
            sens_to_idx = cur_idx;
            for (i=0;i<FLOORS;i=i+1) if (s[i]) begin sens_to_idx = i[2:0]; end
        end
    endfunction

    always @(posedge clk or posedge rst) begin
        if (rst) begin disp<=0; cur_idx<=0; end
        else if (at_any) begin cur_idx<=sens_to_idx(sensors); disp<=sens_to_idx(sensors)+3'd1; end
    end

    // ---------- edge detect ----------
    reg [FLOORS-1:0] f_p;
    reg [(2*FLOORS-2)-1:0] du_p; // 10 bits when FLOORS=6
    wire [FLOORS-1:0] f_rise  = f  & ~f_p;
    wire [(2*FLOORS-2)-1:0] du_rise = du & ~du_p;
    always @(posedge clk or posedge rst) begin
        if (rst) begin f_p<=0; du_p<=0; end
        else begin f_p<=f; du_p<=du; end
    end

    // ---------- pending & FIFO (press-order priority) ----------
    reg [FLOORS-1:0] pending;
    reg [2:0] q_mem [0:QDEPTH-1];
    reg [$clog2(QDEPTH):0] qh, qt;
    wire q_empty = (qh==qt);
    wire q_full  = ((qt+1)%QDEPTH)==qh;
    wire [2:0] q_peek = q_mem[qh];
    task q_push(input [2:0] fl); begin if (!q_full) begin q_mem[qt]<=fl; qt<=(qt+1)%QDEPTH; end end endtask
    task q_pop; begin if (!q_empty) qh <= (qh+1)%QDEPTH; end endtask

    // Map du: U1..U5 at bits [0..FLOORS-2], D2..D6 at bits [FLOORS-1..2*FLOORS-3]
    integer k;
    always @(posedge clk or posedge rst) begin
        if (rst) begin pending<=0; qh<=0; qt<=0; end
        else begin
            // cabin buttons F1..F6
            for (k=0;k<FLOORS;k=k+1) if (f_rise[k] && !pending[k]) begin pending[k]<=1; q_push(k[2:0]); end
            // hall Up: floors 1..5 (index 0..4)
            for (k=0;k<FLOORS-1;k=k+1) if (du_rise[k] && !pending[k]) begin pending[k]<=1; q_push(k[2:0]); end
            // hall Down: floors 2..6 (index 1..5) start at bit offset (FLOORS-1)
            for (k=1;k<FLOORS;k=k+1) if (du_rise[(FLOORS-1)+(k-1)] && !pending[k]) begin pending[k]<=1; q_push(k[2:0]); end
            // clear when served
            if (state==S_OPEN && at_any) begin
                pending[cur_idx] <= 1'b0;
                if (!q_empty && q_peek==cur_idx) q_pop();
            end
        end
    end

    // ---------- FSM ----------
    localparam [2:0] S_IDLE=3'd0, S_UP=3'd1, S_DOWN=3'd2, S_OPEN=3'd3, S_EMG_MOV=3'd4, S_EMG_HLD=3'd5;
    reg [2:0] state, state_n;
    reg dir_up;
    reg [15:0] door_cnt;

    wire at_top    = at_any && (cur_idx == (FLOORS-1));
    wire at_bottom = at_any && (cur_idx == 3'd0);

    always @* begin
        state_n = state; open=1'b0; ac=2'b00;
        case (state)
            S_IDLE: begin
                if (emg) begin
                    state_n = at_any ? S_EMG_HLD : S_EMG_MOV;
                end else if (!q_empty && at_any) begin
                    if (q_peek > cur_idx && !at_top)      state_n = S_UP;
                    else if (q_peek < cur_idx && !at_bottom) state_n = S_DOWN;
                    else                                   state_n = S_OPEN;
                end
            end
            S_UP: begin
                ac=2'b01;
                if (emg) state_n = S_EMG_MOV;
                else if (at_top) state_n = S_OPEN;
                else if (at_any && (cur_idx==q_peek)) state_n = S_OPEN;
            end
            S_DOWN: begin
                ac=2'b10;
                if (emg) state_n = S_EMG_MOV;
                else if (at_bottom) state_n = S_OPEN;
                else if (at_any && (cur_idx==q_peek)) state_n = S_OPEN;
            end
            S_OPEN: begin
                open=1'b1;
                if (door_cnt==0) state_n = emg ? S_EMG_HLD : S_IDLE;
            end
            S_EMG_MOV: begin
                if (dir_up && !at_top) ac=2'b01;
                else if (!dir_up && !at_bottom) ac=2'b10;
                else ac=2'b00;
                if (at_any) state_n = S_EMG_HLD;
            end
            S_EMG_HLD: begin
                open=1'b1; ac=2'b00;
                if (!emg) state_n = S_IDLE;
            end
        endcase
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin state<=S_IDLE; dir_up<=1'b1; door_cnt<=0; open<=0; ac<=2'b00; end
        else begin
            state <= state_n;
            if (state_n==S_UP)   dir_up<=1'b1;
            if (state_n==S_DOWN) dir_up<=1'b0;
            if (state_n==S_OPEN && state!=S_OPEN) door_cnt<=DOOR_TICKS;
            else if (state==S_OPEN && door_cnt!=0) door_cnt<=door_cnt-1;
        end
    end
endmodule
