`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Portland State University
// Engineer: Michael Bourquin
// 
// Create Date: 10/23/2018 05:05:14 PM
// Design Name: World Map Video Scaler
// Module Name: videoScale
// Project Name: Project 2
// Target Devices: 
// Tool Versions: 
// Description: maps display pixels to the corresponding world map pixel
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module videoScale(
    input [11:0] pixel_row, pixel_col,
    //output [6:0] map_row, map_col, //map the display to the 128X128 map
    output reg [13:0] vid_addr);
    
    reg [7:0] map_row, map_col, map_current_rowcol;
    reg [11:0] pixel_l, pixel_m;
    
    //use case/if statements to go through all the possible display ranges (starts from the range column (0-8), row(0-6) ->
    //which maps to world map indices (0,0)
    always@(*) begin
        map_row = 0;
        map_col = 0;
        for (map_current_rowcol=0, pixel_l = 0, pixel_m = 6; pixel_l<768  && map_current_rowcol<128; map_current_rowcol = map_current_rowcol+1, pixel_l = pixel_l + 6, pixel_m = pixel_m +6)
        begin
            if (pixel_row >= pixel_l && pixel_row < pixel_m) //pixel row is within the range row - row+6
              map_row = map_current_rowcol;
         end
         for (map_current_rowcol=0, pixel_l = 0, pixel_m = 8; pixel_l<1024 && map_current_rowcol<128; map_current_rowcol = map_current_rowcol+1, pixel_l = pixel_l + 8, pixel_m = pixel_m +8)
         begin
            if (pixel_col >= pixel_l && pixel_col < pixel_m) //pixel col is within the range col - colrow+8
              map_col = map_current_rowcol;
         end
         
         vid_addr = map_row[6:0]*128 + map_col[6:0];
     end
        
endmodule
