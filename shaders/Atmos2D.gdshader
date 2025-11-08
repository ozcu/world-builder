shader_type canvas_item;
render_mode unshaded, blend_add;

uniform vec3 color_rayleigh = vec3(0.55, 0.75, 1.0);
uniform vec3 color_mie      = vec3(1.0, 0.92, 0.85);
uniform float intensity      = 0.7;
uniform float mie_strength   = 0.25;
uniform float rim_power      = 3.0;   // higher → thinner rim
uniform float day_side_bias  = 0.4;   // how much we restrict to lit side
uniform float light_angle    = 0.6;

void fragment(){
    vec2 uv = UV * 2.0 - 1.0;
    float r = length(uv);
if (r > 1.0) { discard; }  // outside the disc → no pixel drawn


    float z = sqrt(max(0.0, 1.0 - r*r));
    vec3 n = normalize(vec3(uv, z));
    vec3 L = normalize(vec3(cos(light_angle), 0.2, sin(light_angle)));

    float rim = pow(1.0 - z, rim_power);   // strong near edge (low z)
    float day = clamp(dot(n, L) * 0.5 + 0.5, 0.0, 1.0);
    day = smoothstep(day_side_bias, 1.0, day);

    vec3 col = color_rayleigh * rim * day
             + color_mie * pow(rim, 0.5) * mie_strength * day;

    COLOR = vec4(col * intensity, length(col));
}
