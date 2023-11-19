module parser #(
    parameter MEM_ADDR_WIDTH  = 34,
    parameter CPU_CLK_WIDTH   = 8,
    parameter CPU_CORE_WIDTH  = 4,
    parameter MEM_OPN_WIDTH   = 3
)(
    output logic [CPU_CORE_WIDTH-1:0] cpu_core,
    output logic [MEM_OPN_WIDTH-1:0] mem_opn,
    output logic [CPU_CLK_WIDTH-1:0] cpu_clk,
    output logic [MEM_ADDR_WIDTH-1:0] mem_addr,
    output logic [1:0] instruction
);

    int fd;
    string in_fname;
    string mode;

    initial begin
        if ($value$plusargs("mode=%s", mode)) begin
            if (mode == "DEBUG")
                $display("DEBUG mode selected.");
            else
                $display("DEBUG mode not selected.");
        end

        $value$plusargs("ifname=%s", in_fname);

        if(in_fname) begin
            fd = $fopen(in_fname, "r");   //file in the same directory as the code folder.
        end
        else begin
            in_fname = "trace.txt";
            $display("No input file name specified, selecting file %s.", in_fname);
            fd = $fopen(in_fname, "r");   //file in the same directory as the code folder.
        end

        if (fd) begin
            $display("File opened.");
        end
        else begin
            $display("File not opened.");
            if (mode == "DEBUG")
                $display("%s ,%d", in_fname, fd);
        end

        while ($fscanf(fd, "%d %d %d %h", cpu_clk, cpu_core, mem_opn, mem_addr) == 4) begin
            if (mem_opn == 2'b00) begin
                instruction = 2'b00; // Read instruction has priority
            end
            else if (mem_opn == 2'b01) begin
                instruction = 2'b01;
            end
            else if (mem_opn == 2'b10) begin
                instruction = 2'b10;
            end

            if (mode == "DEBUG") begin
                $display("DEBUG mode: Displaying parsed entries:");
                $display("Clock: %d Core: %d Operation: %d mem_addr: %h", cpu_clk, cpu_core, mem_opn, mem_addr);
                $display("Instruction: %b", instruction);
            end
        end
        $display("All lines have been parsed.");
    end
endmodule : parser

module mem_addrDecoder (
    input logic [37:0] mem_addr,
    input logic [3:0] cpu_core,
    input logic [1:0] instruction,
    output logic [5:0] read_queue_addr,
    output logic [4:0] write_queue_addr,
    output logic [4:0] fetch_queue_addr
);
    assign read_queue_addr = (instruction == 2'b00) ? mem_addr[5:0] : 6'hx;
    assign write_queue_addr = (instruction == 2'b01) ? mem_addr[5:0] : 5'hx;
    assign fetch_queue_addr = (instruction == 2'b10) ? mem_addr[5:0] : 5'hx;
endmodule

module Queue #(int DEPTH) (
    input logic clk,
    input logic rst,
    input logic enq,
    input logic deq,
    input logic [37:0] data_in,
    output logic [37:0] data_out,
    output logic empty,
    output logic full
);
    logic [37:0] memory [0:DEPTH-1];
    logic [4:0] head;
    logic [4:0] tail;

    assign empty = (head == tail);
    assign full = ((head + 1) % DEPTH == tail);

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            head <= 5'b0;
        else if (enq && !full) begin
            head <= (head + 1) % DEPTH;
            $display("Address %h added to the queue at head %0d", data_in, head);
        end
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            tail <= 5'b0;
        else if (deq && !empty)
            tail <= (tail + 1) % DEPTH;
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            data_out <= 38'h0;
        else if (deq && !empty) begin
            data_out <= memory[tail];
            $display("Address %h retrieved from the queue at tail %0d", data_out, tail);
        end
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst || enq && !full)
            memory[head] <= data_in;
    end
endmodule

module TopModule #(
    parameter MEM_ADDR_WIDTH  = 34,
    parameter CPU_CLK_WIDTH   = 8,
    parameter CPU_CORE_WIDTH  = 4,
    parameter MEM_OPN_WIDTH   = 3
);
    localparam CLK_PERIOD = 10; // ns
    logic clk, rst;
    logic [2:0] instruction;
    logic [5:0] read_queue_addr;
    logic [4:0] write_queue_addr;
    logic [4:0] fetch_queue_addr;
    int fd;
    logic [CPU_CORE_WIDTH-1:0] cpu_core;
    logic [MEM_OPN_WIDTH-1:0] mem_opn;
    logic [CPU_CLK_WIDTH-1:0] cpu_clk;
    logic [MEM_ADDR_WIDTH-1:0] mem_addr; 

    mem_addrDecoder decoder (
        .mem_addr(mem_addr),
        .cpu_core(cpu_core),
        .instruction(instruction),
        .read_queue_addr(read_queue_addr),
        .write_queue_addr(write_queue_addr),
        .fetch_queue_addr(fetch_queue_addr)
    );

    parser parser (
        .cpu_core(cpu_core),
        .mem_opn(mem_opn),
        .cpu_clk(cpu_clk),
        .mem_addr(mem_addr),
        .instruction(instruction)
    );

    Queue #(6) read_queue (
        .clk(clk),
        .rst(rst),
        .enq(instruction == 2'b00),
        .deq(1'b0),
        .data_in(mem_addr[37:0]),
        .data_out(),
        .empty(),
        .full()
    );

    Queue #(5) write_queue (
        .clk(clk),
        .rst(rst),
        .enq(instruction == 2'b01),
        .deq(1'b0),
        .data_in(mem_addr[37:0]),
        .data_out(),
        .empty(),
        .full()
    );

    Queue #(5) fetch_queue (
        .clk(clk),
        .rst(rst),
        .enq(instruction == 2'b10),
        .deq(1'b0),
        .data_in(mem_addr[37:0]),
        .data_out(),
        .empty(),
        .full()
    );

    always_ff @(posedge clk) begin
        if (clk) begin
            rst <= 1'b1;
        end
        else begin
            rst <= 1'b0;
        end
    end

    always #((CLK_PERIOD)/2) clk <= ~clk;
endmodule
