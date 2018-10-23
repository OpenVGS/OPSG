/*******************************************************************//**
 *  \file opsg_tone.v
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
 
module opsg_tone #(
  parameter TONE_WIDTH = 10
)(
  input clk,
  input [TONE_WIDTH-1:0] freq,
  output reg [TONE_WIDTH-1:0] count,
  output reg toneBit
);

  // init counter to 1, tbit to 1;
  reg [TONE_WIDTH-1:0] counter = 1;
  reg tbit = 1'b1;
  
  always @(posedge clk) begin
 
    counter <= counter - 1;
    
    if ( counter == 0 ) begin
      // output of tone channel forced to 1 if freq == 0 (used for sample playback)
      if ( freq == 0 ) begin
      	tbit <= 1'b1;
      end else begin
 		tbit <= !tbit;      
      end
      counter <= freq;
    end
    
    count = counter;
    toneBit = tbit;
    
  end
  
endmodule
