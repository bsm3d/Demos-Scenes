;===========================================================================
; BSM3D - Starfield Effect
; Amiga 68000 Assembly
; Author: Benoit (BSM3D) Saint-Moulin
; Amiga: Chipset OCS, 512KB Chip RAM, 512KB Fast RAM
;
; Development Note:
; I coded this using Visual Studio Code with Amiga Assembly extension
; and tested on WinUAE emulator with Kickstart 1.3 ROM.
; VSCode Extension: https://marketplace.visualstudio.com/items?itemName=prb28.amiga-assembly
; compatibility : ASM-One (also compatible with SEKA : https://zrk.dk/seka/ and DevPac)
;
; Technical Challenge:
; While HTML5 can use fillRect() for stars with any color, Amiga needs
; to work with bitplanes and use the Blitter for pixel plotting. 
; The original demo scene used different optimizations we don't use here.
;
; AI Note:
; As I dont program in 68000 assembly for many years, AI (Claude) 
; was used to verify and review the code for potential errors. This shows how 
; modern AI tools can help when returning to legacy programming after a long break.
;
; Historical Perspective:
; This assembly version requires bitplane manipulation where HTML5 offers simple 
; pixel operations. Each star must be manually plotted with the Blitter where
; HTML5 just uses a simple fillRect call.
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
COLOR01         EQU     $182

; Bitplane registers
BPLCON0         EQU     $100
BPLCON1         EQU     $102
BPL1PTH         EQU     $0e0
BPL1PTL         EQU     $0e2
DIWSTRT         EQU     $08e
DIWSTOP         EQU     $090
DDFSTRT         EQU     $092
DDFSTOP         EQU     $094

; Blitter registers
BLTCON0         EQU     $040
BLTCON1         EQU     $042
BLTAFWM         EQU     $044
BLTALWM         EQU     $046
BLTCPTH         EQU     $048
BLTCPTL         EQU     $04a
BLTBPTH         EQU     $04c
BLTBPTL         EQU     $04e
BLTAPTH         EQU     $050
BLTAPTL         EQU     $052
BLTDPTH         EQU     $054
BLTDPTL         EQU     $056
BLTSIZE         EQU     $058
BLTCMOD         EQU     $060
BLTBMOD         EQU     $062
BLTAMOD         EQU     $064
BLTDMOD         EQU     $066

; Constants
SCREEN_WIDTH    EQU     320
SCREEN_HEIGHT   EQU     256
NUM_LAYERS      EQU     5
STARS_PER_LAYER EQU     50
FIXED_SHIFT     EQU     8       ; 8.8 fixed point

Start:
        movem.l d0-a6,-(sp)     ; Save registers
        lea     CUSTOM,a6

        move.w  INTENAR(a6),-(sp)
        move.w  DMACONR(a6),-(sp)
        move.w  #$7FFF,INTENA(a6)
        move.w  #$7FFF,DMACON(a6)

        bsr     Init_Display
        bsr     Init_Copper
        bsr     Init_Stars
        
        move.w  #$8380,DMACON(a6)  ; Enable bitplane and blitter DMA

MainLoop:
        btst    #6,CUSTOM+VHPOSR   ; Wait for vertical blank
        beq.s   MainLoop

        bsr     Clear_Screen
        bsr     Update_Stars
        bsr     Draw_Stars

        btst    #6,$bfe001         ; Left mouse button to exit
        bne.s   MainLoop

Exit:
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
        move.w  #$2200,BPLCON0(a6) ; 1 bitplane
        move.w  #$0000,BPLCON1(a6)

        move.w  #$2c81,DIWSTRT(a6)
        move.w  #$2cc1,DIWSTOP(a6)
        move.w  #$0038,DDFSTRT(a6)
        move.w  #$00d0,DDFSTOP(a6)

        move.w  #$0000,COLOR00(a6) ; Black background
        move.w  #$0fff,COLOR01(a6) ; White stars
        rts

;===========================================================================
; Initialize copper
;===========================================================================
Init_Copper:
        lea     Copper_List(pc),a0
        move.l  a0,COP1LC(a6)
        move.w  #$0000,COPJMP1(a6)
        rts

;===========================================================================
; Initialize all stars
;===========================================================================
Init_Stars:
        lea     Stars_Data,a0
        moveq   #NUM_LAYERS-1,d7        ; Layer counter
.layer_loop:
        moveq   #STARS_PER_LAYER-1,d6   ; Stars per layer

.star_loop:
        ; Random X position (0 to SCREEN_WIDTH)
        bsr     Random
        and.w   #$01FF,d0               ; Mask to 0-511
        cmp.w   #SCREEN_WIDTH,d0
        bge.s   .star_loop
        move.w  d0,(a0)+                ; Store X

        ; Random Y position (0 to SCREEN_HEIGHT)
        bsr     Random
        and.w   #$00FF,d0               ; Mask to 0-255
        move.w  d0,(a0)+                ; Store Y

        ; Speed based on layer (fixed point)
        move.w  d7,d0
        addq.w  #1,d0
        mulu    #$20,d0                 ; Base speed * layer
        move.w  d0,(a0)+                ; Store speed

        dbf     d6,.star_loop
        dbf     d7,.layer_loop
        rts

;===========================================================================
; Update all star positions
;===========================================================================
Update_Stars:
        lea     Stars_Data,a0
        move.w  #(NUM_LAYERS*STARS_PER_LAYER)-1,d7

.loop:  
        ; Update X position
        move.w  4(a0),d0                ; Get speed
        add.w   d0,(a0)                 ; Add to X

        ; Check if off screen
        cmp.w   #SCREEN_WIDTH<<FIXED_SHIFT,(a0)
        blt.s   .no_reset

        ; Reset star to left of screen
        bsr     Random
        and.w   #$00FF,d0               ; Random Y (0-255)
        move.w  d0,2(a0)                ; Store new Y
        clr.w   (a0)                    ; Reset X to 0

.no_reset:
        addq.l  #6,a0                   ; Next star
        dbf     d7,.loop
        rts

;===========================================================================
; Draw all stars
;===========================================================================
Draw_Stars:
        lea     Stars_Data,a0
        move.w  #(NUM_LAYERS*STARS_PER_LAYER)-1,d7

.loop:  
        move.w  (a0),d0                 ; Get X
        asr.w   #FIXED_SHIFT,d0         ; Convert fixed point
        move.w  2(a0),d1                ; Get Y

        movem.l d7/a0,-(sp)
        bsr     Plot_Star
        movem.l (sp)+,d7/a0

        addq.l  #6,a0                   ; Next star
        dbf     d7,.loop
        rts

;===========================================================================
; Plot single star using Blitter
; D0 = X, D1 = Y
;===========================================================================
Plot_Star:
        movem.l d2-d6/a0-a1,-(sp)

        ; Calculate screen address
        mulu    #SCREEN_WIDTH/8,d1      ; Y offset
        move.w  d0,d2
        lsr.w   #3,d2                   ; X/8
        add.w   d2,d1                   ; Add to Y offset
        lea     Screen_Mem,a0
        add.w   d1,a0                   ; Final address

        ; Calculate bit position
        move.w  d0,d2
        and.w   #$0007,d2               ; X & 7
        moveq   #0,d3
        bset    d2,d3                   ; Create bit mask

        ; Set bit in screen memory
        or.b    d3,(a0)

        movem.l (sp)+,d2-d6/a0-a1
        rts

;===========================================================================
; Clear screen
;===========================================================================
Clear_Screen:
        lea     Screen_Mem,a0
        move.w  #(SCREEN_WIDTH/32*SCREEN_HEIGHT)-1,d0
.loop:  
        clr.l   (a0)+
        dbf     d0,.loop
        rts

;===========================================================================
; Simple random number generator
; Returns: D0 = random number
;===========================================================================
Random: 
        move.l  Rand_Seed,d0
        mulu    #16807,d0
        move.l  d0,Rand_Seed
        rts

;===========================================================================
; Data Section
;===========================================================================
        SECTION DATA,DATA_C

; Initial copper list
Copper_List:
        dc.w    BPLCON0,$2200
        dc.w    COLOR00,$0002    ; Very dark blue background
        dc.w    COLOR01,$0FFF    ; White stars
        dc.l    $FFFFFFFE

;===========================================================================
; BSS Section - Variables
;===========================================================================
        SECTION BSS,BSS_C

Stars_Data:
        ds.b    NUM_LAYERS*STARS_PER_LAYER*6  ; X,Y,Speed for each star
Rand_Seed:
        ds.l    1

;===========================================================================
; Chip Memory Section
;===========================================================================
        SECTION CHIP,DATA_C

Screen_Mem:
        ds.b    SCREEN_WIDTH/8*SCREEN_HEIGHT

;===========================================================================
; End of program
;===========================================================================


        END