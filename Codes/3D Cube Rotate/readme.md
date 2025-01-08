# 3D Cube: Understanding Implementation and Modern Recreation
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

3D cube rendering is a fundamental concept in computer graphics, serving as a gateway to understanding 3D transformations, perspective projection, and wireframe rendering. This tutorial explores both the mathematical concepts and their practical implementation in modern web technologies.

### What You'll Learn
- Understanding 3D coordinate systems
- Matrix transformations and rotations
- Perspective projection techniques
- Animation timing and synchronization
- Modern implementation using HTML5 Canvas

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

### Rotation Matrices

Understanding rotation matrices is crucial:

1. **Main Components**
   - X-axis rotation matrix
   - Y-axis rotation matrix
   - Z-axis rotation matrix
   - Combined rotation matrix

## Part 2: Cube Structure Implementation

### Defining Cube Vertices

#### HTML5 Implementation:

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

#### Amiga Assembly Implementation:

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

### Edge Connections

```javascript
const edges = [
    [0, 1], [1, 2], [2, 3], [3, 0],  // Front face
    [4, 5], [5, 6], [6, 7], [7, 4],  // Back face
    [0, 4], [1, 5], [2, 6], [3, 7]   // Connecting edges
];
```

## Part 3: Rotation and Transformation

### Rotation Function

```javascript
function rotate(point, angleX, angleY, angleZ) {
    let [x, y, z] = point;

    // Z-axis rotation
    let x1 = x * Math.cos(angleZ) - y * Math.sin(angleZ);
    let y1 = x * Math.sin(angleZ) + y * Math.cos(angleZ);

    // Y-axis rotation
    let x2 = x1 * Math.cos(angleY) - z * Math.sin(angleY);
    let z1 = z * Math.cos(angleY) + x1 * Math.sin(angleY);

    // X-axis rotation
    let y2 = y1 * Math.cos(angleX) - z1 * Math.sin(angleX);
    let z2 = z1 * Math.cos(angleX) + y1 * Math.sin(angleX);

    return [x2, y2, z2];
}
```

## Part 4: Drawing and Animation

### Canvas Setup

```javascript
const canvas = document.getElementById('canvas');
const ctx = canvas.getContext('2d');

// Handle window resizing
function resizeCanvas() {
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
}
```

### Memory Management and Display Setup

#### Amiga Assembly:
```assembly
; Display and memory setup
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

; Fixed point constants (16.16 format)
FIXED_SHIFT     EQU     16
FIXED_ONE       EQU     1<<FIXED_SHIFT
```

### Animation Loop

#### HTML5 Implementation:

```javascript
function draw() {
    // Clear previous frame
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    
    const centerX = canvas.width / 2;
    const centerY = canvas.height / 2;
    const scale = 150;

    // Calculate rotation angles
    let angleX = Date.now() * 0.001;
    let angleY = Date.now() * 0.0005;
    let angleZ = Date.now() * 0.00075;

    // Draw each edge
    edges.forEach(edge => {
        let p1 = rotate(points[edge[0]], angleX, angleY, angleZ);
        let p2 = rotate(points[edge[1]], angleX, angleY, angleZ);

        ctx.beginPath();
        ctx.moveTo(p1[0] * scale + centerX, p1[1] * scale + centerY);
        ctx.lineTo(p2[0] * scale + centerX, p2[1] * scale + centerY);
        ctx.stroke();
    });

    requestAnimationFrame(draw);
}
```

## Part 5: Advanced Techniques

### 1. Multiple Cubes

```javascript
const cubes = [
    { points: createCube(1), color: 'white', offset: 0 },
    { points: createCube(0.6), color: 'red', offset: Math.PI / 12 },
    { points: createCube(0.3), color: 'cyan', offset: Math.PI / 6 }
];
```

### 2. Perspective Projection

```javascript
function applyPerspective(point, distance) {
    const [x, y, z] = point;
    const scale = distance / (distance + z);
    return [x * scale, y * scale];
}
```

## Part 6: Performance Optimization

### 1. Request Animation Frame

```javascript
// Use requestAnimationFrame for smooth animation
requestAnimationFrame(draw);
```

### 2. Canvas Optimization

```javascript
// Optimize canvas drawing
ctx.beginPath();
edges.forEach(edge => {
    // Draw all edges in a single path
    ctx.moveTo(p1[0], p1[1]);
    ctx.lineTo(p2[0], p2[1]);
});
ctx.stroke(); // Single stroke call
```

## Conclusion

The 3D cube implementation demonstrates several important concepts:

- 3D mathematics and transformations
- Animation timing and optimization
- Canvas drawing techniques
- Matrix operations and rotations

This foundation can be expanded to create more complex 3D graphics and animations in web applications.

## Further Reading

1. Linear Algebra and 3D Transformations
2. Canvas Performance Optimization
3. Advanced 3D Graphics Techniques
4. WebGL and Three.js for more complex 3D
