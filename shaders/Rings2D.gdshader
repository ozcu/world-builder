shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform float inner_radius : hint_range(0.0, 1.5) = 0.65;
uniform float outer_radius : hint_range(0.0, 2.0) = 1.35;
uniform float edge_softness : hint_range(0.0, 0.2) = 0.05;

uniform float tilt_deg   : hint_range(0.0, 90.0)  = 23.5;
uniform float rotate_deg : hint_range(0.0, 360.0) = 0.0;

uniform vec3  color_a = vec3(0.86, 0.79, 0.68);
uniform vec3  color_b = vec3(0.92, 0.88, 0.80);
uniform float band_freq     : hint_range(0.0, 30.0) = 12.0;
uniform float band_contrast : hint_range(0.0, 4.0)  = 1.8;

uniform float brightness   : hint_range(0.0, 2.0) = 1.0;
uniform float light_angle  = 0.6;
uniform float day_contrast : hint_range(0.0, 2.0) = 0.8;

/* 0 = full ring, 1 = front half (toward camera), 2 = back half (behind planet) */
uniform int which_half = 0;

/* helpers */
float annulus(vec2 p, float r0, float r1, float soft){
    float r = length(p);
    float a0 = smoothstep(r0 - soft, r0 + soft, r);
    float a1 = 1.0 - smoothstep(r1 - soft, r1 + soft, r);
    return clamp(a0 * a1, 0.0, 1.0);
}

void fragment() {
    vec2 uv = UV * 2.0 - 1.0;

    // screen rotation (mat2 uses column vectors in Godot 4)
    float ang = radians(rotate_deg);
    float c = cos(ang), s = sin(ang);
    mat2 R = mat2(vec2(c, s), vec2(-s, c));
    vec2 q = R * uv;

    // remember sign BEFORE tilt to decide front/back
    float side = q.y;

    // apply tilt by squashing the minor axis (ellipse)
    float ct = max(0.001, cos(radians(tilt_deg)));
    vec2 e = vec2(q.x, q.y / ct);

    // ring base alpha
    float alpha = annulus(e, inner_radius, outer_radius, edge_softness);

    // split into halves
    if (which_half == 1) {
        alpha *= step(0.0, side);        // keep q.y >= 0 (front)
    } else if (which_half == 2) {
        alpha *= step(side, 0.0);        // keep q.y < 0  (back)
    }

    // banding
    float r = length(e);
    float bands = 0.5 + 0.5 * sin(r * band_freq * 6.28318530718);
    bands = pow(max(bands, 0.0), band_contrast);
    vec3 base = mix(color_a, color_b, bands);

    // simple day/night falloff across ring
    vec2 L = vec2(cos(light_angle), sin(light_angle));
    float day = clamp(0.5 + 0.5 * dot(normalize(q + 1e-6), normalize(L)), 0.0, 1.0);
    day = mix(1.0, day, day_contrast);

    COLOR = vec4(base * brightness * day, alpha);
}
