shader_type canvas_item;

uniform float strength : hint_range(0.0, 2.0) = 1.2;
uniform vec4 color : source_color = vec4(0.4, 0.0, 0.0, 1.0);

void fragment() {
    vec2 uv = SCREEN_UV;
    vec2 center = uv - 0.5;
    float vignette = 1.0 - dot(center, center) * strength * 2.5;
    vignette = clamp(vignette, 0.0, 1.0);
    COLOR = vec4(color.rgb, (1.0 - vignette) * 0.5);
}