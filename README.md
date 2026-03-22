# Yadrutas

### A Real-Time Animated Short Film in Unity

A 45-second animated short film built in Unity as part of the CM3070 Final Project for the BSc Computer Science programme at the University of London.

---

## Story

Blob rushes through his morning routine, sprints to catch the bus...and discovers he did not have to rush.

---

## Technical Highlights

This project explores whether real-time GPU shader programming can serve as a viable alternative to traditional offline animation pipelines, lowering the barrier to entry for independent creators.

### Custom HLSL Shaders

- **Emission shader** — organic character glow using Fractal Brownian Motion noise and Fresnel edge detection, inspired by Pixar's _Inside Out 2_ multi-layer emission system
- **FractalFuzzyEdge_Tex shader** — handles face texture compositing over the emission effect without the "light bulb" uniform glow problem
- **Toon shader** — cel-shaded environment rendering with discrete lighting steps and outline pass
- **LightShaft shader** — volumetric light rays using additive blending, FBM noise scrolling, Fresnel transparency, and depth fade

### Pipeline

- Character modelled, rigged and animated in **Blender**, exported as FBX
- The film was setup in **Unity Timeline** with **Cinemachine** camera control
- Rendered in **Unity URP** (Universal Render Pipeline) on an M1 MacBook Pro
- Post-processing via Global Volume (bloom, film grain, vignette) and per-scene Local Volumes

### Performance

- Sustained **24 fps at 1080p** on consumer hardware (M1 MacBook Pro)
- Scene complexity: 106k–209k triangles
- Memory usage: ~23.7 MB

---

## Project Structure

```
Assets/
├── Shaders/          # Custom HLSL shaders
├── Char/             # Blob character prefab and materials
├── Material          # All the metarials used in the film
├── Scenes/           # Three film scenes
├── Scripts/          # Scripts used in the film - only 2
└── var/   # various other folder that are not important
```

---

## Requirements

- Unity 2022.3 LTS or later
- Universal Render Pipeline (URP) package
- Cinemachine package
- Unity's Timlen
- Recorder

---

## Course Context

| Field       | Detail                             |
| ----------- | ---------------------------------- |
| Module      | CM3070 Final Project               |
| Institution | University of London               |
| Student     | 220472209                          |
| Template    | 9.2 — Animated Short Film with VFX |

---

## Academic References

[1] Unity Technologies, "Rendering Pipeline Documentation," Unity Technologies, 2024. [Online]. Available: https://docs.unity3d.com/Manual/render-pipelines.html

[2] Unity Technologies, "Shader Graph," Unity Technologies, 2024. [Online]. Available: https://unity.com/features/shader-graph

[3] University of London, "CM3045 3D Graphics and Animation - Final Project Templates," 2025, pp. 52-54.

[4] D. Silva Jasaui, M. Cordeiro de Morais, and E. Clua, "The Democratization of Virtual Production Through Real-Time Rendering Pipelines," IEEE Computer Graphics and Applications, vol. 14, no. 6, pp. 2530, 2024.

[5] A. Zucconi, "Game Development, Shader Coding & Artificial Intelligence," Alan Zucconi, 2024. [Online]. Available: https://www.alanzucconi.com

[6] P. Gonzalez Vivo and J. Lowe, "The Book of Shaders," 2015-2024. [Online]. Available: https://thebookofshaders.com

[7] E. Chang, E. Lacroix and A. Kutt, "Pixars Win or Lose - Stylized FX in an Animated Series," in ACM SIGGRAPH 2024 [Online] Available: https://graphics.pixar.com/library/WinOrLoseStyle/paper.pdf

[8] A. Lacaze, M. Ellsworth, B. Porter, A. Xenakis, T. Hu, M. Kranzler, J. Kuenzel, and A. Angelidis, "Familiar Feelings: Emotion Look Re-Development on Pixars Inside Out 2,” in ACM SIGGRAPH 2024 [Online] Available: https://graphics.pixar.com/library//InsideOut2Shade/paper.pdf.

[9] Unity Technologies, "ShaderLab and Shader Programming," Unity Manual, 2024. [Online]. Available: https://docs.unity3d.com/Manual/SL-Reference.html

[10] Unity Technologies, "Timeline," Unity Manual, 2024. [Online]. Available: https://docs.unity3d.com/Manual/TimelineSection.html

[11] Pixar Animation Studios, "Win or Lose," Disney+, 2024. [Streaming series].

[12] Pixar Animation Studios, "Character Design in Win or Lose," Pixar Animation Studios, 2024. [Online]. Available: https://www.pixar.com/win-or-lose

[13] Pixar Animation Studios, "Inside Out 2," directed by Kelsey Mann, Walt Disney Pictures, 2024. [Film].

[14] R. Fernando, GPU Gems: Programming Techniques, Tips and Tricks for Real-Time Graphics, 2004, ch. 21.

[15] Unity Technologies, "Adam," Unity Films, 2016. [Short film]. Available: https://unity.com/demos/adam

[16] Unity Technologies, "The Heretic," Unity Films, 2022. [Short film]. Available: https://unity.com/the-heretic

[17] E. Luthermilla, W.-T. Kim, and J.-S. Yoon, "Unity: A Powerful Tool for 3D Computer Animation Production," Korea Computer Graphics Society, vol. 29, no. 3, pp. 45-57, 2023.

[18] Illumination Entertainment, "Despicable Me" and "Minions" franchise, directed by Pierre Coffin and Chris Renaud, Universal Pictures, 2010-present. [Film series].

[19] R. Fernando, GPU Gems: Programming Techniques, Tips and Tricks for Real-Time Graphics., 2004.

[20] R. Fernando, M. Pharr, , GPU Gems 2: Programming Techniques for High-Performance Graphics and General-Purpose Computation., 2005.

[21] H. Nguyen, GPU Gems 3., 2008.

[22] Unity Technologies, "Shader Graph," Unity Manual, 2024. [Online]. Available: https://docs.unity3d.com/Manual/shader-graph.html

[23] Unity Technologies, "Introduction to Shader Graph," Unity Learn, 2024. [Online]. Available: https://learn.unity.com/tutorial/introduction-to-shader-graph

[24] GameDev.tv, "GameDev.tv Learning Platform," 2024. [Online]. Available: https://gamedev.tv/

[25] GameDev.tv, "Complete Unity 3D Developer: Design & Develop Games in Unity 6 using C#," 2024. [Online]. Available: https://gamedev.tv/courses/unity6-complete-3d

[26] GameDev.tv, "Complete Blender Creator 3: Learn 3D Modelling for Beginners," 2024. [Online]. Available: https://gamedev.tv/courses/complete-blender-creator/section-intro-introduction-to-blender/548

[27] GameDev.tv, "From Blender to Unity: Game-Ready Assets, Characters and Animation," 2024. [Online]. Available: https://gamedev.tv/courses/blender-to-unity/course-introduction-blender-to-unity/7987

[28] Unity Technologies, "ShaderLab: Writing Shaders," Unity Manual, 2024. [Online]. Available: https://docs.unity3d.com/Manual/SL-Reference.html

[29] “Simple Sky - Cartoon assets | 3D Environments | Unity Asset Store,” Unity Asset Store, Nov. 05, 2019. https://assetstore.unity.com/packages/3d/environments/simple-sky-cartoon-assets-42373

[30] “Low-Poly Simple Nature Pack | 3D Landscapes | Unity Asset Store,” Unity Asset Store, Oct. 31, 2024. https://assetstore.unity.com/packages/3d/environments/landscapes/low-poly-simple-nature-pack-162153

[31] “Stylized bedroom kit | 3D Environments | Unity Asset Store,” Unity Asset Store. https://assetstore.unity.com/packages/3d/environments/stylized-bedroom-kit-308050

[32] “Pandazole - City Town Lowpoly Pack | 3D Exterior | Unity Asset Store,” Unity Asset Store, Dec. 05, 2025. https://assetstore.unity.com/packages/3d/props/exterior/pandazole-city-town-lowpoly-pack-205787

[33] “Street_Vehicles_Pack_Autobus_Tram | 3D Land | Unity Asset Store,” Unity Asset Store, Feb. 09, 2023. https://assetstore.unity.com/packages/3d/vehicles/land/street-vehicles-pack-autobus-tram-213421
