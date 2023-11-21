package structures;

	typedef struct packed {
		logic [63:0]	cpu_cyc;
		logic [3:0]		core;
		logic [1:0]		opn;
		logic [33:0]	addr;
	} dIn_t;
	
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

	typedef struct packed {
		dIn_t		dIN;
		addrMap_t	addrMap;
		// Assuming cmd_t is defined elsewhere in your code
		// cmd_t		cmd;
	} q_t;
	
	q_t q[15:0];
	
	int head = 0;
	int tail = -1;
	int members = 0;
	
	function automatic bit isFull();
		return (members == 16);
	endfunction
	
	function automatic bit isEmpty();
		return (members == 0);
	endfunction
	
	function automatic void enqueue (dIn_t dIn);
		if (!isFull()) begin
			tail = (tail + 1) % 16;
			
			// Assigning values to addrMap within the enqueue function
			q[tail].addrMap.row         = dIn.addr[33:16];
			q[tail].addrMap.low_column  = dIn.addr[5:2];
			q[tail].addrMap.high_column = dIn.addr[17:12];
			q[tail].addrMap.Bank        = dIn.addr[11:10];
			q[tail].addrMap.Bank_group  = dIn.addr[9:7];
			q[tail].addrMap.column      = {dIn.addr[17:12],dIn.addr[5:2]};
			
			q[tail].dIN = dIn; // Assign to the dIN field of the q structure
			members++;
		end
		else
			$display("Maximum number of requests met, cannot enqueue.");
	endfunction
	
	function automatic dIn_t dequeue();
		dIn_t temp;
		if (!isEmpty()) begin
			temp = q[head].dIN; // Access the dIN field of the q structure
			head = (head + 1) % 16;
			members--;
			return temp;
		end
		else begin
			$display("No other requests in the queue, cannot dequeue.");
			return temp;
		end
	endfunction
endpackage
