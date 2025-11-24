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


uniform usampler3D s_texbounds_xy;
uniform usampler3D s_texbounds_zw;
uniform usampler3D s_glcolor;
uniform sampler2D s_entity;

uniform sampler2D colortex0;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D colortex6;
uniform sampler2D colortex7;
uniform sampler2D colortex8;
uniform sampler2D colortex9;
uniform sampler2D colortex10;
uniform sampler2D colortex14;

#include "../lib/common.glsl"
#include "../lib/color.glsl"
#include "../lib/prng.glsl"
#include "../lib/bsdf.glsl"
#include "../lib/dda.glsl"
#include "../lib/preetham.glsl"

uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferProjection;
uniform vec3 previousCameraPosition;
uniform vec3 cameraPosition;
uniform vec3 eyePosition;
uniform vec3 playerLookVector;
uniform float aspectRatio;
uniform ivec2 atlasSize;
uniform float viewWidth;
uniform float viewHeight;
uniform vec3 skyColor;
uniform vec3 shadowLightPosition;
uniform float frameTimeCounter;
uniform int frameCounter;
uniform vec2 gi_resolution;
uniform float sunAngle;
uniform float shadowAngle;

layout(std430, binding = 0) buffer AccLayout {
    int accumulations[];
};

in vec2 texcoord;

/* RENDERTARGETS: 5,6,7,8,9,11 */
layout(location = 0) out vec4 f_color5;
layout(location = 1) out vec4 f_color6;
layout(location = 2) out vec4 f_normal7;
layout(location = 3) out vec4 f_normal8;
layout(location = 4) out vec4 f_position;
layout(location = 5) out vec4 f_sky;


const int voxelDistance = VOXEL_DIAMETER;
const bool colortex5Clear = false;
const bool colortex6Clear = false;
const bool colortex7Clear = false;
const bool colortex8Clear = false;
const bool colortex9Clear = false;
const bool colortex10Clear = false;
const bool colortex11Clear = false;
/*
const int colortex5Format = RGBA16F;
*/
/*
const int colortex6Format = RGBA16F;
*/
/*
const int colortex7Format = RGBA16F;
*/
/*
const int colortex8Format = RGBA16F;
*/
/*
const int colortex9Format = RGBA16F;
*/
/*
const int colortex10Format = RGBA16F;
*/
/*
const int colortex11Format = RGBA16F;
*/

// TODO: Bench 16F vs 32F for performance & image quality


Material material_from_hitinfo(HitInfo hitinfo) {
	/*
		labPBR standard:
		https://shaderlabs.org/wiki/LabPBR_Material_Standard

		Specular Map
		------------
		R -> Perceptual smoothness
		G -> [0, 229]: F0  [230, 255]: Hardcoded metals 
		B -> Not needed for Lyrae
		A -> Emission
	*/

	// TODO: Hardcoded metals, default roughness

	int block_id = int(hitinfo.glcolor.a * 255.0);

	vec4 tex_bounds = hitinfo.tex_bounds;
	vec2 face_uv = hitinfo.face_uv;

	if (block_id == 17 || block_id == 18 || block_id == 19) {
		if (hitinfo.normal.y == 1.0) {
			face_uv.y *= 16.0 / 10.0;
			face_uv.y += 0.1;
		}
		else {
			face_uv.y *= 16.0 / 10.0;
		}

		face_uv.x = 1.0 - face_uv.x;

		//face_uv.x -= 0.5;
		//face_uv.x = 1.0 - face_uv.x;
	}

	face_uv.y = 1.0 - face_uv.y;

	vec2 voxel_tex_uv = mix(tex_bounds.xy, tex_bounds.zw, face_uv);

	vec3 albedo = texture(colortex4, voxel_tex_uv).rgb * hitinfo.glcolor.rgb;

	vec4 specular = texture(colortex14, voxel_tex_uv);

	vec3 emissive = vec3(0.0);
	if (specular.a != 1.0) {
		emissive = specular.a * albedo;
	}

	// Concrete powder
	if (block_id == 11) {
		emissive = albedo * 1.0;
	}
	// Torches
	else if (block_id == 17) {
		albedo = vec3(1.0, 0.85, 0.6);
		emissive = albedo * 1.0;
	}
	else if (block_id == 18) {
		albedo = vec3(0.35, 0.96, 1.0);
		emissive = albedo * 1.0;
	}
	else if (block_id == 19) {
		albedo = vec3(1.0, 0.1, 0.19);
		emissive = albedo * 0.2;
	}

	emissive *= EMISSIVE_MULT;

	float roughness = pow(1.0 - specular.r, 2.0);
	float metallic = 0.0;
	float glass = 0.0;

	if (block_id == 12) {
		metallic = 1.0;
	}
	else if (block_id == 13) {
		glass = 1.0;
	}

	return Material(
        albedo,
        emissive,
        metallic,
        roughness,
        DIELECTRIC_BASE_REFLECTANCE,
        glass,
        1.4
    );
}

bool is_ray_occluded(vec3 pos, vec3 dir, Ray ray0, out Material nee_mat) {
    HitInfo hitinfo = dda(Ray(pos, dir), ray0, 0);
	nee_mat = material_from_hitinfo(hitinfo);

	#if (ARTISTIC_CAUSTICS == 1)
		if (nee_mat.glass > 0.5) hitinfo.hit = false;
	#endif

    return hitinfo.hit;
}

vec3 pathtrace(Ray ray, out HitInfo primary_hit, out Material primary_mat) {
	vec3 radiance = vec3(0.0); // Final ray color
    vec3 radiance_delta = vec3(1.0); // Accumulated multiplier (throughput)

    bool allow_nee = bool(ENABLE_NEE);

	float t = shadowAngle * TAU;
	vec3 u_sun_direction = normalize(vec3(cos(t), sin(t), 0.0));
	float u_sun_angular_radius = 0.03;
	float u_sun_radiance = 1500.0;

	Ray ray0 = Ray(ray.origin, ray.dir);

	for (int bounce = 0; bounce < MAX_BOUNCES; bounce++) {

		/******************************

                 Trace the ray

         ******************************/
		
		HitInfo hitinfo = dda(ray, ray0, bounce);

		if (bounce == 0) {
			primary_hit = hitinfo;
		}

		/******************************

              Environment sampling

         ******************************/

		if (!hitinfo.hit) {
			float cos_angle = dot(ray.dir, u_sun_direction);
            float cos_theta_max = cos(u_sun_angular_radius);

            // We shouldn't show the sun in the sky to avoid double-counting lights
            // if NEE is enabled, BSDF shouldn't reach the sun.
            bool show_sun = (cos_angle >= cos_theta_max) &&
                            (!allow_nee || bounce == 0);

            if (show_sun) {
                radiance += u_sun_radiance * radiance_delta;
                break;
            }
            else {
				vec3 sky_color = preetham_sky(u_sun_direction, ray.dir, 2.73) * 0.042;
                radiance += sky_color * radiance_delta;
                break;
            }
		}

		/******************************

            Prepare surface material

         ******************************/

        vec3 N = normalize(hitinfo.normal);
        vec3 V = normalize(-ray.dir);

		Material material = material_from_hitinfo(hitinfo);
		if (bounce == 0) {
			primary_mat = material;
		}

		/******************************

           NEE (Next Event Estimation)

         ******************************/

        if (allow_nee) {
            vec3 sun_world_dir;
            float sun_pdf;
            sample_sun_cone(
                u_sun_direction,
                u_sun_angular_radius,
                sun_world_dir,
                sun_pdf
            );

			Material nee_mat;
            if (!is_ray_occluded(hitinfo.point + N * EPSILON, sun_world_dir, ray0, nee_mat)) {
                BSDFState state = prepare_bsdf(material);
                vec3 H = normalize(V + sun_world_dir);

                vec3 nee_bsdf = vec3(0.0);
                float nee_pdf = 0.0;
                if (state.lobe < state.diffuse_weight) {
                    nee_bsdf = diffuse_brdf(V, N, sun_world_dir, state, nee_pdf);
                }
                else {
                    if (state.lobe < state.diffuse_weight + state.specular_weight) {
                        nee_bsdf = specular_brdf(V, N, sun_world_dir, H, state, nee_pdf);
                    }
                    else if (state.transmit_weight > 0.0) {
                        nee_bsdf = specular_btdf(V, N, sun_world_dir, H, hitinfo.inside, state, nee_pdf);
                    }
                }

                // Brings NaNs
                if (nee_pdf > 0.0) {
					vec3 nee_radiance = radiance_delta * nee_bsdf * u_sun_radiance / sun_pdf;

					#if (ARTISTIC_CAUSTICS == 1)
						/*
							The NEE ray is obstructed by a glass, so fake caustics.
							Since everything is flat surfaces (voxels), I chose the creative
							freedom to abandon physical accuracy here.
						*/
						if (nee_mat.glass > 0.5) {
							nee_radiance *= nee_mat.albedo;
						}
					#endif

                    radiance += nee_radiance;
                }
                // else {
                //     issue = true;
                // }
            }
        }

		/******************************

            Indirect lighting (BSDF)

         ******************************/

		vec3 L;
        float pdf;
        vec3 bsdf = sample_bsdf(V, N, hitinfo.inside, material, L, pdf);

		// Current surface emission
        if (length(material.emissive) > 0.0) {
            radiance += material.emissive * radiance_delta;
        }

		// Absorption
        if (pdf > 0.0) {
            // BSDF radiance is already multiplied by NoL
            radiance_delta *= bsdf / pdf;
        }

		// Spawn new ray from the BSDF reflection
        ray = Ray(hitinfo.point + (N * EPSILON * 2.1), L);

		#if (ARTISTIC_CAUSTICS == 0)
			// If BSDF sampling reached a transmissive surface, disable NEE so
			// BSDF can reach sky
			if (material.glass > 0.0) {
				allow_nee = false;
			}
		#endif
	}

	return radiance;
}

vec3 reproject(
	vec3 world_pos,
	vec3 prev_pos,
	vec3 prev_front,
	vec3 prev_u,
	vec3 prev_v
) {
	vec3 delta = world_pos - prev_pos;
    vec3 delta_n = normalize(delta);

    vec3 camera_dir = normalize(prev_front);
	vec3 u = normalize(prev_u);
    vec3 v = normalize(prev_v);

    float d = dot(camera_dir, delta_n);
    if (d < EPSILON) {
        return vec3(0.0, 0.0, -1.0);
    }
    d = 1.0 / d;

    delta = delta_n * d - camera_dir;

	// TODO: no need for length calls
    float x = dot(delta, u) / length(prev_u);
    float y = dot(delta, v) / length(prev_v);
    vec2 uv = vec2(x, y);

    // [-1, 1] -> [0, 1]
    uv = uv * 0.5 + 0.5;

    return vec3(uv, 1.0);
}


void main() {
	ivec2 pixel = ivec2(texcoord * vec2(viewWidth, viewHeight));

	ivec2 acc_pixel = ivec2(texcoord * gi_resolution);
	int acc_index = acc_pixel.x + acc_pixel.y * int(gi_resolution.x);

	mat4 inv_prev_view = inverse(gbufferPreviousModelView);
	// TODO: Handle eye pos (view bobbing and such)
	vec3 prev_cam = previousCameraPosition;
	vec3 current_cam = cameraPosition;
	vec3 cam_delta = current_cam - prev_cam;
	vec3 current_cam_fract = fract(current_cam);

	vec3 prev_front = -normalize(vec3(inv_prev_view[2].xyz));
	vec3 prev_pos = vec3(VOXEL_RADIUS) + current_cam_fract - cam_delta;
	vec3 prev_u = normalize(cross(prev_front, vec3(0.0, 1.0, 0.0)));
	vec3 prev_v = normalize(cross(prev_u, prev_front));

	float prev_fov = 2.0 * atan(1.0 / gbufferPreviousProjection[1][1]);
	float prev_half_height = tan(prev_fov * 0.5);
	float prev_half_width = prev_half_height * aspectRatio;
	prev_u *= prev_half_width;
	prev_v *= prev_half_height;


	vec3 pos = vec3(VOXEL_RADIUS) + current_cam_fract;
	vec3 front = -normalize(vec3(gbufferModelViewInverse[2].xyz));
	vec3 u = normalize(cross(front, vec3(0.0, 1.0, 0.0)));
	vec3 v = normalize(cross(u, front));

	float fov = 2.0 * atan(1.0 / gbufferProjection[1][1]);
	float half_height = tan(fov * 0.5);
	float half_width = half_height * aspectRatio;
	u *= half_width;
	v *= half_height;

	vec2 uv = texcoord * 2.0 - 1.0;
	vec3 screen_world = (pos + front) + u * uv.x + v * uv.y;


	// We are not doing jiter sampling
	// No need to generate new ray for each sample
	Ray ray = Ray(pos, normalize(screen_world - pos));

	HitInfo primary_hit;
	Material primary_mat;
	vec3 final_radiance = vec3(0.0);

    for (int sample_i = 0; sample_i < SAMPLE_COUNT; sample_i++) {

        // Initialize PRNGs
		int temporal_frame_i = accumulations[acc_pixel.x + acc_pixel.y * int(gi_resolution.x)];
        prng_seed(pixel, sample_i+1, temporal_frame_i);

		vec3 radiance;
		if (sample_i == 0) {
			radiance = pathtrace(ray, primary_hit, primary_mat);
		}
		else {
			HitInfo temp_hit;
			Material temp_mat;
        	radiance = pathtrace(ray, temp_hit, temp_mat);
		}
        final_radiance += radiance / float(SAMPLE_COUNT);
    }

	int pingpong = frameCounter % 2;

	vec4 f_normal = vec4(0.0);

	if (primary_hit.hit) {
		vec3 gi_out = final_radiance;

		vec3 ray_delta = primary_hit.point - pos;
		float curr_depth = length(ray_delta);
		
		f_normal = vec4(primary_hit.normal, curr_depth);

		f_position = vec4(primary_hit.point, 1.0);

		// Demodulate albedo
		gi_out = mix(gi_out / primary_mat.albedo, vec3(0.0), equal(primary_mat.albedo, vec3(0.0)));

		#if (ENABLE_ACCUMULATION == 1)
			vec3 prev_uv = reproject(primary_hit.point, prev_pos, prev_front, prev_u, prev_v);

			if (
				primary_hit.hit &&
				prev_uv.z > 0.0 &&
				(prev_uv.x > 0.0 && prev_uv.x < 1.0 && prev_uv.y > 0.0 && prev_uv.y < 1.0)
			) {
				// rgb -> normal  alpha -> depth
				vec4 _previous_normal_sample = vec4(0.0);
				if (pingpong == 0) {
					_previous_normal_sample = texture(colortex8, prev_uv.xy);
				}
				else {
					_previous_normal_sample = texture(colortex7, prev_uv.xy);
				}
				vec3 previous_normal = normalize(_previous_normal_sample.rgb);
				float previous_depth = _previous_normal_sample.a;

				// Depth is relative to each scene but it's linear
				float normal_diff = dot(primary_hit.normal, previous_normal);
				float depth_diff = curr_depth - previous_depth;

				// Very arbitrary values I found by playing around ...
				float normal_threshold = 0.97;
				float depth_threshold = 0.5;

				if (
					//normal_diff > normal_threshold &&
					abs(depth_diff) < depth_threshold
				) {
					vec3 previous_color = vec3(0.0);
					if (pingpong == 0) {
						previous_color = texture(colortex6, prev_uv.xy).rgb;
					}
					else {
						previous_color = texture(colortex5, prev_uv.xy).rgb;
					}

					if (!any(isnan(previous_color)) && !any(isinf(previous_color))) {
						// Temporal blending weight
						int acc = accumulations[acc_index];

						float acc_limit = float(DIFFUSE_ACCUMULATION_LENGTH);

						if (
							primary_mat.glass > 0.5 ||
							primary_mat.metallic > 0.5
						) {
							acc_limit = float(SPECULAR_ACCUMULATION_LENGTH);
						}

						float capped_frame = min(float(acc), acc_limit);
						float weight = 1.0 / (capped_frame + 1.0);

						// Blend current and reprojected colors
						gi_out = mix(previous_color, gi_out, weight);

						accumulations[acc_index] += 1;
					}
					else {
						// Don't blend NaN history
						accumulations[acc_index] = 0;
					}
				}
				else {
					// Reject
					accumulations[acc_index] = 0;
				}
			}
			else {
				// No valid history reset accumulation
				accumulations[acc_index] = 0;
			}

		#else

			accumulations[acc_index] = 0;

		#endif

		ray_delta = abs(ray_delta);
		float c_depth = max(ray_delta.x, max(ray_delta.y, ray_delta.z));
		float max_depth = float(VOXEL_RADIUS)-1.0;

		float x = clamp(c_depth / max_depth, 0.0, 1.0);
		//float alpha = 1.0 - (curr_depth / max_depth);
		float a = 0.55;
		// TODO: OPTIMIZE! two pows!!!
		float alpha = 1.0 - pow(x, pow(a + 1.0, 7.0));
		//alpha = 1.0;

		//gi_out = primary_mat.albedo;

		if (pingpong == 0) {
			f_color5 = vec4(gi_out, alpha);
			f_normal7 = f_normal;
		}
		else {
			f_color6 = vec4(gi_out, alpha);
			f_normal8 = f_normal;
		}
	}
	else {
		accumulations[acc_index] = 0;

		vec4 world_color = vec4(vec3(1.0), 0.0);

		f_color5 = world_color;
		f_color6 = world_color;
	}

	f_sky = vec4(final_radiance, 1.0);
}