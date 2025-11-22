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


layout (r32ui) uniform uimage3D img_texbounds_xy;
layout (r32ui) uniform uimage3D img_texbounds_zw;
layout (r32ui) uniform uimage3D img_glcolor;

uniform sampler2D gtexture;
uniform vec3 cameraPosition;
uniform vec3 cameraPositionFract;
uniform mat4 gbufferModelViewInverse;
uniform float frameTimeCounter;
uniform mat4 shadowModelViewInverse;
uniform int entityId;

in vec4 at_midBlock;
in vec2 mc_midTexCoord;
in vec2 mc_Entity;

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;


void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	glcolor = gl_Color;

	vec3 shadow_view_pos = vec4(gl_ModelViewMatrix * gl_Vertex).xyz;
	vec3 feet = (shadowModelViewInverse * vec4(shadow_view_pos, 1.0)).xyz;
	vec3 rel_in_chunk = feet + at_midBlock.xyz * INV_64 + cameraPositionFract;
	ivec3 voxel = ivec3((rel_in_chunk + VOXEL_RADIUS));

	if (
		mod(gl_VertexID, 4) == 0 &&
		voxel_in_bounds(voxel, 0, VOXEL_DIAMETER) &&
		entityId == 0 &&
		(mc_Entity.x == 10.0 || mc_Entity.x == 11.0 || mc_Entity.x == 12.0 || mc_Entity.x == 13.0)
	) {
		vec2 half_tex = abs(texcoord - mc_midTexCoord.xy);
		vec4 texture_bounds = vec4(mc_midTexCoord.xy - half_tex, mc_midTexCoord.xy + half_tex);
		
		// 2x16s for less quantization (texture atlas is large, we need precision)
		imageAtomicMax(img_texbounds_xy, voxel, packUnorm2x16(texture_bounds.xy));
		imageAtomicMax(img_texbounds_zw, voxel, packUnorm2x16(texture_bounds.zw));

		// TODO: block id only upto 255! 
		imageAtomicMax(img_glcolor, voxel, packUnorm4x8(vec4(glcolor.rgb, mc_Entity.x / 255.0)));
	}
}