# Moving Dot Tunnel: Complete Implementation Guide and Technical Explanation
## A Deep Dive into Classic Demo Effects and Modern Web Implementation

Author: Benoit (BSM3D) Saint-Moulin
Website: www.bsm3d.com
© 2025 BSM3D

This tutorial is accompanied by a working HTML5 implementation (`BSM3D-dot-tunnel.html`) that you can run in any modern web browser to see the effect in action. The source code is extensively commented and can be used as a learning resource alongside this tutorial.

## How to Use This Tutorial

1. **View the Effect**: 
   - Open the provided `BSM3D-dot-tunnel.html` file in your web browser
   - No additional setup or libraries required
   - Works in any modern browser with HTML5 support

2. **Study the Code**:
   - The HTML file contains detailed comments explaining each part
   - You can modify values in real-time to see their effects
   - Use browser developer tools to inspect and debug

3. **Learn and Experiment**:
   - Follow this tutorial while referring to the working example
   - Try modifying parameters like point counts, speeds, and depths
   - Use this as a base to create your own tunnel effects

## Introduction

The Moving Dot Tunnel effect is a classic demo scene technique that creates the illusion of movement through a 3D tunnel using simple 2D points. By arranging points in concentric circles and manipulating their positions and sizes based on perspective, this effect creates a compelling sense of depth and motion.

The effect consists of:
- Multiple layers of circular point arrangements
- Perspective-based point scaling
- Forward motion simulation
- Dynamic point coloring based on depth
- Smooth circular motion effects

Our implementation recreates this classic effect while adding modern enhancements like smooth color gradients and motion blur.

### Why Compare with Amiga Assembly?

Throughout this tutorial, we present both modern HTML5/JavaScript code and classic Amiga assembly implementations side by side. This comparison serves multiple purposes:

1. **Historical Context**:
   - Shows how 3D illusions were created with limited hardware
   - Demonstrates the evolution of visual effects
   - Highlights optimization techniques of the era

2. **Educational Value**:
   - Contrasts high-level vs low-level approaches
   - Shows different ways to handle perspective
   - Illustrates optimization across platforms

3. **Technical Understanding**:
   - Point plotting techniques
   - Perspective calculation methods
   - Memory and performance considerations

4. **Programming Techniques**:
   - Different approaches to animation
   - Point management strategies
   - Screen update methods

## Core Concepts

Let's break down the key components:

1. **Circular Point Arrangement**
   - Multiple concentric circles of points
   - Z-depth management
   - Point distribution algorithms

2. **Perspective System**
   - Distance-based scaling
   - Point size variation
   - Color intensity mapping

3. **Motion Effects**
   - Forward movement simulation
   - Circular wobble
   - Smooth transitions

## Part 2: Detailed HTML5 Implementation

### Configuration and Constants

```javascript
const NUM_CIRCLES = 16;        // Number of circles in the tunnel
const POINTS_PER_CIRCLE = 32;  // Number of points in each circle
const MAX_RADIUS = Math.min(canvas.width, canvas.height) * 0.45;
const MIN_RADIUS = 10;         // Minimum radius for the farthest circle
const Z_SPEED = 0.003;         // Speed of tunnel movement
const MOTION_SCALE = 0.02;     // Scale of the forward motion effect
```

These constants define:
1. Tunnel structure and density
2. Size and scale limits
3. Movement characteristics
4. Animation timing

### Circle Initialization

```javascript
function initCircles() {
    circles = [];
    for(let i = 0; i < NUM_CIRCLES; i++) {
        circles.push({
            z: i / NUM_CIRCLES,
            points: []
        });
    }
}
```

This function:
1. Creates the basic tunnel structure
2. Distributes circles evenly in Z-space
3. Prepares for point calculations
4. Sets up depth management

### Point Generation

```javascript
function calculatePoints(circle, moveOffset) {
    circle.points = [];
    const perspective = 1 / (circle.z + 1 + moveOffset);
    const radius = MIN_RADIUS + (MAX_RADIUS - MIN_RADIUS) * perspective;
    
    for(let i = 0; i < POINTS_PER_CIRCLE; i++) {
        const angle = (i / POINTS_PER_CIRCLE) * Math.PI * 2;
        const wobble = Math.sin(moveTime * 2 + circle.z * 4) * MOTION_SCALE;
        circle.points.push({
            x: (Math.cos(angle) * radius) * (1 + wobble),
            y: (Math.sin(angle) * radius) * (1 + wobble)
        });
    }
}
```

Key aspects:
1. **Perspective Calculation**:
   - Uses inverse distance for scaling
   - Applies motion offset for depth effect
   - Interpolates between radius limits

2. **Point Distribution**:
   - Even angular spacing
   - Circular arrangement
   - Wobble effect for organic motion

3. **Position Calculation**:
   - Trigonometric point placement
   - Radius modification
   - Movement integration

### Point Rendering

```javascript
function drawPoint(x, y, z) {
    const size = Math.max(1, Math.floor(3 * (1 - z)));
    const intensity = Math.floor(255 * (1 - z * 0.8));
    const r = intensity;
    const g = intensity * 0.5;
    const b = intensity * 0.8;
    ctx.fillStyle = `rgb(${r}, ${g}, ${b})`;
    ctx.fillRect(x - size/2, y - size/2, size, size);
}
```

This function handles:
1. **Size Calculation**:
   - Depth-based scaling
   - Minimum size limit
   - Centered rendering

2. **Color Generation**:
   - Depth-based intensity
   - Color channel variation
   - Smooth gradients

## Part 3: Animation System

### Main Animation Loop

```javascript
function animate() {
    ctx.fillStyle = 'rgba(0, 0, 0, 0.2)';
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    const centerX = canvas.width / 2;
    const centerY = canvas.height / 2;

    moveTime += 0.016;
    const moveOffset = Math.sin(moveTime) * MOTION_SCALE;

    circles.forEach(circle => {
        circle.z -= Z_SPEED;
        if (circle.z <= 0) circle.z += 1;
        calculatePoints(circle, moveOffset);
        // Draw points...
    });

    requestAnimationFrame(animate);
}
```

Animation features:
1. **Motion Trail**:
   - Semi-transparent background clear
   - Smooth motion blur effect
   - Depth persistence

2. **Movement Management**:
   - Time-based updates
   - Circular motion offset
   - Z-depth cycling

3. **Point Updates**:
   - Position recalculation
   - Depth management
   - Perspective updates

## Part 4: Amiga Implementation

### Point Plotting System

```assembly
; Plot a point with size based on Z
plot_point:
    movem.l d0-d7/a0-a6,-(sp)
    
    ; Calculate size based on Z
    move.w  d2,d3           ; Z coordinate
    neg.w   d3
    add.w   #256,d3        ; Reverse Z (0-255)
    lsr.w   #6,d3          ; Scale to 0-3
    addq.w  #1,d3          ; Minimum size 1
    
    ; Plot based on size
    move.w  d3,d4          ; Size counter
.size_loop:
    bsr     plot_pixel
    dbf     d4,.size_loop
    
    movem.l (sp)+,d0-d7/a0-a6
    rts
```

### Circle Generation

```assembly
init_circles:
    lea     circle_data,a0
    moveq   #NUM_CIRCLES-1,d7
.circle_loop:
    move.w  d7,d0
    mulu    #256/NUM_CIRCLES,d0  ; Z spacing
    move.w  d0,(a0)+            ; Store Z
    dbf     d7,.circle_loop
    rts
```

## Part 5: Visual Enhancements

### Motion Blur Effect

```javascript
// HTML5 Version
ctx.fillStyle = 'rgba(0, 0, 0, 0.2)';
ctx.fillRect(0, 0, canvas.width, canvas.height);
```

```assembly
; Amiga Version - Fade using copper
fade_screen:
    move.w  #4,d0          ; Fade amount
.fade_loop:
    move.l  screen_ptr,a0
    move.w  #(320*256/32)-1,d7
.pixel_loop:
    move.l  (a0),d1
    lsr.l   #1,d1          ; Divide by 2
    move.l  d1,(a0)+
    dbf     d7,.pixel_loop
    dbf     d0,.fade_loop
    rts
```

### Color Gradients

```javascript
// HTML5 Version
const intensity = Math.floor(255 * (1 - z * 0.8));
const r = intensity;
const g = intensity * 0.5;
const b = intensity * 0.8;
```

```assembly
; Amiga Version - Color lookup table
color_table:
    dc.w    $0000,$0111,$0222,$0333
    dc.w    $0444,$0555,$0666,$0777
    ; ... more color values
```

## Conclusion

The Moving Dot Tunnel effect demonstrates:
- Effective use of perspective techniques
- Different approaches to animation
- Platform-specific optimizations
- Evolution of visual effects

The modern implementation maintains the classic feel while adding contemporary enhancements for improved visual quality.

Enjoy, Explore ;)
