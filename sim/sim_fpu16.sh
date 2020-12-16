./c_tools/calctestgen_half -a 32 ./obj/fop
iverilog -o ./obj/a.out -I . ./RTL/fpu16_tb.v ../RTL/CPU/EX/VPU/FALU16.v ../RTL/CPU/EX/bshifter16.v
vvp ./obj/a.out
