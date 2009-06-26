main()
{
//	setCullFog (0, 16500, 0.7, 0.85, 1.0, 0);
	setCullFog (0, 8000, .32, .36, .40, 0);
	ambientPlay("ambient_mp_carentan");

	// set the nighttime flag to be off
	setcvar("sv_night", "0" );

	maps\mp\_load::main();
	maps\mp\mp_uo_dawnville::layout_images();
	maps\mp\mp_uo_dawnville_fx::main();

	game["allies"] = "american";
	game["axis"] = "german";

	game["american_soldiertype"] = "airborne";
	game["american_soldiervariation"] = "normal";
	game["german_soldiertype"] = "fallschirmjagercamo";
	game["german_soldiervariation"] = "normal";

	game["attackers"] = "allies";
	game["defenders"] = "axis";

	game["hud_allies_victory_image"] = "gfx/hud/hud@mp_victory_dawnville_us.dds";
	game["hud_axis_victory_image"] = "gfx/hud/hud@mp_victory_dawnville_g.dds";

	//retrival settings
	level.obj["Field Radio"] = (&"RE_OBJ_FIELD_RADIO");
	game["re_attackers"] = "axis";
	game["re_defenders"] = "allies";
	game["re_attackers_obj_text"] = (&"RE_OBJ_DAWNVILLE_OBJ_ATTACKER");
	game["re_defenders_obj_text"] = (&"RE_OBJ_DAWNVILLE_OBJ_DEFENDER");
	game["re_spectator_obj_text"] = (&"RE_OBJ_DAWNVILLE_OBJ_SPECTATOR");
	game["re_attackers_intro_text"] = (&"RE_OBJ_DAWNVILLE_SPAWN_ATTACKER");
	game["re_defenders_intro_text"] = (&"RE_OBJ_DAWNVILLE_SPAWN_DEFENDER");

	
	//Flag Setup
	//There must be a set of the following for each flag in your map.
	flag1 = getent("flag1","targetname");				// identifies the flag you're setting up
	flag1.script_timer = 6;						// how many seconds a capture takes with one player
	flag1.description = (&"GMI_DOM_FLAG1_MP_UO_DAWNVILLE");		// the name of the flag (localized in gmi_mp.str)

	flag2 = getent("flag2","targetname");
	flag2.script_timer = 8;
	flag2.description = (&"GMI_DOM_FLAG2_MP_UO_DAWNVILLE");

	flag3 = getent("flag3","targetname");
	flag3.script_timer = 10;
	flag3.description = (&"GMI_DOM_FLAG3_MP_UO_DAWNVILLE");

	flag4 = getent("flag4","targetname");
	flag4.script_timer = 8;
	flag4.description = (&"GMI_DOM_FLAG4_MP_UO_DAWNVILLE");

	flag5 = getent("flag5","targetname");
	flag5.script_timer = 6;
	flag5.description = (&"GMI_DOM_FLAG5_MP_UO_DAWNVILLE");

	//hq settings
	if (getcvar("g_gametype") == "hq")
	{
		radio = spawn ("script_model", (0,0,0));
		radio.origin = (315, -18121, 172);
		radio.angles = (0, 353, 0);
		radio.targetname = "hqradio";
		radio = spawn ("script_model", (0,0,0));
		radio.origin = (184, -16100, 16);
		radio.angles = (0, 29, 0);
		radio.targetname = "hqradio";
		radio = spawn ("script_model", (0,0,0));
		radio.origin = (2952, -15537, -51);
		radio.angles = (0, 180, 5);
		radio.targetname = "hqradio";
		radio = spawn ("script_model", (0,0,0));
		radio.origin = (-1168, -18616, 64);
		radio.angles = (0, 90, 0);
		radio.targetname = "hqradio";
		radio = spawn ("script_model", (0,0,0));
		radio.origin = (-1461, -16249, -36);
		radio.angles = (356, 289, 1);
		radio.targetname = "hqradio";
		radio = spawn ("script_model", (0,0,0));
		radio.origin = (-674, -15032, -19);
		radio.angles = (350, 0, 0);
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
	game["dom_layoutimage"] = "mp_uo_dawnville_dom";
	game["ctf_layoutimage"] = "mp_uo_dawnville_ctf";
	game["layoutimage"] = "mp_uo_dawnville";
}