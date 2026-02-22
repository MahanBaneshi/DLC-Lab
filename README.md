These codes were entered for the Logic Circuit Laboratory course at Shahid Beheshti University in spring 2025.

---

- In file elevator.v, we have defined an elevator in Verilog. The elevator's function is to go up or down based on a button that is pressed from inside the elevator or from the floors. We have first defined the different states of the elevator based on the input as a state machine and then implemented the actual elevator based on the same machine. This program has a complete test bench in which all the states and exceptions are tested.
- In the file fifo.v, we have designed a memory with FIFO logic that has 128 8-bit cells. In this structure, with each clock, if the RD_EN is 1, we read 8 bits from the FIFO, and if the WR_EN is 1, we write 8 bits. This FIFO has an asynchronous signal that, if it becomes 1, the contents of all FIFO cells will be 0.
- In the file ram.v, we design a memory that requires random access reading and writing. In fact, this file is the same RAM that has 128 8-bit cells. In this structure, with each clock, an 8-bit data is read according to the address specified by the Addr pin, if the EN is 1, and if the WE_EN are 1, the pin is written.
- In last project, the system is implemented using several Verilog modules including transmitter, receiver, err_inject and a module above and is simulated in the form of a testbench. The execution steps are according to the available commands
First, it is compiled by iverilog, then executed with vvp and finally the waveforms are checked with gtkwave.
In this structure, the transmitter generates and sends the data, the error injection module allows for controlled errors in the transmission path, and the receiver analyzes and recovers. The goal of the system is to simulate a data transmission channel along with checking the correctness of the operation in the presence of errors. The final output is in the form of a wave file (V) so that decisions can be analyzed over time.

