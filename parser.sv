////////////////////////////////////////////////////////////////////////////////////////////////
// 
// parser.sv 	- Parser module for trace file
// PSU ECE 585 	- Microprocessor System Design
// Fall 2023
//
// Contributors -  	Avadhoot Modak, Aaditya Shah, Smit Patel, Satyam Sharma
//
// 
//
// Date			- 	09-Nov-2023
//
// Description 	- 	Module to parse the input trace file containing CPU clock, requesting core,
//					operation and memory address. 
//
////////////////////////////////////////////////////////////////////////////////////////////////

module parser_top (
);

int fd;
int cpu_core;
int mem_opn;
int cpu_clk;
logic [35:0] mem_addr;
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

	while($fscanf(fd,"%d %d %d %h", cpu_clk, cpu_core, mem_opn, mem_addr) == 4) begin
		$display("Here lies input.");
		`ifdef DEBUG
		$display("Shows all parsed entries (soon).");
		`endif
	end