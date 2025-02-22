//Test bench for the fifo top module
module async_fifo_tb;
    parameter SIZE = 4;
    parameter WIDTH = 8;
    parameter DEPTH = 16;

    reg wr_clk, rd_clk, rst_n;
    reg write_en, read_en;
    reg [WIDTH-1:0] data_in;
    wire [WIDTH-1:0] data_out;
    wire fifo_full, fifo_empty;

  async_fifo #(SIZE, WIDTH, DEPTH) dut (
        .wr_clk(wr_clk),
        .rd_clk(rd_clk),
        .rst_n(rst_n),
        .write_en(write_en),
        .read_en(read_en),
        .data_in(data_in),
        .data_out(data_out),
        .fifo_full(fifo_full),
        .fifo_empty(fifo_empty)
    );

    // Clock generation
    initial begin
        wr_clk = 0; rd_clk = 0;
        forever #5 wr_clk = ~wr_clk;
    end

    initial begin
        forever #7 rd_clk = ~rd_clk;
    end

    // Test sequence
    initial begin
        rst_n = 0; write_en = 0; read_en = 0; data_in = 0;
        #15 rst_n = 1;

        // Write data
        repeat (10) begin
            @(posedge wr_clk);
            if (!fifo_full) begin
                write_en = 1;
                data_in = data_in + 1;
            end
        end
        write_en = 0;

        // Read data
        repeat (10) begin
            @(posedge rd_clk);
            if (!fifo_empty)
                read_en = 1;
        end
        read_en = 0;

        // Finish simulation
        #50 $finish;
    end

    // Monitor output
    initial begin
        $monitor("Time=%0t, DataOut=%0h, Full=%b, Empty=%b", $time, data_out, fifo_full, fifo_empty);
    end
endmodule
