////////////////////////////////////////////////////////////////////////////////////////////////
// 
// parser.sv 		- 	Parser module for trace file
// PSU ECE 585 		- 	Microprocessor System Design
// 						Fall 2023
//
// Contributors 	-  	Avadhoot Modak, Aaditya Shah, Smit Patel, Satyam Sharma
//
// Date				- 	09-Nov-2023
//
// Description 		- 	Module to parse the input trace file containing CPU clock, requesting core,
//						operation and memory address. Declare all parameters and width.
//
// Future changes	-	DEBUG mode - prints all parsed entries
//
////////////////////////////////////////////////////////////////////////////////////////////////

module parser
(
	parameter MEM_ADDR_WIDTH	=	64,
	parameter CPU_CLK_WIDTH		=	8,
	parameter CPU_CORE_WIDTH	=	4,
	parameter MEM_OPN_WIDTH		=	3
);

int fd;
int [CPU_CORE_WIDTH-1:0]	cpu_core;
int [MEM_OPN_WIDTH-1:0]		mem_opn;
int [CPU_CLK_WIDTH-1:0]		cpu_clk;
logic [MEM_ADDR_WIDTH-1:0]	mem_addr;
string in_fname;
string mode;

initial begin

	if ($value$plusargs("mode=%s", mode)) begin
		if(mode == "DEBUG")
			$display("DEBUG mode selected.");
		else
        	$display("DEBUG mode not selected.");
	end

	$value$plusargs("ifname=%s", in_fname);

	fd = $fopen(in_fname,"r");   //file in same directory of the code folder.
    
    if (fd) begin
    	$display("File opened.");
    end
    
    else begin
    	$display("File not opened.");
    	`ifdef DEBUG
		$display("%s ,%d", in_fname, fd);
		`endif
	end

	while($fscanf(fd,"%d %d %d %h", cpu_clk, cpu_core, mem_opn, mem_addr) != 4) begin
		$fatal("Error reading trace file. Exiting...");
	end

	else begin
		`ifdef DEBUG
		$display("DEBUG mode: Displaying parsed entries:");
		$display("Clock: %d Core: %d Operation: %d Address: %h", cpu_clk, cpu_core, mem_opn, mem_addr);
		`endif
	end

	$display("Parsing complete.");

end
endmodule:parser