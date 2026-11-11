shader_type spatial;
render_mode unshaded, fog_disabled, blend_add, cull_disabled, depth_draw_never, depth_test_disabled;

uniform sampler2D scene_depth : hint_depth_texture, repeat_disable, filter_nearest;
uniform vec2 sun_screen = vec2(.5,.3);
uniform vec4 sun_tint : source_color = vec4(1.,.7,.4,1.);
uniform float strength = 0.;
uniform float sky_distance = 310.;
uniform float aspect_ratio = 1.7778;

float view_depth(float depth, vec2 uv, mat4 inv_projection) {
	#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
		vec3 ndc = vec3(uv,depth)*2.-1.;
	#else
		vec3 ndc = vec3(uv*2.-1.,depth);
	#endif
	vec4 view = inv_projection*vec4(ndc,1.);
	return abs(view.z/max(abs(view.w),.000001));
}

void vertex() {
	POSITION = vec4(VERTEX.xy,1.,1.);
}

void fragment() {
	vec2 step_uv = (sun_screen-SCREEN_UV)/32.;
	vec2 sample_uv = SCREEN_UV;
	float sum = 0.;
	float weight = 1.;
	// Sky openings form the emitter mask: branches and solid roofs block it.
	for (int i=0;i<32;i++) {
		sample_uv += step_uv;
		if (sample_uv.x>=0. && sample_uv.x<=1. && sample_uv.y>=0. && sample_uv.y<=1.) {
			float sky = smoothstep(sky_distance*.975,sky_distance*.995,view_depth(textureLod(scene_depth,sample_uv,0.).r,sample_uv,INV_PROJECTION_MATRIX));
			vec2 radius = (sample_uv-sun_screen)*vec2(aspect_ratio,1.);
			float emitter = exp(-dot(radius,radius)*35.);
			sum += sky*emitter*weight;
		}
		weight *= .972;
	}
	float depth = view_depth(textureLod(scene_depth,SCREEN_UV,0.).r,SCREEN_UV,INV_PROJECTION_MATRIX);
	float foreground = smoothstep(1.2,9.,depth);
	float scattering = sum/32.*foreground;
	ALBEDO = sun_tint.rgb*scattering*strength*.85;
	ALPHA = 1.;
}
