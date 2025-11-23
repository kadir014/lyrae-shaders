/*

    Project Lyrae
    Copyright (c) 2025 lucysir

    This file is a part of Project Lyrae (the "Software") and is
    subject to the Project Lyrae License.
    
    Full license text: https://github.com/kadir014/lyrae-shaders/blob/main/LICENSE
    Official page: https://modrinth.com/project/lyrae-shaders

*/

#ifndef OPTIONS_H
#define OPTIONS_H


#define TITLE 0 //[0]


#define VOXEL_DIAMETER 32 //[16 32 64 128]

#define SAMPLE_COUNT 1 //[1 2 4 8]
#define MAX_BOUNCES 4 //[2 3 4 5 30]

#define ENABLE_NEE 1 //[0 1]
#define ARTISTIC_CAUSTICS 1

#define ENABLE_ACCUMULATION 1
#define DIFFUSE_ACCUMULATION_LENGTH 30
#define SPECULAR_ACCUMULATION_LENGTH 3

#define TARGET_BUFFER 0 //[0 1 2 3 4]

#define GI_SCALE 0.85 //[0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.0]


#define DENOISING 1 //[0 1]
#define ATROUS_ITERS 5 //[1 2 3 4 5 6]
#define PHI_GI 1.7
#define PHI_N 0.045
#define PHI_P 0.025


#define POST_CHROMATIC_ABERRATION 0.003
#define POST_EXPOSURE -0.25
#define POST_BRIGHTNESS 0.02
#define POST_CONTRAST 1.086
#define POST_SATURATION 1.53


#endif // OPTIONS_H