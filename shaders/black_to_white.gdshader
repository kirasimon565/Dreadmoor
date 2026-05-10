shader_type canvas_item;

uniform float opacity : hint_range(0.0, 1.0) = 0.88;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    // If the image is black (RGB ~ 0) with alpha, make it white with alpha
    // We'll replace the rgb with white and multiply alpha
    COLOR = vec4(1.0, 1.0, 1.0, tex_color.a * opacity);
}
