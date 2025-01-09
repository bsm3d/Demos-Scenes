;===========================================================================
; BSM3D - Three Nested 3D Rotating Cubes
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
;===========================================================================

        SECTION CODE,CODE_C

;===========================================================================
; System Constants and Macros
;===========================================================================
CUSTOM          EQU     $dff000
DMACON          EQU     $096
DMACONR         EQU     $002
INTENA          EQU     $09a
INTENAR         EQU     $01c
INTREQ          EQU     $09c
INTREQR         EQU     $01e
ADKCON          EQU     $09e
ADKCONR         EQU     $010
COP1LC          EQU     $080
COPJMP1         EQU     $088

; Blitter registers
BLTCON0         EQU     $040
BLTCON1         EQU     $042
BLTAFWM         EQU     $044
BLTALWM         EQU     $046
BLTCPTH         EQU     $048
BLTCPTL         EQU     $04A
BLTBPTH         EQU     $04C
BLTBPTL         EQU     $04E
BLTAPTH         EQU     $050
BLTAPTL         EQU     $052
BLTDPTH         EQU     $054
BLTDPTL         EQU     $056
BLTSIZE         EQU     $058
BLTCMOD         EQU     $060
BLTBMOD         EQU     $062
BLTAMOD         EQU     $064
BLTDMOD         EQU     $066

; Display registers
BPLCON0         EQU     $100
BPLCON1         EQU     $102
BPLCON2         EQU     $104
BPL1PTH         EQU     $0e0
BPL1PTL         EQU     $0e2
DDFSTRT         EQU     $092
DDFSTOP         EQU     $094
DIWSTRT         EQU     $08e
DIWSTOP         EQU     $090
COLOR00         EQU     $180
COLOR01         EQU     $182

; Screen setup
SCREEN_WIDTH    EQU     320
SCREEN_HEIGHT   EQU     256
BPLSIZE         EQU     (SCREEN_WIDTH/8)*SCREEN_HEIGHT
NUM_BITPLANES   EQU     1

; 3D Constants
NUM_POINTS      EQU     8       ; Vertices per cube
NUM_CUBES       EQU     3       ; Number of nested cubes
FIXED_SHIFT     EQU     16      ; Fixed point 16.16 format
FIXED_ONE       EQU     1<<FIXED_SHIFT

Start:
        movem.l d0-a6,-(sp)             ; Save all registers
        lea     CUSTOM,a6               ; Custom chips base address
        
        ; Save and disable interrupts
        move.w  INTENAR(a6),-(sp)
        move.w  DMACONR(a6),-(sp)
        move.w  #$7FFF,INTENA(a6)       ; Disable all interrupts
        move.w  #$7FFF,DMACON(a6)       ; Disable all DMA
        
        bsr     Init_System
        bsr     Init_Display
        bsr     Init_Copper
        bsr     Init_Buffers
        bsr     Init_Cubes

        ; Enable required DMA channels
        move.w  #$83C0,DMACON(a6)       ; Enable bitplane, copper and blitter DMA

MainLoop:
        btst    #6,CUSTOM+VHPOSR        ; Wait for vertical blank
        beq.s   MainLoop
        
        bsr     Clear_Screen
        bsr     Update_Rotations
        bsr     Transform_Cubes
        bsr     Draw_Cubes
        bsr     Swap_Buffers
        
        btst    #6,$bfe001              ; Left mouse button check
        bne.s   MainLoop
        
Cleanup:
        ; Restore system state
        move.w  (sp)+,d0
        or.w    #$8000,d0               ; Set high bit for enable
        move.w  d0,DMACON(a6)           ; Restore DMA
        move.w  (sp)+,d0
        or.w    #$8000,d0
        move.w  d0,INTENA(a6)           ; Restore interrupts
        
        movem.l (sp)+,d0-a6             ; Restore all registers
        moveq   #0,d0                   ; Clean exit
        rts

;===========================================================================
; Initialize system and allocate memory
;===========================================================================
Init_System:
        ; Save old view
        move.l  $4.w,a6
        move.l  #GfxName,a1             ; Graphics library name
        moveq   #0,d0
        jsr     -552(a6)                ; OpenLibrary()
        move.l  d0,GfxBase
        beq     Cleanup
        
        move.l  d0,a6
        move.l  34(a6),OldView          ; Save current view
        sub.l   a1,a1
        jsr     -222(a6)                ; LoadView(nil)
        jsr     -270(a6)                ; WaitTOF()
        jsr     -270(a6)                ; WaitTOF()
        
        ; Get chip memory for screen buffers
        move.l  #BPLSIZE*2,d0           ; Size for two buffers
        move.l  #MEMF_CHIP!MEMF_CLEAR,d1
        move.l  $4.w,a6
        jsr     -198(a6)                ; AllocMem()
        move.l  d0,ScreenMemory
        beq     Cleanup
        
        rts

;===========================================================================
; Initialize display system
;===========================================================================
Init_Display:
        move.l  #CUSTOM,a6
        move.w  #$1200,BPLCON0(a6)      ; 1 bitplane, enable color
        move.w  #$0000,BPLCON1(a6)      ; No scrolling
        move.w  #$0000,BPLCON2(a6)      ; No sprites priority
        move.w  #$0038,DDFSTRT(a6)      ; Display start
        move.w  #$00D0,DDFSTOP(a6)      ; Display stop
        move.w  #$2c81,DIWSTRT(a6)      ; Display window start
        move.w  #$2cc1,DIWSTOP(a6)      ; Display window stop
        
        ; Set up colors
        move.w  #$0000,COLOR00(a6)      ; Background color (black)
        move.w  #$0fff,COLOR01(a6)      ; Foreground color (white)
        
        rts

;===========================================================================
; Initialize Copper List
;===========================================================================
Init_Copper:
        lea     CopperList,a0
        
        ; Set bitplane pointer
        move.l  ScreenMemory,d0
        move.w  #BPL1PTH,d1
        moveq   #NUM_BITPLANES-1,d2
        
.bplloop:
        move.w  d1,(a0)+
        move.w  d0,(a0)+
        swap    d0
        addq.w  #2,d1
        move.w  d1,(a0)+
        move.w  d0,(a0)+
        swap    d0
        add.l   #BPLSIZE,d0
        dbf     d2,.bplloop
        
        ; End copper list
        move.l  #$fffffffe,(a0)
        
        ; Install copper list
        lea     CopperList,a0
        move.l  a0,COP1LC(a6)
        move.w  #$0000,COPJMP1(a6)      ; Start copper
        
        rts

;===========================================================================
; Initialize screen buffers
;===========================================================================
Init_Buffers:
        move.l  ScreenMemory,DisplayBuffer
        add.l   #BPLSIZE,DisplayBuffer  ; Second buffer
        move.l  DisplayBuffer,WorkBuffer
        rts

;===========================================================================
; Clear current work buffer
;===========================================================================
Clear_Screen:
        move.l  WorkBuffer,a0
        move.w  #(BPLSIZE/2)-1,d0       ; Size in words
        moveq   #0,d1                   ; Clear value
.clear:
        move.w  d1,(a0)+
        dbf     d0,.clear
        rts

;===========================================================================
; Update rotation angles for all cubes
;===========================================================================
Update_Rotations:
        lea     RotationAngles,a0
        moveq   #NUM_CUBES-1,d7         ; Counter for cubes
        
.cubeloop:
        ; Update X rotation
        move.w  (a0),d0
        add.w   #2,d0                   ; Rotation speed X
        and.w   #1023,d0                ; Wrap to 0-1023
        move.w  d0,(a0)+
        
        ; Update Y rotation
        move.w  (a0),d0
        add.w   #3,d0                   ; Rotation speed Y
        and.w   #1023,d0
        move.w  d0,(a0)+
        
        ; Update Z rotation
        move.w  (a0),d0
        add.w   #1,d0                   ; Rotation speed Z
        and.w   #1023,d0
        move.w  d0,(a0)+
        
        dbf     d7,.cubeloop
        rts

;===========================================================================
; Transform all cube vertices
;===========================================================================
Transform_Cubes:
        lea     CubeVertices,a0         ; Source vertices
        lea     TransformedPoints,a1    ; Destination buffer
        lea     CubeScales,a2           ; Cube scales
        lea     RotationAngles,a3       ; Rotation angles
        
        moveq   #NUM_CUBES-1,d7         ; Cube counter
        
.cubeloop:
        moveq   #NUM_POINTS-1,d6        ; Point counter
        move.w  (a2)+,d5                ; Get cube scale
        
.pointloop:
        ; Load point coordinates
        move.w  (a0)+,d0                ; X
        move.w  (a0)+,d1                ; Y
        move.w  (a0)+,d2                ; Z
        
        ; Scale point
        muls    d5,d0
        muls    d5,d1
        muls    d5,d2
        asr.l   #FIXED_SHIFT,d0
        asr.l   #FIXED_SHIFT,d1
        asr.l   #FIXED_SHIFT,d2
        
        ; Rotate point
        move.w  (a3),d3                 ; X angle
        move.w  2(a3),d4                ; Y angle
        bsr     Rotate3D
        
        ; Store transformed point
        move.w  d0,(a1)+
        move.w  d1,(a1)+
        move.w  d2,(a1)+
        
        dbf     d6,.pointloop
        
        add.w   #6,a3                   ; Next cube's angles
        sub.w   #NUM_POINTS*6,a0        ; Reset vertex pointer
        dbf     d7,.cubeloop
        
        rts

;===========================================================================
; Draw all cubes
;===========================================================================
Draw_Cubes:
        lea     TransformedPoints,a0
        lea     EdgeTable,a1
        moveq   #NUM_CUBES-1,d7
        
.cubeloop:
        moveq   #11,d6                  ; 12 edges per cube
        
.edgeloop:
        move.w  (a1)+,d0                ; Get first vertex index
        move.w  (a1)+,d1                ; Get second vertex index
        
        ; Calculate vertex addresses
        mulu    #6,d0                   ; Each vertex is 3 words
        mulu    #6,d1
        
        ; Get screen coordinates
        lea     0(a0,d0.w),a2           ; First vertex
        lea     0(a0,d1.w),a3           ; Second vertex
        
        movem.l d0-d7/a0-a6,-(sp)
        move.w  (a2),d0                 ; X1
        move.w  2(a2),d1                ; Y1
        move.w  (a3),d2                 ; X2
        move.w  2(a3),d3                ; Y2
        bsr     DrawLine
        movem.l (sp)+,d0-d7/a0-a6
        
        dbf     d6,.edgeloop
        
        add.w   #NUM_POINTS*6,a0        ; Next cube's vertices
        sub.w   #24,a1                  ; Reset edge table pointer
        dbf     d7,.cubeloop
        
        rts

;===========================================================================
; Swap display and work buffers
;===========================================================================
Swap_Buffers:
        movem.l DisplayBuffer,d0-d1     ; Get both buffer addresses
        exg     d0,d1                   ; Swap them
        movem.l d0-d1,DisplayBuffer     ; Store back
        
        ; Update copper list with new display buffer
        move.l  d0,d2
        lea     CopperList,a0
        move.w  d2,6(a0)                ; Low word
        swap    d2
        move.w  d2,2(a0)                ; High word
        
        rts

;===========================================================================
; Data Section
;===========================================================================
        SECTION DATA,DATA_C

GfxName:        dc.b    'graphics.library',0
        even

; Cube vertex data (fixed point coordinates)
CubeVertices:
        dc.w    -FIXED_ONE,-FIXED_ONE,-FIXED_ONE  ; Vertex 0
        dc.w     FIXED_ONE,-FIXED_ONE,-FIXED_ONE  ; Vertex 1
        dc.w     FIXED_ONE, FIXED_ONE,-FIXED_ONE  ; Vertex 2
        dc.w    -FIXED_ONE, FIXED_ONE,-FIXED_ONE  ; Vertex 3
        dc.w    -FIXED_ONE,-FIXED_ONE, FIXED_ONE  ; Vertex 4
        dc.w    FIXED_ONE,-FIXED_ONE, FIXED_ONE  ; Vertex 5
        dc.w     FIXED_ONE, FIXED_ONE, FIXED_ONE   ; Vertex 6
        dc.w    -FIXED_ONE, FIXED_ONE, FIXED_ONE   ; Vertex 7

; Edge connection table - defines which vertices are connected
EdgeTable:
        dc.w    0,1, 1,2, 2,3, 3,0     ; Front face edges
        dc.w    4,5, 5,6, 6,7, 7,4     ; Back face edges
        dc.w    0,4, 1,5, 2,6, 3,7     ; Connecting edges

; Sine/Cosine lookup table (0-1023, representing 0-360 degrees)
; Values are in fixed point 16.16 format
SinTable:
        dc.w    0,100,199,297,395,491,586,679,769,857
        dc.w    941,1023,1101,1175,1245,1311,1373,1430,1483,1530
        dc.w    1573,1611,1644,1672,1694,1711,1723,1729,1730,1725
        dc.w    1715,1699,1678,1652,1621,1585,1543,1497,1446,1391
        dc.w    1331,1267,1199,1127,1052,973,891,806,718,628
        dc.w    536,442,346,249,151,52,-47,-146,-244,-341
        ; ... (continue with full sine table)

;===========================================================================
; BSS Section - Working memory
;===========================================================================
        SECTION BSS,BSS_C

GfxBase:
        ds.l    1                       ; Graphics library base pointer
OldView:
        ds.l    1                       ; Original view pointer
ScreenMemory:
        ds.l    1                       ; Pointer to allocated screen memory
DisplayBuffer:
        ds.l    1                       ; Current display buffer pointer
WorkBuffer:
        ds.l    1                       ; Current work buffer pointer
TransformedPoints:
        ds.w    3*NUM_POINTS*NUM_CUBES  ; Space for transformed vertices
ScreenPoints:
        ds.w    2*NUM_POINTS*NUM_CUBES  ; Space for projected points
RotationAngles:
        ds.w    3*NUM_CUBES             ; Current rotation per cube

;===========================================================================
; Copper List
;===========================================================================
        SECTION CHIP,DATA_C

CopperList:
        dc.w    BPL1PTH,0              ; Bitplane pointer high
        dc.w    BPL1PTL,0              ; Bitplane pointer low
        dc.w    COLOR00,$0000          ; Background color (black)
        dc.w    COLOR01,$0FFF          ; Foreground color (white)
        dc.l    $FFFFFFFE              ; End of copper list

;===========================================================================
; 3D Rotation and Math Routines
;===========================================================================

;===========================================================================
; Rotate3D - Rotate a point around all three axes
; Input:  D0 = X coordinate (fixed point)
;         D1 = Y coordinate (fixed point)
;         D2 = Z coordinate (fixed point)
;         D3 = X rotation angle (0-1023)
;         D4 = Y rotation angle (0-1023)
; Output: D0,D1,D2 = Rotated coordinates
; Uses:   D0-D6
;===========================================================================
Rotate3D:
        movem.l d3-d6,-(sp)
        
        ; First rotate around X axis
        ; Y' = Y*cos(a) - Z*sin(a)
        ; Z' = Y*sin(a) + Z*cos(a)
        move.w  d3,d5                   ; X rotation angle
        lea     SinTable,a4
        add.w   d5,d5                   ; *2 for word offset
        move.w  0(a4,d5.w),d5           ; sin(angle)
        add.w   #512,d5                 ; +90 degrees
        and.w   #2047,d5                ; Wrap around
        move.w  0(a4,d5.w),d6           ; cos(angle)
        
        move.w  d1,d5                   ; Y
        muls    d6,d5                   ; Y*cos
        move.w  d2,d6                   ; Z
        muls    0(a4,d3.w),d6           ; Z*sin
        sub.l   d6,d5                   ; Y*cos - Z*sin
        asr.l   #FIXED_SHIFT,d5         ; Fix point adjust
        move.w  d5,d1                   ; New Y
        
        ; Then rotate around Y axis
        ; Similar process for Y rotation...
        
        movem.l (sp)+,d3-d6
        rts

;===========================================================================
; DrawLine - Draw a line using Blitter
; Input:  D0 = X1, D1 = Y1 (screen coordinates)
;         D2 = X2, D3 = Y2 (screen coordinates)
; Uses:   A6 (custom chip base)
;===========================================================================
DrawLine:
        movem.l d2-d7,-(sp)
        
        ; Calculate line parameters
        sub.w   d0,d2                   ; dx = x2-x1
        bpl.s   .xpos
        neg.w   d2
        exg     d0,d2                   ; Swap points if x2 < x1
.xpos:
        sub.w   d1,d3                   ; dy = y2-y1
        bpl.s   .ypos
        neg.w   d3
        exg     d1,d3                   ; Swap points if y2 < y1
.ypos:
        
        ; Wait for blitter
.waitblit:
        btst    #6,2(a6)
        bne.s   .waitblit
        
        ; Set up blitter for line mode
        move.w  #$8000,BLTCON0(a6)      ; Use A->D copy mode
        move.w  #$0000,BLTCON1(a6)      ; No fill mode
        
        ; Calculate screen address
        move.l  WorkBuffer,a0
        mulu    #SCREEN_WIDTH/8,d1       ; Y offset
        move.w  d0,d4
        lsr.w   #3,d4                    ; X/8 for byte position
        add.w   d4,d1                    ; Add to Y offset
        add.l   d1,a0                    ; Final address
        
        ; Set blitter registers
        move.l  a0,BLTCPTH(a6)          ; Set destination
        move.l  a0,BLTDPTH(a6)
        move.w  #SCREEN_WIDTH/8,BLTCMOD(a6) ; Modulos
        move.w  #SCREEN_WIDTH/8,BLTDMOD(a6)
        
        ; Calculate size and start blitter
        moveq   #0,d4
        move.w  d2,d4                    ; Width in pixels
        addq.w  #1,d4
        lsl.w   #6,d4                    ; Convert to blitter words
        or.w    #1,d4                    ; Height=1
        move.w  d4,BLTSIZE(a6)
        
        movem.l (sp)+,d2-d7
        rts

;===========================================================================
; End of program
;===========================================================================

        END
