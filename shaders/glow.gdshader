shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;
uniform vec4 color : source_color = vec4(1.0,0.55,0.12,1.0);
uniform float occlusion = 1.0;
global uniform float road_time;
void vertex() {
	// Match upright actor cards. A fully tilted glow plane sliced through them
	// when looking down; put the parallel glow just behind its source instead.
	vec3 right=normalize(vec3(INV_VIEW_MATRIX[0].x,0.,INV_VIEW_MATRIX[0].z));
	vec3 up=vec3(0.,1.,0.);
	vec3 forward=cross(right,up);
	vec3 at=MODEL_MATRIX[3].xyz;
	at+=normalize(at-INV_VIEW_MATRIX[3].xyz)*.06;
	mat4 model=mat4(vec4(right*length(MODEL_MATRIX[0].xyz),0.),vec4(up*length(MODEL_MATRIX[1].xyz),0.),vec4(forward,0.),vec4(at,1.));
	MODELVIEW_MATRIX=VIEW_MATRIX*model;
}
void fragment() {
	float d = length(UV-0.5)*2.0;
	float a = pow(max(0.0,1.0-d),3.0);
	ALBEDO = color.rgb * (1.0+0.08*sin(road_time*7.0));
	ALPHA = a*color.a*occlusion;
}
