//Code for the FIFO memory module
`timescale 1ns / 1ps

module fifo_mem #(parameter SIZE = 4, parameter WIDTH = 8, parameter DEPTH = 16)(
    input  wire                  wr_clk,       // Write clock
    input  wire                  rd_clk,       // Read clock
    input  wire                  rst_n,        // Active-low reset
    input  wire                  write_en,     // Write enable
    input  wire                  read_en,      // Read enable
    input  wire [WIDTH-1:0]      data_in,       // Data input
    input  wire [SIZE-1:0]       wr_addr,       // Write address (from write pointer)
    input  wire [SIZE-1:0]       rd_addr,       // Read address (from read pointer)
    output reg  [WIDTH-1:0]      data_out       // Data output
);

    
    // FIFO Memory Declaration
   reg [WIDTH-1:0] mem [0:DEPTH-1];

     // Write Operation
    always @(posedge wr_clk) begin
        if (write_en) begin
            mem[wr_addr] <= data_in;
        end
    end

    
    // Read Operation
     always @(posedge rd_clk) begin
        if (read_en) begin
            data_out <= mem[rd_addr];
        end
    end

endmodule
