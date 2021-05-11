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

reg [1:0}bus_state; //Estat del bus. 0->Esperant peticio, 1->Bus cedit a 1 proc, 2
reg [1:0] cnt;
reg [1:0] proc_bus_owner;

wire nxt_bus_state;
wire [1:0]nxt_proc_bus_owner;

//wire [NUM_PROCS-1:0] pr_rd_req; 
//wire [NUM_PROCS-1:0] pr_wr_req;
wire [NUM_PROCS-1:0] pr_bus_req_i;
wire [NUM_PROCS-1:0] pr_bus_req_o;
wire [NUM_PROCS-1:0][1:0] pr_bus_msg_i;
wire [1:0] pr_bus_msg_o;
wire [NUM_PROCS-1:0][ADDR_SIZE-1:0] pr_addr_req_i; //Addr que es solicita a memoria
wire [ADDR_SIZE-1:0] pr_addr_req_o; //Addr per que els altres facin el snoopy
wire [NUM_PROCS-1:0] flush_i;

//Seleccio del missatge que es transmet pel bus
always @(*) begin
    if(bus_state) begin
        case (proc_bus_owner)
            2'b00 : begin
                pr_bus_msg_o <= pr_bus_msg_i[0];
                pr_addr_req_o <= pr_addr_req_i[0];
            end
            2'b01 : begin
                pr_bus_msg_o <= pr_bus_msg_i[1];
                pr_addr_req_o <= pr_addr_req_i[1];
            end
            2'b10 : begin
                pr_bus_msg_o <= pr_bus_msg_i[2];
                pr_addr_req_o <= pr_addr_req_i[2];
            end
            2'b11 : begin
                pr_bus_msg_o <= pr_bus_msg_i[3];
                pr_addr_req_o <= pr_addr_req_i[3];
            end
            default : ; 
        endcase
        bus_valid = 1;
    end
    else begin
        pr_bus_msg_o <= 0;
        pr_addr_req_o <= 0;
        bus_valid <= 0;
    end
end

//Decisio de qui guanya acces al bus
always @(*) begin
    if(!bus_state) begin
        case (cnt)
            2'b00 : begin
                if (pr_bus_req_i[0] == 1'b1) begin
                    pr_bus_req_o <= 1;
                    nxt_proc_bus_owner <= 0;
                end
                else if (pr_bus_req_i[1] == 1'b1) begin
                    pr_bus_req_o <= 2;
                    nxt_proc_bus_owner <= 1;
                end 
                else if (pr_bus_req_i[2] == 1'b1) begin
                    pr_bus_req_o <= 4;
                    nxt_proc_bus_owner <= 2;
                end
                else if (pr_bus_req_i[3] == 1'b1) begin
                    pr_bus_req_o <= 8;
                    nxt_proc_bus_owner <= 3;
                end
            end
            2'b01 : begin
                if (pr_bus_req_i[1] == 1'b1) begin
                    pr_bus_req_o <= 2;
                    nxt_proc_bus_owner <= 1;
                end
                else if (pr_bus_req_i[2] == 1'b1) begin
                    pr_bus_req_o <= 4;
                    nxt_proc_bus_owner <= 2;
                end 
                else if (pr_bus_req_i[3] == 1'b1) begin
                    pr_bus_req_o <= 8;
                    nxt_proc_bus_owner <= 3;
                end
                else if (pr_bus_req_i[0] == 1'b1) begin
                    pr_bus_req_o <= 1;
                    nxt_proc_bus_owner <= 0;
                end
            end
            2'b10 : begin
                if (pr_bus_req_i[2] == 1'b1) begin
                    pr_bus_req_o <= 4;
                    nxt_proc_bus_owner <= 2;
                end
                else if (pr_bus_req_i[3] == 1'b1) begin
                    pr_bus_req_o <= 8;
                    nxt_proc_bus_owner <= 3;
                end 
                else if (pr_bus_req_i[0] == 1'b1) begin
                    pr_bus_req_o <= 1;
                    nxt_proc_bus_owner <= 0;
                end
                else if (pr_bus_req_i[1] == 1'b1) begin
                    pr_bus_req_o <= 2;
                    nxt_proc_bus_owner <= 1;
                end
            end
            2'b11 : begin
                if (pr_bus_req_i[3] == 1'b1) begin
                    pr_bus_req_o <= 8;
                    nxt_proc_bus_owner <= 3;
                end
                else if (pr_bus_req_i[0] == 1'b1) begin
                    pr_bus_req_o <= 1;
                    nxt_proc_bus_owner <= 0;
                end 
                else if (pr_bus_req_i[1] == 1'b1) begin
                    pr_bus_req_o <= 2;
                    nxt_proc_bus_owner <= 1;
                end
                else if (pr_bus_req_i[2] == 1'b1) begin
                    pr_bus_req_o <= 4;
                    nxt_proc_bus_owner <= 2;
                end
            end
            default: ;
        endcase
    else
        pr_bus_req_o <= 0;
        nxt_proc_bus_owner <= 0;
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
        nxt_bus_state <= 0;
    else
        case (bus_state)
            0: nxt_bus_state <= |pr_bus_req_i; //Aixo val en Verilog? xD
            1: nxt_bus_state <= 0;
            default: ;
        endcase
end

always @ (posedge clk) begin
    if(rst_i)
        bus_state <= 0;
        proc_bus_owner <= 0;
    else
        bus_state <= nxt_bus_state;
        proc_bus_owner <= nxt_proc_bus_owner;
end

cache #(
    NUM_LINES=2
) c0 (
    .clk_i (clk_i),
    .rst_i (rst_i),
    .bus_msg_i (pr_bus_msg_i[0]),
    .bus_msg_o (pr_bus_msg_o),
    .flush_o (flush_i[0]);
    .data_flush_fake_o()
    pr_bus_req_o(pr_bus_req_i[0]);
    pr_bus_req_i(pr_bus_req_o[0])
    //pr_rd_o (pr_rd_req[0]),
    //pr_wr_o (pr_wr_req[0]),
    addr_o (pr_addr_req_i[0]),
    do_rd_i (),
    do_wr_i (),
    addr_i (pr_addr_req_o)
);


endmodule
