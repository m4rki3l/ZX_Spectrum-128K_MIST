//============================================================================
// The implementation of the Sinclair ZX Spectrum ULA
//
//  Copyright (C) 2015 Sorgelig
//
//  Based on sample ZX Spectrum code by Goran Devic
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================
module ula
(
    //-------- Clocks and reset -----------------
    input  wire [1:0]  CLOCK_27,     // Input clock 27 MHz
    input  wire        turbo,        // Turbo speed (3.5 MHz x 2 = 7.0 MHz)
    input  wire        mZX,
    input  wire        m128,
    input  wire        nRESET,       // KEY0 is reset
    output wire        locked,       // PLL is locked signal

    //-------- CPU control ----------------------
    output wire        clk_cpu,      // Generates CPU clock of 3.5 MHz
    output wire        clk_ram,      // SDRAM clock 112MHz
    output wire        clk_sys,      // System master clock (28 MHz)
    output wire        clk_ula,		 // System master clock (14 MHz)
    output wire        nINT,         // Generates a vertical retrace interrupt
    output wire        SDRAM_CLK,    // SDRAM clock 112MHz phase shifted for chip

    //-------- Address and data buses -----------
    input  wire [15:0] A,            // Input address bus
    input  wire [7:0]  din,           // Input data bus
    output wire [7:0]  ula_data,     // Output data
    input  wire        nIORQ,
    input  wire        nMREQ,
    input  wire        nRFSH,
    input  wire        io_we,        // Write enable to data register through IO
    input  wire        io_rd,               
    output wire        F11,
    output wire        F1,
	 input  wire [2:0]  page_ram_sel,

    //-------- PS/2 Keyboard --------------------
    input  wire        PS2_CLK,
    input  wire        PS2_DAT,

    //-------- Audio --------------
    output wire        AUDIO_L,
    output wire        AUDIO_R,
    input  wire        AUDIO_IN,

    //-------- VGA connector --------------------
    input  wire        SPI_SCK,
    input  wire        SPI_SS3,
    input  wire        SPI_DI,

    output wire [5:0]  VGA_R,
    output wire [5:0]  VGA_G,
    output wire [5:0]  VGA_B,
    output reg         VGA_HS,
    output reg         VGA_VS,
	 
    output wire [12:0] vram_address, // ULA video block requests a byte from the video RAM
    input  wire [7:0]  vram_data,    // ULA video block reads a byte from the video RAM
	 input  wire        scandoubler_disable
);
`default_nettype none

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Instantiate PLL and clocks block
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
wire f0,f1;

pll pll_( .inclk0(CLOCK_27[0]), .c0(f0), .c1(f1), .locked(locked));

reg [5:0] counter0 = 6'd0;
wire   clk_psg = counter0[5]; //1.75MHz
assign clk_ula = counter0[2]; //14MHz
assign clk_sys = counter0[1]; //28MHz
always @(posedge f0) counter0 <= counter0 + 6'd1;

reg clk_cpu_turbo;
reg [3:0] counterT = 4'd0;
always @(posedge f0) begin
	counterT <= counterT + 4'd1;
	if(counterT == 4'd13) begin
		counterT <= 4'd0;
		clk_cpu_turbo <= !clk_cpu_turbo;
	end
end

reg [4:0] counter1 = 5'd0;
always @(posedge f1) counter1 <= counter1 + 4'd1;

//`define SLOWRAM

`ifdef SLOWRAM
	assign clk_ram = counter0[0];    //56MHz
	assign SDRAM_CLK = counter1[0];  //56MHz
`else
	assign clk_ram = f0;             //112MHz
	assign SDRAM_CLK = f1;           //112MHz
`endif

wire clk_cpu_std;
clk_switch switch(
	.clk_a(clk_cpu_std),
	.clk_b(clk_cpu_turbo),
	.select(~turbo),
	.out_clk(clk_cpu)
);

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// The ULA output data
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reg [2:0] border;

always @(posedge clk_sys)
begin
	if(!nRESET) begin
        border  <=  3'b000;
        ear_out <= 1'b0; 
        mic_out <= 1'b0;
    end else if (!A[0] && io_we) begin
        border  <= din[2:0];
        ear_out <= din[4]; 
        mic_out <= din[3];
    end
end

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Instantiate audio interface
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reg ear_out;
reg mic_out;

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Instantiate AY8910
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
wire [7:0] sound_data;
wire [7:0] psg_ch_a;
wire [7:0] psg_ch_b;
wire [7:0] psg_ch_c;
wire psg_enable = A[0] && A[15] && !A[1];

wire psg_dir   = psg_delay && io_we && psg_enable;
reg  psg_delay = 0;
always @(negedge clk_cpu) psg_delay <= io_we && psg_enable;
/*
ay8910 ay8910(
	.CLK(clk_psg),
	.EN(1),
	.RESET(!nRESET),
	.BDIR(psg_dir),
	.CS(1),
	.BC(A[14]),
	.DI(din),
	.DO(sound_data),
	.CHANNEL_A(psg_ch_a),
	.CHANNEL_B(psg_ch_b),
	.CHANNEL_C(psg_ch_c)
);
*/
ym2149 ym2149(
	.CLK(clk_psg),
	.RESET(!nRESET),
	.BDIR(psg_dir),
	.BC(A[14]),
	.DI(din),
	.DO(sound_data),
	.CHANNEL_A(psg_ch_a),
	.CHANNEL_B(psg_ch_b),
	.CHANNEL_C(psg_ch_c),
	.SEL(0),
	.MODE(0)
);

sigma_delta_dac #(.MSBI(10)) dac_l (
	.CLK(clk_ula),
	.RESET(!nRESET),
	.DACin({1'b0, psg_ch_a, 1'b0} + {2'b00, psg_ch_b} + {2'b00, ear_out, mic_out, AUDIO_IN, 5'b00000}),
	.DACout(AUDIO_L)
);

sigma_delta_dac #(.MSBI(10)) dac_r(
	.CLK(clk_ula),
	.RESET(!nRESET),
	.DACin({1'b0, psg_ch_c, 1'b0} + {2'b00, psg_ch_b} + {2'b00, ear_out, mic_out, AUDIO_IN, 5'b00000}),
	.DACout(AUDIO_R)
);

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Instantiate ULA's video subsystem
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
wire [7:0] port_ff;
video video(.*, .CLK(clk_ula), .clk_cpu(clk_cpu_std));

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Instantiate keyboard support
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
wire [4:0] KEYB;
keyboard kbd( .*, .CLK(clk_ula));

always_comb begin
	ula_data =       (A[0]==0) ? { 1'b1, AUDIO_IN, 1'b1, KEYB[4:0] } :
                 (psg_enable) ? (A[14] ? sound_data : 8'hFF) :
                                port_ff;
end

endmodule

module clk_switch 
(
   input  clk_a,
   input  clk_b,
   input  select,
   output out_clk
);

reg q1,q2,q3,q4;

always @ (posedge clk_a) begin
	q1 <= q4;
	q3 <= or_one;
end

always @ (posedge clk_b) begin
	q2 <= q3;
	q4 <= or_two;
end

wire or_one   = (!q1) | (!select);
wire or_two   = (!q2) | (select);
wire or_three = (q3)  | (clk_a);
wire or_four  = (q4)  | (clk_b);

assign out_clk  = or_three & or_four;

endmodule
