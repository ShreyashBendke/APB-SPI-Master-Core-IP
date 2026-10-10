# APB SPI Master Core IP

A Verilog implementation of an SPI master core with an APB-style register interface. The design is divided into modules for the SPI core, baud-rate generation, data shifting, and slave selection.

## Features
- APB-style register read/write interface
- SPI clock generation with configurable baud-rate settings
- Serial data transmission and reception through MOSI and MISO
- Slave-select control and transfer-status signalling
- Separate module-level testbenches for key components

## Tools & Technologies
- Verilog HDL
- Icarus Verilog for command-line simulation (or ModelSim/QuestaSim)
- Testbenches for functional verification

## Project Structure
- `spi_core.v` – top-level SPI core and APB interface
- `spi_baud_generator.v` – SPI clock and baud-rate timing
- `spi_shifter.v` – serial data shifting and reception
- `spi_slave_select.v` – slave-select and transfer control
- `*_tb.v` – module testbenches

## How to Run
1. Install a Verilog simulator such as [Icarus Verilog](https://steveicarus.github.io/iverilog/) or use ModelSim/QuestaSim.
2. Open a terminal in this project directory.
3. Run the following command(s):

Compile the top-level core with its supporting modules and the core testbench:
```bash
iverilog -g2012 -o spi_sim spi_core.v spi_baud_generator.v spi_shifter.v spi_slave_select.v spi_core_tb.v
vvp spi_sim
```
Individual component testbenches may require compiling the corresponding module with its matching testbench.

4. Review the simulator output. To inspect waveforms, add `$dumpfile` / `$dumpvars` to the testbench and open the generated VCD file in GTKWave, or configure waveform viewing in ModelSim/QuestaSim.

## Results
- Simulation is driven by the included testbench files.
- Add screenshots of simulation output or waveforms here after running the testbench.
- Verify the results against the expected behavior for each input combination.

## Author
Shreyash Bendke – [LinkedIn](https://www.linkedin.com/in/shreyash-bendke-422b72254/)
