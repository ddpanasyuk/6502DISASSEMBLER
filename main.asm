START *= $0400
        byte 0
        byte $04

        JMP START_LOOP

SET_MODE_HEX
        LDA #'$'
        STA PRINTING_CHAR
        JMP START_LOOP
SET_MODE_DISASM
        LDA #'>'
        STA PRINTING_CHAR
        JMP START_LOOP
SET_MODE_ASCII
        LDA #'%'
        STA PRINTING_CHAR
        JMP START_LOOP
SET_MODE_WRITE
        LDA #'!'
        STA PRINTING_CHAR
        JMP START_LOOP

START_LOOP
        LDA #13
        JSR $FFD2

        LDA PRINTING_CHAR
        JSR $FFD2

START_LOOP_FINISH_SETUP

        LDA #4
        STA STR_ADDRESS_TO_LOAD_COUNTER        
        LDA #0
        STA STR_ADDRESS_TO_LOAD_OFFSET
LOAD_CHARS_LOOP
        LDY STR_ADDRESS_TO_LOAD_COUNTER
        CPY #0  
        BEQ START_DISASSEMBLE
        JSR $FFCF
        CMP #72 ; (h)ex dump mode
        BEQ SET_MODE_HEX
        CMP #73 ; disassemble (i)nstruction mode
        BEQ SET_MODE_DISASM
        CMP #84 ; (t)ext mode
        BEQ SET_MODE_ASCII
        CMP #87 ; (w)rite mode
        BEQ SET_MODE_WRITE
        CMP #88 ; e(x)ecute command
        BEQ START_DISASSEMBLE_NEXT_ADDR
        CMP #81 ; (q)uit command
        BEQ QUIT_PROGRAM
        LDY STR_ADDRESS_TO_LOAD_OFFSET
        STA STR_ADDRESS_TO_LOAD,Y
        INC STR_ADDRESS_TO_LOAD_OFFSET
        DEC STR_ADDRESS_TO_LOAD_COUNTER
        JMP LOAD_CHARS_LOOP
START_DISASSEMBLE
        LDX STR_ADDRESS_TO_LOAD
        LDY #1
        LDA STR_ADDRESS_TO_LOAD,Y
        TAY
        JSR CHARS_TO_BYTE
        LDY #1
        STA ADDRESS_TO_LOAD,Y
        INY
        LDX STR_ADDRESS_TO_LOAD,Y
        INY
        LDA STR_ADDRESS_TO_LOAD,Y
        TAY
        JSR CHARS_TO_BYTE
        STA ADDRESS_TO_LOAD ; convert our input hex string into regular bytes

START_DISASSEMBLE_NEXT_ADDR
        LDY #1
        LDX ADDRESS_TO_LOAD,Y
        LDY ADDRESS_TO_LOAD
        JSR SET_UP_LINE ; print line

        LDY #1
        LDX ADDRESS_TO_LOAD,Y
        LDY ADDRESS_TO_LOAD
        LDA PRINTING_CHAR
        CMP #'$'
        BEQ START_MODE_HEX
        CMP #'%'
        BEQ START_MODE_ASCII
        CMP #'!'
        BEQ START_MODE_WRITE

        JSR MAKE_OP_CODE_STRING ; print disassembled line
        JMP START_CALC_NEXT_ADDR

START_MODE_HEX
        JSR MAKE_HEX_DUMP_STRING
        JMP START_CALC_NEXT_ADDR

START_MODE_WRITE
        JSR MAKE_INSERT_BYTE
        JMP START_CALC_NEXT_ADDR

START_MODE_ASCII        
        JSR MAKE_ASCII_DUMP_STRING
        
START_CALC_NEXT_ADDR
        CLC
        ADC ADDRESS_TO_LOAD
        STA ADDRESS_TO_LOAD
        LDA #0
        LDY #1
        ADC ADDRESS_TO_LOAD,Y
        STA ADDRESS_TO_LOAD,Y ; next address 

        JMP START_LOOP

QUIT_PROGRAM
        BRK

STR_ADDRESS_TO_LOAD
        byte 0,0,0,0
ADDRESS_TO_LOAD
        byte 0,0
STR_ADDRESS_TO_LOAD_COUNTER
        byte 0
STR_ADDRESS_TO_LOAD_OFFSET
        byte 0
;printing mode: > = disassembly, $ = hexdump, % = ascii, ! byte insert
PRINTING_CHAR
        text ">"

;subroutine for byte insert at address
;address should be passed in $XXYY
MAKE_INSERT_BYTE
        STY $00
        STX $01

        JSR $FFCF
        STA MAKE_INSERT_BYTE_STRING
        JSR $FFCF
        STA MAKE_INSERT_BYTE_STRING_SEC

        LDX MAKE_INSERT_BYTE_STRING
        LDY MAKE_INSERT_BYTE_STRING_SEC
        JSR CHARS_TO_BYTE

        LDY #0
        STA ($00),Y

        LDA #1
        RTS
MAKE_INSERT_BYTE_STRING
                byte 0
MAKE_INSERT_BYTE_STRING_SEC
                byte 0

;subroutine for dumping hex
;address for subroutine should be passed in $XXYY
MAKE_HEX_DUMP_STRING
        STY $00
        STX $01

        LDY #0
        STY MAKE_HEX_DUMP_COUNTER
MAKE_HEX_DUMP_STRING_LOAD_LOOP
        LDY MAKE_HEX_DUMP_COUNTER
        CPY #4
        BEQ MAKE_HEX_DUMP_STRING_RET
        LDA ($00),Y
        JSR PRINT_HEX_BYTE
        LDA #' '
        JSR $FFD2
        INC MAKE_HEX_DUMP_COUNTER
        JMP MAKE_HEX_DUMP_STRING_LOAD_LOOP

MAKE_HEX_DUMP_STRING_RET
        LDA #4
        RTS
MAKE_HEX_DUMP_COUNTER
        byte 0

;subroutine for dumping ascii
;address for subroutine should be passed in $XXYY
MAKE_ASCII_DUMP_STRING
        STY $00
        STX $01

        LDY #0
        STY MAKE_ASCII_DUMP_COUNTER
MAKE_ASCII_DUMP_STRING_LOAD_LOOP
        LDY MAKE_ASCII_DUMP_COUNTER
        CPY #8
        BEQ MAKE_ASCII_DUMP_STRING_RET
        LDA ($00),Y
        JSR CHECK_ASCII_PRINT
        JSR $FFD2
        INC MAKE_ASCII_DUMP_COUNTER
        JMP MAKE_ASCII_DUMP_STRING_LOAD_LOOP
MAKE_ASCII_DUMP_STRING_RET
        LDA #8
        RTS
MAKE_ASCII_DUMP_COUNTER
        byte 0

CHECK_ASCII_PRINT
        CMP #32
        BCC CHECK_ASCII_PRINT_UNPRINTABLE
        CMP #122
        BCS CHECK_ASCII_PRINT_UNPRINTABLE
        RTS
CHECK_ASCII_PRINT_UNPRINTABLE
        LDA #127
        RTS

;subroutine for making opcode string
;address for subroutine should be passed with addr $XXYY in X and Y
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
        LDA OP_CODE_FIRST_BYTE
        CMP #$0
        BEQ MAKE_OP_CODE_STRING_INSTRUCTION_BRANCH
        CMP #$20
        BEQ MAKE_OP_CODE_STRING_INSTRUCTION_BRANCH
        CMP #$40
        BEQ MAKE_OP_CODE_STRING_INSTRUCTION_BRANCH
        CMP #$60
        BEQ MAKE_OP_CODE_STRING_INSTRUCTION_BRANCH ; ham-fisted approach during testing, will fix later
        AND #$1F
        CMP #$10
        BEQ MAKE_OP_CODE_STRING_INSTRUCTION_BRANCH
        JMP MAKE_OP_CODE_STRING_GET_STRING_TABLE

MAKE_OP_CODE_STRING_INSTRUCTION_A
        LDA OP_CODE_FIRST_BYTE
        CMP #$8A
        BCC MAKE_OP_CODE_STRING_GET_STRING_TABLE_JMP

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

MAKE_OP_CODE_STRING_GET_STRING_TABLE_JMP
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
        LDA OP_CODE_FIRST_BYTE
        AND #$1F
        CMP #$1
        BEQ ADDRESSING_ZERO_PAGE_INDIRECT_INDEXED
        CMP #$11
        BEQ ADDRESSING_ZERO_PAGE_INDIRECT_OFFSET
        JSR PRINT_SYM_SPACE
        LDA #' '
        STA ADDRESSING_ZERO_PAGE_PAREN_SECOND
        STA ADDRESSING_ZERO_PAGE_PAREN_THIRD
ADDRESSING_ZERO_PAGE_POST_PAREN
        LDA OP_CODE_SECOND_BYTE
        JSR PRINT_HEX_BYTE
        LDA ADDRESSING_ZERO_PAGE_PAREN_SECOND
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

        LDA ADDRESSING_ZERO_PAGE_PAREN_THIRD
        JSR $FFD2

        JMP MAKE_OP_CODE_STRING_DUAL_BYTE_END
ADDRESSING_ZERO_PAGE_PAREN_SECOND
        byte 0
ADDRESSING_ZERO_PAGE_PAREN_THIRD
        byte 0

ADDRESSING_ZERO_PAGE_INDIRECT_INDEXED
        LDA #' '
        STA ADDRESSING_ZERO_PAGE_PAREN_SECOND
        JSR $FFD2
        LDA #$28 ; '('
        JSR $FFD2
        LDA #'$'
        JSR $FFD2
        LDA #$29
        STA ADDRESSING_ZERO_PAGE_PAREN_THIRD
        JMP ADDRESSING_ZERO_PAGE_POST_PAREN
ADDRESSING_ZERO_PAGE_INDIRECT_OFFSET
        LDA #' '
        STA ADDRESSING_ZERO_PAGE_PAREN_THIRD
        JSR $FFD2
        LDA #$28 ; '('
        JSR $FFD2
        LDA #'$'
        JSR $FFD2
        LDA #$29
        STA ADDRESSING_ZERO_PAGE_PAREN_SECOND
        JMP ADDRESSING_ZERO_PAGE_POST_PAREN

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
        STX SET_UP_LINE_X
        STY SET_UP_LINE_Y
        LDA #13
        JSR $FFD2
        LDA #'$'
        JSR $FFD2
        LDX SET_UP_LINE_X
        TXA
        JSR PRINT_HEX_BYTE
        LDY SET_UP_LINE_Y
        TYA
        JSR PRINT_HEX_BYTE
        LDA #':'
        JSR $FFD2
        RTS
SET_UP_LINE_X
        byte 0
SET_UP_LINE_Y
        byte 0

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

;INSTRUCTION_SET_01_TEST
;        ORA ($12,X)
;        ORA $34
;        ORA #12
;        ORA $1234
;        ORA ($12),Y
;        ORA $34,X
;        ORA $1234,Y
;        ORA $1234,X

;        AND ($12,X)
;        AND $34
;        AND #12
;        AND $1234
;        AND ($12),Y
;        AND $34,X
;        AND $1234,Y
;        AND $1234,X

;        EOR ($12,X)
;        EOR $34
;        EOR #12
;        EOR $1234
;        EOR ($12),Y
;        EOR $34,X
;        EOR $1234,Y
;        EOR $1234,X

;        ADC ($12,X)
;        ADC $34
;        ADC #12
;        ADC $1234
;        ADC ($12),Y
;        ADC $34,X
;        ADC $1234,Y
;        ADC $1234,X        

;        STA ($12,X)
;        STA $34
        ;EOR #12
;        STA $1234
;        STA ($12),Y
;        STA $34,X
;        STA $1234,Y
;        STA $1234,X

;       LDA ($12,X)
;       LDA $34
;       LDA #12
;       LDA $1234
;       LDA ($12),Y
;       LDA $34,X
;       LDA $1234,Y
;       LDA $1234,X

;       CMP ($12,X)
;       CMP $34
;       CMP #12
;       CMP $1234
;       CMP ($12),Y
;       CMP $34,X
;       CMP $1234,Y
;       CMP $1234,X

;       SBC ($12,X)
;       SBC $34
;       SBC #12
;       SBC $1234
;       SBC ($12),Y
;       SBC $34,X
;       SBC $1234,Y
;       SBC $1234,X

;NSTRUCTION_SET_10_TEST
;       ASL $12
;       ASL
;       ASL $1234
;       ASL $12,X
;       ASL $1234,X
;
;      ROL $12
;       ROL
;       ROL $1234
;       ROL $12,X
;       ROL $1234,X;
;
;       LSR $12
;       LSR
;       LSR $1234
;       LSR $12,X
;       LSR $1234,X
;
;       ROR $12
;       ROR
;       ROR $1234
;       ROR $12,X
;       ROR $1234,X

;      STX $12
;       STX $1234
;       STX $34,Y;
;
 ;      LDX #$12
 ;      LDX $34
 ;      LDX $1234
 ;      LDX $12,Y
 ;      LDX $1234,Y

 ;      DEC $12
;       DEC $1234
;       DEC $34,X
;       DEC $1234,X
;       
;       INC $12
;       INC $1234
;       INC $34,X
;       INC $1234,X        ;;
;
;NSTRUCTION_SET_00_TEST
;       BIT $12
;       BIT $1234
        
;       JMP $1234
        
;       STY $12
;       STY $1234
;       STY $12,X

        ;DY #$12
;       LDY $34
;       LDY $1234
;       LDY $12,X
;       LDY $1234,X

        ;PY #$12
        ;PY $34
;        CPY $1234

;        CPX #$12
;        CPX $34
;        CPX $1234;

;INSTRUCTION_SET_BRANCH_TEST
;        BPL INSTRUCTION_SET_BRANCH_TEST
;        BMI INSTRUCTION_SET_BRANCH_TEST
;        BVC INSTRUCTION_SET_BRANCH_TEST
;        BVS INSTRUCTION_SET_BRANCH_TEST
;        BCC INSTRUCTION_SET_BRANCH_TEST
;        BCC INSTRUCTION_SET_BRANCH_TEST
;        BCS INSTRUCTION_SET_BRANCH_TEST
;        BCS INSTRUCTION_SET_BRANCH_TEST
;        BNE INSTRUCTION_SET_BRANCH_TEST
;        BEQ INSTRUCTION_SET_BRANCH_TEST
;        BRK
;        JSR $1234
;        RTI
;        RTS

;INSTRUCTION_SET_SINGLE_TEST
;        PHP
;        CLC
;        PLP
;        SEC
;        PHA
;        CLI
;        PLA
;        SEI
;        DEY
;        TYA
;        TAY
;        CLV
;        INY
;        CLD
;        INX
;        SED
;        TXA
;        TXS
;        TAX
;        TSX
;        DEX
;        NOP