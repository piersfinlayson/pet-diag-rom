
.include "macros.inc"
.include "constants.inc"
.include "version.inc"

.import memory_address_list
.import AuthorString
.import ProgString

.segment "HEADER"
.byte $F0
.byte MAJOR_VERSION, MINOR_VERSION, PATCH_VERSION
.byte PET_DIAG_ROM_ID1, PET_DIAG_ROM_ID2, PET_DIAG_ROM_ID3, PET_DIAG_ROM_ID4

.segment "CODE"

start:
    ; Initialize the CPU and stack
    sei
    cld
    ldx #$ff
    txs

    ; Clear the screen
    JSR init_screen

    ; Initialize the screen write pointers
    ldx #$0
    stx ZP_LINE
    stx ZP_COL

    ; Write the author string
    lda #<AuthorString
    sta ZP_STR_PTR
    lda #>AuthorString
    sta ZP_STR_PTR + 1
    jsr write_string

    ; Write the program name
    jsr newline
    lda #<ProgString
    sta ZP_STR_PTR
    lda #>ProgString
    sta ZP_STR_PTR + 1
    jsr write_string

    ; Dump the first few bytes of the $E000 memory area
    jsr dump_address_list

final_loop:
    ; Infinite loop to keep the program running
    jmp final_loop

; Clear the screen
;
; Uses A, X and Y
init_screen:
    ; Set pointer to the start of screen RAM
    lda #<SCREEN_RAM
    sta ZP_PTR
    lda #>SCREEN_RAM
    sta ZP_PTR + 1

    ; Set A to the space character
    lda #$20

    ; Set X to the number of lines minus one
    ldx #(SCREEN_ROWS - 1)

    ; Loop through each line
@init_line:
    ldy #(SCREEN_COLS-1)    ; Column
@init_char:
    sta (ZP_PTR), Y         ; Store space at the current position
    dey
    bpl @init_char          ; Loop until column is less than 0

    ; Add SCREEN_COLS to the pointer to move to the next line
    clc
    lda ZP_PTR
    adc #SCREEN_COLS
    sta ZP_PTR
    lda ZP_PTR + 1
    adc #0
    sta ZP_PTR + 1

    dex
    bpl @init_line          ; Loop until line is less than 0

    rts

; Calculate screen address from ZP_LINE/ZP_COL into ZP_PTR
; Uses A, X
calc_screen_addr:
    lda ZP_LINE
    beq @line_done          ; If line 0, skip multiply
    
    ; Multiply line by 40
    ldx ZP_LINE
    lda #0
@mult_loop:
    clc
    adc #SCREEN_COLS
    dex
    bne @mult_loop
    
@line_done:
    ; Add column offset and screen base
    clc
    adc ZP_COL
    clc
    adc #<SCREEN_RAM
    sta ZP_PTR
    lda #>SCREEN_RAM
    adc #0
    sta ZP_PTR + 1
    rts

; Advance ZP_COL/ZP_LINE to next position (with wrap)
; Uses A
advance_position:
    inc ZP_COL
    lda ZP_COL
    cmp #SCREEN_COLS
    bcc @done               ; No wrap needed
    
    ; Wrap to next line
    lda #0
    sta ZP_COL
    inc ZP_LINE
@done:
    rts

; Write a single character
write_char:
    pha                     ; Save character
    jsr calc_screen_addr
    pla                     ; Restore character
    ldy #0
    sta (ZP_PTR), y
    jmp advance_position    ; Tail call

; Write string (MSB-terminated)
write_string:
    ldy #0
@write_loop:
    jsr calc_screen_addr
    lda (ZP_STR_PTR), y     ; Load character
    tax                     ; Save for MSB check
    and #$7F                ; Clear MSB
    ldy #0
    sta (ZP_PTR), y         ; Store to screen
    
    jsr advance_position
    
    ; Check if last character
    txa
    bmi @done
    
    ; Advance string pointer
    inc ZP_STR_PTR
    bne @write_loop
    inc ZP_STR_PTR + 1
    bne @write_loop
    
@done:
    rts

; Convert nibble (0-15) to hex ASCII character
; Input: A contains nibble (0-15)
; Output: A contains ASCII hex digit
; Uses: A
nibble_to_hex:
    cmp #10
    bcc @digit              ; 0-9
    clc
    adc #('A' - 10)         ; A-F
    rts
@digit:
    clc
    adc #'0'                ; 0-9
    rts

; Output byte in A as two hex digits
; Uses: A, X
write_hex_byte:
    pha                     ; Save original byte
    
    ; Output high nibble
    lsr
    lsr
    lsr
    lsr
    jsr nibble_to_hex
    jsr write_char
    
    ; Output low nibble
    pla                     ; Restore original
    and #$0F
    jsr nibble_to_hex
    jmp write_char          ; Tail call

; Output 16-bit address as 4 hex digits
; Address in ZP_DUMP_ADDR/ZP_DUMP_ADDR+1
; Uses: A, X
write_hex_addr:
    lda ZP_DUMP_ADDR + 1    ; High byte first
    jsr write_hex_byte
    lda ZP_DUMP_ADDR        ; Low byte
    jmp write_hex_byte      ; Tail call

; Main memory dump routine
; Outputs: $ADDR bytes...
dump_memory:
    ; Output '$'
    lda #'$'
    jsr write_char
    
    ; Output address
    jsr write_hex_addr
    
    ; Output space
    lda #' '
    jsr write_char
    
    ; Output data bytes
    ldy #0
@dump_loop:
    lda (ZP_DUMP_ADDR), y
    jsr write_hex_byte
    
    iny
    cpy ZP_DUMP_COUNT
    bcc @dump_loop
    
    rts

; Move to beginning of next line
; Wraps to line 0 if at bottom of screen
; Uses: A
newline:
    lda #0
    sta ZP_COL              ; Column 0
    
    inc ZP_LINE             ; Next line
    lda ZP_LINE
    cmp #SCREEN_ROWS        ; Check if past bottom
    bcc @done               ; Still on screen
    
    lda #0                  ; Wrap to top
    sta ZP_LINE
    
@done:
    rts

dump_address_list:
    ; Initialize list pointer and get count
    lda #<memory_address_list
    sta ZP_LIST_PTR
    lda #>memory_address_list
    sta ZP_LIST_PTR + 1
    
    ; Get address count
    ldy #0
    lda (ZP_LIST_PTR), y
    tax                     ; X = address count
    
    ; Advance pointer past count byte
    inc ZP_LIST_PTR
    bne @setup_count
    inc ZP_LIST_PTR + 1
    
@setup_count:
    ; Set up dump count
    lda #4
    sta ZP_DUMP_COUNT

@loop:
    ; Load next address from list
    ldy #0
    lda (ZP_LIST_PTR), y    ; Low byte
    sta ZP_DUMP_ADDR
    iny
    lda (ZP_LIST_PTR), y    ; High byte
    sta ZP_DUMP_ADDR + 1

    jsr newline
    jsr dump_memory
    
    ; Advance to next address in list
    clc
    lda ZP_LIST_PTR
    adc #2
    sta ZP_LIST_PTR
    bcc @next
    inc ZP_LIST_PTR + 1
    
@next:
    dex
    bne @loop

    rts

nmi_handler:
    ; Handle NMI (not implemented)
    rti

irq_handler:
    ; Handle IRQ (not implemented)
    rti

; Interrupt vectors - NMI, Reset and IRQ
.segment "VECTORS"

nmi_vector:
    .word nmi_handler

reset_vector:
    .word start

irq_vector:
    .word irq_handler