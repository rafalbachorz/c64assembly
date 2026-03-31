;===========================
;COLOUR SPLITTING USING $D012
;===========================

;!TO "COLOURSPLIT1.PRG",CBM

    *=$0801                                      ; Assemble program start at BASIC start address.
   !byte $0c,$08,$b5,$07,$9e,$20,$32,$30,$36,$32,$00,$00,$00 ; BASIC SYS line to jump into machine code.

    SEI                                          ; Disable maskable IRQs while installing custom handler.

    ; Install our IRQ vector.
    LDA #<IRQ                                    ; Load low byte of IRQ routine address.
    STA $0314                                    ; Store low byte into system IRQ vector low location.
    LDA #>IRQ                                    ; Load high byte of IRQ routine address.
    STA $0315                                    ; Store high byte into system IRQ vector high location.

    ; Disable/clear CIA IRQs so raster IRQ drives timing.
    LDA #$7F                                     ; Bit mask for "disable all CIA IRQ sources" command.
    STA $DC0D                                    ; Disable CIA1 IRQ sources.
    STA $DD0D                                    ; Disable CIA2 IRQ sources.
    LDA $DC0D                                    ; Read CIA1 ICR to clear any pending CIA1 interrupt flags.
    LDA $DD0D                                    ; Read CIA2 ICR to clear any pending CIA2 interrupt flags.

    ; Screen on, high raster bit = 0.
    LDA #$1B                                     ; Set normal text mode and clear raster high bit.
    STA $D011                                    ; Write VIC control register 1.

    ; First raster line for IRQ stage 0.
    LDA #$32                                     ; Select raster line 50 for first IRQ trigger.
    STA $D012                                    ; Program VIC raster compare register.

    ; Enable raster IRQ source.
    LDA #$01                                     ; Enable bit 0 (raster IRQ) in VIC interrupt-enable register.
    STA $D01A                                    ; Activate VIC raster IRQ generation.

    LDA #$00                                     ; Set initial stage index to stage 0.
    STA STAGE                                    ; Store current IRQ stage state.

    CLI                                          ; Re-enable maskable IRQs so raster interrupts can fire.

HOLD                                             ; Main loop label (CPU waits here between IRQs).
    JMP HOLD                                     ; Infinite loop; all visible work happens in IRQ.

IRQ                                              ; Custom IRQ routine entry point.
    ; Preserve registers used by the handler.
    PHA                                          ; Push A to stack.
    TXA                                          ; Copy X into A so X can be saved.
    PHA                                          ; Push original X value (now in A) to stack.
    TYA                                          ; Copy Y into A so Y can be saved.
    PHA                                          ; Push original Y value (now in A) to stack.

    ; Acknowledge VIC raster IRQ (bit 0).
    LDA #$01                                     ; Prepare raster IRQ acknowledge mask.
    STA $D019                                    ; Clear VIC raster IRQ flag so next IRQ can occur.

    LDA STAGE                                    ; Read current stage selector.
    BEQ IRQ_STAGE0                               ; If STAGE is 0, branch to first split handler.
    CMP #$01                                     ; Compare STAGE against 1.
    BEQ IRQ_STAGE1                               ; If STAGE is 1, branch to second split handler.

IRQ_STAGE2                                       ; Third stage handler (used when STAGE == 2).
    ; Third split: blue, schedule next frame's first split.
    LDA #$06                                     ; Blue background color value.
    STA $D021                                    ; Apply new background color.
    LDA #$32                                     ; Next IRQ line: 50 (start of next frame sequence).
    STA $D012                                    ; Program next raster compare line.
    LDA #$00                                     ; Reset stage counter to stage 0.
    STA STAGE                                    ; Store updated stage value.
    JMP IRQ_DONE                                 ; Skip remaining stage handlers.

IRQ_STAGE0                                       ; First stage handler (STAGE == 0).
    ; First split: red.
    LDA #$02                                     ; Red background color value.
    STA $D021                                    ; Apply new background color.
    LDA #$78                                     ; Next IRQ line: 120.
    STA $D012                                    ; Program next raster compare line.
    LDA #$01                                     ; Advance stage counter to stage 1.
    STA STAGE                                    ; Store updated stage value.
    JMP IRQ_DONE                                 ; Skip remaining stage handlers.

IRQ_STAGE1                                       ; Second stage handler (STAGE == 1).
    ; Second split: light blue.
    LDA #$0E                                     ; Light blue background color value.
    STA $D021                                    ; Apply new background color.
    LDA #$C8                                     ; Next IRQ line: 200.
    STA $D012                                    ; Program next raster compare line.
    LDA #$02                                     ; Advance stage counter to stage 2.
    STA STAGE                                    ; Store updated stage value.

IRQ_DONE                                         ; Common IRQ exit path.
    PLA                                          ; Restore original Y value into A.
    TAY                                          ; Transfer restored Y back into Y register.
    PLA                                          ; Restore original X value into A.
    TAX                                          ; Transfer restored X back into X register.
    PLA                                          ; Restore original A value into A register.
    JMP $EA7E                                    ; Chain to KERNAL IRQ tail (normal system IRQ exit).

STAGE                                            ; State variable used to rotate IRQ stages.
    !byte $00                                    ; Initial/default stage value storage byte.