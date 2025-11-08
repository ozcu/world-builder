shader_type canvas_item;

// ===== Sun Controls =====
uniform vec3 core_color = vec3(1.0, 0.95, 0.85);      // Inner bright color
uniform vec3 corona_color = vec3(1.0, 0.6, 0.2);      // Outer glow color
uniform float size = 1.0;                             // Overall size multiplier
uniform float corona_intensity = 0.8;                 // Brightness of outer glow
uniform float flare_strength = 0.3;                   // Intensity of surface activity
uniform float rotation_speed = 0.1;                   // Surface rotation speed
uniform float seed = 123.0;

// ===== Noise =====
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453 + seed);
}

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

float fbm(vec2 p) {
    float value = 0.0;
    float amp = 0.5;
    for (int i = 0; i < 5; i++) {
        value += amp * noise(p);
        p *= 2.0;
        amp *= 0.5;
    }
    return value;
}

void fragment() {
    // Circle mapping
    vec2 uv = UV * 2.0 - 1.0;
    float r = length(uv);

    // Rotating surface noise for solar activity
    float angle = atan(uv.y, uv.x);
    vec2 polar = vec2(angle, r);
    polar.x += TIME * rotation_speed;

    // Surface turbulence
    float surface = fbm(polar * 8.0 + TIME * 0.2);
    float flares = fbm(polar * 12.0 - TIME * 0.3) * flare_strength;

    // Core to corona gradient
    float core_radius = 0.6 * size;
    float dist_from_core = smoothstep(0.0, core_radius, r);

    // Blend core and corona colors
    vec3 col = mix(core_color, corona_color, dist_from_core);

    // Add surface detail
    col += vec3(surface * 0.15 + flares * 0.2);

    // Soft circular falloff
    float circle_alpha = 1.0 - smoothstep(0.85 * size, 1.0 * size, r);

    // Bright core with soft edges
    float brightness = 1.5 - dist_from_core * 0.5;
    col *= brightness;

    // Outer glow/corona
    float glow = exp(-r * 2.0) * corona_intensity;
    col += corona_color * glow;

    // Discard pixels outside the sun
    if (r > 1.0 * size) {
        discard;
    }

    COLOR = vec4(clamp(col, 0.0, 2.0), circle_alpha);
}
