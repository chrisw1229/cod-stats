main()
{
	setCullFog (0, 3200, .32, .36, .40, 0 );
	ambientPlay("ambient_mp_hurtgen");

	// set the nighttime flag to be off
	setcvar("sv_night", "0" );

	maps\mp\_load::main();
	maps\mp\mp_uo_hurtgen_fx::main();
	maps\mp\mp_uo_hurtgen::layout_images();
	level thread maps\mp\_tankdrive_gmi::main();
	level thread maps\mp\_jeepdrive_gmi::main();

	game["allies"] = "american";
	game["axis"] = "german";

	game["american_soldiertype"] = "airborne";
	game["american_soldiervariation"] = "winter";
	game["german_soldiertype"] = "wehrmacht";
	game["german_soldiervariation"] = "winter";

	game["attackers"] = "allies";
	game["defenders"] = "axis";

	game["hud_allies_victory_image"] = "gfx/hud/hud@mp_victory_hurtgen_us.dds";
	game["hud_axis_victory_image"] = "gfx/hud/hud@mp_victory_hurtgen_g.dds";
	
	//retrival settings
	level.obj["V-2 Rocket Schedule"] = (&"RE_OBJ_ROCKET_SCHEDULE");
	level.obj["Artillery Map"] = (&"RE_OBJ_ARTILLERY_MAP");
	game["re_attackers"] = "allies";
	game["re_defenders"] = "axis";
	game["re_attackers_obj_text"] = (&"RE_OBJ_HURTGEN_OBJ_ATTACKER");
	game["re_defenders_obj_text"] = (&"RE_OBJ_HURTGEN_OBJ_DEFENDER");
	game["re_spectator_obj_text"] = (&"RE_OBJ_HURTGEN_OBJ_SPECTATOR");
	game["re_attackers_intro_text"] = (&"RE_OBJ_HURTGEN_SPAWN_ATTAKER");
	game["re_defenders_intro_text"] = (&"RE_OBJ_HURTGEN_SPAWN_DEFENDER");

	// DOM Setup
	flag1 = getent("flag1","targetname");				// identifies the flag you're setting up
	flag1.script_timer = 8;						// how many seconds a capture takes with one player
	flag1.description = (&"GMI_DOM_FLAG1_MP_UO_HURTGEN");		// the name of the flag	(localized in gmi_mp.str)

	flag2 = getent("flag2","targetname");
	flag2.script_timer = 8;
	flag2.description = (&"GMI_DOM_FLAG2_MP_UO_HURTGEN");

	flag3 = getent("flag3","targetname");
	flag3.script_timer = 8;
	flag3.description = (&"GMI_DOM_FLAG3_MP_UO_HURTGEN");

	//flag4 = getent("flag4","targetname");
	//flag4.script_timer = 8;
	//flag4.description = (&"GMI_DOM_FLAG4_MP_UO_HURTGEN");
	
	flag4 = getent("flag4","targetname");
	flag4.script_timer = 8;
	flag4.description = (&"GMI_DOM_FLAG5_MP_UO_HURTGEN");

	flag5 = getent("flag5","targetname");
	flag5.script_timer = 8;
	flag5.description = (&"GMI_DOM_FLAG6_MP_UO_HURTGEN");

	//hq settings
	if (getcvar("g_gametype") == "hq")
	{
		radio = spawn ("script_model", (0,0,0));
		radio.origin = (-3504, 932, -46);
		radio.angles = (0, 98, 0);
		radio.targetname = "hqradio";
		radio = spawn ("script_model", (0,0,0));
		radio.origin = (-484, 1305, -61);
		radio.angles = (0, 106, 0);
		radio.targetname = "hqradio";
		radio = spawn ("script_model", (0,0,0));
		radio.origin = (125, -628, -198);
		radio.angles = (0, 106, 0);
		radio.targetname = "hqradio";
		radio = spawn ("script_model", (0,0,0));
		radio.origin = (2384, -2255, -230.5);
		radio.angles = (0, 349, 0);
		radio.targetname = "hqradio";
		radio = spawn ("script_model", (0,0,0));
		radio.origin = (3682, 823, -148);
		radio.angles = (359, 296, 2);
		radio.targetname = "hqradio";
		radio = spawn ("script_model", (0,0,0));
		radio.origin = (4480, -2106, 74);
		radio.angles = (0, 180, 0);
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
	game["dom_layoutimage"] = "mp_uo_hurtgen_dom";
	game["ctf_layoutimage"] = "mp_uo_hurtgen_ctf";
	game["layoutimage"] = "mp_uo_hurtgen";
}