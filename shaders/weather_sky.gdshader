shader_type sky;
uniform sampler2D panorama : source_color, filter_linear;
uniform vec3 sun_direction = vec3(.5,.5,.5);
uniform vec4 sun_tint : source_color = vec4(1.,.8,.5,1.);
uniform float sun_strength = 0.;
global uniform float road_time;
global uniform float road_clouds;
global uniform float road_wind;
global uniform float road_flash;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1)),f.x),f.y);}
void sky(){
	vec3 painted=texture(panorama,SKY_COORDS).rgb;
	vec3 clear_colour=mix(vec3(.38,.57,.63),vec3(.12,.32,.49),clamp(EYEDIR.y,0.,1.));
	vec2 plane=EYEDIR.xz/max(.18,EYEDIR.y+.28)*2.4+vec2(road_time*.008*(.3+road_wind),road_time*.002);
	float n=noise(plane)*.55+noise(plane*2.1)*.28+noise(plane*4.2)*.17;
	float clouds=smoothstep(.80-road_clouds*.66,.99-road_clouds*.63,n)*smoothstep(-.08,.22,EYEDIR.y);
	vec3 cloud_colour=mix(vec3(.91,.87,.74),vec3(.19,.26,.31),road_clouds);
	vec3 base=mix(clear_colour,painted,.25+road_clouds*.3);
	COLOR=mix(base,cloud_colour,clouds)+road_flash*vec3(.6,.7,.9);
	float alignment=max(dot(normalize(EYEDIR),sun_direction),0.);
	float disc=smoothstep(.99980,.99996,alignment);
	float halo=pow(alignment,220.)*.35+pow(alignment,24.)*.08;
	COLOR+=sun_tint.rgb*(disc*2.+halo)*sun_strength*(1.-clouds*.92);
}
