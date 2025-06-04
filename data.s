; This file contains data for the project

; Copyright (c) 2025 Piers Finlayson <piers@piers.rocks>
;
; Licensed under the MIT License.  See [LICENSE] for details.

.include "macros.inc"
.include "constants.inc"

.export memory_address_list
.export AuthorString, DashString, ProgString, ZeroString, StackString
.export PageString, RamString, TestString, TestingString, PassedString
.export FailedString, CompleteString, DetectedString, KbString, RomString
.export DumpString

.segment "DATA"

CbmString AuthorString, "PIERS.ROCKS"
CbmString DashString, " - "
CbmString ProgString, "PET DIAGNOSTICS ROM"
CbmString ZeroString, "ZERO"
CbmString StackString, "STACK"
CbmString PageString, "PAGE"
CbmString RamString, "RAM"
CbmString TestString, "TEST"
CbmString TestingString, "TESTING"
CbmString PassedString, "PASSED"
CbmString FailedString, "FAILED"
CbmString CompleteString, "COMPLETE"
CbmString DetectedString, "DETECTED"
CbmString KbString, "KB"
CbmString RomString, "ROM"
CbmString DumpString, "DUMP"

; Memory address list to dump - first byte is count
memory_address_list:
    .byte 6                 ; Number of addresses
    .word $E000
    .word $D000  
    .word $C000
    .word $B000
    .word $A000
    .word $9000