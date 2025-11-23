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

/*
    AABB x Ray intersection function
    by iq: https://iquilezles.org/articles/intersectors/

    Edited to support boxes in world space
*/
vec2 aabb_x_ray(
    in vec3 ro,
    in vec3 rd,
    in vec3 boxMin,
    in vec3 boxMax,
    out vec3 outNormal
) {
    vec3 inv = 1.0 / rd;

    vec3 t1 = (boxMin - ro) * inv;
    vec3 t2 = (boxMax - ro) * inv;

    vec3 tmin = min(t1, t2);
    vec3 tmax = max(t1, t2);

    float tN = max(max(tmin.x, tmin.y), tmin.z);
    float tF = min(min(tmax.x, tmax.y), tmax.z);

    if (tN > tF || tF < 0.0)
        return vec2(-1.0);

    outNormal = (tN > 0.0) ? step(vec3(tN), tmin) : // ro ouside the box
                             step(tmax, vec3(tF));  // ro inside the box
    outNormal *= -sign(rd);

    return vec2(tN, tF);
}

void aabb_hit(
    Ray ray,
    inout HitInfo hitinfo,
    inout bool voxel_hit,
    int voxel_id,
    vec3 voxel,
    inout float hit_t,
    out bool first_aabb_hit,
    int bounce
) {
    if (!voxel_hit) return;
    
    vec2 t = vec2(-1.0);
    vec3 aabb_normal;
    bool full_voxel = false;
    first_aabb_hit = false;
    
    // Slab
    if (voxel_id == 14) {
        vec3 aabb_min = vec3(0.0) + voxel;
        vec3 aabb_max = vec3(1.0, 0.5, 1.0) + voxel;

        t = aabb_x_ray(ray.origin, ray.dir, aabb_min, aabb_max, aabb_normal);
    }
    // Carpet
    else if (voxel_id == 15) {
        vec3 aabb_min = vec3(0.0) + voxel;
        vec3 aabb_max = vec3(1.0, INV_16, 1.0) + voxel;

        t = aabb_x_ray(ray.origin, ray.dir, aabb_min, aabb_max, aabb_normal);
    }
    // End rod
    else if (voxel_id == 16) {
        vec3 aabb_min = vec3(0.5 - INV_16, 0.0, 0.5 - INV_16) + voxel;
        vec3 aabb_max = vec3(0.5 + INV_16, 1.0, 0.5 + INV_16) + voxel;

        t = aabb_x_ray(ray.origin, ray.dir, aabb_min, aabb_max, aabb_normal);
    }
    // Torch
    else if (voxel_id == 17 || voxel_id == 18 || voxel_id == 19) {
        float w = bounce == 0 ? 1.0 : 4.0;
        float h = bounce == 0 ? 1.0 : 1.25;
        float s = bounce == 0 ? 0.0 : 0.45;
        vec3 aabb_min = vec3(0.5 - INV_16 * w, s, 0.5 - INV_16 * w) + voxel;
        vec3 aabb_max = vec3(0.5 + INV_16 * w, 10.0 * INV_16 * h, 0.5 + INV_16 * w) + voxel;

        t = aabb_x_ray(ray.origin, ray.dir, aabb_min, aabb_max, aabb_normal);
    }
    else {
        full_voxel = true;
    }

    if (full_voxel) return;

    // TODO: > 0.0 better?
    if (t.y != -1.0) {
        hit_t = t.x;
        hitinfo.normal = aabb_normal;
        first_aabb_hit = true;
    }
    else {
        voxel_hit = false;
    }
}

// TODO: OPTIMIZE!!!
HitInfo dda(Ray ray, Ray ray0, int bounce) {
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
    float first_t = 0.0;
    bool first_hit = read_world(voxel, first_bounds, first_glcolor, first_id);
    bool first_aabb_hit = false;

    aabb_hit(ray, hitinfo, first_hit, first_id, voxel, first_t, first_aabb_hit, bounce);
    vec3 first_normal = hitinfo.normal;

    hitinfo.inside = first_hit;

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
        bool _voxel_unused;
        bool voxel_hit = read_world(voxel, voxel_bounds, voxel_glcolor, voxel_id);

        // Connected voxels, useful for glass
        if (hitinfo.inside && voxel_hit && any(equal(first_bounds, voxel_bounds))) {
            continue;
        }

        // Handle non-full-voxels
        aabb_hit(ray, hitinfo, voxel_hit, voxel_id, voxel, hit_t, _voxel_unused, bounce);

        if (hitinfo.inside || voxel_hit) {
            hitinfo.hit = true;

            if (hitinfo.inside) {
                hitinfo.tex_bounds = first_bounds;
                hitinfo.glcolor = first_glcolor;

                if (first_aabb_hit) {
                    hitinfo.normal = first_normal;
                    hitinfo.point = ray.origin + ray.dir * (first_t);
                }
                else {
                    hitinfo.point = ray.origin + ray.dir * (hit_t);
                }
            }
            else {
                hitinfo.tex_bounds = voxel_bounds;
                hitinfo.glcolor = voxel_glcolor;
                hitinfo.point = ray.origin + ray.dir * (hit_t);
            }

            vec3 local = fract(hitinfo.point / u_voxel_size);

            // Project onto correct plane
            vec3 abs_n = abs(hitinfo.normal);
            hitinfo.face_uv = local.yz * abs_n.x + local.xz * abs_n.y + local.xy * abs_n.z;

            hitinfo.face_uv = mix(hitinfo.face_uv, hitinfo.face_uv.yx, abs_n.x); // swap axes for X faces
            hitinfo.face_uv.x = mix(hitinfo.face_uv.x, 1.0 - hitinfo.face_uv.x, step(0.0, hitinfo.normal.z));
            hitinfo.face_uv.y = mix(hitinfo.face_uv.y, hitinfo.face_uv.y, step(0.0, -hitinfo.normal.y));

            // TODO: PASS THIS TO HITINFO
            // vec4 tex_bounds = hitinfo.tex_bounds;
            // vec2 face_uv = hitinfo.face_uv;
            // face_uv.y = 1.0 - face_uv.y;
            // vec2 voxel_tex_uv = mix(tex_bounds.xy, tex_bounds.zw, face_uv);

            // vec4 albedo = texture(colortex4, voxel_tex_uv);
            // // leaves
            // if (voxel_id == 10 && albedo.a < 1.0) {
            //     hitinfo.hit = false;
            //     continue;
            // }

            break;
        }
    }

    return hitinfo;
}


#endif // DDA_H