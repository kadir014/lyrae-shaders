/*

    Project Lyrae
    Copyright (c) 2025 lucysir

    This file is a part of Project Lyrae (the "Software") and is
    subject to the Project Lyrae License.
    
    Full license text: https://github.com/kadir014/lyrae-shaders/blob/main/LICENSE
    Official page: https://modrinth.com/project/lyrae-shaders

*/

#ifndef PREETHAM_H
#define PREETHAM_H

#include "common.glsl"
#include "color.glsl"


/*
    A Practical Analytic Model for Daylight
    
    A. J. Preetham et al.

    https://courses.cs.duke.edu/cps124/spring08/assign/07_papers/p91-preetham.pdf
*/


#define PREETHAM_INV_120 0.00833333333333333333333333333333  // 1.0 / 120.0
#define PREETHAM_4_OVER_9 0.44444444444444444444444444444444 // 4.0 / 9.0


// Coefficients are in xyY
void perez_distribution_coefficients(
    float T,
    out vec3 A,
    out vec3 B,
    out vec3 C,
    out vec3 D,
    out vec3 E
) {
    // Values are given in section A.2
	A = vec3(-0.0193 * T - 0.2592, -0.0167 * T - 0.2608,  0.1787 * T - 1.4630);
	B = vec3(-0.0665 * T + 0.0008, -0.0950 * T + 0.0092, -0.3554 * T + 0.4275);
	C = vec3(-0.0004 * T + 0.2125, -0.0079 * T + 0.2102, -0.0227 * T + 5.3251);
	D = vec3(-0.0641 * T - 0.8989, -0.0441 * T - 1.6537,  0.1206 * T - 2.5771);
	E = vec3(-0.0033 * T + 0.0452, -0.0109 * T + 0.0529, -0.0670 * T + 0.3703);
}

// Returns in xyY
vec3 zenith_chromaticity(float T, float theta_s) {
    // Values are given in section A.2

	float chi = (PREETHAM_4_OVER_9 - T * PREETHAM_INV_120) * (PI - 2.0 * theta_s);
	float Yz = (4.0453 * T - 4.9710) * tan(chi) - 0.2155 * T + 2.4192;

	float theta_s2 = theta_s * theta_s;
    float theta_s3 = theta_s2 * theta_s;
    float T2 = T * T;

	float xz = ( 0.0017 * theta_s3 - 0.0037 * theta_s2 + 0.0021 * theta_s + 0.0   ) * T2 +
               (-0.0290 * theta_s3 + 0.0638 * theta_s2 - 0.0320 * theta_s + 0.0039) * T +
               ( 0.1169 * theta_s3 - 0.2120 * theta_s2 + 0.0605 * theta_s + 0.2589);

    float yz = ( 0.0028 * theta_s3 - 0.0061 * theta_s2 + 0.0032 * theta_s + 0.0   ) * T2 +
               (-0.0421 * theta_s3 + 0.0897 * theta_s2 - 0.0415 * theta_s + 0.0052) * T +
               ( 0.1535 * theta_s3 - 0.2676 * theta_s2 + 0.0667 * theta_s + 0.2669);

	return vec3(xz, yz, Yz);
}

vec3 perez_model(
    float theta,
    float gamma,
    vec3 A,
    vec3 B,
    vec3 C,
    vec3 D,
    vec3 E
) {
    // Equation 3 in chapter 2.3
    float cos_gamma = cos(gamma);
	return (1.0 + A * exp(B / cos(theta))) * (1.0 + C * exp(D * gamma) + E * cos_gamma * cos_gamma);
}

// Returns sky color in RGB
vec3 preetham_sky(vec3 sun_dir, vec3 view_dir, float turbidity) {
	vec3 A, B, C, D, E;
	perez_distribution_coefficients(turbidity, A, B, C, D, E);

	float theta_s = acos(max(dot(sun_dir, vec3(0.0, 1.0, 0.0)), 0.0));
	float theta_e = acos(max(dot(view_dir, vec3(0.0, 1.0, 0.0)), 0.0));
	float gamma_e = acos(max(dot(sun_dir, view_dir), 0.0));

	vec3 zenith_xyY = zenith_chromaticity(turbidity, theta_s);

	vec3 F_num = perez_model(theta_e, gamma_e, A, B, C, D, E);
	vec3 F_denum = perez_model(0.0, theta_s, A, B, C, D, E);

	vec3 preetham_xyY = zenith_xyY * (F_num / F_denum);

	return xyY_to_RGB(preetham_xyY);
}


#endif // PREETHAM_H