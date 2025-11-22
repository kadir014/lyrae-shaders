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

#include "../lib/common.glsl"
#include "../lib/color.glsl"

uniform sampler2D colortex10;

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 f_color;


void main() {
    vec3 color = texture(colortex10, texcoord).rgb;

    /*
        HDR -> LDR sRGB color space pipeline:

        1. The image is in HDR linear space [0, infinity)
        2. Lens aberration
        3. Exposure adjustment
        4. Tonemapping
        6. Gamma correction and convert to sRGB [0, 1]
        5. Color grading (contrast, saturation, ...)
    */

    /*
        Radial Chromatic Aberration
        ---------------------------
        Imitates lens aberration.

        Since chromatic aberration happens on the lens by affecting the
        individual wavelengths, I think it's most sensible to do this
        in HDR space before any color grading and tonemapping.

        Note: In real life cameras, chromatic aberration mostly affects
        1-2 pixels at max. So keeping the intensity low will be better.
    */
    vec2 delta = texcoord - vec2(0.5);
    float d = length(delta);
    vec2 dir = delta / d;
    
    vec2 nuv = (texcoord - 0.5) * 2.0;
    vec2 offset = dir * (POST_CHROMATIC_ABERRATION * d * dot(nuv, nuv));
    
    // Offset outside screen so repeated pixels at the edges don't show
    vec4 g_sample = texture(colortex10, texcoord - offset);
    vec4 b_sample = texture(colortex10, texcoord - offset * 2.0);
    color.g = g_sample.g;
    color.b = b_sample.b;

    /*
        Exposure
        --------
        Each value adds one half-stop. 0.0 is neutral exposure.
        - EV = -1.0 -> 0.7x darker
        - EV = 0.0 -> Neutral
        - EV = 1.0 -> 1.4x brighter
        - EV = 2.0 -> 2.0x brighter (one full-stop)
    */
    color *= pow(SQRT2, POST_EXPOSURE);

    /*
        Tonemapping
        -----------
        We map the image from HDR to LDR using a tonemap curve.

        In my experience, this often washes out the image,
        so aggressive color grading is needed afterwards.
    */
    color = aces_filmic(color);

    /*
        Gamma Correction
        ----------------
        Map the colors onto non-linear sRGB space.
    */
    color = pow(color, vec3(GAMMA));

    /*
        Brightness
        ----------
        - A value of 0.0 is neutral and does nothing.
        - Over or under 0.0, it simply adjusts the overall brightness linearly.
    */
    color += POST_BRIGHTNESS;

    /*
        Contrast
        --------
        Pivot around mid-grays and show the difference between darks and lights.

        - A value of 1.0 is neutral and does nothing.
        - Under 1.0, the image loses contrast until 0.0.
        - Over 1.0, the image 'pops up' more.
    */
    color = ((color - 0.5) * max(POST_CONTRAST, 0.0)) + 0.5;

    /*
        Saturation
        ----------
        Boost colors depending on human-eye perceived weights.

        - A value of 1.0 is neutral and does nothing.
        - Under 1.0 the image approaches grayscale until 0.0.
        - Over 1.0 the colors start to get stronger.
    */
    color = mix(vec3(luminance(color)), color, POST_SATURATION);

    f_color = vec4(color, 1.0);

    // if (texcoord.x > 0.5) {
	// 	vec2 uv = texcoord;
	// 	uv.x -= 0.5;
	// 	uv.x *= 2.0;

	// 	f_color = texture(s_entity, uv);
    // }
}