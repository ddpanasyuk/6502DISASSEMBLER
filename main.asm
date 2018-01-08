START *= $0400

START_LOOP
        LDA #13
        JSR $FFD2
        LDA #'$'
        JSR $FFD2
        LDA #0
        STA STR_ADDRESS_TO_LOAD_COUNTER        
LOAD_CHARS_LOOP
        LDY STR_ADDRESS_TO_LOAD_COUNTER
        JSR $FFCF
        CMP #13
        STA STR_ADDRESS_TO_LOAD_COUNTER,Y
        INY
        BEQ START_DISASSEMBLE
        JMP LOAD_CHARS_LOOP
START_DISASSEMBLE
        

        ;LDX STR_ADDRESS_TO_LOAD
        ;LDY #1
        ;LDA STR_ADDRESS_TO_LOAD,Y
        ;TAY
        ;JSR CHARS_TO_BYTE
        ;LDY #1
        ;STA ADDRESS_TO_LOAD,Y
        ;INY
        ;LDX STR_ADDRESS_TO_LOAD,Y
        ;INY
        ;LDA STR_ADDRESS_TO_LOAD,Y
        ;TAY
        ;JSR CHARS_TO_BYTE
        ;STA ADDRESS_TO_LOAD

        ;JSR PRINT_HEX_BYTE
        ;LDY #1
        ;LDA ADDRESS_TO_LOAD,Y
        ;JSR PRINT_HEX_BYTE
        ;JMP HANG

        ;JMP START_LOOP
        
        ;LDX TEST_COUNTER
        ;CPX #0
        ;BEQ HANG
        ;LDA TEST_ADDRESS
        ;TAY
        ;PHA
        ;LDX #1
        ;LDA TEST_ADDRESS,X
        ;TAX
        ;PHA
        ;JSR SET_UP_LINE
        ;PLA
        ;TAX
        ;PLA
        ;TAY
        ;JSR MAKE_OP_CODE_STRING
        ;CLC
        ;ADC TEST_ADDRESS
        ;STA TEST_ADDRESS
        ;LDX #1
        ;LDA #0
        ;ADC TEST_ADDRESS,X
        ;STA TEST_ADDRESS,X
        ;DEC TEST_COUNTER
        ;JMP START_LOOP
HANG
        JMP HANG
STR_ADDRESS_TO_LOAD
        byte 0,0,0,0
ADDRESS_TO_LOAD
        byte 0,0
STR_ADDRESS_TO_LOAD_COUNTER
        byte 0
        

;subroutine for making opcode string
;address for subroutine should be passed wivic-th addr $XXYY in X and Y
;string to print afterwards can be found at address MAKE_OP_CODE_STRING_TXT
;returns number of bytes op-code used in register A
MAKE_OP_CODE_STRING
        STY $00
        STX $01
        LDY #0
MAKE_OP_CODE_STRING_TO_LOAD_LOOP
        LDA ($00),Y
        STA OP_CODE_FIRST_BYTE,Y
        INY
        CPY #3
        BNE MAKE_OP_CODE_STRING_TO_LOAD_LOOP

        LDA OP_CODE_FIRST_BYTE
        AND #$F
        CMP #$8
        BEQ MAKE_OP_CODE_STRING_INSTRUCTION_EIGHT
        CMP #$A
        BEQ MAKE_OP_CODE_STRING_INSTRUCTION_A
        CMP #$0
        BEQ MAKE_OP_CODE_STRING_INSTRUCTION_BRANCH
        JMP MAKE_OP_CODE_STRING_GET_STRING_TABLE

; single byte instruction ending with 8
MAKE_OP_CODE_STRING_INSTRUCTION_EIGHT     
        LDA #<OPCODE_TABLE_EIGHT
        STA $00
        LDA #>OPCODE_TABLE_EIGHT
        STA $01
        
        LDA OP_CODE_FIRST_BYTE
        AND #$F0
        LSR 
        LSR
        JSR PRINT_STRING
        
MAKE_OP_CODE_STRING_INSTRUCTION_ONE_BYTE_END
        LDA #1
        RTS

MAKE_OP_CODE_STRING_INSTRUCTION_BRANCH
        LDA #<OPCODE_TABLE_BRANCH
        STA $00
        LDA #>OPCODE_TABLE_BRANCH
        STA $01

        LDA OP_CODE_FIRST_BYTE
        AND #$F0
        LSR
        LSR
        JSR PRINT_STRING

        LDA OP_CODE_FIRST_BYTE
        CMP #$00 ; check for brk
        BEQ MAKE_OP_CODE_STRING_INSTRUCTION_ONE_BYTE_END
        CMP #$40 ; check for rti
        BEQ MAKE_OP_CODE_STRING_INSTRUCTION_ONE_BYTE_END
        CMP #$60 ; check for rts
        BEQ MAKE_OP_CODE_STRING_INSTRUCTION_ONE_BYTE_END
        CMP #$20 ; check if it's jsr
        BEQ MAKE_OP_CODE_STRING_INSTRUCTION_BRANCH_JSR
        
        LDA #' '
        JSR $FFD2
        LDA #'$'
        JSR $FFD2

        LDA OP_CODE_THIRD_BYTE
        JSR PRINT_HEX_BYTE

        LDA #$2
        RTS

MAKE_OP_CODE_STRING_INSTRUCTION_BRANCH_JSR
        LDA #' '
        JSR $FFD2
        LDA #'$'
        JSR $FFD2

        LDA OP_CODE_THIRD_BYTE
        JSR PRINT_HEX_BYTE
        LDA OP_CODE_SECOND_BYTE
        JSR PRINT_HEX_BYTE

        LDA #$3
        RTS


MAKE_OP_CODE_STRING_INSTRUCTION_A
        LDA #<OPCODE_TABLE_A
        STA $00
        LDA #>OPCODE_TABLE_A
        STA $01

        LDA OP_CODE_FIRST_BYTE
        AND #$F0
        LSR
        LSR
        AND #$1F                
        JSR PRINT_STRING

        LDA #1
        RTS

MAKE_OP_CODE_STRING_GET_STRING_TABLE
        LDA OP_CODE_FIRST_BYTE
        AND #$3
        STA OP_CODE_CC_BYTE

        ;LDA OP_CODE_FIRST_BYTE
        ;AND #$3 ; gives us address in opcode_type_table to load opcode from
        ASL ; shift to the left to double for op code type table
        TAY
        
        ; indirect index addressing to get string table location
        LDA #<OPCODE_TYPE_TABLE
        STA $02
        LDA #>OPCODE_TYPE_TABLE
        STA $03

        LDA ($02),Y
        STA $00
        INY
        LDA ($02),Y
        STA $01

MAKE_OP_CODE_STRING_INSTRUCTION
        LDA OP_CODE_FIRST_BYTE
        LSR 
        LSR
        LSR
        CLC ; 3 shifts and carry bit clear to find opcode name in table
        AND #$1C ; get rid of any bits we don't need
        JSR PRINT_STRING

        LDA OP_CODE_FIRST_BYTE
        AND #$1C
        PHA ; save for fetching addressing offset register later

        ASL ; table is made up of 8 byte segments for each addressing mode type
        STA MAKE_OP_CODE_PTR

        ;LDA OP_CODE_FIRST_BYTE
        ;AND #$3
        LDA OP_CODE_CC_BYTE
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
        LDX #$B6 ; LDX                  ; LDX and STX are the only two zero page instructions for which the 
        BEQ ADDRESSING_ZERO_PAGE_Y_CHAR ; 3 bits corresponding to addressing "$<ZERO PAGE>,X" are flipped
        CPX #$96 ; STX                  ; internally to represent "$<ZERO PAGE>,Y"
        BEQ ADDRESSING_ZERO_PAGE_Y_CHAR
        JMP ADDRESSING_ZERO_PAGE_X_CHAR
ADDRESSING_ZERO_PAGE_Y_CHAR
        LDA #$59
ADDRESSING_ZERO_PAGE_X_CHAR        
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
        CPX #$BE ; LDX                  ; as explained before, LDX's 3 addressing bits for "$<ABS>,X"
        BNE ADDRESSING_ABS_X_CHAR       ; are flipped internally for "$<ABS>,Y". STX does not have 
ADDRESSING_ABS_Y_CHAR                   ; the option for addressing mode "$<ABS,X"
        LDA #$59
ADDRESSING_ABS_X_CHAR
        JSR $FFD2
        JMP MAKE_OP_CODE_STRING_TRIPLE_BYTE_END

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

;function that gets addressing mode character, returns it in A
;3 bit addressing should be passed in A
GET_ADDRESSING_MODE_CHAR
        STA GET_ADDRESSING_MODE_PTR
        LDA OP_CODE_CC_BYTE
        ;LDA OP_CODE_FIRST_BYTE
        ;AND #$3
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
OP_CODE_CC_BYTE
        byte 0
MAKE_OP_CODE_PTR
        byte 0,0

PRINT_SYM_SPACE
        LDA #' '
        JSR $FFD2
        LDA #'$'
        JSR $FFD2
        RTS     

; put address in $00 and $01
; call with desired offset in Y
;function for printing string to output
;;pass address of string $XXYY, reg X and Y
PRINT_STRING
        ;STY $00
        ;STX $01
        ;LDY #0
        STA PRINT_STRING_PTR
PRINT_STRING_LOOP
        LDY PRINT_STRING_PTR
PRINT_STRING_CHAR_TO_LOAD
        LDA ($00),Y
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

;converts two hex chars to a byte
;pass in X,Y as $XY
;byte is returned in A
CHARS_TO_BYTE
        TYA
        CMP #57 ; check to see if char is bigger than ascii for 9
        BEQ CHARS_TO_BYTE_DIGIT_LOWER
        BCS CHARS_TO_BYTE_ALPHA_LOWER
CHARS_TO_BYTE_DIGIT_LOWER
        SEC
        SBC #48 ; subtract '0'
        STA CHARS_TO_BYTE_SAVED
        JMP CHARS_TO_BYTE_UPPER
CHARS_TO_BYTE_ALPHA_LOWER
        SEC
        SBC #55 ; subtract 'a'
        STA CHARS_TO_BYTE_SAVED
CHARS_TO_BYTE_UPPER
        TXA
        CMP #57
        BEQ CHARS_TO_BYTE_DIGIT_UPPER
        BCS CHARS_TO_BYTE_ALPHA_UPPER
CHARS_TO_BYTE_DIGIT_UPPER
        SEC
        SBC #48
        JMP CHARS_TO_BYTE_END
CHARS_TO_BYTE_ALPHA_UPPER        
        SEC
        SBC #55
CHARS_TO_BYTE_END
        ASL
        ASL
        ASL
        ASL
        ORA CHARS_TO_BYTE_SAVED
        RTS
CHARS_TO_BYTE_SAVED
        byte 0

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

; single byte instructions ending with 0x8
OPCODE_TABLE_EIGHT
        text "php" ; $08
        byte 0
        text "clc" ; $18
        byte 0          
        text "plp" ; $28
        byte 0
        text "sec" ; $38
        byte 0
        text "pha" ; $48
        byte 0
        text "cli" ; $58
        byte 0
        text "pla" ; $68
        byte 0
        text "sei" ; $78
        byte 0
        text "dey" ; $88
        byte 0
        text "tya" ; $98
        byte 0 
        text "tay" ; $A8
        byte 0
        text "clv" ; $B8
        byte 0
        text "iny" ; $C8
        byte 0
        text "cld" ; $D8
        byte 0
        text "inx" ; $E8
        byte 0
        text "sed" ; $F8
        byte 0

; single byte instructions ending with 0xA
OPCODE_TABLE_A
        text "txa" ; $8A
        byte 0
        text "txs" ; $9A
        byte 0
        text "tax" ; $AA
        byte 0
        text "tsx" ; $BA
        byte 0
        text "dex" ; $CA
        byte 0
        text "nop" ; $EA
        byte 0

; branching instructions
OPCODE_TABLE_BRANCH
        text "brk" ; $00
        byte 0
        text "bpl" ; $10
        byte 0
        text "jsr" ; $20
        byte 0
        text "bmi" ; $30
        byte 0
        text "rti" ; $40
        byte 0
        text "bvc" ; $50
        byte 0
        text "rts" ; $60
        byte 0
        text "bvs" ; $70
        byte 0
        byte 0,0   ; $80
        byte 0,0
        text "bcc" ; $90
        byte 0
        byte 0,0   ; $A0
        byte 0,0
        text "bcs" ; $B0
        byte 0
        byte 0,0   ; $C0
        byte 0,0
        byte "bne" ; $D0
        byte 0
        byte 0,0   ; $E0
        byte 0,0
        byte "beq" ; $F0
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