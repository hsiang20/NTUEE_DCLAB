module RsaPrep (
    input          i_clk, 
    input          i_rst,
    input          i_start,
    input  [255:0] i_a, //cipher text y
    input  [255:0] i_n, 
    output [255:0] o_a_mult, // y * (2 ^ 256) (mod N)
    output         o_prep_finished
);
// ===== States =====
parameter IDLE = 1'b0;
parameter CALC = 1'b1;

// ===== Output Buffers =====
logic [256:0] o_a_mult_r, o_a_mult_w;
logic         o_prep_finished_r, o_prep_finished_w;

// ===== Registers and Wires =====
logic         state_r, state_w;
logic [8:0]   cycle_r, cycle_w;
logic [256:0] iter_r, iter_w;

// ===== Output Assignments =====
assign o_a_mult        = o_a_mult_r[255:0];
assign o_prep_finished = o_prep_finished_r;

// ===== Combinational Circuits =====
always_comb begin
    // Default Values 
    o_a_mult_w        = o_a_mult_r;
    o_prep_finished_w = o_prep_finished_r;
    state_w           = state_r;
    cycle_w           = cycle_r;
    iter_w            = iter_r;
    // FSM
    case (state_r)
    IDLE: begin
        o_prep_finished_w = 1'b0;
        o_a_mult_w        = 257'b0;
        iter_w            = 257'b0;
        if (i_start) begin
            state_w           = CALC;
            cycle_w           = 9'b0;
            iter_w            = {1'b0, i_a};
        end
    end

    CALC: begin
        if (cycle_r == 9'b1_0000_0000) begin
            if (iter_r >= {1'b0, i_n}) begin
                o_a_mult_w    = iter_r - i_n;
            end
            else begin
                o_a_mult_w    = iter_r;
            end
            o_prep_finished_w = 1'b1;
            state_w           = IDLE;
            cycle_w           = 9'b0;
            iter_w            = i_a;
        end
        else begin
            cycle_w           = cycle_r + 1;
        end
        if (iter_r << 1 > {1'b0, i_n}) begin
            iter_w = (iter_r << 1) - i_n;
        end
        else begin
            iter_w = iter_r << 1;
        end
    end
    endcase
end

// ===== Sequential Circuits =====
always_ff @(posedge i_clk or posedge i_rst) begin
    // reset
    if (i_rst) begin
        o_a_mult_r        <= 257'b0;
        o_prep_finished_r <= 1'b0;
        state_r           <= IDLE;
        cycle_r           <= 8'b0;
        iter_r            <= {1'b0, i_a};
    end
    else begin
        o_a_mult_r        <= o_a_mult_w;
        o_prep_finished_r <= o_prep_finished_w;
        state_r           <= state_w;
        cycle_r           <= cycle_w;
        iter_r            <= iter_w;
    end
end

endmodule