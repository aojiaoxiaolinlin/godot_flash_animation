shader_type canvas_item;

#include "res://addons/swf/shaders/filter/color_matrix.gdshaderinc"
#include "res://addons/swf/shaders/filter/glow.gdshaderinc"
#include "res://addons/swf/shaders/filter/blur.gdshaderinc"
#include "res://addons/swf/shaders/color_transform.gdshaderinc"

uniform int filter_mode = 1;
uniform mat4 world_matrix;

varying vec2 blur_uv;

void vertex() {
	// Called for every vertex the material is visible on.
	VERTEX = (world_matrix * vec4(VERTEX,0.0,1.0)).xy;

}

void fragment() {
	vec4 blur_color;
	if ((filter_mode & 1) != 0) {
		//Blur blur = blur_direction();
		//vec2 direction = vec2(TEXTURE_PIXEL_SIZE.x,0.0);
		//blur_uv = UV - direction * blur.m;
		//vec4 total = vec4(0.0,0.0,0.0,0.0);
		//total += texture(TEXTURE, blur_uv - direction) * blur.first_weight;
		//vec4 center;
		//for (float i = 0.5; i < blur.m2; i+=2.0) {
			//center += texture(TEXTURE, blur_uv + direction * i);
		//}
		//total += center * 2.0;
		//vec2 last_location = blur_uv + direction * (blur.m2 + blur.last_offset);
		//total += texture(TEXTURE, last_location) * blur.last_weight;
		//vec4 result = total / blur.full_size;
		////blur_color = floor(result * 255.0) / 255.0;
		//COLOR = blur_color;
	}
	if ((filter_mode & 2) != 0) {
		//bool inner = glow_inner > 0;
		//bool knockout = glow_knockout > 0;
		//bool composite_source = glow_composite_source > 0;
//
		//vec4 dest = texture(TEXTURE, UV);
//
		//vec4 result = vec4(glow_color.r, glow_color.g, glow_color.b, 1.0);
		//if (inner) {
			//vec4 alpha = glow_color.a * clamp((1.0 - blur_color) * glow_strength, 0.0, 1.0);
			//if (knockout) {
				//result = result * alpha * dest.a;
			//}else if (composite_source) {
				//result = result * alpha * dest.a + dest * (1.0 - alpha);
			//} else {
				//result = result * alpha * dest.a;
			//}
		//} else {
			//vec4 alpha = glow_color.a * clamp(blur_color * glow_strength, 0.0, 1.0);
			//if (knockout) {
				//result = result * alpha * (1.0 - dest.a);
			//}else if (composite_source) {
				//result = result * alpha * (1.0 - dest.a) + dest;
			//}else {
				//result = result * alpha;
			//}
		//}
		//COLOR = result;
	}
	COLOR = COLOR * mult_color + add_color;
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
