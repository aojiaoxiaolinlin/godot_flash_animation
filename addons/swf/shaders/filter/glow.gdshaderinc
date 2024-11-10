group_uniforms Glow;

uniform vec4 glow_color;
uniform float glow_strength;
uniform int glow_inner;
uniform int glow_knockout;
uniform int glow_composite_source;

vec4 glow(vec4 src){
	return vec4(1,1,1,1);
}