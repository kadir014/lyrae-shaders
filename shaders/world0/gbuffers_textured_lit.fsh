/*

    Project Lyrae
    Copyright (c) 2025 lucysir

    This file is a part of Project Lyrae (the "Software") and is
    subject to the Project Lyrae License.
    
    Full license text: https://github.com/kadir014/lyrae-shaders/blob/main/LICENSE
    Official page: https://modrinth.com/project/lyrae-shaders

*/

#version 430 compatibility


uniform sampler2D lightmap;
uniform sampler2D gtexture;

uniform float alphaTestRef = 0.1;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;

/* RENDERTARGETS: 13 */
layout(location = 0) out vec4 f_color;


void main() {
	f_color = texture(gtexture, texcoord) * glcolor;
	f_color *= texture(lightmap, lmcoord);
	if (f_color.a < alphaTestRef) {
		discard;
	}
}