shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled, depth_prepass_alpha;
uniform sampler2D image : source_color, filter_linear, repeat_disable;
uniform float fade = 1.0;
#include "res://shaders/road_fog.gdshaderinc"
varying vec3 world_at;
void vertex() {
	vec3 scale = vec3(length(MODEL_MATRIX[0].xyz),length(MODEL_MATRIX[1].xyz),length(MODEL_MATRIX[2].xyz));
	vec3 right = normalize(vec3(INV_VIEW_MATRIX[0].x,0.,INV_VIEW_MATRIX[0].z));
	vec3 forward = cross(right,vec3(0.,1.,0.));
	mat4 model = mat4(vec4(right*scale.x,0.),vec4(0.,scale.y,0.,0.),vec4(forward*scale.z,0.),MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = VIEW_MATRIX*model;
	world_at = (model*vec4(VERTEX,1.)).xyz;
}
void fragment() {
	vec4 paint = textureLod(image,UV,0.0);
	if(paint.a<.3) discard;
	ALBEDO = road_atmosphere(paint.rgb*mix(.50,1.0,road_daylight),world_at,INV_VIEW_MATRIX[3].xyz);
	ALPHA = paint.a*fade;
}
