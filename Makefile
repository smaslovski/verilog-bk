MODULES = ay_cmd_test.v bk0011m.v cmd_ay_orig.v cmd_ay_stas1.v cmd_ay_stas2.v cpu_emulator.v
PROGRAM = ay_cmd_test
VERILOG = iverilog -Wall
LOGS = cpu_bus.log
WAVEFORMS = cpu_emulator.vcd

all: $(PROGRAM)

run: $(PROGRAM)
	./$(PROGRAM)

wave: $(WAVEFORMS)
	gtkwave $(WAVEFORMS)

clean:
	rm -f $(PROGRAM) $(LOGS) $(WAVEFORMS)

$(WAVEFORMS): $(MODULES)
	$(VERILOG) -DGTKWAVE_DUMP -o $(PROGRAM) $(MODULES)
	./$(PROGRAM)

$(PROGRAM): $(MODULES)
	$(VERILOG) -o $(PROGRAM) $(MODULES)

.PHONY: all run wave clean
