`timescale 1ns / 1ps

module image_processor #(
    parameter IMG_WIDTH = 320,
    parameter IMG_HEIGHT = 240
)(
    input  logic clk,
    input  logic reset,
    input  logic [7:0] red_in,
    input  logic [7:0] green_in,
    input  logic [7:0] blue_in,
    input  logic valid_in,       
    input  logic frame_start,    
    input  logic [2:0] mode,     
    output logic [7:0] red_out,
    output logic [7:0] green_out,
    output logic [7:0] blue_out
);

    logic [7:0] gray;
    
    logic [7:0] edges;
    logic edges_valid;
    
    logic [7:0] red_delayed, green_delayed, blue_delayed;
    logic [7:0] gray_delayed;
    logic valid_delayed;

    logic [7:0] red_pipe [0:7];
    logic [7:0] green_pipe [0:7];
    logic [7:0] blue_pipe [0:7];
    logic [7:0] gray_pipe [0:7];
    
    always_ff @(posedge clk) begin
        if (reset) begin
            for (int i = 0; i < 8; i++) begin
                red_pipe[i] <= 8'd0;
                green_pipe[i] <= 8'd0;
                blue_pipe[i] <= 8'd0;
                gray_pipe[i] <= 8'd0;
            end
        end else begin
            red_pipe[0] <= red_in;
            green_pipe[0] <= green_in;
            blue_pipe[0] <= blue_in;
            gray_pipe[0] <= gray;
            
            for (int i = 1; i < 8; i++) begin
                red_pipe[i] <= red_pipe[i-1];
                green_pipe[i] <= green_pipe[i-1];
                blue_pipe[i] <= blue_pipe[i-1];
                gray_pipe[i] <= gray_pipe[i-1];
            end
        end
    end
    
    assign red_delayed = red_pipe[7];
    assign green_delayed = green_pipe[7];
    assign blue_delayed = blue_pipe[7];
    assign gray_delayed = gray_pipe[7];
    
    grayscale_converter gray_conv (
        .clk(clk),
        .reset(reset),
        .red(red_in),
        .green(green_in),
        .blue(blue_in),
        .gray(gray)
    );
    
    sobel_edge_detector #(
        .WIDTH(IMG_WIDTH)
    ) edge_det (
        .clk(clk),
        .reset(reset),
        .enable(valid_in),
        .frame_start(frame_start),
        .pixel_in(gray),
        .edge_out(edges),
        .valid(edges_valid)
    );
    
    always_ff @(posedge clk) begin
        if (reset) begin
            red_out   <= 8'd0;
            green_out <= 8'd0;
            blue_out  <= 8'd0;
        end else begin
            case (mode)
                3'd0: begin
                    // Mode 0: Original color image
                    red_out   <= red_delayed;
                    green_out <= green_delayed;
                    blue_out  <= blue_delayed;
                end
                
                3'd1: begin
                    // Mode 1: Grayscale
                    red_out   <= gray_delayed;
                    green_out <= gray_delayed;
                    blue_out  <= gray_delayed;
                end
                
                3'd2: begin
                    // Mode 2: Edge Detection (white on black)
                    red_out   <= edges;
                    green_out <= edges;
                    blue_out  <= edges;
                end
                
                3'd3: begin
                    // Mode 3: Inverted Edges (black on white)
                    red_out   <= ~edges;
                    green_out <= ~edges;
                    blue_out  <= ~edges;
                end
                
                3'd4: begin
                    // Mode 4: Inverted Colors
                    red_out   <= ~red_delayed;
                    green_out <= ~green_delayed;
                    blue_out  <= ~blue_delayed;
                end
                
                3'd5: begin
                    // Mode 5: Sepia Tone
                    logic [15:0] sepia_r, sepia_g, sepia_b;
                    sepia_r = (red_delayed * 100 + green_delayed * 196 + blue_delayed * 48) >> 8;
                    sepia_g = (red_delayed * 89 + green_delayed * 175 + blue_delayed * 43) >> 8;
                    sepia_b = (red_delayed * 70 + green_delayed * 136 + blue_delayed * 33) >> 8;
                    
                    red_out   <= (sepia_r > 255) ? 8'd255 : sepia_r[7:0];
                    green_out <= (sepia_g > 255) ? 8'd255 : sepia_g[7:0];
                    blue_out  <= (sepia_b > 255) ? 8'd255 : sepia_b[7:0];
                end
                
                3'd6: begin
                    // Mode 6: Brightness Boost (+50%)
                    logic [8:0] bright_r, bright_g, bright_b;
                    bright_r = red_delayed + (red_delayed >> 1);   
                    bright_g = green_delayed + (green_delayed >> 1);
                    bright_b = blue_delayed + (blue_delayed >> 1);
                    
                    red_out   <= (bright_r > 255) ? 8'd255 : bright_r[7:0];
                    green_out <= (bright_g > 255) ? 8'd255 : bright_g[7:0];
                    blue_out  <= (bright_b > 255) ? 8'd255 : bright_b[7:0];
                end
                
                3'd7: begin
                    logic signed [9:0] contrast_r, contrast_g, contrast_b;
                    contrast_r = ((signed'({1'b0, red_delayed}) - 128) * 3 / 2) + 128;
                    contrast_g = ((signed'({1'b0, green_delayed}) - 128) * 3 / 2) + 128;
                    contrast_b = ((signed'({1'b0, blue_delayed}) - 128) * 3 / 2) + 128;
                    
                    red_out   <= (contrast_r < 0) ? 8'd0 : 
                                 (contrast_r > 255) ? 8'd255 : contrast_r[7:0];
                    green_out <= (contrast_g < 0) ? 8'd0 : 
                                 (contrast_g > 255) ? 8'd255 : contrast_g[7:0];
                    blue_out  <= (contrast_b < 0) ? 8'd0 : 
                                 (contrast_b > 255) ? 8'd255 : contrast_b[7:0];
                end
            endcase
        end
    end

endmodule
