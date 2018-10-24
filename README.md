# OPSG
A verilog implementation of variants of the SN76489 programmable sound generator. It aims to provide a parameterized module which can closely replicate the behaviour of all the variants by providing
options for things like: tapped bits, shift register size, etc...

## Copyright and Disclaimer
Copyright: René Richard 2018

OPSG is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

OPSG is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with OPSG.  If not, see <http://www.gnu.org/licenses/>.

# Simulation
Run the test benches with iverilog using the following commands:
```
iverilog [testbench.v] [design.v] -o wave.out
```
Then, use vvp to convert the 'test.out' file into a format .bcd which gtkwave can view:
```
vvp wave.out
```
Finally, open the waveform using gtkwave:
```
gtkwave dump.bcd
```
