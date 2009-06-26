main()
{
  setExpFog(0.00001, .001, .001, .001, 0); 

	ambientPlay("ambient_varaville");

	maps\mp\_load::main();
	maps\mp\mp_varaville_fx::main();
	
	maps\mp\_load::main();
	maps\mp\_flak_gmi::main();
	level thread maps\mp\_tankdrive_gmi::main();
	level thread maps\mp\_jeepdrive_gmi::main();
	level thread maps\mp\_treefall_gmi::main();

	game["hud_allies_victory_image"] 	= "gfx/hud/hud@mp_victory_foy_us.dds";
	game["hud_axis_victory_image"] 		= "gfx/hud/hud@mp_victory_foy_g.dds";
	
	game["allies"] = "british";
	game["axis"] = "german";
		
	game["british_soldiertype"] = "commando";
	game["british_soldiervariation"] = "normal";
	game["american_soldiertype"] = "airborne";
	game["american_soldiervariation"] = "normal";
	game["german_soldiertype"] = "waffen";
	game["german_soldiervariation"] = "normal";

  game["attackers"] = "allies";
	game["defenders"] = "axis";
	
	game["compass_range"] = 6124;				//How far the compass is zoomed in
	game["sec_type"] = "hold";				//What type of secondary objective

 	//retrival settings
	level.obj["Code Book"] = (&"RE_OBJ_CODE_BOOK");
	level.obj["Field Radio"] = (&"RE_OBJ_FIELD_RADIO");
	game["re_attackers"] = "allies";
	game["re_defenders"] = "axis";
	game["re_attackers_obj_text"] = (&"GMI_MP_RE_OBJ_FOY_ATTACKER");
	game["re_defenders_obj_text"] = (&"GMI_MP_RE_OBJ_FOY_DEFENDER");
	game["re_spectator_obj_text"] = (&"GMI_MP_RE_OBJ_FOY_SPECTATOR");
	game["re_attackers_intro_text"] = (&"GMI_MP_RE_OBJ_FOY_SPAWN_ATTACKER");
	game["re_defenders_intro_text"] = (&"GMI_MP_RE_OBJ_FOY_SPAWN_DEFENDER");

	// FOR BUILDING PAK FILES ONLY
	if (getcvar("fs_copyfiles") == "1")
	{
		precacheShader(game["dom_layoutimage"]);
		precacheShader(game["ctf_layoutimage"]);
		precacheShader(game["bas_layoutimage"]);
		precacheShader(game["layoutimage"]);
		precacheShader(game["hud_allies_victory_image"]);
		precacheShader(game["hud_axis_victory_image"]);
	}

	//block any map exploits
	fixExploits();

}

vehicle_spawner()      // Spawns in sets of tanks dependent upon gametype.
{
        level.vehicles = getentarray ("script_vehicle","classname");
        
        // GMI game modes
	if (getcvar("g_gametype") == "dom")
	{
	        for (i=0;i<level.vehicles.size;i++)
	        {
	            if ((level.vehicles[i].targetname == "tank_ctf") || (level.vehicles[i].targetname == "bas"))
                    {
		     level.vehicles[i] delete();
		     }
	        }
	}
        if (getcvar("g_gametype") == "ctf")
	{
	        for (i=0;i<level.vehicles.size;i++)
	        {
	            if ((level.vehicles[i].targetname == "tank_dom") || (level.vehicles[i].targetname == "bas"))
                    {
		     level.vehicles[i] delete();
		     }
	        }
	}
	if (getcvar("g_gametype") == "ttdm")
	{
	        for (i=0;i<level.vehicles.size;i++)
	        {
	            if ((level.vehicles[i].targetname == "tank_ctf") || (level.vehicles[i].targetname == "bas"))
                    {
		     level.vehicles[i] delete();
		     }
	        }
	}
	
	if (getcvar("g_gametype") == "bas")
	{
	        for (i=0;i<level.vehicles.size;i++)
	        {
	            if ((level.vehicles[i].targetname == "tank_dom") || (level.vehicles[i].targetname == "tank_ctf"))
                    {
		     level.vehicles[i] delete();
		     }
	        }
	}
	
        // IW Game Modes
     	if (getcvar("g_gametype") == "re")
	{
	        for (i=0;i<level.vehicles.size;i++)
	        {
	            if ((level.vehicles[i].targetname == "tank_ctf") || (level.vehicles[i].targetname == "bas"))
                    {
		     level.vehicles[i] delete();
		     }
	        }
	}
	if (getcvar("g_gametype") == "sd")
	{
	        for (i=0;i<level.vehicles.size;i++)
	        {
	            if ((level.vehicles[i].targetname == "tank_ctf") || (level.vehicles[i].targetname == "bas"))
                    {
		     level.vehicles[i] delete();
		     }
	        }
	}
        if (getcvar("g_gametype") == "bel")
	{
	        for (i=0;i<level.vehicles.size;i++)
	        {
	            if ((level.vehicles[i].targetname == "tank_dom") || (level.vehicles[i].targetname == "bas"))
                    {
		     level.vehicles[i] delete();
		     }
	        }
	}
        if (getcvar("g_gametype") == "hq")
	{
	        for (i=0;i<level.vehicles.size;i++)
	        {
	            if ((level.vehicles[i].targetname == "tank_dom") || (level.vehicles[i].targetname == "bas"))
                    {
		     level.vehicles[i] delete();
		     }
	        }
	}
	
	/*// NO TANKS OR JEEPS
	if (getcvar("g_gametype") == "dm")
	{
	        for (i=0;i<level.vehicles.size;i++)
	        {
		     level.vehicles[i] delete();
	        }
	}
        if (getcvar("g_gametype") == "tdm")
	{
	        for (i=0;i<level.vehicles.size;i++)
	        {
		     level.vehicles[i] delete();
	        }
	}*/
}

layout_images()
{
	game["bas_layoutimage"] = "mp_foy_bas";
	game["dom_layoutimage"] = "mp_foy_dom";
	game["ctf_layoutimage"] = "mp_foy_ctf";
	game["layoutimage"] = "mp_foy";
}

move_bases()
{
	base_movers = [];	
		
	entitytypes = getentarray();
	for(i = 0; i < entitytypes.size; i++)
	{
		if(isdefined(entitytypes[i].groupname))
		{
			if(entitytypes[i].groupname == "base_mover")
			{		
				entitytypes[i] moveto(entitytypes[i].origin+(0,0,256), 0.1,0,0);	
			}
	
		}
	}
}


fixExploits() {
//fixes by innocent bystander, www.after-hourz.com

	// Block access to player clip exploits
	//missing playerclips
	thread maps\mp\_exploit_blocker::blockBox((-5800, -14835, -15), (1,150,40));
	thread maps\mp\_exploit_blocker::blockBox((-5813, -14430, -15), (1,240,40));
	
}