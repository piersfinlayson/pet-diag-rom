; This file contains constants for the project

; Copyright (c) 2025 Piers Finlayson <piers@piers.rocks>
;
; Licensed under the MIT License.  See [LICENSE] for details.

; Location of the screen RAM in memory
SCREEN_RAM = $8000

; Screen dimensions
SCREEN_COLS = 40
SCREEN_ROWS = 24

; Number of bytes to dump from each address
DUMP_BYTES = 8

; Pointer to current screen position
ZP_SCREEN_PTR = $00

; Column to write string to
ZP_COL = $02

; Line to write string to
ZP_LINE = $03

; Two byte pointer to a string
ZP_STR_PTR = $04

; Two byte address to dump from
ZP_DUMP_ADDR = $06

; Number of bytes to dump
ZP_DUMP_COUNT = $08

; Two byte pointer to current address in list
ZP_LIST_PTR = $0A

; Temporary storage for dump routine
ZP_TEMP_DUMP_LIST = $0C

; Temporary storage for dump routine
ZP_TEMP_DUMP_MEM = $0D