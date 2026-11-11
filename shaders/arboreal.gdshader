shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
uniform bool leafy = true;
global uniform float road_time;
global uniform float road_wind;
global uniform vec3 road_scream_position;
global uniform float road_scream_strength;
#include "res://shaders/road_fog.gdshaderinc"
varying vec3 world_at;
varying vec3 world_normal;
varying vec4 paint;
void vertex() {
	world_at=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;
	if(leafy) VERTEX.x+=(sin(road_time*1.5+world_at.x*.13+world_at.z*.17)+.3*sin(road_time*3.1+world_at.z))*.013*road_wind;
	if(leafy) VERTEX.x+=sin(road_time*46.0+world_at.z)*.045*road_scream_strength*(1.0-smoothstep(5.0,15.0,distance(world_at.xz,road_scream_position.xz)));
	world_normal=normalize((MODEL_MATRIX*vec4(NORMAL,0.)).xyz);
	paint=COLOR;
}
void fragment() {
	float light=.66+.34*max(dot(normalize(world_normal),normalize(vec3(-.4,.8,.3))),0.);
	float fleck=fract(sin(dot(floor(world_at*(leafy?10.:22.)),vec3(12.9898,78.233,37.719)))*43758.5453);
	float texture_detail=leafy?mix(.86,1.10,fleck):(.78+.22*sin(world_at.y*1.3+sin(world_at.x*17.)+world_at.z*25.));
	vec3 colour=paint.rgb*light*texture_detail*mix(.30,1.0,road_daylight);
	ALBEDO=road_atmosphere(colour,world_at,INV_VIEW_MATRIX[3].xyz);
}
