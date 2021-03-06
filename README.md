# 6502DISASSEMBLER

6502 disassembler written in 6502 ASM for a VIC-20, made for the purpose of futher learning VIC-20 computing. End goal is implementation of memory dump disassembly on programs currently loaded in VIC-20 RAM for debugging on physical VIC-20 hardware.

## 1/7/2018 CHANGELOG

-Implemented basic command-line for address entry. Location in memory is input as two hexadecimal bytes, and confirmed with the enter key

-Next instruction can be loaded and disassembled with the e(x)ecute key, and the user can return to the VIC-20 BASIC at any time with the (q)uit key

-Program must now be loaded into memory off of a floppy disk or cassette tape. The program is listed on the disk as "DISASM", and can be loaded with 'LOAD "DISASM",<drive number>,1'. To run the program afterwards, jump to the starting address it was loaded to, 0x0402

As of now, there are two bugs remaining that must be ironed out that I'm aware of at the moment. The first is the incorrect dissassembly of the indirect indexed addressing mode. The instruction and operands are disassembled and listed correctly, but they are shown as being used in indexed addressing mode. The second is certain one byte instructions being disassembled incorrectly and listed as the wrong instruction. These will be fixed in the next few days. 

![Screenshot](images/6502disasm_start.png)

## 1/8/2018 CHANGELOG

-All documented instructions and addressing modes supported in disassembly.

-Added a table of every single possible instruction on the 6502 processor at the end of the program for testing purposes. This will be removed when the disassembly part of the program's testing isn't needed anymore.

-Minor bugs may still exist, and I will focus on finding and removing them as I clean up the code to make it more efficient

![Screenshot](images/6502disasm_addressing_modes.png)

## 1/9/2018

-Added hex and ASCII dump features. Features currently mapped to (h)ex dump key and (t)ext dump key. Bytes that do not meet the criteria for printable ASCII characters are represented with a triangle in the top right of the character space. 

![Screenshot](images/6502disasm_hex_ascii_dump.png)


-Added byte insert feature, activated with (w)rite key. Bytes are read one at a time from the user and written to the requested address. Next address can be accessed with e(x)ecute key without manually entering it. 

![Screenshot](images/6502disasm_byte_insert_1.png)

In this first image, the bytes for LDA #'&', JSR $FFD2, JSR $FFC2, BRK are manually entered into the VIC-20's RAM at address $A000

![Screenshot](images/6502disasm_byte_insert_2.png)

We can confirm that we did in fact write the correct bytes by running a disassembly at this address. 

![Screenshot](images/6502disasm_byte_insert_3.png)

Then, if we exit the program and jump to $A000 from BASIC (decimal address 40960), we can see that these short few instructions print an ampersand and then wait for the user to press any key before exiting to BASIC. 
