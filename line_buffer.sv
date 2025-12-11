`timescale 1ns / 1ps


module line_buffer #(
    parameter WIDTH = 320,
    parameter DATA_WIDTH = 8
)(
    input  logic clk,
    input  logic reset,
    input  logic enable,           
    input  logic [DATA_WIDTH-1:0] pixel_in,  
    output logic [DATA_WIDTH-1:0] line0,     
    output logic [DATA_WIDTH-1:0] line1,     
    output logic [DATA_WIDTH-1:0] line2      
);


    (* ram_style = "distributed" *) logic [DATA_WIDTH-1:0] buffer0 [0:WIDTH-1];
    (* ram_style = "distributed" *) logic [DATA_WIDTH-1:0] buffer1 [0:WIDTH-1];
    

    logic [$clog2(WIDTH)-1:0] col;
    

    assign line0 = buffer0[col];
    assign line1 = buffer1[col];
    assign line2 = pixel_in;
    
    always_ff @(posedge clk) begin
        if (reset) begin
            col <= 0;

            for (int i = 0; i < WIDTH; i++) begin
                buffer0[i] <= {DATA_WIDTH{1'b0}};
                buffer1[i] <= {DATA_WIDTH{1'b0}};
            end
        end else if (enable) begin

            buffer0[col] <= buffer1[col];  
            buffer1[col] <= pixel_in;    
            

            if (col == WIDTH - 1) begin
                col <= 0;
            end else begin
                col <= col + 1;
            end
        end
    end

endmodule

