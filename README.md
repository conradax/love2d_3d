# love2d_3d

![preview](https://github.com/shockla/love2d_3d/raw/main/preview.gif)

## What is this
This is an experiment to draw 3d model in [love2d](https://love2d.org/).

It's simulates pixel using `love.graphics.rectangle()`.

It's draws every pixel with `depth testing` and the color returned by a function in `fragShader.lua`,

Therefore, it has bad performance.

## Why
Just for fun. I was learning computer graphics, and decided to make this.

## Notice
* Camera is intented to facing z+ in view space.
* Left hand coordinate system
* Rotation is counter-clock-wise while looking toward axis' positive direction.
* There might be some bugs with matrices.
