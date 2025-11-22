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
#include "/lib/prng.glsl"
#include "/lib/bsdf.glsl"
#include "/lib/preetham.glsl"


uniform sampler2D lightmap;
uniform sampler2D gtexture;
uniform vec3 skyColor;
uniform float frameTimeCounter;
uniform float shadowAngle;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 normal;
flat in vec2 v_mc_Entity;

/* RENDERTARGETS: 0,12 */
layout(location = 0) out vec4 f_color0;
layout(location = 1) out vec4 f_color12;


void main() {
	vec4 light_color = texture(lightmap, lmcoord);
	vec4 color = texture(gtexture, texcoord);
	color.rgb *= glcolor.rgb;
	color.rgb *= vec3(glcolor.a);

	// v_mc_Entity.x != 13.0 &&
	if (color.a < 0.1) {
		discard;
	}

	// if (v_mc_Entity.x == 13.0) {
	// 	//color.rgb = vec3(0.5);
	// }

	float t = shadowAngle * TAU;
	vec3 u_sun_direction = normalize(vec3(cos(t), sin(t), 0.0));
	float u_sun_angular_radius = 0.03;
	float sun_solid_angle = TAU * (1.0 - cos(u_sun_angular_radius)); 
	float u_sun_radiance = 1500.0;

	float NoL = max(dot(normal, u_sun_direction), 0.0);

	vec4 diffuse_brdf = color / PI;
	vec4 sun_diffuse = diffuse_brdf * (u_sun_radiance * sun_solid_angle * NoL);

	vec3 sky_color = preetham_sky(u_sun_direction, normalize(vec3(0.0, 1.0, 0.0)), 2.73) * 0.042;
	vec4 sky_diffuse = diffuse_brdf * vec4(sky_color, 1.0);

	f_color0 = (sun_diffuse + sky_diffuse) * light_color;

	f_color12 = vec4(color.rgb, 1.0);
}