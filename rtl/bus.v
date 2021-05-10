module bus (
);

parameter NUM_LINES=2;
parameter NUM_PROCS=4;

reg [NUM_PROCS-1:0] msg_pending;

wire mem_data_valid;
wire cache_data_valid;
wire [NUM_LINES-1:0] req_addr;

cache #(
    NUM_LINES=2
) c0 (
    .clk_i (clk),
    .rst_i (rst),
    .bus_mgs_i (),
    pr_rd_o (),
    pr_wr_o (),
    addr_o (),
    do_rd_i (),
    do_wr_i (),
    addr_i ()
);

endmodule
