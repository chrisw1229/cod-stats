//mp_streets

main()
{
	//setExpFog (0.00005, .72, .59, .63, 0 );
	setCullFog (500, 7000, .61, .66, .68, 0 );
	ambientPlay("ambient_mp_foy");
	level thread firesounds();

	maps\mp\_load::main();
	maps\mp\mp_streets::layout_images();
	maps\mp\mp_streets_fx::main();
	//level thread maps\mp\_tankdrive_gmi::main();
	//level thread maps\mp\_treefall_gmi::main();

	game["allies"] = "american";
	game["axis"] = "german";

	game["british_soldiertype"] = "airborn";
	game["british_soldiervariation"] = "normal";
	game["german_soldiertype"] = "waffen";
	game["german_soldiervariation"] = "normal";

	game["attackers"] = "allies";
	game["defenders"] = "axis";

	game["layoutimage"] = "mp_streets.dds";

        //retrival settings
	level.obj["Code Book"] = (&"RE_OBJ_CODE_BOOK");
	level.obj["Field Radio"] = (&"RE_OBJ_FIELD_RADIO");
	game["re_attackers"] = "allies";
	game["re_defenders"] = "axis";

        game["re_attackers_obj_text"] = (&"GMI_MP_RE_OBJ_STREETS_ATTACKER");
	game["re_defenders_obj_text"] = (&"GMI_MP_RE_OBJ_STREETS_DEFENDER");
	game["re_spectator_obj_text"] = (&"GMI_MP_RE_OBJ_STREETS_SPECTATOR");
	game["re_attackers_intro_text"] = (&"GMI_MP_RE_OBJ_STREETS_SPAWN_ATTACKER");
	game["re_defenders_intro_text"] = (&"GMI_MP_RE_OBJ_STREETS_SPAWN_DEFENDER");

	game["hud_allies_victory_image"] = "gfx/hud/hud@mp_victory_streets_us.dds";
  	game["hud_axis_victory_image"] = "gfx/hud/hud@mp_victory_streets_g.dds";

	thread Flag_Setup();
	
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
	flag1.description = (&"GMI_DOM_FLAG1_MP_STREETS");	// the name of the flag (localized in gmi_mp.str)

	flag2 = getent("flag2","targetname");
	flag2.script_timer = 5;
	flag2.description = (&"GMI_DOM_FLAG2_MP_STREETS");

	flag3 = getent("flag3","targetname");
	flag3.script_timer = 5;
	flag3.description = (&"GMI_DOM_FLAG3_MP_STREETS");

	flag4 = getent("flag4","targetname");
	flag4.script_timer = 5;
	flag4.description = (&"GMI_DOM_FLAG4_MP_STREETS");

	flag5 = getent("flag5","targetname");
	flag5.script_timer = 3;
	flag5.description = (&"GMI_DOM_FLAG5_MP_STREETS");

	//block any map exploits
	fixExploits();

}

layout_images()
{
	game["dom_layoutimage"] = "mp_streets_dom.dds";
	game["ctf_layoutimage"] = "mp_streets_ctf.dds";
	game["layoutimage"] = "mp_streets";
}

firesounds()
{
	org1 = spawn("script_model",(856,-4904,16));
	org1 playloopsound ("medfire");
	org2 = spawn("script_model",(528,-4864,16));
	org2 playloopsound ("medfire");
}

fixExploits() {
//fixes by innocent bystander, www.after-hourz.com

	// Block access to exploits
	thread maps\mp\_exploit_blocker::blockBox((803, -6042, 188), (2,1,1));
	thread maps\mp\_exploit_blocker::blockBox((732, -5575, 162), (1,1,1));
	
}