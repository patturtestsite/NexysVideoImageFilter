`timescale 1ns / 1ps

// Using Y = 0.299*R + 0.587*G + 0.114*B - Using integer approximation: Y = (77*R + 150*G + 29*B) >> 8
module grayscale_converter (
    input  logic clk,
    input  logic reset,
    input  logic [7:0] red,
    input  logic [7:0] green,
    input  logic [7:0] blue,
    output logic [7:0] gray
);

    logic [15:0] r_weighted;
    logic [15:0] g_weighted;
    logic [15:0] b_weighted;
    logic [15:0] sum;
    
    always_ff @(posedge clk) begin
        if (reset) begin
            r_weighted <= 16'd0;
            g_weighted <= 16'd0;
            b_weighted <= 16'd0;
            sum <= 16'd0;
            gray <= 8'd0;
        end else begin

            r_weighted <= red * 77;   // 0.299 * 256 ≈ 77
            g_weighted <= green * 150; // 0.587 * 256 ≈ 150
            b_weighted <= blue * 29;   // 0.114 * 256 ≈ 29
            

            sum <= r_weighted + g_weighted + b_weighted;
            gray <= sum[15:8];  // Divide by 256
        end
    end

endmodule

