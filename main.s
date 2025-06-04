
.include "macros.inc"
.include "constants.inc"
.include "version.inc"

.import memory_address_list
.import AuthorString, DashString, ProgString, ZeroString, StackString
.import PageString, RamString, TestString, TestingString, PassedString
.import FailedString, CompleteString, DetectedString, KbString, RomString
.import DumpString

.segment "HEADER"
.byte $F0
.byte MAJOR_VERSION, MINOR_VERSION, PATCH_VERSION
.byte PET_DIAG_ROM_ID1, PET_DIAG_ROM_ID2, PET_DIAG_ROM_ID3, PET_DIAG_ROM_ID4

.segment "CODE"

start:
    ; Initialize the CPU
    sei
    cld

    ; Test zero page - jmps to test_stack if successful
    jmp test_zero_page

    ; Test the stack - jmps to after_stack_test if successful
test_stack:
    lda #$01            ; Test page $0100
    jmp test_ram_page   ; JMP - not JSR

    ; Initialize the stack
after_stack_test:
    ldx #$ff
    txs

    ; Clear the screen and write pointers
    jsr init_screen

    WriteString ProgString
    WriteString DashString
    WriteString AuthorString
    jsr newline

    ; Output zero and stack page tests were successful (which they were if
    ; we get here)
    jsr newline
    WriteString ZeroString
    WriteChar ' '
    WriteString PageString
    WriteChar ' '
    WriteString TestString
    WriteChar ' '
    WriteString PassedString
    jsr newline
    WriteString StackString
    WriteChar ' '
    WriteString PageString
    WriteChar ' '
    WriteString TestString
    WriteChar ' '
    WriteString PassedString
    jsr newline

    ; Test RAM
    jsr newline
    WriteString TestingString
    WriteChar ' '
    WriteString RamString
    WriteChar ' '
    WriteString PageString
    WriteChar ' '
    WriteChar '$'
    jsr test_all_ram
    pha                 ; store any failed RAM page
    php                 ; store result

    ; Output RAM test result - on same line as testing RAM
    lda #$00
    sta ZP_COL
    jsr calc_screen_addr
    jsr clear_line
    WriteString DetectedString
    WriteChar ' '
    lda ZP_RAM_SIZE
    jsr write_decimal_byte
    WriteString KbString
    WriteChar ' '
    WriteString RamString
    jsr newline
    WriteString RamString
    WriteChar ' '
    WriteString TestString
    WriteChar ' '

    plp
    bcs @ram_fail

    ; RAM test passed
    WriteString PassedString
    pla                 ; Get A back off stack
    jmp @dump_address_list

@ram_fail:
    WriteString FailedString
    WriteString DashString
    WriteString PageString
    WriteChar ' '
    WriteChar '$'
    pla                 ; Get failed page off stack
    jsr write_hex_byte

@dump_address_list:
    jsr newline
    jsr dump_address_list
    jsr newline

    ; Write the finished string
    jsr newline
    WriteString TestString
    WriteChar 'S'
    WriteChar ' '
    WriteString CompleteString

final_loop:
    ; Infinite loop to keep the program running
    jmp final_loop

; Clear a single line
; Input: ZP_SCREEN_PTR points to start of line to clear
; Uses: A, Y
; Preserves: ZP_SCREEN_PTR, X
clear_line:
    lda #$20                ; Space character
    ldy #(SCREEN_COLS-1)    ; Start from last column
@clear_char:
    sta (ZP_SCREEN_PTR), Y  ; Store space at current position
    dey
    bpl @clear_char         ; Loop until column < 0
    rts

; Clear the screen
; Uses A, X and Y
init_screen:
    ; Set pointer to the start of screen RAM
    lda #<SCREEN_RAM
    sta ZP_SCREEN_PTR
    lda #>SCREEN_RAM
    sta ZP_SCREEN_PTR + 1

    ; Set X to the number of lines minus one
    ldx #(SCREEN_ROWS - 1)

@init_line:
    jsr clear_line          ; Clear current line

    ; Advance pointer to next line
    clc
    lda ZP_SCREEN_PTR
    adc #SCREEN_COLS
    sta ZP_SCREEN_PTR
    lda ZP_SCREEN_PTR + 1
    adc #0
    sta ZP_SCREEN_PTR + 1

    dex
    bpl @init_line          ; Loop until all lines done

    ; Initialize the screen write pointers
    ldx #$0
    stx ZP_LINE
    stx ZP_COL
    jsr calc_screen_addr

    rts

; Calculate screen address from ZP_LINE/ZP_COL into ZP_SCREEN_PTR
; Uses A, X
calc_screen_addr:
    lda ZP_LINE
    beq @line_done          ; If line 0, skip multiply
    
    ; Multiply line by 40 (16-bit result)
    ldx ZP_LINE
    lda #0
    sta ZP_SCREEN_PTR              ; Clear low byte
    sta ZP_SCREEN_PTR + 1          ; Clear high byte
@mult_loop:
    clc
    lda ZP_SCREEN_PTR
    adc #SCREEN_COLS
    sta ZP_SCREEN_PTR
    lda ZP_SCREEN_PTR + 1
    adc #0                  ; Add carry to high byte
    sta ZP_SCREEN_PTR + 1
    dex
    bne @mult_loop
    jmp @add_col

@line_done:
    ; Line 0 - result is 0
    lda #0
    sta ZP_SCREEN_PTR
    sta ZP_SCREEN_PTR + 1

@add_col:
    ; Add column offset
    clc
    lda ZP_SCREEN_PTR
    adc ZP_COL
    sta ZP_SCREEN_PTR
    lda ZP_SCREEN_PTR + 1
    adc #0
    sta ZP_SCREEN_PTR + 1
    
    ; Add screen base address
    clc
    lda ZP_SCREEN_PTR
    adc #<SCREEN_RAM
    sta ZP_SCREEN_PTR
    lda ZP_SCREEN_PTR + 1
    adc #>SCREEN_RAM
    sta ZP_SCREEN_PTR + 1
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

    cmp #SCREEN_ROWS
    bcc @done               ; Still on screen

    ; Wrap to top of screen
    sta ZP_LINE             ; A is still 0
@done:
    rts

; Write a single character
write_char:
    pha                     ; Save character
    jsr calc_screen_addr
    pla                     ; Restore character
    ldy #0
    sta (ZP_SCREEN_PTR), y
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
    sta (ZP_SCREEN_PTR), y         ; Store to screen
    
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
    pha                     ; Save it again to restore on return
    and #$0F
    jsr nibble_to_hex
    jsr write_char
    pla
    rts

; Output 16-bit address as 4 hex digits
; Address in ZP_DUMP_ADDR/ZP_DUMP_ADDR+1
; Uses: A, X
write_hex_addr:
    lda ZP_DUMP_ADDR + 1    ; High byte first
    jsr write_hex_byte
    lda ZP_DUMP_ADDR        ; Low byte
    jmp write_hex_byte      ; Tail call

; Write byte in A as decimal (0-255)
; Uses: A, X, Y
write_decimal_byte:
    ldx #0              ; Hundreds counter
    ldy #0              ; Tens counter
    
    ; Count hundreds
@hundreds:
    cmp #100
    bcc @tens_start
    sbc #100            ; A = A - 100
    inx                 ; Increment hundreds
    jmp @hundreds
    
@tens_start:
    ; Count tens
@tens:
    cmp #10
    bcc @output
    sbc #10             ; A = A - 10  
    iny                 ; Increment tens
    jmp @tens
    
@output:
    pha                 ; Save units digit
    
    ; Output hundreds (if non-zero)
    cpx #0
    beq @check_tens
    txa
    clc
    adc #'0'
    jsr write_char
    
@check_tens:
    ; Output tens (if hundreds printed or tens non-zero)
    cpx #0              ; Were hundreds printed?
    bne @print_tens     ; Yes, always print tens
    cpy #0              ; No hundreds, check if tens non-zero
    beq @print_units    ; Skip tens if zero
    
@print_tens:
    tya
    clc
    adc #'0'
    jsr write_char
    
@print_units:
    pla                 ; Restore units
    clc
    adc #'0'
    jsr write_char
    rts

; Main memory dump routine
; Outputs: $ADDR bytes...
dump_memory:
    ; Output '$'
    WriteChar '$'
    
    ; Output address
    jsr write_hex_addr
    
    ; Output data bytes
    ldy #0
    sty ZP_TEMP_DUMP_MEM
@dump_loop:
    WriteChar ' '

    ; Output byte
    ldy ZP_TEMP_DUMP_MEM
    lda (ZP_DUMP_ADDR), y
    jsr write_hex_byte
    
    ; Move to next byte
    inc ZP_TEMP_DUMP_MEM
    lda ZP_TEMP_DUMP_MEM
    cmp ZP_DUMP_COUNT
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
    jsr newline
    WriteString RomString
    WriteChar ' '
    WriteString DumpString

    ; Initialize list pointer and get count
    lda #<memory_address_list
    sta ZP_LIST_PTR
    lda #>memory_address_list
    sta ZP_LIST_PTR + 1
    
    ; Get address count
    ldy #0
    lda (ZP_LIST_PTR), y
    sta ZP_TEMP_DUMP_LIST
    
    ; Advance pointer past count byte
    inc ZP_LIST_PTR
    bne @setup_count
    inc ZP_LIST_PTR + 1
    
@setup_count:
    ; Set up dump count
    lda #DUMP_BYTES
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
    dec ZP_TEMP_DUMP_LIST
    bne @loop

    rts

; RAM page test routine
; Input: A = page number to test (high byte of address)
; Output: Carry clear = pass, Carry set = fail
; Uses: A, X, Y, ZP_PTR, ZP_TEMP_RAM_TEST
test_ram_page:
    ; Output which page is being tested, then reset write position to overwrite
    ; it
    cmp #$01
    beq @start              ; Don't output for stack page (no stack - can't jsr)
    jsr write_hex_byte
    dec ZP_COL
    dec ZP_COL

@start:
    ; Set up page address
    sta ZP_PTR + 1
    lda #0
    sta ZP_PTR
    
    ; Test 1: Walking 1s pattern
    ldx #8                  ; 8 bit positions
    lda #1
@walk1_loop:
    sta ZP_TEMP_RAM_TEST    ; Current test pattern
    ldy #0
@write1_loop:
    lda ZP_TEMP_RAM_TEST
    sta (ZP_PTR), y
    iny
    bne @write1_loop
    
    ; Verify pattern
    ldy #0
@read1_loop:
    lda (ZP_PTR), y
    cmp ZP_TEMP_RAM_TEST
    bne @fail
    iny
    bne @read1_loop
    
    ; Next bit position
    asl ZP_TEMP_RAM_TEST
    dex
    bne @walk1_loop
    
    ; Test 2: Walking 0s pattern  
    ldx #8
    lda #$FE
@walk0_loop:
    sta ZP_TEMP_RAM_TEST
    ldy #0
@write0_loop:
    lda ZP_TEMP_RAM_TEST
    sta (ZP_PTR), y
    iny
    bne @write0_loop
    
    ldy #0
@read0_loop:
    lda (ZP_PTR), y
    cmp ZP_TEMP_RAM_TEST
    bne @fail
    iny
    bne @read0_loop
    
    rol ZP_TEMP_RAM_TEST         ; Rotate 0 bit left
    dex
    bne @walk0_loop
    
    ; Test 3: Address-in-address pattern
    ldy #0
@write_addr_loop:
    tya
    sta (ZP_PTR), y
    iny
    bne @write_addr_loop
    
    ldy #0
@read_addr_loop:
    lda (ZP_PTR), y
    cmp (ZP_PTR), y     ; Compare with itself
    bne @fail
    tya
    cmp (ZP_PTR), y     ; Compare with expected value
    bne @fail
    iny
    bne @read_addr_loop
    
    ; All tests passed
    lda ZP_PTR + 1      ; Check which page we tested
    cmp #$01            ; Stack page?
    beq @stack_done     ; If stack, don't RTS

    clc
    rts
    
@fail:
    lda ZP_PTR + 1
    cmp #$01
    beq @stack_fail

    sec
    rts

@stack_done:
    jmp after_stack_test

@stack_fail:
    lda #'S'
    sta $8000
    lda #'P'
    sta $8001
    lda #' '
    sta $8002
    sta $8006
    lda #'E'
    sta $8003
    lda #'R'
    sta $8004
    sta $8005
    jmp final_loop

; Test all RAM and detect size
; Output: Carry clear = success, Carry set = failure
; Sets: ZP_RAM_SIZE ($08/$10/$20 for working KB, $00 if 8K fails)
;       ZP_FAILED_PAGE (first failed page, $00 if all passed)
test_all_ram:
    ; Initialize
    lda #$00
    sta ZP_RAM_SIZE
    sta ZP_FAILED_PAGE
    
    ; Test 8K base RAM (pages $02-$1F)
    lda #$02
@test_8k:
    jsr test_ram_page
    bcs @failed
    clc
    adc #1
    cmp #$20
    bne @test_8k
    
    ; 8K passed
    lda #$08
    sta ZP_RAM_SIZE
    
    ; Test 16K extension (pages $20-$3F)
    lda #$20
@test_16k:
    jsr test_ram_page
    bcs @failed
    clc
    adc #1
    cmp #$40
    bne @test_16k
    
    ; 16K passed
    lda #$10
    sta ZP_RAM_SIZE
    
    ; Test 32K extension (pages $40-$7F)
    lda #$40
@test_32k:
    jsr test_ram_page
    bcs @failed
    clc
    adc #1
    cmp #$80
    bne @test_32k
    
    ; 32K passed
    lda #$20
    sta ZP_RAM_SIZE
    
    ; All tests passed
    lda #$00
    sta ZP_FAILED_PAGE
    clc
    rts
    
@failed:
    ; Carry is already set if we get here
    sta ZP_FAILED_PAGE
    rts

; Zero page test routine
; Output: Carry clear = pass, Carry set = fail
; Uses only A, X, Y registers - no RAM/ZP/stack storage
test_zero_page:
    ; Test 1: Walking 1s pattern
    ldy #1              ; Start with bit 0 set
@walk1_outer:
    ; Write pattern Y to all of zero page
    ldx #0
@walk1_write:
    sty $00, x
    inx
    bne @walk1_write
    
    ; Verify pattern
    ldx #0
@walk1_read:
    tya                 ; Get test pattern into A
    cmp $00, x          ; Compare A with memory
    bne @fail
    inx
    bne @walk1_read
    
    ; Next bit position
    tya
    asl                 ; Shift left
    tay
    bcc @walk1_outer    ; Continue until bit 7 shifts out
    
    ; Test 2: Walking 0s pattern
    ldy #$FE            ; Start with bit 0 clear
@walk0_outer:
    ; Write pattern Y to all of zero page
    ldx #0
@walk0_write:
    sty $00, x
    inx
    bne @walk0_write
    
    ; Verify pattern  
    ldx #0
@walk0_read:
    tya                 ; Get test pattern into A
    cmp $00, x          ; Compare A with memory
    bne @fail
    inx
    bne @walk0_read
    
    ; Next bit position (rotate 0 left)
    tya
    rol
    tay
    cmp #$7F            ; Stop when we've done all 8 positions
    bne @walk0_outer
    
    ; Test 3: Address-in-address pattern
    ldx #0
@addr_write:
    txa                 ; Transfer X to A
    sta $00, x          ; Store A at address X
    inx
    bne @addr_write
    
    ldx #0
@addr_read:
    txa                 ; Get X into A
    cmp $00, x          ; Compare A with memory at X
    bne @fail
    inx
    bne @addr_read
    
    ; All tests passed
    clc
    jmp test_stack
    
@fail:
    sec
    lda #'Z'
    sta $8000
    lda #'P'
    sta $8001
    lda #' '
    sta $8002
    sta $8006
    lda #'E'
    sta $8003
    lda #'R'
    sta $8004
    sta $8005
    jmp final_loop


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