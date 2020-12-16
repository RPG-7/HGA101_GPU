SIMULATOR=iverilog
RTL_DIR = ./RTL/
TB_DIR= ./sim/RTL/
INCLUDE_DIR= ./RTL/CPU/
TOP_MODULE=hga4g32e_top

elaborate:
	bash ./script/elaborate.sh $(TOP_MODULE) $(RTL_DIR) $(INCLUDE_DIR)
