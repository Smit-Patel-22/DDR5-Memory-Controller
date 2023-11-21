`include "structures.sv";


module parser #(
    parameter ADDR_WIDTH  	= 34,
    parameter CPU_CYC_WIDTH	= 64,
    parameter CORE_WIDTH  	= 4,
    parameter OPN_WIDTH   	= 3
);

	import structures::*;
	
	// DECLARATIONS FOR READING FROM INPUT FILE

    int fd_in;
	int fd_out;
    string in_fname;
	string out_fname;
    string mode;
	longint unsigned	current_cyc = 1;
	int					wait_time;
	int					tail = -1;
	int					head = 0;
	int					members = 0;
	
	// Input data structure

	typedef struct packed {
		logic [CPU_CYC_WIDTH-1:0]	cpu_cyc;
		logic [CORE_WIDTH-1:0]		core;
		logic [OPN_WIDTH-1:0]		opn;
		logic [ADDR_WIDTH-1:0]		addr;
		logic [9:0]			column;  
	} dIn_t;
	
	dIn_t dIn;
	//dIn.column = dIn.addr {dIn.addr[17:12],dIn.addr[5:2]} ;
	// typedef struct packed {
	// 	logic [15:0]	row;
	// 	logic [5:0]		high_column;
	// 	logic [1:0]		Bank;
	// 	logic [2:0]		Bank_group;
	// 	logic			channel;
	// 	logic [3:0]		low_column;
	// 	logic [1:0]		byte_select;
	// 	logic [9:0]		column;
	// } addrMap_t;
	// 			
	// addrMap_t addrMap;
	
	//queue structure
	
	typedef struct packed {
			dIn_t		dIn;
			// addrMap_t	addrMap;
		} q_t;

		q_t  q[15:0];
		
	function automatic  enqueue (dIn_t dIn);
		tail = (tail + 1) % 16;
		q[tail] = dIn;
		members++;
		
	endfunction
	
	function automatic  dequeue();
		dIn_t temp = q[head];
		head = (head + 1) % 16;
		members--;
		return temp;
	endfunction
	
	task printOutFile (input dIn_t temp);
		if(temp.opn == 0 || temp.opn == 2) begin
			$display("%t ACT0 %d %d %h", $time, temp.addr[9:7], temp.addr[11:10], temp.addr[33:16]);			// CHECK IF $TIME IS COPY AND %H FOR HEX ROW/COLM IS CORRECT
			$display("%t ACT1 %d %d %h", $time, temp.addr[9:7], temp.addr[11:10], temp.addr[33:16]);
			$display("%t RD0 %d %d %h", $time, temp.addr[9:7], temp.addr[11:10], temp.addr[17:12]);
			$display("%t RD1 %d %d %h", $time, temp.addr[9:7], temp.addr[11:10], temp.addr [17:12]);
			$display("%t PRE %d %d", $time, temp.addr[9:7], temp.addr[11:10]);
			$display("READ DATA");
		end
		else if(temp.opn == 1) begin
			$display("%t ACT0 %d %d %h", $time, temp.addr[9:7], temp.addr[11:10], temp.addr[33:16]);			// CHECK IF $TIME IS COPY AND %H FOR HEX ROW/COLM IS CORRECT
			$display("%t ACT1 %d %d %h", $time, temp.addr[9:7], temp.addr[11:10], temp.addr[33:16]);
			$display("%t WR0 %d %d %h", $time, temp.addr[9:7], temp.addr[11:10], temp.addr[17:12]);
			$display("%t WR1 %d %d %h", $time, temp.addr[9:7], temp.addr[11:10], temp.addr[17:12]);
			$display("%t PRE %d %d", $time, temp.addr[9:7], temp.addr[11:10]);
		end
	endtask

	always #1 current_cyc += 1;
		

    initial begin
        if ($value$plusargs("mode=%s", mode)) begin
            if (mode == "DEBUG")
                $display("DEBUG mode selected.");
            else
                $display("DEBUG mode not selected.");
        end

        $value$plusargs("ifname=%s", in_fname);
		$value$plusargs("ofname=%s", out_fname);

        if(in_fname) begin
            fd_in = $fopen(in_fname, "r");   													//file in the same directory as the code folder.
        end
        else begin
            in_fname = "trace.txt";
            $display("No input file name specified, selecting file %s.", $sformatf("%s", in_fname));
            fd_in = $fopen(in_fname, "r");   													//file in the same directory as the code folder.
        end
		
		if (out_fname) begin
   		 fd_out = $fopen(out_fname, "w");
		end
		else begin
    	out_fname = "dram.txt";
    	$display("No output file name specified, selecting file %s.", out_fname);
    	fd_out = $fopen(out_fname, "w");
		end


        if (fd_in) begin
            $display("File opened.");
        end
        else begin
            $display("File not opened.");
             if (mode == "DEBUG")
                $display("%s ,%d", in_fname, fd_in);
        end

		while(!$feof(fd_in))begin
			while ($fscanf(fd_in, "%d %d %d %h", dIn.cpu_cyc, dIn.core, dIn.opn, dIn.addr) == 4) begin
				if (members <16) begin
					enqueue(dIn);
					$display("%p",q[0].dIn);

				if (members > 0) begin
    			automatic dIn_t dequeuedItem = dequeue();
    			printOutFile(dequeuedItem);
				end


				if (mode == "DEBUG") begin
					$display("DEBUG mode: Displaying parsed entries:");
					$display("Clock: %d Core: %d Operation: %d Data_In Address: %h Bank Group : %h Bank No :  %h Column : %h Row : %h", dIn.cpu_cyc, dIn.core, dIn.opn, dIn.addr, dIn.addr[11:10], dIn.addr[9:7],dIn.addr[17:12], dIn.addr[33:16]);
				
				end
			end
			else begin
				$display("Queue is full.");
			end
end
       		 end
		$display("All lines have been parsed.");
		
		
		
    end

endmodule : parser

