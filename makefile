SIMULATOR=iverilog
SYNTHESIZER=qflow synthesize
RTL_DIR = ./RTL/
TB_DIR= ./sim/RTL/
OBJ_DIR=./sim/obj
REPORT_DIR=./temp
INCLUDE_DIR= ./RTL/CPU/
TOP_MODULE=hga4g32e_top
SHOW_WAVEFORM=TRUE

elaborate:
	bash ./script/elaborate.sh $(TOP_MODULE) $(RTL_DIR) $(INCLUDE_DIR) $(REPORT_DIR)/hierarchy.rpt
lint:$(REPORT_DIR)/hierarchy.rpt
	bash ./script/lint.sh $(INCLUDE_DIR)
autosim:
	bash ./script/autosim.sh $(TB_MODULE) $(INCLUDE_DIR)


clean:
	rm $(REPORT_DIR)/*
	rm $(OBJ_DIR)/*