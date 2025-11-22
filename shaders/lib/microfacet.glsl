/*

    Project Lyrae
    Copyright (c) 2025 lucysir

    This file is a part of Project Lyrae (the "Software") and is
    subject to the Project Lyrae License.
    
    Full license text: https://github.com/kadir014/lyrae-shaders/blob/main/LICENSE
    Official page: https://modrinth.com/project/lyrae-shaders

*/

#ifndef MICROFACET_H
#define MICROFACET_H


// Trowbridge-Reitz / GGX Normal Distribution Function
float D_GGX(float NoH, float alpha) {
    float alpha_sqr = alpha * alpha;
    float denom = (NoH * NoH) * (alpha_sqr - 1.0) + 1.0;
    return alpha_sqr / (PI * denom * denom);
}

// Schlick approximation for Fresnel term
vec3 F_Schlick(vec3 f0, float VoH) {
    // f90 = 1.0
    return f0 + (vec3(1.0) - f0) * pow(1.0 - VoH, 5.0);
}

// Schlick approximation for GGX monodirectional shadowing function
float G1_SchlickGGX(float NdotX, float roughness) {
    /*
        According to UE4 paper, this modification is only for analytical light
        sources and makes the results at glancing angles much darker:
        float r = roughness + 1.0;
        float k = (r * r) / 8.0;

        They also mention choosing k as alpha/2 to match Smith.
    */
    float k = roughness * 0.5;
    return NdotX / (NdotX * (1.0 - k) + k);
}

// Bidirectional shadowing-masking function
// g1(v) * g1(l)
float G_Smith(float NdotV, float NdotL, float roughness) {
    float ggx1 = G1_SchlickGGX(NdotV, roughness);
    float ggx2 = G1_SchlickGGX(NdotL, roughness);
    return ggx1 * ggx2;
}

// From UE4 paper
// https://cdn2.unrealengine.com/Resources/files/2013SiggraphPresentationsNotes-26915738.pdf
vec3 GGX_importance_sample(vec2 xi, float roughness, vec3 N) {
    float alpha = roughness * roughness;
    float phi = TAU * xi.x;
    float cos_theta = sqrt((1.0 - xi.y) / (1.0 + (alpha * alpha - 1.0) * xi.y));
    float sin_theta = sqrt(1.0 - cos_theta * cos_theta);

    // Spherical coordinates
    vec3 H;
    H.x = sin_theta * cos(phi);
    H.y = sin_theta * sin(phi);
    H.z = cos_theta;

    vec3 up = abs(N.z) < 0.9999 ? vec3(0.0, 0.0, 1.0) : vec3(1.0, 0.0, 0.0);
    vec3 tangent_x = normalize(cross(up, N));
    vec3 tangent_y = cross(N, tangent_x);

    // Tangent to world space
    return tangent_x * H.x + tangent_y * H.y + N * H.z;
}


#endif // MICROFACET_H