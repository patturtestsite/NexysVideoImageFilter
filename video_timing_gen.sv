`timescale 1ns / 1ps

// VERY IMPORTANT! Generates sync signals and pixel coordinates for standard video formats
module video_timing_gen #(
    parameter H_ACTIVE = 1920,
    parameter H_FRONT  = 88,
    parameter H_SYNC   = 44,
    parameter H_BACK   = 148,
    parameter V_ACTIVE = 1080,
    parameter V_FRONT  = 4,
    parameter V_SYNC   = 5,
    parameter V_BACK   = 36
)(
    input  logic clk_pixel,     
    input  logic reset,
    output logic hsync,          
    output logic vsync,          
    output logic video_active,   
    output logic [11:0] x,       
    output logic [11:0] y       
);


    localparam H_TOTAL = H_ACTIVE + H_FRONT + H_SYNC + H_BACK;  
    localparam V_TOTAL = V_ACTIVE + V_FRONT + V_SYNC + V_BACK;  
    

    logic [11:0] h_count;
    logic [11:0] v_count;
    
    always_ff @(posedge clk_pixel) begin
        if (reset) begin
            h_count <= 12'd0;
        end else begin
            if (h_count == H_TOTAL - 1) begin
                h_count <= 12'd0;
            end else begin
                h_count <= h_count + 1'b1;
            end
        end
    end
    
    always_ff @(posedge clk_pixel) begin
        if (reset) begin
            v_count <= 12'd0;
        end else begin
            if (h_count == H_TOTAL - 1) begin
                if (v_count == V_TOTAL - 1) begin
                    v_count <= 12'd0;
                end else begin
                    v_count <= v_count + 1'b1;
                end
            end
        end
    end
    
    always_ff @(posedge clk_pixel) begin
        if (reset) begin
            hsync <= 1'b0;
            vsync <= 1'b0;
        end else begin
            hsync <= (h_count >= H_ACTIVE + H_FRONT) && 
                     (h_count < H_ACTIVE + H_FRONT + H_SYNC);
            
            vsync <= (v_count >= V_ACTIVE + V_FRONT) && 
                     (v_count < V_ACTIVE + V_FRONT + V_SYNC);
        end
    end
    
    always_ff @(posedge clk_pixel) begin
        if (reset) begin
            video_active <= 1'b0;
        end else begin
            video_active <= (h_count < H_ACTIVE) && (v_count < V_ACTIVE);
        end
    end
    
    assign x = h_count;
    assign y = v_count;

endmodule
