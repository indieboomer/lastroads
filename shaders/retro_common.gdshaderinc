uniform bool retro_enabled = false;
uniform int style = 1;
uniform float virtual_height = 270.0;
uniform float dither_amount = 0.65;
uniform float grain_amount = 0.20;

// A stable 4x4 ordered pattern: no animated noise or shimmering when paused.
float ordered(vec2 pixel) {
	ivec2 p = ivec2(mod(pixel,4.0));
	const float bayer[16] = float[16](0.,8.,2.,10.,12.,4.,14.,6.,3.,11.,1.,9.,15.,7.,13.,5.);
	return (bayer[p.y*4+p.x]+0.5)/16.0-0.5;
}

vec3 earth(int i) {
	const vec3 palette[24] = vec3[24](
		vec3(.045,.065,.075),vec3(.09,.12,.13),vec3(.15,.19,.18),vec3(.21,.26,.22),
		vec3(.28,.33,.25),vec3(.37,.41,.30),vec3(.49,.50,.36),vec3(.62,.60,.43),
		vec3(.21,.16,.14),vec3(.32,.23,.17),vec3(.44,.31,.20),vec3(.56,.39,.24),
		vec3(.68,.48,.28),vec3(.80,.60,.36),vec3(.90,.73,.48),vec3(.97,.86,.65),
		vec3(.25,.34,.36),vec3(.35,.45,.47),vec3(.47,.57,.58),vec3(.62,.69,.67),
		vec3(.42,.25,.25),vec3(.62,.34,.28),vec3(.77,.48,.35),vec3(.87,.66,.50));
	return palette[i];
}

vec3 gothic(int i) {
	const vec3 palette[24] = vec3[24](
		vec3(.035,.035,.065),vec3(.075,.07,.12),vec3(.13,.12,.19),vec3(.21,.19,.28),
		vec3(.30,.28,.38),vec3(.40,.38,.49),vec3(.52,.49,.59),vec3(.68,.64,.70),
		vec3(.10,.16,.17),vec3(.16,.23,.23),vec3(.24,.32,.28),vec3(.34,.41,.32),
		vec3(.46,.50,.37),vec3(.59,.59,.43),vec3(.72,.69,.51),vec3(.86,.81,.64),
		vec3(.29,.19,.19),vec3(.44,.27,.22),vec3(.59,.37,.25),vec3(.74,.49,.29),
		vec3(.88,.63,.37),vec3(.98,.80,.51),vec3(.29,.38,.46),vec3(.47,.56,.61));
	return palette[i];
}

vec3 gilded(int i) {
	const vec3 palette[24] = vec3[24](
		vec3(.025,.035,.05),vec3(.035,.09,.10),vec3(.055,.16,.14),vec3(.10,.245,.18),
		vec3(.19,.34,.20),vec3(.32,.45,.23),vec3(.46,.54,.30),vec3(.66,.64,.38),
		vec3(.14,.07,.045),vec3(.27,.135,.065),vec3(.42,.235,.09),vec3(.60,.36,.115),
		vec3(.76,.50,.16),vec3(.88,.66,.27),vec3(.97,.81,.43),vec3(1.,.93,.69),
		vec3(.10,.23,.29),vec3(.18,.35,.43),vec3(.32,.49,.56),vec3(.52,.65,.68),
		vec3(.37,.10,.075),vec3(.58,.22,.11),vec3(.76,.39,.20),vec3(.88,.60,.37));
	return palette[i];
}

vec3 nearest_colour(vec3 colour, bool dark) {
	vec3 best=vec3(0.0);
	float distance_best=100.0;
	for(int i=0;i<24;i++) {
		vec3 candidate=style==5?gilded(i):(dark?gothic(i):earth(i));
		vec3 gap=colour-candidate;
		float distance_now=dot(gap*gap,vec3(.30,.55,.15));
		if(distance_now<distance_best) { best=candidate; distance_best=distance_now; }
	}
	return best;
}

vec3 retro_colour(vec3 colour, vec2 pixel, vec2 screen_pixel) {
	vec3 original_colour=colour;
	bool vivid_blood=colour.r>colour.g*3.0 && colour.r>colour.b*2.0 && colour.r>.22;
	bool spectral_ink=colour.b>.7 && colour.g>.6 && colour.r<.18;
	float pattern=ordered(pixel);
	float noise=fract(sin(dot(pixel,vec2(12.9898,78.233)))*43758.5453)-.5;
	colour=clamp(colour,vec3(0.),vec3(1.));
	if(style>=6) {
		// Strict two-colour output, including blood, magic and illustrations.
		// Compress dark values so night silhouettes retain useful texture.
		float luma=pow(dot(colour,vec3(.299,.587,.114)),.72);
		float threshold=.43+pattern*dither_amount*1.35+noise*grain_amount*.12;
		vec3 ink=style==6?vec3(.055,.060,.050):(style==7?vec3(.012,.045,.020):vec3(.035,.045,.13));
		vec3 paper=style==6?vec3(.85,.84,.73):(style==7?vec3(.34,.90,.40):vec3(.69,.79,.98));
		return luma>=threshold?paper:ink;
	} else if(style==0) {
		// RGB 5:6:5, deliberately calmer than the limited-palette modes.
		vec3 levels=vec3(31.,63.,31.);
		colour=floor(colour*levels+.5+pattern*dither_amount)/levels;
	} else if(style==1 || style==3 || style==5) {
		float luma=dot(colour,vec3(.299,.587,.114));
		colour=mix(vec3(luma),colour,style==5?1.22:(style==3?.78:.92));
		colour=(colour-.40)*(style==3?1.12:1.07)+.40;
		if(style==3) colour*=vec3(.92,.95,1.035);
		if(style==5) colour=(colour-.42)*1.03+.42;
		colour=nearest_colour(clamp(colour+(pattern*dither_amount*.095+noise*grain_amount*.035),vec3(0.),vec3(1.)),style==3);
	} else if(style==2) {
		// VGA-style channel ramps, deliberately stronger ordered dithering.
		colour=pow(colour,vec3(.94));
		colour=floor(colour*5.+.5+pattern*dither_amount*.95)/5.;
	} else {
		colour=floor(colour*31.+.5+pattern*dither_amount)/31.;
		colour*=vec3(1.025,1.0,.96);
		float scan=.955+.045*cos(screen_pixel.y*3.14159265);
		float mask=mod(floor(screen_pixel.x),3.);
		colour*=scan;
		colour*=mix(vec3(.96),vec3(1.025),vec3(float(mask<1.),float(mask>=1. && mask<2.),float(mask>=2.)));
	}
	if(style!=1 && style!=3 && style!=5) colour+=noise*grain_amount*.035;
	if(vivid_blood) colour=mix(colour,vec3(max(original_colour.r,.62),original_colour.g*.45,original_colour.b*.55),.85);
	if(spectral_ink) colour=mix(colour,original_colour,.85);
	return clamp(colour,vec3(0.),vec3(1.));
}
