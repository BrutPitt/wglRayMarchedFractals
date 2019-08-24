# wglMengerBulb 

WebGL Ray Marching Distance Extimation intersection between MandelBulb and MengerSponge cube 

|![](https://brutpitt.github.io/wglRayMarchedFractals/WebGL/MengerBulb/screenShots/screenShot0.jpg) | ![](https://brutpitt.github.io/wglRayMarchedFractals/WebGL/MengerBulb/screenShots/screenShot1.jpg)|
| :-----: | :----: |
|![](https://brutpitt.github.io/wglRayMarchedFractals/WebGL/MengerBulb/screenShots/screenShot7.jpg) | ![](https://brutpitt.github.io/wglRayMarchedFractals/WebGL/MengerBulb/screenShots/screenShot8.jpg)|
|![](https://brutpitt.github.io/wglRayMarchedFractals/WebGL/MengerBulb/screenShots/screenShot91.jpg) | ![](https://brutpitt.github.io/wglRayMarchedFractals/WebGL/MengerBulb/screenShots/screenShot92.jpg)|

### Features
- light (blinn-phong) and shadows with full settings
- ambient occlusion with settings
- subpixel subdivision
- level of details (epsilon)
- auto-progressive step of accuracy.
- settings MengerSponge parameters: iterations / rotation / increment / scale / offset
- settings MandelBulb parameters: iterations / power 
- 10 palettes with offset setting

### Tips
Shadow *Deep* and *Density* parameters start with a low value (for slow GPU): increment values to get a better render (*Deep*) or for smooth shadows (*Density*)


### Commands
- LeftMouseButton -> Rotate object
- RightMouseButton -> Rotate light
- MouseWheel -> Zoom in/out
- shift + LeftMouseButton -> Pan

### Description

This is **pure** WebGL 2.0 Experiment, without 3th party WebGL tools/library.

It uses only [gl-matrix](https://github.com/toji/gl-matrix) js library for mat/vec/quat, and other self-made tools in the [jsLib](https://github.com/BrutPitt/wglMandelBulber/tree/master/jsLib) directory

### Warnings
For standalone use, on local computer, need of an http server to load external **glsl** shader file.

**Commons workarounds**

For safety the browsers can't load external files from local machine, but if you want to test this experiment, without a http server, you can use a workaround:


**Chrome** 

Launch browser with `--allow-file-access-from-files` command line option.

**Firefox** (from v.68 and above: before works fine w/o any settings)

In `about:config` url (config page), set `privacy.file_unique_origin = false`
