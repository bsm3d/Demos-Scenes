# Amiga Boing Ball: Modern HTML5 vs Classic Assembly
## A Comparative Implementation Guide

## Introduction

The Amiga Boing Ball demo, created in 1984 by Dale Luck and RJ Mical, is one of the most iconic demos in computer history. It showcased the Amiga's advanced graphics capabilities and became a symbol of the platform. This tutorial will show you how to recreate this classic effect using both modern web technologies and original Amiga assembly.

### What You'll Learn

In this tutorial, you will learn:
- How to create a 3D sphere with checker pattern
- Implementation of realistic bounce physics
- Creation of smooth rotation animations
- Drawing techniques for the classic Amiga-style grid
- Shadow projection and handling
- Performance optimization techniques
- Color cycling and palette manipulation

### Prerequisites

For the HTML5 version:
- Understanding of HTML5 Canvas
- Basic JavaScript knowledge
- Familiarity with 3D mathematics
- Basic physics concepts (gravity, bounce)

For the Amiga Assembly version:
- Knowledge of 68000 assembly
- Understanding of Amiga hardware:
  - Blitter operations
  - Copper lists
  - Color registers
  - Sprite handling

### Effect Breakdown

The Boing Ball effect consists of several key components:

1. **Ball Rendering**
   - 3D sphere generation
   - Checker pattern mapping
   - Color alternation (red/white)
   - Surface shading
   
2. **Physics Simulation**
   - Gravity effects
   - Bounce mechanics
   - Energy damping
   - Position tracking

3. **Background Elements**
   - Grid pattern generation
   - Color cycling
   - Shadow projection

4. **Animation System**
   - Smooth rotation
   - Physics updates
   - Frame synchronization

### Part 1: Implementation Comparison

Let's look at how this is implemented in both modern and classic code:

#### HTML5 Canvas Version

```javascript
// Ball physics constants
const BALL_RADIUS = 100;
const GRAVITY = 0.2;
const DAMPING = 0.98;
const BOUNCE_SPEED = 2;

// 3D sphere generation with checker pattern
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
            
            // Add checker pattern
            const isRed = (Math.floor(u) + Math.floor(v)) % 2 === 0;
            // ...
        }
    }
}
```

#### Amiga Assembly Version

```assembly
; Ball constants
BALL_SIZE       EQU     64      ; Ball diameter in pixels
GRAVITY_ACC     EQU     $0080   ; Fixed point gravity
BOUNCE_DAMP     EQU     $00F0   ; Energy loss on bounce

; Sprite data structure
ball_sprite:
    dc.w    $2c40,$2c40        ; Position control word
    dc.w    $8000,$0000        ; Sprite header
    dc.w    %0000000000000000  ; Sprite data start
    dc.w    %0111111111111110
    ; ... more sprite data ...

init_ball:
    ; Set up sprite DMA and position
    lea     CUSTOM,a6
    move.w  #$8020,DMACON(a6)  ; Enable sprite DMA
    move.l  #ball_sprite,d0
    move.w  d0,SPR0PTH(a6)
    swap    d0
    move.w  d0,SPR0PTL(a6)
    rts
```

### Part 2: Physics Implementation

#### HTML5 Version
```javascript
function updatePhysics() {
    // Apply gravity
    velocityY += GRAVITY;
    ballY += velocityY;
    
    // Handle bounce
    if (ballY > canvas.height - BALL_RADIUS) {
        ballY = canvas.height - BALL_RADIUS;
        velocityY = -velocityY * DAMPING;
    }
}
```

#### Amiga Assembly Version
```assembly
update_physics:
    ; Update vertical position
    move.l  ball_velocity,d0
    add.l   #GRAVITY_ACC,d0     ; Add gravity
    move.l  d0,ball_velocity
    
    ; Update position
    move.l  ball_position,d1
    add.l   d0,d1
    
    ; Check for bounce
    cmp.l   #SCREEN_BOTTOM,d1
    blt.s   .no_bounce
    neg.l   d0                  ; Reverse velocity
    mulu    #BOUNCE_DAMP,d0     ; Apply damping
    lsr.l   #8,d0              ; Fixed point adjust
.no_bounce:
    rts
```

### Part 3: Drawing the Background Grid

#### HTML5 Version
```javascript
function drawGrid() {
    ctx.strokeStyle = '#8040c0';  // Classic Amiga purple
    
    // Draw vertical lines
    for (let i = 0; i <= canvas.width; i += 40) {
        ctx.beginPath();
        ctx.moveTo(i, 0);
        ctx.lineTo(i, canvas.height);
        ctx.stroke();
    }
    
    // Draw horizontal lines
    for (let i = 0; i <= canvas.height; i += 40) {
        ctx.beginPath();
        ctx.moveTo(0, i);
        ctx.lineTo(canvas.width, i);
        ctx.stroke();
    }
}
```

#### Amiga Assembly Version
```assembly
draw_grid:
    ; Set up Blitter for line drawing
    move.w  #$FFFF,BLTAFWM(a6)  ; First word mask
    move.w  #$FFFF,BLTALWM(a6)  ; Last word mask
    move.w  #$8000,BLTCON0(a6)  ; Line draw mode
    move.w  #$0000,BLTCON1(a6)  
    
    ; Draw vertical lines
    lea     grid_buffer,a0
    moveq   #39,d7              ; 40 lines
.vert_loop:
    ; Set up line coordinates
    move.w  #SCREEN_WIDTH,d0
    mulu    #40,d7
    move.w  d7,d1              ; X position
    ; ... more line drawing code ...
    dbra    d7,.vert_loop
    rts
```

### Part 4: Shadow Projection

#### HTML5 Version
```javascript
function drawShadow(x, y) {
    const shadowY = canvas.height - 20;
    const scale = 1 - (shadowY - y) / (canvas.height * 0.8);
    
    ctx.save();
    ctx.translate(x, shadowY);
    ctx.scale(1, 0.2);  // Flatten to create oval
    ctx.beginPath();
    ctx.arc(0, 0, BALL_RADIUS * scale, 0, Math.PI * 2);
    ctx.fillStyle = 'rgba(80, 40, 120, 0.5)';
    ctx.fill();
    ctx.restore();
}
```

#### Amiga Assembly Version
```assembly
draw_shadow:
    ; Calculate shadow scale based on ball height
    move.l  ball_height,d0
    sub.l   #SCREEN_BOTTOM,d0
    neg.l   d0
    mulu    #SHADOW_SCALE,d0
    lsr.l   #8,d0              ; Fixed point adjust
    
    ; Set up Bob for shadow
    move.l  #shadow_data,a0
    move.w  d0,2(a0)           ; Update width
    lsr.w   #2,d0
    move.w  d0,6(a0)           ; Update height
    ; ... more shadow drawing code ...
    rts
```

### Key Differences and Optimizations

1. **Rendering Approach**
   - HTML5: Uses Canvas 2D context with pixel manipulation
   - Amiga: Uses hardware sprites and blitter for efficient drawing

2. **Physics Calculations**
   - HTML5: Floating-point math with JavaScript
   - Amiga: Fixed-point math for performance

3. **Animation Timing**
   - HTML5: RequestAnimationFrame for smooth animation
   - Amiga: Vertical blank synchronization

4. **Memory Management**
   - HTML5: Automatic garbage collection
   - Amiga: Careful memory allocation and copper list management

### Conclusion

The Boing Ball demo represents a perfect example of how different technologies can achieve the same visual result through different means:

- The HTML5 version offers easier development and maintenance
- The Amiga version showcases efficient use of limited hardware
- Both versions require careful attention to animation timing
- The physics simulation principles remain the same across platforms

This recreation demonstrates how fundamental computer graphics and animation principles transcend specific platforms while implementation details adapt to available technology.