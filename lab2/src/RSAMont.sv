module RsaMont (
    input          i_clk,
    input          i_rst,
    input          i_start, 
    input  [255:0] i_a,
    input  [255:0] i_b, 
    input  [255:0] i_n, 
    output [255:0] o_a_mont,
    output         o_mont_finished
);
// ===== States =====
parameter IDLE = 1'b0;
parameter CALC = 1'b1;

// ===== Output Buffers =====
logic [258:0] o_a_mont_r, o_a_mont_w;
logic         o_mont_finished_r, o_mont_finished_w;

// ===== Registers and Wires =====
logic         state_r, state_w;
logic [8:0]   cycle_r, cycle_w;
logic [255:0] a_bitwise_r, a_bitwise_w;

// ===== Output Assignments =====
assign o_a_mont        = o_a_mont_r[255:0];
assign o_mont_finished = o_mont_finished_r;

// ===== Combinational Circuits =====
always_comb begin
    // Default Values 
    o_a_mont_w        = o_a_mont_r;
    o_mont_finished_w = o_mont_finished_r;
    state_w           = state_r;
    cycle_w           = cycle_r;
    a_bitwise_w       = a_bitwise_r;
    // FSM
    case (state_r)
    IDLE: begin
        // $display("mont_idle");
        o_mont_finished_w = 1'b0;
        o_a_mont_w        = 259'b0;
        if (i_start) begin
            state_w           = CALC;
            a_bitwise_w       = i_a;
        end
    end
    CALC: begin
        // $display("mont_calc");
        if (cycle_r == 9'b1_0000_0000) begin
            if (o_a_mont_r >= {4'b0, i_n}) begin
                o_a_mont_w = o_a_mont_r - i_n;
            end
            cycle_w = cycle_r + 1;
        end
        else if (cycle_r == 9'b1_0000_0001) begin
            o_mont_finished_w = 1'b1;
            state_w           = IDLE;
            cycle_w           = 9'b0;
        end
        else begin
            if (a_bitwise_r[0] == 1'b1) begin
                if (o_a_mont_r[0] ^ i_b[0]) begin
                    o_a_mont_w = (o_a_mont_r + i_b + i_n) >> 1;
                end
                else begin
                    o_a_mont_w = (o_a_mont_r + i_b) >> 1;
                end
            end
            else begin
                if (o_a_mont_r[0]) begin
                    o_a_mont_w = (o_a_mont_r + i_n) >> 1;
                end
                else begin
                    o_a_mont_w = o_a_mont_r >> 1;
                end
            end
            cycle_w     = cycle_r + 1;
            a_bitwise_w = a_bitwise_r >> 1;
        end
    end
    endcase
end

// ===== Sequential Circuits =====
always_ff @( posedge i_clk or posedge i_rst ) begin
    // reset
    if (i_rst) begin
        o_a_mont_r        <= 259'b0;
        o_mont_finished_r <= 1'b0;
        state_r           <= IDLE;
        cycle_r           <= 9'b0;
        a_bitwise_r       <= 256'b0;

    end
    else begin
        o_a_mont_r        <= o_a_mont_w;
        o_mont_finished_r <= o_mont_finished_w;
        state_r           <= state_w;
        cycle_r           <= cycle_w;
        a_bitwise_r       <= a_bitwise_w;
    end
end
endmodule