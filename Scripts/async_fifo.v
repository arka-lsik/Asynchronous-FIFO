module async_fifo #(
  parameter DATA_WIDTH = 8,
  parameter ADDR_WIDTH = 4
)(
  input  wire                  wr_clk,
  input  wire                  wr_rst_n,
  input  wire                  wr_en,
  input  wire [DATA_WIDTH-1:0] wr_data,
  output wire                  full,
  input  wire                  rd_clk,
  input  wire                  rd_rst_n,
  input  wire                  rd_en,
  output wire [DATA_WIDTH-1:0] rd_data,
  output wire                  empty
);
  localparam DEPTH = (1 << ADDR_WIDTH);
  reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
  reg [ADDR_WIDTH:0] wr_bin, wr_gray;
  reg [ADDR_WIDTH:0] rd_bin, rd_gray;
  (* ASYNC_REG = "TRUE" *) reg [ADDR_WIDTH:0] wg_s1, wg_s2;
  (* ASYNC_REG = "TRUE" *) reg [ADDR_WIDTH:0] rg_s1, rg_s2;

  function [ADDR_WIDTH:0] b2g;
    input [ADDR_WIDTH:0] b;
    begin 
      b2g = b ^ (b >> 1); 
    end
  endfunction

  wire [ADDR_WIDTH:0] wr_bin_nxt  = wr_bin + (wr_en & ~full);
  wire [ADDR_WIDTH:0] rd_bin_nxt  = rd_bin + (rd_en & ~empty);
  wire [ADDR_WIDTH:0] wr_gray_nxt = b2g(wr_bin_nxt);
  wire [ADDR_WIDTH:0] rd_gray_nxt = b2g(rd_bin_nxt);

  always @(posedge wr_clk or negedge wr_rst_n) 
    begin
    if (!wr_rst_n) 
      begin 
        wr_bin <= 0; wr_gray <= 0; 
      end
    else           
      begin 
        wr_bin <= wr_bin_nxt; wr_gray <= wr_gray_nxt; 
      end
  end
  always @(posedge wr_clk)
    if (wr_en && !full) mem[wr_bin[ADDR_WIDTH-1:0]] <= wr_data;

  always @(posedge rd_clk or negedge rd_rst_n) 
    begin
    if (!rd_rst_n) 
      begin 
        rd_bin <= 0; rd_gray <= 0; 
      end
    else           
      begin 
        rd_bin <= rd_bin_nxt; 
        rd_gray <= rd_gray_nxt; 
      end
  end
  assign rd_data = mem[rd_bin[ADDR_WIDTH-1:0]];

  always @(posedge rd_clk or negedge rd_rst_n) 
    begin
    if (!rd_rst_n) 
      begin 
        wg_s1 <= 0; 
        wg_s2 <= 0; 
      end
    else           
      begin 
        wg_s1 <= wr_gray; 
        wg_s2 <= wg_s1; 
      end
  end
  always @(posedge wr_clk or negedge wr_rst_n) 
    begin
    if (!wr_rst_n) 
      begin 
        rg_s1 <= 0; 
        rg_s2 <= 0; 
      end
    else           
      begin 
        rg_s1 <= rd_gray; 
        rg_s2 <= rg_s1; 
      end
  end

  assign full  = (wr_gray == {~rg_s2[ADDR_WIDTH:ADDR_WIDTH-1], rg_s2[ADDR_WIDTH-2:0]});
  assign empty = (rd_gray == wg_s2);
endmodule
