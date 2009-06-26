//mpx_depot

main()
{
//	setCullFog (0, 16500, 0.7, 0.85, 1.0, 0);
	ambientPlay("ambient_mp_depot");

	// set the nighttime flag to be off
	setcvar("sv_night", "0" );

	maps\mp\_load::main();
	maps\mp\mp_uo_depot_fx::main();
  maps\mp\mp_uo_depot::layout_images();

	game["allies"] = "british";
	game["axis"] = "german";

	game["british_soldiertype"] = "commando";
	game["british_soldiervariation"] = "normal";
	game["german_soldiertype"] = "wehrmacht";
	game["german_soldiervariation"] = "normal";

	game["attackers"] = "allies";
	game["defenders"] = "axis";
	
	game["sec_type"] = "destroy";				//What type of secondary objective

	game["hud_allies_victory_image"] = "gfx/hud/hud@mp_victory_depot_b.dds";
	game["hud_axis_victory_image"] = "gfx/hud/hud@mp_victory_depot_g.dds";

	//retrival settings
	level.obj["Code Book"] = (&"RE_OBJ_CODE_BOOK");
	game["re_attackers"] = "allies";
	game["re_defenders"] = "axis";
	game["re_attackers_obj_text"] = (&"RE_OBJ_DEPOT_OBJ_ATTACKER");
	game["re_defenders_obj_text"] = (&"RE_OBJ_DEPOT_OBJ_DEFENDER");
	game["re_spectator_obj_text"] = (&"RE_OBJ_DEPOT_OBJ_SPECTATOR");
	game["re_attackers_intro_text"] = (&"RE_OBJ_DEPOT_SPAWN_ATTACKER");
	game["re_defenders_intro_text"] = (&"RE_OBJ_DEPOT_SPAWN_DEFENDER");


	// DOM Setup
	flag1 = getent("flag1","targetname");				// identifies the flag you're setting up
	flag1.script_timer = 8;						// how many seconds a capture takes with one player
	flag1.description = (&"GMI_DOM_FLAG1_MP_UO_DEPOT");		// the name of the flag	(localized in gmi_mp.str)

	flag2 = getent("flag2","targetname");
	flag2.script_timer = 8;
	flag2.description = (&"GMI_DOM_FLAG2_MP_UO_DEPOT");

	flag3 = getent("flag3","targetname");
	flag3.script_timer = 8;
	flag3.description = (&"GMI_DOM_FLAG3_MP_UO_DEPOT");

	flag4 = getent("flag4","targetname");
	flag4.script_timer = 8;
	flag4.description = (&"GMI_DOM_FLAG4_MP_UO_DEPOT");
	
	flag5 = getent("flag5","targetname");
	flag5.script_timer = 8;
	flag5.description = (&"GMI_DOM_FLAG5_MP_UO_DEPOT");


	//hq settings
	if (getcvar("g_gametype") == "hq")
	{
		radio = spawn ("script_model", (0,0,0));
		radio.origin = (-909, 2007, 21);
		radio.angles = (0, 57, 0);
		radio.targetname = "hqradio";
		radio = spawn ("script_model", (0,0,0));
		radio.origin = (-2644, 1444, -24);
		radio.angles = (0, 1, 0);
		radio.targetname = "hqradio";
		radio = spawn ("script_model", (0,0,0));
		radio.origin = (207, 432, -24);
		radio.angles = (0, 312, 0);
		radio.targetname = "hqradio";
		radio = spawn ("script_model", (0,0,0));
		radio.origin = (-987, 439, -24);
		radio.angles = (0, 228, 0);
		radio.targetname = "hqradio";
		radio = spawn ("script_model", (0,0,0));
		radio.origin = (-1271, -471, -24);
		radio.angles = (0, 317, 0);
		radio.targetname = "hqradio";
		radio = spawn ("script_model", (0,0,0));
		radio.origin = (-2530, -573, 20);
		radio.angles = (0, 163, 0);
		radio.targetname = "hqradio";
		radio = spawn ("script_model", (0,0,0));
		radio.origin = (-1778, -2002, 40);
		radio.angles = (0, 97, 0);
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
	game["dom_layoutimage"] = "mp_uo_depot_dom";
	game["ctf_layoutimage"] = "mp_uo_depot_ctf";
	game["layoutimage"] = "mp_uo_depot";
}	
