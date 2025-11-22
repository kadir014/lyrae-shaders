/*

    Project Lyrae
    Copyright (c) 2025 lucysir

    This file is a part of Project Lyrae (the "Software") and is
    subject to the Project Lyrae License.
    
    Full license text: https://github.com/kadir014/lyrae-shaders/blob/main/LICENSE
    Official page: https://modrinth.com/project/lyrae-shaders

*/

#ifndef DDA_H
#define DDA_H

#include "common.glsl"


bool read_world(vec3 voxel, out vec4 tex_bounds, out vec4 glcolor, out int block_id) {
    ivec3 ivoxel = ivec3(voxel);
	if (voxel_in_bounds(ivoxel, 0, VOXEL_DIAMETER)) {
        vec3 atlasuv = voxel / vec3(float(VOXEL_DIAMETER));
		vec2 packed0 = unpackUnorm2x16(texture(s_texbounds_xy, atlasuv).r);
        vec2 packed1 = unpackUnorm2x16(texture(s_texbounds_zw, atlasuv).r);
        vec4 packed2 = unpackUnorm4x8(texture(s_glcolor, atlasuv).r);
        
        if (packed1.y == 0.0) {
            return false;
        }

        tex_bounds = vec4(packed0.xy,  packed1.xy);
        glcolor = packed2;
        block_id = int(packed2.a * 255.0);
        return true;
	}

    return false;
}

// TODO: OPTIMIZE!!!
HitInfo dda(Ray ray, Ray ray0) {
    HitInfo hitinfo = HitInfo(
        false,
        vec3(0.0),
        vec3(0.0),
        false,
        vec4(-1.0),
        vec4(-1.0),
        vec2(-1.0)
    );

    float u_voxel_size = 1.0;

    // Yeah, not the most robust solution ...
    vec3 delta = ray0.origin - ray.origin;
    vec3 origin = vec3(VOXEL_RADIUS) - delta + fract(ray0.origin);
    ray.origin = origin;
    vec3 voxel = vec3(ivec3(origin));

    int first_id = -1;
    vec4 first_glcolor = vec4(-1.0);
    vec4 first_bounds = vec4(-1.0);
    hitinfo.inside = read_world(voxel, first_bounds, first_glcolor, first_id);

    vec3 step_dir = vec3(
        int(ray.dir.x > 0.0) - int(ray.dir.x < 0.0),
        int(ray.dir.y > 0.0) - int(ray.dir.y < 0.0),
        int(ray.dir.z > 0.0) - int(ray.dir.z < 0.0)
    );

    vec3 next_boundary = vec3(
        (voxel.x + (step_dir.x > 0.0 ? 1.0 : 0.0)) * u_voxel_size,
        (voxel.y + (step_dir.y > 0.0 ? 1.0 : 0.0)) * u_voxel_size,
        (voxel.z + (step_dir.z > 0.0 ? 1.0 : 0.0)) * u_voxel_size
    );

    vec3 t_max = next_boundary - ray.origin;
    if (ray.dir.x == 0.0) t_max.x = HIGHP_FLT_MAX;
    else t_max.x /= ray.dir.x;
    if (ray.dir.y == 0.0) t_max.y = HIGHP_FLT_MAX;
    else t_max.y /= ray.dir.y;
    if (ray.dir.z == 0.0) t_max.z = HIGHP_FLT_MAX;
    else t_max.z /= ray.dir.z;

    vec3 t_delta = vec3(0.0);
    if (ray.dir.x == 0.0) t_delta.x = HIGHP_FLT_MAX;
    else t_delta.x = abs(u_voxel_size / ray.dir.x);
    if (ray.dir.y == 0.0) t_delta.y = HIGHP_FLT_MAX;
    else t_delta.y = abs(u_voxel_size / ray.dir.y);
    if (ray.dir.z == 0.0) t_delta.z = HIGHP_FLT_MAX;
    else t_delta.z = abs(u_voxel_size / ray.dir.z);

    // Traverse world texture
    for (int i = 0; i < MAX_DDA_STEPS; i++) {
        float hit_t = min(t_max.x, min(t_max.y, t_max.z));

        if (t_max.x < t_max.y && t_max.x < t_max.z) {
            voxel.x += step_dir.x;
            t_max.x += t_delta.x;
            hitinfo.normal = vec3(-step_dir.x, 0.0, 0.0);
        }
        else if (t_max.y < t_max.z) {
            voxel.y += step_dir.y;
            t_max.y += t_delta.y;
            hitinfo.normal = vec3(0.0, -step_dir.y, 0.0);
        }
        else {
            voxel.z += step_dir.z;
            t_max.z += t_delta.z;
            hitinfo.normal = vec3(0.0, 0.0, -step_dir.z);
        }

        int voxel_id = -1;
        vec4 voxel_glcolor = vec4(-1.0);
        vec4 voxel_bounds = vec4(-1.0);
        bool voxel_hit = read_world(voxel, voxel_bounds, voxel_glcolor, voxel_id);

        //Connected voxels, useful for glass
        if (voxel_hit && any(equal(first_bounds, voxel_bounds))) {
            continue;
        }

        if (hitinfo.inside || voxel_hit) {
            hitinfo.hit = true;

            hitinfo.point = ray.origin + ray.dir * hit_t;

            //if (hitinfo.inside) hitinfo.normal = -hitinfo.normal;

            if (hitinfo.inside) {
                hitinfo.tex_bounds = first_bounds;
                hitinfo.glcolor = first_glcolor;
            }
            else {
                hitinfo.tex_bounds = voxel_bounds;
                hitinfo.glcolor = voxel_glcolor;
            }

            vec3 local = fract(hitinfo.point / u_voxel_size);

            // Project onto correct plane
            vec3 abs_n = abs(hitinfo.normal);
            hitinfo.face_uv = local.yz * abs_n.x + local.xz * abs_n.y + local.xy * abs_n.z;

            hitinfo.face_uv = mix(hitinfo.face_uv, hitinfo.face_uv.yx, abs_n.x); // swap axes for X faces
            hitinfo.face_uv.x = mix(hitinfo.face_uv.x, 1.0 - hitinfo.face_uv.x, step(0.0, hitinfo.normal.z));
            hitinfo.face_uv.y = mix(hitinfo.face_uv.y, hitinfo.face_uv.y, step(0.0, -hitinfo.normal.y));

            break;
        }
    }

    return hitinfo;
}


#endif // DDA_H