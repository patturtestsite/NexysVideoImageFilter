`timescale 1ns / 1ps

// Sobel Edge Detector
// Applies 3x3 Sobel kernels to detect edges
// Gx = [-1  0  1]    Gy = [-1 -2 -1]
//      [-2  0  2]         [ 0  0  0]
//      [-1  0  1]         [ 1  2  1]
module sobel_edge_detector #(
    parameter WIDTH = 320
)(
    input  logic clk,
    input  logic reset,
    input  logic enable,       
    input  logic frame_start,  
    input  logic [7:0] pixel_in,  
    output logic [7:0] edge_out,  
    output logic valid         
);


    logic [7:0] line0, line1, line2;
    

    logic [$clog2(WIDTH)-1:0] pixel_count;
    logic [10:0] line_count; 
    
    always_ff @(posedge clk) begin
        if (reset || frame_start) begin
            pixel_count <= 0;
            line_count <= 0;
        end else if (enable) begin
            if (pixel_count == WIDTH - 1) begin
                pixel_count <= 0;
                if (line_count < 1000)  
                    line_count <= line_count + 1;
            end else begin
                pixel_count <= pixel_count + 1;
            end
        end
    end
    
    line_buffer #(
        .WIDTH(WIDTH),
        .DATA_WIDTH(8)
    ) lbuf (
        .clk(clk),
        .reset(reset | frame_start),
        .enable(enable),
        .pixel_in(pixel_in),
        .line0(line0),
        .line1(line1),
        .line2(line2)
    );
    

    logic [7:0] window [0:2][0:2];  
    

    always_ff @(posedge clk) begin
        if (reset) begin
            for (int i = 0; i < 3; i++) begin
                for (int j = 0; j < 3; j++) begin
                    window[i][j] <= 8'd0;
                end
            end
        end else if (enable) begin
            //shift columns left
            window[0][0] <= window[0][1];
            window[0][1] <= window[0][2];
            window[0][2] <= line0;
            
            window[1][0] <= window[1][1];
            window[1][1] <= window[1][2];
            window[1][2] <= line1;
            
            window[2][0] <= window[2][1];
            window[2][1] <= window[2][2];
            window[2][2] <= line2;
        end
    end
    
    logic signed [11:0] gx, gy;
    logic [11:0] gx_abs, gy_abs;
    logic [12:0] magnitude;
    
    logic [3:0] valid_delay;
    
    always_ff @(posedge clk) begin
        if (reset) begin
            gx <= 12'sd0;
            gy <= 12'sd0;
            gx_abs <= 12'd0;
            gy_abs <= 12'd0;
            magnitude <= 13'd0;
            edge_out <= 8'd0;
            valid_delay <= 4'd0;
        end else if (enable) begin

            gx <= signed'({1'b0, window[0][2]}) - signed'({1'b0, window[0][0]})
                + (signed'({1'b0, window[1][2]}) - signed'({1'b0, window[1][0]})) * 2
                + signed'({1'b0, window[2][2]}) - signed'({1'b0, window[2][0]});
            
            gy <= signed'({1'b0, window[2][0]}) - signed'({1'b0, window[0][0]})
                + (signed'({1'b0, window[2][1]}) - signed'({1'b0, window[0][1]})) * 2
                + signed'({1'b0, window[2][2]}) - signed'({1'b0, window[0][2]});
            

            gx_abs <= (gx[11]) ? -gx : gx;
            gy_abs <= (gy[11]) ? -gy : gy;
            

            magnitude <= gx_abs + gy_abs;
            

            if (magnitude > 255)
                edge_out <= 8'd255;
            else
                edge_out <= magnitude[7:0];
            

            if (line_count >= 2 && pixel_count >= 2) begin
                valid_delay <= {valid_delay[2:0], 1'b1};
            end else begin
                valid_delay <= {valid_delay[2:0], 1'b0};
            end
        end
    end
    
    assign valid = valid_delay[3];

endmodule



