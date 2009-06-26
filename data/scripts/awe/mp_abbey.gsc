main()
{
	setCullFog (800, 6000, 0.3, .27, .35, 0);
        ambientPlay("ambient_mp_brecourt");
        
        level._effect["water"] = loadfx ("fx/water/em_froth.efx");
	maps\mp\_fx::loopfx("water", (-2138, -6108, -207), 0.6);
        level._effect["water"] = loadfx ("fx/water/em_froth.efx");
	maps\mp\_fx::loopfx("water", (-1848, -7910, -207), 0.6);

	
	maps\mp\_load::main();

        getent ("waterfall1","targetname") playloopsound ("waterfall_dam2");	
        getent ("waterfall2","targetname") playloopsound ("waterfall_dam2");


        game["allies"] = "american";
	game["axis"] = "german";

	game["american_soldiertype"] = "airborne";
	game["american_soldiervariation"] = "normal";
	game["german_soldiertype"] = "wehrmacht_soldier";
	game["german_soldiervariation"] = "normal";

	game["attackers"] = "allies";
	game["defenders"] = "axis";
	
        //retrival settings
 	level.obj["Code Book"] = (&"RE_OBJ_CODE_BOOK");
 	game["re_attackers"] = "axis";
 	game["re_defenders"] = "allies";
 	game["re_attackers_obj_text"] = (&"RE_OBJ_BRECOURT_OBJ_ATTACKER");
 	game["re_defenders_obj_text"] = (&"RE_OBJ_BRECOURT_OBJ_DEFENDER");
 	game["re_spectator_obj_text"] = (&"RE_OBJ_BRECOURT_OBJ_SPECTATOR");
 	game["re_attackers_intro_text"] = (&"RE_OBJ_BRECOURT_SPAWN_ATTACKER");
 	game["re_defenders_intro_text"] = (&"RE_OBJ_BRECOURT_SPAWN_DEFENDER");
 
 	fixBugs();
 
}

fixBugs() {
//fixes by innocent bystander, www.after-hourz.com

	// Block access to exploits
 	level thread maps\mp\_exploit_blocker::sharkScanner(-240, 1, "lt");
	
}	
	