module dimm;

	// DECLARATIONS

	int					fd_in;
	int					fd_out;
	string				in_fname;
	string				out_fname;
	string				mode;
	longint unsigned	current_cyc = 0;
	longint unsigned	wait_time;
	int					tail 		= -1;
	int					head		= 0;
	int					members		= 0;
	longint unsigned	in_cpu_cyc;
	logic [2:0]			in_core;
	int					in_opn;
	logic [33:0]		in_addr;
	int					isFull, isEmpty;
	
	// INPUT DATA STRUCTURE

	typedef struct packed {
		longint unsigned cpu_cyc;
		logic [2:0]		core;
		logic [1:0]		byte_select;
		logic [1:0]		opn;
		logic			channel;
		logic [2:0]		bank_group;
		logic [1:0]		bank;
		logic [15:0]	row;
		logic [5:0]		high_column;
		logic [4:0]		low_column;
		logic [9:0]		column;
		logic [33:0]	addr;
    } dIn_t;
	
	dIn_t q_in[$];					// INPUT QUEUE TO STORE PARSED ENTRIES
	dIn_t scheduler[$:16];			// SCHEDULER QUEUE OF SIZE 16
	dIn_t temp_in;					// VARIABLE TO INSERT ELEMENT IN INPUT QUEUE
	dIn_t temp_wait;				// VARIABLE TO INSERT ELEMENT IN SCHEDULER QUEUE
	dIn_t temp_out;					// VARIABLE TO EXTRACT ELEMENT FROM SCHEDULER QUEUE
	
	// COMMANDS TO BE ISSUED BY DIMM
	
	typedef enum {
		ACT0	= 4'b0000,
		ACT1	= 4'b0001,
		RD0		= 4'b0010,
		RD1		= 4'b0011,
		WR0		= 4'b0100,
		WR1		= 4'b0101,
		PRE		= 4'b0110,
		STALL	= 4'b0111
	} cmd_t;
	
	cmd_t current_cmd;				// CURRENTLY ISSUED COMMAND
	cmd_t next_cmd;					// COMMAND TO BE ISSUED NEXT
	
	// READ AND PARSE TRACE FILE

    initial begin
	current_cyc = 0;
        if ($value$plusargs("mode=%s", mode)) begin
            if (mode == "DEBUG")
                $display("DEBUG mode selected.");
            else
                $display("DEBUG mode not selected.");
        end

        $value$plusargs("ifname=%s", in_fname);
		$value$plusargs("ofname=%s", out_fname);

        if(in_fname) begin
            fd_in = $fopen(in_fname, "r");
        end
        else begin
            in_fname = "trace.txt";
            $display("No input file name specified, selecting file %s.", $sformatf("%s", in_fname));
			$fwrite	(fd_out,"No input file name specified, selecting file %s.\n", $sformatf("%s", in_fname));
            fd_in = $fopen(in_fname, "r");   	
        end
		
		if (out_fname) begin
			fd_out = $fopen(out_fname, "w");
		end
		else begin
			out_fname = "dram.txt";
			$display("No output file name specified, selecting file %s.", out_fname);
			$fwrite	(fd_out,"No output file name specified, selecting file %s.\n", out_fname);
			fd_out = $fopen(out_fname, "w");
		end


        if (fd_in) begin
            $display("File opened.");
        end
        else begin
            $display("File not opened.");
             if (mode == "DEBUG") begin
                $display("%s ,%d", in_fname, fd_in);
				$fwrite	(fd_out,"%s ,%d\n", in_fname, fd_in);
			end
		end

	// ADDING ELEMENT TO QUEUE

		while(!$feof(fd_in))begin
			while ($fscanf(fd_in, "%0d %d %d %h", in_cpu_cyc, in_core, in_opn, in_addr) == 4) begin
				temp_in.cpu_cyc		=	in_cpu_cyc;
				temp_in.core		=	in_core;
				temp_in.byte_select	=	in_addr[1:0];
				temp_in.opn			=	in_opn;
				temp_in.channel		=	in_addr[6];
				temp_in.bank_group	=	in_addr[9:7];
				temp_in.bank		=	in_addr[11:10];
				temp_in.row			=	in_addr[33:18];
				temp_in.high_column	=	in_addr[17:12];
				temp_in.low_column	=	in_addr[5:2];
				temp_in.column		=	{in_addr[17:12],in_addr[5:2]};
				temp_in.addr		=	in_addr;
					
				if (mode == "DEBUG") begin
					$display("At time %0d temp_in has been assigned input values. temp_in = %p", current_cyc, temp_in);
					$fwrite	(fd_out,"At time %0d temp_in has been assigned input values. temp_in = %p\m", current_cyc, temp_in);
				end
				q_in.push_back(temp_in);

				if (mode == "DEBUG") begin
					$display("DEBUG mode: Displaying parsed entries:");
					$fwrite	(fd_out,"DEBUG mode: Displaying parsed entries:\n");
					$display("Clock: %0d Core: %d Operation: %d Bank Group : %h Bank: %h Row : %h Column: %h", temp_in.cpu_cyc, temp_in.core, temp_in.opn, temp_in.bank_group, temp_in.bank, temp_in.row, temp_in.column);
					$fwrite	(fd_out,"Clock: %0d Core: %d Operation: %d Bank Group : %h Bank: %h Row : %h Column: %h\n", temp_in.cpu_cyc, temp_in.core, temp_in.opn, temp_in.bank_group, temp_in.bank, temp_in.row, temp_in.column);
				end
			end
       	end
		$display("All lines have been parsed.");
		$fwrite(fd_out,"All lines have been parsed.\n");
		$fclose(fd_in);
    end
	
	// TASK TO PRINT OUTPUT
	
	task printOutFile (input dIn_t temp_out);
		if(temp_out.opn == 0 || temp_out.opn == 2) begin
			$fwrite	(fd_out, "At time %0d ACT0 %d %d %h Addr: %h\n", current_cyc, temp_out.bank_group, temp_out.bank, temp_out.row,	temp_out.addr	);
			$fwrite	(fd_out, "At time %0d ACT1 %d %d %h Addr: %h\n", current_cyc, temp_out.bank_group, temp_out.bank, temp_out.row,	temp_out.addr	);
			$fwrite	(fd_out, "At time %0d RD0  %d %d %h Addr: %h\n", current_cyc, temp_out.bank_group, temp_out.bank, temp_out.column,	temp_out.addr	);
			$fwrite	(fd_out, "At time %0d RD1  %d %d %h Addr: %h\n", current_cyc, temp_out.bank_group, temp_out.bank, temp_out.column,	temp_out.addr	);
			$fwrite	(fd_out, "At time %0d PRE  %d %d 	Addr: %h\n", current_cyc, temp_out.bank_group, temp_out.bank, temp_out.addr					);
		end
		else if(temp_out.opn == 1) begin
			$fwrite	(fd_out, "At time %0d ACT0 %d %d %h Addr: %h\n", current_cyc, temp_out.bank_group, temp_out.bank, temp_out.row,	temp_out.addr	);
			$fwrite	(fd_out, "At time %0d ACT1 %d %d %h Addr: %h\n", current_cyc, temp_out.bank_group, temp_out.bank, temp_out.row,	temp_out.addr	);
			$fwrite	(fd_out, "At time %0d WR0  %d %d %h Addr: %h\n", current_cyc, temp_out.bank_group, temp_out.bank, temp_out.column,	temp_out.addr	);
			$fwrite	(fd_out, "At time %0d WR1  %d %d %h Addr: %h\n", current_cyc, temp_out.bank_group, temp_out.bank, temp_out.column,	temp_out.addr	);
			$fwrite	(fd_out, "At time %0d PRE  %d %d    Addr: %h\n", current_cyc, temp_out.bank_group, temp_out.bank, temp_out.addr					);
		end
	endtask
	
	// TASK TO INSERT ELEMENT IN QUEUE
	
	task inScheduler;
		temp_wait = q_in.pop_front();
		wait_time = temp_wait.cpu_cyc;
		wait(wait_time <= current_cyc);
		// #wait_time;
		scheduler.push_back(temp_wait);
		if (mode == "DEBUG") begin
			$display("At time %0d element entered into scheduler queue. Element temp_wait = %p", current_cyc, temp_wait, current_cyc);
			$fwrite	(fd_out,"At time %0d element entered into scheduler queue. Element temp_wait = %p\n", current_cyc, temp_wait, current_cyc);
		end
	endtask
	
	// TASK TO REMOVE ELEMENT FROM SCHEDULER QUEUE AND CALL PRINT OUTPUT TASK
	
	task outScheduler;
			// temp_out = scheduler.pop_front();
			if (mode == "DEBUG") begin
	 			$display("At time %0d temp_out = %p", current_cyc, temp_out);
	 			$fwrite	(fd_out,"At time %0d temp_out = %p\n", current_cyc, temp_out);
	 		end
			printOutFile(temp_out);
			if (mode == "DEBUG") begin
				$display("At time %0d element removed from scheduler queue.", current_cyc);
				$fwrite	(fd_out,"At time %0d element removed from scheduler queue.\n", current_cyc);
			end
	endtask
	
	always #1 current_cyc = current_cyc + 1;
	
	// INSERT REQUEST IN SCHEDULER QUEUE WHILE STALLING REQUESTS TILL QUEUE HAS SPACE
		
	always@(current_cyc) begin
		if (scheduler.size() < 16)
			inScheduler;
	end
	
	// EXTACT REQUEST FROM SCHEDULER QUEUE AND PRINT OUTPUT AFTER EVERY 2 CLOCK CYCLES
	
	always@(current_cyc) begin
		temp_out = scheduler.pop_front();
		if(current_cyc % 2 == 0)
			outScheduler;
			
			case(current_cmd):
				ACT0: begin
					// <INSERT LOGIC HERE>
					// PRINT AT CURRENT_CYC
					// CURRENT STATE = ACT0
					// ACT0 <FORMAT>
					// NEXT STATE = WHATEVER
					current_cmd = ACT1;
				end
				ACT1: begin
					// <INSERT LOGIC HERE>
					current_cmd = (temp_out.opn ? WR0 : WR1);
				end
				RD0: begin
					// <INSERT LOGIC HERE>
					current_cmd = RD1;
				end
				RD1: begin
					// <INSERT LOGIC HERE>
					current_cmd = PRE;
				end
				WR0: begin
					// <INSERT LOGIC HERE>
					current_cmd = WR1;
				end
				WR1: begin
					// <INSERT LOGIC HERE>
					current_cmd = PRE;
				end
				PRE: begin
					// <INSERT LOGIC HERE>
					current_cmd = IDLE;
				end
				IDLE: begin
					// <INSERT LOGIC HERE>
					// WAIT TILL NEXT COMMAND, AFTER IT ARRIVES ->
					current_cmd = ACT0;
				end
			
	end
	
	// PRINT OUT SCHEDULER QUEUE IS FULL
	
	always@(current_cyc) begin
		if(scheduler.size() == 16)
			$fwrite(fd_out,"Scheduler full at time %0d.\n", current_cyc);
	end

endmodule : dimm