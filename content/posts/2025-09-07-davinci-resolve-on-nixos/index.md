---
author: "ca4mi"
title: "Davinci Resolve on NixOS"
date: "2025-09-07"
description: "Davinci Resolve 19 on NixOS"
ShowToc: false
TocOpen: false
---
Here's how I got DaVinci Resolve 19 running smoothly on my NixOS setup. This guide covers the basic installation, creating a launch script for NVIDIA GPUs, and handling common video formats that the free version doesn't support on Linux.

### ⚙️ Installation
Firsty added the `davinci-resolve` package to my machine within configuration.nix

```nix
users.users.ca4mi = {
  # ... other user settings
  packages = with pkgs; [
    davinci-resolve
    # ... other packages
  ];
};
```

### 🚀 Forcing Resolve to Use the NVIDIA GPU (PRIME Offload)
Nixos machine is already configured to use **NVIDIA PRIME** with render offload mode enabled. This allows the integrated GPU to handle the laptop while keeping the NVIDIA card ready for demanding applications.

Then created a custom launch script. This script sets the necessary environment variables to force the application to run on the dedicated GPU.

`resolve-launcher.sh`:
```sh
#!/bin/sh
export __NV_PRIME_RENDER_OFFLOAD=1
export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export __VK_LAYER_NV_optimus=NVIDIA_only

exec davinci-resolve "$@"
```
Making the script executable with `chmod +x resolve-launcher.sh`.

### 🎬 Handling Incompatible Media
The free version of DaVinci Resolve on Linux has licensing restrictions and doesn't support common formats like H.264/H.265 (.MP4) or AAC audio. To import footages, first need to convert it into an editing-friendly format that Resolve can handle, like DNxHR in a .mov container.

I use `FFmpeg` for this conversion. First, ensure it's installed packages in configuration.nix:
```nix
# somehow installed it systemPackages but u can install it user or whatever 
environment.systemPackages = with pkgs; [
  # ... other packages
  ffmpeg
];
```
Then
```sh
ffmpeg -i your_video.MP4 -c:v dnxhd -profile:v dnxhr_hq -c:a pcm_s16le -pix_fmt yuv422p converted_video.mov
```
Replace your_video.MP4 and converted_video.mov with your input and desired output filenames. Now you can import the .mov files.
