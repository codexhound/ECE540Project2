// mfp_nexys4_ddr.v
// Collaborators: Michael Bourquin, Jean Shirimpaka
// Project: Project 2: Rojobot, Icon, and Video Display
// File Description:
// Defines the top level for the system and instantiates all the lower level modules
// match the GPIO, LEDs, switches, Segment Display, and VGA outputs on Digilent's (Xilinx)
// Nexys4 DDR board
// Also Debounces button and switch inputs

// Outputs:
// 16 LEDs (IO_LED), 
// 8 7SegMentDisplay Enables(AN) 
// 8 7SegmentDisplaySeg Enables(CA,CB,CC,CD,CE,CF,CG,DP)
// 2 VGA Sync Enables (VGA_HS, VGA_VS)
// 3 VGA Color Signals (VGA_R, VGA_G, VGA_B)
// Inputs:
// 16 Slide switches (IO_Switch),
// 5 Pushbuttons (IO_PB): {BTNU, BTND, BTNL, BTNC, BTNR}
//

`include "mfp_ahb_const.vh"

module mfp_nexys4_ddr( 
                        input                   CLK100MHZ,
                        input                   CPU_RESETN,
                        input                   BTNU, BTND, BTNL, BTNC, BTNR, 
                        input  [`MFP_N_SW-1 :0] SW,         
                        output [`MFP_N_LED-1:0] LED,
                        inout  [ 8          :1] JB,
                        input                   UART_TXD_IN,
                        output                  CA,CB,CC,CD,CE,CF,CG,DP,
                        output [7:0]            AN,
                        output                  VGA_HS, VGA_VS,
                        output [3:0]            VGA_R, VGA_G, VGA_B);

  // Press btnCpuReset to reset the processor. 
        
  wire clk_out50, clk_out75; 
  wire tck_in, tck;
  
  clk_wiz_1 clk_wiz_1(.clk_in1(CLK100MHZ), .clk_out1(clk_out50), .clk_out2(clk_out75));
  IBUF IBUF1(.O(tck_in),.I(JB[4]));
  BUFG BUFG1(.O(tck), .I(tck_in));
     
  wire [5:0] pbtn_db;
  wire [15:0] switch_db;
  wire [7:0] dispenout;
  wire [7:0] dispout;
  wire [31:0] haddr;
  wire [31:0] hrdata;
  wire [31:0] hwdata;
  wire hwrite;
  wire [5:0] pbtn_in;
  wire [31:0] IO_BOTINFO;
  
  wire [7:0] iobotcntr, LocX_reg, LocY_reg, Sensors_reg, iobotinfo;
  wire iointack, iobotupdtsync, bot_update;
  wire [13:0] worldmap_addr, vid_addr;
  wire [11:0] pixel_row, pixel_column;    
  wire [1:0] worldmap_data, world_pixel, icon, worldmap_data_shifted, world_pixel_shifted;    
  
  //32 input bus from the rojobot to the MIPS slave bus system (for software)
  assign IO_BOTINFO[31:24] = LocX_reg;
  assign IO_BOTINFO[23:16] = LocY_reg;
  assign IO_BOTINFO[15:8] = Sensors_reg;
  assign IO_BOTINFO[7:0] = iobotinfo;
  
  //no debounced inputs to debouncer
  assign pbtn_in[5] = CPU_RESETN;
  assign pbtn_in[4] = BTNC;
  assign pbtn_in[3] = BTNL;
  assign pbtn_in[2] = BTNU;
  assign pbtn_in[1] = BTNR;
  assign pbtn_in[0] = BTND;
  
  //7seg segment enable outputs
  assign DP = dispout[7]; //assigning these based on mfp_ahb_sevensegdec.v
  assign CA = dispout[6];
  assign CB = dispout[5];
  assign CC = dispout[4];
  assign CD = dispout[3];
  assign CE = dispout[2];
  assign CF = dispout[1];
  assign CG = dispout[0];
  
  //7seg display enable output
  assign AN = dispenout;
                                        
  debounce debounce(
                                 .clk(clk_out50),
                                 .pbtn_in(pbtn_in),
                                 .switch_in(SW),
                                 .pbtn_db(pbtn_db),
                                 .swtch_db(switch_db));
  
  //MIPS System Instantiation                                                                               
  mfp_sys mfp_sys(
                                                            .SI_Reset_N(pbtn_db[5]),
                                                            .SI_ClkIn(clk_out50),
                                                            .HADDR(haddr),
                                                            .HRDATA(hrdata),
                                                            .HWDATA(hwdata),
                                                            .HWRITE(hwrite),
                                                            .HSIZE(),
                                                            .EJ_TRST_N_probe(JB[7]),
                                                            .EJ_TDI(JB[2]),
                                                            .EJ_TDO(JB[3]),
                                                            .EJ_TMS(JB[1]),
                                                            .EJ_TCK(tck),
                                                            .SI_ColdReset_N(JB[8]),
                                                            .EJ_DINT(1'b0),
                                                            .IO_Switch(switch_db),
                                                            .IO_PB(pbtn_db[4:0]),
                                                            .IO_LED(LED),
                                                            .disenout(dispenout),
                                                            .disout(dispout),
                                                            .IO_BotCtrl(iobotcntr), 
                                                            .IO_BotInfo(IO_BOTINFO), 
                                                            .IO_INT_ACK(iointack),
                                                            .IO_BotUpdt_Sync(iobotupdtsync),
                                                            .UART_RX(UART_TXD_IN));
                                                                                                       

//handshake flip flop for sync between 75MHZ Video System and 50MHZ MIPS System                                                           
handshakeflipflop handshakeflipflop (
    .clk50(clk_out50),
    .IO_INT_ACK(iointack),
    .IO_BotUpdt_Sync(iobotupdtsync), 
    .IO_BotUpdt(bot_update));

//delay world pixel by 1 more clks after change in display in (2 total after RAM)
//reason is it takes icon pixel 2 clks for valid data after change of display in(pipelining) 
delayWorldPixel(
       .clk(clk_out75),
       .dina(worldmap_data),
       .dinb(world_pixel),
       .douta(worldmap_data_shifted),
       .doutb(world_pixel_shifted)
        );
        
//Instantiate the rojobot                                                          
rojobot31_0 rojobot31_0 (
                                                                .MotCtl_in(iobotcntr),
                                                                .LocX_reg(LocX_reg),
                                                                .LocY_reg(LocY_reg),
                                                                .Sensors_reg(Sensors_reg),
                                                                .BotInfo_reg(iobotinfo),
                                                                .worldmap_addr(worldmap_addr),
                                                                .worldmap_data(worldmap_data_shifted),
                                                                .clk_in(clk_out75),
                                                                .reset(~pbtn_db[5]),
                                                                .upd_sysregs(bot_update),
                                                                .Bot_Config_reg(switch_db[7:0]));

//instantiate the world map RAM                                                                
world_map world_map(
    .clka(clk_out75),
    .addra(worldmap_addr),
    .douta(worldmap_data),
    .clkb(clk_out75),
    .addrb(vid_addr),
    .doutb(world_pixel));

//Instantiate the video out 60HZ refresh controller
    dtg dtg (
        .clock(clk_out75), 
        .rst(~pbtn_db[5]),
        .horiz_sync(VGA_HS),
        .vert_sync(VGA_VS), 
        .video_on(video_on),        
        .pixel_row(pixel_row), 
        .pixel_column(pixel_column));
        
 //Instantiate the scaler from display to world map
        
    videoScale videoScale(
        .pixel_row(pixel_row),
        .pixel_col(pixel_column),
        .vid_addr(vid_addr));
        
//Instantiate colorizer of map pixels  
    colorizer colorizer(
        .video_on(video_on),
        .world_pixel(world_pixel_shifted),
        .icon(icon),
        .red(VGA_R),
        .green(VGA_G),
        .blue(VGA_B));
 
 //instantiate the icon mapping logic
    icon icon1(
          .clk(clk_out75),
          .locXReg(LocX_reg),
          .locYReg(LocY_reg),
          .botInfoReg(iobotinfo),
          .pixel_row(pixel_row),
          .pixel_column(pixel_column),
          .icon(icon));

endmodule
