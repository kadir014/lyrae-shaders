/*

    Project Lyrae
    Copyright (c) 2025 lucysir

    This file is a part of Project Lyrae (the "Software") and is
    subject to the Project Lyrae License.
    
    Full license text: https://github.com/kadir014/lyrae-shaders/blob/main/LICENSE
    Official page: https://modrinth.com/project/lyrae-shaders

*/

#ifndef COMMON_H
#define COMMON_H

#include "constants.glsl"
#include "types.glsl"
#include "options.glsl"


#if VOXEL_DIAMETER == 128
	#define VOXEL_RADIUS 64
#endif
#if VOXEL_DIAMETER == 64
	#define VOXEL_RADIUS 32
#endif
#if VOXEL_DIAMETER == 32
	#define VOXEL_RADIUS 16
#endif
#if VOXEL_DIAMETER == 16
	#define VOXEL_RADIUS 8
#endif


bool voxel_in_bounds(ivec3 voxel, int low, int high) {
	return (
		voxel.x > low && voxel.x < high &&
		voxel.y > low && voxel.y < high &&
		voxel.z > low && voxel.z < high
	);
}


#endif // COMMON_H