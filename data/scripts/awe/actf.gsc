/*
	AWE Capture the Flag
	Objective: 	Capture the other teams flag and bring it home
	Map ends:	When one team reaches the score limit, or time limit is reached
	Respawning:	No wait

	Level requirements
	------------------
		Spawnpoints:
			classname		mp_teamdeathmatch_spawn
			All players spawn from these. The spawnpoint chosen is dependent on the current locations of teammates and enemies
			at the time of spawn. Players generally spawn behind their teammates relative to the direction of enemies. 

		Spectator Spawnpoints:
			classname		mp_teamdeathmatch_intermission
			Spectators spawn from these and intermission is viewed from these positions.
			Atleast one is required, any more and they are randomly chosen between.

	Level script requirements
	-------------------------
		Team Definitions:
			game["allies"] = "american";
			game["axis"] = "german";
			This sets the nationalities of the teams. Allies can be american, british, or russian. Axis can be german.
	
		If using minefields or exploders:
			maps\mp\_load::main();
		
	Optional level script settings
	------------------------------
		Soldier Type and Variation:
			game["american_soldiertype"] = "airborne";
			game["american_soldiervariation"] = "normal";
			game["german_soldiertype"] = "wehrmacht";
			game["german_soldiervariation"] = "normal";
			This sets what models are used for each nationality on a particular map.
			
			Valid settings:
				american_soldiertype		airborne
				american_soldiervariation	normal, winter
				
				british_soldiertype		airborne, commando
				british_soldiervariation	normal, winter
				
				russian_soldiertype		conscript, veteran
				russian_soldiervariation	normal, winter
				
				german_soldiertype		waffen, wehrmacht, fallschirmjagercamo, fallschirmjagergrey, kriegsmarine
				german_soldiervariation		normal, winter

		Layout Image:
			game["layoutimage"] = "yourlevelname";
			This sets the image that is displayed when players use the "View Map" button in game.
			Create an overhead image of your map and name it "hud@layout_yourlevelname".
			Then move it to main\levelshots\layouts. This is generally done by taking a screenshot in the game.
			Use the outsideMapEnts console command to keep models such as trees from vanishing when noclipping outside of the map.
*/

/*QUAKED mp_teamdeathmatch_spawn (0.0 0.0 1.0) (-16 -16 0) (16 16 72)
Players spawn away from enemies and near their team at one of these positions.
*/

/*QUAKED mp_teamdeathmatch_intermission (1.0 0.0 1.0) (-16 -16 -16) (16 16 16)
Intermission is randomly viewed from one of these positions.
Spectators spawn randomly at one of these positions.
*/

main()
{
//////// Added by AWE ///////
	if(getCvar("scr_actf_autoswitch")=="1")
	{
		spawnpoints = getentarray("mp_uo_spawn_allies", "classname");
		if(isdefined(spawnpoints) && spawnpoints.size)
		{
			spawnpoints = getentarray("mp_uo_spawn_axis", "classname");
			if(isdefined(spawnpoints) && spawnpoints.size)
			{
				spawnpoints = getentarray("mp_ctf_intermission", "classname");
				if(isdefined(spawnpoints) && spawnpoints.size)
				{
					setcvar("g_gametype", "ctf");
					maps\mp\gametypes\ctf::main();
					return;
				}
			}
		}
	}
///////////////////////////////

	level.flagmodel["axis"]	= "xmodel/" + cvardef("scr_actf_axis_flagmodel",	"uodropped","","","string");
	level.flagmodel["allies"]="xmodel/" + cvardef("scr_actf_allied_flagmodel",	"uodropped","","","string");
	
	level.flagmodel_dropped["axis"] 	= "xmodel/" + cvardef("scr_actf_axis_flagmodel_dropped",	"uodropped","","","string");
	level.flagmodel_dropped["allies"] 	= "xmodel/" + cvardef("scr_actf_allied_flagmodel_dropped",	"uodropped","","","string");

	level.flagname["axis"] 	= cvardef("scr_actf_axis_flagname",	"flag","","","string");
	level.flagname["allies"]= cvardef("scr_actf_allied_flagname","flag","","","string");

	spawnpointname = "mp_teamdeathmatch_spawn";
	spawnpoints = getentarray(spawnpointname, "classname");
	for(i = 0; i < spawnpoints.size; i++)
		spawnpoints[i] placeSpawnpoint();

	level.callbackStartGameType = ::Callback_StartGameType;
	level.callbackPlayerConnect = ::Callback_PlayerConnect;
	level.callbackPlayerDisconnect = ::Callback_PlayerDisconnect;
	level.callbackPlayerDamage = ::Callback_PlayerDamage;
	level.callbackPlayerKilled = ::Callback_PlayerKilled;

	maps\mp\gametypes\_callbacksetup::SetupCallbacks();
	
	allowed[0] = "tdm";
	maps\mp\gametypes\_gameobjects::main(allowed);
	
	maps\mp\gametypes\_rank_gmi::InitializeBattleRank();
	maps\mp\gametypes\_secondary_gmi::Initialize();

	// Time limit per map
	level.timelimit = cvardef("scr_actf_timelimit", 30, 0, 1440, "float");
//	setCvar("ui_actf_timelimit", level.timelimit);
//	makeCvarServerInfo("ui_actf_timelimit", "30");

	// Score limit per map
	level.scorelimit = cvardef("scr_actf_scorelimit", 5, 1, 999, "int");
//	setCvar("ui_actf_scorelimit", level.scorelimit);
//	makeCvarServerInfo("ui_actf_scorelimit", "5");

	// Flag recover time
	level.flagrecovertime = cvardef("scr_actf_flagrecovertime", 0, 0, 9999, "int");
//	setCvar("ui_actf_flagrecovertime", level.flagrecovertime);
//	makeCvarServerInfo("ui_actf_flagrecovertime", "0");

	// Score on dropped
	level.scoreondropped = cvardef("scr_actf_scoreondropped", 1, 0, 1, "int");
//	setCvar("ui_actf_scoreondropped", level.scoreondropped);
//	makeCvarServerInfo("ui_actf_scoreondropped", "0");

	// Score on dropped
	level.removeflagspawns = cvardef("scr_actf_removeflagspawns", 1, 0, 1, "int");
//	setCvar("ui_actf_removeflagspawns", level.removeflagspawns);
//	makeCvarServerInfo("ui_actf_removeflagspawns", "0");

	if(getCvar("scr_forcerespawn") == "")		// Force respawning
		setCvar("scr_forcerespawn", "0");
	
	if(getCvar("scr_teambalance") == "")		// Auto Team Balancing
		setCvar("scr_teambalance", "0");
	level.teambalance = getCvarInt("scr_teambalance");
	level.teambalancetimer = 0;
	
	if(getCvar("scr_battlerank") == "")		
		setCvar("scr_battlerank", "1");	//default is ON
	level.battlerank = getCvarint("scr_battlerank");
	setCvar("ui_battlerank", level.battlerank);
	makeCvarServerInfo("ui_battlerank", "0");

	if(getCvar("scr_shellshock") == "")		// controls whether or not players get shellshocked from grenades or rockets
		setCvar("scr_shellshock", "1");
	setCvar("ui_shellshock", getCvar("scr_shellshock"));
	makeCvarServerInfo("ui_shellshock", "0");
			
	if(!isDefined(game["compass_range"]))		// set up the compass range.
		game["compass_range"] = 1024;		
	setCvar("cg_hudcompassMaxRange", game["compass_range"]);

	if(getCvar("scr_drophealth") == "")		// Free look spectator
		setCvar("scr_drophealth", "1");

	killcam = getCvar("scr_killcam");
	if(killcam == "")				// Kill cam
		killcam = "1";
	setCvar("scr_killcam", killcam, true);
	level.killcam = getCvarInt("scr_killcam");
	
	if(getCvar("scr_drawfriend") == "")		// Draws a team icon over teammates
		setCvar("scr_drawfriend", "1");
	level.drawfriend = getCvarInt("scr_drawfriend");

	if(!isDefined(game["state"]))
		game["state"] = "playing";

	// turn off ceasefire
	level.ceasefire = 0;
	setCvar("scr_ceasefire", "0");

	level.mapended = false;
	level.healthqueue = [];
	level.healthqueuecurrent = 0;
	
	level.team["allies"] = 0;
	level.team["axis"] = 0;
	
	if(level.killcam >= 1)
		setarchive(true);
}

Callback_StartGameType()
{

////////////// Added by AWE ///////////
	maps\mp\gametypes\_awe::Callback_StartGameType();
///////////////////////////////////////

	// defaults if not defined in level script
	if(!isDefined(game["allies"]))
		game["allies"] = "american";
	if(!isDefined(game["axis"]))
		game["axis"] = "german";

	if(!isDefined(game["layoutimage"]))
		game["layoutimage"] = "default";
	layoutname = "levelshots/layouts/hud@layout_" + game["layoutimage"];
	precacheShader(layoutname);
	setCvar("scr_layoutimage", layoutname);
	makeCvarServerInfo("scr_layoutimage", "");

	// server cvar overrides
	if(getCvar("scr_allies") != "")
		game["allies"] = getCvar("scr_allies");	
	if(getCvar("scr_axis") != "")
		game["axis"] = getCvar("scr_axis");
	
//	game["menu_serverinfo"] = "serverinfo_" + getCvar("g_gametype");
	game["menu_team"] = "team_" + game["allies"] + game["axis"];
	game["menu_weapon_allies"] = "weapon_" + game["allies"];
	game["menu_weapon_axis"] = "weapon_" + game["axis"];
	game["menu_viewmap"] = "viewmap";
	game["menu_callvote"] = "callvote";
	game["menu_quickcommands"] = "quickcommands";
	game["menu_quickstatements"] = "quickstatements";
	game["menu_quickresponses"] = "quickresponses";
	game["menu_quickvehicles"] = "quickvehicles";
	game["menu_quickrequests"] = "quickrequests";

	precacheString(&"MPSCRIPT_PRESS_ACTIVATE_TO_RESPAWN");
	precacheString(&"MPSCRIPT_KILLCAM");
	precacheString(&"GMI_MP_CEASEFIRE");

//	precacheMenu(game["menu_serverinfo"]);	
	precacheMenu(game["menu_team"]);
	precacheMenu(game["menu_weapon_allies"]);
	precacheMenu(game["menu_weapon_axis"]);
	precacheMenu(game["menu_viewmap"]);
	precacheMenu(game["menu_callvote"]);
	precacheMenu(game["menu_quickcommands"]);
	precacheMenu(game["menu_quickstatements"]);
	precacheMenu(game["menu_quickresponses"]);
	precacheMenu(game["menu_quickvehicles"]);
	precacheMenu(game["menu_quickrequests"]);

	precacheShader("black");
	precacheShader("hudScoreboard_mp");
	precacheShader("gfx/hud/hud@mpflag_spectator.tga");
	precacheStatusIcon("gfx/hud/hud@status_dead.tga");
	precacheStatusIcon("gfx/hud/hud@status_connecting.tga");
	precacheItem("item_health");

	if(level.flagmodel["axis"] == "xmodel/uo")
		level.flagmodel["axis"] = "xmodel/mp_ctf_flag_ge60";
	if(level.flagmodel["axis"] == "xmodel/uodropped")
		level.flagmodel["axis"] = "xmodel/mp_ctf_flag_ge40";

	if(level.flagmodel["allies"] == "xmodel/uo")
	{
		switch(game["allies"])
		{
			case "british":
				level.flagmodel["allies"] = "xmodel/mp_ctf_flag_br60";
				break;
			case "russian":
				level.flagmodel["allies"] = "xmodel/mp_ctf_flag_ru60";
				break;
			default:
				level.flagmodel["allies"] = "xmodel/mp_ctf_flag_usa60";
				break;
		}
	}
	if(level.flagmodel["allies"] == "xmodel/uodropped")
	{
		switch(game["allies"])
		{
			case "british":
				level.flagmodel["allies"] = "xmodel/mp_ctf_flag_br40";
				break;
			case "russian":
				level.flagmodel["allies"] = "xmodel/mp_ctf_flag_ru40";
				break;
			default:
				level.flagmodel["allies"] = "xmodel/mp_ctf_flag_usa40";
				break;
		}
	}

	if(level.flagmodel_dropped["axis"] == "xmodel/uo")
		level.flagmodel_dropped["axis"] = "xmodel/mp_ctf_flag_ge60";
	if(level.flagmodel_dropped["axis"] == "xmodel/uodropped")
		level.flagmodel_dropped["axis"] = "xmodel/mp_ctf_flag_ge40";

	if(level.flagmodel_dropped["allies"] == "xmodel/uo")
	{
		switch(game["allies"])
		{
			case "british":
				level.flagmodel_dropped["allies"] = "xmodel/mp_ctf_flag_br60";
				break;
			case "russian":
				level.flagmodel_dropped["allies"] = "xmodel/mp_ctf_flag_ru60";
				break;
			default:
				level.flagmodel_dropped["allies"] = "xmodel/mp_ctf_flag_usa60";
				break;
		}
	}
	if(level.flagmodel_dropped["allies"] == "xmodel/uodropped")
	{
		switch(game["allies"])
		{
			case "british":
				level.flagmodel_dropped["allies"] = "xmodel/mp_ctf_flag_br40";
				break;
			case "russian":
				level.flagmodel_dropped["allies"] = "xmodel/mp_ctf_flag_ru40";
				break;
			default:
				level.flagmodel_dropped["allies"] = "xmodel/mp_ctf_flag_usa40";
				break;
		}
	}

	precacheModel(level.flagmodel["axis"]);
	precacheModel(level.flagmodel["allies"]);
	precacheModel(level.flagmodel_dropped["axis"]);
	precacheModel(level.flagmodel_dropped["allies"]);

	precacheShader("gfx/hud/hud@objectivegoal.dds");
	precacheShader("gfx/hud/hud@objectivegoal_up.dds");
	precacheShader("gfx/hud/hud@objectivegoal_down.dds");

	game["headicon_carrier"] = "gfx/hud/headicon@re_objcarrier.tga";
	precacheHeadIcon(game["headicon_carrier"]);
	precacheStatusIcon(game["headicon_carrier"]);
	precacheShader(game["headicon_carrier"]);

	// Setup and precache radio objectives (used to mark flags)
	game["radio_axis"] = "gfx/hud/hud@objective_german.tga";
	if (game["allies"] == "russian")
		game["radio_allies"] = "gfx/hud/hud@objective_russian.tga";
	else if (game["allies"] == "british")
		game["radio_allies"] = "gfx/hud/hud@objective_british.tga";
	else
		game["radio_allies"] = "gfx/hud/hud@objective_american.tga";

	precacheShader(game["radio_allies"]);
	precacheShader(game["radio_axis"]);
	precacheShader("gfx/hud/hud@objective_german_up.tga");
	precacheShader("gfx/hud/hud@objective_german_down.tga");
	if (game["allies"] == "russian")
	{
		precacheShader("gfx/hud/hud@objective_russian_up.tga");
		precacheShader("gfx/hud/hud@objective_russian_down.tga");
	}
	else if (game["allies"] == "british")
	{
		precacheShader("gfx/hud/hud@objective_british_up.tga");
		precacheShader("gfx/hud/hud@objective_british_down.tga");
	}
	else
	{
		precacheShader("gfx/hud/hud@objective_american_up.tga");
		precacheShader("gfx/hud/hud@objective_american_down.tga");
	}

	maps\mp\gametypes\_teams::modeltype();
	maps\mp\gametypes\_teams::precache();
	maps\mp\gametypes\_teams::scoreboard();
	maps\mp\gametypes\_teams::initGlobalCvars();
	maps\mp\gametypes\_teams::initWeaponCvars();
	maps\mp\gametypes\_teams::restrictPlacedWeapons();
	thread maps\mp\gametypes\_teams::updateGlobalCvars();
	thread maps\mp\gametypes\_teams::updateWeaponCvars();

	setClientNameMode("auto_change");
	
	thread spawnFlags();
	thread startGame();
	thread updateGametypeCvars();
}

Callback_PlayerConnect()
{
	self.statusicon = "gfx/hud/hud@status_connecting.tga";
	self waittill("begin");
	self.statusicon = "";
	self.pers["teamTime"] = 1000000;
	
	iprintln(&"MPSCRIPT_CONNECTED", self);

	lpselfnum = self getEntityNumber();
	lpGuid = self getGuid();
	logPrint("J;" + lpGuid + ";" + lpselfnum + ";" + self.name + "\n");

	// set the cvar for the map quick bind
	self setClientCvar("g_scriptQuickMap", game["menu_viewmap"]);

	if(game["state"] == "intermission")
	{
		spawnIntermission();
		return;
	}
	
	level endon("intermission");

	if(isDefined(self.pers["team"]) && self.pers["team"] != "spectator")
	{
		self setClientCvar("ui_weapontab", "1");

		if(self.pers["team"] == "allies")
		{
			self.sessionteam = "allies";
			self setClientCvar("g_scriptMainMenu", game["menu_weapon_allies"]);
		}
		else
		{
			self.sessionteam = "axis";
			self setClientCvar("g_scriptMainMenu", game["menu_weapon_axis"]);
		}
			
		if(isDefined(self.pers["weapon"]))
			spawnPlayer();
		else
		{
			spawnSpectator();

			if(self.pers["team"] == "allies")
				self openMenu(game["menu_weapon_allies"]);
			else
				self openMenu(game["menu_weapon_axis"]);
		}
	}
	else
	{
		self setClientCvar("g_scriptMainMenu", game["menu_team"]);
		self setClientCvar("ui_weapontab", "0");
		
//		if(!isDefined(self.pers["skipserverinfo"]))
//			self openMenu(game["menu_serverinfo"]);

		if(!isdefined(self.pers["team"]))
			self openMenu(game["menu_team"]);

		self.pers["team"] = "spectator";
		self.sessionteam = "spectator";

		spawnSpectator();
	}

	// start the vsay thread
	self thread maps\mp\gametypes\_teams::vsay_monitor();

	for(;;)
	{
		self waittill("menuresponse", menu, response);
		
/*		if(menu == game["menu_serverinfo"] && response == "close")
		{
			self.pers["skipserverinfo"] = true;
			self openMenu(game["menu_team"]);
		}
*/
		if(response == "open" || response == "close")
			continue;

		if(menu == game["menu_team"])
		{
			switch(response)
			{
			case "allies":
			case "axis":
			case "autoassign":
				if(response == "autoassign")
				{
					numonteam["allies"] = 0;
					numonteam["axis"] = 0;

					players = getentarray("player", "classname");
					for(i = 0; i < players.size; i++)
					{
						player = players[i];
					
						if(!isDefined(player.pers["team"]) || player.pers["team"] == "spectator" || player == self)
							continue;
			
						numonteam[player.pers["team"]]++;
					}
					
					// if teams are equal return the team with the lowest score
					if(numonteam["allies"] == numonteam["axis"])
					{
						if(getTeamScore("allies") == getTeamScore("axis"))
						{
							teams[0] = "allies";
							teams[1] = "axis";
							response = teams[randomInt(2)];
						}
						else if(getTeamScore("allies") < getTeamScore("axis"))
							response = "allies";
						else
							response = "axis";
					}
					else if(numonteam["allies"] < numonteam["axis"])
						response = "allies";
					else
						response = "axis";
					skipbalancecheck = true;
				}
				
				if(response == self.pers["team"] && (self.sessionstate == "playing" || self.sessionstate == "dead"))
				{
					if(self.pers["team"] == "allies")
					{
						self setClientCvar("g_scriptMainMenu", game["menu_weapon_allies"]);
						self openMenu(game["menu_weapon_allies"]);
					}
					else
					{
						self setClientCvar("g_scriptMainMenu", game["menu_weapon_axis"]);
						self openMenu(game["menu_weapon_axis"]);
					}				
					break;
				}
				
				//Check if the teams will become unbalanced when the player goes to this team...
				//------------------------------------------------------------------------------
				if ( (level.teambalance > 0) && (!isdefined (skipbalancecheck)) )
				{
					//Get a count of all players on Axis and Allies
					players = maps\mp\gametypes\_teams::CountPlayers();
					
					if (self.sessionteam != "spectator")
					{
						if (((players[response] + 1) - (players[self.pers["team"]] - 1)) > level.teambalance)
						{
							if (response == "allies")
							{
								if (game["allies"] == "american")
									self iprintlnbold(&"PATCH_1_3_CANTJOINTEAM_ALLIED",&"PATCH_1_3_AMERICAN");
								else if (game["allies"] == "british")
									self iprintlnbold(&"PATCH_1_3_CANTJOINTEAM_ALLIED",&"PATCH_1_3_BRITISH");
								else if (game["allies"] == "russian")
									self iprintlnbold(&"PATCH_1_3_CANTJOINTEAM_ALLIED",&"PATCH_1_3_RUSSIAN");
							}
							else
								self iprintlnbold(&"PATCH_1_3_CANTJOINTEAM_ALLIED",&"PATCH_1_3_GERMAN");
							break;
						}
					}
					else
					{
						if (response == "allies")
							otherteam = "axis";
						else
							otherteam = "allies";
						if (((players[response] + 1) - players[otherteam]) > level.teambalance)
						{
							if (response == "allies")
							{
								if (game["allies"] == "american")
									self iprintlnbold(&"PATCH_1_3_CANTJOINTEAM_ALLIED2",&"PATCH_1_3_AMERICAN");
								else if (game["allies"] == "british")
									self iprintlnbold(&"PATCH_1_3_CANTJOINTEAM_ALLIED2",&"PATCH_1_3_BRITISH");
								else if (game["allies"] == "russian")
									self iprintlnbold(&"PATCH_1_3_CANTJOINTEAM_ALLIED2",&"PATCH_1_3_RUSSIAN");
							}
							else
							{
								if (game["allies"] == "american")
									self iprintlnbold(&"PATCH_1_3_CANTJOINTEAM_AXIS",&"PATCH_1_3_AMERICAN");
								else if (game["allies"] == "british")
									self iprintlnbold(&"PATCH_1_3_CANTJOINTEAM_AXIS",&"PATCH_1_3_BRITISH");
								else if (game["allies"] == "russian")
									self iprintlnbold(&"PATCH_1_3_CANTJOINTEAM_AXIS",&"PATCH_1_3_RUSSIAN");
							}
							break;
						}
					}
				}
				skipbalancecheck = undefined;
				//------------------------------------------------------------------------------
				
				if(response != self.pers["team"] && self.sessionstate == "playing")
					self suicide();

				self notify("end_respawn");

				self.pers["team"] = response;
				self.pers["teamTime"] = (gettime() / 1000);
				self.pers["weapon"] = undefined;
				self.pers["savedmodel"] = undefined;

				// if there are weapons the user can select then open the weapon menu
				if ( maps\mp\gametypes\_teams::isweaponavailable(self.pers["team"]) )
				{
					if(self.pers["team"] == "allies")
					{
						menu = game["menu_weapon_allies"];
					}
					else
					{
						menu = game["menu_weapon_axis"];
					}
				
					self setClientCvar("ui_weapontab", "1");
					self openMenu(menu);
				}
				else
				{
					self setClientCvar("ui_weapontab", "0");
					self menu_spawn("none");
				}
		
				self setClientCvar("g_scriptMainMenu", menu);
				break;

			case "spectator":
				if(self.pers["team"] != "spectator")
				{
					self.pers["team"] = "spectator";
					self.pers["teamTime"] = 1000000;
					self.pers["weapon"] = undefined;
					self.pers["savedmodel"] = undefined;
					
					self.sessionteam = "spectator";
					self setClientCvar("g_scriptMainMenu", game["menu_team"]);
					self setClientCvar("ui_weapontab", "0");
					spawnSpectator();
				}
				break;

			case "weapon":
				if(self.pers["team"] == "allies")
					self openMenu(game["menu_weapon_allies"]);
				else if(self.pers["team"] == "axis")
					self openMenu(game["menu_weapon_axis"]);
				break;
				
			case "viewmap":
				self openMenu(game["menu_viewmap"]);
				break;

			case "callvote":
				self openMenu(game["menu_callvote"]);
				break;
			}
		}		
		else if(menu == game["menu_weapon_allies"] || menu == game["menu_weapon_axis"])
		{
			if(response == "team")
			{
				self openMenu(game["menu_team"]);
				continue;
			}
			else if(response == "viewmap")
			{
				self openMenu(game["menu_viewmap"]);
				continue;
			}
			else if(response == "callvote")
			{
				self openMenu(game["menu_callvote"]);
				continue;
			}
			
			if(!isDefined(self.pers["team"]) || (self.pers["team"] != "allies" && self.pers["team"] != "axis"))
				continue;

			weapon = self maps\mp\gametypes\_teams::restrict(response);

			if(weapon == "restricted")
			{
				self openMenu(menu);
				continue;
			}
			
			if(isDefined(self.pers["weapon"]) && self.pers["weapon"] == weapon)
				continue;
			
			menu_spawn(weapon);
		}
		else if(menu == game["menu_viewmap"])
		{
			switch(response)
			{
			case "team":
				self openMenu(game["menu_team"]);
				break;
				
			case "weapon":
				if(self.pers["team"] == "allies")
					self openMenu(game["menu_weapon_allies"]);
				else if(self.pers["team"] == "axis")
					self openMenu(game["menu_weapon_axis"]);
				break;

			case "callvote":
				self openMenu(game["menu_callvote"]);
				break;
			}
		}
		else if(menu == game["menu_callvote"])
		{
			switch(response)
			{
			case "team":
				self openMenu(game["menu_team"]);
				break;
				
			case "weapon":
				if(self.pers["team"] == "allies")
					self openMenu(game["menu_weapon_allies"]);
				else if(self.pers["team"] == "axis")
					self openMenu(game["menu_weapon_axis"]);
				break;

			case "viewmap":
				self openMenu(game["menu_viewmap"]);
				break;
			}
		}
		else if(menu == game["menu_quickcommands"])
			maps\mp\gametypes\_teams::quickcommands(response);
		else if(menu == game["menu_quickstatements"])
			maps\mp\gametypes\_teams::quickstatements(response);
		else if(menu == game["menu_quickresponses"])
			maps\mp\gametypes\_teams::quickresponses(response);
		else if(menu == game["menu_quickvehicles"])
			maps\mp\gametypes\_teams::quickvehicles(response);
		else if(menu == game["menu_quickrequests"])
			maps\mp\gametypes\_teams::quickrequests(response);
	}
}

Callback_PlayerDisconnect()
{
	//player died or went spectator
	if (isdefined(self.carrying))
		self dropFlag(undefined);

///// Added by AWE ////////
	self maps\mp\gametypes\_awe::PlayerDisconnect();
///////////////////////////

	iprintln(&"MPSCRIPT_DISCONNECTED", self);
	
	lpselfnum = self getEntityNumber();
	lpGuid = self getGuid();
	logPrint("Q;" + lpGuid + ";" + lpselfnum + ";" + self.name + "\n");
}

Callback_PlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc)
{
	if(self.sessionteam == "spectator")
		return;

	// dont take damage during ceasefire mode
	// but still take damage from ambient damage (water, minefields, fire)
	if(level.ceasefire && sMeansOfDeath != "MOD_EXPLOSIVE" && sMeansOfDeath != "MOD_WATER" && sMeansOfDeath != "MOD_TRIGGER_HURT")
		return;

	// Don't do knockback if the damage direction was not specified
	if(!isDefined(vDir))
		iDFlags |= level.iDFLAGS_NO_KNOCKBACK;

	// check for completely getting out of the damage
//	if(!(iDFlags & level.iDFLAGS_NO_PROTECTION))
	{
		if(isPlayer(eAttacker) && (self != eAttacker) && (self.pers["team"] == eAttacker.pers["team"]))
		{
///////////// Changed by AWE ///////////////
			if( level.friendlyfire == "1" && !isdefined(eAttacker.pers["awe_teamkiller"]) && !(sMeansOfDeath == "MOD_CRUSH_TANK" || sMeansOfDeath == "MOD_CRUSH_JEEP") )
////////////////////////////////////////////
			{
				// Make sure at least one point of damage is done
				if(iDamage < 1)
					iDamage = 1;
////////////// Added by AWE /////////////
				eAttacker maps\mp\gametypes\_awe::teamdamage(self, iDamage);
/////////////////////////////////////////
				self finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc);
////////////// Added by AWE //////////////////
				self maps\mp\gametypes\_awe::DoPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc);
//////////////////////////////////////////////
			}
////////////// Changed by AWE /////////
			else if(level.friendlyfire == "0" && !(sMeansOfDeath == "MOD_CRUSH_TANK" || sMeansOfDeath == "MOD_CRUSH_JEEP"))
///////////////////////////////////////
			{
				return;
			}
////////////// Changed by AWE /////////
			else if( (level.friendlyfire == "2" && !(sMeansOfDeath == "MOD_CRUSH_TANK" || sMeansOfDeath == "MOD_CRUSH_JEEP")) || isdefined(eAttacker.pers["awe_teamkiller"]))
///////////////////////////////////////
			{
				eAttacker.friendlydamage = true;
		
				iDamage = iDamage * .5;
		
				// Make sure at least one point of damage is done
				if(iDamage < 1)
					iDamage = 1;
		
				eAttacker finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc);
				eAttacker.friendlydamage = undefined;
				
				friendly = true;
			}
////////////// Changed by AWE /////////
			else if(level.friendlyfire == "3" || sMeansOfDeath == "MOD_CRUSH_TANK" || sMeansOfDeath == "MOD_CRUSH_JEEP" )
///////////////////////////////////////
			{
				eAttacker.friendlydamage = true;
		
				iDamage = iDamage * .5;
		
				// Make sure at least one point of damage is done
				if(iDamage < 1)
					iDamage = 1;

				self finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc);
				eAttacker finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc);
				eAttacker.friendlydamage = undefined;
				
				friendly = true;
			}
		}
		else
		{
			// Make sure at least one point of damage is done
			if(iDamage < 1)
				iDamage = 1;

			self finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc);
////////////// Added by AWE //////////////////
			self maps\mp\gametypes\_awe::DoPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc);
//////////////////////////////////////////////
		}
	}

	self maps\mp\gametypes\_shellshock_gmi::DoShellShock(sWeapon, sMeansOfDeath, sHitLoc, iDamage);

	// Do debug print if it's enabled
	if(getCvarInt("g_debugDamage"))
	{
		println("client:" + self getEntityNumber() + " health:" + self.health +
			" damage:" + iDamage + " hitLoc:" + sHitLoc);
	}

	if(self.sessionstate != "dead")
	{
		lpselfnum = self getEntityNumber();
		lpselfname = self.name;
		lpselfteam = self.pers["team"];
		lpselfGuid = self getGuid();
		lpattackerteam = "";

		if(isPlayer(eAttacker))
		{
			lpattacknum = eAttacker getEntityNumber();
			lpattackGuid = eAttacker getGuid();
			lpattackname = eAttacker.name;
			lpattackerteam = eAttacker.pers["team"];
		}
		else
		{
			lpattacknum = -1;
			lpattackGuid = "";
			lpattackname = "";
			lpattackerteam = "world";
		}

		if(isDefined(friendly)) 
		{  
			lpattacknum = lpselfnum;
			lpattackname = lpselfname;
			lpattackGuid = lpselfGuid;
		}
		
		logPrint("D;" + lpselfGuid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackGuid + ";" + lpattacknum + ";" + lpattackerteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");
	}
}

Callback_PlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc)
{
	self endon("spawned");
	
	if (isdefined(self.carrying))
		self dropFlag(sMeansOfDeath);

	if(self.sessionteam == "spectator")
		return;

/////////// Added by AWE ///////////
	self thread maps\mp\gametypes\_awe::PlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc);
////////////////////////////////////

	// If the player was killed by a head shot, let players know it was a head shot kill
	if(sHitLoc == "head" && sMeansOfDeath != "MOD_MELEE")
		sMeansOfDeath = "MOD_HEAD_SHOT";
		
	// if this is a melee kill from a binocular then make sure they know that they are a loser
	if(sMeansOfDeath == "MOD_MELEE" && (sWeapon == "binoculars_artillery_mp" || sWeapon == "binoculars_mp") )
	{
		sMeansOfDeath = "MOD_MELEE_BINOCULARS";
	}
	
	// if this is a kill from the artillery binocs change the icon
	if(sMeansOfDeath != "MOD_MELEE_BINOCULARS" && sWeapon == "binoculars_artillery_mp" )
		sMeansOfDeath = "MOD_ARTILLERY";

	// send out an obituary message to all clients about the kill
////////// Removed by AWE ///////
//	obituary(self, attacker, sWeapon, sMeansOfDeath);
/////////////////////////////////
	
	self.sessionstate = "dead";
	self.statusicon = "gfx/hud/hud@status_dead.tga";
	self.headicon = "";
	if (!isdefined (self.autobalance))
		self.deaths++;

	lpselfnum = self getEntityNumber();
	lpselfname = self.name;
	lpselfguid = self getGuid();
	lpselfteam = self.pers["team"];
	lpattackerteam = "";

	attackerNum = -1;
	if(isPlayer(attacker))
	{
		if(attacker == self) // killed himself
		{
			doKillcam = false;
			if (!isdefined (self.autobalance))
				attacker.score--;
			
			if(isDefined(attacker.friendlydamage))
				clientAnnouncement(attacker, &"MPSCRIPT_FRIENDLY_FIRE_WILL_NOT"); 
		}
		else
		{
			attackerNum = attacker getEntityNumber();
			doKillcam = true;

			if(self.pers["team"] == attacker.pers["team"]) // killed by a friendly
			{
				attacker.score--;
////// Added by AWE ////////
				attacker maps\mp\gametypes\_awe::teamkill();
////////////////////////////
			}
			else
			{
				attacker.score++;

//				teamscore = getTeamScore(attacker.pers["team"]);
//				teamscore++;
//				setTeamScore(attacker.pers["team"], teamscore);

//				checkScoreLimit();
			}
		}

		lpattacknum = attacker getEntityNumber();
		lpattackguid = attacker getGuid();
		lpattackname = attacker.name;
		lpattackerteam = attacker.pers["team"];
	}
	else // If you weren't killed by a player, you were in the wrong place at the wrong time
	{
		doKillcam = false;
		
		self.score--;

		lpattacknum = -1;
		lpattackname = "";
		lpattackguid = "";
		lpattackerteam = "world";
	}

	logPrint("K;" + lpselfguid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackguid + ";" + lpattacknum + ";" + lpattackerteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");

	// Stop thread if map ended on this death
	if(level.mapended)
		return;

	// Make the player drop his weapon
///// Removed by AWE /////
//	self dropItem(self getcurrentweapon());
//////////////////////////
	
	// Make the player drop health
	self dropHealth();
	self.autobalance = undefined;
///// Removed by AWE /////
//	body = self cloneplayer();
//////////////////////////

	delay = 2;	// Delay the player becoming a spectator till after he's done dying
	wait delay;	// ?? Also required for Callback_PlayerKilled to complete before respawn/killcam can execute

	if((getCvarInt("scr_killcam") <= 0) || (getCvarInt("scr_forcerespawn") > 0))
		doKillcam = false;
	
	if(doKillcam)
		self thread killcam(attackerNum, delay);
	else
		self thread respawn();
}

// ----------------------------------------------------------------------------------
//	menu_spawn
//
// 		called from the player connect to spawn the player
// ----------------------------------------------------------------------------------
menu_spawn(weapon)
{
	if(!isDefined(self.pers["weapon"]))
	{
		self.pers["weapon"] = weapon;
		spawnPlayer();
		self thread printJoinedTeam(self.pers["team"]);
	}
	else
	{
		self.pers["weapon"] = weapon;

		weaponname = maps\mp\gametypes\_teams::getWeaponName(self.pers["weapon"]);
		
		if(maps\mp\gametypes\_teams::useAn(self.pers["weapon"]))
			self iprintln(&"MPSCRIPT_YOU_WILL_RESPAWN_WITH_AN", weaponname);
		else
			self iprintln(&"MPSCRIPT_YOU_WILL_RESPAWN_WITH_A", weaponname);
	}
	if (isdefined (self.autobalance_notify))
		self.autobalance_notify destroy();
}

spawnPlayer()
{
	self notify("spawned");
	self notify("end_respawn");
	
	resettimeout();

	self.sessionteam = self.pers["team"];
	self.sessionstate = "playing";
	self.spectatorclient = -1;
	self.archivetime = 0;
	self.friendlydamage = undefined;
	
	spawnpointname = "mp_teamdeathmatch_spawn";
	spawnpoints = getentarray(spawnpointname, "classname");
	// If no alive team mates (except me), spawn near base	
	if(alivePlayers(self.sessionteam)<2)
		spawnpoint = maps\mp\gametypes\_spawnlogic::NearestSpawnpoint(spawnpoints, level.flag[self.sessionteam]["marker"].origin);
	else		// Use TDM spawnlogic
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam(spawnpoints);

	if(isDefined(spawnpoint))
		spawnpoint maps\mp\gametypes\_spawnlogic::SpawnPlayer(self);
	else
		maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");

	self.statusicon = "";
	self.maxhealth = 100;
	self.health = self.maxhealth;

	if(isdefined(self.flagindicator))
		self.flagindicator destroy();
	
	self.pers["rank"] = maps\mp\gametypes\_rank_gmi::DetermineBattleRank(self);
	self.rank = self.pers["rank"];

	if(!isDefined(self.pers["savedmodel"]))
		maps\mp\gametypes\_teams::model();
	else
		maps\mp\_utility::loadModel(self.pers["savedmodel"]);

	// setup all the weapons
	self maps\mp\gametypes\_loadout_gmi::PlayerSpawnLoadout();

	alliesObj = "AWE Capture the " + level.flagname["axis"] + "\n\nGet the " + level.flagname["axis"] + " from the axis and bring it to your own " + level.flagname["allies"] + ".";
	axisObj = "AWE Capture the " + level.flagname["allies"] + "\n\nGet the " + level.flagname["allies"] + " from the allies and bring it to your own " + level.flagname["axis"] + ".";

	if(self.pers["team"] == "allies")
		self setClientCvar("cg_objectiveText", alliesObj);
	else if(self.pers["team"] == "axis")
		self setClientCvar("cg_objectiveText", axisObj);

	if(level.drawfriend)
	{
		if(level.battlerank)
		{
			self.statusicon = maps\mp\gametypes\_rank_gmi::GetRankStatusIcon(self);
			self.headicon = maps\mp\gametypes\_rank_gmi::GetRankHeadIcon(self);
			self.headiconteam = self.pers["team"];
		}
		else
		{
			if(self.pers["team"] == "allies")
			{
				self.headicon = game["headicon_allies"];
				self.headiconteam = "allies";
			}
			else
			{
				self.headicon = game["headicon_axis"];
				self.headiconteam = "axis";
			}
		}
	}
	else if(level.battlerank)
	{
		self.statusicon = maps\mp\gametypes\_rank_gmi::GetRankStatusIcon(self);
	}	

	// setup the hud rank indicator
	self thread maps\mp\gametypes\_rank_gmi::RankHudInit();

	// Check for flags thread
	self thread checkForFlags();

//////////// Added  by AWE ////////
	self maps\mp\gametypes\_awe::spawnPlayer();
///////////////////////////////////

}

spawnSpectator(origin, angles)
{
	self notify("spawned");
	self notify("end_respawn");

	resettimeout();

	self.sessionstate = "spectator";
	self.spectatorclient = -1;
	self.archivetime = 0;
	self.friendlydamage = undefined;

	if(self.pers["team"] == "spectator")
		self.statusicon = "";
	
	if(isDefined(origin) && isDefined(angles))
		self spawn(origin, angles);
	else
	{
		spawnpointname = "mp_teamdeathmatch_intermission";
		spawnpoints = getentarray(spawnpointname, "classname");

		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnpoints);
	
		if(isDefined(spawnpoint))
			self spawn(spawnpoint.origin, spawnpoint.angles);
		else
			maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");
	}
	
	Obj = "AWE Capture the " + level.flagname["axis"] + "\n\nGet the " + level.flagname["axis"] + " from the enemy and bring it to your own " + level.flagname["allies"] + ".";
	self setClientCvar("cg_objectiveText", Obj);
}

spawnIntermission()
{
	self notify("spawned");
	self notify("end_respawn");

	resettimeout();

	self.sessionstate = "intermission";
	self.spectatorclient = -1;
	self.archivetime = 0;
	self.friendlydamage = undefined;

	spawnpointname = "mp_teamdeathmatch_intermission";
	spawnpoints = getentarray(spawnpointname, "classname");

	spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnpoints);
	
	if(isDefined(spawnpoint))
		self spawn(spawnpoint.origin, spawnpoint.angles);
	else
		maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");
}

respawn()
{
	if(!isDefined(self.pers["weapon"]))
		return;
	
	self endon("end_respawn");
	
	if(getCvarInt("scr_forcerespawn") > 0)
	{
		self thread waitForceRespawnTime();
		self thread waitRespawnButton();
		self waittill("respawn");
	}
	else
	{
		self thread waitRespawnButton();
		self waittill("respawn");
	}
	
	self thread spawnPlayer();
}

waitForceRespawnTime()
{
	self endon("end_respawn");
	self endon("respawn");
	
	wait getCvarInt("scr_forcerespawn");
	self notify("respawn");
}

waitRespawnButton()
{
	self endon("end_respawn");
	self endon("respawn");
	
	wait 0; // Required or the "respawn" notify could happen before it's waittill has begun

	if ( getcvar("scr_forcerespawn") == "1" )
		return;

	self.respawntext = newClientHudElem(self);
	self.respawntext.alignX = "center";
	self.respawntext.alignY = "middle";
	self.respawntext.x = 320;
	self.respawntext.y = 70;
	self.respawntext.archived = false;
	self.respawntext setText(&"MPSCRIPT_PRESS_ACTIVATE_TO_RESPAWN");

	thread removeRespawnText();
	thread waitRemoveRespawnText("end_respawn");
	thread waitRemoveRespawnText("respawn");

	while(self useButtonPressed() != true)
		wait .05;
	
	self notify("remove_respawntext");

	self notify("respawn");	
}

removeRespawnText()
{
	self waittill("remove_respawntext");

	if(isDefined(self.respawntext))
		self.respawntext destroy();
}

waitRemoveRespawnText(message)
{
	self endon("remove_respawntext");

	self waittill(message);
	self notify("remove_respawntext");
}

killcam(attackerNum, delay)
{
	self endon("spawned");

//	previousorigin = self.origin;
//	previousangles = self.angles;
	
	// killcam
	if(attackerNum < 0)
		return;

	self.sessionstate = "spectator";
	self.spectatorclient = attackerNum;
	self.archivetime = delay + 7;

	// wait till the next server frame to allow code a chance to update archivetime if it needs trimming
	wait 0.05;

	if(self.archivetime <= delay)
	{
		self.spectatorclient = -1;
		self.archivetime = 0;
		self.sessionstate = "dead";
	
		self thread respawn();
		return;
	}

	if(!isDefined(self.kc_topbar))
	{
		self.kc_topbar = newClientHudElem(self);
		self.kc_topbar.archived = false;
		self.kc_topbar.x = 0;
		self.kc_topbar.y = 0;
		self.kc_topbar.alpha = 0.5;
		self.kc_topbar setShader("black", 640, 112);
	}

	if(!isDefined(self.kc_bottombar))
	{
		self.kc_bottombar = newClientHudElem(self);
		self.kc_bottombar.archived = false;
		self.kc_bottombar.x = 0;
		self.kc_bottombar.y = 368;
		self.kc_bottombar.alpha = 0.5;
		self.kc_bottombar setShader("black", 640, 112);
	}

	if(!isDefined(self.kc_title))
	{
		self.kc_title = newClientHudElem(self);
		self.kc_title.archived = false;
		self.kc_title.x = 320;
		self.kc_title.y = 40;
		self.kc_title.alignX = "center";
		self.kc_title.alignY = "middle";
		self.kc_title.sort = 1; // force to draw after the bars
		self.kc_title.fontScale = 3.5;
	}
	self.kc_title setText(&"MPSCRIPT_KILLCAM");

	if ( getcvar("scr_forcerespawn") != "1" )
	{
		if(!isDefined(self.kc_skiptext))
		{
			self.kc_skiptext = newClientHudElem(self);
			self.kc_skiptext.archived = false;
			self.kc_skiptext.x = 320;
			self.kc_skiptext.y = 70;
			self.kc_skiptext.alignX = "center";
			self.kc_skiptext.alignY = "middle";
			self.kc_skiptext.sort = 1; // force to draw after the bars
		}
		self.kc_skiptext setText(&"MPSCRIPT_PRESS_ACTIVATE_TO_RESPAWN");
	}

	if(!isDefined(self.kc_timer))
	{
		self.kc_timer = newClientHudElem(self);
		self.kc_timer.archived = false;
		self.kc_timer.x = 320;
		self.kc_timer.y = 428;
		self.kc_timer.alignX = "center";
		self.kc_timer.alignY = "middle";
		self.kc_timer.fontScale = 3.5;
		self.kc_timer.sort = 1;
	}
	self.kc_timer setTenthsTimer(self.archivetime - delay);

	self thread spawnedKillcamCleanup();
	self thread waitSkipKillcamButton();
	self thread waitKillcamTime();
	self waittill("end_killcam");

	self removeKillcamElements();

	self.spectatorclient = -1;
	self.archivetime = 0;
	self.sessionstate = "dead";

	//self thread spawnSpectator(previousorigin + (0, 0, 60), previousangles);
	self thread respawn();
}

waitKillcamTime()
{
	self endon("end_killcam");
	
	wait(self.archivetime - 0.05);
	self notify("end_killcam");
}

waitSkipKillcamButton()
{
	self endon("end_killcam");
	
	while(self useButtonPressed())
		wait .05;

	while(!(self useButtonPressed()))
		wait .05;
	
	self notify("end_killcam");	
}

removeKillcamElements()
{
	if(isDefined(self.kc_topbar))
		self.kc_topbar destroy();
	if(isDefined(self.kc_bottombar))
		self.kc_bottombar destroy();
	if(isDefined(self.kc_title))
		self.kc_title destroy();
	if(isDefined(self.kc_skiptext))
		self.kc_skiptext destroy();
	if(isDefined(self.kc_timer))
		self.kc_timer destroy();
}

spawnedKillcamCleanup()
{
	self endon("end_killcam");

	self waittill("spawned");
	self removeKillcamElements();
}

startGame()
{
	level.starttime = getTime();
	
	if(level.timelimit > 0)
	{
		level.clock = newHudElem();
		level.clock.x = 320;
		level.clock.y = 460;
		level.clock.alignX = "center";
		level.clock.alignY = "middle";
		level.clock.font = "bigfixed";
		level.clock setTimer(level.timelimit * 60);
	}
	
	for(;;)
	{
		checkTimeLimit();
		wait 1;
	}
}

endMap()
{
////// Added by AWE ///////////
	maps\mp\gametypes\_awe::endMap();
/////////////////////////////////

	game["state"] = "intermission";
	level notify("intermission");
	
	alliedscore = getTeamScore("allies");
	axisscore = getTeamScore("axis");
	
	if(alliedscore == axisscore)
	{
		winningteam = "tie";
		losingteam = "tie";
		text = "MPSCRIPT_THE_GAME_IS_A_TIE";
	}
	else if(alliedscore > axisscore)
	{
		winningteam = "allies";
		losingteam = "axis";
		text = &"MPSCRIPT_ALLIES_WIN";
	}
	else
	{
		winningteam = "axis";
		losingteam = "allies";
		text = &"MPSCRIPT_AXIS_WIN";
	}
	
	if((winningteam == "allies") || (winningteam == "axis"))
	{
		winners = "";
		losers = "";
	}
	
	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if((winningteam == "allies") || (winningteam == "axis"))
		{
			lpGuid = player getGuid();
			if((isDefined(player.pers["team"])) && (player.pers["team"] == winningteam))
					winners = (winners + ";" + lpGuid + ";" + player.name);
			else if((isDefined(player.pers["team"])) && (player.pers["team"] == losingteam))
					losers = (losers + ";" + lpGuid + ";" + player.name);
		}
		player closeMenu();
		player setClientCvar("g_scriptMainMenu", "main");
		player setClientCvar("cg_objectiveText", text);
		player spawnIntermission();
	}
	
	if((winningteam == "allies") || (winningteam == "axis"))
	{
		logPrint("W;" + winningteam + winners + "\n");
		logPrint("L;" + losingteam + losers + "\n");
	}
	
	wait 10;
	exitLevel(false);
}

checkTimeLimit()
{
	if(level.timelimit <= 0)
		return;
	
	timepassed = (getTime() - level.starttime) / 1000;
	timepassed = timepassed / 60.0;
	
	if(timepassed < level.timelimit)
		return;
	
	if(level.mapended)
		return;
	level.mapended = true;

	iprintln(&"MPSCRIPT_TIME_LIMIT_REACHED");
	level thread endMap();
}

checkScoreLimit()
{
	if(level.scorelimit <= 0)
		return;
	
	if(getTeamScore("allies") < level.scorelimit && getTeamScore("axis") < level.scorelimit)
		return;

	if(level.mapended)
		return;
	level.mapended = true;

	iprintln(&"MPSCRIPT_SCORE_LIMIT_REACHED");
	level thread endMap();
}

updateGametypeCvars()
{
	for(;;)
	{
		ceasefire = getCvarint("scr_ceasefire");

		// if we are in cease fire mode display it on the screen
		if (ceasefire != level.ceasefire)
		{
			level.ceasefire = ceasefire;
			if ( ceasefire )
			{
				level thread maps\mp\_util_mp_gmi::make_permanent_announcement(&"GMI_MP_CEASEFIRE", "end ceasefire", 220, (1.0,0.0,0.0));			
			}
			else
			{
				level notify("end ceasefire");
			}
		}

		// check all the players for rank changes
		if ( getCvarint("scr_battlerank") )
			maps\mp\gametypes\_rank_gmi::CheckPlayersForRankChanges();

		timelimit = cvardef("scr_actf_timelimit", 30, 0, 1440, "float");
		if(level.timelimit != timelimit)
		{
			level.timelimit = timelimit;
//			setCvar("ui_ctf_timelimit", level.timelimit);
			level.starttime = getTime();
			
			if(level.timelimit > 0)
			{
				if(!isDefined(level.clock))
				{
					level.clock = newHudElem();
					level.clock.x = 320;
					level.clock.y = 440;
					level.clock.alignX = "center";
					level.clock.alignY = "middle";
					level.clock.font = "bigfixed";
				}
				level.clock setTimer(level.timelimit * 60);
			}
			else
			{
				if(isDefined(level.clock))
					level.clock destroy();
			}
			
			checkTimeLimit();
		}

		// Score limit per map
		scorelimit = cvardef("scr_actf_scorelimit", 5, 1, 999, "int");
		if(level.scorelimit != scorelimit)
		{
			level.scorelimit = scorelimit;
//			setCvar("ui_ctf_scorelimit", level.scorelimit);
		}
		checkScoreLimit();

		// Flag recover time
		flagrecovertime = cvardef("scr_actf_flagrecovertime", 0, 0, 9999, "int");
		if(level.flagrecovertime != flagrecovertime)
		{
			level.flagrecovertime = flagrecovertime;
//			setCvar("ui_ctf_flagrecovertime", level.flagrecovertime);
		}	

		// Score on dropped
		scoreondropped = cvardef("scr_actf_scoreondropped", 1, 0, 1, "int");
		if(level.scoreondropped != scoreondropped)
		{
			level.scoreondropped = scoreondropped;
//			setCvar("ui_ctf_scoreondropped", level.scoreondropped);
		}	

		drawfriend = getCvarint("scr_drawfriend");
		battlerank = getCvarint("scr_battlerank");
		if(level.battlerank != battlerank || level.drawfriend != drawfriend)
		{
			level.drawfriend = drawfriend;
			level.battlerank = battlerank;
			
			// battle rank has precidence over draw friend
			if(level.battlerank)
			{
				// for all living players, show the appropriate headicon
				players = getentarray("player", "classname");
				for(i = 0; i < players.size; i++)
				{
					player = players[i];
					
					if(isDefined(player.pers["team"]) && player.pers["team"] != "spectator" && player.sessionstate == "playing")
					{
						// setup the hud rank indicator
						player thread maps\mp\gametypes\_rank_gmi::RankHudInit();

						player.statusicon = maps\mp\gametypes\_rank_gmi::GetRankStatusIcon(player);
						if ( level.drawfriend )
						{
							player.headicon = maps\mp\gametypes\_rank_gmi::GetRankHeadIcon(player);
							player.headiconteam = player.pers["team"];
						}
						else
						{
							player.headicon = "";
						}
					}
				}
			}
			else if(level.drawfriend)
			{
				// for all living players, show the appropriate headicon
				players = getentarray("player", "classname");
				for(i = 0; i < players.size; i++)
				{
					player = players[i];
					
					if(isDefined(player.pers["team"]) && player.pers["team"] != "spectator" && player.sessionstate == "playing")
					{
						if(player.pers["team"] == "allies")
						{
							player.headicon = game["headicon_allies"];
							player.headiconteam = "allies";
				
						}
						else
						{
							player.headicon = game["headicon_axis"];
							player.headiconteam = "axis";
						}
						
						player.statusicon = "";
					}
				}
			}
			else
			{
				players = getentarray("player", "classname");
				for(i = 0; i < players.size; i++)
				{
					player = players[i];
					
					if(isDefined(player.pers["team"]) && player.pers["team"] != "spectator" && player.sessionstate == "playing")
					{
						player.headicon = "";
						player.statusicon = "";
					}
				}
			}
		}

		killcam = getCvarInt("scr_killcam");
		if (level.killcam != killcam)
		{
			level.killcam = getCvarInt("scr_killcam");
			if(level.killcam >= 1)
				setarchive(true);
			else
				setarchive(false);
		}
		
		teambalance = getCvarInt("scr_teambalance");
		if (level.teambalance != teambalance)
		{
			level.teambalance = getCvarInt("scr_teambalance");
			if (level.teambalance > 0)
			{
				level thread maps\mp\gametypes\_teams::TeamBalance_Check();
				level.teambalancetimer = 0;
			}
		}
		
		if (level.teambalance > 0)
		{
			level.teambalancetimer++;
			if (level.teambalancetimer >= 60)
			{
				level thread maps\mp\gametypes\_teams::TeamBalance_Check();
				level.teambalancetimer = 0;
			}
		}
		
		wait 1;
	}
}

printJoinedTeam(team)
{
	if(team == "allies")
		iprintln(&"MPSCRIPT_JOINED_ALLIES", self);
	else if(team == "axis")
		iprintln(&"MPSCRIPT_JOINED_AXIS", self);
}

// ----------------------------------------------------------------------------------
//	dropHealth
// ----------------------------------------------------------------------------------
dropHealth()
{
	if ( !getcvarint("scr_drophealth") )
		return;
		
//// Added by AWE ////
	if(isdefined(self.awe_nohealthpack))
		return;
	self.awe_nohealthpack = true;
//////////////////////

	if(isDefined(level.healthqueue[level.healthqueuecurrent]))
		level.healthqueue[level.healthqueuecurrent] delete();
	
	level.healthqueue[level.healthqueuecurrent] = spawn("item_health", self.origin + (0, 0, 1));
	level.healthqueue[level.healthqueuecurrent].angles = (0, randomint(360), 0);

	level.healthqueuecurrent++;
	
	if(level.healthqueuecurrent >= 16)
		level.healthqueuecurrent = 0;
}

getFlagPoint(team)
{
	if(!isdefined(level.flagpoint))
	{
		spawnpointname = "mp_teamdeathmatch_spawn";
		spawnpoints = getentarray(spawnpointname, "classname");
		maxdist = 0;
		level.flagpoint["axis"] = spawnpoints[0];
		level.flagpoint["allies"] = spawnpoints[0];
		for(i=0;i<spawnpoints.size;i++)
		{
			for(j=0;j<spawnpoints.size;j++)
			{
				if(i==j) continue;
				dist = distance(spawnpoints[i].origin,spawnpoints[j].origin);
				if(dist>maxdist)
				{
					maxdist = dist;
					level.flagpoint["axis"] = spawnpoints[i];
					level.flagpoint["allies"] = spawnpoints[j];
				}
			}
		}
		// 50% chance on swapping sides
		if(randomInt(2))
		{
			temp = level.flagpoint["axis"];
			level.flagpoint["axis"] = level.flagpoint["allies"];
			level.flagpoint["allies"] = temp;
		}
	}
	return level.flagpoint[team];
}


findGround(position)
{
	trace=bulletTrace(position+(0,0,10),position+(0,0,-1200),false,undefined);
	ground=trace["position"];
	return ground;
}

spawnFlags()
{
	level.flag = [];

	//spawn markers

	mapname = getcvar("mapname");

	level.flag["allies"]["marker"] = getent("allies_flag_home","targetname");
	if(!isdefined(level.flag["allies"]["marker"]))
	{
		x = getcvar("scr_actf_allied_home_x_" + mapname);
		y = getcvar("scr_actf_allied_home_y_" + mapname);
		z = getcvar("scr_actf_allied_home_z_" + mapname);
		a = getcvar("scr_actf_allied_home_a_" + mapname);

		if(x != "" && y != "" && z != "" && a != "")
		{
			position = (x,y,z);
			angles = (0,a,0);
		}
		else
		{
			flagpoint = getFlagPoint("allies");
			position = flagpoint.origin;
			angles = flagpoint.angles;
		}

		offset = (0,0,0);
		if(level.flagmodel["allies"] == "xmodel/stalingrad_flag")
		{
			angles = (-90,angles[1],angles[2]);
			offset = (0,0,17);
		}

		level.flag["allies"]["marker"] = spawn("script_model", findGround(position) + offset);
		level.flag["allies"]["marker"].targetname = "allies_flag_home";
		level.flag["allies"]["marker"].angles = angles;
		level.flag["allies"]["marker"] hide();
	}

	level.flag["axis"]["marker"] = getent("axis_flag_home","targetname");
	if(!isdefined(level.flag["axis"]["marker"]))
	{
		x = getcvar("scr_actf_axis_home_x_" + mapname);
		y = getcvar("scr_actf_axis_home_y_" + mapname);
		z = getcvar("scr_actf_axis_home_z_" + mapname);
		a = getcvar("scr_actf_axis_home_a_" + mapname);

		if(x != "" && y != "" && z != "" && a != "")
		{
			position = (x,y,z);
			angles = (0,a,0);
		}
		else
		{
			flagpoint = getFlagPoint("axis");
			position = flagpoint.origin;
			angles = flagpoint.angles;
		}	

		offset = (0,0,0);
		if(level.flagmodel["axis"] == "xmodel/stalingrad_flag")
		{
			angles = (-90,angles[1],angles[2]);
			offset = (0,0,17);
		}

		level.flag["axis"]["marker"] = spawn("script_model", findGround(position) + offset);
		level.flag["axis"]["marker"].targetname = "axis_flag_home";
		level.flag["axis"]["marker"].angles = angles;
		level.flag["axis"]["marker"] hide();
	}

	level.flag["allies"]["marker"].objnum = 0;
	level.flag["axis"]["marker"].objnum = 1;

	// Remove spawns on flag points
	if(level.removeflagspawns)
	{
		spawnpointname = "mp_teamdeathmatch_spawn";
		spawnpoints = getentarray(spawnpointname, "classname");
		for(i=0;i<spawnpoints.size;i++)
		{
			if(spawnpoints[i] == getFlagPoint("axis"))
				spawnpoints[i] delete();
			if(spawnpoints[i] == getFlagPoint("allies"))
				spawnpoints[i] delete();
		}
	}

	wait 0.05;

	returnflag("allies");
	returnflag("axis");

	wait 1;	// TEMP: without this one of the objective icon is the default. Carl says we're overflowing something.

	objective_add(level.flag["allies"]["marker"].objnum, "current", level.flag["allies"]["marker"].origin, "gfx/hud/hud@objectivegoal.dds");
	objective_team(level.flag["allies"]["marker"].objnum, "allies");

	objective_add(level.flag["axis"]["marker"].objnum, "current", level.flag["axis"]["marker"].origin, "gfx/hud/hud@objectivegoal.dds");
	objective_team(level.flag["axis"]["marker"].objnum, "axis");
}

returnflag(team)
{
	angles = level.flag[team]["marker"].angles;
	offset = (0,0,0);
	if(level.flagmodel[team] == "xmodel/stalingrad_flag")
	{
		angles = (-90,angles[1],angles[2]);
		offset = (0,0,17);
	}

	dropFlagAt(team, level.flag[team]["marker"].origin + offset, angles);
	level.flag[team]["flag"].angles = angles;
	level.flag[team]["flag"] setModel(level.flagmodel[team]);
	level.flag[team]["flag"].athome = true;
	level.flag[team]["flag"] notify("returned");
}

checkForFlags()
{
	// Kill dupes
	self notify("checkforflags");
	self endon("checkforflags");

	level endon("intermission");

	// What is my team?
	myteam = self.sessionteam;
	if(myteam == "allies")
		otherteam = "axis";
	else
		otherteam = "allies";
	
	while (isAlive(self) && self.sessionstate=="playing" && myteam == self.sessionteam) 
	{
		// Check for my my flag if I am carrying the enemyflag, and it exists and it is not being stolen and (it is at home or score on dropped is allowed)
		if(isdefined(self.carrying) && isdefined(level.flag[myteam]["flag"]) && !isdefined(level.flag[myteam]["flag"].stolen) && (isdefined(level.flag[myteam]["flag"].athome) || level.scoreondropped) )
		{
			// Am I touching it?
			if(self isTouchingFlag(myteam))
			{
				self.carrying = undefined;
				self.objnum = undefined;

				// Restore head and status icon
/*				if(level.drawfriend == 1)
				{
					if(level.battlerank)
							self.headicon = maps\mp\gametypes\_rank_gmi::GetRankHeadIcon(self);
					else
						self.headicon = game["headicon_" + myteam];
					self.headiconteam = myteam;
				}
				self.statusicon = "";*/

				if(level.drawfriend)
				{
					if(level.battlerank)
					{
						self.statusicon = maps\mp\gametypes\_rank_gmi::GetRankStatusIcon(self);
						self.headicon = maps\mp\gametypes\_rank_gmi::GetRankHeadIcon(self);
					}
					else
					{
						self.statusicon = "";
						self.headicon = game["headicon_" + myteam];
					}
					self.headiconteam = myteam;
				}
				else
				{
					if(level.battlerank)
					{
						self.headicon = "";
						self.statusicon = maps\mp\gametypes\_rank_gmi::GetRankStatusIcon(self);
					}	
					else
					{
						self.headicon = "";
						self.statusicon = "";
					}
				}

				if(isdefined(self.flagindicator))
					self.flagindicator destroy();

				// Get personal score
				self.score += 3;

				// Get team score
				teamscore = getTeamScore(myteam);
				teamscore++;
				setTeamScore(myteam, teamscore);
				checkScoreLimit();

				// Bring it home?
				if(!isdefined(level.flag[myteam]["flag"].athome))
					returnFlag(myteam);

				// Return enemy flag
				returnFlag(otherteam);

				// Announce score
				self announce("^7scored for the " + game[myteam] + " team!");
				level thread playsound_onplayers("hq_score");

				// Write log entry
				lpselfnum = self getEntityNumber();
				lpselfguid = self getGuid();
				logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + myteam + ";" + self.name + ";" + "actf_score" + "\n");
			}
		}

		// Does my flag exist but is not at home?
		if(isdefined(level.flag[myteam]["flag"]) && !isdefined(level.flag[myteam]["flag"].athome) )
		{
			// Am I touching it?
			if(self isTouchingFlag(myteam))
			{
				// Bring it home
				returnFlag(myteam);
			
				self announce("^7returned the " + game[myteam] + " " + level.flagname[myteam] + "^7!");
				self playsound("car_door_close");

				if(!level.scoreondropped)
				{
					// Get personal score
					self.score += 1;

					lpselfnum = self getEntityNumber();
					lpselfguid = self getGuid();
					logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + myteam + ";" + self.name + ";" + "actf_return" + "\n");
				}
			}
		}

		// Does other teams flag exist and is not currently being stolen?
		if(isdefined(level.flag[otherteam]["flag"]) && !isdefined(level.flag[otherteam]["flag"].stolen) )
		{
			// Am I touching it and it is not currently being stolen?
			if(self isTouchingFlag(otherteam) && !isdefined(level.flag[otherteam]["flag"].stolen) )
			{
				level.flag[otherteam]["flag"].stolen = true;
		
				// Steal enemy flag
				self.carrying = true;
				self.objnum = level.flag[otherteam]["flag"].objnum;
/*				self.statusicon = game["headicon_carrier"];
				self.headicon = game["headicon_carrier"];
				if(getCvar("scr_actf_showcarrier") == "0")
					self.headiconteam = myteam;
				else
					self.headiconteam = "none";*/

				self.flagindicator = newClientHudElem(self);	
				self.flagindicator.x = 600;
				self.flagindicator.y = 410;
				self.flagindicator.alpha = 0.65;
				self.flagindicator.alignX = "center";
				self.flagindicator.alignY = "middle";
				self.flagindicator setShader(game["headicon_carrier"],40,40);

				objective_delete(level.flag[otherteam]["flag"].objnum);
				level.flag[otherteam]["flag"] delete();

				self announce("^7stole the " + game[otherteam] + " " + level.flagname[otherteam] + "^7!");
				self playsound("truck_door_open");

				// Get personal score
				self.score += 1;

				lpselfnum = self getEntityNumber();
				lpselfguid = self getGuid();
				logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + myteam + ";" + self.name + ";" + "actf_stole" + "\n");
			}
		}

		if(isdefined(self.carrying))
		{
			self.statusicon = game["headicon_carrier"];
			self.headicon = game["headicon_carrier"];
			if(getCvar("scr_actf_showcarrier") == "0")
				self.headiconteam = myteam;
			else
				self.headiconteam = "none";
		}

		wait 0.2;		
	}

	//player died or went spectator
	if (isdefined(self.carrying))
		self dropFlag(undefined);
}

dropFlag(sMeansOfDeath)
{
	ground = findGround(self.origin);

	// What is my team?
	myteam = self.sessionteam;
	if(myteam == "allies")
		otherteam = "axis";
	else
		otherteam = "allies";

	// Check if player died in a minefield
	minefields = getentarray( "minefield", "targetname" );
	if( minefields.size > 0 )
	{
		for( i = 0; i < minefields.size; i++ )
		{
			if( minefields[i] istouching( self ) )
			{
				touching = true;
				break;
			}
		}
	}
		
	// If player died in minefield or was killed by a trigger, replace flag
	if( isdefined(touching) || (isdefined(sMeansOfDeath) && sMeansOfDeath == "MOD_TRIGGER_HURT") )
	{
		returnflag(otherteam);
		iprintlnbold("The " + game[otherteam] + " " + level.flagname[otherteam] + " was automaticly returned.");
		self.carrying = undefined;	
		self.objnum = undefined;
	}
	else
	{
		dropFlagAt(otherteam, ground, self.angles);
		level.flag[otherteam]["flag"].athome = undefined;
		if(level.flagrecovertime)
			level.flag[otherteam]["flag"] thread autoReturnFlag(otherteam);
		self.carrying = undefined;	
		self.objnum = undefined;
	
		self announce("^7dropped the " + game[otherteam] + " " + level.flagname[otherteam] + "^7!");
	}

	// Restore head and status icon
/*	if(level.drawfriend == 1)
	{
		self.headicon = game["headicon_" + myteam];
		self.headiconteam = myteam;
	}
	self.statusicon = "";*/

	if(level.drawfriend)
	{
		if(level.battlerank)
		{
			self.statusicon = maps\mp\gametypes\_rank_gmi::GetRankStatusIcon(self);
			self.headicon = maps\mp\gametypes\_rank_gmi::GetRankHeadIcon(self);
		}
		else
		{
			self.statusicon = "";
			self.headicon = game["headicon_" + myteam];
		}
		self.headiconteam = myteam;
	}
	else
	{
		if(level.battlerank)
		{
			self.headicon = "";
			self.statusicon = maps\mp\gametypes\_rank_gmi::GetRankStatusIcon(self);
		}	
		else
		{
			self.headicon = "";
			self.statusicon = "";
		}
	}

	if(isdefined(self.flagindicator))
		self.flagindicator destroy();
}

autoReturnFlag(team)
{
	self endon("returned");
	
	wait level.flagrecovertime;
	
	returnflag(team);	
	iprintlnbold("The " + game[team] + " " + level.flagname[team] + " was automaticly returned.");
}

dropFlagAt(team, origin, angles)
{
	if( isdefined(level.flag[team]["flag"]) )
		level.flag[team]["flag"] delete();

	offset = (0,0,0);
	if(level.flagmodel_dropped[team] == "xmodel/stalingrad_flag")
	{
		angles = (angles[0],angles[1],90);
		offset = (0,0,1);
	}

	level.flag[team]["flag"] = spawn("script_model", origin + offset);
	level.flag[team]["flag"].targetname = team + "_flag";
	level.flag[team]["flag"] setmodel( level.flagmodel_dropped[team] );
	level.flag[team]["flag"].angles = angles;
	level.flag[team]["flag"].objnum = level.flag[team]["marker"].objnum + 2;
	level.flag[team]["flag"] show();

	objective_add(level.flag[team]["flag"].objnum, "current", origin, game["radio_" + team]);
}

isTouchingFlag(team)
{
	if(distance(self.origin, level.flag[team]["flag"].origin) < 50)
		return true;
	else
		return false;
}

announce(what)
{
	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		if(players[i] == self)
			players[i] iprintlnbold("You " + what);
		else if(isPlayer(players[i]))
			players[i] iprintln(self.name + " " + what);
	}
}

/*
USAGE OF "cvardef"
cvardef replaces the multiple lines of code used repeatedly in the setup areas of the script.
The function requires 5 parameters, and returns the set value of the specified cvar
Parameters:
	varname - The name of the variable, i.e. "scr_teambalance", or "scr_dem_respawn"
		This function will automatically find map-sensitive overrides, i.e. "src_dem_respawn_mp_brecourt"

	vardefault - The default value for the variable.  
		Numbers do not require quotes, but strings do.  i.e.   10, "10", or "wave"

	min - The minimum value if the variable is an "int" or "float" type
		If there is no minimum, use "" as the parameter in the function call

	max - The maximum value if the variable is an "int" or "float" type
		If there is no maximum, use "" as the parameter in the function call

	type - The type of data to be contained in the vairable.
		"int" - integer value: 1, 2, 3, etc.
		"float" - floating point value: 1.0, 2.5, 10.384, etc.
		"string" - a character string: "wave", "player", "none", etc.
*/

cvardef(varname, vardefault, min, max, type)
{
	mapname = getcvar("mapname");		// "mp_dawnville", "mp_rocket", etc.
	gametype = getcvar("g_gametype");	// "tdm", "bel", etc.

//	if(getcvar(varname) == "")		// if the cvar is blank
//		setcvar(varname, vardefault); // set the default

	tempvar = varname + "_" + gametype;	// i.e., scr_teambalance becomes scr_teambalance_tdm
	if(getcvar(tempvar) != "") 		// if the gametype override is being used
		varname = tempvar; 		// use the gametype override instead of the standard variable

	tempvar = varname + "_" + mapname;	// i.e., scr_teambalance becomes scr_teambalance_mp_dawnville
	if(getcvar(tempvar) != "")		// if the map override is being used
		varname = tempvar;		// use the map override instead of the standard variable


	// get the variable's definition
	switch(type)
	{
		case "int":
			if(getcvar(varname) == "")		// if the cvar is blank
				definition = vardefault;	// set the default
			else
				definition = getcvarint(varname);
			break;
		case "float":
			if(getcvar(varname) == "")	// if the cvar is blank
				definition = vardefault;	// set the default
			else
				definition = getcvarfloat(varname);
			break;
		case "string":
		default:
			if(getcvar(varname) == "")		// if the cvar is blank
				definition = vardefault;	// set the default
			else
				definition = getcvar(varname);
			break;
	}

	// if it's a number, with a minimum, that violates the parameter
	if((type == "int" || type == "float") && min != "" && definition < min)
		definition = min;

	// if it's a number, with a maximum, that violates the parameter
	if((type == "int" || type == "float") && max != "" && definition > max)
		definition = max;

	return definition;
}

playsound_onplayers(sound)
{
	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		if((isDefined(players[i].pers["team"])) && (players[i].pers["team"] != "spectator"))
			players[i] playLocalSound(sound);
	}
}

alivePlayers(team)
{
	allplayers = getentarray("player", "classname");
	alive = [];
	for(i = 0; i < allplayers.size; i++)
	{
		if(allplayers[i].sessionstate == "playing" && allplayers[i].sessionteam == team)
			alive[alive.size] = allplayers[i];
	}
	return alive.size;
}