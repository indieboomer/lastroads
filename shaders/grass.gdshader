shader_type spatial;
render_mode unshaded,cull_disabled,fog_disabled;
#include "res://shaders/road_fog.gdshaderinc"
uniform sampler2D image : source_color, filter_linear_mipmap;
varying float variant;
global uniform float road_time;
global uniform float road_wind;
varying vec3 world_at;
varying vec3 ink;
void vertex(){
	vec3 base=MODEL_MATRIX[3].xyz;
	float distance_to_eye=distance(base,INV_VIEW_MATRIX[3].xyz);
	VERTEX*=1.-smoothstep(58.,76.,distance_to_eye);
	variant=floor(fract(sin(dot(base.xz,vec2(12.9898,78.233)))*43758.5453)*4.);
	float crown=(1.-UV.y)*(1.-UV.y);
	VERTEX.x+=sin(road_time*1.8+base.x*.47+base.z*.31)*.14*road_wind*crown;
	VERTEX.z+=cos(road_time*1.3+base.x*.27)*.07*road_wind*crown;
	world_at=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;
	ink=COLOR.rgb;
}
void fragment(){vec4 paint=texture(image,vec2((UV.x+variant)*.25,UV.y)); ALBEDO=road_atmosphere(paint.rgb*mix(.38,1.,road_daylight),world_at,INV_VIEW_MATRIX[3].xyz); ALPHA=paint.a; ALPHA_SCISSOR_THRESHOLD=.5;}
