shader_type spatial;
render_mode unshaded, cull_disabled, depth_prepass_alpha;
uniform vec4 ink : source_color = vec4(.8,.008,.025,1.0);
varying vec4 tint;
void vertex(){
	vec3 up=normalize(MODEL_MATRIX[1].xyz);
	vec3 toward=normalize(INV_VIEW_MATRIX[3].xyz-MODEL_MATRIX[3].xyz);
	vec3 right=normalize(cross(up,toward));
	MODELVIEW_MATRIX=VIEW_MATRIX*mat4(vec4(right*length(MODEL_MATRIX[0].xyz),0.),vec4(up*length(MODEL_MATRIX[1].xyz),0.),vec4(toward*length(MODEL_MATRIX[2].xyz),0.),MODEL_MATRIX[3]);
	tint=COLOR;
}
void fragment(){
	vec2 p=UV;
	float curved=.5+sin(p.y*6.0)*.09;
	float width=.025+pow(clamp(p.y,0.,1.),1.8)*.32;
	float stream=1.-smoothstep(width*.65,width,abs(p.x-curved));
	float end=1.-smoothstep(.0,.12,abs(p.y-.80)-.12);
	float head=1.-smoothstep(.17,.23,length((p-vec2(.43,.77))*vec2(1.,.75)));
	float alpha=max(stream*(1.-smoothstep(.83,1.,p.y)),head)*smoothstep(0.,.10,p.y);
	ALBEDO=ink.rgb*mix(.7,1.25,end)*tint.rgb;
	ALPHA=alpha*tint.a;
}
