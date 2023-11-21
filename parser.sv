module parser #(
    parameter MEM_ADDR_WIDTH  = 34,
    parameter CPU_CLK_WIDTH   = 8,
    parameter CPU_CORE_WIDTH  = 4,
    parameter MEM_OPN_WIDTH   = 3
);

    int fd;
    logic [CPU_CORE_WIDTH-1:0] cpu_core;
    logic [MEM_OPN_WIDTH-1:0] mem_opn;
    logic [CPU_CLK_WIDTH-1:0] cpu_clk;
    logic [MEM_ADDR_WIDTH-1:0] mem_addr;
    logic [9:0]column_addr;
    
    //assign Bank_Group = mem_addr[9:7] ;
    //assign Bank_Number = mem_addr[11:10]; 
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
typedef struct packed {
	logic [15:0]		row;
	logic [5:0]		high_column;
	logic [1:0]		Bank;
	logic [2:0]		Bank_group;
	logic			channel;
	logic [3:0]		low_column;
	logic [1:0]		byte_select;
	logic [9:0]		column;
} addrMap_t;


addrMap_t addrMap;
addrMap.row = mem_addr[33:16];
addrMap.low_column = mem_addr[5:2];
addrMap.high_column = mem_addr[17:12];
addrMap.Bank = mem_addr[11:10];
addrMap.Bank_group = mem_addr[9:7];
addrMap.column = {mem_addr[17:12],mem_addr[5:2]};
         if (mode == "DEBUG") begin
            $display("DEBUG mode: Displaying parsed entries:");
            $display("Clock: %d Core: %d Operation: %d mem_addr: %h Bank Group : %h Bank No :  %h Column : %h Row : %h", cpu_clk, cpu_core, mem_opn, mem_addr,addrMap.Bank_group,addrMap.Bank,addrMap.column,addrMap.row);
         end
    end
    $display("All lines have been parsed.");
end
endmodule : parser