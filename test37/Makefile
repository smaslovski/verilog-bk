MODULES = tb_037.v va_037.v
PROGRAM = test37
VERILOG = iverilog -Wall
WAVEFORMS = test37.lxt
GTKWAVEFILE = test37.gtkw
LOGS=

all: $(PROGRAM)

run: $(PROGRAM)
	./$(PROGRAM)

wave: $(WAVEFORMS)
	gtkwave $(GTKWAVEFILE)

clean:
	rm -f $(PROGRAM) $(LOGS) $(WAVEFORMS)

$(WAVEFORMS): $(MODULES)
	$(VERILOG) -DGTKWAVE_DUMP -o $(PROGRAM) $(MODULES)
	./$(PROGRAM) -lxt2

$(PROGRAM): $(MODULES)
	$(VERILOG) -o $(PROGRAM) $(MODULES)

.PHONY: all run wave clean
