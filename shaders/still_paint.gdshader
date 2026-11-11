shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
uniform sampler2D image : source_color, filter_linear, repeat_disable;
#include "res://shaders/road_fog.gdshaderinc"
varying vec3 world_at;
void vertex(){world_at=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;}
void fragment(){
	vec4 paint=textureLod(image,UV,0.0);
	ALBEDO=road_atmosphere(paint.rgb*mix(.50,1.0,road_daylight),world_at,INV_VIEW_MATRIX[3].xyz);
	ALPHA=paint.a;
	ALPHA_SCISSOR_THRESHOLD=.3;
}
