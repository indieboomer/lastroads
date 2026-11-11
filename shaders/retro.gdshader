shader_type canvas_item;
render_mode unshaded, blend_disabled;
uniform sampler2D screen_image : hint_screen_texture, repeat_disable, filter_nearest;
#include "res://shaders/retro_common.gdshaderinc"
void fragment() {
	vec2 dimensions=1.0/SCREEN_PIXEL_SIZE;
	// Whole physical pixels and a centred grid prevent uneven pixel widths.
	float step_size=max(1.0,floor(dimensions.y/virtual_height+.5));
	vec2 grid=floor(dimensions/step_size);
	vec2 origin=(dimensions-grid*step_size)*.5;
	vec2 pixel=floor((SCREEN_UV*dimensions-origin)/step_size);
	vec2 uv=clamp((pixel*step_size+origin+step_size*.5)/dimensions,SCREEN_PIXEL_SIZE*.5,vec2(1.)-SCREEN_PIXEL_SIZE*.5);
	vec3 colour=textureLod(screen_image,retro_enabled?uv:SCREEN_UV,0.).rgb;
	COLOR=vec4(retro_enabled?retro_colour(colour,pixel,FRAGCOORD.xy):colour,1.);
}
