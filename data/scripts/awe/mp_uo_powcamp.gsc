main()
{
	setCullFog (0, 8000, .32, .36, .40, 0);
	ambientPlay("ambient_mp_powcamp");
	
	// set the nighttime flag to be off
	setcvar("sv_night", "0" );

	maps\mp\_load::main();
	maps\mp\mp_uo_powcamp_fx::main();
  maps\mp\mp_uo_powcamp::layout_images();
	
	game["allies"] = "russian";
	game["axis"] = "german";

	game["russian_soldiertype"] = "conscript";
	game["russian_soldiervariation"] = "normal";
	game["german_soldiertype"] = "wehrmacht";
	game["german_soldiervariation"] = "normal";

	game["attackers"] = "allies";
	game["defenders"] = "axis";

	game["hud_allies_victory_image"] = "gfx/hud/hud@mp_victory_powcamp_r.dds";
	game["hud_axis_victory_image"] = "gfx/hud/hud@mp_victory_powcamp_g.dds";

	//retrival settings
	level.obj["Camp Records"] = (&"RE_OBJ_CAMP_RECORDS");
	game["re_attackers"] = "allies";
	game["re_defenders"] = "axis";
	game["re_attackers_obj_text"] = (&"RE_OBJ_POWCAMP_OBJ_ATTACKER");
	game["re_defenders_obj_text"] = (&"RE_OBJ_POWCAMP_OBJ_DEFENDER");
	game["re_spectator_obj_text"] = (&"RE_OBJ_POWCAMP_OBJ_SPECTATOR");
	game["re_attackers_intro_text"] = (&"RE_OBJ_POWCAMP_SPAWN_ATTACKER");
	game["re_defenders_intro_text"] = (&"RE_OBJ_POWCAMP_SPAWN_DEFENDER");
	

	// DOM Setup
	flag1 = getent("flag1","targetname");				// identifies the flag you're setting up
	flag1.script_timer = 8;						// how many seconds a capture takes with one player
	flag1.description = (&"GMI_DOM_FLAG1_MP_UO_POWCAMP");		// the name of the flag	(localized in gmi_mp.str)

	flag2 = getent("flag2","targetname");
	flag2.script_timer = 8;
	flag2.description = (&"GMI_DOM_FLAG2_MP_UO_POWCAMP");

	flag3 = getent("flag3","targetname");
	flag3.script_timer = 8;
	flag3.description = (&"GMI_DOM_FLAG3_MP_UO_POWCAMP");

	flag4 = getent("flag4","targetname");
	flag4.script_timer = 8;
	flag4.description = (&"GMI_DOM_FLAG4_MP_UO_POWCAMP");
	
	flag5 = getent("flag5","targetname");
	flag5.script_timer = 8;
	flag5.description = (&"GMI_DOM_FLAG5_MP_UO_POWCAMP");

	//hq settings
	if (getcvar("g_gametype") == "hq")
	{
		radio = spawn ("script_model", (0,0,0));
		radio.origin = (1552, 4464, 0);
		radio.angles = (0, 270, 0);
		radio.targetname = "hqradio";
		radio = spawn ("script_model", (0,0,0));
		radio.origin = (-570, 3743, 34);
		radio.angles = (0, 8, 0);
		radio.targetname = "hqradio";
		radio = spawn ("script_model", (0,0,0));
		radio.origin = (-107, 1741, 0);
		radio.angles = (0, 259, 0);
		radio.targetname = "hqradio";
		radio = spawn ("script_model", (0,0,0));
		radio.origin = (-1758, 42, 0);
		radio.angles = (0, 205, 0);
		radio.targetname = "hqradio";
		radio = spawn ("script_model", (0,0,0));
		radio.origin = (-146, -825, 36);
		radio.angles = (0, 67, 0);
		radio.targetname = "hqradio";
	}

	// FOR BUILDING PAK FILES ONLY
	if (getcvar("fs_copyfiles") == "1")
	{
		precacheShader(game["dom_layoutimage"]);
		precacheShader(game["ctf_layoutimage"]);
//		precacheShader(game["bas_layoutimage"]);
		precacheShader(game["layoutimage"]);
		precacheShader(game["hud_allies_victory_image"]);
		precacheShader(game["hud_axis_victory_image"]);
	}
	
	//block any map exploits
	fixExploits();	
}


layout_images()
{
	game["dom_layoutimage"] = "mp_uo_powcamp_dom";
	game["ctf_layoutimage"] = "mp_uo_powcamp_ctf";
	game["layoutimage"] = "mp_uo_powcamp";
}


fixExploits() {
//fixes by innocent bystander, www.after-hourz.com

	// Block access to exploits
	thread maps\mp\_exploit_blocker::blockBox((1595, -1566, 88), (80,1,40));
	
}

