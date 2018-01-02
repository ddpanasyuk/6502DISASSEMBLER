START *= $0400
        ;LDA #>MAKE_OP_CODE_STRING
        ;PHA
        ;LDA #<MAKE_OP_CODE_STRING
        ;PHA
        ;JSR MAKE_OP_CODE_STRING
        ;JSR PRINT_HEX_BYTE
        LDX #>TEST_INSTRUCTION
        LDY #<TEST_INSTRUCTION
        JSR SET_UP_LINE

        LDX #>TEST_INSTRUCTION                        
        LDY #<TEST_INSTRUCTION
        JSR MAKE_OP_CODE_STRING

        LDX #>TEST_INSTRUCTION_TWO
        LDY #<TEST_INSTRUCTION_TWO
        JSR SET_UP_LINE

        LDX #>TEST_INSTRUCTION_TWO                     
        LDY #<TEST_INSTRUCTION_TWO
        JSR MAKE_OP_CODE_STRING

        LDX #>TEST_INSTRUCTION_THREE
        LDY #<TEST_INSTRUCTION_THREE
        JSR SET_UP_LINE

        LDX #>TEST_INSTRUCTION_THREE                     
        LDY #<TEST_INSTRUCTION_THREE
        JSR MAKE_OP_CODE_STRING
HERE
        JMP HERE

TEST_INSTRUCTION
        LDA $1234,X
TEST_INSTRUCTION_TWO
        AND #$FF
TEST_INSTRUCTION_THREE
        STA $AB,Y


;subroutine for making opcode string
;address for subroutine should be passed with addr $XXYY in X and Y
;string to print afterwards can be found at address MAKE_OP_CODE_STRING_TXT
;returns number of bytes op-code used in register A
MAKE_OP_CODE_STRING
        TYA
        LDY #1
        STA MAKE_OP_CODE_STRING_OP_TO_LOAD,Y
        TXA
        INY
        STA MAKE_OP_CODE_STRING_OP_TO_LOAD,Y ; get address to load opcode from

MAKE_OP_CODE_STRING_OP_TO_LOAD
        LDA $FFFF ; this gets over written with correct address
        STA OP_CODE_FIRST_BYTE
        
        CLC
        DEY
        LDA MAKE_OP_CODE_STRING_OP_TO_LOAD,Y
        ADC #1
        STA MAKE_OP_CODE_STRING_OP_TO_LOAD_SECOND,Y
        INY
        LDA MAKE_OP_CODE_STRING_OP_TO_LOAD,Y
        ADC #0
        STA MAKE_OP_CODE_STRING_OP_TO_LOAD_SECOND,Y

MAKE_OP_CODE_STRING_OP_TO_LOAD_SECOND
        LDA $FFFF
        STA OP_CODE_SECOND_BYTE

        CLC
        LDY #1
        LDA MAKE_OP_CODE_STRING_OP_TO_LOAD,Y
        ADC #2
        STA MAKE_OP_CODE_STRING_OP_TO_LOAD_THIRD,Y
        INY
        LDA MAKE_OP_CODE_STRING_OP_TO_LOAD,Y
        ADC #0
        STA MAKE_OP_CODE_STRING_OP_TO_LOAD_THIRD,Y

MAKE_OP_CODE_STRING_OP_TO_LOAD_THIRD
        LDA $FFFF
        STA OP_CODE_THIRD_BYTE ; loaded 3 bytes just in case

        LDA OP_CODE_FIRST_BYTE
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
        LDA OP_CODE_FIRST_BYTE
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
        
        LDY #1
        LDX MAKE_OP_CODE_PTR,Y
        LDY MAKE_OP_CODE_PTR
        JSR PRINT_STRING ; push opcode name string and print it
        LDA OP_CODE_FIRST_BYTE
        AND #$3
        CMP #$0
        BEQ MAKE_OP_CODE_ADDRESSING_00
        CMP #$1
        BEQ MAKE_OP_CODE_ADDRESSING_01
        CMP #$2
        BEQ MAKE_OP_CODE_ADDRESSING_10
        RTS
MAKE_OP_CODE_ADDRESSING_01
        LDA OP_CODE_FIRST_BYTE
        LSR
        LSR
        AND #$7
        PHA
        CMP #$0
        BEQ MAKE_OP_CODE_ADDRESSING_ZERO_PAGE_X
        CMP #$1
        BEQ MAKE_OP_CODE_ADDRESSING_ZERO_PAGE
        CMP #$2
        BEQ MAKE_OP_CODE_ADDRESSING_IMM
        CMP #$3
        BEQ MAKE_OP_CODE_ADDRESSING_ABS
        CMP #$4
        BEQ MAKE_OP_CODE_ADDRESSING_ZERO_PAGE_Y
        CMP #$5
        BEQ MAKE_OP_CODE_ADDRESSING_ZERO_PAGE_X
        CMP #$6
        BEQ MAKE_OP_CODE_ADDRESSING_ABS_Y
        CMP #$7
        BEQ MAKE_OP_CODE_ADDRESSING_ABS_X
        LDA #1
        PLA
        LDA #1
        RTS
MAKE_OP_CODE_ADDRESSING_00
        RTS
MAKE_OP_CODE_ADDRESSING_10
        RTS
MAKE_OP_CODE_STRING_END
        LDA #1
MAKE_OP_CODE_STRING_DUAL_BYTE_END
        LDA #2
        RTS

MAKE_OP_CODE_ADDRESSING_ZERO_PAGE_X
MAKE_OP_CODE_ADDRESSING_ZERO_PAGE_Y
MAKE_OP_CODE_ADDRESSING_ZERO_PAGE ; all same, only difference being register offset
        LDA #' '
        JSR $FFD2
        LDA #'$'
        JSR $FFD2
        LDA OP_CODE_SECOND_BYTE
        JSR PRINT_HEX_BYTE
        LDA #' '
        JSR $FFD2
        PLA
        TAX
        LDA OPCODE_ADDRESSING_TYPE_01,X
        CMP #0
        BEQ MAKE_OP_CODE_STRING_DUAL_BYTE_END
        JSR $FFD2
        PLA
        LDA #2
        RTS
MAKE_OP_CODE_ADDRESSING_IMM
        LDA #' '
        JSR $FFD2
        LDA #'#'
        JSR $FFD2
        LDA #'$'
        JSR $FFD2
        LDA OP_CODE_SECOND_BYTE
        JSR PRINT_HEX_BYTE
        PLA
        LDA #2
        RTS
MAKE_OP_CODE_ADDRESSING_ABS
MAKE_OP_CODE_ADDRESSING_ABS_X
MAKE_OP_CODE_ADDRESSING_ABS_Y ; these are also all the same, with X/Y/' ' differing
        LDA #' '
        JSR $FFD2
        LDA #'$'
        JSR $FFD2
        LDA OP_CODE_THIRD_BYTE
        JSR PRINT_HEX_BYTE
        LDA OP_CODE_SECOND_BYTE
        JSR PRINT_HEX_BYTE
        LDA #' '
        JSR $FFD2
        PLA
        TAX
        LDA OPCODE_ADDRESSING_TYPE_01,X
        CMP #0
        BEQ MAKE_OP_CODE_STRING_END
        JSR $FFD2
        LDA #3
        RTS

OP_CODE_FIRST_BYTE
        byte 0
OP_CODE_SECOND_BYTE
        byte 0
OP_CODE_THIRD_BYTE
        byte 0
MAKE_OP_CODE_PTR
        byte 0,0

;function for printing string to output
;pass address of string $XXYY, reg X and Y
PRINT_STRING
        TYA
        LDY #1
        STA PRINT_STRING_CHAR_TO_LOAD,Y
        TXA
        INY
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

;function for printing hex byte
;pass hex byte to print in register A
PRINT_HEX_BYTE
        PHA
        LSR
        LSR
        LSR
        LSR
        TAX
        LDA HEX_PRINT_TABLE,X
        JSR $FFD2
        PLA
        AND #$F
        TAX
        LDA HEX_PRINT_TABLE,X
        JSR $FFD2
        RTS

;function for setting up line
;pass address of line in $XXYY
SET_UP_LINE
        LDA #13
        JSR $FFD2
        LDA #'$'
        TXA
        JSR PRINT_HEX_BYTE
        TYA
        JSR PRINT_HEX_BYTE
        LDA #':'
        JSR $FFD2
        RTS

OPCODE_ADDRESSING_TYPE_01
        text "x"
        byte 0
        byte 0
        byte 0
        text "x"
        text "x"
        text "y"
        text "x"

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

HEX_PRINT_TABLE
        byte '0'
        byte '1'
        byte '2'
        byte '3'
        byte '4'
        byte '5'
        byte '6'
        byte '7'
        byte '8'
        byte '9'
        text "a"
        text "b"
        text "c"
        text "d"
        text "e"
        text "f"