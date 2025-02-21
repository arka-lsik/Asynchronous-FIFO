`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////


// Two-Stage Gray Code Synchronizer

module shyn #(parameter SIZE = 4)(
    input  wire clk,rst_n,        
    input  wire [SIZE-1:0]  async_bin_in,// Asynchronous binary input signal
    output reg  [SIZE-1:0]  sync_bin_out // Synchronized binary output signal
);


    reg [SIZE-1:0] gray_in;         // Gray-coded input
    reg [SIZE-1:0] sync_stage1;     // First stage of synchronization (Gray code)
    reg [SIZE-1:0] sync_stage2;     // Second stage of synchronization (Gray code)


    function [SIZE-1:0] bin_to_gray;
        input [SIZE-1:0] bin;
        begin
            bin_to_gray = bin ^ (bin >> 1); // Binary to Gray code conversion
        end
    endfunction
//gray to binary conversion
    function [SIZE-1:0] gray_to_bin;
        input [SIZE-1:0] gray;
        integer i;
        begin
            gray_to_bin[SIZE-1] = gray[SIZE-1];
            for (i = SIZE-2; i >= 0; i = i - 1)
                gray_to_bin[i] = gray_to_bin[i+1] ^ gray[i];
        end
    endfunction

 
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_stage1   <= 0;
            sync_stage2   <= 0;
            sync_bin_out  <= 0;
        end else begin
            gray_in       <= bin_to_gray(async_bin_in);  // Convert binary input to Gray code
            sync_stage1   <= gray_in;                   // First synchronization stage
            sync_stage2   <= sync_stage1;               // Second synchronization stage
            sync_bin_out  <= gray_to_bin(sync_stage2);  // Convert synchronized Gray code back to binary
        end
    end

endmodule
