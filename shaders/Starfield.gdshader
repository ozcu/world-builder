shader_type canvas_item;

// High-quality procedural starfield shader
uniform float star_density : hint_range(0.0, 1.0) = 0.015;
uniform float star_brightness : hint_range(0.0, 2.0) = 1.0;
uniform vec2 scroll_speed = vec2(0.0, 0.0);
uniform float time_scale = 0.1;

// Hash function for pseudo-random numbers
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

// Noise function
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Generate stars at different scales
float stars(vec2 uv, float scale, float threshold) {
    vec2 st = uv * scale;
    vec2 i_st = floor(st);
    vec2 f_st = fract(st);

    float m_dist = 1.0;
    vec2 m_point;

    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 neighbor = vec2(float(x), float(y));
            vec2 point = hash(i_st + neighbor) * vec2(1.0, 1.0);
            point = 0.5 + 0.5 * sin(TIME * time_scale + 6.2831 * point);

            vec2 diff = neighbor + point - f_st;
            float dist = length(diff);

            if (dist < m_dist) {
                m_dist = dist;
                m_point = point;
            }
        }
    }

    float star = smoothstep(threshold + 0.01, threshold, m_dist);
    float twinkle = 0.5 + 0.5 * sin(TIME * 2.0 + hash(i_st + m_point) * 6.28);

    return star * twinkle;
}

void fragment() {
    vec2 uv = UV + scroll_speed * TIME * 0.01;

    // Multiple layers of stars for depth
    float stars1 = stars(uv, 30.0, 0.05) * 1.0;  // Large close stars
    float stars2 = stars(uv, 60.0, 0.03) * 0.7;  // Medium stars
    float stars3 = stars(uv, 120.0, 0.02) * 0.5; // Small distant stars

    // Add some nebula-like background glow
    float nebula = noise(uv * 2.0 + TIME * 0.02) * 0.1;
    nebula += noise(uv * 4.0 - TIME * 0.03) * 0.05;

    // Combine layers
    float star_field = stars1 + stars2 + stars3;
    star_field *= star_brightness;

    // Color variation for stars
    vec3 star_color = vec3(1.0);
    float color_var = hash(uv * 100.0);
    if (color_var > 0.7) {
        star_color = vec3(0.8, 0.9, 1.0); // Blue stars
    } else if (color_var < 0.3) {
        star_color = vec3(1.0, 0.9, 0.8); // Yellow stars
    }

    // Final color with nebula background
    vec3 bg_color = vec3(0.01, 0.01, 0.02); // Very dark blue
    vec3 nebula_color = vec3(0.05, 0.03, 0.08) * nebula; // Purple nebula
    vec3 final_color = bg_color + nebula_color + star_color * star_field;

    COLOR = vec4(final_color, 1.0);
}
