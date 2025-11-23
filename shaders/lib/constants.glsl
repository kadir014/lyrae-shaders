/*

    Project Lyrae
    Copyright (c) 2025 lucysir

    This file is a part of Project Lyrae (the "Software") and is
    subject to the Project Lyrae License.
    
    Full license text: https://github.com/kadir014/lyrae-shaders/blob/main/LICENSE
    Official page: https://modrinth.com/project/lyrae-shaders

*/

#ifndef CONSTANTS_H
#define CONSTANTS_H


/******************************************************

                Mathematical Constants

 ******************************************************/

#define PI      3.141592653589793238462643383279
#define TAU     6.283185307179586476925286766559
#define INV_PI  0.318309886183790671537767526745 // 1.0 / pi
#define INV_TAU 0.159154943091895335768883763372 // 1.0 / tau

#define INV_64  0.015625                         // 1.0 / 64.0
#define INV_16  0.0625                           // 1.0 / 16.0

#define GAMMA   0.454545454545454545454545454545 // 1.0 / 2.2
#define SQRT2   1.414213562373095048801688724209 // sqrt(2.0)
#define EPSILON 0.0005

#define HIGHP_FLT_MAX 999999.0


/******************************************************

                   Rendering Constants

 ******************************************************/

/*
    No real world material has a reflectance lower than 2% (0.02).
    Use 4% as the default constant for dielectrics for consistency
    with other PBR specifications.
*/
#define DIELECTRIC_BASE_REFLECTANCE 0.04

// GGX can mess up if roughness is exactly 0, so clamp it to a minimum value
#define MIN_ROUGHNESS 0.05

// Index of Refraction of air
#define AIR_IOR 1.0

// Maximum allowed number of steps in DDA
#define MAX_DDA_STEPS 56 // 16 * sqrt(3) * 2

// Factor to multiply emissive surface colors by 
#define EMISSIVE_MULT 3.0


#endif // CONSTANTS_H