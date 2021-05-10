module cache #(
    parameter NUM_LINES=2,
    parameter CPU=1
)(
    input clk_i,
    input rst_i,

    // Bus messages
    // BusRd   - 00
    // BusRdX  - 01
    // BusUpgr - 10
    // Flush   - 11
    input [1:0] bus_msg_i,
    input [NUM_LINES-1:0] addr_i,

    // Processor requests
    output pr_rd_o,
    output pr_wr_o,
    output [NUM_LINES-1:0] addr_o,

    // Processor Data
    input  data_valid_i,
    output data_valid_o,

    // Stimulus
    input do_rd_i,
    input do_wr_i,
    input [NUM_LINES-1] addr_i
);

// Bus messages
localparam BUS_RD    = 0;
localparam BUS_RDX   = 1
localparam BUS_UPGR  = 2;
localparam BUS_FLUSH = 3;

localparam NUM_STATES = 6;
localparam STATES_WIDTH = 3;
// States are:
localparam INVALID  = 0;
localparam INV2SHA  = 1;
localparam INV2MOD  = 2;
localparam SHARED   = 3;
//localparam SHA2MOD  = 4;
localparam MODIFIED = 5;

reg [STATES_WIDTH-1:0] line_state [NUM_LINES-1:0];
wire [STATES_WIDTH-1:0] nxt_line_state [NUM_LINES-1:0];

always(@posedge clk_i) begin
    if (!rst_i) begin
        for (integer i = 0; i < NUM_LINES; i++) begin
            line_state[i] <= '0;
        end
    end
    else begin
        for (integer i = 0; i < NUM_LINES; i++) begin
            line_state[i] <= nxt_line_state[i];
        end
    end
end

always@(*) begin
    if (!rst_i) begin
        for (integer i = 0; i < NUM_LINES; i++) begin
            if (line_state[i] == INVALID) begin
                if (pr_rd_o && addr_o == i) nxt_line_state[i] = INV2SHA;
                else if (pr_wr_o && addr_o == i) nxt_line_state[i] = INV2MOD;
                else nxt_line_state[i] = INVALID;
            end
            if (line_state[i] == SHARED) begin
                if (pr_wr_o && addr_o == i) nxt_line_state[i] = MODIFIED;
                else if (bus_msg_i == BUS_RDX && addr_i == i) nxt_line_state[i] = INVALID;
                else if (bus_msg_i == BUS_UPGR && addr_i == i) nxt_line_state[i] = INVALID;
                else nxt_line_state[i] = SHARED;
            end
            if (line_state[i] == MODIFIED) begin
                if (bus_msg_i == BUS_RD && addr_i == i) nxt_line_state[i] = SHARED;
                else if (bus_msg_i == BUS_RDX && addr_i == i) nxt_line_state[i] = INVALID;
                else nxt_line_state[i] = MODIFIED;
            end
            if (line_state[i] == INV2SHA) begin
                if (data_valid_i && addr_i == i) nxt_line_state[i] = SHARED; 
                else nxt_line_state[i] = INV2SHA;
            end
            if (line_state[i] == INV2MOD) begin
                if (data_valid_i && addr_i == i) nxt_line_state[i] = MODIFIED;
                else nxt_line_state[i] = INV2MOD;
            end
        end
    end
end

endmodule
