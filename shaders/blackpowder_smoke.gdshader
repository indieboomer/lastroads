shader_type canvas_item;
render_mode unshaded;
uniform vec2 muzzle = vec2(730.,320.);
uniform vec2 pan = vec2(1035.,460.);
uniform float age = 0.;
uniform float lifetime = 4.;
uniform float strength = 1.;
uniform float ignition = 0.;
uniform vec2 fire_muzzle = vec2(730.,320.);
uniform vec2 fire_pan = vec2(1035.,460.);

float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
	vec2 i=floor(p), f=fract(p); f=f*f*(3.-2.*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1)),f.x),f.y);
}
float fbm(vec2 p) {
	float v=0., a=.55;
	for(int i=0;i<5;i++) { v+=a*noise(p); p=mat2(vec2(.8,.6),vec2(-.6,.8))*p*2.07+vec2(13.7,9.2); a*=.49; }
	return v;
}
vec2 cloud(vec2 pixel,vec2 source,float scale,float seed) {
	float t=max(age,0.);
	float expansion=1.-exp(-t*5.);
	vec2 radius=vec2(22.+expansion*115.+t*26.,18.+expansion*85.+t*34.)*scale*strength;
	vec2 center=source+vec2(-t*(28.+seed),-t*61.-expansion*32.)*strength;
	vec2 q=(pixel-center)/radius;
	if(dot(q,q)>5.) { return vec2(0.); }
	// Domain-warped eddies break the edge into billows and stretch into rising wisps.
	vec2 flow=q*2.1+vec2(seed,-t*.48);
	vec2 warp=vec2(fbm(flow+vec2(t*.18,0)),fbm(flow+vec2(5.2,8.7)))-.5;
	vec2 curled=q+warp*.9;
	float detail=fbm(flow+warp*2.8);
	float envelope=1.-smoothstep(.18,1.35,length(curled));
	float density=envelope*smoothstep(.19,.72,detail)*1.9;
	float fade=smoothstep(0.,.07,t)*(1.-smoothstep(lifetime*.38,lifetime,t));
	float alpha=(1.-exp(-density*2.4))*fade;
	return vec2(alpha,detail);
}
vec4 flame(vec2 pixel,vec2 source,vec2 extent,float seed) {
	vec2 q=(pixel-source)/extent;
	float n=fbm(q*3.7+vec2(seed,age*-18.));
	float shape=length(q+vec2(n-.5,(n-.5)*.45));
	float density=(1.-smoothstep(.06,.95,shape))*ignition;
	float core=1.-smoothstep(.05,.46,shape);
	vec3 heat=mix(vec3(1.,.22,.025),vec3(1.,.82,.30),core);
	heat=mix(heat,vec3(1.,.98,.81),core*core);
	return vec4(heat,density);
}
void fragment() {
	vec2 pixel=UV*vec2(1280.,720.);
	vec2 barrel=cloud(pixel,muzzle,1.,1.7);
	vec2 primer=cloud(pixel,pan,.65,8.3);
	float alpha=1.-(1.-barrel.x*.9)*(1.-primer.x*.88);
	float detail=max(barrel.y,primer.y);
	// Dense soot core, charcoal folds, warm grey thin edges; never flat black discs.
	vec3 soot=mix(vec3(.032,.029,.025),vec3(.27,.255,.23),smoothstep(.27,.79,detail));
	soot=mix(soot,vec3(.32,.31,.285),.22*(1.-alpha));
	vec4 muzzle_fire=vec4(0.);
	vec4 pan_fire=vec4(0.);
	if(ignition>0.) {
		muzzle_fire=flame(pixel,fire_muzzle+vec2(-12.,-14.)*strength,vec2(62.,48.)*strength,2.3);
		pan_fire=flame(pixel,fire_pan+vec2(0.,-20.)*strength,vec2(27.,53.)*strength,7.9);
	}
	float fire_alpha=1.-(1.-muzzle_fire.a)*(1.-pan_fire.a);
	vec3 fire_colour=mix(muzzle_fire.rgb,pan_fire.rgb,pan_fire.a);
	float combined=fire_alpha+alpha*(1.-fire_alpha);
	vec3 colour=(fire_colour*fire_alpha+soot*alpha*(1.-fire_alpha))/max(combined,.001);
	COLOR=vec4(colour,combined);
}
