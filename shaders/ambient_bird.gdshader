shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
#include "res://shaders/road_fog.gdshaderinc"
uniform float life_time=0.;
varying vec3 world_at;
varying vec3 ink;
void vertex(){
	float flying=INSTANCE_CUSTOM.g;
	if(UV.y>0.){VERTEX.x*=mix(.25,1.,flying);}
	VERTEX.y+=UV.y*(sin(life_time*12.+INSTANCE_CUSTOM.r*6.283)*.28*flying-.06*(1.-flying));
	world_at=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;
	ink=COLOR.rgb*INSTANCE_CUSTOM.b;
}
void fragment(){ALBEDO=road_atmosphere(ink*mix(.5,1.,road_daylight),world_at,INV_VIEW_MATRIX[3].xyz);}
