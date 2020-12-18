SIMULATOR=iverilog
SYNTHESIZER=qflow synthesize
RTL_DIR = ./RTL
TB_DIR=./sim
OBJ_DIR=./sim/obj
REPORT_DIR=./temp
INCLUDE_DIR=./RTL/CPU
SIMU_INCDIR=./sim
TOP_MODULE=hga4g32e_top
TB_MODULE=hga4g32e_tb
SHOW_WAVEFORM=TRUE

help:
	@echo "\033[33melaborate\033[0m to examine given TOP_MODULE and generate HIERARCHY_FILE"
	@echo "\033[33mlint\033[0m to check syntax errors of RTLs listed in HIERARCHY_FILE"
	@echo "\033[33mautosim\033[0m to automaically simulate testebench of the given TB_MODULE"
	@echo "\033[33mclean\033[0m to clean all objects and temp files"
elaborate:
	bash ./script/elaborate.sh $(TOP_MODULE) $(RTL_DIR) $(INCLUDE_DIR) $(REPORT_DIR)/hierarchy.rpt
lint:$(REPORT_DIR)/hierarchy.rpt
	bash ./script/lint.sh $(INCLUDE_DIR)
autosim:
	
	bash ./script/autosim.sh $(TB_MODULE) $(TB_DIR) $(SIMU_INCDIR) $(REPORT_DIR)/tb_hierarchy.rpt $(RTL_DIR) $(OBJ_DIR)
	gtkwave $(OBJ_DIR)/$(TB_MODULE).vcd

clean:
	rm $(REPORT_DIR)/*
	rm $(OBJ_DIR)/*

.PHONY: make help