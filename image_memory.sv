`timescale 1ns / 1ps

module image_memory #(
    parameter WIDTH = 320,
    parameter HEIGHT = 240,
    parameter MEM_INIT_FILE = "image_data.mem"  
)(
    input  logic clk,
    input  logic [16:0] addr,      
    output logic [23:0] data      
);

    localparam TOTAL_PIXELS = WIDTH * HEIGHT;  
    
    (* ram_style = "block" *) logic [23:0] image_ram [0:TOTAL_PIXELS-1];
    
    initial begin
        if (MEM_INIT_FILE != "") begin
            $readmemh(MEM_INIT_FILE, image_ram);
        end
    end
    
    always_ff @(posedge clk) begin
        if (addr < TOTAL_PIXELS) begin
            data <= image_ram[addr];
        end else begin
            data <= 24'h000000;  //black because out of bounds
        end
    end

endmodule
