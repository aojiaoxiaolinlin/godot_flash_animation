shader_type canvas_item;
uniform float blur_x:hint_range(0, 100) = 1;
uniform float blur_y:hint_range(0, 100) = 1;
uniform float blur:hint_range(0, 100) = 1;
uniform int passes : hint_range(1, 10) = 2;  // 迭代次数

varying vec2 blur_uv;

void vertex() {
	// Called for every vertex the material is visible on.
	
}

void fragment() {
	vec4 color = vec4(0.0);
	ivec2 size = textureSize(TEXTURE, 0);

	// Called for every pixel the material is visible on.
	// 水平模糊
    for (float i = -blur; i <= blur; i++) {
        vec2 offset = vec2(i, 0) / vec2(size);  // 计算偏移量
        color += texture(TEXTURE, UV + offset) * (1.0 / (2.0 * blur + 1.0));  // 累加纹理值
    }

    // 垂直模糊
    vec4 vert_color = vec4(0.0);
    for (float j = -blur; j <= blur; j++) {
        vec2 offset = vec2(0.0, j) / vec2(size);  // 计算偏移量
        vert_color += texture(TEXTURE,  UV + offset) * (1.0 / (2.0 * blur + 1.0));  // 累加纹理值
    } 
	vec4 src = texture(TEXTURE, UV);
	COLOR = max(color,vert_color);
	//vec4 res = max(color,vert_color);
	//COLOR = max(res,src);
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
