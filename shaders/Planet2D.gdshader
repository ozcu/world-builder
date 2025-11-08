shader_type canvas_item;

// ===== Controls =====
uniform float seed = 123.0;
uniform float rotation_y = 0.0;  // Y-axis rotation in radians for planet spin
uniform float elevation_amp = 0.10;
uniform float elevation_freq = 2.0;
uniform float detail_amp = 0.02;
uniform float detail_freq = 6.0;

uniform vec3 shallow_color = vec3(0.04, 0.25, 0.55);
uniform vec3 land_low     = vec3(0.12, 0.36, 0.10);
uniform vec3 land_high    = vec3(0.70, 0.66, 0.56);
uniform vec3 snow_color   = vec3(0.95, 0.98, 1.0);

uniform float water_level = 0.0;
uniform float snow_height = 0.55;

// Lighting / look
uniform float light_angle = 0.6; // radians; 0 = +X
uniform float light_strength = 1.25; // brighter direct light
uniform float ambient_floor  = 0.28; // minimum light on night side
uniform float exposure       = 1.25; // final multiplier
uniform float edge_vignette  = 0.25; // 0..1, lower = less dark rim

// Specular for oceans
uniform float specular_strength = 0.9;   // 0..1
uniform float specular_gloss    = 80.0;  // higher = tighter highlight

// Optional gas-giant bands (set band_strength > 0 to use)
uniform float band_strength = 0.0;   // 0 = off, 1 = full
uniform float band_freq     = 7.0;
uniform float band_contrast = 2.0;
uniform vec3  band_col_a    = vec3(0.85, 0.80, 0.70);
uniform vec3  band_col_b    = vec3(0.90, 0.88, 0.83);

// ===== Noise =====
float hash(vec3 p){ return fract(sin(dot(p, vec3(12.9898,78.233,37.719))) * 43758.5453 + seed); }

float noise3(vec3 p){
    vec3 i = floor(p);
    vec3 f = fract(p);
    float s = 0.0;
    for (int x = 0; x <= 1; x++)
    for (int y = 0; y <= 1; y++)
    for (int z = 0; z <= 1; z++) {
        vec3 c = vec3(float(x), float(y), float(z));
        float h = hash(i + c);
        vec3  w = abs(f - c);
        s += h * (1.0 - w.x) * (1.0 - w.y) * (1.0 - w.z);
    }
    return s;
}

float fbm(vec3 p){
    float a = 0.5;
    float s = 0.0;
    for (int i=0;i<6;i++){ s += a * noise3(p); p *= 2.02; a *= 0.5; }
    return s;
}

void fragment() {
    // circle → sphere mapping
    vec2 uv = UV * 2.0 - 1.0;
    float r = length(uv);
    if (r > 1.0) { discard; }

    float z = sqrt(max(0.0, 1.0 - r*r));
    vec3 n = normalize(vec3(uv, z));  // Unrotated normal for lighting

    // Create rotated normal for terrain sampling only
    float c = cos(rotation_y);
    float s = sin(rotation_y);
    mat3 rot_y = mat3(
        vec3(c, 0.0, s),
        vec3(0.0, 1.0, 0.0),
        vec3(-s, 0.0, c)
    );
    vec3 n_terrain = rot_y * n;

    // continents (sample terrain using rotated normal)
    float h = fbm(n_terrain * elevation_freq);
    h += detail_amp * (fbm(n_terrain * detail_freq) - 0.5);
    float height = (h * 2.0 - 1.0) * elevation_amp;

    // base colors (use rotated normal for latitude so polar caps rotate)
    float lat = abs(n_terrain.y);
    float height_norm = smoothstep(-elevation_amp, elevation_amp, height);
    vec3 land_col = mix(land_low, land_high, height_norm);
    land_col = mix(land_col, land_col * vec3(1.12,1.07,1.0),
                   clamp(0.5 - abs(lat-0.5), 0.0, 0.5) * 2.0);
    float snow_mask = smoothstep(snow_height, snow_height + 0.05, height_norm) * smoothstep(0.35, 0.9, lat);
    land_col = mix(land_col, snow_color, snow_mask);
    vec3 ocean_col = shallow_color * (0.7 + 0.3 * height_norm);
    bool ocean = height < water_level;
    vec3 col = ocean ? ocean_col : land_col;

    // Optional gas bands (override terrain look)
    if (band_strength > 0.001) {
        float warp = fbm(n_terrain * 5.0) * 0.6;
        float b = sin(n_terrain.y * band_freq + warp);
        b = 0.5 + 0.5 * sign(b) * pow(abs(b), band_contrast);
        vec3 band_col = mix(band_col_a, band_col_b, b);
        col = mix(col, band_col, clamp(band_strength, 0.0, 1.0));
        ocean = false; // no ocean specular for gas giants
    }

    // lighting
    vec3 L = normalize(vec3(cos(light_angle), 0.25, sin(light_angle)));
    vec3 V = vec3(0.0, 0.0, 1.0); // screen-facing
    float ndl = max(0.0, dot(n, L));
    float lit = ambient_floor + light_strength * ndl;

    // specular highlight (oceans only)
    float spec = 0.0;
    if (ocean) {
        vec3 H = normalize(L + V);
        spec = pow(max(dot(n, H), 0.0), specular_gloss) * specular_strength;
    }

    // softer rim darkening
    float vignet = mix(1.0, smoothstep(1.0, 0.55, r), edge_vignette);

    col = (col * lit + spec) * exposure * vignet;

    COLOR = vec4(clamp(col, 0.0, 1.0), 1.0);
}
