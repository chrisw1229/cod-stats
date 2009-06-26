//mp_sicily

main()
{
	//setCullFog (500, 7000, .61, .66, .68, 0 );
	ambientPlay("ambient_mp_depot");

	maps\mp\_load::main();
	level thread maps\mp\_tankdrive_gmi::main();
	level thread maps\mp\_jeepdrive_gmi::main();
	level thread maps\mp\_treefall_gmi::main();

	game["allies"] = "american";
	game["axis"] = "german";

	game["british_soldiertype"] = "airborne";
	game["british_soldiervariation"] = "winter";
	game["german_soldiertype"] = "wehrmacht";
	game["german_soldiervariation"] = "winter";

	game["attackers"] = "allies";
	game["defenders"] = "axis";

	game["layoutimage"] = "mp_peaks.dds";

        //retrival settings
//	level.obj["Code Book"] = (&"RE_OBJ_CODE_BOOK");
//	level.obj["Field Radio"] = (&"RE_OBJ_FIELD_RADIO");
	game["re_attackers"] = "allies";
	game["re_defenders"] = "axis";

        game["re_attackers_obj_text"] = (&"GMI_MP_RE_OBJ_CASSINO_ATTACKER");
	game["re_defenders_obj_text"] = (&"GMI_MP_RE_OBJ_CASSINO_DEFENDER");
	game["re_spectator_obj_text"] = (&"GMI_MP_RE_OBJ_CASSINO_SPECTATOR");
	game["re_attackers_intro_text"] = (&"GMI_MP_RE_OBJ_CASSINO_SPAWN_ATTACKER");
	game["re_defenders_intro_text"] = (&"GMI_MP_RE_OBJ_CASSINO_SPAWN_DEFENDER");

	game["hud_allies_victory_image"] = "gfx/hud/hud@mp_victory_peaks_us.dds";

        game["hud_axis_victory_image"] = "gfx/hud/hud@mp_victory_peaks_g.dds";

	game["dom_layoutimage"] = "mp_peaks_dom.dds";
        game["ctf_layoutimage"] = "mp_peaks_ctf.dds";
	
	thread Flag_Setup();
	thread HQ_Setup();
	thread MG42_Health_Regen();
	
	// FOR BUILDING PAK FILES ONLY
	if (getcvar("fs_copyfiles") == "1")
	{
		precacheShader(game["dom_layoutimage"]);
		precacheShader(game["ctf_layoutimage"]);
		precacheShader(game["layoutimage"]);
		precacheShader(game["hud_allies_victory_image"]);
		precacheShader(game["hud_axis_victory_image"]);
	}
}

Flag_Setup()
{
	flag1 = getent("flag1","targetname");			// identifies the flag you're setting up
	flag1.script_timer = 3;					// how many seconds a capture takes with one player
	flag1.description = (&"GMI_DOM_FLAG1_MP_PEAKS");	// the name of the flag (localized in gmi_mp.str)

	flag2 = getent("flag2","targetname");
	flag2.script_timer = 5;
	flag2.description = (&"GMI_DOM_FLAG2_MP_PEAKS");

	flag3 = getent("flag3","targetname");
	flag3.script_timer = 5;
	flag3.description = (&"GMI_DOM_FLAG3_MP_PEAKS");

	flag4 = getent("flag4","targetname");
	flag4.script_timer = 5;
	flag4.description = (&"GMI_DOM_FLAG4_MP_PEAKS");

	flag5 = getent("flag5","targetname");
	flag5.script_timer = 3;
	flag5.description = (&"GMI_DOM_FLAG5_MP_PEAKS");
}

// Spawn points for the HQ Radio
HQ_Setup()
{
	//hq settings
	if (getcvar("g_gametype") == "hq")
	{
		radio = spawn ("script_model", (0,0,0));
		radio.origin = (-768, 684, 263);
		radio.angles = (0, 290, 0);
		radio.targetname = "hqradio";
		radio = spawn ("script_model", (0,0,0));
		radio.origin = (-1089, 33, 503);
		radio.angles = (0, 140, 0);
		radio.targetname = "hqradio";
		radio = spawn ("script_model", (0,0,0));
		radio.origin = (-112, -1220, 324);
		radio.angles = (10, 250, 0);
		radio.targetname = "hqradio";
		radio = spawn ("script_model", (0,0,0));
		radio.origin = (-1176, 2619, 313);
		radio.angles = (10, 214, 3.394);
		radio.targetname = "hqradio";
		radio = spawn ("script_model", (0,0,0));
		radio.origin = (334, 16, 488);
		radio.angles = (0, 190, 0);
		radio.targetname = "hqradio";
		radio = spawn ("script_model", (0,0,0));
		radio.origin = (-1917, 1954, 333);
		radio.angles = (0, -10, 0);
		radio.targetname = "hqradio";
		radio = spawn ("script_model", (0,0,0));
		radio.origin = (-3750, 3148, -48);
		radio.angles = (16, -60, 0);
		radio.targetname = "hqradio";
	}
}

MG42_Health_Regen()
{
	wait 1;
	mg42s = getentarray("misc_mg42","classname");

	if(!isdefined(mg42s))
	{
		println("^1MG42s are not defined!!!");
		return;
	}

	while(1)
	{
		for(i=0;i<mg42s.size;i++)
		{
			mg42s[i].health = 1000000;
		}
		wait 3;
	}
}