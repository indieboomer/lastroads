global uniform vec4 road_fog_colour : source_color;
global uniform float road_fog_density;
global uniform float road_daylight;
global uniform float road_flash;

vec3 road_atmosphere(vec3 colour, vec3 at, vec3 eye) {
	// Fragment distance, with a clear near field. No per-vertex light/fog bands.
	float distance_to_eye=length(at-eye);
	float amount=1.0-exp(-max(distance_to_eye-35.0,0.0)*road_fog_density);
	return mix(colour,road_fog_colour.rgb,clamp(amount,0.0,.9))+road_flash*.18;
}
