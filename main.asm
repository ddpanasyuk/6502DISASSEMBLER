START *= $0400

START_LOOP
        LDX TEST_COUNTER
        CPX #0
        BEQ HERE
        LDA TEST_ADDRESS
        TAY
        PHA
        LDX #1
        LDA TEST_ADDRESS,X
        TAX
        PHA
        JSR SET_UP_LINE
        PLA
        TAX
        PLA
        TAY
        JSR MAKE_OP_CODE_STRING
        CLC
        ADC TEST_ADDRESS
        STA TEST_ADDRESS
        LDX #1
        LDA #0
        ADC TEST_ADDRESS,X
        STA TEST_ADDRESS,X
        DEC TEST_COUNTER
        JMP START_LOOP
HANG
        JMP HANG
TEST_COUNTER
        byte 8
TEST_ADDRESS
        byte <TEST_INSTRUCTIONS
        byte >TEST_INSTRUCTIONS
TEST_INSTRUCTIONS
        DEC $FF,X
        ADC $FF,Y                
        CMP #0
        LDA $1234
        STA $4321,Y
        STY $12,X
        LDY $4321,X
        JMP $FFFF

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
        AND #$1C
        PHA ; save for fetching addressing offset register later

        ASL ; table is made up of 8 byte segments for each addressing mode type
        STA MAKE_OP_CODE_PTR
        LDA OP_CODE_FIRST_BYTE
        AND #$3
        ASL ; to get address offset in 8 byte segment by multiples of 2
        CLC
        ADC MAKE_OP_CODE_PTR ; put the two offsets together
        TAX
        LDA OPCODE_ADDRESSING_TABLE_UNIV,X
        LDY #$1
        STA MAKE_OP_CODE_ADDRESSING_JMP,Y
        INX
        INY
        LDA OPCODE_ADDRESSING_TABLE_UNIV,X
        STA MAKE_OP_CODE_ADDRESSING_JMP,Y ; code for overwriting jump with address from table
MAKE_OP_CODE_ADDRESSING_JMP
        JMP $FFFF ; $FFFF gets replaced with above code on run time

MAKE_OP_CODE_STRING_END
        PLA
        LDA #1
        RTS
MAKE_OP_CODE_STRING_DUAL_BYTE_END
        LDA #2
        RTS
MAKE_OP_CODE_STRING_TRIPLE_BYTE_END
        LDA #3
        RTS

ADDRESSING_ZERO_PAGE_X
ADDRESSING_ZERO_PAGE_Y
ADDRESSING_ZERO_PAGE ; all same, only difference being register offset
        JSR PRINT_SYM_SPACE
        LDA OP_CODE_SECOND_BYTE
        JSR PRINT_HEX_BYTE
        LDA #' '
        JSR $FFD2
        PLA
        JSR GET_ADDRESSING_MODE_CHAR
        CMP #0
        BEQ MAKE_OP_CODE_STRING_DUAL_BYTE_END
        LDX #$B4 ; LDY                  ; LDY and STY are the only two zero page instructions for which the 
        BEQ ADDRESSING_ZERO_PAGE_X_CHAR ; 3 bits corresponding to addressing "$<ZERO PAGE>,Y" are flipped
        CPX #$94 ; STY                  ; internally to represent "$<ZERO PAGE>,X"
        BEQ ADDRESSING_ZERO_PAGE_X_CHAR
        JMP ADDRESSING_ZERO_PAGE_Y_CHAR
ADDRESSING_ZERO_PAGE_X_CHAR
        LDA #'x'
ADDRESSING_ZERO_PAGE_Y_CHAR        
        JSR $FFD2
        JMP MAKE_OP_CODE_STRING_DUAL_BYTE_END

ADDRESSING_IMM ; immediate addressing
        LDA #' '
        JSR $FFD2
        LDA #'#'
        JSR $FFD2
        LDA #'$'
        JSR $FFD2
        LDA OP_CODE_SECOND_BYTE
        JSR PRINT_HEX_BYTE
        PLA
        JMP MAKE_OP_CODE_STRING_DUAL_BYTE_END

ADDRESSING_ABS_X
ADDRESSING_ABS_Y
ADDRESSING_ABS ; all same, only difference being register offset
        JSR PRINT_SYM_SPACE
        LDA OP_CODE_THIRD_BYTE
        JSR PRINT_HEX_BYTE
        LDA OP_CODE_SECOND_BYTE
        JSR PRINT_HEX_BYTE
        LDA #' '
        JSR $FFD2
        PLA
        JSR GET_ADDRESSING_MODE_CHAR
        CMP #0
        BEQ MAKE_OP_CODE_STRING_TRIPLE_BYTE_END
        LDX OP_CODE_FIRST_BYTE
        CPX #$BC ; LDY                  ; as explained before, LDY's 3 addressing bits for "$<ABS>,Y"
        BNE ADDRESSING_ABS_Y_CHAR       ; are flipped internally for "$<ABS>,X". STY does not have 
ADDRESSING_ABS_X_CHAR                   ; the option for addressing mode "$<ABS,Y"
        LDA #'x'
ADDRESSING_ABS_Y_CHAR
        JSR $FFD2
        JMP MAKE_OP_CODE_STRING_TRIPLE_BYTE_END

;function that gets addressing mode character, returns it in A
;3 bit addressing should be passed in A
GET_ADDRESSING_MODE_CHAR
        STA GET_ADDRESSING_MODE_PTR
        LDA OP_CODE_FIRST_BYTE
        AND #$3
        CLC
        ADC GET_ADDRESSING_MODE_PTR
        TAX
        LDA OPCODE_ADDRESSING_TYPE,X
        RTS
GET_ADDRESSING_MODE_PTR
        byte 0

OP_CODE_FIRST_BYTE
        byte 0
OP_CODE_SECOND_BYTE
        byte 0
OP_CODE_THIRD_BYTE
        byte 0
MAKE_OP_CODE_PTR
        byte 0,0

PRINT_SYM_SPACE
        LDA #' '
        JSR $FFD2
        LDA #'$'
        JSR $FFD2
        RTS     

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

OPCODE_ADDRESSING_TABLE_UNIV
        ; 000
        byte <ADDRESSING_IMM
        byte >ADDRESSING_IMM            ; 00
        byte <ADDRESSING_ZERO_PAGE_X
        byte >ADDRESSING_ZERO_PAGE_X    ; 01
        byte <ADDRESSING_IMM
        byte >ADDRESSING_IMM            ; 10
        byte <MAKE_OP_CODE_STRING_END
        byte >MAKE_OP_CODE_STRING_END

        ; 001
        byte <ADDRESSING_ZERO_PAGE
        byte >ADDRESSING_ZERO_PAGE      ; 00
        byte <ADDRESSING_ZERO_PAGE
        byte >ADDRESSING_ZERO_PAGE      ; 01
        byte <ADDRESSING_ZERO_PAGE
        byte >ADDRESSING_ZERO_PAGE      ; 10
        byte <MAKE_OP_CODE_STRING_END
        byte >MAKE_OP_CODE_STRING_END

        ; 010
        byte <MAKE_OP_CODE_STRING_END
        byte >MAKE_OP_CODE_STRING_END   ; 00
        byte <ADDRESSING_IMM
        byte >ADDRESSING_IMM            ; 01
        byte <MAKE_OP_CODE_STRING_END
        byte >MAKE_OP_CODE_STRING_END   ; 10
        byte <MAKE_OP_CODE_STRING_END
        byte >MAKE_OP_CODE_STRING_END

        ; 011
        byte <ADDRESSING_ABS
        byte >ADDRESSING_ABS            ; 00
        byte <ADDRESSING_ABS
        byte >ADDRESSING_ABS            ; 01
        byte <ADDRESSING_ABS
        byte >ADDRESSING_ABS            ; 10
        byte <MAKE_OP_CODE_STRING_END
        byte >MAKE_OP_CODE_STRING_END

        ; 100
        byte <MAKE_OP_CODE_STRING_END
        byte >MAKE_OP_CODE_STRING_END   ; 00
        byte <ADDRESSING_ZERO_PAGE_Y
        byte >ADDRESSING_ZERO_PAGE_Y    ; 01
        byte <MAKE_OP_CODE_STRING_END
        byte >MAKE_OP_CODE_STRING_END   ; 10
        byte <MAKE_OP_CODE_STRING_END
        byte >MAKE_OP_CODE_STRING_END

        ; 101
        byte <ADDRESSING_ZERO_PAGE_X
        byte >ADDRESSING_ZERO_PAGE_X    ; 00
        byte <ADDRESSING_ZERO_PAGE_X
        byte >ADDRESSING_ZERO_PAGE_X    ; 01
        byte <ADDRESSING_ZERO_PAGE_X
        byte >ADDRESSING_ZERO_PAGE_X    ; 10
        byte <MAKE_OP_CODE_STRING_END
        byte >MAKE_OP_CODE_STRING_END

        ; 110
        byte <MAKE_OP_CODE_STRING_END
        byte >MAKE_OP_CODE_STRING_END   ; 00
        byte <ADDRESSING_ABS_Y
        byte >ADDRESSING_ABS_Y          ; 01
        byte <MAKE_OP_CODE_STRING_END
        byte >MAKE_OP_CODE_STRING_END   ; 10
        byte <MAKE_OP_CODE_STRING_END
        byte >MAKE_OP_CODE_STRING_END

        ; 111
        byte <ADDRESSING_ABS_X
        byte >ADDRESSING_ABS_X          ; 00
        byte <ADDRESSING_ABS_X
        byte >ADDRESSING_ABS_X          ; 01
        byte <ADDRESSING_ABS_X
        byte >ADDRESSING_ABS_X            ; 10
        byte <MAKE_OP_CODE_STRING_END
        byte >MAKE_OP_CODE_STRING_END

OPCODE_ADDRESSING_TYPE
        ; 000
        byte 0  ; 00
        text "x"; 01
        byte 0  ; 10
        byte 0

        ; 001
        byte 0  ; 00
        byte 0  ; 01
        byte 0  ; 10
        byte 0

        ; 010
        byte 0  ; 00
        byte 0  ; 01
        byte 0  ; 10
        byte 0

        ; 011
        byte 0  ; 00
        byte 0  ; 01
        byte 0  ; 10
        byte 0

        ; 100
        byte 0  ; 00
        text "y"; 01
        byte 0  ; 10
        byte 0

        ; 101
        text "x"; 00
        text "x"; 01
        text "x"; 10
        byte 0
        
        ; 110
        byte 0  ; 00
        text "y"; 01
        byte 0  ; 10
        byte 0

        ; 111
        text "x"; 00
        text "x"; 01
        text "x"; 10
        byte 0

OPCODE_TYPE_TABLE
        byte <OPCODE_TABLE_00
        byte >OPCODE_TABLE_00
        byte <OPCODE_TABLE_01
        byte >OPCODE_TABLE_01
        byte <OPCODE_TABLE_10
        byte >OPCODE_TABLE_10

OPCODE_TABLE_00
        byte 0,0,0,0
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
        text "ror"
        byte 0
        text "stx"
        byte 0
        text "ldx"
        byte 0
        text "dec"
        byte 0
        text "inc"
        byte 0

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