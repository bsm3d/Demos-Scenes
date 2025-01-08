# Boing Ball: Complete Implementation Guide and Technical Explanation
## A Deep Dive into Classic Demo Effects and Modern Web Implementation

Author: Benoit (BSM3D) Saint-Moulin
Website: www.bsm3d.com
© 2025 BSM3D

This tutorial is accompanied by a working HTML5 implementation (`BSM3D-boing-ball.html`) that you can run in any modern web browser to see the effect in action. The source code is extensively commented and can be used as a learning resource alongside this tutorial.

## How to Use This Tutorial

1. **View the Effect**: 
   - Open the provided `BSM3D-boing-ball.html` file in your web browser
   - No additional setup or libraries required
   - Works in any modern browser with HTML5 support

2. **Study the Code**:
   - The HTML file contains detailed comments explaining each part
   - You can modify values in real-time to see their effects
   - Use browser developer tools to inspect and debug

3. **Learn and Experiment**:
   - Follow this tutorial while referring to the working example
   - Try modifying parameters like ball size, physics, and colors
   - Use this as a base to create your own effects

## Introduction

The Boing Ball is one of the most iconic demonstrations of the Amiga's capabilities, originally created in 1984 by Dale Luck and RJ Mical. This bouncing red and white checkered ball became synonymous with the Amiga computer and represented a breakthrough in real-time 3D animation and physics simulation.

The effect consists of:
- A 3D sphere with red and white checker pattern
- Realistic bounce physics with damping
- Smooth rotation animation
- Classic Amiga-style background grid
- Dynamic shadow projection

This implementation recreates this historic demo using modern web technologies while staying true to the original's visual style and feel.

### Why Compare with Amiga Assembly?

Throughout this tutorial, we present both modern HTML5/JavaScript code and classic Amiga assembly implementations side by side. This comparison serves multiple purposes:

1. **Historical Context**:
   - Shows how this iconic effect was originally achieved
   - Demonstrates the evolution of graphics and physics simulation
   - Highlights the innovative techniques used in 1984

2. **Educational Value**:
   - Contrasts high-level vs low-level approaches to graphics
   - Shows different ways to handle physics simulation
   - Illustrates optimization techniques across platforms

3. **Technical Understanding**:
   - Modern canvas drawing vs hardware sprites
   - Floating-point vs fixed-point mathematics
   - Memory and performance considerations

4. **Programming Techniques**:
   - Different approaches to 3D rendering
   - Physics simulation methods
   - Color and pattern manipulation

## Core Concepts

Let's break down the key components of the effect:

1. **3D Sphere Generation**
   - Mathematical sphere generation
   - Checkerboard pattern mapping
   - Point projection and depth sorting

2. **Physics Simulation**
   - Gravity and velocity calculations
   - Bounce detection and response
   - Energy damping for realism

3. **Visual Elements**
   - Background grid rendering
   - Dynamic shadow casting
   - Depth-based shading

## Part 1: Implementation Comparison

### Modern HTML5 vs Amiga Assembly

Let's explore how each platform handles different aspects:

**HTML5 Version**
- Uses Canvas 2D context for rendering
- Floating-point physics calculations
- Built-in color and transparency support
- Dynamic resolution support

**Amiga Assembly Version**
- Hardware sprite multiplexing
- Copper list color manipulation
- Fixed-point mathematics
- Hardware-specific optimizations

## Part 2: Detailed HTML5 Implementation

### Basic Setup and Structure

```html
<style>
    body { 
        margin: 0;
        overflow: hidden;
        background-color: #a8b0c0;  /* Classic Amiga background color */
        display: flex;
        justify-content: center;
        align-items: center;
        height: 100vh;
    }
    canvas { 
        background-color: #a8b0c0;
        image-rendering: pixelated;
        image-rendering: crisp-edges;
    }
</style>
```

Important style considerations:
- Amiga-authentic background color
- Pixel-perfect rendering settings
- Centered canvas display
- Full viewport height usage

### Configuration Constants

```javascript
const BALL_RADIUS = 100;       // Ball size in pixels
const ROTATION_SPEED = 0.02;    // Speed of ball rotation
const BOUNCE_SPEED = 2;         // Initial bounce velocity
const GRAVITY = 0.2;            // Gravity strength
const DAMPING = 0.98;           // Bounce energy loss
const CHECKER_SIZE = 8;         // Checker pattern repeats
```

These constants control:
1. Physical dimensions and appearance
2. Animation timing and speed
3. Physics behavior and feel
4. Visual pattern density

### 3D Point Management

```javascript
function rotateAndProject(x, y, z, rotX, rotY) {
    // Rotate around Y axis first
    let x1 = x * Math.cos(rotY) - z * Math.sin(rotY);
    let z1 = z * Math.cos(rotY) + x * Math.sin(rotY);

    // Then rotate around X axis
    let y2 = y * Math.cos(rotX) - z1 * Math.sin(rotX);
    let z2 = z1 * Math.cos(rotX) + y * Math.sin(rotX);

    // Apply perspective projection
    let scale = 400 / (400 + z2);
    return {
        x: x1 * scale,
        y: y2 * scale,
        z: z2,
        visible: z2 > 0
    };
}
```

This function handles:
1. Sequential axis rotations
2. Perspective projection
3. Visibility determination
4. Scale calculations

### Sphere Generation and Rendering

```javascript
function drawBall(centerX, centerY, radius) {
    const resolution = 50;
    const spherePoints = [];

    // Generate sphere points
    for (let lat = 0; lat <= resolution; lat++) {
        const theta = lat * Math.PI / resolution;
        for (let lon = 0; lon <= resolution; lon++) {
            const phi = lon * 2 * Math.PI / resolution;

            // Calculate 3D coordinates
            const x = radius * Math.sin(theta) * Math.cos(phi);
            const y = radius * Math.sin(theta) * Math.sin(phi);
            const z = radius * Math.cos(theta);

            // Calculate pattern
            const u = (lon / resolution) * CHECKER_SIZE;
            const v = (lat / resolution) * CHECKER_SIZE;
            const isRed = (Math.floor(u) + Math.floor(v)) % 2 === 0;

            // Project point
            const projected = rotateAndProject(x, y, z, rotationX, rotationY);
            // ... point processing ...
        }
    }
}
```

The sphere generation process:
1. Creates points using spherical coordinates
2. Maps checker pattern to surface
3. Projects points to 2D
4. Handles depth sorting

### Physics System

```javascript
function updatePhysics() {
    velocityY += GRAVITY;
    ballY += velocityY;

    // Handle floor bounce
    if (ballY > canvas.height - BALL_RADIUS) {
        ballY = canvas.height - BALL_RADIUS;
        velocityY = -velocityY * DAMPING;
    }

    // Handle ceiling bounce
    if (ballY < BALL_RADIUS) {
        ballY = BALL_RADIUS;
        velocityY = Math.abs(velocityY) * DAMPING;
    }
}
```

Physics implementation features:
1. Gravity acceleration
2. Collision detection
3. Energy conservation
4. Bounce damping

## Part 3: Amiga Implementation

### Hardware Sprite Setup

```assembly
; Sprite control registers
SPRPOS      EQU     $140     ; Sprite position register
SPRCTL      EQU     $142     ; Sprite control register
SPRDATA     EQU     $144     ; Sprite data register

init_sprites:
    move.w  #$1200,BPLCON0(a6)    ; Enable sprites
    move.w  #$0000,BPLCON1(a6)    ; No scrolling
    
    ; Setup ball sprite
    lea     ball_data,a0          ; Pointer to sprite data
    move.l  a0,SPR0PTH(a6)        ; Set sprite pointer
    move.w  #$8000,SPRCTL(a6)     ; Enable sprite
    rts
```

### Fixed-Point Physics

```assembly
; Physics constants (16.16 fixed point)
GRAVITY     EQU     $00000333  ; ~0.2 in fixed point
DAMPING     EQU     $0000FB33  ; ~0.98 in fixed point

update_ball:
    ; Update velocity
    move.l  velocity_y,d0
    add.l   #GRAVITY,d0       ; Add gravity
    move.l  d0,velocity_y
    
    ; Update position
    move.l  ball_y,d1
    add.l   d0,d1            ; Add velocity to position
    
    ; Check bounds and bounce
    cmp.l   #FLOOR_Y,d1
    blt.s   .no_bounce
    neg.l   d0              ; Reverse velocity
    muls    #DAMPING,d0     ; Apply damping
    asr.l   #16,d0          ; Fix point adjust
    move.l  #FLOOR_Y,d1     ; Set to floor position
.no_bounce:
    move.l  d1,ball_y       ; Store new position
    rts
```

## Part 4: Visual Effects

### Shadow Implementation

HTML5 Version:
```javascript
function drawShadow(x, y) {
    const shadowY = canvas.height - 20;
    const scale = 1 - (shadowY - y) / (canvas.height * 0.8);
    
    ctx.save();
    ctx.translate(x, shadowY);
    ctx.scale(1, 0.2);  // Flatten to create oval shadow
    
    ctx.beginPath();
    ctx.arc(0, 0, BALL_RADIUS * scale, 0, Math.PI * 2);
    ctx.fillStyle = 'rgba(80, 40, 120, 0.5)';
    ctx.fill();
    
    ctx.restore();
}
```

Amiga Version:
```assembly
draw_shadow:
    ; Calculate shadow scale based on ball height
    move.l  ball_y,d0
    sub.l   #FLOOR_Y,d0
    asr.l   #4,d0           ; Scale factor
    
    ; Update shadow sprite
    move.w  d0,SPRCTL(a6)   ; Set sprite height
    rts
```

### Grid Background

HTML5 Version:
```javascript
function drawGrid() {
    ctx.strokeStyle = '#8040c0';  // Classic Amiga purple
    ctx.lineWidth = 1;

    // Draw grid lines...
}
```

Amiga Version:
```assembly
; Use Copper list for grid
copper_list:
    dc.w    COLOR00,$0abc    ; Background color
    dc.w    COLOR01,$8040    ; Grid color
    dc.w    $2c01,$FFFE      ; Wait for line
    ; ... more copper instructions ...
```

## Conclusion

The Boing Ball demonstrates:
- Evolution of graphics techniques
- Different approaches to physics simulation
- Platform-specific optimizations
- Historical significance in computer graphics

The modern implementation maintains the spirit of the original while leveraging current technology for enhanced visual quality and performance.

Enjoy, Explore !
