module cache #(
    parameter NUM_LINES=2,
    parameter CPU=1
)(
    input clk_i,
    input rst_i,

    // Bus messages
    // BusIdle - 0
    // BusRd   - 1
    // BusRdX  - 2
    // BusUpgr - 3
    input  [2:0] bus_msg_i,
    input  [NUM_LINES-1:0] addr_i,
    output [2:0] bus_msg_o,
    output [NUM_LINES-1:0] addr_o,
    input  pr_bus_req_i,
    output pr_bus_req_o,

    input  data_valid_i,
    output flush_o,

    // Stimulus
    input test_rd_i,
    input test_wr_i,
    input [NUM_LINES-1] test_addr_i
);

// Bus messages
localparam BUS_IDLE  = 0;
localparam BUS_RD    = 1;
localparam BUS_RDX   = 2;
localparam BUS_UPGR  = 3;

localparam NUM_STATES = 3;
localparam STATES_WIDTH = 2;
// States are:
localparam INVALID  = 0;
localparam SHARED   = 1;
localparam MODIFIED = 2;

reg [STATES_WIDTH-1:0] line_state [NUM_LINES-1:0];
wire [STATES_WIDTH-1:0] nxt_line_state [NUM_LINES-1:0];

reg [OP_WIDTH-1:0] op;
reg [NUM_LINES-1:0] op_addr;

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

// Next state of the cache
always@(*) begin
    if (!rst_i) begin
        for (integer i = 0; i < NUM_LINES; i++) begin
            if (line_state[i] == INVALID) begin
                if (pr_rd_o && addr_o == i) nxt_line_state[i] =SHARED;
                else if (pr_wr_o && addr_o == i) nxt_line_state[i] = MODIFIED;
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
        end
    end
end

// Bus messages
always @(*) begin
    if (!rst_i) begin
        if (line_state[op_addr] == INVALID) begin
            if (op == READ && pr_bus_req_i) bus_msg_o = BUS_RD;
            else if (op == WRITE && pr_bus_req_i) bus_msg_o = BUS_RDX;
            else bus_msg_o = BUS_IDLE;
        end
        else if (line_state[op_addr] == SHARED) begin
            if (op == WRITE && pr_bus_req_i) bus_msg_o = BUS_UPGR;
            else bus_msg_o = BUS_IDLE;
        end
        else bus_msg_o = BUS_IDLE;
    end
end

// Flush
always @(*) begin
    if (!rst_i) begin
        if (bus_msg_i == BUS_RD  && line_state[addr_i] == MODIFIED || 
            bus_msg_i == BUS_RDX && line_state[addr_i] == MODIFIED    ) begin
            flush_o = 1'b1;
        end
        else begin
            flush_o = 0;
        end
    end
end

// Test operations
always @(posedge clk_i) begin
    if (!rst_i) begin
        if (op != IDLE) begin
            if (test_rd_i) op <= READ;
            else if (test_wr_i) op <= WRITE;
            op_addr <= test_addr_i;
        end
    end
end

// Request bus
always @(*) begin
    if (!rst_i) begin
        if (!bus_requested && (op != IDLE || test_rd_i || test_wr_i)) begin
            pr_bus_req_o = 1'b1;
        end
        else begin
            pr_bus_req_o = 0;
        end
    end
end

always @(posedge clk_i) begin
    if (rst_i) begin
        bus_requested <= 1'b0;
    else begin
        if (pr_bus_req_o) bus_requested <= 1'b1;
        else if (pr_bus_req_i) bus_requested <= 1'b0;
    end
end


endmodule
