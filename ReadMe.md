# 32-bit RISC-V processor design

Implements RV32I instruction set except for interrupts and some CSRs.

Warning: CSR and system instructions weren't really tested so may not work properly

Default software runs a 2.5D maze game through the VGA port, using SW2 and SW3 to turn and move.

Implemented CSRs:
- cycle/cycleh -- doesn't count
- time/timeh -- doesn't count
- instret/instreth -- doesn't count
- mvendorid
- marchid
- mimpid
- misa -- ignores writes
- mstatus -- all but mpie and mie are hardwired
- mie -- all but meie, mtie, and msie are hardwired
- mtvec -- hardwired to 0x10040
- mscratch
- mepc
- mcause
- mip -- ignores writes

- used FPGA: ChinaQMTECH's QM_XC6SLX16_DDR3 board with the vga output board. [Docs](https://raw.githubusercontent.com/ChinaQMTECH/QM_XC6SLX16_DDR3/master/QM_XC6SLX16_DDR3_V02.zip) [archived on archive.org](http://web.archive.org/web/20180321000346/https://raw.githubusercontent.com/ChinaQMTECH/QM_XC6SLX16_DDR3/master/QM_XC6SLX16_DDR3_V02.zip)
- used programmer: Digilent's Hs2 JTAG programmer

## Building (On Ubuntu 16.04)
Requires Xilinx's ISE v. 14.7 to be installed in /opt/Xilinx (just leave the default installation directory)

    sudo apt-get install git g++ autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev
    sudo mkdir /opt/riscv
    sudo chown $USER /opt/riscv # so you don't need root when building; you can change back after building riscv-gnu-toolchain
    git clone --recursive https://github.com/riscv/riscv-gnu-toolchain.git
    export PATH=/opt/riscv/bin:"$PATH"
    cd riscv-gnu-toolchain
    ./configure --prefix=/opt/riscv --with-arch=rv32i
    make
    sudo chown -R root:root /opt/riscv # change owner back to root as the compiler is finished installing
    cd ..
    git clone https://github.com/programmerjake/rv32.git
    cd rv32/software
    make
    cd ..
    # at this point the built bitstream is in output.bit
    djtgcfg prog -d JtagHS2 -i 0 -f output.bit # program the FPGA

## Simulating using Icarus Verilog
Doesn't require Xilinx's ISE or Digilent's programmer

    sudo apt-get install git g++ autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev
    sudo mkdir /opt/riscv
    sudo chown $USER /opt/riscv # so you don't need root when building; you can change back after building riscv-gnu-toolchain
    git clone --recursive https://github.com/riscv/riscv-gnu-toolchain.git
    export PATH=/opt/riscv/bin:"$PATH"
    cd riscv-gnu-toolchain
    ./configure --prefix=/opt/riscv --with-arch=rv32i
    make
    sudo chown -R root:root /opt/riscv # change owner back to root as the compiler is finished installing
    cd ..
    git clone https://github.com/programmerjake/rv32.git
    cd rv32/software
    make ram0_byte0.hex
    cd ..
    iveriog -o rv32 -Wall *.v
    vvp -n rv32 # doesn't terminate, press Ctrl+C when it's generated enough output

The output is in `dump.vcd`, which can be viewed with GTKWave.

## Building the hardware (only required if verilog source is modified)

Requires having built the software at least once to generate the ram initialization files.

Run `(. /opt/Xilinx/14.7/ISE_DS/settings64.sh; ise&)` in a terminal.  
Switch the view to Implementation  
Select main.v  
Run "Generate Programming File"  
Open a terminal and run:

    export PATH=/opt/riscv/bin:"$PATH"
    cd rv32/software
    make
    cd ..
    # at this point the built bitstream is in output.bit
    djtgcfg prog -d JtagHS2 -i 0 -f output.bit # program the FPGA

