//code for read pointer module
`timescale 1ns / 1ps

module rd_ptr #(parameter SIZE = 4)(
    input  wire                  rd_clk, rst_n, read_en,     //all input signal
    output reg  [SIZE-1:0]       rd_ptr_bin    // Read pointer (binary)
);

    
    // Read Pointer Logic (Binary Only)
    
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr_bin <= 0;
        end else if (read_en) begin
            rd_ptr_bin <= rd_ptr_bin + 1; // Increment binary pointer
        end
    end

endmodule
