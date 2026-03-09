;
; Hello, world!
;

*=$0801
!byte $0c,$08,$b5,$07,$9e,$20,$32,$30,$36,$32,$00,$00,$00
jmp main                  ; JMP = JuMP to label (unconditional)

!set txt = data
!set text_len = data_end - data - 1         ; generated data has '@' terminator
!set row = 2
!set screen_row = $0400 + row * 40
!set color_row = $d800 + row * 40

main
    lda #40                 ; LDA = LoaD Accumulator (A) with an immediate value
    sta xpos                ; STA = STore Accumulator (A) into memory

loop
    jsr wait_frame          ; JSR = Jump to SubRoutine (call)
    jsr render              ; JSR = Jump to SubRoutine (call)
    dec xpos                ; DEC = DECrement memory by 1
    lda xpos                ; LDA = LoaD Accumulator (A) from memory
    cmp #256 - text_len     ; CMP = CoMPare A with value (sets flags, does not store)
    bne loop                ; BNE = Branch if Not Equal (Z flag clear)
    lda #40                 ; LDA = LoaD Accumulator (A) with an immediate value
    sta xpos                ; STA = STore Accumulator (A) into memory
    jmp loop                ; JMP = JuMP to label (unconditional)

wait_frame
    lda #$ff                ; LDA = LoaD Accumulator (A) with an immediate value
wait_ff
    cmp $d012               ; CMP = CoMPare A with value from memory
    bne wait_ff             ; BNE = Branch if Not Equal (Z flag clear)
wait_next
    cmp $d012               ; CMP = CoMPare A with value from memory
    beq wait_next           ; BEQ = Branch if EQual (Z flag set)
    rts                     ; RTS = ReTurn from Subroutine

render
    ldx #0                  ; LDX = LoaD X register
clear_row
    lda #$20                ; LDA = LoaD Accumulator (A) with an immediate value
    sta screen_row,x        ; STA = STore Accumulator (A) into indexed memory
    lda #1                  ; LDA = LoaD Accumulator (A) with an immediate value
    sta color_row,x         ; STA = STore Accumulator (A) into indexed memory
    inx                     ; INX = INcrement X register by 1
    cpx #40                 ; CPX = ComPare X register with value
    bne clear_row           ; BNE = Branch if Not Equal (Z flag clear)

    ldy #0                  ; LDY = LoaD Y register
draw_text
    cpy #text_len           ; CPY = ComPare Y register with value
    beq draw_done           ; BEQ = Branch if EQual (Z flag set)
    tya                     ; TYA = Transfer Y to A
    clc                     ; CLC = CLear Carry flag
    adc xpos                ; ADC = ADd with Carry (A = A + value + carry)
    cmp #40                 ; CMP = CoMPare A with value (sets flags, does not store)
    bcs draw_skip           ; BCS = Branch if Carry Set
    tax                     ; TAX = Transfer A to X
    lda txt,y               ; LDA = LoaD Accumulator (A) from indexed memory
    and #%00111111          ; AND = bitwise AND (mask ASCII into screen-code range)
    sta screen_row,x        ; STA = STore Accumulator (A) into indexed memory
draw_skip
    iny                     ; INY = INcrement Y register by 1
    jmp draw_text           ; JMP = JuMP to label (unconditional)
draw_done
    rts                     ; RTS = ReTurn from Subroutine

xpos
    !byte 40

!src "src/include.asm"
