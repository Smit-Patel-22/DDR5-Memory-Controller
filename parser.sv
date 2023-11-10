module parser #(
    parameter MEM_ADDR_WIDTH  = 64,
    parameter CPU_CLK_WIDTH   = 8,
    parameter CPU_CORE_WIDTH  = 4,
    parameter MEM_OPN_WIDTH   = 3
);

    int fd;
    logic [CPU_CORE_WIDTH-1:0] cpu_core;
    logic [MEM_OPN_WIDTH-1:0] mem_opn;
    logic [CPU_CLK_WIDTH-1:0] cpu_clk;
    logic [MEM_ADDR_WIDTH-1:0] mem_addr; // Assuming 4 elements in the unpacked array
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

        fd = $fopen(in_fname, "r");   //file in the same directory as the code folder.

        if (fd) begin
            $display("File opened.");
        end
        else begin
            $display("File not opened.");
             if (mode == "DEBUG")
                $display("%s ,%d", in_fname, fd);
        end

        while ($fscanf(fd, "%d %d %d %h", cpu_clk, cpu_core, mem_opn, mem_addr) == 4) begin
         if (mode == "DEBUG") begin
            $display("DEBUG mode: Displaying parsed entries:");
            $display("Clock: %d Core: %d Operation: %d Address: %h", cpu_clk, cpu_core, mem_opn, mem_addr);
         end

        $display("Parsing complete.");
    end
end

endmodule : parser
