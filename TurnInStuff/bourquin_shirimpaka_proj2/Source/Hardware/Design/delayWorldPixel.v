`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Portland State University
// Engineer: Michael Bourquin
// 
// Create Date: 10/30/2018 06:39:00 PM
// Design Name: Deslay World Pixel
// Module Name: delayWorldPixel
// Project Name: Project 2
// Target Devices: 
// Tool Versions: 
// Description: Delays the world pixel data
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module delayWorldPixel(
    input clk,
    input [1:0] dina,
    input [1:0] dinb,
    output reg [1:0] douta,
    output reg [1:0] doutb
    );
    
    always @(posedge clk) begin
        douta <= dina;
        doutb <= dinb;
    end
endmodule
