
main()
{

	level._effect["fire"] = loadfx ("fx/fire/fireheavysmoke.efx");
	maps\mp\_fx::loopfx("fire", (224, -624, 75), 0.6);

	level._effect["smoke"] = loadfx ("fx/smoke/dawnville_smoke3.efx");
	maps\mp\_fx::loopfx("smoke", (224, -624, 125), 0.5);

	level._effect["fire"] = loadfx ("fx/fire/fireheavysmoke.efx");
	maps\mp\_fx::loopfx("fire", (-1824, -976, 104), 0.5);

	level._effect["smoke"] = loadfx ("fx/smoke/dawnville_smoke3.efx");
	maps\mp\_fx::loopfx("smoke", (-1824, -976, 120), 0.5);

	setCullFog (0, 6500, .32, .36, .40, 0 );

	ambientPlay("ambient_mp_brecourt");
	
	maps\mp\_load::main();
	maps\mp\wolfsquare_sounds::main();

	
	game["allies"] = "american";
	game["axis"] = "german";

	game["american_soldiertype"] = "airborne";
	game["american_soldiervariation"] = "normal";
	game["german_soldiertype"] = "fallschirmjagergrey";
	game["german_soldiervariation"] = "normal";
	game["attackers"] = "allies";
	game["defenders"] = "axis";
	
	game["layoutimage"] = "mp_wolfsquare_final";

	fixBugs();

}


fixBugs() {
//fixes by innocent bystander, www.after-hourz.com

	// Block access to exploits
 	level thread maps\mp\_exploit_blocker::sharkScanner(-120, 1, "lt");
	
}	
	