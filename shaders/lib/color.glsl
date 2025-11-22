/*

    Project Lyrae
    Copyright (c) 2025 lucysir

    This file is a part of Project Lyrae (the "Software") and is
    subject to the Project Lyrae License.
    
    Full license text: https://github.com/kadir014/lyrae-shaders/blob/main/LICENSE
    Official page: https://modrinth.com/project/lyrae-shaders

*/

#ifndef COLOR_H
#define COLOR_H


/*
    Human eyes don't see each color equally, we are more sensitive
    to some than others.

    Instead of using 1/3 for each channel, we use a weight distribution
    more suitable for our eyes to determine the luminance of a color.

    Weights are taken from https://en.wikipedia.org/wiki/Relative_luminance
*/
float luminance(vec3 color) {
    return dot(color, vec3(0.2125, 0.7154, 0.0721));
}

// Convert from CIE xyY color space to XYZ
vec3 xyY_to_XYZ(vec3 xyY) {
    // https://en.wikipedia.org/wiki/CIE_1931_color_space#CIE_XYZ_color_space

	float x = xyY.x;
	float y = xyY.y;
    float Y = xyY.z;

    float c = (Y / y);
	float X = x * c;
	float Z = (1.0 - x - y) * c;

	return vec3(X, Y, Z);
}

// Convert from CIE XYZ color space to RGB
vec3 XYZ_to_RGB(vec3 XYZ) {
	// https://en.wikipedia.org/wiki/CIE_1931_color_space#CIE_rg_chromaticity_space

    // Approximate inverse
	return XYZ * mat3(
		 2.36461385, -0.89654057, -0.46807328,
        -0.51516621,  1.4264081,   0.0887581,
         0.0052037,  -0.01440816,  1.00920446
	);
}

// Convert from CIE xyY color space to RGB
vec3 xyY_to_RGB(vec3 xyY) {
	return XYZ_to_RGB(xyY_to_XYZ(xyY));
}


/*
    ACES filmic tone mapping curve
    https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/
*/
vec3 aces_filmic(vec3 x) {
    float a = 2.51;
    float b = 0.03;
    float c = 2.43;
    float d = 0.59;
    float e = 0.14;
    return clamp((x*(a*x + b)) / (x*(c*x + d) + e), 0.0, 1.0);
}


#endif // COLOR_H