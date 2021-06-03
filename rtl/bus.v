module bus (
    input clk_i,
    
    input [3:0] do_rd_i,
    input [3:0] do_wr_i,
    input [1:0] test_addr0_i,
    input [1:0] test_addr1_i,
    input [1:0] test_addr2_i,
    input [1:0] test_addr3_i
);



parameter NUM_LINES=2;
parameter NUM_PROCS=4;
parameter ADDR_SIZE=NUM_LINES;
parameter CACHE_LINE_SIZE=128;

reg bus_state; //Estat del bus. 0->Esperant peticio, 1->Bus cedit a 1 proc
reg [1:0] cnt;
reg [1:0] proc_bus_owner;

wire rst_i;
wire nxt_bus_state;
wire [1:0] nxt_proc_bus_owner;

wire [NUM_PROCS-1:0] pr_bus_req_i;
wire [NUM_PROCS-1:0] pr_bus_req_o;
wire [1:0] pr_bus_msg_i [NUM_PROCS-1:0];
wire [1:0] pr_bus_msg_o;
wire [ADDR_SIZE-1:0] pr_addr_req_i [NUM_PROCS-1:0]; //Addr que es solicita a memoria
wire [ADDR_SIZE-1:0] pr_addr_req_o; //Addr per que els altres facin el snoopy
wire flush_i [NUM_PROCS-1:0];
wire flush_o;
wire [CACHE_LINE_SIZE-1:0] data_flush_fake_i [NUM_PROCS-1:0];
wire data_flush_fake [NUM_PROCS-1:0];
wire data_fake_o [NUM_PROCS-1:0];

reg [1:0] rst_cnt;
reg rst_block;
initial rst_i = 0;

always @(posedge clk_i) begin
	if (!rst_i) begin
		rst_cnt <= rst_cnt +1;
	end
end
assign rst_i = rst_cnt == 3 ? 1 : 0;


//Seleccio del missatge que es transmet pel bus
always @(*) begin
    if(bus_state) begin
        case (proc_bus_owner)
            2'b00 : begin
                pr_bus_msg_o = pr_bus_msg_i[0];
                pr_addr_req_o = pr_addr_req_i[0];
            end
            2'b01 : begin
                pr_bus_msg_o = pr_bus_msg_i[1];
                pr_addr_req_o = pr_addr_req_i[1];
            end
            2'b10 : begin
                pr_bus_msg_o = pr_bus_msg_i[2];
                pr_addr_req_o = pr_addr_req_i[2];
            end
            2'b11 : begin
                pr_bus_msg_o = pr_bus_msg_i[3];
                pr_addr_req_o = pr_addr_req_i[3];
            end
            default : ; 
        endcase
        //bus_valid = 1;
    end
    else begin
        pr_bus_msg_o = 0;
        pr_addr_req_o = 0;
        //bus_valid = 0;
    end
end

//Logica del flush
always @(*) begin
    if(bus_state) begin
        case (proc_bus_owner)
            2'b00 : begin
                flush_o = flush_i[0];
                if(rst_i) assert(flush_i[1] == 0); //Nomes 1 processador pot fer flush
                if(rst_i) assert(flush_i[2] == 0);
                if(rst_i) assert(flush_i[3] == 0);
            end
            2'b01 : begin
                flush_o = flush_i[1];
                if(rst_i) assert(flush_i[0] == 0); //Nomes 1 processador pot fer flush
                if(rst_i) assert(flush_i[2] == 0);
                if(rst_i) assert(flush_i[3] == 0);
            end
            2'b10 : begin
                flush_o = flush_i[2];
                if(rst_i) assert(flush_i[0] == 0); //Nomes 1 processador pot fer flush
                if(rst_i) assert(flush_i[1] == 0);
                if(rst_i) assert(flush_i[3] == 0);
            end
            2'b11 : begin
                flush_o = flush_i[3];
                if(rst_i) assert(flush_i[0] == 0); //Nomes 1 processador pot fer flush
                if(rst_i) assert(flush_i[1] == 0);
                if(rst_i) assert(flush_i[2] == 0);
            end
            default : ; 
        endcase
    end
    else begin
        flush_o = 0;
    end
end

//Decisio de qui guanya acces al bus
always @(*) begin
    if(!bus_state) begin
        case (cnt)
            2'b00 : begin
                if (pr_bus_req_i[0] == 1'b1) begin
                    pr_bus_req_o = 4'h1;
                    nxt_proc_bus_owner = 0;
                end
                else if (pr_bus_req_i[1] == 1'b1) begin
                    pr_bus_req_o = 4'h2;
                    nxt_proc_bus_owner = 1;
                end 
                else if (pr_bus_req_i[2] == 1'b1) begin
                    pr_bus_req_o = 4'h4;
                    nxt_proc_bus_owner = 2;
                end
                else if (pr_bus_req_i[3] == 1'b1) begin
                    pr_bus_req_o <= 4'h8;
                    nxt_proc_bus_owner = 3;
                end
            end
            2'b01 : begin
                if (pr_bus_req_i[1] == 1'b1) begin
                    pr_bus_req_o = 4'h2;
                    nxt_proc_bus_owner = 1;
                end
                else if (pr_bus_req_i[2] == 1'b1) begin
                    pr_bus_req_o = 4'h4;
                    nxt_proc_bus_owner = 2;
                end 
                else if (pr_bus_req_i[3] == 1'b1) begin
                    pr_bus_req_o = 4'h8;
                    nxt_proc_bus_owner = 3;
                end
                else if (pr_bus_req_i[0] == 1'b1) begin
                    pr_bus_req_o = 4'h1;
                    nxt_proc_bus_owner = 0;
                end
            end
            2'b10 : begin
                if (pr_bus_req_i[2] == 1'b1) begin
                    pr_bus_req_o = 4'h4;
                    nxt_proc_bus_owner = 2;
                end
                else if (pr_bus_req_i[3] == 1'b1) begin
                    pr_bus_req_o = 4'h8;
                    nxt_proc_bus_owner = 3;
                end 
                else if (pr_bus_req_i[0] == 1'b1) begin
                    pr_bus_req_o = 4'h1;
                    nxt_proc_bus_owner = 0;
                end
                else if (pr_bus_req_i[1] == 1'b1) begin
                    pr_bus_req_o = 4'h2;
                    nxt_proc_bus_owner = 1;
                end
            end
            2'b11 : begin
                if (pr_bus_req_i[3] == 1'b1) begin
                    pr_bus_req_o = 4'h8;
                    nxt_proc_bus_owner = 3;
                end
                else if (pr_bus_req_i[0] == 1'b1) begin
                    pr_bus_req_o = 4'h1;
                    nxt_proc_bus_owner = 0;
                end 
                else if (pr_bus_req_i[1] == 1'b1) begin
                    pr_bus_req_o = 4'h2;
                    nxt_proc_bus_owner = 1;
                end
                else if (pr_bus_req_i[2] == 1'b1) begin
                    pr_bus_req_o = 4'h4;
                    nxt_proc_bus_owner = 2;
                end
            end
            default: ;
        endcase
    end
    else begin
        pr_bus_req_o = 0;
        nxt_proc_bus_owner = 0;
    end
    if (rst_i) begin
    assert( (pr_bus_req_o[0] + pr_bus_req_o[1] + pr_bus_req_o[2] + pr_bus_req_o[3]) <= 1); //Nomes un proc guanya acces al bus
    end
end

//Comptador per assignar prioritats rotatives en el bus. S'incrementa a cada cicle.
//Si cnt=2 la prioritat sera: 2-3-0-1
always @ (posedge clk_i) begin
    if(!rst_i)
        cnt <= 2'b00;
    else
        cnt <= cnt + 1; 
end

//Decisio del seguent estat del bus
always @ (*) begin
    if(!rst_i)
        nxt_bus_state = 0;
    else
        case (bus_state)
            0: nxt_bus_state = |pr_bus_req_i;
            1: nxt_bus_state = 0;
            default: ;
        endcase
end

always @ (posedge clk_i) begin
    if(!rst_i) begin
        bus_state <= 0;
        proc_bus_owner <= 0;
    end
    else begin
        bus_state <= nxt_bus_state;
        proc_bus_owner <= nxt_proc_bus_owner;
    end
end

cache #(
    .NUM_LINES(2)
) c0 (
    .clk_i (clk_i),
    .rst_i (rst_i),
    .bus_msg_o (pr_bus_msg_i[0]),
    .bus_msg_i (pr_bus_msg_o),
    .flush_o (flush_i[0]),
    .pr_bus_req_o(pr_bus_req_i[0]),
    .pr_bus_req_i(pr_bus_req_o[0]),
    .addr_o (pr_addr_req_i[0]),
    .addr_i (pr_addr_req_o),
    .test_rd_i (do_rd_i[0]),
    .test_wr_i (do_wr_i[0]),
    .test_addr_i (test_addr0_i)
);
cache #(
    .NUM_LINES(2)
) c1 (
    .clk_i (clk_i),
    .rst_i (rst_i),
    .bus_msg_o (pr_bus_msg_i[1]),
    .bus_msg_i (pr_bus_msg_o),
    .flush_o (flush_i[1]),
    .pr_bus_req_o(pr_bus_req_i[1]),
    .pr_bus_req_i(pr_bus_req_o[1]),
    .addr_o (pr_addr_req_i[1]),
    .addr_i (pr_addr_req_o),
    .test_rd_i (do_rd_i[1]),
    .test_wr_i (do_wr_i[1]),
    .test_addr_i (test_addr1_i)
);
cache #(
    .NUM_LINES(2)
) c2 (
    .clk_i (clk_i),
    .rst_i (rst_i),
    .bus_msg_o (pr_bus_msg_i[2]),
    .bus_msg_i (pr_bus_msg_o),
    .pr_bus_req_o(pr_bus_req_i[2]),
    .pr_bus_req_i(pr_bus_req_o[2]),
    .addr_o (pr_addr_req_i[2]),
    .addr_i (pr_addr_req_o),
    .test_rd_i (do_rd_i[2]),
    .test_wr_i (do_wr_i[2]),
    .test_addr_i (test_addr2_i)
);
cache #(
    .NUM_LINES(2)
) c3 (
    .clk_i (clk_i),
    .rst_i (rst_i),
    .bus_msg_o (pr_bus_msg_i[3]),
    .bus_msg_i (pr_bus_msg_o),
    .pr_bus_req_o(pr_bus_req_i[3]),
    .pr_bus_req_i(pr_bus_req_o[3]),
    .addr_o (pr_addr_req_i[3]),
    .addr_i (pr_addr_req_o),
    .test_rd_i (do_rd_i[3]),
    .test_wr_i (do_wr_i[3]),
    .test_addr_i (test_addr3_i)
);

endmodule
