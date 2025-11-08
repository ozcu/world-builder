shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform float seed = 42.0;
uniform float coverage = 0.55;  // more → more clouds
uniform float crisp = 3.0;      // edge hardness
uniform float freq = 3.0;
uniform float wind_speed = 0.2; // rotation speed (deg/sec feel)
uniform float density = 0.8;

uniform float light_angle = 0.6; // must match planet/analyzer
uniform float brightness = 1.15;

float hash(vec3 p){
    return fract(sin(dot(p, vec3(12.9898,78.233,37.719))) * 43758.5453 + seed);
}

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
    float a=0.6, s=0.0;
    for (int i=0;i<5;i++){ s+=a*noise3(p); p*=2.0; a*=0.5; }
    return s;
}

void fragment(){
    vec2 uv = UV * 2.0 - 1.0;
    float r = length(uv);
    if (r > 1.0) { discard; }

    float z = sqrt(max(0.0, 1.0 - r*r));
    vec3 n = normalize(vec3(uv, z));

    // rotate noise around Y over time
    float ang = radians(TIME * wind_speed * 60.0);
    float ct = cos(ang), st = sin(ang);
    mat3 R = mat3(vec3(ct,0,st), vec3(0,1,0), vec3(-st,0,ct));
    vec3 q = R * n;

    float base = fbm(q * freq);
    float m = pow(smoothstep(coverage, 1.0, base), crisp);

    // light weighting so night side is dim
    vec3 L = normalize(vec3(cos(light_angle), 0.25, sin(light_angle)));
    float day = clamp(dot(n, L) * 0.5 + 0.5, 0.0, 1.0);

    float limb = smoothstep(1.0, 0.7, r);
    float alpha = m * density * limb * day;

    COLOR = vec4(vec3(brightness), alpha);
}
