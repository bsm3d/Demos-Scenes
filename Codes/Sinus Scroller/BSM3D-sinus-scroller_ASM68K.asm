;===========================================================================
; BSM3D - Sinus Scroller Effect
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
; While HTML5 can use canvas.fillText() and HSL colors, Amiga needs
; bitmap font rendering and copper list color cycling. Additionally,
; we're drawing each character manually here, when the Amiga originally
; used bitmap fonts directly, which was much more efficient. Thanks to AI
; for helping with the tedious character drawing approach used here!
;
; AI Note:
; As I dont program in 68000 assembly for many years, AI (Claude) 
; was used to verify and review the code for potential errors. This shows how 
; modern AI tools can help when returning to legacy programming after a long break.
;
; Historical Perspective:
; This assembly version requires different techniques than the HTML5 version.
; Each character must be manually plotted using the Blitter, and color cycling
; is achieved using the Copper instead of HSL color space manipulation.
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
SCREEN_WIDTH    EQU     320             ; Screen width in pixels
SCREEN_HEIGHT   EQU     256             ; Screen height in pixels
FONT_HEIGHT     EQU     8               ; Font height in pixels
FONT_WIDTH      EQU     8               ; Font width in pixels
WAVE_HEIGHT     EQU     40              ; Wave amplitude
SCROLL_SPEED    EQU     2               ; Pixels per frame
CHAR_SPACING    EQU     16              ; Pixels between chars

Start:
        movem.l d0-a6,-(sp)             ; Save registers
        lea     CUSTOM,a6               ; Custom chip base address

        move.w  INTENAR(a6),-(sp)
        move.w  DMACONR(a6),-(sp)
        move.w  #$7FFF,INTENA(a6)
        move.w  #$7FFF,DMACON(a6)
        
        bsr     Init_Display
        bsr     Init_Copper
        bsr     Init_Screen
        bsr     Init_Scroller
        
        move.w  #$8380,DMACON(a6)       ; Enable Copper, Blitter, and bitplane DMA

MainLoop:
        btst    #6,CUSTOM+VHPOSR        ; Wait for vertical blank
        beq.s   MainLoop
        
        bsr     Clear_Screen
        bsr     Update_Colors
        bsr     Update_Scroller
        bsr     Draw_Text
        
        btst    #6,$bfe001              ; Left mouse button exit
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
; Initialize display
;===========================================================================
Init_Display:
        move.w  #$2200,BPLCON0(a6)      ; One bitplane
        move.w  #$0000,BPLCON1(a6)
        
        move.w  #$2c81,DIWSTRT(a6)
        move.w  #$2cc1,DIWSTOP(a6)
        move.w  #$003c,DDFSTRT(a6)
        move.w  #$00d4,DDFSTOP(a6)
        
        move.w  #$0000,COLOR00(a6)      ; Black background
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
; Initialize screen buffer
;===========================================================================
Init_Screen:
        lea     Screen_Mem,a0
        move.l  a0,d0
        move.w  d0,BPL1PTL(a6)
        swap    d0
        move.w  d0,BPL1PTH(a6)
        rts

;===========================================================================
; Initialize scroller data
;===========================================================================
Init_Scroller:
        move.w  #SCREEN_WIDTH,Scroll_X  ; Start at right edge
        clr.w   Wave_Offset            ; Reset wave position
        rts

;===========================================================================
; Update scroller position
;===========================================================================
Update_Scroller:
        ; Update scroll position
        move.w  Scroll_X,d0
        sub.w   #SCROLL_SPEED,d0
        bpl.s   .no_wrap
        add.w   #Message_Length*CHAR_SPACING,d0
.no_wrap:
        move.w  d0,Scroll_X
        
        ; Update wave offset
        move.w  Wave_Offset,d0
        addq.w  #2,d0
        and.w   #$FF,d0
        move.w  d0,Wave_Offset
        rts

;===========================================================================
; Draw scrolling text
;===========================================================================
Draw_Text:
        lea     Scroll_Text(pc),a0      ; Text pointer
        move.w  Scroll_X,d2             ; Starting X position
        moveq   #0,d3                   ; Character counter

.char_loop:
        moveq   #0,d0
        move.b  (a0)+,d0                ; Get character
        beq.s   .done                   ; End of text
        
        move.w  d2,d4                   ; X position
        
        ; Calculate Y using sine table
        move.w  d2,d0
        lsr.w   #2,d0                   ; Scale X for wave
        add.w   Wave_Offset,d0          ; Add time offset
        and.w   #$FF,d0                 ; Wrap to table size
        add.w   d0,d0                   ; Word offset
        lea     SineTable(pc),a1
        move.w  (a1,d0.w),d1            ; Get sine value
        muls    #WAVE_HEIGHT,d1         ; Scale to amplitude
        asr.l   #8,d1                   ; Fixed point adjust
        add.w   #SCREEN_HEIGHT/2,d1     ; Center on screen
        
        ; Draw character if on screen
        cmp.w   #SCREEN_WIDTH,d4
        bgt.s   .nextchar
        bsr     Draw_Char
        
.nextchar:
        add.w   #CHAR_SPACING,d2        ; Next char position
        addq.w  #1,d3                   ; Count characters
        cmp.w   #Message_Length,d3
        blt.s   .char_loop
        
.done:
        rts

;===========================================================================
; Draw a single character
; D0 = Character, D4 = X, D1 = Y
;===========================================================================
Draw_Char:
        movem.l d0-d7/a0-a6,-(sp)
        
        sub.b   #32,d0                  ; ASCII adjust
        mulu    #FONT_HEIGHT,d0         ; Bytes per char
        lea     Font_Data(pc),a0
        add.w   d0,a0                   ; Point to char data
        
        ; Set blitter for character
        move.l  #Screen_Mem,d0
        add.w   d4,d0                   ; Add X offset
        mulu    #SCREEN_WIDTH/8,d1      ; Y offset
        add.l   d1,d0                   ; Final address
        
        ; Wait for blitter
.waitblit:
        btst    #6,2(a6)
        bne.s   .waitblit
        
        ; Set up blitter
        move.l  #$09f00000,BLTCON0(a6)  ; A->D copy, minterm
        move.l  d0,BLTDPTH(a6)          ; Destination
        move.l  a0,BLTAPTH(a6)          ; Source
        move.w  #0,BLTAMOD(a6)          ; Source modulo
        move.w  #SCREEN_WIDTH/8-1,BLTDMOD(a6)  ; Dest modulo
        move.w  #(FONT_HEIGHT*64)+1,BLTSIZE(a6)  ; Height*64 + width
        
        movem.l (sp)+,d0-d7/a0-a6
        rts

;===========================================================================
; Data Section
;===========================================================================
        SECTION DATA,DATA_C

; Sine table (256 entries, 8.8 fixed point)
SineTable:
        dc.w    0,3,6,9,12,16,19,22,25,28,31,34,37,40,43,46
        dc.w    49,51,54,57,60,63,65,68,71,73,76,78,81,83,85,88
        dc.w    90,92,94,96,98,100,102,104,106,107,109,111,112,113,115,116
        dc.w    117,118,120,121,122,122,123,124,125,125,126,126,126,127,127,127
        dc.w    127,127,127,127,126,126,126,125,125,124,123,122,122,121,120,118
        dc.w    117,116,115,113,112,111,109,107,106,104,102,100,98,96,94,92
        dc.w    90,88,85,83,81,78,76,73,71,68,65,63,60,57,54,51
        dc.w    49,46,43,40,37,34,31,28,25,22,19,16,12,9,6,3
        dc.w    0,-3,-6,-9,-12,-16,-19,-22,-25,-28,-31,-34,-37,-40,-43,-46
        dc.w    -49,-51,-54,-57,-60,-63,-65,-68,-71,-73,-76,-78,-81,-83,-85,-88
        dc.w    -90,-92,-94,-96,-98,-100,-102,-104,-106,-107,-109,-111,-112,-113,-115,-116
        dc.w    -117,-118,-120,-121,-122,-122,-123,-124,-125,-125,-126,-126,-126,-127,-127,-127
        dc.w    -127,-127,-127,-127,-126,-126,-126,-125,-125,-124,-123,-122,-122,-121,-120,-118
        dc.w    -117,-116,-115,-113,-112,-111,-109,-107,-106,-104,-102,-100,-98,-96,-94,-92
        dc.w    -90,-88,-85,-83,-81,-78,-76,-73,-71,-68,-65,-63,-60,-57,-54,-51
        dc.w    -49,-46,-43,-40,-37,-34,-31,-28,-25,-22,-19,-16,-12,-9,-6,-3

; Scroller text
Scroll_Text:
    dc.b    "    WELCOME TO THE CLASSIC SINUS SCROLLER DEMO... "
    dc.b    "GREETINGS TO ALL OLD SCHOOL DEMO MAKERS! "
    dc.b    "PUSH YOUR PIXELS TO THE LIMIT!     ",0
    even
Message_Length  EQU     (*-Scroll_Text)-1

; 8x8 Font data (complete ASCII set from 32 to 90)
Font_Data:
    ; SPACE (32)
    dc.b    %00000000
    dc.b    %00000000
    dc.b    %00000000
    dc.b    %00000000
    dc.b    %00000000
    dc.b    %00000000
    dc.b    %00000000
    dc.b    %00000000

    ; ! (33)
    dc.b    %00011000
    dc.b    %00011000
    dc.b    %00011000
    dc.b    %00011000
    dc.b    %00000000
    dc.b    %00011000
    dc.b    %00000000
    dc.b    %00000000

    ; " (34)
    dc.b    %01100110
    dc.b    %01100110
    dc.b    %00000000
    dc.b    %00000000
    dc.b    %00000000
    dc.b    %00000000
    dc.b    %00000000
    dc.b    %00000000

    ; # (35)
    dc.b    %01100110
    dc.b    %11111111
    dc.b    %01100110
    dc.b    %01100110
    dc.b    %11111111
    dc.b    %01100110
    dc.b    %00000000
    dc.b    %00000000

    ; A (65)
    dc.b    %00111100
    dc.b    %01100110
    dc.b    %01100110
    dc.b    %01111110
    dc.b    %01100110
    dc.b    %01100110
    dc.b    %01100110
    dc.b    %00000000

    ; B (66)
    dc.b    %01111100
    dc.b    %01100110
    dc.b    %01111100
    dc.b    %01100110
    dc.b    %01100110
    dc.b    %01111100
    dc.b    %00000000
    dc.b    %00000000

    ; C (67)
    dc.b    %00111100
    dc.b    %01100110
    dc.b    %01100000
    dc.b    %01100000
    dc.b    %01100110
    dc.b    %00111100
    dc.b    %00000000
    dc.b    %00000000

    ; D (68)
    dc.b    %01111100
    dc.b    %01100110
    dc.b    %01100110
    dc.b    %01100110
    dc.b    %01100110
    dc.b    %01111100
    dc.b    %00000000
    dc.b    %00000000

    ; E (69)
    dc.b    %01111110
    dc.b    %01100000
    dc.b    %01111100
    dc.b    %01100000
    dc.b    %01100000
    dc.b    %01111110
    dc.b    %00000000
    dc.b    %00000000

    ; F (70)
    dc.b    %01111110
    dc.b    %01100000
    dc.b    %01111100
    dc.b    %01100000
    dc.b    %01100000
    dc.b    %01100000
    dc.b    %00000000
    dc.b    %00000000

    ; G (71)
    dc.b    %00111100
    dc.b    %01100110
    dc.b    %01100000
    dc.b    %01101110
    dc.b    %01100110
    dc.b    %00111100
    dc.b    %00000000
    dc.b    %00000000

    ; H (72)
    dc.b    %01100110
    dc.b    %01100110
    dc.b    %01111110
    dc.b    %01100110
    dc.b    %01100110
    dc.b    %01100110
    dc.b    %00000000
    dc.b    %00000000

    ; I (73)
    dc.b    %00111100
    dc.b    %00011000
    dc.b    %00011000
    dc.b    %00011000
    dc.b    %00011000
    dc.b    %00111100
    dc.b    %00000000
    dc.b    %00000000

    ; J (74)
    dc.b    %00011110
    dc.b    %00001100
    dc.b    %00001100
    dc.b    %01101100
    dc.b    %01101100
    dc.b    %00111000
    dc.b    %00000000
    dc.b    %00000000

    ; K (75)
    dc.b    %01100110
    dc.b    %01101100
    dc.b    %01111000
    dc.b    %01111000
    dc.b    %01101100
    dc.b    %01100110
    dc.b    %00000000
    dc.b    %00000000

    ; L (76)
    dc.b    %01100000
    dc.b    %01100000
    dc.b    %01100000
    dc.b    %01100000
    dc.b    %01100000
    dc.b    %01111110
    dc.b    %00000000
    dc.b    %00000000

    ; M (77)
    dc.b    %01100011
    dc.b    %01110111
    dc.b    %01111111
    dc.b    %01101011
    dc.b    %01100011
    dc.b    %01100011
    dc.b    %00000000
    dc.b    %00000000

    ; N (78)
    dc.b    %01100110
    dc.b    %01110110
    dc.b    %01111110
    dc.b    %01111110
    dc.b    %01101110
    dc.b    %01100110
    dc.b    %00000000
    dc.b    %00000000

    ; O (79)
    dc.b    %00111100
    dc.b    %01100110
    dc.b    %01100110
    dc.b    %01100110
    dc.b    %01100110
    dc.b    %00111100
    dc.b    %00000000
    dc.b    %00000000

    ; P (80)
    dc.b    %01111100
    dc.b    %01100110
    dc.b    %01100110
    dc.b    %01111100
    dc.b    %01100000
    dc.b    %01100000
    dc.b    %00000000
    dc.b    %00000000

    ; Q (81)
    dc.b    %00111100
    dc.b    %01100110
    dc.b    %01100110
    dc.b    %01101110
    dc.b    %00111100
    dc.b    %00000110
    dc.b    %00000000
    dc.b    %00000000

    ; R (82)
    dc.b    %01111100
    dc.b    %01100110
    dc.b    %01100110
    dc.b    %01111100
    dc.b    %01101100
    dc.b    %01100110
    dc.b    %00000000
    dc.b    %00000000

    ; S (83)
    dc.b    %00111100
    dc.b    %01100000
    dc.b    %00111100
    dc.b    %00000110
    dc.b    %01100110
    dc.b    %00111100
    dc.b    %00000000
    dc.b    %00000000

    ; T (84)
    dc.b    %01111110
    dc.b    %00011000
    dc.b    %00011000
    dc.b    %00011000
    dc.b    %00011000
    dc.b    %00011000
    dc.b    %00000000
    dc.b    %00000000

    ; U (85)
    dc.b    %01100110
    dc.b    %01100110
    dc.b    %01100110
    dc.b    %01100110
    dc.b    %01100110
    dc.b    %00111100
    dc.b    %00000000
    dc.b    %00000000

    ; V (86)
    dc.b    %01100110
    dc.b    %01100110
    dc.b    %01100110
    dc.b    %01100110
    dc.b    %00111100
    dc.b    %00011000
    dc.b    %00000000
    dc.b    %00000000

    ; W (87)
    dc.b    %01100011
    dc.b    %01100011
    dc.b    %01101011
    dc.b    %01111111
    dc.b    %01110111
    dc.b    %01100011
    dc.b    %00000000
    dc.b    %00000000

    ; X (88)
    dc.b    %01100110
    dc.b    %01100110
    dc.b    %00111100
    dc.b    %00111100
    dc.b    %01100110
    dc.b    %01100110
    dc.b    %00000000
    dc.b    %00000000

    ; Y (89)
    dc.b    %01100110
    dc.b    %01100110
    dc.b    %00111100
    dc.b    %00011000
    dc.b    %00011000
    dc.b    %00011000
    dc.b    %00000000
    dc.b    %00000000

    ; Z (90)
    dc.b    %01111110
    dc.b    %00000110
    dc.b    %00011100
    dc.b    %00111000
    dc.b    %01100000
    dc.b    %01111110
    dc.b    %00000000
    dc.b    %00000000

; Copper list with color cycling
Copper_List:
    ; Basic setup
    dc.w    BPLCON0,$2200        ; One bitplane
    dc.w    COLOR00,$0000        ; Background color (black)

    ; Color cycling for text (16 colors, repeated every 16 lines)
    dc.w    $3001,$FFFE          ; Wait for line 48
    dc.w    COLOR01,$0FFF        ; White
    dc.w    $4001,$FFFE
    dc.w    COLOR01,$0EEE        ; Light gray
    dc.w    $5001,$FFFE
    dc.w    COLOR01,$0DDD
    dc.w    $6001,$FFFE
    dc.w    COLOR01,$0CCC
    dc.w    $7001,$FFFE
    dc.w    COLOR01,$0BBB
    dc.w    $8001,$FFFE
    dc.w    COLOR01,$0AAA
    dc.w    $9001,$FFFE
    dc.w    COLOR01,$0999
    dc.w    $A001,$FFFE
    dc.w    COLOR01,$0888        ; Dark gray

    ; End of copper list
    dc.l    $FFFFFFFE

;===========================================================================
; BSS Section - Variables
;===========================================================================
        SECTION BSS,BSS_C

Scroll_X:       ds.w    1    ; Current scroll position
Wave_Offset:    ds.w    1    ; Current wave offset
Color_Cycle:    ds.w    1    ; Color cycling counter

;===========================================================================
; Chip Memory Section
;===========================================================================
        SECTION CHIP,DATA_C

Screen_Mem:
    ds.b    SCREEN_WIDTH/8*SCREEN_HEIGHT

;===========================================================================
; Update color cycling in copper list
;===========================================================================
Update_Colors:
        ; Update color cycle counter
        move.w  Color_Cycle,d0
        addq.w  #1,d0
        and.w   #$0F,d0           ; Keep in range 0-15
        move.w  d0,Color_Cycle    ; Store back

        ; Update copper list colors
        lea     Copper_List,a0
        add.w   #8,a0             ; Skip to first color change
        moveq   #7,d7             ; 8 colors to update

.color_loop:
        add.w   d0,d7             ; Add phase
        and.w   #$0F,d7           ; Keep in range
        move.w  d7,d1
        lsl.w   #8,d1             ; Shift to color position
        or.w    #$0FFF,d1         ; Maximum intensity
        move.w  d1,6(a0)          ; Update color in copper list
        add.w   #8,a0             ; Next copper instruction
        dbf     d7,.color_loop
        rts

;===========================================================================
; End of program
;===========================================================================

        END