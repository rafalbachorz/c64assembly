;===========================
;COLOUR SPLITTING USING $D012
;===========================

;!TO "COLOURSPLIT1.PRG",CBM

    *=$0801
   !byte $0c,$08,$b5,$07,$9e,$20,$32,$30,$36,$32,$00,$00,$00
   ;jmp MAIN

    SEI
MAIN

    LDA #$30
    LDX #$00 ;BLACK
RASTER1 
    CMP $D012
    BNE RASTER1
    STX $D020 ;ASSIGN BLACK TO
    STX $D021 ;BORDER AND FRAME
    LDA #$A8
    LDX #$01 ;WHITE
RASTER2 
    CMP $D012
    BNE RASTER2
    STX $D020
    STX $D021
    JMP MAIN