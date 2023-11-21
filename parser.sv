module parser #(
    parameter ADDR_WIDTH  = 34,
    parameter CPU_CYC_WIDTH   = 64,
    parameter CORE_WIDTH  = 4,
    parameter OPN_WIDTH   = 3
);

    int fd;
	
	typedef struct packed {
		logic [CPU_CYC_WIDTH-1:0]	cpu_cyc;
		logic [CORE_WIDTH-1:0]		core;
		logic [OPN_WIDTH-1:0]		opn;
		logic [ADDR_WIDTH-1:0]		addr;
	} dIn_t;
	
	dIn_t dIn;

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
            fd = $fopen(in_fname, "r");   													//file in the same directory as the code folder.
        end
        else begin
            in_fname = "trace.txt";
            $display("No input file name specified, selecting file %s.", in_fname);
            fd = $fopen(in_fname, "r");   													//file in the same directory as the code folder.
        end

        if (fd) begin
            $display("File opened.");
        end
        else begin
            $display("File not opened.");
             if (mode == "DEBUG")
                $display("%s ,%d", in_fname, fd);
        end

        while ($fscanf(fd, "%d %d %d %h", dIn.cpu_cyc, dIn.core, dIn.opn, dIn.addr) == 4) begin
            typedef struct packed {
            	logic [15:0]	row;
            	logic [5:0]		high_column;
            	logic [1:0]		Bank;
            	logic [2:0]		Bank_group;
            	logic			channel;
            	logic [3:0]		low_column;
            	logic [1:0]		byte_select;
            	logic [9:0]		column;
            } addrMap_t;
            
            addrMap_t addrMap;
            
            addrMap.row         = dIn.addr[33:16];
            addrMap.low_column  = dIn.addr[5:2];
            addrMap.high_column = dIn.addr[17:12];
            addrMap.Bank        = dIn.addr[11:10];
            addrMap.Bank_group  = dIn.addr[9:7];
            addrMap.column      = {dIn.addr[17:12],dIn.addr[5:2]};
			
			// Input data structure
			
            if (mode == "DEBUG") begin
                $display("DEBUG mode: Displaying parsed entries:");
                $display("Clock: %d Core: %d Operation: %d dIn.addr: %h Bank Group : %h Bank No :  %h Column : %h Row : %h", dIn.cpu_cyc, dIn.core, dIn.opn, dIn.addr, addrMap.Bank_group,addrMap.Bank,addrMap.column,addrMap.row);
            end
        end
        $display("All lines have been parsed.");
    end
endmodule : parser

