# Sinus Scroller: Complete Implementation Guide and Technical Explanation
## A Deep Dive into Classic Demo Effects and Modern Web Implementation

Author: Benoit (BSM3D) Saint-Moulin
Website: www.bsm3d.com
© 2025 BSM3D

This tutorial is accompanied by a working HTML5 implementation (`BSM3D-sinus-scroller.html`) that you can run in any modern web browser to see the effect in action. The source code is extensively commented and can be used as a learning resource alongside this tutorial.

## How to Use This Tutorial

1. **View the Effect**: 
   - Open the provided `BSM3D-sinus-scroller.html` file in your web browser
   - No additional setup or libraries required
   - Works in any modern browser with HTML5 support

2. **Study the Code**:
   - The HTML file contains detailed comments explaining each part
   - You can modify values in real-time to see their effects
   - Use browser developer tools to inspect and debug

3. **Learn and Experiment**:
   - Follow this tutorial while referring to the working example
   - Try modifying parameters like wave height, speed, and text properties
   - Use this as a base to create your own text effects

## Introduction

The Sinus Scroller is a quintessential demo scene effect from the late 1980s and early 1990s. It combines smooth text scrolling with sinusoidal wave motion, creating an engaging visual display often used for credits and messages in demos. This effect demonstrates mastery of both text rendering and mathematical animation.

The effect consists of:
- Smoothly scrolling text message
- Sinusoidal vertical movement
- Dynamic color cycling
- Text shadows for depth
- Infinite loop with seamless wrapping

Our modern implementation recreates this classic effect while adding contemporary touches like HSL color space and text shadows.

### Why Compare with Amiga Assembly?

Throughout this tutorial, we present both modern HTML5/JavaScript code and classic Amiga assembly implementations side by side. This comparison serves multiple purposes:

1. **Historical Context**:
   - Shows how text effects were achieved on vintage hardware
   - Demonstrates the evolution of text rendering techniques
   - Highlights creative use of limited resources

2. **Educational Value**:
   - Contrasts high-level vs low-level text handling
   - Shows different approaches to animation timing
   - Illustrates platform-specific optimization techniques

3. **Technical Understanding**:
   - Font rendering differences
   - Scrolling implementation methods
   - Memory and performance considerations

4. **Programming Techniques**:
   - Different approaches to text animation
   - Color cycling systems
   - Screen update strategies

## Core Concepts

Let's break down the key components:

1. **Text Management**
   - Character positioning and spacing
   - Scrolling mechanics
   - Font rendering

2. **Wave Motion**
   - Sinusoidal movement calculation
   - Time-based animation
   - Position offsetting

3. **Visual Effects**
   - Color cycling
   - Shadow rendering
   - Screen wrapping

## Part 2: Detailed HTML5 Implementation

### Configuration and Constants

```javascript
// Scroller configuration
const text = "    WELCOME TO THE CLASSIC SINUS SCROLLER DEMO...";
const CHAR_SIZE = 48;        // Font size
const CHAR_SPACING = 30;     // Space between characters
const SCROLL_SPEED = 2;      // Pixels per frame
const WAVE_HEIGHT = 40;      // Amplitude of sine wave
const WAVE_SPEED = 0.05;     // Wave movement speed
```

These constants define:
1. Visual appearance and sizing
2. Movement characteristics
3. Animation timing
4. Wave properties

### Text Rendering and Movement

```javascript
function draw() {
    ctx.font = `bold ${CHAR_SIZE}px monospace`;
    
    for (let i = 0; i < text.length; i++) {
        const char = text[i];
        const x = scrollOffset + (i * CHAR_SPACING);
        
        // Skip if outside screen
        if (x < -CHAR_SIZE || x > canvas.width + CHAR_SIZE) continue;

        const waveOffset = (x * 0.02) + (time * WAVE_SPEED);
        const y = centerY + Math.sin(waveOffset) * WAVE_HEIGHT;

        // Draw character
        drawCharacter(char, x, y, waveOffset);
    }
}
```

Key aspects:
1. **Character Positioning**:
   - Horizontal spacing calculation
   - Screen boundary checking
   - Smooth scrolling offset

2. **Wave Motion**:
   - Time-based wave calculation
   - Position-dependent offset
   - Amplitude control

3. **Optimization**:
   - Off-screen character skipping
   - Efficient screen updates
   - Memory usage control

### Color and Shadow System

```javascript
function drawCharacter(char, x, y, waveOffset) {
    const hue = (time * 30 + i * 5) % 360;
    const colorIntensity = (Math.sin(waveOffset) + 1) / 2;
    
    // Draw shadow
    ctx.fillStyle = 'rgba(0, 0, 0, 0.5)';
    ctx.fillText(char, x + 2, y + 2);

    // Draw colored character
    ctx.fillStyle = `hsl(${hue}, 100%, ${50 + (colorIntensity * 50)}%)`;
    ctx.fillText(char, x, y);
}
```

Visual effects details:
1. **Color Generation**:
   - HSL color space usage
   - Dynamic hue cycling
   - Intensity variation

2. **Shadow Implementation**:
   - Offset shadow positioning
   - Semi-transparent black
   - Depth enhancement

## Part 3: Amiga Implementation

### Font System

```assembly
; Font data structure
FONT_HEIGHT  EQU     16          ; Character height in pixels
FONT_WIDTH   EQU     8           ; Character width in pixels

font_data:
    ; Bitmap data for each character (8x16 pixels)
    dc.w    %0000000000000000   ; Space
    dc.w    %0011110000111100   ; A
    ; ... more character data ...

; Character plotting routine
plot_char:
    movem.l d0-d7/a0-a6,-(sp)
    
    ; Calculate character offset in font
    sub.b   #32,d0              ; ASCII adjustment
    mulu    #FONT_HEIGHT*2,d0   ; Bytes per character
    lea     font_data,a0
    add.l   d0,a0              ; Point to character data
    
    ; Plot character bitmap
    moveq   #FONT_HEIGHT-1,d7   ; Line counter
.char_loop:
    move.w  (a0)+,d0           ; Get character line
    bsr     plot_line          ; Draw the line
    addq.w  #1,d1              ; Next Y position
    dbf     d7,.char_loop
    
    movem.l (sp)+,d0-d7/a0-a6
    rts
```

### Sine Wave Calculation

```assembly
; Sine table with 256 entries (fixed point 8.8)
sine_table:
    dc.w    0,12,25,37,49,61,73,85,97,109,120,131,142,153,164,174
    ; ... more sine values ...

; Calculate Y position
calc_wave_y:
    move.w  d0,d1              ; X position
    lsr.w   #3,d1              ; Scale for table lookup
    add.w   wave_offset,d1     ; Add time-based offset
    and.w   #255,d1           ; Wrap to table size
    
    move.w  sine_table(d1*2),d2 ; Get sine value
    muls    #WAVE_HEIGHT,d2    ; Scale by height
    asr.l   #8,d2              ; Fixed point adjust
    
    add.w   #SCREEN_CENTER,d2  ; Center on screen
    rts
```

## Part 4: Animation System

### HTML5 Version
```javascript
function animate() {
    // Clear and update
    ctx.fillStyle = '#000';
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    // Draw characters
    drawText();

    // Update scroll position
    scrollOffset -= SCROLL_SPEED;
    if (scrollOffset < -(text.length * CHAR_SIZE)) {
        scrollOffset = canvas.width;
    }

    requestAnimationFrame(animate);
}
```

### Amiga Version
```assembly
main_loop:
    btst    #6,CUSTOM+VHPOSR   ; Wait for vertical blank
    beq.s   main_loop
    
    bsr     clear_screen       ; Clear buffer
    bsr     update_scroll      ; Move text
    bsr     update_wave        ; Update sine offset
    bsr     draw_text         ; Render text
    bsr     swap_buffers      ; Show new frame
    
    bra     main_loop

update_wave:
    addq.w  #1,wave_offset    ; Increment wave phase
    and.w   #255,wave_offset  ; Wrap at 256
    rts
```

## Part 5: Modern Enhancements

### Color Cycling System

```javascript
// HTML5 Version - HSL Color Space
const hue = (time * 30 + i * 5) % 360;
const colorIntensity = (Math.sin(waveOffset) + 1) / 2;
ctx.fillStyle = `hsl(${hue}, 100%, ${50 + (colorIntensity * 50)}%)`;
```

### Shadow Effect

```javascript
// Add depth with shadows
ctx.fillStyle = 'rgba(0, 0, 0, 0.5)';
ctx.fillText(char, x + 2, y + 2);
```

## Conclusion

The Sinus Scroller effect demonstrates:
- Evolution of text animation techniques
- Different approaches to mathematical animation
- Platform-specific optimizations
- Blend of classic and modern effects

Our modern implementation maintains the spirit of the original while adding contemporary visual enhancements.

## Further Reading

1. Demo Scene History
2. Text Rendering Techniques
3. Color Theory and HSL Space
4. Animation Timing Systems
5. Font Bitmap Techniques
6. Performance Optimization in Graphics
