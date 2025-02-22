//Code for write pointer module

`timescale 1ns / 1ps

module wr_ptr #(parameter SIZE = 4)(
    input  wire                  wr_clk, rst_n, write_en,   //all input signal
    output reg  [SIZE-1:0]       wr_ptr_bin    // Write pointer (binary)
);

    
    // Write Pointer Logic (Binary Only)
   always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_bin <= 0;
        end else if (write_en) begin
            wr_ptr_bin <= wr_ptr_bin + 1; // Increment binary pointer
        end
    end

endmodule
