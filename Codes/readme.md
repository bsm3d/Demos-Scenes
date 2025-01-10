# Amiga Demo Effects Collection in Assembly
by Benoit (BSM3D) Saint-Moulin

## Table of Contents
1. [Introduction](#Introduction)
2. [Code Philosophy](#code-philosophy)
3. [Development Environment Setup](#development-environment-setup)
4. [Amiga Hardware Basics](#amiga-hardware-basics)
5. [Assembly Language Guide](#assembly-language-guide)
6. [Program Structure](#program-structure)
7. [The Copper](#the-copper)
8. [The Blitter](#the-blitter)
9. [Memory Management](#memory-management)
10. [Common Effects Implementation](#common-effects-implementation)
11. [Optimization Tips](#optimization-tips)
12. [Common Pitfalls](#common-pitfalls)
13. [Further Learning](#further-learning)


## Introduction

This is a collection of iconic demo effects implemented in 68000 assembly, exploring the technical capabilities of the Amiga 500, a pioneering computer in the demoscene of the 1980s and early 1990s.

### Technical Context

The instructions and examples provide insight into low-level Amiga programming, focusing specifically on:
- Creating graphic effects
- Direct hardware manipulation
- Optimization techniques specific to the Amiga architecture

#### Typical Hardware Configuration
- **Processor**: Motorola 68000 clocked at 7.09 MHz
- **Chip RAM**: 512 KB (dedicated to graphics and sound operations)
- **Fast RAM**: 512 KB (for general data processing)
- **Distinctive Feature**: No integrated FPU (floating-point unit)

### Limitations and Scope

**Important**: This document presents a pedagogical approach to Amiga assembly programming. The codes and instructions do not cover the entire Amiga operating system (Amiga OS / Workbench). The emphasis is on:
- Direct hardware manipulation techniques
- Demoscene graphic effects
- Optimization of limited resources

### Note on Arithmetic Coprocessor (FPU)

Although a 68882 FPU could be added for floating-point calculations, its use was rare in demos and games of the era. Its interest was primarily limited to specialized 3D design software.

### Objective

These examples aim to:
- Understand low-level Amiga programming
- Discover demoscene techniques
- Learn optimization on hardware with constrained resources

## Effects Overview
This repository contains several classic demo effects ported from HTML5 to Amiga Assembly:
- 3D Rotating Cubes
- Boing Ball Animation
- Copper Bars Effect
- Dot Tunnel Effect
- Sine Wave Scroller
- Stars field

Each effect is self-contained in a single file for learning purposes, although this isn't the most efficient approach for real Amiga development.

## Code Philosophy
I've intentionally kept a similar structure across all examples:
- Same initialization routines
- Similar hardware setup
- Consistent code organization
- Repeated utility functions

This consistency helps learners understand the code more easily, although it's not how we would write Amiga programs in the 1990s. Back then, we would use includes for common routines:
```assembly
  INCLUDE "hardware/custom.i"    ; Hardware registers
  INCLUDE "hardware/screen.i"    ; Screen management
  INCLUDE "utils/sincos.i"      ; Sine/Cosine tables
  INCLUDE "utils/copper.i"      ; Copper list management
```

## Development Environment Setup

### Using WinUAE
1. Install WinUAE and configure an A500 with:
   - OCS Chipset
   - 512KB Chip RAM
   - 512KB Fast RAM
   - Kickstart 1.3 ROM
2. Install ASM-One or SEKA assembler
3. Copy the .asm file to the Amiga environment
4. In ASM-One:
   - Load the file with 'r'
   - Assemble with 'a'
   - Execute with 'j'

### Using Visual Studio Code
1. Install VS Code
2. Install "Amiga Assembly" extension
3. Configure extension settings for WinUAE
4. Open .asm file
5. Use extension commands to assemble and run

## Amiga Hardware Basics

### Memory Types
- **Chip RAM**: Required for DMA operations (screen, sprites, etc.)
- **Fast RAM**: Regular memory, faster but can't be used for DMA
- **ROM**: System and Kickstart code

### Memory Sections
- **CODE**: Program instructions
- **DATA**: Initialized data (constants, tables)
- **BSS**: Uninitialized variables
- **CHIP**: Data that must be in Chip RAM (graphics, sound)

## Assembly Language Guide

### Complete 68000 Instruction Set Reference
Here are the most commonly used instructions in demo coding:

#### Data Movement
```assembly
move.w source,dest     ; Move word
movem.l d0-d7,-(sp)   ; Multiple register move
moveq   #0,d0         ; Quick immediate data (8-bit)
lea     label,a0      ; Load effective address
exg     d0,d1         ; Exchange registers
```

#### Arithmetic Operations
```assembly
add.w   d0,d1         ; Add
sub.w   d0,d1         ; Subtract
mulu    d0,d1         ; Unsigned multiply
divs    d0,d1         ; Signed divide
neg.w   d0            ; Negate
clr.w   d0            ; Clear
```

#### Logical Operations
```assembly
and.w   d0,d1         ; Logical AND
or.w    d0,d1         ; Logical OR
eor.w   d0,d1         ; Exclusive OR
not.w   d0            ; Logical complement
```

#### Bit Manipulation
```assembly
bset    d0,d1         ; Set bit
bclr    d0,d1         ; Clear bit
btst    d0,d1         ; Test bit
rol.w   #1,d0         ; Rotate left
ror.w   #1,d0         ; Rotate right
```

#### Branch Instructions
```assembly
bra     label         ; Branch always
beq     label         ; Branch if equal
bne     label         ; Branch if not equal
bgt     label         ; Branch if greater than
blt     label         ; Branch if less than
dbf     d0,label      ; Decrement and branch
```

#### Subroutine Instructions
```assembly
bsr     subroutine    ; Branch to subroutine
jsr     subroutine    ; Jump to subroutine
rts                   ; Return from subroutine
```

## Program Structure

### Basic Template
```assembly
        SECTION CODE,CODE_C    ; Code must be first section

Start:  
        movem.l d0-a6,-(sp)   ; Save all registers
        lea     CUSTOM,a6     ; Custom chips base address

        ; Initialize hardware
        bsr     Init_Display
        bsr     Init_Copper
        bsr     Init_Screen

MainLoop:
        btst    #6,CUSTOM+VHPOSR  ; Wait for vertical blank
        beq.s   MainLoop
        
        ; Your effect code here
        
Exit:   
        movem.l (sp)+,d0-a6   ; Restore registers
        moveq   #0,d0         ; Clean exit
        rts

        SECTION DATA,DATA_C   ; Constants and tables
        ; Your data here

        SECTION BSS,BSS_C     ; Variables
        ; Your variables here

        SECTION CHIP,DATA_C   ; Must be in Chip RAM
        ; Screen buffers, copper lists, sprites

        END                   ; MANDATORY!
```

## The Copper
The Copper is a display synchronized coprocessor. It can:
- Change colors per scanline
- Modify any hardware register
- Create raster effects
- Control display timing

### Copper List Structure
```assembly
Copper_List:
        dc.w    BPLCON0,$1200    ; One bitplane
        dc.w    COLOR00,$000     ; Background color
        dc.w    $3001,$FFFE      ; Wait for line $30
        dc.w    COLOR00,$F00     ; Change to red
        dc.l    $FFFFFFFE        ; End list
```

### Common Copper Instructions
- **WAIT**: Wait for specific screen position
- **MOVE**: Write to hardware register
- **SKIP**: Skip next instruction if beam past position

## The Blitter
The Blitter is a hardware-accelerated graphics processor:

### Basic Operations
- Area Fill
- Line Drawing
- Block Copy
- Pattern Drawing

### Blitter Example
```assembly
Draw_Line:
        moveq   #-1,d1               ; Pattern all ones
        move.l  d1,BLTAFWM(a6)       ; First/last word mask
        move.w  #$8000,BLTCON0(a6)   ; Line draw mode
        move.w  #$0000,BLTCON1(a6)   ; No fill
        move.l  #Screen,BLTDPTH(a6)  ; Destination
        move.w  #SIZE,BLTSIZE(a6)    ; Start operation
```

## Memory Management

### Memory Allocation
```assembly
        move.l  #MEMF_CHIP,d1    ; Chip memory
        move.l  #SIZE,d0         ; Bytes needed
        jsr     AllocMem         ; System call
```

### Memory Layout
- Keep data aligned on word boundaries
- Place frequently accessed data in Fast RAM
- Keep graphics data in Chip RAM
- Manage memory fragmentation

## Common Effects Implementation

### Double Buffering
```assembly
Swap_Buffers:
        movem.l DisplayBuffer,d0-d1  ; Get buffers
        exg     d0,d1               ; Swap them
        movem.l d0-d1,DisplayBuffer  ; Store back
```

### Color Cycling
```assembly
Update_Colors:
        lea     Colors,a0
        moveq   #NUM_COLORS-1,d7
.loop:  
        move.w  (a0),d0
        rol.w   #1,d0        ; Rotate colors
        move.w  d0,(a0)+
        dbf     d7,.loop
```

## Optimization Tips
1. Use moveq instead of move for small values
2. Utilize the Blitter for graphics operations
3. Keep critical data in registers
4. Use word operations when possible
5. Minimize memory access

## Common Pitfalls
1. Missing END directive
2. Unaligned memory access
3. Not waiting for Blitter
4. Wrong memory type for DMA
5. Incorrect interrupt handling

## Further Learning
- Amiga Hardware Reference Manual
- Demo scene source codes
- Online Amiga communities
- Practice with simple effects
- Use debugger in WinUAE

---
Remember: While these examples repeat code for clarity, real Amiga development would use includes and libraries to avoid duplication and maintain cleaner code structure.
