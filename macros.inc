; This file contains macros used by the project.

; Copyright (c) 2025 Piers Finlayson <piers@piers.rocks>
;
; Licensed under the MIT License.  See [LICENSE] for details.

; Helper macro for Commodore-style strings, which are terminated with the last
; byte having the high bit set.  Saves us a byte and is slightly easier to
; test when the string terminates.
.macro CbmString label, str
    label:
    .repeat .strlen(str)-1, i
        .byte .strat(str, i)
    .endrepeat
    .byte .strat(str, .strlen(str)-1) | $80
.endmacro

; Macro to write a string to the screen at the current position.
.macro WriteString str_label
    lda #<str_label
    sta ZP_STR_PTR
    lda #>str_label
    sta ZP_STR_PTR + 1
    jsr write_string
.endmacro

; Macro to write a character to the screen at the current position.
.macro WriteChar char
    lda #char
    jsr write_char
.endmacro