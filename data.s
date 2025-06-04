; This file contains data for the project

; Copyright (c) 2025 Piers Finlayson <piers@piers.rocks>
;
; Licensed under the MIT License.  See [LICENSE] for details.

.include "macros.inc"
.include "constants.inc"

.export memory_address_list
.export AuthorString
.export ProgString

.segment "DATA"

CbmString AuthorString, "piers.rocks"
CbmString ProgString, "pet-diag-rom"

; Memory address list to dump - first byte is count
memory_address_list:
    .byte 6                 ; Number of addresses
    .word $E000
    .word $D000  
    .word $C000
    .word $B000
    .word $A000
    .word $9000