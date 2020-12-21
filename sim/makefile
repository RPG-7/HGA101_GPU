VPATH=c_tools
OBJ=$(wildcard *.c)
calctestgen_half: calctestgen_half.o half_funcs.o test_write.o
    gcc -o $@$^
%.o:%.c
    gcc -o $@$^
	