/*******************************************************************//**
 *  \file opsg.v
 *  \author René Richard
 *  \brief This program contains specific functions for the genesis cartridge
 *
 *  \copyright This file is part of OPSG.
 *
 *   OPSG is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   OPSG is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with OPSG.  If not, see <http://www.gnu.org/licenses/>.
 */

`include "opsg_tone.v"
`include "opsg_noise.v"

module opsg #(
	parameter TAPPED_BIT0 = 0,
	parameter TAPPED_BIT1 = 3,
	parameter SHIFT_WIDTH = 15,
	parameter TONE_WIDTH = 10,
	parameter MAX_VOLUME = 4096,
	parameter CLK_DIV = 4
)(
	input clk, n_rst, n_wr,
	input [7:0] data,
	output ch1, ch2, ch3, ch4,
	output [15:0] audio_left,
	output [15:0] audio_right
);

	//clock divider
	reg [4:0] clk_div = 0;
	wire clk32;

	//tone, vol, ctrl registers
	reg [TONE_WIDTH-1:0] freq1 = 1;
	reg [TONE_WIDTH-1:0] freq2 = 1;
	reg [TONE_WIDTH-1:0] freq3 = 1;
	reg [3:0] vol1 = 4'b1111;
	reg [3:0] vol2 = 4'b1111;
	reg [3:0] vol3 = 4'b1111;
	reg [3:0] vol4 = 4'b1111;
	reg [2:0] ctrl4 = 3'b100;
	reg [2:0] prev_reg = 3'b000;
	reg noise_reload = 0;

	// audio summing
	reg [15:0] aleft;
	reg [15:0] aright;
  
	// each bit of attenuation corresponds to 2dB
	// 2dB = 10^(-0.1) = 0.79432823
	function [15:0] vol_table;
		input [3:0] vol;
		reg [15:0] vol_temp;
		begin
			case(vol)
				0  : vol_temp = MAX_VOLUME;
				1  : vol_temp = MAX_VOLUME * 0.79432823;
				2  : vol_temp = MAX_VOLUME * 0.63095734;
				3  : vol_temp = MAX_VOLUME * 0.50118723;
				4  : vol_temp = MAX_VOLUME * 0.39810717;
				5  : vol_temp = MAX_VOLUME * 0.31622777;
				6  : vol_temp = MAX_VOLUME * 0.25118864;
				7  : vol_temp = MAX_VOLUME * 0.19952623;
				8  : vol_temp = MAX_VOLUME * 0.15848932;
				9  : vol_temp = MAX_VOLUME * 0.12589254;
				10 : vol_temp = MAX_VOLUME * 0.10000000;
				11 : vol_temp = MAX_VOLUME * 0.07943282;
				12 : vol_temp = MAX_VOLUME * 0.06309573;
				13 : vol_temp = MAX_VOLUME * 0.05011872;
				14 : vol_temp = MAX_VOLUME * 0.03981072;
				default : vol_temp = 0;
			endcase
		  //$display("att: %d vol: %d",vol,vol_temp);
		  vol_table = vol_temp;
		end
	endfunction
  
	//divide the master clock by 32
	always @(posedge clk) begin
		clk_div <= clk_div + 1;
	end
	// 
	assign clk32 = clk_div[CLK_DIV];
  
	// assign weighted audio outputs to channels
	assign audio_left = (ch1 ? vol_table(vol1) : 0) + (ch2 ? vol_table(vol2) : 0) + (ch3 ? vol_table(vol3) : 0) + (ch4 ? vol_table(vol4) : 0)   ;
	assign audio_right = audio_left;
  
	// CHANNEL 1
	opsg_tone #(
		.TONE_WIDTH(TONE_WIDTH)
	) psg_ch1(
		.clk(clk32),
		.freq(freq1),
		.toneBit(ch1)
	);
  
	// CHANNEL 2
	opsg_tone #(
		.TONE_WIDTH(TONE_WIDTH)
	) psg_ch2 (
		.clk(clk32),
		.freq(freq2),
		.toneBit(ch2)
	);
  
	// CHANNEL 3
	opsg_tone #(
		.TONE_WIDTH(TONE_WIDTH)
	) psg_ch3 (
		.clk(clk32),
		.freq(freq3),
		.toneBit(ch3)
	);
  
	// NOISE CHANNEL
	opsg_noise #(
		.TAPPED_BIT0(0),
		.TAPPED_BIT1(3),
		.SHIFT_WIDTH(15),
		.TONE_WIDTH(TONE_WIDTH)
	) psg_noise (
		.clk(clk32),
		.reload(noise_reload),
		.fb(ctrl4[2]),
		.nf(ctrl4[1:0]),
		.freq(freq3),
		.noiseBit(ch4)
	);
  
  //data input
	always @(posedge clk, negedge n_rst) begin
		if (!n_rst) begin
			vol1 = 4'b1111;
			vol2 = 4'b1111;
			vol3 = 4'b1111;
			vol4 = 4'b1111;
			ctrl4 = 3'b100;
			noise_reload = 0;
		end else begin
			noise_reload <= 1;
			if (!n_wr) begin
				if (data[7] == 1'b1) begin
					case(data[6:4])
						3'b000 : freq1[3:0] <= data[3:0];
						3'b010 : freq2[3:0] <= data[3:0];
						3'b100 : freq3[3:0] <= data[3:0];
						3'b110 : 
							begin 
								ctrl4 <= data[2:0];
								noise_reload <= 0;
							end
						3'b001 : vol1[3:0] <= data[3:0];
						3'b011 : vol2[3:0] <= data[3:0];
						3'b101 : vol3[3:0] <= data[3:0];
						3'b111 : vol4[3:0] <= data[3:0];
						default : begin end
					endcase
					prev_reg <= data[6:4];
				end else begin
					case(prev_reg)
						3'b000 : freq1[9:4] <= data[5:0];
						3'b010 : freq2[9:4] <= data[5:0];
						3'b100 : freq3[9:4] <= data[5:0];
						3'b001 : vol1[3:0] <= data[3:0];
						3'b011 : vol2[3:0] <= data[3:0];
						3'b101 : vol3[3:0] <= data[3:0];
						3'b111 : vol4[3:0] <= data[3:0];
						default : begin end
					endcase
				end
			end
		end
	end
  
endmodule
