shader_type canvas_item;

uniform vec4 start_color : source_color = vec4(0.24, 0.85, 0.95, 0.15);
uniform vec4 end_color : source_color = vec4(0.0, 0.0, 0.0, 0.0);

void fragment() {
    COLOR = mix(start_color, end_color, UV.x);
}
