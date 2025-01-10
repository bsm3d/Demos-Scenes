;===========================================================================
; BSM3D - Dot Tunnel Effect
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
; While HTML5 can use floating-point math and direct canvas drawing,
; Amiga needs fixed-point calculations and Blitter operations.
; The original demo scene used various optimizations that we don't use here.
;
; AI Note:
; As I dont program in 68000 assembly for many years, AI (Claude)
; was used to verify and review the code for potential errors. This shows how
; modern AI tools can help when returning to legacy programming after a long break.
;
; Historical Perspective:
; This assembly version requires more complex techniques than the HTML5 version,
; using Blitter operations and fixed-point math where HTML5 offers simple
; floating-point calculations and canvas.fillRect() operations.
;===========================================================================

SECTION CODE,CODE_C

;===========================================================================
; Hardware Registers
;===========================================================================
CUSTOM EQU $dff000
DMACON EQU $096
DMACONR EQU $002
INTENA EQU $09a
INTENAR EQU $01c
COP1LC EQU $080
COPJMP1 EQU $088
COLOR00 EQU $180
COLOR01 EQU $182
BPLCON0 EQU $100
BPLCON1 EQU $102
BPLCON2 EQU $104
BPL1PTH EQU $0e0
BPL1PTL EQU $0e2
DIWSTRT EQU $08e
DIWSTOP EQU $090
DDFSTRT EQU $092
DDFSTOP EQU $094

; Constants for effect
SCREEN_WIDTH EQU 320
SCREEN_HEIGHT EQU 256
NUM_CIRCLES EQU 16
POINTS_PER_CIRCLE EQU 32
FIXED_SHIFT EQU 8 ; 8.8 fixed point
MIN_RADIUS EQU 10
MAX_RADIUS EQU 100
MOVE_SPEED EQU 2 ; Movement speed (fixed point)

Start:
movem.l d0-a6,-(sp) ; Save all registers
lea CUSTOM,a6

move.w INTENAR(a6),-(sp)
move.w DMACONR(a6),-(sp)
move.w #$7FFF,INTENA(a6)
move.w #$7FFF,DMACON(a6)

bsr Init_Display
bsr Init_Copper
bsr Init_Screen
bsr Init_Circles

move.w #$8380,DMACON(a6) ; Enable DMA

MainLoop:
btst #6,$bfe001 ; Left mouse button
bne.s .no_exit
bra Exit
.no_exit:
btst #6,CUSTOM+VHPOSR ; Vertical blank
beq.s MainLoop

bsr Clear_Screen ; Clear old points
bsr Update_Circles ; Move circles
bsr Draw_Tunnel ; Draw new frame
bra MainLoop

Exit:
move.w (sp)+,d0 ; Restore DMA and interrupts
or.w #$8000,d0
move.w d0,DMACON(a6)
move.w (sp)+,d0
or.w #$8000,d0
move.w d0,INTENA(a6)

movem.l (sp)+,d0-a6
moveq #0,d0
rts

;===========================================================================
; Initialize display system
;===========================================================================
Init_Display:
move.w #$2200,BPLCON0(a6) ; One bitplane
move.w #$0000,BPLCON1(a6)
move.w #$0000,BPLCON2(a6)

move.w #$2c81,DIWSTRT(a6)
move.w #$2cc1,DIWSTOP(a6)
move.w #$0038,DDFSTRT(a6)
move.w #$00d0,DDFSTOP(a6)

move.w #$0000,COLOR00(a6) ; Black background
move.w #$0fff,COLOR01(a6) ; White dots
rts

;===========================================================================
; Initialize copper
;===========================================================================
Init_Copper:
lea Copper_List,a0
move.l a0,COP1LC(a6)
move.w #$0000,COPJMP1(a6)
rts

;===========================================================================
; Initialize screen
;===========================================================================
Init_Screen:
move.l #Screen_Buffer,d0
move.w d0,BPL1PTL(a6)
swap d0
move.w d0,BPL1PTH(a6)
rts

;===========================================================================
; Initialize circle data
;===========================================================================
Init_Circles:
lea Circle_Data,a0
moveq #NUM_CIRCLES-1,d7
.loop:
move.w d7,d0 ; Z position
mulu #$100,d0 ; Convert to fixed point
divu #NUM_CIRCLES,d0
move.w d0,(a0) ; Store Z
clr.w 2(a0) ; Clear angle
addq.l #6,a0 ; Next circle
dbf d7,.loop
rts

;===========================================================================
; Clear screen
;===========================================================================
Clear_Screen:
lea Screen_Buffer,a0
move.w #(SCREEN_WIDTH/16*SCREEN_HEIGHT)-1,d7
.loop:
clr.l (a0)+
dbf d7,.loop
rts

;===========================================================================
; Update circle positions
;===========================================================================
Update_Circles:
lea Circle_Data,a0
moveq #NUM_CIRCLES-1,d7
.loop:
move.w (a0),d0 ; Get Z
sub.w #MOVE_SPEED,d0 ; Move forward
bpl.s .no_wrap
add.w #$100,d0 ; Wrap to back
.no_wrap:
move.w d0,(a0) ; Store new Z

move.w 2(a0),d0 ; Get angle
addq.w #2,d0 ; Rotate
and.w #$1FF,d0 ; Wrap angle
move.w d0,2(a0) ; Store new angle

addq.l #6,a0 ; Next circle
dbf d7,.loop
rts

;===========================================================================
; Draw complete tunnel
;===========================================================================
Draw_Tunnel:
lea Circle_Data,a0
moveq #NUM_CIRCLES-1,d7
.circle_loop:
move.w (a0),d6 ; Get Z
move.w 2(a0),d5 ; Get base angle

; Calculate radius based on Z
move.w #$100,d4 ; 1.0 fixed point
sub.w d6,d4 ; 1 - Z
mulu #MAX_RADIUS,d4
lsr.l #8,d4
add.w #MIN_RADIUS,d4 ; Add minimum radius

moveq #POINTS_PER_CIRCLE-1,d3
.point_loop:
move.w d3,d0
add.w d5,d0 ; Add base angle
and.w #$1FF,d0 ; Wrap angle
add.w d0,d0 ; Word offset
lea SineTable,a1

; Get sine and cosine
move.w (a1,d0.w),d1 ; sin
move.w 90*2(a1,d0.w),d2 ; cos

; Scale by radius
muls d4,d1
muls d4,d2
asr.l #8,d1
asr.l #8,d2

; Add screen center
add.w #SCREEN_WIDTH/2,d1
add.w #SCREEN_HEIGHT/2,d2

movem.l d0-d7/a0-a1,-(sp)
move.w d1,d0 ; X
move.w d2,d1 ; Y

; Calculate point size based on Z
moveq #3,d2 ; Base size
sub.w d6,d2 ; Adjust for Z
bpl.s .size_ok
moveq #1,d2 ; Minimum size
.size_ok:
bsr Plot_Point
movem.l (sp)+,d0-d7/a0-a1

dbf d3,.point_loop
addq.l #6,a0 ; Next circle
dbf d7,.circle_loop
rts

;===========================================================================
; Plot point
; D0 = X, D1 = Y, D2 = Size
;===========================================================================
Plot_Point:
movem.l d2-d6/a0,-(sp)

; Calculate screen address
mulu #SCREEN_WIDTH/8,d1 ; Y * bytes per line
move.w d0,d3
lsr.w #3,d3 ; X / 8
add.w d3,d1 ; Add to Y offset
lea Screen_Buffer,a0
add.w d1,a0 ; Final address

; Calculate bit position
move.w d0,d3
and.w #7,d3 ; X & 7
moveq #$80,d4
lsr.b d3,d4 ; Create bit mask

; Draw point based on size
subq.w #1,d2 ; Size-1 for dbf
.size_loop:
or.b d4,(a0) ; Set pixel
lea SCREEN_WIDTH/8(a0),a0 ; Next line
dbf d2,.size_loop

movem.l (sp)+,d2-d6/a0
rts

;===========================================================================
; Data Section
;===========================================================================
SECTION DATA,DATA_C

SineTable: ; 256 entries for 0-360 degrees
dc.w 0,3,6,9,12,16,19,22,25,28,31,34,37,40,43,46
dc.w 49,51,54,57,60,63,65,68,71,73,76,78,81,83,85,88
dc.w 90,92,94,96,98,100,102,104,106,107,109,111,112,113,115,116
dc.w 117,118,120,121,122,122,123,124,125,125,126,126,126,127,127,127
dc.w 127,127,127,127,126,126,126,125,125,124,123,122,122,121,120,118
dc.w 117,116,115,113,112,111,109,107,106,104,102,100,98,96,94,92
dc.w 90,88,85,83,81,78,76,73,71,68,65,63,60,57,54,51
dc.w 49,46,43,40,37,34,31,28,25,22,19,16,12,9,6,3
dc.w 0,-3,-6,-9,-12,-16,-19,-22,-25,-28,-31,-34,-37,-40,-43,-46
dc.w -49,-51,-54,-57,-60,-63,-65,-68,-71,-73,-76,-78,-81,-83,-85,-88
dc.w -90,-92,-94,-96,-98,-100,-102,-104,-106,-107,-109,-111,-112,-113,-115,-116
dc.w -117,-118,-120,-121,-122,-122,-123,-124,-125,-125,-126,-126,-126,-127,-127,-127
dc.w -127,-127,-127,-127,-126,-126,-126,-125,-125,-124,-123,-122,-122,-121,-120,-118
dc.w -117,-116,-115,-113,-112,-111,-109,-107,-106,-104,-102,-100,-98,-96,-94,-92
dc.w -90,-88,-85,-83,-81,-78,-76,-73,-71,-68,-65,-63,-60,-57,-54,-51
dc.w -49,-46,-43,-40,-37,-34,-31,-28,-25,-22,-19,-16,-12,-9,-6,-3

Copper_List:
dc.w BPLCON0,$2200 ; One bitplane
dc.w COLOR00,$0000 ; Black background
dc.w COLOR01,$0FFF ; White dots
dc.l $FFFFFFFE ; End copper list

;===========================================================================
; BSS Section
;===========================================================================
SECTION BSS,BSS_C

Circle_Data:
ds.b NUM_CIRCLES*6 ; Structure: Z pos, Angle, Reserved

;===========================================================================
; Chip Memory Section
;===========================================================================
SECTION CHIP,DATA_C

Screen_Buffer:
ds.b SCREEN_WIDTH/8*SCREEN_HEIGHT

;===========================================================================
; End of program
;===========================================================================

END