`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/23/2018 05:05:14 PM
// Design Name: World Colorizer
// Module Name: colorizer
// Project Name: Project 2
// Target Devices: 
// Tool Versions: 
// Description: Translates world pixel data to an RGB color for output
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module colorizer(
    input video_on,
    input [1:0] world_pixel,
    input [1:0] icon,
    
    output reg [3:0] red,
    output reg [3:0] green,
    output reg [3:0] blue  
    );
    
    //reg [3:0] red, green, blue; //combinatorial wires for red, green and blue
    
    //combinatorial logic for output
    always@(*) begin
       //defaulted to black screen
       red = 4'h0;
       green = 4'h0;
       blue = 4'h0;
       if(video_on) begin //only output world map data when video_on
       	if(icon != 0) begin //icon not transparent
       	     case(icon)
       	         2'b01: begin //green
       	             red = 4'h0;
       	             green = 4'hf;
       	             blue = 4'h0;
       	         end
       	         2'b10: begin //blue
       	             red = 4'h0;
       	             green = 4'h0;
       	             blue = 4'hf;
       	         end
       	         2'b11: begin //yellow
       	             red = 4'hf;
       	             green = 4'hf;
       	             blue = 4'h8;
       	         end 
       	     endcase    
       	end
       	else
       	 case(world_pixel)
       	     2'b00: begin //white background
       	         red = 4'hf;
       	         green = 4'hf;
       	         blue = 4'hf;
       	     end
       	     2'b01: begin //black line
       	         red = 4'h0;
       	         green = 4'h0;
       	         blue = 4'h0;
       	     end
       	     2'b10: begin //red obstruction
       	         red = 4'hf;
       	         green = 4'h0;
       	         blue = 4'h0;
       	     end
       	 endcase
       	end
    end
endmodule
