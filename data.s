; This file contains data for the project

; Copyright (c) 2025 Piers Finlayson <piers@piers.rocks>
;
; Licensed under the MIT License.  See [LICENSE] for details.

.include "macros.inc"
.include "constants.inc"

.export memory_address_list
.export AuthorString, DashString, ProgString, ZeroPageString, TestString
.export PassedString, FinishedString

.segment "DATA"

CbmString AuthorString, "PIERS.ROCKS"
CbmString DashString, " - "
CbmString ProgString, "PET DIAGNOSTICS ROM"
CbmString ZeroPageString, "ZEROPAGE"
CbmString TestString, "TEST"
CbmString PassedString, "PASSED"
CbmString FinishedString, "FINISHED"

; Memory address list to dump - first byte is count
memory_address_list:
    .byte 6                 ; Number of addresses
    .word $E000
    .word $D000  
    .word $C000
    .word $B000
    .word $A000
    .word $9000