<br>
<p align="center">
<b>Lyrae • Physically-Based Real-Time Path Traced Shaderpack</b>
<br><br>
<img width=600 src="https://raw.githubusercontent.com/kadir014/lyrae-shaders/refs/heads/main/assets/thumb.png">
</p>

📌 **NOTICE:** This project is currently in _very early_ alpha stages. Expect issues, visual artifacts and varying performance. I have a huge roadmap. I'd appreciate any kind of feedback and your support!

## Features
- **Real-Time Voxel Path Tracing**
  - Monte Carlo global illumination with multiple light bounces
  - Fast voxel traversal via DDA algorithm
  <br>
- **Sampling & Image Stability**
  - Low-discrepancy blue noise sampling
  - Temporal accumulation with reprojection for noise reduction
  - Next Event Estimation (NEE) for explicit sun sampling
  - Edge avoiding À-Trous denoiser
  <br>
- **Physically-Based Materials**
  - Unified physically-based shading pipeline
  - Designed for real-time & artistic efficiency
  - Support for **LabPBR** resource packs
  <br>
- **Post-Processing**
  - Filmic tonemapping
  - Color grading
  - Chromatic aberration

## Community
If you enjoy my shaderpack, you can support me & my studies here: [Buy Me a Coffee](https://buymeacoffee.com/kadir014) ❤️

You can join the [discord server here](https://discord.gg/eS7MzZHmWq).

## PBR Support
Lyrae supports **LabPBR 1.3** standard. So make sure to use a resourcepack with **LabPBR** material support, here's a [list of resourcepacks](https://shaderlabs.org/wiki/LabPBR_Supported_Packs#Resource_Packs) on shaderlabs site.

## Performance Tips
- `Samples` is one setting with the most impact on the performance, because it directly affects the number of paths per pixel. Try to keep this at 1 if you want to enjoy real-time.
- You can try changing the `Resolution Scale` setting, lowering this will make the lighting quality lower.
- For most scenarios 3 bounces is enough. If you have lots of reflections and refraction, you *may* try 4 or 5.
- If you are in a *completely isolated* room where no sunlight is visible, you can try disabling NEE. Note that disabling NEE will break sun light.
- You can lower denoiser iterations or disable it alltogether if you are okay with the noise.
- Post-processing almost has zero effect (compared to global illumination).
