/*

    Project Lyrae
    Copyright (c) 2025 lucysir

    This file is a part of Project Lyrae (the "Software") and is
    subject to the Project Lyrae License.
    
    Full license text: https://github.com/kadir014/lyrae-shaders/blob/main/LICENSE
    Official page: https://modrinth.com/project/lyrae-shaders

*/

#ifndef ATROUS_H
#define ATROUS_H


/*
    Edge-Avoiding À-Trous Wavelet Transform for fast Global Illumination Filtering
        
    Holger Dammertz et al.

    https://jo.dreggn.org/home/2010_atrous.pdf
*/


struct ATrousData {
    float gi_phi;
    float normal_phi;
    float position_phi;

    float stepwidth;
    float kernel[25];
    vec2 offset[25];
};

vec3 edge_avoiding_atrous(
    sampler2D gi_map,
    sampler2D normal_map,
    sampler2D position_map,
    ATrousData data,
    vec2 p,
    vec2 resolution
) {
    vec2 pixel = p * resolution;

    vec3 sum = vec3(0.0);
    float cum_w = 0.0;

    vec3 cval = texelFetch(gi_map, ivec2(pixel), 0).rgb;
    vec3 nval = texelFetch(normal_map, ivec2(pixel), 0).rgb;
    vec3 pval = texelFetch(position_map, ivec2(pixel), 0).rgb;

    float inv_gi_phi = 1.0 / data.gi_phi;
    float inv_normal_phi = 1.0 / data.normal_phi;
    float inv_position_phi = 1.0 / data.position_phi;
    float invstepsq = 1.0 / (data.stepwidth * data.stepwidth);

    for (int i = 0; i < 25; i++) {
        ivec2 uv = ivec2(pixel + data.offset[i] * data.stepwidth);

        vec3 ctmp = texelFetch(gi_map, uv, 0).rgb;
        vec3 t = cval - ctmp;
        float dist2 = dot(t, t);
        float c_w = min(exp(-(dist2) * inv_gi_phi), 1.0);

        vec3 ntmp = texelFetch(normal_map, uv, 0).rgb;
        t = nval - ntmp;
        dist2 = max(dot(t, t) * invstepsq, 0.0);
        float n_w = min(exp(-(dist2) * inv_normal_phi), 1.0);

        vec3 ptmp = texelFetch(position_map, uv, 0).rgb;
        t = pval - ptmp;
        dist2 = dot(t, t);
        float p_w = min(exp(-(dist2) * inv_position_phi), 1.0);

        float weight = c_w * n_w * p_w;
        sum += ctmp * weight * data.kernel[i];
        cum_w += weight * data.kernel[i];
    }

    return sum / cum_w;
}


#endif // ATROUS_H