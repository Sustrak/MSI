module cache #(
    parameter NUM_LINES=2
)(
    input clk_i,
    input rst_i,

    // Bus messages
    // BusRd   - 00
    // BusRdX  - 01
    // BusUpgr - 10
    // Flush   - 11
    input [1:0] bus_mgs_i,

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


// States are:
localparam INVALID  = 00;
localparam SHARED   = 01;
localparam MODIFIED = 10;

reg [1:0] line_state [NUM_LINES-1:0];
wire [1:0] nxt_line_state [NUM_LINES-1:0];

always(@posedge clk_i) begin
    if (!rst_i) begin
        line_state <= '0;
    end
    else begin
        line_state <= nxt_line_state;
    end
end

always@(*) begin
    if (!rst_i) begin
        for (integer i = 0; i < NUM_LINES; i++) begin
            if (line_state[i] == INVALID) begin
            end
            if (line_state[i] == SHARED) begin
            end
            if (line_state[i] == MODIFIED) begin
            end
        end
    end
end

endmodule
