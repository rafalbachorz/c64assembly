turns your previous one-shot HELLO, WORLD! print into a small real-time loop that redraws one screen row every frame with a changing X position.

## High-Level Flow

1. Program boots via BASIC stub, then jumps to main.
2. main initializes horizontal position (xpos = 40), meaning “start just off the right edge”.
3. Infinite loop:
* Wait for next frame (wait_frame).
* Clear one row and draw text at current xpos (render).
* Move left by 1 (dec xpos).
* When text has fully moved off left side, reset xpos to 40.
References: src/main.asm:15, src/main.asm:19.

## Startup / Constants

* *=$0801 and the !byte ... sequence is a BASIC loader line (equivalent to SYS 2062) so the machine code can be started from BASIC.
* txt = data points to string bytes generated in build resources.
* text_len = data_end - data - 1 subtracts the trailing @ terminator from generated data.
* row = 12 chooses vertical screen row.
* screen_row and color_row are base addresses for that row in screen RAM ($0400) and color RAM ($d800).
   
References: src/main.asm:5, src/main.asm:6, src/main.asm:9, src/main.asm:10, src/main.asm:11, src/main.asm:12, src/main.asm:13.

## Main Loop Details

* lda #40 / sta xpos: horizontal start position (column after visible 0..39 range).
* dec xpos: shifts left by 1 each frame.
* cmp #256 - text_len: uses 8-bit wrap behavior. After passing column 0, xpos underflows to 255, and once it reaches 256-text_len, text is fully off-screen, so it resets to 40.
  
References: src/main.asm:16, src/main.asm:17, src/main.asm:22, src/main.asm:24, src/main.asm:26, src/main.asm:27.

## wait_frame (including your selected wait_ff)
This routine throttles drawing to roughly once per video frame by watching raster register $d012.

* lda #$ff: load target raster line 255.
wait_ff: cmp $d012 / bne wait_ff: stay here until current raster line becomes 255.
* wait_next: cmp $d012 / beq wait_next: then wait until raster changes away from 255, guaranteeing a fresh frame edge.
* rts: return to render next frame.
So wait_ff is the first synchronization gate: “don’t proceed until raster reaches line 255”.

References: src/main.asm:30, src/main.asm:31, src/main.asm:32, src/main.asm:33, src/main.asm:34, src/main.asm:35, src/main.asm:36, src/main.asm:37.

## render Routine
Two phases:

1. Clear chosen row:
* Loop x = 0..39.
* Write space ($20) to screen row.
* Write color 1 (white) to color row.
2. Draw text:
* Loop y = 0..text_len-1.
* Compute screen X as xpos + y.
* If X is outside visible 0..39 (cmp #40 / bcs), skip drawing that character.
* Else load text byte, convert ASCII-ish source to C64 screen code by and #%00111111, and store to screen RAM at computed X.

References: src/main.asm:40, src/main.asm:42, src/main.asm:43, src/main.asm:44, src/main.asm:45, src/main.asm:46, src/main.asm:48, src/main.asm:51, src/main.asm:53, src/main.asm:57, src/main.asm:58, src/main.asm:59, src/main.asm:61, src/main.asm:62, src/main.asm:63.

## State Variable

* xpos is a single-byte variable storing current leftmost text column.
Reference: src/main.asm:70, src/main.asm:71.