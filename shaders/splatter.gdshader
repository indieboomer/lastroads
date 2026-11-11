shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;
uniform vec4 ink : source_color = vec4(0.35,0.025,0.04,1.0);
uniform float variation = 0.0;
uniform float opacity = 1.0;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
void fragment() {
	vec2 p = (UV-0.5)*2.0;
	float angle = atan(p.y,p.x);
	float radius = 0.72+sin(angle*7.0+variation)*0.12+sin(angle*13.0-variation)*0.075;
	float r=length(p);
	float edge = 1.0-smoothstep(radius-0.09,radius,r);
	float droplets=step(.86,hash(floor(UV*21.0)+variation))*smoothstep(.48,.65,r)*(1.-smoothstep(.83,.98,r));
	edge=max(edge,droplets);
	float brush = mix(0.72,1.0,hash(floor(UV*95.0)));
	ALBEDO = ink.rgb*brush;
	ALPHA = edge*0.88*opacity;
}
