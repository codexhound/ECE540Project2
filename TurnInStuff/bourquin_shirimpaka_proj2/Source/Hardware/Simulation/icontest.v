// icontest.v
//
// Drive the icon module to test correct mapping

`timescale 100ps/1ps

module icontest;
    reg clk;
    reg [7:0] locXReg, locYReg, botInfoReg;
    reg [11:0] pixel_row, pixel_column;
    wire [1:0] icon;
    
    icon icon1(
        .clk(clk),
        .locXReg(locXReg),
        .locYReg(locYReg),
        .botInfoReg(botInfoReg),
        .pixel_row(pixel_row),
        .pixel_column(pixel_column),
        .icon(icon));

    initial
    begin
        clk = 0;
        forever
            #50 clk = ~clk;
    end
    
    integer row;
    integer col;
    initial
    begin
        locXReg <= 2;
        locYReg <= 2;
        botInfoReg <= 2;
        //loop through overlapping display pixels
        for(row = 3; row < 27; row=row+1) begin
            for(col = 4; col < 36; col=col+1) begin
                pixel_row <= row;
                pixel_column <= col;
                repeat (1) @(posedge clk);
            end
        end
        $stop;
    end
endmodule
