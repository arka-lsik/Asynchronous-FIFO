//The integration of all the Asynchronus module I written
//So this is the top module for to implement the overall Asynchronus FIFO
timescale 1ns / 1ps

module async_fifo #(parameter SIZE = 4, parameter WIDTH = 8, parameter DEPTH = 10)(
    input  wire                  wr_clk,
    input  wire                  rd_clk,
    input  wire                  rst_n,
    input  wire                  write_en,
    input  wire                  read_en,
    input  wire [WIDTH-1:0]      data_in,
    output wire [WIDTH-1:0]      data_out,
    output wire                  fifo_full,
    output wire                  fifo_empty
);

    wire [SIZE-1:0] wr_ptr_bin, rd_ptr_bin;
    wire [SIZE-1:0] wr_ptr_sync, rd_ptr_sync;

    // Write Pointer
    wr_ptr #(SIZE) wp_inst(
        .wr_clk(wr_clk),
        .rst_n(rst_n),
        .write_en(write_en),
        .wr_ptr_bin(wr_ptr_bin)
    );

    // Read Pointer
    rd_ptr #(SIZE) rp_inst(
        .rd_clk(rd_clk),
        .rst_n(rst_n),
        .read_en(read_en),
        .rd_ptr_bin(rd_ptr_bin)
    );

    // Synchronize Read Pointer into Write Clock Domain
    shyn #(SIZE) sync_rd(
    .sync_bin_out(rd_ptr_sync),
    .async_bin_in(rd_ptr_bin),   // Updated to match shyn port name
    .clk(wr_clk),
    .rst_n(rst_n)
);


    // Synchronize Write Pointer into Read Clock Domain
    shyn #(SIZE) sync_wr(
        .sync_bin_out(wr_ptr_sync),
        .async_bin_in(wr_ptr_bin),
        .clk(rd_clk),
        .rst_n(rst_n)
    );

    // FIFO Memory
    fifo_mem #(SIZE, WIDTH, DEPTH) mem_inst(
        .wr_clk(wr_clk),
        .rd_clk(rd_clk),
        .rst_n(rst_n),
        .write_en(write_en),
        .read_en(read_en),
        .data_in(data_in),
        .wr_addr(wr_ptr_bin),
        .rd_addr(rd_ptr_bin),
        .data_out(data_out)
    );

    // Status Flags
    status_flags #(SIZE, DEPTH) flag_inst(
        .wr_ptr_bin(wr_ptr_sync),
        .rd_ptr_bin(rd_ptr_sync),
        .fifo_full(fifo_full),
        .fifo_empty(fifo_empty)
    );

endmodule
