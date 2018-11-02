// mfp_ahb_gpio.v
//////////////////////////////////////////////////////////////////////////////////
// Company: Portland State University
// Engineer: Michael Bourquin
// 
// Create Date: 10/22/2018 11:15:54 PM
// Design Name: MIPS GPIO Slave
// Module Name: mfp_ahb_gpio
// Project Name: Project 2
// Target Devices: 
// Tool Versions: 
// Description: Maps MIPS addresses to GPIO input/output ports
// Project 2 added 2 write only inputs and 2 read only outputs

`include "mfp_ahb_const.vh"

module mfp_ahb_gpio(
    input                        HCLK,
    input                        HRESETn,
    input      [  3          :0] HADDR,
    input      [  1          :0] HTRANS,
    input      [ 31          :0] HWDATA,
    input                        HWRITE,
    input                        HSEL,
    output reg [ 31          :0] HRDATA,

// memory-mapped I/O
    input      [`MFP_N_SW-1  :0] IO_Switch,
    input      [`MFP_N_PB-1  :0] IO_PB,
    output reg [`MFP_N_LED-1 :0] IO_LED,
    output reg [7:0] IO_BotCtrl, //on a MIPS write, IO_bot control is updated on the bus (input to rojobot)
    input [31:0] IO_BotInfo, //on a MIPS read, bot info is read from the rojobot into HRDATA(software read)
    output reg IO_INT_ACK, //write ACK to the handshake ff
    input IO_BotUpdt_Sync //read rojobot update into HRDATA(software read)
);

  reg  [3:0]  HADDR_d;
  reg         HWRITE_d;
  reg         HSEL_d;
  reg  [1:0]  HTRANS_d;
  wire        we;            // write enable

  // delay HADDR, HWRITE, HSEL, and HTRANS to align with HWDATA for writing
  always @ (posedge HCLK) 
  begin
    HADDR_d  <= HADDR;
	HWRITE_d <= HWRITE;
	HSEL_d   <= HSEL;
	HTRANS_d <= HTRANS;
  end
  
  // overall write enable signal
  assign we = (HTRANS_d != `HTRANS_IDLE) & HSEL_d & HWRITE_d;

    always @(posedge HCLK or negedge HRESETn)
       if (~HRESETn) begin
         IO_LED <= `MFP_N_LED'b0; 
         IO_BotCtrl <= 0;
         IO_INT_ACK <= 0;
       end
       else if (we)
         case (HADDR_d)
           `H_LED_IONUM: IO_LED <= HWDATA[`MFP_N_LED-1:0];
           `H_IO_BotCtrl: IO_BotCtrl <= HWDATA[7:0];
           `H_IO_INT_ACK: IO_INT_ACK <= HWDATA[0];
         endcase
    
	always @(posedge HCLK or negedge HRESETn)
       if (~HRESETn) begin
         HRDATA <= 32'h0;
       end
       else begin
	     case (HADDR)
           `H_SW_IONUM: HRDATA <= { {32 - `MFP_N_SW {1'b0}}, IO_Switch };
           `H_PB_IONUM: HRDATA <= { {32 - `MFP_N_PB {1'b0}}, IO_PB };
           `H_IO_BotInfo: HRDATA <= IO_BotInfo;
           `H_IO_BotUpdt_Sync: begin
                HRDATA[31:1] <= 0;
                HRDATA[0] <= IO_BotUpdt_Sync;
            end
            default:    HRDATA <= 32'h00000000;
         endcase
       end
endmodule
