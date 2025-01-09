;===========================================================================
; BSM3D - Simple Boing Ball Effect
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
; This is NOT a recreation of the original Amiga Boing Ball demo.
; This is a port of my HTML5 version to ASM68K, using a single sprite frame
; + rotation, where the original Boing Ball used 32 pre-rendered frames
; for smoother animation and better visual quality.
;
; AI Note:
; As I dont program in 68000 assembly for many years, AI (GitHub Copilot) 
; was used to verify and review the code for potential errors. This shows how 
; modern AI tools can help when returning to legacy programming after a long break.
;
; Historical Perspective:
; This assembly version is significantly longer than its HTML5 counterpart, 
; illustrating the evolution of 3D graphics programming. What can now be achieved
; in a few lines of high-level code using modern APIs and hardware acceleration
; required extensive low-level programming in the Amiga era.
;
; all had to be manually implemented on the Amiga. This code serves as a testament
; to the ingenuity of early demo scene programmers who created impressive 3D
; graphics despite these limitations.
;
;===========================================================================

        SECTION CODE,CODE_C

;===========================================================================
; Hardware Registers
;===========================================================================
CUSTOM          EQU     $dff000
; DMA Control
DMACON          EQU     $096
DMACONR         EQU     $002

; Interrupt Control
INTENA          EQU     $09a
INTENAR         EQU     $01c
INTREQ          EQU     $09c
INTREQR         EQU     $01e

; Copper Control
COP1LC          EQU     $080
COPJMP1         EQU     $088

; Sprite Registers
SPR0PTH         EQU     $120    ; Sprite 0 pointer (high)
SPR0PTL         EQU     $122    ; Sprite 0 pointer (low)
SPR1PTH         EQU     $124    ; Sprite 1 pointer (high)
SPR1PTL         EQU     $126    ; Sprite 1 pointer (low)
SPR0POS         EQU     $140    ; Sprite 0 position
SPR0CTL         EQU     $142    ; Sprite 0 control
SPR1POS         EQU     $148    ; Sprite 1 position
SPR1CTL         EQU     $14A    ; Sprite 1 control

; Bitplane Control
BPLCON0         EQU     $100
BPLCON1         EQU     $102
BPLCON2         EQU     $104
DIWSTRT         EQU     $08e
DIWSTOP         EQU     $090
DDFSTRT         EQU     $092
DDFSTOP         EQU     $094

; Color Registers
COLOR00         EQU     $180    ; Background
COLOR01         EQU     $182    ; Grid color
COLOR17         EQU     $1A2    ; Sprite 0 color 1
COLOR18         EQU     $1A4    ; Sprite 0 color 2
COLOR19         EQU     $1A6    ; Sprite 0 color 3

; Screen Dimensions
SCREEN_WIDTH    EQU     320
SCREEN_HEIGHT   EQU     256
BALL_SIZE       EQU     32

; Physics Constants (Fixed Point 8.8)
GRAVITY         EQU     $0020   ; 0.125 pixels per frame squared
BOUNCE_DAMP     EQU     $00F0   ; 0.94 bounce damping
MAX_VELOCITY    EQU     $0400   ; Maximum velocity

Start:
        movem.l d0-a6,-(sp)
        lea     CUSTOM,a6

        ; Save and disable interrupts/DMA
        move.w  INTENAR(a6),-(sp)
        move.w  DMACONR(a6),-(sp)
        move.w  #$7FFF,INTENA(a6)
        move.w  #$7FFF,DMACON(a6)

        bsr     Init_Display
        bsr     Init_Copper
        bsr     Init_Ball

        ; Enable DMA
        move.w  #$8380,DMACON(a6)    ; Enable sprite & copper DMA

        ; Initialize ball state
        move.w  #160,Ball_X          ; Center X
        move.w  #50,Ball_Y           ; Start near top
        clr.l   Ball_VelY            ; Zero initial velocity
        clr.w   Ball_Rotation        ; Zero rotation

MainLoop:
        btst    #6,CUSTOM+VHPOSR     ; Wait for vertical blank
        beq.s   MainLoop

        bsr     Update_Ball
        bsr     Update_Grid
        bsr     Update_Shadow

        btst    #6,$bfe001           ; Left mouse button exit
        bne.s   MainLoop

Exit:
        ; Restore old state
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
        ; Set screen parameters
        move.w  #$2C81,DIWSTRT(a6)   ; Display window start
        move.w  #$2CC1,DIWSTOP(a6)   ; Display window stop
        move.w  #$0038,DDFSTRT(a6)   ; Display data fetch start
        move.w  #$00D0,DDFSTOP(a6)   ; Display data fetch stop

        ; Set display mode
        move.w  #$1200,BPLCON0(a6)   ; Enable sprites
        move.w  #$0000,BPLCON1(a6)   ; No scroll
        move.w  #$0024,BPLCON2(a6)   ; Sprite priorities

        ; Set colors
        move.w  #$0A8B,COLOR00(a6)   ; Background gray
        move.w  #$0F00,COLOR17(a6)   ; Red for ball
        move.w  #$0FFF,COLOR18(a6)   ; White for ball
        move.w  #$0444,COLOR19(a6)   ; Shadow gray
        rts

;===========================================================================
; Initialize Copper
;===========================================================================
Init_Copper:
        ; Set copper list pointer
        lea     Copper_List(pc),a0
        move.l  a0,COP1LC(a6)
        move.w  #$0000,COPJMP1(a6)   ; Start copper
        rts

;===========================================================================
; Initialize ball and shadow sprites
;===========================================================================
Init_Ball:
        ; Set up sprite 0 for ball
        lea     Ball_Data(pc),a0
        move.l  a0,SPR0PTH(a6)

        ; Set up sprite 1 for shadow
        lea     Shadow_Data(pc),a0
        move.l  a0,SPR1PTH(a6)
        rts

;===========================================================================
; Update ball physics and position
;===========================================================================
Update_Ball:
        ; Update velocity (fixed point)
        move.l  Ball_VelY,d0
        add.l   #GRAVITY,d0          ; Add gravity
        cmp.l   #MAX_VELOCITY,d0     ; Check max velocity
        ble.s   .vel_ok
        move.l  #MAX_VELOCITY,d0
.vel_ok:
        move.l  d0,Ball_VelY

        ; Update position
        move.w  Ball_Y,d1
        add.w   d0,d1

        ; Check floor collision
        cmp.w   #(SCREEN_HEIGHT-BALL_SIZE),d1
        blt.s   .no_floor
        move.w  #(SCREEN_HEIGHT-BALL_SIZE),d1
        neg.l   d0
        muls    #BOUNCE_DAMP,d0
        asr.l   #8,d0
.no_floor:

        ; Check ceiling collision
        cmp.w   #0,d1
        bgt.s   .no_ceiling
        moveq   #0,d1
        neg.l   d0
        muls    #BOUNCE_DAMP,d0
        asr.l   #8,d0
.no_ceiling:

        ; Store new position and velocity
        move.l  d0,Ball_VelY
        move.w  d1,Ball_Y

        ; Update sprite position
        move.w  Ball_X,d0
        add.w   #128,d0              ; Center on screen
        move.w  d1,d2
        add.w   #44,d2               ; Y offset

        move.b  d0,SPR0POS(a6)
        move.b  d2,SPR0CTL(a6)

        ; Update rotation
        addq.w  #1,Ball_Rotation
        and.w   #$1F,Ball_Rotation   ; Keep in 0-31 range
        rts

;===========================================================================
; Update shadow position and size
;===========================================================================
Update_Shadow:
        ; Calculate shadow Y position based on ball height
        move.w  Ball_Y,d0
        add.w   #BALL_SIZE+8,d0      ; Position below ball

        ; Update shadow sprite position
        move.w  Ball_X,d1
        add.w   #128,d1              ; Center X
        move.b  d1,SPR1POS(a6)
        move.b  d0,SPR1CTL(a6)
        rts

;===========================================================================
; Update grid colors
;===========================================================================
Update_Grid:
        moveq   #7,d7                ; 8 color changes
        lea     Grid_Data(pc),a0     ; Color data
        lea     Copper_Colors(pc),a1 ; Copper list position

.loop:  move.w  (a0)+,2(a1)         ; Update color
        addq.l  #8,a1               ; Next copper instruction
        dbf     d7,.loop
        rts

;===========================================================================
; Data Section - Sprites and Copper List
;===========================================================================
        SECTION DATA,DATA_C

; Ball sprite - 32x32 checker pattern
Ball_Data:
        dc.w    $2C00,$2C20          ; VSTART, VSTOP
        dc.w    %0000111111110000,%1111111111111111
        dc.w    %0011111111111100,%1111111111111111
        dc.w    %0111100110011110,%1111111111111111
        dc.w    %1111001100110011,%1111111111111111
        dc.w    %1110011001100111,%1111111111111111
        dc.w    %1100110011001111,%1111111111111111
        dc.w    %1100110011001111,%1111111111111111
        dc.w    %1100110011001111,%1111111111111111
        dc.w    %1100110011001111,%1111111111111111
        dc.w    %1100110011001111,%1111111111111111
        dc.w    %1110011001100111,%1111111111111111
        dc.w    %1111001100110011,%1111111111111111
        dc.w    %0111100110011110,%1111111111111111
        dc.w    %0011111111111100,%1111111111111111
        dc.w    %0000111111110000,%1111111111111111
        dc.w    $0000,$0000          ; End of sprite

; Shadow sprite - Simple oval
Shadow_Data:
        dc.w    $5000,$5008          ; VSTART, VSTOP
        dc.w    %0000111111110000,%1111111111111111
        dc.w    %0011111111111100,%1111111111111111
        dc.w    %0000111111110000,%1111111111111111
        dc.w    $0000,$0000          ; End of sprite

; Complete copper list with grid
Copper_List:
        dc.w    DIWSTRT,$2C81
        dc.w    DIWSTOP,$2CC1
        dc.w    DDFSTRT,$0038
        dc.w    DDFSTOP,$00D0
        dc.w    BPLCON0,$1200
        dc.w    BPLCON1,$0000
        dc.w    BPLCON2,$0024
        dc.w    COLOR00,$0A8B        ; Background
Copper_Colors:
        dc.w    COLOR01,$0804        ; Grid color changes
        dc.w    $3001,$FFFE          ; Wait
        dc.w    COLOR01,$0805
        dc.w    $4001,$FFFE
        dc.w    COLOR01,$0806
        dc.w    $5001,$FFFE
        dc.w    COLOR01,$0807
        dc.w    $6001,$FFFE
        dc.w    COLOR01,$0808
        dc.w    $7001,$FFFE
        dc.w    COLOR01,$0809
        dc.w    $8001,$FFFE
        dc.w    COLOR01,$080A
        dc.w    $9001,$FFFE
        dc.w    COLOR01,$080B
        dc.l    $FFFFFFFE            ; End copper list

; Grid colors (purple shades)
Grid_Data:
        dc.w    $0804,$0805,$0806,$0807
        dc.w    $0808,$0809,$080A,$080B

;===========================================================================
; BSS Section - Variables
;===========================================================================
        SECTION BSS,BSS_C

Ball_X:         ds.w    1    ; Current X position
Ball_Y:         ds.w    1    ; Current Y position
Ball_VelY:      ds.l    1    ; Y velocity (fixed point)
Ball_Rotation:  ds.w    1    ; Current rotation angle

;===========================================================================
; End of program
;===========================================================================

        END
