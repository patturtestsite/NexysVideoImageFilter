`timescale 1ns / 1ps

// Senior project: Image Filtering with FPGA Top Module!
module image_display_top (
    input  logic       clk,           
    input  logic       reset_n,       
    input  logic [2:0] sw,            
    

    output logic       hdmi_tx_clk_p,
    output logic       hdmi_tx_clk_n,
    output logic [2:0] hdmi_tx_p,
    output logic [2:0] hdmi_tx_n,
    

    output logic [7:0] led
);


    logic clk_pixel;
    logic clk_locked;
    logic sys_reset;
    
    assign sys_reset = !reset_n || !clk_locked;
    

    logic hsync, vsync, video_active;
    logic [11:0] x, y;
    

    logic [16:0] mem_addr;
    logic [23:0] pixel_data;
    

    logic [7:0] red_raw, green_raw, blue_raw;
    logic in_image_region;
    

    logic [7:0] red_proc, green_proc, blue_proc;
    

    logic [7:0] red, green, blue;
    

    logic [23:0] vid_data;
    assign vid_data = {red, green, blue};
    

    assign led[0] = clk_locked;
    assign led[1] = video_active;
    assign led[4:2] = sw;  // for filter mode!
    //assign led[7:5] = 3'd0;
    
    clk_wiz_0 clock_gen (
        .clk_in1(clk),
        .reset(!reset_n),
        .clk_out1(clk_pixel),   // 148.5 MHz
        .locked(clk_locked)
    );
    
    video_timing_gen timing_gen (
        .clk_pixel(clk_pixel),
        .reset(sys_reset),
        .hsync(hsync),
        .vsync(vsync),
        .video_active(video_active),
        .x(x),
        .y(y)
    );
    
    image_memory #(
        .WIDTH(320),
        .HEIGHT(240),
        .MEM_INIT_FILE("image_data.mem")
    ) img_mem (
        .clk(clk_pixel),
        .addr(mem_addr),
        .data(pixel_data)
    );
    
    // mapping x, y to img_x, img_y (+ scaling/centering)
    localparam SCALE = 3;
    localparam SCALED_WIDTH = 320 * SCALE;   // 960
    localparam SCALED_HEIGHT = 240 * SCALE;  // 720
    localparam X_OFFSET = (1920 - SCALED_WIDTH) / 2;
    localparam Y_OFFSET = (1080 - SCALED_HEIGHT) / 2;
    
    logic [11:0] img_x, img_y;
    logic frame_start;

    assign frame_start = (x == X_OFFSET) && (y == Y_OFFSET) && video_active;
    
    always_comb begin
        in_image_region = video_active && 
                         (x >= X_OFFSET) && (x < X_OFFSET + SCALED_WIDTH) &&
                         (y >= Y_OFFSET) && (y < Y_OFFSET + SCALED_HEIGHT);
        
        if (in_image_region) begin
            img_x = (x - X_OFFSET) / SCALE;
            img_y = (y - Y_OFFSET) / SCALE;
        end else begin
            img_x = 12'd0;
            img_y = 12'd0;
        end
    end
    
    assign mem_addr = (img_y * 320) + img_x;
    
    always_ff @(posedge clk_pixel) begin
        if (sys_reset) begin
            red_raw   <= 8'd0;
            green_raw <= 8'd0;
            blue_raw  <= 8'd0;
        end else begin
            red_raw   <= pixel_data[23:16];
            green_raw <= pixel_data[15:8];
            blue_raw  <= pixel_data[7:0];
        end
    end
    
    image_processor #(
        .IMG_WIDTH(320),
        .IMG_HEIGHT(240)
    ) proc (
        .clk(clk_pixel),
        .reset(sys_reset),
        .red_in(red_raw),
        .green_in(green_raw),
        .blue_in(blue_raw),
        .valid_in(in_image_region),
        .frame_start(frame_start),
        .mode(sw),
        .red_out(red_proc),
        .green_out(green_proc),
        .blue_out(blue_proc)
    );
    
    always_ff @(posedge clk_pixel) begin
        if (sys_reset) begin
            red   <= 8'd0;
            green <= 8'd0;
            blue  <= 8'd0;
        end else if (in_image_region) begin
            red   <= red_proc;
            green <= green_proc;
            blue  <= blue_proc;
        end else begin
            // Black background outside image
            red   <= 8'd0;
            green <= 8'd0;
            blue  <= 8'd0;
        end
    end
    
    rgb2dvi_0 hdmi_tx (
        .TMDS_Clk_p(hdmi_tx_clk_p),
        .TMDS_Clk_n(hdmi_tx_clk_n),
        .TMDS_Data_p(hdmi_tx_p),
        .TMDS_Data_n(hdmi_tx_n),
        
        .aRst(sys_reset),
        
        .vid_pData(vid_data),
        .vid_pVDE(video_active),
        .vid_pHSync(hsync),
        .vid_pVSync(vsync),
        
        .PixelClk(clk_pixel)
    );

endmodule

