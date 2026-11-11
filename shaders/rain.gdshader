shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
void vertex(){
	// Only the thin axis faces the observer. The long axis follows world velocity.
	vec3 up=normalize(MODEL_MATRIX[1].xyz);
	vec3 toward=normalize(INV_VIEW_MATRIX[3].xyz-MODEL_MATRIX[3].xyz);
	vec3 side=cross(up,toward);
	if(length(side)<0.001){side=INV_VIEW_MATRIX[0].xyz;}
	side=normalize(side);
	vec3 normal=normalize(cross(side,up));
	MODELVIEW_MATRIX=VIEW_MATRIX*mat4(vec4(side*length(MODEL_MATRIX[0].xyz),0.),vec4(up*length(MODEL_MATRIX[1].xyz),0.),vec4(normal,0.),MODEL_MATRIX[3]);
}
void fragment(){
	ALBEDO=vec3(.57,.72,.78);
	ALPHA=.48*(1.-smoothstep(.15,.5,abs(UV.x-.5)))*sin(UV.y*3.14159);
}
