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
	longint unsigned	in_cpu_cyc;
	logic [2:0]			in_core;
	int					in_opn;
	logic [33:0]		in_addr;
	
	// Input data structure

	typedef struct packed {
		logic [CPU_CYC_WIDTH-1:0]	cpu_cyc;
		logic [CORE_WIDTH-1:0]		core;
		logic [OPN_WIDTH-1:0]		opn;
		logic [ADDR_WIDTH-1:0]		addr;
		logic [9:0]					column;  
	} dIn_t;
	
	dIn_t q_dIn [$:16];
	dIn_t temp_in;
	dIn_t temp;
	dIn_t tmp;
	
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
	
/* 	typedef struct packed {
			dIn_t		dIn;
			// addrMap_t	addrMap;
		} q_t;

		q_t  q[15:0]; */
		
	// function automatic  enqueue (dIn_t dIn);
	// 	tail = (tail + 1) % 16;
	// 	q[tail] = dIn;
	// 	members++;
	// 	
	// endfunction
	
	// function automatic  dequeue();
	// 	dIn_t temp = q[head];
	// 	head = (head + 1) % 16;
	// 	members--;
	// 	return temp;
	// endfunction
	
	// PRINT OUTPUT
	
	task printOutFile (input dIn_t temp);
		if(temp.opn == 0 || temp.opn == 2) begin
			$fwrite(fd_out, "At time %t ACT0 %d %d %h \n", $time, temp.addr[9:7], temp.addr[11:10], temp.addr[33:16]);			// CHECK IF $TIME IS COPY AND %H FOR HEX ROW/COLM IS CORRECT
			$fwrite(fd_out, "At time %t ACT1 %d %d %h \n", $time, temp.addr[9:7], temp.addr[11:10], temp.addr[33:16]);
			$fwrite(fd_out, "At time %t RD0 %d %d %h \n", $time, temp.addr[9:7], temp.addr[11:10], temp.addr[17:12]);
			$fwrite(fd_out, "At time %t RD1 %d %d %h \n", $time, temp.addr[9:7], temp.addr[11:10], temp.addr [17:12]);
			$fwrite(fd_out, "At time %t PRE %d %d \n", $time, temp.addr[9:7], temp.addr[11:10]);
		end
		else if(temp.opn == 1) begin
			$fwrite(fd_out, "At time %t ACT0 %d %d %h \n", $time, temp.addr[9:7], temp.addr[11:10], temp.addr[33:16]);			// CHECK IF $TIME IS COPY AND %H FOR HEX ROW/COLM IS CORRECT
			$fwrite(fd_out, "At time %t ACT1 %d %d %h \n", $time, temp.addr[9:7], temp.addr[11:10], temp.addr[33:16]);
			$fwrite(fd_out, "At time %t WR0 %d %d %h \n", $time, temp.addr[9:7], temp.addr[11:10], temp.addr[17:12]);
			$fwrite(fd_out, "At time %t WR1 %d %d %h \n", $time, temp.addr[9:7], temp.addr[11:10], temp.addr[17:12]);
			$fwrite(fd_out, "At time %t PRE %d %d \n", $time, temp.addr[9:7], temp.addr[11:10]);
		end
	endtask

	always #1 current_cyc <= current_cyc + 1;
	
	// STALLING REQUESTS TILL QUEUE HAS SPACE
	
	always@(current_cyc) begin
		if (q_dIn.size() != 0 && q_dIn.size() < 17) begin
			tmp = q_dIn.pop_front();
			wait_time = tmp.cpu_cyc;
			wait(wait_time <= current_cyc);
			// q_dIn.push_back();
			q_dIn.push_back(tmp);
		end
	end
	
	// PRINT OUTPUT EVERY 2 CLOCK CYCLES
	
	always@(current_cyc) begin
		if(q_dIn.size() != 0 || q_dIn.size() < 17) begin
			if (current_cyc % 2 == 0) begin
				temp = q_dIn.pop_front();
				printOutFile(temp);
			end
		end
	end
		

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
            fd_in = $fopen(in_fname, "r");   	
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

// ADDING ELEMENT TO THE QUEUE

		while(!$feof(fd_in))begin
			while ($fscanf(fd_in, "%d %d %d %h", in_cpu_cyc, in_core, in_opn, in_addr) == 4) begin
			members = q_dIn.size();
				if (members < 16) begin
					temp_in.cpu_cyc = in_cpu_cyc;
					temp_in.core = in_core;
					temp_in.opn = in_opn;
					temp_in.addr = in_addr;
					q_dIn.push_back(temp_in);
					// $display("%p",q[0].dIn);

// REMOVING ELEMENT FROM THE QUEUE

				// if (members > 0) begin
    			// temp = q_dIn.pop_front();
    			// printOutFile(temp);
				// end


				if (mode == "DEBUG") begin
					$display("DEBUG mode: Displaying parsed entries:");
					//$display("Clock: %d Core: %d Operation: %d Data_In Address: %h Bank Group : %h Bank No :  %h Column : %h Row : %h", dIn.cpu_cyc, dIn.core, dIn.opn, dIn.addr, dIn.addr[11:10], dIn.addr[9:7],dIn.addr[17:12], dIn.addr[33:16]);
				
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

//initiate clock =0 , queue not full except all request popout not initiated satisfactorily , column bits address wrong 2nd //