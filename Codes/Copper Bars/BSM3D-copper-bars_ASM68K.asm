;===========================================================================
; BSM3D - Copper Bars Effect
; Amiga 68000 Assembly
; Author: Benoit (BSM3D) Saint-Moulin
; Amiga: Chipset OCS, 512KB Chip RAM, 512KB Fast RAM
;
; Development Note:
; I'm coded this using Visual Studio Code with the Amiga Assembly extension
; and tested on WinUAE emulator with Kickstart 1.3 ROM.
; VSCode Extension: https://marketplace.visualstudio.com/items?itemName=prb28.amiga-assembly
; compatibility : ASM-One (also compatible with SEKA : https://zrk.dk/seka/ and DevPac)
;
; Technical Challenge:
; This is NOT a recreation of classic Amiga demo scene copper bars.
; This is a port of my HTML5 version to ASM68K, using Copper Coprocessor
; instead of HTML5 Canvas gradients. The Amiga Copper was specifically designed
; for these kind of effects, making it more efficient than modern equivalents.
;
; AI Note:
; As I dont program in 68000 assembly for many years, AI (Claude) 
; was used to verify and review the code for potential errors. This shows how 
; modern AI tools can help when returning to legacy programming after a long break.
;
; Historical Perspective:
; While this effect requires complex Canvas gradient manipulation in HTML5,
; the Amiga hardware was specifically designed for these color-changing effects
; through its Copper coprocessor. This demonstrates how specialized hardware
; sometimes offers more elegant solutions than modern generic approaches.
;===========================================================================

        SECTION CODE,CODE_C

;===========================================================================
; Hardware Registers
;===========================================================================
CUSTOM          EQU     $dff000
DMACON          EQU     $096
DMACONR         EQU     $002
INTENA          EQU     $09a
INTENAR         EQU     $01c
COP1LC          EQU     $080
COPJMP1         EQU     $088
COLOR00         EQU     $180
BPLCON0         EQU     $100
BPLCON1         EQU     $102
BPLCON2         EQU     $104
DIWSTRT         EQU     $08e
DIWSTOP         EQU     $090
DDFSTRT         EQU     $092
DDFSTOP         EQU     $094

; Constants
NUM_BARS        EQU     8           ; Number of color bars
BAR_HEIGHT      EQU     4           ; Height of each color step in scanlines
GRADIENT_STEPS  EQU     16          ; Number of gradient steps per bar
SCREEN_HEIGHT   EQU     256         ; PAL screen height
BAR_SPACING     EQU     SCREEN_HEIGHT/NUM_BARS

Start:
        movem.l d0-a6,-(sp)
        lea     CUSTOM,a6

        ; Save and disable interrupts
        move.w  INTENAR(a6),-(sp)
        move.w  DMACONR(a6),-(sp)
        move.w  #$7FFF,INTENA(a6)
        move.w  #$7FFF,DMACON(a6)

        bsr     Init_Display
        bsr     Init_Copper
        bsr     Init_Bars
        
        ; Enable DMA
        move.w  #$8280,DMACON(a6)   ; Enable Copper DMA

MainLoop:
        btst    #6,CUSTOM+VHPOSR    ; Wait for vertical blank
        beq.s   MainLoop

        bsr     Update_Colors        ; Update color cycling
        bsr     Update_Positions     ; Update bar positions

        btst    #6,$bfe001          ; Left mouse button to exit
        bne.s   MainLoop

Exit:
        ; Restore system state
        move.w  (sp)+,d0
        or.w    #$8000,d0
        move.w  d0,DMACON(a6)
        move.w  (sp)+,d0
        or.w    #$8000,d0
        move.w  d0,INTENA(a6)

        movem.l (sp)+,d0-a6
        moveq   #0,d0
        rts

;===========================================================================
; Initialize display system
;===========================================================================
Init_Display:
        move.w  #$1200,BPLCON0(a6)  ; Set display mode
        move.w  #$0000,BPLCON1(a6)
        move.w  #$0000,BPLCON2(a6)
        move.w  #$2c81,DIWSTRT(a6)  ; Set display window
        move.w  #$2cc1,DIWSTOP(a6)
        move.w  #$0038,DDFSTRT(a6)  ; Set display data fetch
        move.w  #$00d0,DDFSTOP(a6)
        rts

;===========================================================================
; Initialize Copper list and data structures
;===========================================================================
Init_Copper:
        lea     Copper_List,a0
        move.l  a0,COP1LC(a6)       ; Set copper list pointer
        move.w  #$0000,COPJMP1(a6)  ; Start copper
        rts

;===========================================================================
; Initialize bars data
;===========================================================================
Init_Bars:
        lea     Bar_Positions,a0
        lea     Bar_Colors,a1
        lea     Bar_Phases,a2
        moveq   #NUM_BARS-1,d7

.init_loop:
        ; Set initial Y position
        move.w  d7,d0
        mulu    #BAR_SPACING,d0
        move.w  d0,(a0)+

        ; Set initial color (rainbow spread)
        move.w  d7,d0
        mulu    #$0FFF/NUM_BARS,d0
        move.w  d0,(a1)+

        ; Set random phase
        move.w  d7,d0
        mulu    #256/NUM_BARS,d0
        move.w  d0,(a2)+

        dbf     d7,.init_loop
        rts

;===========================================================================
; Update color cycling for rainbow effect
;===========================================================================
Update_Colors:
        lea     Bar_Colors,a0
        moveq   #NUM_BARS-1,d7

.color_loop:
        move.w  (a0),d0
        addq.w  #1,d0                ; Increment color
        and.w   #$0FFF,d0            ; Keep in RGB12 range
        move.w  d0,(a0)+
        
        dbf     d7,.color_loop
        rts

;===========================================================================
; Update bar positions using sine table
;===========================================================================
Update_Positions:
        lea     Bar_Positions,a0
        lea     Bar_Phases,a1
        moveq   #NUM_BARS-1,d7

.pos_loop:
        ; Update phase
        move.w  (a1),d0
        addq.w  #2,d0                ; Speed of movement
        and.w   #$FF,d0              ; Wrap around 256 values
        move.w  d0,(a1)+

        ; Get sine value
        add.w   d0,d0                ; Word offset into table
        lea     SineTable,a2
        move.w  (a2,d0.w),d1         ; Get sine value
        
        ; Scale to screen position
        asr.w   #4,d1                ; Scale down sine value
        add.w   #SCREEN_HEIGHT/2,d1  ; Center on screen
        move.w  d1,(a0)+             ; Store new position

        dbf     d7,.pos_loop

        bsr     Update_Copper_List
        rts

;===========================================================================
; Update copper list with current positions and colors
;===========================================================================
Update_Copper_List:
        lea     Copper_List,a0
        lea     Bar_Positions,a1
        lea     Bar_Colors,a2
        moveq   #NUM_BARS-1,d7

.bar_loop:
        move.w  (a1)+,d2             ; Get bar Y position
        move.w  (a2)+,d3             ; Get base color
        moveq   #GRADIENT_STEPS-1,d6

        ; Create gradient effect
.gradient_loop:
        ; Wait for line position
        move.w  d2,(a0)              ; Y position
        move.w  #$FFFE,2(a0)         ; Wait for line
        
        ; Set color
        move.w  #COLOR00,4(a0)       ; Color register
        move.w  d3,6(a0)             ; Color value

        ; Calculate next gradient step
        move.w  d3,d0
        lsr.w   #4,d0                ; Reduce intensity for gradient
        sub.w   d0,d3                ; Darken color

        addq.w  #1,d2                ; Next scanline
        addq.l  #8,a0                ; Next copper instruction
        
        dbf     d6,.gradient_loop
        
        dbf     d7,.bar_loop

        ; End of copper list
        move.l  #$FFFFFFFE,(a0)
        rts

;===========================================================================
; Data Section
;===========================================================================
        SECTION DATA,DATA_C

; Pre-calculated sine table (0-255 values scaled to screen coordinates)
SineTable:
        dc.w    0,3,6,9,12,15,18,21,24,27,30,33,36,39,42,45
        dc.w    48,51,54,57,60,63,66,69,71,74,77,79,82,85,87,90
        dc.w    92,94,97,99,101,103,106,108,110,112,114,115,117,119,120,122
        dc.w    123,125,126,127,128,129,130,131,132,133,134,134,135,135,136,136
        dc.w    136,136,136,136,136,136,135,135,134,134,133,132,131,130,129,128
        dc.w    127,126,125,123,122,120,119,117,115,114,112,110,108,106,103,101
        dc.w    99,97,94,92,90,87,85,82,79,77,74,71,69,66,63,60
        dc.w    57,54,51,48,45,42,39,36,33,30,27,24,21,18,15,12
        dc.w    9,6,3,0,-3,-6,-9,-12,-15,-18,-21,-24,-27,-30,-33,-36
        dc.w    -39,-42,-45,-48,-51,-54,-57,-60,-63,-66,-69,-71,-74,-77,-79,-82
        dc.w    -85,-87,-90,-92,-94,-97,-99,-101,-103,-106,-108,-110,-112,-114,-115,-117
        dc.w    -119,-120,-122,-123,-125,-126,-127,-128,-129,-130,-131,-132,-133,-134,-134,-135
        dc.w    -135,-136,-136,-136,-136,-136,-136,-136,-136,-135,-135,-134,-134,-133,-132,-131
        dc.w    -130,-129,-128,-127,-126,-125,-123,-122,-120,-119,-117,-115,-114,-112,-110,-108
        dc.w    -106,-103,-101,-99,-97,-94,-92,-90,-87,-85,-82,-79,-77,-74,-71,-69
        dc.w    -66,-63,-60,-57,-54,-51,-48,-45,-42,-39,-36,-33,-30,-27,-24,-21
        dc.w    -18,-15,-12,-9,-6,-3

;===========================================================================
; Initial copper list structure (updated in real-time)
;===========================================================================
        SECTION CHIP,DATA_C          ; Must be in chip memory!

Copper_List:
        ; Space for copper instructions (NUM_BARS * GRADIENT_STEPS * 8 bytes each + 4 for end)
        dcb.b   NUM_BARS*GRADIENT_STEPS*8,0
        dc.l    $FFFFFFFE            ; End of copper list

;===========================================================================
; BSS Section - Variables
;===========================================================================
        SECTION BSS,BSS_C

Bar_Positions:   ds.w    NUM_BARS    ; Current Y positions
Bar_Colors:      ds.w    NUM_BARS    ; Current colors
Bar_Phases:      ds.w    NUM_BARS    ; Current movement phases

;===========================================================================
; End of program
;===========================================================================

        END
