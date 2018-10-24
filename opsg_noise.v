/*******************************************************************//**
 *  \file opsg_noise.v
 *  \author René Richard
 *  \brief This module implements
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

module opsg_noise #(
	parameter TAPPED_BIT0 = 0,
	parameter TAPPED_BIT1 = 3,
	parameter SHIFT_WIDTH = 15,
	parameter TONE_WIDTH = 10
)(
	input clk,
	input reload,
	input fb,
	input [1:0] nf,
	input [TONE_WIDTH-1:0] freq,
	output reg [TONE_WIDTH-1:0] count,
	output reg [SHIFT_WIDTH-1:0] shiftReg,
	output reg noiseBit
);
  
	// init counter to 1, nbit to 1;
	reg [TONE_WIDTH-1:0] counter = 1;
	reg [SHIFT_WIDTH-1:0] shift = { 1'b1, { SHIFT_WIDTH-1 {1'b0} } };
	reg nbit = 1'b1;
	reg feedback;
  
	always @(posedge clk) begin
		if ( counter == 1 ) begin
			case(nf)
				2'b00 : counter <= 16;
				2'b01 : counter <= 32;
				2'b10 : counter <= 64;
				// noiseFreq to be connected to tone channel 3
				default : counter <= freq;
			endcase
			nbit <= !nbit;
		end else begin
			counter <= counter - 1;
		end
		count = counter;
	end
  
	// LFSR needs to reset on each freq write to the noise channel
	// reset value is top bit getting set while all others are back to zero. 
	always @(posedge nbit, negedge reload) begin
		if (!reload) begin
			shift <= { 1'b1, { SHIFT_WIDTH-1 {1'b0} } };
		end else begin
			if (fb) begin
				shift <= { (shift[TAPPED_BIT0] ^ shift[TAPPED_BIT1]), shift[SHIFT_WIDTH-1:1] };
			end else begin
				shift <= { shift[0], shift[SHIFT_WIDTH-1:1] };
			end
			shiftReg = shift;
			noiseBit = shift[0];
		end
	end
  
endmodule
