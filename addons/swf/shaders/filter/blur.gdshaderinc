group_uniforms Glow;

uniform float blur_x;
uniform float blur_y;

struct Blur {
	float full_size;
	float m;
	float m2;
	float first_weight;
	float last_offset;
	float last_weight;
};

//int num_passes(){
	//return (flags & (31 << 3)) >> 3;
//}

Blur blur_direction(){

	bool horizontal = true;
	float strength = horizontal ? blur_x : blur_y;

	float full_size = strength < 255.0 ? strength : 255.0;
	//if (full_size <= 1.0) {
		//continue;
	//}
	float radius = (full_size - 1.0) / 2.0;
	float m = ceil(radius) - 1.0;
	float m2 = m * 2.0;
	float alpha = floor(((radius - m) * 255.0)) / 255.0;
	float last_offset = 1.0 / ((1.0 / alpha) + 1.0);
	float last_weight = alpha + 1.0;		
	
	return Blur(full_size, m,m2, alpha, last_offset, last_weight);
}

vec4 blur(Blur blur, vec2 blur_uv) {
		//vec4 total = vec4(0.0,0.0,0.0,0.0);
		//total += texture(TEXTURE, blur_uv - blur.direction) * blur.first_weight;
		//vec4 center;
		//for (float i = 0.5; i < m2; i+=2.0) {
			//center += texture(TEXTURE, blur_uv + direction * i);
		//}
		//total += center * 2.0;
		//vec2 last_location = blur_uv + direction * (m2 + last_offset);
		//total += texture(TEXTURE, last_location) * last_weight;
		//vec4 result = total / full_size;
		return vec4(1.0,1.0,1.0,1.0);
}