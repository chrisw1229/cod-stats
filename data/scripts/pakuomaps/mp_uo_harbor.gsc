main()
{
	setCullFog (0, 6500, .8, .8, .8, 0); //pavlovtest sky color
	ambientPlay("ambient_mp_harbor");

	// set the nighttime flag to be off
	setcvar("sv_night", "0" );

	maps\mp\_load::main();
	maps\mp\mp_uo_harbor::layout_images();
	
	game["allies"] = "russian";
	game["axis"] = "german";

	game["russian_soldiertype"] = "conscript";
	game["russian_soldiervariation"] = "winter";
	game["german_soldiertype"] = "waffen";
	game["german_soldiervariation"] = "winter";

	game["attackers"] = "allies";
	game["defenders"] = "axis";

	game["hud_allies_victory_image"] = "gfx/hud/hud@mp_victory_harbor_r.dds";
	game["hud_axis_victory_image"] = "gfx/hud/hud@mp_victory_harbor_g.dds";

	//retrival settings
	level.obj["Artillery Map"] = (&"RE_OBJ_ARTILLERY_MAP");
	game["re_attackers"] = "allies";
	game["re_defenders"] = "axis";
	game["re_attackers_obj_text"] = (&"RE_OBJ_HARBOR_OBJ_ATTACKER");
	game["re_defenders_obj_text"] = (&"RE_OBJ_HARBOR_OBJ_DEFENDER");
	game["re_spectator_obj_text"] = (&"RE_OBJ_HARBOR_OBJ_SPECTATOR");
	game["re_attackers_intro_text"] = (&"RE_OBJ_HARBOR_SPAWN_ATTACKER");
	game["re_defenders_intro_text"] = (&"RE_OBJ_HARBOR_SPAWN_DEFENDER");

	game["compass_range"] = 3200;					//How far the compass is zoomed in

	// DOM Setup
	flag1 = getent("flag1","targetname");				// identifies the flag you're setting up
	flag1.script_timer = 8;						// how many seconds a capture takes with one player
	flag1.description = (&"GMI_DOM_FLAG1_MP_UO_HARBOR");		// the name of the flag	(localized in gmi_mp.str)

	flag2 = getent("flag2","targetname");
	flag2.script_timer = 8;
	flag2.description = (&"GMI_DOM_FLAG2_MP_UO_HARBOR");

	flag3 = getent("flag3","targetname");
	flag3.script_timer = 8;
	flag3.description = (&"GMI_DOM_FLAG3_MP_UO_HARBOR");

	flag4 = getent("flag4","targetname");
	flag4.script_timer = 8;
	flag4.description = (&"GMI_DOM_FLAG4_MP_UO_HARBOR");
	
	flag5 = getent("flag5","targetname");
	flag5.script_timer = 8;
	flag5.description = (&"GMI_DOM_FLAG5_MP_UO_HARBOR");

	//hq settings
	if (getcvar("g_gametype") == "hq")
	{
		radio = [];
		radio = spawn ("script_model", (0,0,0));
		radio.origin = (-11600, -7600, 32);
		radio.angles = (0, 135, 0);
		radio.targetname = "hqradio";
		radio = spawn ("script_model", (0,0,0));
		radio.origin = (-9774, -8612, 8);
		radio.angles = (0, 8, 0);
		radio.targetname = "hqradio";
		radio = spawn ("script_model", (0,0,0));
		radio.origin = (-9112, -6657, 0);
		radio.angles = (0, 137, 0);
		radio.targetname = "hqradio";
		radio = spawn ("script_model", (0,0,0));
		radio.origin = (-8385, -7940, 0);
		radio.angles = (0, 51, 0);
		radio.targetname = "hqradio";
		radio = spawn ("script_model", (0,0,0));
		radio.origin = (-6932, -7395, 0);
		radio.angles = (0, 153, 0);
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
}

layout_images()
{
	game["dom_layoutimage"] = "mp_uo_harbor_dom";
	game["ctf_layoutimage"] = "mp_uo_harbor_ctf";
	game["layoutimage"] = "mp_uo_harbor";
}