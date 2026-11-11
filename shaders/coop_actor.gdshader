shader_type spatial;
render_mode unshaded, cull_disabled, depth_prepass_alpha;
uniform sampler2D image : source_color, filter_linear_mipmap;
uniform vec4 recognition_color : source_color = vec4(0.75,0.15,0.1,1.0);
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], vec4(0.0,1.0,0.0,0.0), INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}
void fragment() {
	vec4 pixel = texture(image,UV);
	float dye = smoothstep(0.02,0.14,min(pixel.g,pixel.b)-pixel.r) * smoothstep(0.1,0.25,pixel.g+pixel.b);
	vec3 cloth = recognition_color.rgb * clamp(dot(pixel.rgb,vec3(0.2126,0.7152,0.0722))*1.8,0.18,1.35);
	ALBEDO = mix(pixel.rgb,cloth,dye);
	ALPHA = pixel.a;
	ALPHA_SCISSOR_THRESHOLD = 0.4;
}
