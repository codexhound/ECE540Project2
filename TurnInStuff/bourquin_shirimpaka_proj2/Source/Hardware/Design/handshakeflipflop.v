`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Portland State University
// Engineer: Michael Bourquin
// 
// Create Date: 10/22/2018 11:15:54 PM
// Design Name: Handshake Flip Flop
// Module Name: handshakeflipflop
// Project Name: Project 2
// Target Devices: 
// Tool Versions: 
// Description: Syncs the rojo bot (75HZ) update signal with the MIPS system (50HZ).
// Also drives an ACK signal which disables the update until it is deasserted
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module handshakeflipflop(
    input clk50,
    input IO_INT_ACK,
    input IO_BotUpdt,
    output reg IO_BotUpdt_Sync);

    always @ (posedge clk50) begin
        if (IO_INT_ACK == 1'b1) begin
            IO_BotUpdt_Sync <= 1'b0;
        end
        else if (IO_BotUpdt == 1'b1) begin
            IO_BotUpdt_Sync <= 1'b1;
        end else begin
            IO_BotUpdt_Sync <= IO_BotUpdt_Sync;
        end
    end // always
endmodule
