shader_type canvas_item;
uniform vec4 recognition_color : source_color = vec4(0.75,0.15,0.1,1.0);
void fragment() {
	vec4 pixel = texture(TEXTURE,UV);
	float dye = smoothstep(0.02,0.14,min(pixel.g,pixel.b)-pixel.r);
	vec3 cloth = recognition_color.rgb * clamp(dot(pixel.rgb,vec3(0.2126,0.7152,0.0722))*1.8,0.18,1.35);
	COLOR = vec4(mix(pixel.rgb,cloth,dye),pixel.a);
}
