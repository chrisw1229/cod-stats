main()
{
	setCullFog (0, 16500, 0.7, 0.85, 1.0, 0);
	ambientPlay("ambient_mp_carentan");

	// set the nighttime flag to be off
	setcvar("sv_night", "0" );

	maps\mp\_load::main();
	maps\mp\mp_uo_carentan_fx::main();
	maps\mp\mp_uo_carentan::layout_images();

	remove_me_ctf();

	game["allies"] = "american";
	game["axis"] = "german";

	game["american_soldiertype"] = "airborne";
	game["american_soldiervariation"] = "normal";
	game["german_soldiertype"] = "fallschirmjagergrey";
	game["german_soldiervariation"] = "normal";

	game["attackers"] = "allies";
	game["defenders"] = "axis";

	game["hud_allies_victory_image"] = "gfx/hud/hud@mp_victory_carentan_us.dds";
	game["hud_axis_victory_image"] = "gfx/hud/hud@mp_victory_carentan_g.dds";
	
	//retrival settings
	level.obj["Code Book"] = (&"RE_OBJ_CODE_BOOK");
	level.obj["Field Radio"] = (&"RE_OBJ_FIELD_RADIO");
	game["re_attackers"] = "allies";
	game["re_defenders"] = "axis";
	game["re_attackers_obj_text"] = (&"RE_OBJ_CARENTAN_OBJ_ATTACKER");
	game["re_defenders_obj_text"] = (&"RE_OBJ_CARENTAN_OBJ_DEFENDER");
	game["re_spectator_obj_text"] = (&"RE_OBJ_CARENTAN_OBJ_SPECTATOR");
	game["re_attackers_intro_text"] = (&"RE_OBJ_CARENTAN_SPAWN_ATTACKER");
	game["re_defenders_intro_text"] = (&"RE_OBJ_CARENTAN_SPAWN_DEFENDER");


	// DOM Setup
	flag1 = getent("flag1","targetname");				// identifies the flag you're setting up
	flag1.script_timer = 8;						// how many seconds a capture takes with one player
	flag1.description = (&"GMI_DOM_FLAG1_MP_UO_CARENTAN");		// the name of the flag	(localized in gmi_mp.str)

	flag2 = getent("flag2","targetname");
	flag2.script_timer = 8;
	flag2.description = (&"GMI_DOM_FLAG2_MP_UO_CARENTAN");

	flag3 = getent("flag3","targetname");
	flag3.script_timer = 8;
	flag3.description = (&"GMI_DOM_FLAG3_MP_UO_CARENTAN");

	flag4 = getent("flag4","targetname");
	flag4.script_timer = 8;
	flag4.description = (&"GMI_DOM_FLAG4_MP_UO_CARENTAN");
	
	flag5 = getent("flag5","targetname");
	flag5.script_timer = 8;
	flag5.description = (&"GMI_DOM_FLAG5_MP_UO_CARENTAN");

	//hq settings
	if (getcvar("g_gametype") == "hq")
	{
		radio = spawn ("script_model", (0,0,0));
		radio.origin = (1198, 155, 18);
		radio.angles = (0, 257, 0);
		radio.targetname = "hqradio";
		radio = spawn ("script_model", (0,0,0));
		radio.origin = (100, 601, 0);
		radio.angles = (0, 352, 0);
		radio.targetname = "hqradio";
		radio = spawn ("script_model", (0,0,0));
		radio.origin = (-678, 430, 6);
		radio.angles = (354, 234, 0);
		radio.targetname = "hqradio";
		radio = spawn ("script_model", (0,0,0));
		radio.origin = (-842, 2084, 179);
		radio.angles = (0, 290, 0);
		radio.targetname = "hqradio";
		radio = spawn ("script_model", (0,0,0));
		radio.origin = (525, 1975, -118);
		radio.angles = (0, 267, 0);
		radio.targetname = "hqradio";
		radio = spawn ("script_model", (0,0,0));
		radio.origin = (1962, 2293, -24);
		radio.angles = (0, 245, 0);
		radio.targetname = "hqradio";
		radio = spawn ("script_model", (0,0,0));
		radio.origin = (837, 3637, -16);
		radio.angles = (0, 90, 0);
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
	game["dom_layoutimage"] = "mp_uo_carentan_dom";
	game["ctf_layoutimage"] = "mp_uo_carentan_ctf";
	game["layoutimage"] = "mp_uo_carentan";
}

remove_me_ctf()
{
	if (getcvar("g_gametype") == "ctf")
	{
		mg42 = getent("remove_me_42","targetname");
		mg42 delete();
	}
}