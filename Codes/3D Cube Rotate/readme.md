# 3D Cube: Complete Implementation Guide and Technical Explanation
## A Deep Dive into 3D Graphics and Modern Web Implementation

Author: Benoit (BSM3D) Saint-Moulin
Website: www.bsm3d.com
© 2025 BSM3D

This tutorial is accompanied by a working HTML5 implementation (`BSM3D-3d-cube.html`) that you can run in any modern web browser to see the effect in action. The source code is extensively commented and can be used as a learning resource alongside this tutorial.

## How to Use This Tutorial

1. **View the Effect**: 
   - Open the provided `BSM3D-3d-cube.html` file in your web browser
   - No additional setup or libraries required
   - Works in any modern browser with HTML5 support

2. **Study the Code**:
   - The HTML file contains detailed comments explaining each part
   - You can modify values in real-time to see their effects
   - Use browser developer tools to inspect and debug

3. **Learn and Experiment**:
   - Follow this tutorial while referring to the working example
   - Try modifying parameters like rotation speeds, colors, and cube sizes
   - Use this as a base to create your own 3D effects

## Introduction

3D cube rendering is a fundamental concept in computer graphics, serving as a gateway to understanding 3D transformations, perspective projection, and wireframe rendering. This effect was particularly popular in the demo scene of the late 1980s and early 1990s, showcasing both technical prowess and artistic creativity.

In this implementation, we create three nested wireframe cubes rotating at different speeds and offsets, creating a mesmerizing display of 3D graphics. This effect demonstrates key concepts of real-time 3D graphics while paying homage to classic demo scene techniques.

The effect consists of:
- Three concentric wireframe cubes of different sizes
- Independent rotation on all axes
- Color differentiation between cubes
- Perspective projection for depth
- Smooth animation and synchronization

This tutorial explores both the mathematical concepts and their practical implementation in modern web technologies, while also examining how similar effects were achieved on classic hardware like the Amiga.

### Why Compare with Amiga Assembly?

Throughout this tutorial, we present both modern HTML5/JavaScript code and classic Amiga assembly implementations side by side. This comparison serves multiple purposes:

1. **Historical Context**:
   - Shows how effects were achieved with limited hardware
   - Demonstrates the evolution of graphics programming
   - Highlights the ingenuity of early demo scene programmers

2. **Educational Value**:
   - Contrasts high-level vs low-level programming approaches
   - Shows how the same mathematical concepts apply across platforms
   - Illustrates different optimization techniques

3. **Technical Understanding**:
   - Modern abstractions vs direct hardware manipulation
   - Memory management differences
   - Performance considerations across eras

4. **Programming Techniques**:
   - Fixed-point vs floating-point mathematics
   - Hardware-specific optimizations
   - Memory and resource management strategies

This dual approach helps developers understand both modern and classic techniques, providing insight into the fundamentals of 3D graphics programming.

### What You'll Learn

Before diving into implementations, let's understand the key concepts:

1. **Three Concentric Cubes**
   - Our demo features three nested wireframe cubes
   - Each cube has different size and rotation offset
   - The cubes rotate independently but in sync

2. **3D to 2D Projection**
   - Converting 3D coordinates to 2D screen space
   - Applying perspective for depth effect
   - Managing multiple rotation axes

3. **Animation and Timing**
   - Smooth rotation using time-based animation
   - Independent control of each axis
   - Synchronized movement between cubes

## Part 1: Mathematical Foundation

### 3D Coordinate System

The 3D coordinate system is the foundation of our cube implementation:

1. **Basic Concepts**
   - X-axis: horizontal (left/right)
   - Y-axis: vertical (up/down)
   - Z-axis: depth (in/out of screen)
   - Origin point (0,0,0)

2. **Key Features**
   - Right-handed coordinate system
   - Perspective projection
   - Matrix transformations
   - Vector operations

### Understanding Rotation Mathematics

Before looking at the implementations, let's understand the mathematics:

1. **Rotation Matrices**
   - Each axis rotation is represented by a 2D transformation
   - Order of rotations matters (they are not commutative)
   - Composite rotations combine multiple axes

2. **Fixed-Point vs Floating-Point**
   - HTML5 uses native floating-point math
   - Amiga uses fixed-point for performance
   - Both achieve the same visual result

## Part 2: Implementation Comparison

### Modern HTML5 vs Amiga Assembly

Let's explore both modern web and classic Amiga implementations:

**HTML5 Version**
- Uses floating-point mathematics
- Hardware-accelerated canvas rendering
- Dynamic color manipulation
- Modern JavaScript syntax

**Amiga Assembly Version**
- Fixed-point mathematics (16.16 format)
- Direct bitplane manipulation
- Hardware sprite utilization
- Manual memory allocation

## Part 3: HTML5 Implementation In Detail

### Basic Setup and Structure

```html
<!DOCTYPE html>
<html lang="fr">
<head>
    <style>
        body { 
            margin: 0; 
            overflow: hidden; 
            background-color: black;
        }
        canvas { 
            display: block; 
            background-color: black;
        }
    </style>
</head>
```

These CSS rules are crucial because:
- `margin: 0` prevents unwanted spacing
- `overflow: hidden` prevents scrollbars
- `background-color: black` creates the void effect
- `display: block` removes inline canvas spacing

### Canvas Setup and Management

```javascript
const canvas = document.getElementById('canvas');
const ctx = canvas.getContext('2d');

function resizeCanvas() {
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
}
```

Understanding the canvas setup:
1. We get a 2D rendering context
2. The resize function handles window changes
3. Canvas dimensions match the window
4. Event listener keeps it responsive

### Cube Data Structure

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

This structure is elegant because:
1. Each vertex is relative to center (0,0,0)
2. Single size parameter scales the entire cube
3. Vertices are ordered for easy edge connections
4. The cube is symmetrical around its center

### Edge Definition System

```javascript
const edges = [
    [0, 1], [1, 2], [2, 3], [3, 0],  // Front face
    [4, 5], [5, 6], [6, 7], [7, 4],  // Back face
    [0, 4], [1, 5], [2, 6], [3, 7]   // Connecting edges
];
```

The edge system:
1. Defines connections between vertices
2. Creates a complete wireframe structure
3. Optimizes drawing by reusing vertices
4. Maintains visual clarity

## Part 4: Amiga Implementation In Detail

### Memory and Display Setup

```assembly
; Constants and data structures
SCREEN_WIDTH     EQU     320
SCREEN_HEIGHT    EQU     256
NUM_POINTS       EQU     8

    SECTION BSS
vertices:        ds.w    3*NUM_POINTS    ; X,Y,Z coordinates
rotated:        ds.w    3*NUM_POINTS    ; Rotated coordinates
projected:      ds.w    2*NUM_POINTS    ; Projected X,Y coordinates

    SECTION CODE
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

Understanding the Amiga setup:
1. Screen dimensions are fixed
2. Memory is pre-allocated for all points
3. Display registers are manually configured
4. Bitplane mode is set for wireframe rendering

### Fixed-Point Mathematics

```assembly
; Fixed point constants (16.16 format)
FIXED_SHIFT     EQU     16
FIXED_ONE       EQU     1<<FIXED_SHIFT

; Rotation calculation
rotate_point:
    movem.l d0-d7/a0-a6,-(sp)
    
    ; Calculate rotation matrix...
    ; Transform point...
    
    movem.l (sp)+,d0-d7/a0-a6
    rts
```

The fixed-point system:
1. Uses 16.16 format for precision
2. Implements multiplication and division
3. Handles rotation calculations efficiently
4. Maintains accuracy without floating-point

## Part 5: Animation Systems

### HTML5 Animation Loop

```javascript
function draw() {
    // Calculate rotation angles
    let baseAngleX = Date.now() * 0.001;    // X rotation speed
    let baseAngleY = Date.now() * 0.0005;   // Y rotation speed
    let baseAngleZ = Date.now() * 0.00075;  // Z rotation speed

    cubes.forEach(cube => {
        ctx.strokeStyle = cube.color;
        let angleX = baseAngleX + cube.offset;
        let angleY = baseAngleY + cube.offset;
        let angleZ = baseAngleZ + cube.offset;

        // Draw edges...
    });

    requestAnimationFrame(draw);
}
```

Key animation features:
1. Time-based rotation for smooth motion
2. Different speeds per axis
3. Independent cube rotations
4. Synchronized with screen refresh

### Amiga Animation Loop

```assembly
main_loop:
    btst    #6,CUSTOM+VHPOSR    ; Wait for vertical blank
    beq.s   main_loop
    
    bsr     clear_screen        ; Clear current buffer
    bsr     update_rotation     ; Update angles
    bsr     transform_points    ; Apply rotations
    bsr     draw_edges         ; Draw wireframe
    bsr     swap_buffers       ; Flip display buffers
    
    bra     main_loop
```

Amiga animation features:
1. Synchronized with display beam
2. Double buffering for smooth display
3. Hardware-level timing
4. Efficient screen clearing

## Part 6: Advanced Techniques

### 1. Multiple Cubes (HTML5)

```javascript
const cubes = [
    { points: createCube(1), color: 'white', offset: 0 },
    { points: createCube(0.6), color: 'red', offset: Math.PI / 12 },
    { points: createCube(0.3), color: 'cyan', offset: Math.PI / 6 }
];
```

Multi-cube system benefits:
1. Independent size control
2. Unique colors per cube
3. Offset rotations
4. Easy to extend

### 2. Optimizations

**HTML5 Optimization**
```javascript
// Batch rendering for performance
ctx.beginPath();
edges.forEach(edge => {
    // Draw all edges in a single path
    ctx.moveTo(p1[0], p1[1]);
    ctx.lineTo(p2[0], p2[1]);
});
ctx.stroke(); // Single stroke call
```

**Amiga Optimization**
```assembly
; Use blitter for line drawing
blit_line:
    move.w  #$8000,BLTCON0(a6)  ; A->D copy
    move.w  #$0000,BLTCON1(a6)  ; No fill mode
    ; ... efficient line drawing ...
```

## Conclusion

The 3D cube implementation showcases:
- Mathematical principles of 3D graphics
- Different approaches to the same visual goal
- Performance optimization techniques
- Platform-specific advantages

This foundation can be expanded to create more complex 3D graphics and animations in both modern and retro platforms.

## Further Reading

1. Linear Algebra and 3D Transformations
2. Canvas Performance Optimization
3. Advanced 3D Graphics Techniques
4. WebGL and Three.js for complex 3D
5. Amiga Hardware Programming
6. Demo Scene History and Techniques
