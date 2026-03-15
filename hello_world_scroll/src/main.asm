;
; Hello, world!
;

*=$0801
!byte $0c,$08,$b5,$07,$9e,$20,$32,$30,$36,$32,$00,$00,$00
jmp main                  ; JMP = JuMP to label (unconditional)

!set txt = data
!set text_len = data_end - data - 1         ; generated data has '@' terminator
; this is expressed as integer, -1 because of the '@' terminator in generated data
!set row = 2
!set screen_row = $0400 + row * 40
; start of screen memory is $0400, each row is 40 bytes, so we can calculate the address for the current row
!set color_row = $d800 + row * 40
; start of color memory is $d800, each row is 40 bytes, so we can calculate the address for the current row

main
; Initialize the X position for the text
    lda #40                 ; LDA = LoaD Accumulator (A) with an immediate value
; We start with 40 because the text will scroll left, and we want it to start just off the right edge of the screen
    sta xpos                ; STA = STore Accumulator (A) into memory

loop
; Main loop: wait for the next frame, render the text, update the position, and repeat
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
; Wait for the next frame by synchronizing with the raster beam
    lda #$ff                ; LDA = LoaD Accumulator (A) with an immediate value
wait_ff
    cmp $d012               ; CMP = CoMPare A with value from memory
    ; The $d012 register contains the current raster line. By waiting until it reaches a certain value, we can synchronize our code to run at a specific point in the screen refresh cycle. This is important for smooth animation and to avoid visual artifacts.
    bne wait_ff             ; BNE = Branch if Not Equal (Z flag clear)
    ; Now we are at the desired raster line, we can proceed with rendering the text. This ensures that our updates to the screen memory happen at the right time, resulting in smoother animation.
wait_next
    cmp $d012               ; CMP = CoMPare A with value from memory
    ; After rendering, we wait until the raster line moves past the point where we started waiting. This prevents us from accidentally running our code multiple times within the same frame if the raster line happens to be at the right position when we start waiting.
    beq wait_next           ; BEQ = Branch if EQual (Z flag set)
    rts                     ; RTS = ReTurn from Subroutine

render
    ldx #0                  ; LDX = LoaD X register
    ; First, we clear the row where the text will be displayed. This ensures that any previous text is removed before we draw the new frame. We do this by writing spaces (ASCII code 32) to the screen memory and setting the color memory to a default value (1 in this case).
clear_row
    ; The $20 value corresponds to the ASCII code for a space character. By writing this to the screen memory, we effectively clear any existing characters in that row. This is important for creating a clean slate for our new text to be drawn on each frame.
    lda #$20                ; LDA = LoaD Accumulator (A) with an immediate value
    ; Setting the color memory to 1 gives us a default color for the text. The color memory controls the foreground and background colors of the characters on the screen. By setting it to a specific value, we can ensure that our text is displayed in a consistent color throughout the animation. This is especially important if we want to create a visually appealing effect or if we want to differentiate our text from other elements on the screen.
    sta screen_row,x        ; STA = STore Accumulator (A) into indexed memory
    ; By incrementing the X register, we move to the next position in the row. We repeat this process until we have cleared all 40 positions in the row. This loop ensures that the entire row is cleared before we start drawing our text, which helps to prevent any visual artifacts from previous frames.
    lda #1                  ; LDA = LoaD Accumulator (A) with an immediate value
    ; By writing to the color memory, we can control the appearance of our text. In this case, setting it to 1 might correspond to a specific color (e.g., white on black), depending on the color palette of the Commodore 64. This allows us to enhance the visual presentation of our text and make it stand out against the background.
    sta color_row,x         ; STA = STore Accumulator (A) into indexed memory
    ; After clearing the row, we can proceed to draw the text. We use the X register to keep track of our horizontal position on the screen, and we will increment it as we draw each character. The Y register will be used to index through the characters in our text string.
    inx                     ; INX = INcrement X register by 1
    ; We check if we have reached the end of the row (40 characters). If we have, we stop clearing and move on to drawing the text. This ensures that we only clear the portion of the screen where our text will be displayed, which can help improve performance and reduce flickering.
    cpx #40                 ; CPX = ComPare X register with value
    ; If the X register is not equal to 40, we continue clearing the row. This loop will run until we have cleared all 40 positions in the row, ensuring that the entire area where our text will be displayed is clean and ready for the new frame.
    bne clear_row           ; BNE = Branch if Not Equal (Z flag clear)

    ldy #0                  ; LDY = LoaD Y register
    ; Now we will draw the text character by character. We will use the Y register to index through our text string, and the X register to determine where on the screen to draw each character. We will continue this process until we have drawn all characters in our text string.
draw_text
    cpy #text_len           ; CPY = ComPare Y register with value
    ; By comparing the Y register with the length of our text string, we can determine when we have finished drawing all characters. If the Y register is equal to the length of the text, it means we have drawn all characters and we can exit the loop. This check is crucial for preventing us from trying to access memory beyond the end of our text string, which could lead to unintended behavior or crashes.
    beq draw_done           ; BEQ = Branch if EQual (Z flag set)
    ; To draw each character, we first calculate its position on the screen based on the current X and Y values. We then load the character from our text string, mask it to fit within the screen code range, and store it in the appropriate position in the screen memory. This process is repeated for each character in our text string until we have drawn the entire message.
    tya                     ; TYA = Transfer Y to A
    ; clc - Before we add the X position to the Y index, we need to clear the carry flag to ensure that the addition is performed correctly. The ADC instruction will add the value of the X register to the Y index, along with any carry from previous operations. By clearing the carry flag beforehand, we can ensure that we are only adding the X position and not any unintended carry from previous calculations. This is important for accurately calculating the position of each character on the screen, especially as the text scrolls left and the X position changes over time.
    clc                     ; CLC = CLear Carry flag
    ; The carry flag () in Commodore 64 (6502/6510) assembly is a 1-bit status flag in the Processor Status Register, used to indicate if an arithmetic operation has exceeded 8-bit capacity (or). It acts as a "carry" for additions and a "borrow" indicator for subtractions, essential for multibyte arithmetic and comparisons.
    adc xpos                ; ADC = ADd with Carry (A = A + value + carry)
    ; By adding the X position to the Y index, we can calculate the correct position on the screen where each character should be drawn. The X position determines how far from the left edge of the screen the text will start, while the Y index allows us to access each character in our text string sequentially. This combination of X and Y values allows us to create a scrolling effect as the text moves left across the screen.
    cmp #40                 ; CMP = CoMPare A with value (sets flags, does not store)
    ; After calculating the position for the current character, we check if it exceeds the width of the screen (40 characters). If it does (meaning the carry flag is set), we skip drawing this character and move on to the next one. This is important for ensuring that we do not attempt to write characters beyond the right edge of the screen, which could lead to visual artifacts or unintended behavior. By skipping characters that would be off-screen, we can maintain a clean and visually appealing display as the text scrolls.
    bcs draw_skip           ; BCS = Branch if Carry Set (unsigned higher or equal)
    ; If the character is within the visible area of the screen, we proceed to draw it. We load the character from our text string using the Y index, mask it to fit within the screen code range (since the Commodore 64 uses a specific encoding for characters), and then store it in the appropriate position in the screen memory. This process is repeated for each character in our text string until we have drawn the entire message.
    tax                     ; TAX = Transfer A to X
    lda txt,y               ; LDA = LoaD Accumulator (A) from indexed memory
    and #%00111111          ; AND = bitwise AND (mask ASCII into screen-code range)
    ; The Commodore 64 uses a specific encoding for characters on the screen, where the ASCII values are masked to fit within a certain range (0-63) to correspond to the character set in the screen memory. By performing a bitwise AND with the value #%00111111, we effectively convert our ASCII character into the appropriate screen code that can be displayed on the screen. This is crucial for ensuring that our text is rendered correctly and appears as intended when drawn on the screen.
    sta screen_row,x        ; STA = STore Accumulator (A) into indexed memory, here the drawing takes place by writing the character to the screen memory at the calculated position. The X register determines the horizontal position, while the Y index allows us to access each character in our text string sequentially. By storing the masked character in the screen memory, we can ensure that it is displayed correctly on the screen as part of our scrolling text animation.
    ; After drawing the character, we increment the Y index to move to the next character in our text string and repeat the process until we have drawn all characters. This loop allows us to create a smooth scrolling effect as the text moves left across the screen, with each character being drawn in its correct position based on the current X and Y values. By carefully managing the X and Y indices, we can ensure that our text is displayed correctly and creates an engaging visual effect as it scrolls across the screen.
    iny                     ; INY = INcrement Y register by 1
    jmp draw_text           ; JMP = JuMP to label (unconditional)
draw_skip
    iny                     ; INY = INcrement Y register by 1
    jmp draw_text           ; JMP = JuMP to label (unconditional)
draw_done
    rts                     ; RTS = ReTurn from Subroutine

xpos
    !byte 40
    ; The xpos variable is initialized to 40, which means that the text will start just off the right edge of the screen. As the text scrolls left, we will decrement this value to move the text across the screen. When xpos reaches a certain point (256 - text_len), we reset it back to 40 to create a continuous scrolling effect. This allows us to create a smooth animation where the text appears to scroll from right to left across the screen, giving it a dynamic and engaging visual presentation.

!src "src/include.asm"
