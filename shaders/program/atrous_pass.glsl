/*

    Project Lyrae
    Copyright (c) 2025 lucysir

    This file is a part of Project Lyrae (the "Software") and is
    subject to the Project Lyrae License.
    
    Full license text: https://github.com/kadir014/lyrae-shaders/blob/main/LICENSE
    Official page: https://modrinth.com/project/lyrae-shaders

*/

#version 430 compatibility
#extension GL_ARB_shading_language_include: enable

#include "/lib/common.glsl"
#include "/lib/color.glsl"
#include "/lib/atrous.glsl"


uniform sampler2D colortex5;
uniform sampler2D colortex6;
uniform sampler2D colortex7;
uniform sampler2D colortex8;
uniform sampler2D colortex9;
uniform sampler2D colortex10;

uniform int frameCounter;
uniform vec2 gi_resolution;

in vec2 texcoord;

/* RENDERTARGETS: 10 */
layout(location = 0) out vec4 f_color;


// Paper says the 1D kernel is 1/16, 1/4, 3/8, 1/4, 1/16
const float kernel[25] = {
    0.00390625, 0.015625, 0.0234375, 0.015625, 0.00390625,
    0.015625,   0.0625,   0.09375,   0.0625,   0.015625,
    0.0234375,  0.09375,  0.140625,  0.09375,  0.0234375,
    0.015625,   0.0625,   0.09375,   0.0625,   0.015625,
    0.00390625, 0.015625, 0.0234375, 0.015625, 0.00390625
};

const vec2 offset[25] = {
    vec2(-2.0,-2.0), vec2(-1.0,-2.0), vec2(0.0,-2.0), vec2(1.0,-2.0), vec2(2.0,-2.0),
    vec2(-2.0,-1.0), vec2(-1.0,-1.0), vec2(0.0,-1.0), vec2(1.0,-1.0), vec2(2.0,-1.0),
    vec2(-2.0, 0.0), vec2(-1.0, 0.0), vec2(0.0, 0.0), vec2(1.0, 0.0), vec2(2.0, 0.0),
    vec2(-2.0, 1.0), vec2(-1.0, 1.0), vec2(0.0, 1.0), vec2(1.0, 1.0), vec2(2.0, 1.0),
    vec2(-2.0, 2.0), vec2(-1.0, 2.0), vec2(0.0, 2.0), vec2(1.0, 2.0), vec2(2.0, 2.0)
};


#if (ATROUS_STEP == 1)

    #define gi_target0 colortex5
    #define gi_target1 colortex6

#else

    #define gi_target0 colortex10
    #define gi_target1 colortex10

#endif


void main() {
    int pingpong = frameCounter % 2;

    vec4 o_color = vec4(0.0);
    #if (ATROUS_STEP == 1)

        if (pingpong == 0) {
            o_color = texture(gi_target0, texcoord);
        }
        else {
            o_color = texture(gi_target1, texcoord);
        }

    #else

        o_color = texture(gi_target0, texcoord);

    #endif

    #if (DENOISING == 1 && ATROUS_ITERS >= ATROUS_STEP)

        float step_width = float(ATROUS_STEP);

        ATrousData atrous_data = ATrousData(
            PHI_GI,
            PHI_N,
            PHI_P,
            step_width,
            kernel,
            offset
        );

        vec3 filtered_gi = vec3(0.0);

        if (pingpong == 0) {
            filtered_gi = edge_avoiding_atrous(
                gi_target0,
                colortex7,
                colortex9,
                atrous_data,
                texcoord,
                gi_resolution
            );
        }
        else {
            filtered_gi = edge_avoiding_atrous(
                gi_target1,
                colortex8,
                colortex9,
                atrous_data,
                texcoord,
                gi_resolution
            );
        }

        f_color = vec4(filtered_gi, o_color.a);

    #else

        f_color = o_color;

    #endif
}