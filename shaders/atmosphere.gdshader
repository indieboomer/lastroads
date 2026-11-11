shader_type canvas_item;
uniform float hurt = 0.0;
uniform float night = 0.0;
void fragment() {
	vec2 p = UV*2.0-1.0;
	float edge = smoothstep(0.35,1.35,length(p));
	float grain = fract(sin(dot(FRAGCOORD.xy,vec2(12.9898,78.233)))*43758.5453);
	vec3 shade = mix(vec3(0.015,0.035,0.035),vec3(0.4,0.025,0.01),hurt);
	COLOR = vec4(shade,edge*(0.30+night*0.13)+hurt*0.18+(grain-0.5)*0.025);
}
