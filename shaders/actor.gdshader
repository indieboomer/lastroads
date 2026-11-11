shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
uniform sampler2D image : source_color, filter_linear, repeat_disable;
#include "res://shaders/road_fog.gdshaderinc"
varying vec3 world_at;
varying vec4 tint;
void vertex() {
	vec3 scale=vec3(length(MODEL_MATRIX[0].xyz),length(MODEL_MATRIX[1].xyz),length(MODEL_MATRIX[2].xyz));
	vec3 right=normalize(vec3(INV_VIEW_MATRIX[0].x,0.,INV_VIEW_MATRIX[0].z));
	vec3 forward=cross(right,vec3(0.,1.,0.));
	// Keep the small combat lean while the card faces the player.
	vec3 up=vec3(0.,1.,0.);
	float lean=atan(MODEL_MATRIX[0].y,length(MODEL_MATRIX[0].xz));
	vec3 leaned_right=right*cos(lean)+up*sin(lean);
	vec3 leaned_up=up*cos(lean)-right*sin(lean);
	mat4 model=mat4(vec4(leaned_right*scale.x,0.),vec4(leaned_up*scale.y,0.),vec4(forward*scale.z,0.),MODEL_MATRIX[3]);
	MODELVIEW_MATRIX=VIEW_MATRIX*model;
	world_at=(model*vec4(VERTEX,1.)).xyz;
	tint=COLOR;
}
void fragment() {
	vec4 paint=textureLod(image,UV,0.0)*tint;
	vec3 colour=paint.rgb*mix(.50,1.0,road_daylight);
	ALBEDO=road_atmosphere(colour,world_at,INV_VIEW_MATRIX[3].xyz);
	ALPHA=paint.a;
	ALPHA_SCISSOR_THRESHOLD=.3;
}
