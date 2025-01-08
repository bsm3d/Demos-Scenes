# Amiga Copper Bars: Understanding the Hardware and Modern Recreation
## A Deep Dive into Amiga Graphics Hardware and Modern Web Implementation

Author: Benoit (BSM3D) Saint-Moulin
Website: www.bsm3d.com
© 2025 BSM3D

This tutorial is accompanied by a working HTML5 implementation (`BSM3D-copper-bars.html`) that you can run in any modern web browser to see the effect in action. The source code is extensively commented and can be used as a learning resource alongside this tutorial. Feel free to experiment with the code and modify parameters to understand how different values affect the final result.

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
   - Try modifying parameters like colors, speeds, and number of bars
   - Use this as a base to create your own effects

## Introduction

The Copper Bars effect was one of the most distinctive visual effects in Amiga demos, showcasing the unique capabilities of the Amiga's custom graphics hardware. This tutorial explores both the original hardware implementation and its modern web recreation.

### What You'll Learn
- Understanding the Amiga's Copper and Blitter coprocessors
- Color palette manipulation techniques
- Smooth gradient generation
- Animation timing and synchronization
- Modern implementation using HTML5 Canvas

## Part 1: The Amiga Hardware

### The Copper (Coprocessor)

The Copper (Co-Processor) was a unique feature of the Amiga's custom chipset that made effects like copper bars possible. Here's how it worked:

1. **Basic Function**
   - Synchronized with the video beam
   - Could modify hardware registers during screen drawing
   - Executed a simple instruction set (WAIT, MOVE, SKIP)

2. **Key Features**
   - Direct register access without CPU intervention
   - Precise timing with horizontal/vertical beam position
   - Could change color registers mid-screen
   - No computational overhead on the main CPU

### The Blitter

The Blitter (Block Image Transferer) was another key component:

1. **Main Functions**
   - High-speed memory copying
   - Line drawing
   - Area filling
   - Bitmap manipulation

2. **Features**
   - Hardware-accelerated operations
   - Multiple operating modes
   - Built-in logic operations
   - DMA-based transfers

## Part 2: Original Amiga Implementation

### Copper List Programming

```assembly
; Copper list for color bars
copper_list:
    ; Wait for specific screen position
    dc.w    $3001,$FFFE    ; WAIT for line 48
    
    ; Set color register 0
    dc.w    COLOR00,$0000  ; Black background
    
    ; Start of first bar
    dc.w    $3801,$FFFE    ; Wait for line 56
    dc.w    COLOR00,$0F00  ; Bright red
    
    ; Gradient effect
    dc.w    $3901,$FFFE
    dc.w    COLOR00,$0E00  ; Slightly darker red
    dc.w    $3A01,$FFFE
    dc.w    COLOR00,$0D00  ; Continue gradient
    ; ... more gradient steps ...

    dc.w    $FFFF,$FFFE    ; End of copper list
```

### Copper Bar Movement

```assembly
update_copper_bars:
    ; Calculate new Y positions
    move.w  frame_counter,d0
    lea     sine_table,a0
    lea     copper_list,a1
    
    moveq   #NUM_BARS-1,d7     ; Bar counter
.bar_loop:
    ; Calculate sine position
    and.w   #$FF,d0            ; Wrap to table size
    move.b  (a0,d0.w),d1       ; Get sine value
    add.w   #32,d0             ; Phase offset for next bar
    
    ; Update copper list wait position
    mulu    #COPPER_BAR_SIZE,d1
    add.w   #BASE_Y,d1         ; Add base position
    move.w  d1,2(a1)           ; Update WAIT instruction
    
    ; Move to next bar in copper list
    add.w   #COPPER_BAR_INSTRUCTIONS*4,a1
    dbf     d7,.bar_loop
    rts
```

## Part 3: Modern Web Implementation

### HTML5 Canvas Setup

```javascript
const canvas = document.getElementById('canvas');
const ctx = canvas.getContext('2d');

// Copper bars configuration
const NUM_BARS = 8;
const BAR_HEIGHT = 50;
let bars = [];

// Initialize bars
for (let i = 0; i < NUM_BARS; i++) {
    bars.push({
        baseY: i * (canvas.height / NUM_BARS),
        speed: 1 + Math.random() * 0.5,
        hue: i * (360 / NUM_BARS),
        phase: Math.random() * Math.PI * 2
    });
}
```

### Drawing the Bars

```javascript
function draw() {
    // Clear screen
    ctx.fillStyle = '#000';
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    const time = Date.now() * 0.001;

    bars.forEach(bar => {
        // Calculate Y position with sine wave
        const y = (Math.sin(time * bar.speed + bar.phase) * 
                 (canvas.height - BAR_HEIGHT)) + canvas.height/2;

        // Create gradient
        const gradient = ctx.createLinearGradient(0, y, 0, y + BAR_HEIGHT);
        gradient.addColorStop(0, `hsla(${bar.hue}, 100%, 50%, 0.2)`);
        gradient.addColorStop(0.5, `hsla(${bar.hue}, 100%, 50%, 0.8)`);
        gradient.addColorStop(1, `hsla(${bar.hue}, 100%, 50%, 0.2)`);

        // Draw bar with gradient
        ctx.fillStyle = gradient;
        ctx.fillRect(0, y, canvas.width, BAR_HEIGHT);

        // Add shine effect
        ctx.fillStyle = `hsla(${bar.hue}, 100%, 80%, 0.5)`;
        ctx.fillRect(0, y + BAR_HEIGHT/2 - 2, canvas.width, 4);
    });
}
```

## Part 4: Key Differences Between Implementations

### 1. Color Handling

**Amiga Hardware**
- Limited to 32 color registers
- Colors changed by modifying registers
- Hardware color cycling
- 12-bit color (4096 colors)

```assembly
; Color register modification
move.w  #$0F00,COLOR00(a6)  ; Set bright red
move.w  #$0FF0,COLOR01(a6)  ; Set bright yellow
```

**HTML5 Canvas**
- Full 24-bit color support
- Gradient and alpha transparency
- HSL color space for easy manipulation
- Unlimited colors

```javascript
// Modern color handling
gradient.addColorStop(0, `hsla(${hue}, 100%, 50%, 0.2)`);
```

### 2. Timing and Synchronization

**Amiga Hardware**
- Synchronized with video beam
- Precise timing control
- Limited by PAL/NTSC timing (50/60 Hz)

**HTML5 Canvas**
- RequestAnimationFrame timing
- Variable refresh rate support
- Time-based animation

### 3. Resource Usage

**Amiga Hardware**
- Direct hardware access
- Minimal CPU usage
- Limited by available color registers
- Fixed memory usage

**HTML5 Canvas**
- GPU-accelerated rendering
- Higher memory usage
- Dynamic resource allocation
- Flexible gradient generation

## Part 5: Advanced Techniques

### 1. Smooth Color Transitions

**Amiga Version**
```assembly
copper_gradient:
    ; Create smooth gradient by updating color each scanline
    dc.w    $3001,$FFFE
    dc.w    COLOR00,$0F00    ; Start color
    dc.w    $3101,$FFFE
    dc.w    COLOR00,$0E00    ; Slightly darker
    dc.w    $3201,$FFFE
    dc.w    COLOR00,$0D00    ; Continue gradient
```

**HTML5 Version**
```javascript
// Create smooth gradient
const gradient = ctx.createLinearGradient(0, y, 0, y + BAR_HEIGHT);
for (let i = 0; i <= 1; i += 0.1) {
    const alpha = Math.sin(i * Math.PI);
    gradient.addColorStop(i, `hsla(${bar.hue}, 100%, 50%, ${alpha})`);
}
```

### 2. Movement Patterns

**Amiga Version**
```assembly
; Sine table for smooth movement
sine_table:
    dc.b    0,2,4,6,8,10,12,14  ; Pre-calculated sine values
    dc.b    16,18,20,22,24,26,28,30
    ; ... more values ...
```

**HTML5 Version**
```javascript
// Smooth movement calculation
const y = Math.sin(time * bar.speed + bar.phase) * amplitude + offset;
```

## Conclusion

The Copper Bars effect demonstrates how different technologies can achieve similar results through different means:

- The Amiga version showcases efficient use of specialized hardware
- The HTML5 version offers more flexibility and modern features
- Both versions require careful attention to timing and color handling
- The basic principles remain the same despite technological differences

This comparison shows how far graphics programming has come while maintaining the creative spirit of the demo scene.