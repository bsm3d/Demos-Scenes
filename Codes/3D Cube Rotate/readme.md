# 3D Rotating Cubes: Modern HTML5 vs Classic Amiga Assembly
## A Comparative Implementation Guide

## Introduction

This tutorial will teach you how to create the classic demo effect of three nested rotating wireframe cubes, comparing modern web technology with retro Amiga assembly programming. This effect was popular in the demo scene of the late 1980s and early 1990s, demonstrating both artistic creativity and technical prowess.

### What You'll Learn

In this tutorial, you will learn:
- How to create and manipulate 3D wireframe objects
- Basic 3D mathematics including rotation matrices and perspective projection
- Double buffering techniques for smooth animation
- Color manipulation and basic graphics programming
- Performance optimization techniques
- The differences between modern and retro programming approaches

### Prerequisites

For the HTML5 version:
- Basic knowledge of HTML and JavaScript
- Understanding of Canvas 2D context
- Basic trigonometry concepts

For the Amiga Assembly version:
- Understanding of 68000 assembly language
- Knowledge of Amiga hardware architecture
- Familiarity with fixed-point mathematics

### Effect Breakdown

The 3D cube effect consists of several key components:

1. **Geometry Setup**
   - Defining cube vertices in 3D space
   - Creating edge connections between vertices
   - Setting up multiple cubes with different sizes

2. **3D Transformations**
   - Matrix-based rotation calculations
   - Independent rotation on X, Y, and Z axes
   - Offset calculations for nested cube animations

3. **Rendering Pipeline**
   - Perspective projection from 3D to 2D
   - Wireframe drawing algorithms
   - Screen coordinate transformation

4. **Animation System**
   - Timing and synchronization
   - Double buffering for smooth movement
   - Frame rate management

This tutorial explores how to create the classic demo effect of rotating 3D wireframe cubes, comparing a modern HTML5 Canvas implementation with its historical Amiga 68000 assembly counterpart.

### Part 1: Design Approach

Before diving into the implementation, let's understand the design approach for creating this effect:

1. **Planning the Scene**
   - Three concentric cubes with different sizes
   - Each cube rotates independently with an offset
   - Wireframe rendering for a classic demo look
   - Color differentiation between cubes

2. **Technical Considerations**
   - Efficient vertex and edge management
   - Smooth animation through proper timing
   - Screen clearing and redrawing optimization
   - Memory usage and performance balance

3. **Implementation Strategy**
   - Create reusable cube generation function
   - Implement flexible rotation system
   - Setup efficient rendering pipeline
   - Manage animation timing and synchronization

### Part 2: Basic Concepts

Both implementations share the same mathematical principles:
- 3D point rotation using transformation matrices
- Perspective projection
- Wireframe rendering
- Double buffering for smooth animation

### Part 2: HTML5 Canvas Implementation

The modern implementation uses JavaScript and HTML5 Canvas for rendering. Let's break down the key components:

#### 2.1 Setting Up the Canvas

```html
<canvas id="canvas"></canvas>
<script>
    const canvas = document.getElementById('canvas');
    const ctx = canvas.getContext('2d');
    
    // Handle window resizing
    function resizeCanvas() {
        canvas.width = window.innerWidth;
        canvas.height = window.innerHeight;
    }
</script>
```

#### 2.2 3D Point Definition

```javascript
function createCube(size) {
    return [
        [-size, -size, -size],  // Front bottom left
        [size, -size, -size],   // Front bottom right
        [size, size, -size],    // Front top right
        [-size, size, -size],   // Front top left
        [-size, -size, size],   // Back bottom left
        [size, -size, size],    // Back bottom right
        [size, size, size],     // Back top right
        [-size, size, size]     // Back top left
    ];
}
```

### Part 3: Amiga 68000 Assembly Implementation

Now let's look at how this would be implemented in Amiga assembly:

```assembly
; Constants and data structures
SCREEN_WIDTH     EQU     320
SCREEN_HEIGHT    EQU     256
NUM_POINTS       EQU     8

    SECTION BSS
vertices:        ds.w    3*NUM_POINTS    ; X,Y,Z coordinates
rotated:         ds.w    3*NUM_POINTS    ; Rotated coordinates
projected:       ds.w    2*NUM_POINTS    ; Projected X,Y coordinates

    SECTION CODE
init_cube:
    ; Initialize cube vertices
    lea     vertices,a0
    move.w  #-128,(a0)+    ; Point 0: -128,-128,-128
    move.w  #-128,(a0)+
    move.w  #-128,(a0)+
    move.w  #128,(a0)+     ; Point 1: 128,-128,-128
    move.w  #-128,(a0)+
    move.w  #-128,(a0)+
    ; ... remaining points ...
    rts
```

#### 3.1 Rotation Matrix Implementation

The key difference in the assembly version is the fixed-point math:

```assembly
; Rotate point around X axis
; Input: d0,d1,d2 = x,y,z coordinates
; Uses: d3,d4 for temporary calculations
rotate_x:
    ; y' = y*cos(angle) - z*sin(angle)
    ; z' = y*sin(angle) + z*cos(angle)
    move.w  d1,d3           ; Save Y
    muls    cos_angle,d1    ; Y * cos
    asr.l   #14,d1         ; Fixed point adjustment
    move.w  d2,d4           ; Save Z
    muls    sin_angle,d2    ; Z * sin
    asr.l   #14,d2         ; Fixed point adjustment
    sub.w   d2,d1          ; Y' = Y*cos - Z*sin
    
    move.w  d3,d2          ; Restore Y
    muls    sin_angle,d2    ; Y * sin
    asr.l   #14,d2         ; Fixed point
    move.w  d4,d3          ; Restore Z
    muls    cos_angle,d3    ; Z * cos
    asr.l   #14,d3         ; Fixed point
    add.w   d3,d2          ; Z' = Y*sin + Z*cos
    rts
```

### Part 4: Key Differences

1. **Memory Management**
   - HTML5: Automatic memory management through JavaScript
   - Amiga ASM: Manual memory management and copper list setup

2. **Math Operations**
   - HTML5: Floating-point math using JavaScript Math functions
   - Amiga ASM: Fixed-point math (typically 16.16 format)

```assembly
; Fixed point constants (16.16 format)
FIXED_SHIFT     EQU     16
FIXED_ONE       EQU     1<<FIXED_SHIFT
```

3. **Display Output**
   - HTML5: Automatic double buffering through Canvas
   - Amiga ASM: Manual bitplane and copper list management

```assembly
; Amiga display setup
init_display:
    move.l  #CUSTOM,a6
    move.w  #$1200,BPLCON0(a6)    ; 1 bitplane
    move.w  #$0000,BPLCON1(a6)    ; Scroll value = 0
    move.w  #$0000,BPLCON2(a6)    ; Sprite priorities
    move.w  #38,DDFSTRT(a6)       ; Display start
    move.w  #D_END,DDFSTOP(a6)    ; Display stop
    move.w  #$2c81,DIWSTRT(a6)    ; Display window start
    move.w  #$2cc1,DIWSTOP(a6)    ; Display window stop
    rts
```

4. **Performance Considerations**
   - HTML5: Relies on browser optimization and GPU acceleration
   - Amiga ASM: Direct hardware access and careful cycle counting

### Part 5: Drawing the Wireframe

HTML5 Version:
```javascript
edges.forEach(edge => {
    let p1 = rotate(cube.points[edge[0]], angleX, angleY, angleZ);
    let p2 = rotate(cube.points[edge[1]], angleX, angleY, angleZ);
    
    ctx.beginPath();
    ctx.moveTo(p1[0] * scale + centerX, p1[1] * scale + centerY);
    ctx.lineTo(p2[0] * scale + centerX, p2[1] * scale + centerY);
    ctx.stroke();
});
```

Amiga Assembly Version:
```assembly
draw_line:
    ; Input: d0,d1 = x1,y1  d2,d3 = x2,y2
    movem.l d0-d7/a0-a6,-(sp)
    
    ; Bresenham's line algorithm
    move.w  d2,d4
    sub.w   d0,d4          ; dx = x2-x1
    move.w  d3,d5
    sub.w   d1,d5          ; dy = y2-y1
    
    ; Calculate increment direction
    move.w  #1,d6          ; x increment
    tst.w   d4
    bge.s   .dx_pos
    neg.w   d6
    neg.w   d4
.dx_pos:
    
    ; ... rest of line drawing routine ...
    
    movem.l (sp)+,d0-d7/a0-a6
    rts
```

### Part 6: Animation Loop

HTML5 Version:
```javascript
function draw() {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    // ... rotation calculations ...
    requestAnimationFrame(draw);
}
```

Amiga Assembly Version:
```assembly
main_loop:
    btst    #6,CUSTOM+VHPOSR    ; Wait for vertical blank
    beq.s   main_loop
    
    bsr     clear_screen        ; Clear current buffer
    bsr     rotate_points       ; Update 3D rotations
    bsr     project_points      ; Project to 2D
    bsr     draw_edges         ; Draw wireframe
    bsr     swap_buffers       ; Flip display buffers
    
    bra     main_loop
```

### Conclusion

While both implementations achieve the same visual result, they showcase the evolution of graphics programming:

- The HTML5 version benefits from modern abstractions and ease of use
- The Amiga version demonstrates low-level optimization and hardware mastery
- Fixed-point vs floating-point math shows different approaches to performance
- Memory management and display synchronization highlight platform differences

Each approach has its advantages:
- HTML5: Rapid development, cross-platform compatibility, easy maintenance
- Amiga ASM: Maximum performance, precise control, minimal resource usage

This comparison shows how the fundamental principles of 3D graphics remain consistent, while implementation details evolve with technology.
