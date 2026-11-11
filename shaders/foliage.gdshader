shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
uniform sampler2D image : source_color, filter_linear_mipmap_anisotropic;
uniform float amplitude = 0.03;
uniform float phase = 0.0;
uniform float crown_start = 0.4;
uniform bool face_camera = true;
uniform float max_distance = 350.0;
global uniform float road_time;
global uniform float road_wind;
global uniform vec3 road_scream_position;
global uniform float road_scream_strength;
#include "res://shaders/road_fog.gdshaderinc"
varying vec4 tint;
varying vec3 world_at;
void vertex() {
	vec3 scale = vec3(length(MODEL_MATRIX[0].xyz),length(MODEL_MATRIX[1].xyz),length(MODEL_MATRIX[2].xyz));
	vec3 right = normalize(vec3(INV_VIEW_MATRIX[0].x,0.0,INV_VIEW_MATRIX[0].z));
	vec3 forward = cross(right,vec3(0.0,1.0,0.0));
	mat4 model = face_camera ? mat4(vec4(right*scale.x,0.0),vec4(0.0,scale.y,0.0,0.0),vec4(forward*scale.z,0.0),MODEL_MATRIX[3]) : MODEL_MATRIX;
	MODELVIEW_MATRIX = VIEW_MATRIX * model;
	float crown = smoothstep(crown_start,1.0,1.0-UV.y);
	float local_phase=phase+MODEL_MATRIX[3].x*.2+MODEL_MATRIX[3].z*.13;
	float gust=0.65+0.35*sin(road_time*.73+local_phase*.3);
	VERTEX.x += (sin(road_time*1.65+local_phase+VERTEX.y*.25)+.35*sin(road_time*3.3+local_phase))*amplitude*crown*crown*road_wind*2.8*gust;
	float tremble=road_scream_strength*(1.0-smoothstep(5.0,15.0,distance(MODEL_MATRIX[3].xz,road_scream_position.xz)));
	VERTEX.x+=sin(road_time*46.0+local_phase)*.035*crown*tremble;
	world_at = (model*vec4(VERTEX,1.0)).xyz;
	tint = COLOR;
}
void fragment() {
	if(length(world_at-INV_VIEW_MATRIX[3].xyz)>max_distance) discard;
	vec4 paint = texture(image,UV)*tint;
	ALBEDO = road_atmosphere(paint.rgb*mix(0.32,0.88,road_daylight),world_at,INV_VIEW_MATRIX[3].xyz);
	ALPHA = paint.a;
	ALPHA_SCISSOR_THRESHOLD = 0.3;
	ROUGHNESS = 1.0;
	if (!FRONT_FACING) { NORMAL = -NORMAL; }
}
