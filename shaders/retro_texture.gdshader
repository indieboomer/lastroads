shader_type canvas_item;
render_mode unshaded;
#include "res://shaders/retro_common.gdshaderinc"
uniform float image_aspect = 1.7777778;
uniform vec4 item_tint = vec4(1.0);
uniform vec4 uv_rect = vec4(0.0,0.0,1.0,1.0);
void fragment() {
	vec2 grid=max(floor(vec2(virtual_height*image_aspect,virtual_height)),vec2(1.));
	vec2 local_uv=(UV-uv_rect.xy)/uv_rect.zw;
	vec2 pixel=clamp(floor(local_uv*grid),vec2(0.),grid-1.);
	vec2 uv=retro_enabled?uv_rect.xy+(pixel+.5)/grid*uv_rect.zw:UV;
	vec4 colour=texture(TEXTURE,uv);
	if(retro_enabled) colour.rgb=retro_colour(colour.rgb,pixel,FRAGCOORD.xy);
	COLOR=colour*item_tint;
}
