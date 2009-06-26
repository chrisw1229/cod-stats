main()
{
	//setExpFog (0.00002, .72, .59, .63, 0 );
	//setCullFog (0, 16500, 0.7, 0.85, 1.0, 0);
	setExpFog (0.00002, 0.7, 0.85, 1.0, 0 );

	// set the nighttime flag to be off
	setcvar("sv_night", "0" );

	ambientPlay("ambient_day");
	maps\mp\mp_rhinevalley::layout_images();
	maps\mp\mp_rhinevalley::vehicle_spawner();
	//maps\mp\mp_rhinevalley::base_swapper();  

	maps\mp\_load::main();
	maps\mp\_flak_gmi::main();
	level thread maps\mp\_tankdrive_gmi::main();
	level thread maps\mp\_jeepdrive_gmi::main();

	game["allies"] = "american";
	game["axis"] = "german";
	game["compass_range"] = 12500;	
	game["sec_type"] = "hold";				//What type of secondary objective

	//Search & Destroy Settings
	game["attackers"] = "axis";
	game["defenders"] = "allies";

	game["hud_allies_victory_image"]= "gfx/hud/hud@mp_victory_rhinevalley_us.dds";
	game["hud_axis_victory_image"] = "gfx/hud/hud@mp_victory_rhinevalley_g.dds";

		
      //Retrival Settings
	level.obj["Code Book"] = (&"RE_OBJ_CODE_BOOK");
	level.obj["Field Radio"] = (&"RE_OBJ_FIELD_RADIO");
	game["re_attackers"] = "allies";
	game["re_defenders"] = "axis";
	game["re_attackers_obj_text"] = (&"GMI_MP_RE_OBJ_RHINEVALLEY_ATTACKER");
	game["re_defenders_obj_text"] = (&"GMI_MP_RE_OBJ_RHINEVALLEY_DEFENDER");
	game["re_spectator_obj_text"] = (&"GMI_MP_RE_OBJ_RHINEVALLEY_SPECTATOR");
	game["re_attackers_intro_text"] = (&"GMI_MP_RE_OBJ_RHINEVALLEY_SPAWN_ATTACKER");
	game["re_defenders_intro_text"] = (&"GMI_MP_RE_OBJ_RHINEVALLEY_SPAWN_DEFENDER");

	//Domination Settings
	//There must be a set of the following for each flag in your map.
	flag1 = getent("flag1","targetname");			// identifies the flag you're setting up
	flag1.script_timer = 10;					// how many seconds a capture takes with one player
	flag1.description = (&"GMI_DOM_FLAG1_MP_RHINEVALLEY");	// the name of the flag (localized in gmi_mp.str)

      flag2 = getent("flag2","targetname");
	flag2.script_timer = 15;
	flag2.description = (&"GMI_DOM_FLAG2_MP_RHINEVALLEY");

      flag3 = getent("flag3","targetname");
	flag3.script_timer = 20;
	flag3.description = (&"GMI_DOM_FLAG3_MP_RHINEVALLEY");

      flag4 = getent("flag4","targetname");
	flag4.script_timer = 15;
	flag4.description = (&"GMI_DOM_FLAG4_MP_RHINEVALLEY");

      flag5 = getent("flag5","targetname");
	flag5.script_timer = 10;
	flag5.description = (&"GMI_DOM_FLAG5_MP_RHINEVALLEY");

//	-------------------------------------------	
	//	BASE ASSAULT SETUP
//	The following 3 lines added by Number 7
//	-------------------------------------------	
	if(getCvar("scr_bas_basehealth") == "")
		setCvar("scr_bas_basehealth", "24500");

	setCvar("scr_bas_basehealth", getCvarInt("scr_bas_basehealth"));
//	-------------------------------------------	

	setCvar("scr_bas_damagedhealth", getCvarInt("scr_bas_basehealth")/2);
	game["bas_allies_rubble"] 	= "xmodel/mp_bunker_rhinevalley_rubble";
	game["bas_allies_complete"] 	= "xmodel/mp_bunker_rhinevalley";
	game["bas_allies_damaged"] 	= "xmodel/mp_bunker_rhinevalley_predmg";
	game["bas_allies_destroyed"] 	= "xmodel/mp_bunker_rhinevalley_dmg";
	game["bas_axis_rubble"] 	= "xmodel/mp_bunker_rhinevalley_rubble";
	game["bas_axis_complete"] 	= "xmodel/mp_bunker_rhinevalley";
	game["bas_axis_damaged"] 	= "xmodel/mp_bunker_rhinevalley_predmg";
	game["bas_axis_destroyed"] 	= "xmodel/mp_bunker_rhinevalley_dmg";
//	-------------------------------------------	

      maps\mp\_util_mp_gmi::base_swapper();
      
	//base_mover();
	//vehicle_spawner();
	//base_swapper();  

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


vehicle_spawner()      // Spawns in number of vehicles dependent upon gametype.
{
	defcon = 0;
  vehicles = getentarray ("script_vehicle","classname");
	gametype = getcvar("g_gametype");

	println("^1Num of vehicles: "+vehicles.size);

	switch(gametype)
	{
		// GMI modes
		case "dom": defcon = 2;break;
		case "ctf": defcon = 1;break;
		case "bas": defcon = 4;break;
		case "ttdm": defcon = 3;break;
		// IW modes
		case "tdm": defcon = 1;break;
		case "dm": defcon = 1;break;
		case "bel": defcon = 0;break;
		case "sd": defcon = 1;break;
		case "re": defcon = 1;break;
		case "hq": defcon = 1;break;
	}

      for (i=5;i>defcon;i--)
	{
	      for (v=0;v<vehicles.size;v++)
	      {
		      if (isdefined(vehicles[v].script_idnumber) && vehicles[v].script_idnumber == i)
      		      {
					vehicles[v] delete();
				}
		}
	}
}

base_mover()
{
	level.base = getentarray("gmi_base","targetname");
	if (isdefined(level.base))
	{
		for (b=0;b<level.base.size;b++)
		{	
			level.base[b] thread move_to_target();
		}	
	}
}

move_to_target()
{
	self.targeted = getentarray(self.target, "targetname");
	for (a=0;a<self.targeted.size;a++)
	{
		if (isdefined(self.targeted[a].classname) && !isdefined(self.moved_to_ent))
		{
			if (self.targeted[a].classname == "script_origin")
			{
				self.origin = self.targeted[a].origin;
				self.moved_to_ent = a;
			}
		}
	}
}

base_swapper()
{
	gametype = getcvar("g_gametype");
	if(gametype != "bas")
	{
		level.base = getentarray("gmi_base","targetname");
		if (isdefined(level.base))
		{
			for (b=0;b<level.base.size;b++)
			{	
				level.base[b] thread swap_in_base_dmg();
			}	
		}
	}
}

swap_in_base_dmg()
{
	if (isdefined(self.script_damagemodel))
	{
		self.destroyedmodel = spawn("script_model", self.origin);
		self.destroyedmodel.angles = self.angles;
		self.destroyedmodel setmodel(self.script_damagemodel);
	}
}

layout_images()
{
	game["bas_layoutimage"] = "mp_rhinevalley_bas";
	game["dom_layoutimage"] = "mp_rhinevalley_dom";
	game["ctf_layoutimage"] = "mp_rhinevalley_ctf";
	game["layoutimage"] = "mp_rhinevalley";
	
}

fixExploits() {
//fix by innocent bystander, www.after-hourz.com

	// Block roofs in town for linux
	level thread maps\mp\_exploit_blocker::blockBox((-4074,-8204,2329), (60,1,40));
	level thread maps\mp\_exploit_blocker::blockBox((-4126,-8177,2300), (1,65,80));
	level thread maps\mp\_exploit_blocker::blockBox((-4300,-7282,2295), (1,350,40));
}