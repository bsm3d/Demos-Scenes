# Copper Bars: Complete Implementation Guide and Technical Explanation
## A Deep Dive into Classic Demo Effects and Modern Web Implementation

Author: Benoit (BSM3D) Saint-Moulin
Website: www.bsm3d.com
© 2025 BSM3D

This tutorial is accompanied by a working HTML5 implementation (`BSM3D-copper-bars.html`) that you can run in any modern web browser to see the effect in action. The source code is extensively commented and can be used as a learning resource alongside this tutorial.

## How to Use This Tutorial

1. **View the Effect**: 
   - Open the provided `BSM3D-copper-bars.html` file in your web browser
   - No additional setup or libraries required
   - Works in any modern browser with HTML5 support

2. **Study the Code**:
   - The HTML file contains detailed comments explaining each part
   - You can modify values in real-time to see their effects
   - Use browser developer tools to inspect and debug

3. **Learn and Experiment**:
   - Follow this tutorial while referring to the working example
   - Try modifying parameters like bar count, colors, and movements
   - Use this as a base to create your own effects

## Introduction

The Copper Bars effect is one of the most iconic visual effects from the Amiga demo scene. Named after the Amiga's Copper co-processor (which could change color registers during screen drawing), this effect creates smoothly moving color bars that became a hallmark of Amiga demos in the late 1980s and early 1990s.

The effect consists of:
- Smoothly moving horizontal color bars
- Dynamic color gradients
- Rainbow color cycling
- Shine effects and transparency
- Fluid sinusoidal motion

Our modern implementation recreates this classic effect while adding contemporary touches like alpha blending and HSL color space manipulation.

### Why Compare with Amiga Assembly?

Throughout this tutorial, we present both modern HTML5/JavaScript code and classic Amiga assembly implementations side by side. This comparison serves multiple purposes:

1. **Historical Context**:
   - Shows how the original effect utilized the Copper co-processor
   - Demonstrates the evolution of color manipulation techniques
   - Highlights the innovative use of hardware capabilities

2. **Educational Value**:
   - Contrasts high-level vs low-level color manipulation
   - Shows different approaches to animation timing
   - Illustrates platform-specific optimization techniques

3. **Technical Understanding**:
   - Modern gradient generation vs hardware color registers
   - Software-based timing vs hardware synchronization
   - Memory and performance considerations

4. **Programming Techniques**:
   - Different approaches to color cycling
   - Animation synchronization methods
   - Screen update management

## Core Concepts

Let's break down the key components:

1. **Color Bar Management**
   - Bar positioning and movement
   - Gradient generation
   - Color cycling logic

2. **Animation System**
   - Smooth sinusoidal movement
   - Phase offsets for variety
   - Time-based updates

3. **Visual Effects**
   - Gradient transparency
   - Shine effect
   - Color transitions

## Part 1: Implementation Comparison

### Modern HTML5 vs Amiga Assembly

Let's explore how each platform handles different aspects:

**HTML5 Version**
- Canvas gradient API
- HSL color space
- Alpha transparency
- RequestAnimationFrame timing

**Amiga Assembly Version**
- Copper color registers
- Hardware beam synchronization
- Direct memory timing
- Interrupt-driven updates

## Part 2: Detailed HTML5 Implementation

### Basic Setup and Structure

```html
<style>
    body { 
        margin: 0; 
        overflow: hidden; 
        background-color: #000;
    }
    canvas { 
        display: block; 
    }
</style>
```

Style considerations:
- Clean fullscreen setup
- No scrollbars or margins
- Pure black background
- Block display for canvas

### Bar Configuration and Initialization

```javascript
const NUM_BARS = 8;
const BAR_HEIGHT = 50;
let bars = [];

// Initialize bars with random properties
for (let i = 0; i < NUM_BARS; i++) {
    bars.push({
        baseY: i * (canvas.height / NUM_BARS),
        speed: 1 + Math.random() * 0.5,
        hue: i * (360 / NUM_BARS),
        phase: Math.random() * Math.PI * 2
    });
}
```

Bar initialization details:
1. Each bar has:
   - Base vertical position
   - Individual movement speed
   - Starting color (hue)
   - Phase offset for varied motion

2. Properties are calculated to ensure:
   - Even distribution across screen
   - Unique colors for each bar
   - Random but controlled movement

### Movement and Color System

```javascript
function draw() {
    const time = Date.now() * 0.001;

    bars.forEach(bar => {
        // Calculate position
        const y = (Math.sin(time * bar.speed + bar.phase) * 
                 (canvas.height - BAR_HEIGHT)) + canvas.height/2;

        // Create gradient
        const gradient = ctx.createLinearGradient(0, y, 0, y + BAR_HEIGHT);
        gradient.addColorStop(0, `hsla(${bar.hue}, 100%, 50%, 0.2)`);
        gradient.addColorStop(0.5, `hsla(${bar.hue}, 100%, 50%, 0.8)`);
        gradient.addColorStop(1, `hsla(${bar.hue}, 100%, 50%, 0.2)`);
        
        // Draw bar and shine
        ctx.fillStyle = gradient;
        ctx.fillRect(0, y, canvas.width, BAR_HEIGHT);
        
        // Add shine effect
        ctx.fillStyle = `hsla(${bar.hue}, 100%, 80%, 0.5)`;
        ctx.fillRect(0, y + BAR_HEIGHT/2 - 2, canvas.width, 4);

        // Update color
        bar.hue = (bar.hue + 0.5) % 360;
    });
}
```

Important aspects:
1. **Movement Calculation**:
   - Time-based animation for smooth motion
   - Sinusoidal movement for organic feel
   - Screen-height-aware boundaries
   - Phase offsets for variety

2. **Gradient Creation**:
   - Three-stop gradient for depth
   - Alpha transparency for trail effect
   - Color intensity variation
   - Dynamic positioning

3. **Shine Effect**:
   - Lighter color variant
   - Thin line for highlight
   - Positioned at bar center
   - Semi-transparent for blend

## Part 3: Amiga Implementation

### Copper List Setup

```assembly
; Copper list for color bars
copper_list:
    dc.w    $3001,$FFFE    ; Wait for line 48
    dc.w    COLOR00,$0000  ; Black background
    
    ; Bar 1 gradient
    dc.w    $3801,$FFFE    ; Wait for line
    dc.w    COLOR00,$0F00  ; Bright red
    dc.w    $3901,$FFFE
    dc.w    COLOR00,$0E00  ; Slightly darker
    dc.w    $3A01,$FFFE
    dc.w    COLOR00,$0D00  ; Continue gradient
```

### Color Cycling System

```assembly
update_colors:
    move.l  color_ptr,a0    ; Current color table
    moveq   #NUM_BARS-1,d7  ; Bar counter
.cycle:
    move.w  (a0)+,d0       ; Get color
    rol.w   #1,d0          ; Rotate color
    move.w  d0,-(a0)       ; Store back
    addq.l  #4,a0          ; Next color
    dbf     d7,.cycle
    rts
```

## Part 4: Animation System

### HTML5 Version
```javascript
function animate() {
    requestAnimationFrame(draw);
}
```

### Amiga Version
```assembly
copper_interrupt:
    movem.l d0-d7/a0-a6,-(sp)
    
    ; Update bar positions
    bsr     update_bars
    ; Update colors
    bsr     update_colors
    ; Wait for vertical blank
    bsr     wait_vbl
    
    movem.l (sp)+,d0-d7/a0-a6
    rte
```

## Part 5: Modern Enhancements

### Gradient Transparency

```javascript
const gradient = ctx.createLinearGradient(0, y, 0, y + BAR_HEIGHT);
gradient.addColorStop(0, `hsla(${bar.hue}, 100%, 50%, 0.2)`);
gradient.addColorStop(0.5, `hsla(${bar.hue}, 100%, 50%, 0.8)`);
gradient.addColorStop(1, `hsla(${bar.hue}, 100%, 50%, 0.2)`);
```

This creates:
- Soft edges for bars
- Overlapping blend effects
- Dynamic opacity
- Smooth color transitions

### Shine Effect

```javascript
// Add shine effect
ctx.fillStyle = `hsla(${bar.hue}, 100%, 80%, 0.5)`;
ctx.fillRect(0, y + BAR_HEIGHT/2 - 2, canvas.width, 4);
```

Features:
- Subtle highlight
- Dynamic positioning
- Color-matched glow
- Semi-transparent blend

## Conclusion

The Copper Bars effect demonstrates:
- Evolution of color manipulation techniques
- Different approaches to animation timing
- Platform-specific optimizations
- Blend of classic and modern effects

Our modern implementation maintains the spirit of the original while adding contemporary visual enhancements.

Enjoy, Explore ;)
