shader_type canvas_item;
#include "res://addons/swf/shaders/color_transform.gdshaderinc"


void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec4 res = texture(TEXTURE, UV);
	if (COLOR.a > 0.0) {
		COLOR = COLOR * mult_color + add_color;
	}
	//COLOR = mult_color;
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
