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

uniform sampler2D s_entity;

uniform sampler2D colortex0;
uniform sampler2D colortex5;
uniform sampler2D colortex6;
uniform sampler2D colortex7;
uniform sampler2D colortex8;
uniform sampler2D colortex9;
uniform sampler2D colortex10;
uniform sampler2D colortex11;
uniform sampler2D colortex12;
uniform sampler2D colortex13;

uniform int frameCounter;
uniform float viewWidth;
uniform float viewHeight;
uniform vec2 gi_resolution;

layout(std430, binding = 0) buffer AccLayout {
    int accumulations[];
};

in vec2 texcoord;

/* RENDERTARGETS: 10 */
layout(location = 0) out vec4 f_color;


void main() {
    ivec2 pixel = ivec2(texcoord * vec2(viewWidth, viewHeight));

    int pingpong = frameCounter % 2;

    vec3 color = vec3(0.0);

    // Main
    #if (TARGET_BUFFER == 0)

        vec4 world = texture(colortex0, texcoord);
        vec4 albedo = texture(colortex12, texcoord);
        vec4 denoised_gi = texture(colortex10, texcoord);
        vec3 sky = texture(colortex11, texcoord).rgb;
        vec4 overlay = texture(colortex13, texcoord);

        // Remodulate albedo
        color = denoised_gi.rgb * albedo.rgb * denoised_gi.a;

        // Add world
        color += (1.0 - denoised_gi.a) * world.rgb;
        
        // Add sky
        color += sky * (1.0 - albedo.a);

        // Overlay
        color = mix(color, overlay.rgb, overlay.a);

    // Normals
    #elif (TARGET_BUFFER == 1)

        vec4 normal_buf;
        if (pingpong == 0) {
            normal_buf = texture(colortex7, texcoord);
        }
        else {
            normal_buf = texture(colortex8, texcoord);
        }

        color = normal_buf.rgb;

        // [-1, 1] -> [0, 1]
        color = color * 0.5 + 0.5;

        color /= (normal_buf.a);

    // Accumulations
    #elif (TARGET_BUFFER == 2)

        ivec2 acc_pixel = ivec2(texcoord * gi_resolution);
        int acc = accumulations[acc_pixel.x + acc_pixel.y * int(gi_resolution.x)];
        color = vec3(float(acc) / float(DIFFUSE_ACCUMULATION_LENGTH));

    // Albedo
    #elif (TARGET_BUFFER == 3)

        color = texture(colortex12, texcoord).rgb;

    // Raw GI
    #elif (TARGET_BUFFER == 4)

        color = texture(colortex10, texcoord).rgb;

    #endif

    f_color = vec4(color, 1.0);
}