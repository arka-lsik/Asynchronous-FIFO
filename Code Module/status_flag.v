//module code for all the status flags and control signal tocheck full and complete condition
`timescale 1ns / 1ps

module status_flags #(parameter SIZE = 4, parameter DEPTH = 16)(
    input  wire [SIZE-1:0] wr_ptr_bin,    // Write pointer
    input  wire [SIZE-1:0] rd_ptr_bin,    // Read pointer
    output wire            fifo_full,     // FIFO full flag
    output wire            fifo_empty     // FIFO empty flag
);

    // Empty Condition
    // FIFO is empty when write and read pointers are equal.
    assign fifo_empty = (wr_ptr_bin == rd_ptr_bin);

    
    // Full Condition
    // FIFO is full when the difference between write and read pointers
    // equals the FIFO depth.
    assign fifo_full = ((wr_ptr_bin - rd_ptr_bin) == DEPTH);

endmodule

