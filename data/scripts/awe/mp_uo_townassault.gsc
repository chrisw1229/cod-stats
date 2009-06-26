main()  
{  
   setCullFog (256, 4864, .32, .36, .40, 0);  
   ambientPlay("ambient_mp_dawnville");  

   maps\mp\_load::main();  
   maps\mp\mp_uo_townassault::layout_images();
   maps\mp\_flak_gmi::main();

   game["cnq_initialobjective"] = 0;  
   setcvar ("scr_hqradio", "6");  

	level thread maps\mp\_tankdrive_gmi::main();
	level thread maps\mp\_jeepdrive_gmi::main();

	game["hud_allies_victory_image"] 	= "gfx/hud/hud@mp_victory_ta_us.dds";
	game["hud_axis_victory_image"] 		= "gfx/hud/hud@mp_victory_ta_g.dds";

// ------------------------------------------- 
// BASE ASSAULT SETUP

	if(getCvar("scr_bas_basehealth") == "")  
  	setCvar("scr_bas_basehealth", "14000");  
 	setCvar("scr_bas_basehealth", getCvarInt("scr_bas_basehealth"));
	setCvar("scr_bas_damagedhealth", getCvarInt("scr_bas_basehealth")/2);
	
	game["bas_allies_rubble"] = "xmodel/mp_bunker_italy_rubble";
	game["bas_allies_complete"] = "xmodel/mp_bunker_italy";
	game["bas_allies_damaged"] = "xmodel/mp_bunker_italy_predmg";
	game["bas_allies_destroyed"] = "xmodel/mp_bunker_italy_dmg";
	game["bas_axis_rubble"] = "xmodel/mp_bunker_italy_rubble";
	game["bas_axis_complete"] = "xmodel/mp_bunker_italy";
	game["bas_axis_damaged"] = "xmodel/mp_bunker_italy_predmg";
	game["bas_axis_destroyed"] = "xmodel/mp_bunker_italy_dmg";
	// ------------------------------------------- 

  maps\mp\_util_mp_gmi::base_swapper();       
  game["allies"] = "american";  
  game["axis"] = "german";  
  
  game["american_soldiertype"] = "airborne";  
  game["american_soldiervariation"] = "normal";  
  game["german_soldiertype"] = "fallschirmjagercamo";  
  game["german_soldiervariation"] = "normal";  

	game["compass_range"] = 6124; //How far the compass is zoomed in
	game["sec_type"] = "hold"; //What type of secondary objective
  
  level._effect["dawnville_smoke"] = loadfx ("fx/smoke/dawnville_smoke3.efx");  
  level._effect["panzer1_smoke"] = loadfx ("fx/smoke/dawnville_smoke3.efx");  
  level._effect["sherman1_smoke"] = loadfx ("fx/smoke/dawnville_smoke3.efx");  
  level._effect["kubel_smoke"] = loadfx ("fx/smoke/slow_steam.efx");  
  
  maps\mp\_fx::loopfx("dawnville_smoke", (-700, 10952, 0), 0.1);  
  maps\mp\_fx::loopfx("panzer1_smoke", (-3992, 16912, 40), 0.1);  
  maps\mp\_fx::loopfx("sherman1_smoke", (-2068, 42204, 48), 0.1);  
  maps\mp\_fx::loopfx("kubel_smoke", (-6392, 17636, 38), 0.1);  
  
  game["attackers"] = "allies";  
  game["defenders"] = "axis";  

	move_bases();

	// FOR BUILDING PAK FILES ONLY
	if (getcvar("fs_copyfiles") == "1") {
		precacheShader(game["layoutimage"]);
		precacheShader(game["hud_allies_victory_image"]);
		precacheShader(game["hud_axis_victory_image"]);
	}
 
 fixBugs();
  
} 

move_bases() {

	base_movers = []; 

	entitytypes = getentarray();
	for(i = 0; i < entitytypes.size; i++) {
		if(isdefined(entitytypes[i].groupname)) {
			if(entitytypes[i].groupname == "base_mover") { 
				entitytypes[i] moveto(entitytypes[i].origin+(0,0,256), 0.1,0,0); 
			}
		}
	}
}

layout_images() {
	game["bas_layoutimage"] = "mp_uo_townassault_bas";
	game["ctf_layoutimage"] = "mp_uo_townassault_ctf";
	game["cnq_layoutimage"] = "mp_uo_townassault_cnq";
  game["layoutimage"] = "mp_uo_townassault";
}

fixBugs() {
	
	//remove an extra tdm spawn outside the play area
 	if ((getcvar("g_gametype") == "tdm") || (getcvar("g_gametype") == "bel") || (getcvar("g_gametype") == "hq") ) {
	
		spawnpoints = getentarray("mp_teamdeathmatch_spawn", "classname");
		for(i = 0; i < spawnpoints.size; i++) {
			entno = spawnpoints[i] getEntityNumber();
			if (entno == 499) {
				spawnpoints[i] delete();
				break;
			}
		}

		wait 0.1; // a frame for the server to catch up...
	
  }
  	
  //add block wall for missing player clip
  level thread blockBox((-90,13625,230), (10,200,200));	

	//add some thin ones to block a angled missing clip	
	level thread blockBox((-4423,4544,100), (15,15,80));	
	level thread blockBox((-4470,4570,100), (15,15,80));	
  level thread blockBox((-4525,4620,100), (15,15,80));	
  level thread blockBox((-4575,4670,100), (15,15,80));	
	level thread blockBox((-4620,4700,100), (15,15,80));	

}


blockBox(origin,size)
{
	blocker = spawn("script_origin", origin);
	blocker setbounds( ((0,0,0)-size), size );
	blocker setcontents(1);

	if(getcvar("g_exploit_debug") == "1")
	{
		x = size[0];
		y = size[1];
		z = size[2];
		for(;;)
		{
			line(origin + (0-x,  y,  z), origin + (  x,  y,  z), (1,0,0));
			line(origin + (0-x,  y,0-z), origin + (  x,  y,0-z), (1,0,0));
			line(origin + (0-x,  y,  z), origin + (0-x,  y,0-z), (1,0,0));
			line(origin + (  x,  y,  z), origin + (  x,  y,0-z), (1,0,0));

			line(origin + (0-x,0-y,  z), origin + (  x,0-y,  z), (0,1,0));
			line(origin + (0-x,0-y,0-z), origin + (  x,0-y,0-z), (0,1,0));
			line(origin + (0-x,0-y,  z), origin + (0-x,0-y,0-z), (0,1,0));
			line(origin + (  x,0-y,  z), origin + (  x,0-y,0-z), (0,1,0));

			line(origin + (0-x,  y,  z), origin + (0-x,0-y,  z), (0,0,1));
			line(origin + (  x,  y,  z), origin + (  x,0-y,  z), (0,0,1));
			line(origin + (0-x,  y,0-z), origin + (0-x,0-y,0-z), (0,0,1));
			line(origin + (  x,  y,0-z), origin + (  x,0-y,0-z), (0,0,1));

			line(origin + (0-x,0-y,  z), origin + (  x,  y,0-z), (1,0,1));
			line(origin + (0-x,  y,  z), origin + (  x,0-y,0-z), (1,0,1));
			line(origin + (  x,0-y,  z), origin + (0-x,  y,0-z), (1,0,1));
			line(origin + (  x,  y,  z), origin + (0-x,0-y,0-z), (1,0,1));

			wait .05;
		}
	}
}