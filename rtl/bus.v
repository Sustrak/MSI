module bus (
    input clk_i,
    input rst_i,

    inout [CACHE_LINE_SIZE-1:0] mem_data_io,//Basicament per fer flushes, tecnicament tambe serveix per portar les dades desde memoria
    inout [ADDR_SIZE-1:0] mem_addr_io
);

parameter NUM_LINES=2;
parameter NUM_PROCS=4;
parameter ADDR_SIZE=32;
parameter CACHE_LINE_SIZE=128;

reg bus_state; //Estat del bus. 0->Esperant peticio, 1->Bus cedit a 1 proc
reg [1:0] cnt;
reg [NUM_PROCS-1:0] msg_pending;

wire nxt_bus_state;
wire mem_data_valid;
wire cache_data_valid;
wire [NUM_LINES-1:0] req_addr;

wire [NUM_PROCS-1:0] pr_rd_req_i; 
wire [NUM_PROCS-1:0] pr_rd_req_o;
wire [NUM_PROCS-1:0] pr_wr_req;
wire [NUM_PROCS-1:0] pr_bus_req;

//Decisio de qui guanya acces al bus
always @(*) begin
    if(!bus_state) begin
        case (cnt)
            2'b00 : begin
                if (pr_rd_req_i[0] == 1'b1) pr_rd_req_o <= 1;
                else if (pr_rd_req_i[1] == 1'b1) pr_rd_req_o <= 2;
                else if (pr_rd_req_i[2] == 1'b1) pr_rd_req_o <= 4;
                else if (pr_rd_req_i[3] == 1'b1) pr_rd_req_o <= 8;
            end
            2'b01 : begin
                if (pr_rd_req_i[1] == 1'b1) pr_rd_req_o <= 2;
                else if (pr_rd_req_i[2] == 1'b1) pr_rd_req_o <= 4;
                else if (pr_rd_req_i[3] == 1'b1) pr_rd_req_o <= 8;
                else if (pr_rd_req_i[0] == 1'b1) pr_rd_req_o <= 1;
            end
            2'b10 : begin
                if (pr_rd_req_i[2] == 1'b1) pr_rd_req_o <= 4;
                else if (pr_rd_req_i[3] == 1'b1) pr_rd_req_o <= 8;
                else if (pr_rd_req_i[4] == 1'b1) pr_rd_req_o <= 1;
                else if (pr_rd_req_i[0] == 1'b1) pr_rd_req_o <= 2;
            end
            2'b11 : begin
                if (pr_rd_req_i[3] == 1'b1) pr_rd_req_o <= 8;
                else if (pr_rd_req_i[0] == 1'b1) pr_rd_req_o <= 1;
                else if (pr_rd_req_i[1] == 1'b1) pr_rd_req_o <= 2;
                else if (pr_rd_req_i[2] == 1'b1) pr_rd_req_o <= 4;
            end
            default: ;
        endcase
    else
        pr_rd_req_o <= 0;
    end
end

//Comptador per assignar prioritats rotatives en el bus. S'incrementa a cada cicle.
//Si cnt=2 la prioritat sera: 2-3-0-1
always @ (posedge clk) begin
    if(rst_i)
        cnt <= 2'b00;
    else
        cnt <= cnt + 1; 
end

//Decisio del seguent estat del bus
always @ (*) begin
    if(rst_i)
        nxt_bus_state = 0;
    else
        case (bus_state)
            0: nxt_bus_state = |pr_rd_req_i; //Aixo val en Verilog? xD
            1: nxt_bus_state = 0;
            default: ;
        endcase
end

always @ (posedge clk) begin
    if(rst_i)
        bus_state <= 0;
    else
        bus_state <= nxt_bus_state;
end

cache #(
    NUM_LINES=2
) c0 (
    .clk_i (clk_i),
    .rst_i (rst_i),
    .bus_msg_i (),
    pr_bus_req_o(pr_bus_req_i[0]);
    pr_bus_req_i(pr_bus_req_o[0])
    pr_rd_o (pr_rd_req[0]),
    pr_wr_o (pr_wr_req[0]),
    addr_o (),
    do_rd_i (),
    do_wr_i (),
    addr_i ()
);


endmodule
