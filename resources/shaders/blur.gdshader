shader_type canvas_item;

uniform float blur_amount : hint_range(0.0, 10.0) = 4.0;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

void fragment() {
    vec2 uv = SCREEN_UV;
    vec4 color = vec4(0.0);
    float total = 0.0;
    float spread = blur_amount / 1000.0;

    for (float x = -2.0; x <= 2.0; x += 1.0) {
        for (float y = -2.0; y <= 2.0; y += 1.0) {
            color += texture(screen_texture, uv + vec2(x, y) * spread);
            total += 1.0;
        }
    }
    COLOR = color / total;
}