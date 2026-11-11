shader_type spatial;
render_mode cull_disabled;
uniform sampler2D atlas : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D back_atlas : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool use_back_atlas = false;
uniform vec2 tile = vec2(0.0);
uniform vec2 back_tile = vec2(-1.0);
uniform bool atlas_mode = true;
uniform float scale = 0.35;
uniform vec4 tint : source_color = vec4(1.0);
uniform bool limewash = false;
uniform float foundation_y = 0.0;
global uniform float road_rain;
varying vec3 world_pos;
varying vec3 world_normal;
float hash21(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float plaster_noise(vec2 p) {
	vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
	return mix(mix(hash21(i),hash21(i+vec2(1,0)),f.x),mix(hash21(i+vec2(0,1)),hash21(i+vec2(1,1)),f.x),f.y);
}
void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL,0.0)).xyz);
}
void fragment() {
	if (!FRONT_FACING) { NORMAL = -NORMAL; }
	vec3 weights = pow(abs(world_normal),vec3(6.0));
	weights /= max(weights.x+weights.y+weights.z,0.001);
	vec2 uvx = fract(world_pos.zy*scale);
	vec2 uvy = fract(world_pos.xz*scale);
	vec2 uvz = fract(world_pos.xy*scale);
	if(atlas_mode) {
		vec2 selected = (!FRONT_FACING && back_tile.x>=0.0) ? back_tile : tile;
		uvx = (uvx*0.988+0.006+selected)*0.5;
		uvy = (uvy*0.988+0.006+selected)*0.5;
		uvz = (uvz*0.988+0.006+selected)*0.5;
	}
	vec3 tex = texture(atlas,uvx).rgb*weights.x + texture(atlas,uvy).rgb*weights.y + texture(atlas,uvz).rgb*weights.z;
	if (!FRONT_FACING && use_back_atlas) {
		tex=texture(back_atlas,uvx).rgb*weights.x+texture(back_atlas,uvy).rgb*weights.y+texture(back_atlas,uvz).rgb*weights.z;
	}
	ALBEDO = tex*tint.rgb*(1.0-road_rain*.12);
	if (limewash) {
		vec2 face = mix(world_pos.xy,world_pos.zy,weights.x);
		float patches=plaster_noise(face*0.75);
		float fine=plaster_noise(face*17.0);
		float luma=dot(tex,vec3(0.299,0.587,0.114));
		vec3 washed=tint.rgb*(0.55+luma*0.48)*(0.88+patches*0.20+fine*0.06);
		float damp=(1.0-smoothstep(0.5,1.65,world_pos.y-foundation_y))*(0.10+patches*0.18);
		ALBEDO=mix(washed,washed*vec3(0.47,0.53,0.42),damp)*(1.0-road_rain*.08);
		float wear=smoothstep(0.64,0.73,patches)*(1.0-smoothstep(0.85,1.8,world_pos.y-foundation_y));
		vec2 brick_offset=vec2(0.0,0.5);
		vec3 brick=texture(back_atlas,uvx+brick_offset).rgb*weights.x+texture(back_atlas,uvy+brick_offset).rgb*weights.y+texture(back_atlas,uvz+brick_offset).rgb*weights.z;
		ALBEDO=mix(ALBEDO,brick*0.82,wear);
	}
	ROUGHNESS = 0.95-road_rain*.30;
}
