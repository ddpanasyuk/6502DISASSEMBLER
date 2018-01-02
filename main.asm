START *= $1600
        ;LDA #>MAKE_OP_CODE_STRING
        ;PHA
        ;LDA #<MAKE_OP_CODE_STRING
        ;PHA
        ;JSR MAKE_OP_CODE_STRING
        LDA #<MAKE_OP_CODE_STRING_OP_TO_LOAD
        PHA
        LDA #>MAKE_OP_CODE_STRING_OP_TO_LOAD
        PHA
        JSR MAKE_OP_CODE_STRING
HERE
        JMP HERE
STR_HELLO_WORLD
        text "hello world!"
        byte 0

;subroutine for making opcode string
;address for subroutine should be passed
;string to print afterwards can be found at address MAKE_OP_CODE_STRING_TXT
MAKE_OP_CODE_STRING
        TSX
        INX
        INX
        INX
        LDA $100,X
        LDY #2
        STA MAKE_OP_CODE_STRING_OP_TO_LOAD,Y
        INX
        DEY
        LDA $100,X
        STA MAKE_OP_CODE_STRING_OP_TO_LOAD,Y ; get address to load opcode from
MAKE_OP_CODE_STRING_OP_TO_LOAD
        LDA $FFFF ; this gets over written with correct address
        PHA ; save opcode for future work on it
        AND #$3 ; gives us address in opcode_type_table to load opcode from
        ASL ; shift to the left to double for op code type table
        TAX ; transfer A to X
        LDY #1
        LDA OPCODE_TYPE_TABLE,X ; get lower byte of opcode name table
        STA MAKE_OP_CODE_STRING_INSTRUCTION_LOWER,Y ; store lower byte into pointer
        INX 
        LDA OPCODE_TYPE_TABLE,X ; get upper byte of opcode name table
        STA MAKE_OP_CODE_STRING_INSTRUCTION_UPPER,Y ; store upper byte into pointer
MAKE_OP_CODE_STRING_INSTRUCTION
        PLA ; restore opcode byte 
        LSR 
        LSR
        LSR
        CLC ; 3 shifts and carry bit clear to find opcode name in table
        TAY
        LDX #1
MAKE_OP_CODE_STRING_INSTRUCTION_LOWER
        LDA #0 ; this gets over written with correct address byte
        STA MAKE_OP_CODE_PTR 
MAKE_OP_CODE_STRING_INSTRUCTION_UPPER
        LDA #0 ; this gets over written with correct address byte
        STA MAKE_OP_CODE_PTR,X
        TYA
        AND #$1C ; get rid of any bits we don't need
        ADC MAKE_OP_CODE_PTR
        STA MAKE_OP_CODE_PTR ; add and store offset into pointer
        LDA #0
        ADC MAKE_OP_CODE_PTR,X ; carry any possible bit
        STA MAKE_OP_CODE_PTR,X ; store upper byte
        LDA MAKE_OP_CODE_PTR
        PHA
        LDA MAKE_OP_CODE_PTR,X
        PHA
        JSR PRINT_STRING ; push opcode name string and print it
        PLA
        PLA
        JMP MAKE_OP_CODE_STRING_END
MAKE_OP_CODE_STRING_END
        RTS
MAKE_OP_CODE_STRING_TXT
        byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
MAKE_OP_CODE_PTR
        byte 0,0

;function for printing string to output
;pass address of string in stack
PRINT_STRING
        TSX
        INX
        INX
        INX
        LDA $100,X
        LDY #2
        STA PRINT_STRING_CHAR_TO_LOAD,Y
        INX
        DEY
        LDA $100,X
        STA PRINT_STRING_CHAR_TO_LOAD,Y ; get address to load opcode from
        LDX #0
        STX PRINT_STRING_PTR
PRINT_STRING_LOOP
        LDX PRINT_STRING_PTR
PRINT_STRING_CHAR_TO_LOAD
        LDA $FFFF,X
        CMP #0
        BEQ PRINT_STRING_END
        JSR $FFD2
        INC PRINT_STRING_PTR
        JMP PRINT_STRING_LOOP
PRINT_STRING_END
        RTS
PRINT_STRING_PTR
        byte 0

OPCODE_TYPE_TABLE
        byte <OPCODE_TABLE_00
        byte >OPCODE_TABLE_00
        byte <OPCODE_TABLE_01
        byte >OPCODE_TABLE_01
        byte <OPCODE_TABLE_10
        byte >OPCODE_TABLE_10

OPCODE_TABLE_00
        text "bit"
        byte 0
        text "jmp"
        byte 0
        text "jmp"
        byte 0
        text "sty"
        byte 0
        text "ldy"
        byte 0
        text "cpy"
        byte 0
        text "cpx"
        byte 0
        byte 0,0,0,0
OPCODE_TABLE_01
        text "ora"
        byte 0
        text "and"
        byte 0
        text "eor"
        byte 0
        text "adc"
        byte 0
        text "sta"
        byte 0
        text "lda"
        byte 0
        text "cmp"
        byte 0
        text "sbc"
        byte 0
OPCODE_TABLE_10
        text "asl"
        byte 0
        text "rol"
        byte 0
        text "lsr"
        byte 0
        text "stx"
        byte 0
        text "ldx"
        byte 0
        text "dec"
        byte 0
        text "inc"
        byte 0
        byte 0,0,0,0

