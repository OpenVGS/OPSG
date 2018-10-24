/*******************************************************************//**
 *  \file opsg.v
 *  \author René Richard
 *  \brief This module contains a testbench for the opsg top-level module
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

//`include "opsg.v"

module test;
  
	reg clk, n_rst, n_wr;
	reg [7:0] data;
	wire ch1, ch2, ch3, ch4;
	wire [3:0] audio_bits;
	wire [15:0] audio_left;
	wire [15:0] audio_right;
  
	// using CLK_DIV 1 just to shrink the simulation length
	// real hardware needs CLK_DIV = 4
	opsg #(.MAX_VOLUME(2048), .CLK_DIV(1)) opsg_test(
		.clk(clk),
		.n_rst(n_rst),
		.n_wr(n_wr),
		.data(data),
		.ch1(ch1),
		.ch2(ch2),
		.ch3(ch3),
		.ch4(ch4),
		.audio_left(audio_left),
		.audio_right(audio_right)
	);
  
	// task to write to the psg
	task write_psg;
		input [7:0] value;
		begin
			data = value;
			n_wr = 1'b0;
			#4 n_wr = 1'b1;
			#2 data = 8'hFF;
		end
	endtask
  
	always #2 clk = !clk;

	initial begin
		$dumpfile("dump.vcd");
		$dumpvars(1);
		
		clk = 0;
		n_rst = 0;
		n_wr = 1;
		data = 8'hFF;
		
		#10 n_rst = 1;

		// write to lower 4 bits of 3 tone channels
		#100 write_psg(8'b10000011);
		#100 write_psg(8'b10100100);
		#100 write_psg(8'b11001000);
		
		// test ch1, other volumes to 0
		#100 write_psg(8'b10010000);
		write_psg(8'b10111111);
		write_psg(8'b11011111);
		write_psg(8'b11111111);
		
		// volume value 10 should be 0.1 of original volume
		#1000
		write_psg(8'b10011010);
		write_psg(8'b10111010);
		write_psg(8'b11011010);
		write_psg(8'b11111010);
		#10000
		
		// set volumes to all levels
		#100 write_psg(8'b10010000);
		#100 write_psg(8'b10110001);
		#100 write_psg(8'b11010010);
		#100 write_psg(8'b11110011);
		#100 write_psg(8'b10010100);
		#100 write_psg(8'b10110101);
		#100 write_psg(8'b11010110);
		#100 write_psg(8'b11110111);
		
		#100 write_psg(8'b10011000);
		#100 write_psg(8'b10111001);
		#100 write_psg(8'b11011010);
		#100 write_psg(8'b11111011);
		#100 write_psg(8'b10011100);
		#100 write_psg(8'b10111101);
		#100 write_psg(8'b11011110);
		#100 write_psg(8'b11111111);
		
		//all channels to max
		#100 write_psg(8'b10010000);
		#100 write_psg(8'b10110000);
		#100 write_psg(8'b11010000);
		#100 write_psg(8'b11110000);
		
		// write to lower 4 bits followed by upper bits to test prev_reg
		#1000
		write_psg(8'b10000000);
		write_psg(8'b00000011);
		#100
		write_psg(8'b10100000);
		write_psg(8'b00100110);
		#100
		write_psg(8'b11000000);
		write_psg(8'b01001000);
		
		// write to noise frequency, test reset of shift register
		#20000
		write_psg(8'b11100101);
		#80000
		write_psg(8'b11100100);
		#80000
		write_psg(8'b11100000);
		#80000
		
		// set tone channel 2 to low period to test noise channel
		write_psg(8'b11000100);
		write_psg(8'b01000000);
		write_psg(8'b11100011);
		
		#80000 $finish;
	end
  
endmodule
