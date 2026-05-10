shader_type canvas_item;

uniform vec4 color1 : source_color = vec4(0.0, 0.0, 0.0, 0.0);
uniform vec4 color2 : source_color = vec4(0.0, 0.0, 0.0, 0.75);
uniform vec4 color3 : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float stop1 = 0.25;
uniform float stop2 = 0.70;
uniform float stop3 = 1.0;
uniform float radius = 1.2;

void fragment() {
    vec2 center = vec2(0.5, 0.5);
    float dist = distance(UV, center) * 2.0 / radius;

    vec4 final_color = color1;
    if (dist > stop1 && dist <= stop2) {
        final_color = mix(color1, color2, smoothstep(stop1, stop2, dist));
    } else if (dist > stop2 && dist <= stop3) {
        final_color = mix(color2, color3, smoothstep(stop2, stop3, dist));
    } else if (dist > stop3) {
        final_color = color3;
    }

    COLOR = final_color;
}
