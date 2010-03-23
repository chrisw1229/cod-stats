/*
	Super Flag Tag FUBAR
	Objective: 	Score points for your team by tagging the flag for your team
	Map ends:	When one team reaches the score limit, or time limit is reached
	Respawning:	No wait / At base spawn points based on team

	Level requirements
	------------------
		Spawnpoints:
			classname		mp_teamdeathmatch_spawn
                        targetname              mp_uo_spawn_axis, mp_uo_spawn_allies
			All players spawn from these. The spawpoint is chosen based on team.

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
	// Get flagmodels
	level.flagmodel		= "xmodel/" + cvardef("scr_ftf_flagmodel",		"cow_standing","","","string");
	level.flagmodel_dropped	= "xmodel/" + cvardef("scr_ftf_flagmodel_dropped",	"cow_dead","","","string");
	level.flagname	 	= cvardef("scr_ftf_flagname",	"cow","","","string");

	spawnpointname = "mp_teamdeathmatch_spawn";
	spawnpoints = getentarray(spawnpointname, "classname");
	
	if(!spawnpoints.size)
	{
		maps\mp\gametypes\_callbacksetup::AbortLevel();
		return;
	}

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
	level.timelimit = cvardef("scr_ftf_timelimit",20,0,1440,"float");
//	setCvar("ui_ftf_timelimit", level.timelimit);
//	makeCvarServerInfo("ui_ftf_timelimit", "20");

	// Score limit per map
	level.scorelimit = cvardef("scr_ftf_scorelimit",10,0,9999,"int");
//	setCvar("ui_ftf_scorelimit", level.scorelimit);
//	makeCvarServerInfo("ui_ftf_scorelimit", "5");

	// Balance mode
	level.mode = cvardef("scr_ftf_mode", 3, 0, 3, "int");

	// Max hold time
	level.holdtime = cvardef("scr_ftf_holdtime", 90, 1, 99999, "int");
	level.teamholdtime["axis"] = 0;
	level.teamholdtime["allies"] = 0;
	level.oldteamholdtime["allies"] = level.teamholdtime["allies"];
	level.oldteamholdtime["axis"] = level.teamholdtime["axis"];

	// Flag spawn delay
	level.flagspawndelay = cvardef("scr_ftf_flagspawndelay", 20, 0, 9999, "int");

	// Flag recover time
	level.flagrecovertime = cvardef("scr_ftf_flagrecovertime", 10, 0, 9999, "int");

	// Remove spawnpoint which is used by the flag?
	level.removeflagspawns = cvardef("scr_ftf_removeflagspawns", 1, 0, 1, "int");

	// Respawn wait time
	level.respawntime = cvardef("scr_ftf_respawntime", 0, 0, 60, "int");

	// Force respawning
	level.forcerespawn = cvardef("scr_forcerespawn",0,0,60,"int");
	
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
/////////////// Added by AWE ////////////////////
	level.awe_teamplay = true;
	level.awe_roundbased = undefined;
	level.awe_alternatehud = undefined;
	level.awe_spawnalliedname = "mp_teamdeathmatch_spawn";
	level.awe_spawnaxisname	= "mp_teamdeathmatch_spawn";
	level.awe_spawnspectatorname = "mp_teamdeathmatch_intermission";
/////////////////////////////////////////////////

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

    logPrint("Game;" + getCvar("g_gametype") + ";" + getCvar("mapname") + ";" + level.timelimit + ";" + game["allies"] + ";" + game["axis"] + "\n");

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
	precacheShader("white");
	precacheShader("hudScoreboard_mp");
	precacheShader("gfx/hud/hud@mpflag_spectator.tga");
	precacheStatusIcon("gfx/hud/hud@status_dead.tga");
	precacheStatusIcon("gfx/hud/hud@status_connecting.tga");
	precacheItem("item_health");

	// Precache flags
	precacheModel(level.flagmodel);

	if(level.flagmodel_dropped == "xmodel/uodropped")
	{
		precacheModel("xmodel/mp_ctf_flag_ge40");
		switch(game["allies"])
		{
			case "british":
				precacheModel("xmodel/mp_ctf_flag_br40");
				break;
			case "russian":
				precacheModel("xmodel/mp_ctf_flag_ru40");
				break;
			default:
				precacheModel("xmodel/mp_ctf_flag_usa40");
				break;
		}
	}
	else 	if(level.flagmodel_dropped == "xmodel/uo")
	{
		precacheModel("xmodel/mp_ctf_flag_ge60");
		switch(game["allies"])
		{
			case "british":
				precacheModel("xmodel/mp_ctf_flag_br60");
				break;
			case "russian":
				precacheModel("xmodel/mp_ctf_flag_ru60");
				break;
			default:
				precacheModel("xmodel/mp_ctf_flag_usa60");
				break;
		}
	}
	else
	{
		precacheModel(level.flagmodel_dropped);
	}

	// Precache objective
	game["flag"] = "gfx/hud/objective.dds";
	precacheShader("gfx/hud/objective.dds");
	precacheShader("gfx/hud/objective_up.dds");
	precacheShader("gfx/hud/objective_down.dds");

	game["flagspawn"] = "gfx/hud/hud@objective_bel.dds";
	precacheShader("gfx/hud/hud@objective_bel.dds");
	precacheShader("gfx/hud/hud@objective_bel_up.dds");
	precacheShader("gfx/hud/hud@objective_bel_down.dds");

	// Precache headicons
	switch( game["allies"])
		{
		case "british":
			game["headicon_carrier_allies"] = "gfx/hud/headicon@ctf_british.dds";
			game["statusicon_carrier_allies"] = "gfx/hud/hud@ctf_british.dds";
			break;
		case "russian":
			game["headicon_carrier_allies"] = "gfx/hud/headicon@ctf_russian.dds";
			game["statusicon_carrier_allies"] = "gfx/hud/hud@ctf_russian.dds";
			break;
		default:		// default is american
			game["headicon_carrier_allies"] = "gfx/hud/headicon@ctf_american.dds";
			game["statusicon_carrier_allies"] = "gfx/hud/hud@ctf_american.dds";
			break;
	}

	game["headicon_carrier_axis"] = "gfx/hud/headicon@ctf_german.dds";
	game["statusicon_carrier_axis"] = "gfx/hud/hud@ctf_german.dds";

	// Use standard "star" instead?
	if(!cvardef("scr_ftf_flagicons", 1, 0, 1, "int"))
	{
		game["headicon_carrier_allies"] = "gfx/hud/headicon@re_objcarrier.tga";
		game["headicon_carrier_axis"] = "gfx/hud/headicon@re_objcarrier.tga";
		game["statusicon_carrier_allies"] = "gfx/hud/headicon@re_objcarrier.tga";
		game["statusicon_carrier_axis"] = "gfx/hud/headicon@re_objcarrier.tga";
	}

	precacheHeadIcon(game["headicon_carrier_allies"]);
	precacheHeadIcon(game["headicon_carrier_axis"]);
	precacheStatusIcon(game["statusicon_carrier_axis"]);
	precacheStatusIcon(game["statusicon_carrier_allies"]);
	precacheShader(game["headicon_carrier_axis"]);
	precacheShader(game["headicon_carrier_allies"]);

	// Setup and precachfe radio objectives (used to mark flagcarriers)
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

	// Precache stopwatch
	precacheShader("hudStopwatch");
	precacheShader("hudStopwatchNeedle");

	maps\mp\gametypes\_teams::modeltype();
	maps\mp\gametypes\_teams::precache();

	precacheShader(game["headicon_allies"]);
	precacheShader(game["headicon_axis"]);

	maps\mp\gametypes\_teams::scoreboard();
	maps\mp\gametypes\_teams::initGlobalCvars();
	maps\mp\gametypes\_teams::initWeaponCvars();
	maps\mp\gametypes\_teams::restrictPlacedWeapons();
	thread maps\mp\gametypes\_teams::updateGlobalCvars();
	thread maps\mp\gametypes\_teams::updateWeaponCvars();

	setClientNameMode("auto_change");
	
	thread returnFlag();
	thread startGame();
	//thread addBotClients(); // For development testing
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

	for(;;)
	{
		self waittill("menuresponse", menu, response);
		
/*		if(menu == game["menu_serverinfo"] && response == "close")
		{
			self.pers["skipserverinfo"] = true;
			self openMenu(game["menu_team"]);
		}*/

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

				self finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc);
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
	
	flagcarrier = undefined;
	if(isdefined(self.carrying))
	{
		self dropFlag(sMeansOfDeath);
		flagcarrier = true;
	}

	if(self.sessionteam == "spectator")
		return;

	if(!isdefined(self.autobalance))
	{
		body = self cloneplayer();
		self dropItem(self getcurrentweapon());
	}

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
//// Changed by AWE ///
	if(!isdefined(level.awe_uo))
		obituary(self, attacker, sWeapon, sMeansOfDeath);
///////////////////////
	
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
    vPos = self.origin;
    vAngle = self.angles[1];
    vStance = self getStance();

	attackerNum = -1;
	if(isPlayer(attacker))
	{
		lpattacknum = attacker getEntityNumber();
		lpattackguid = attacker getGuid();
		lpattackname = attacker.name;
		lpattackerteam = attacker.pers["team"];
        aPos = attacker.origin;
        aAngle = attacker.angles[1];
        aStance = attacker getStance();

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
				// Was the flagcarrier killed?
				if(isdefined(flagcarrier))
				{
					attacker announce("^1teamkilled ^7the " + level.flagname + " carrier^7!");
					attacker.score -= 15;
				}
			}
			else
			{
				// Add bonus points for jeep kills
				if (!calculateScoreBonus(attacker)) {

					// Regular kills still get one point
					attacker.score++;
				}

				// Was the flagcarrier killed?
				if(isdefined(flagcarrier))
				{
					attacker announce("^7killed the " + level.flagname + " carrier^7!");
					attacker.score += 5;
				}

                // Log actions if applicable
                if (isDefined(attacker.carrying)
                        || (self is_near_carrier(attacker.pers["team"]))) {

                    // Victim was near attacker's carrier teammate (attacker defended)
                    lpaction = getCvar("g_gametype") + "_defended";
                    logPrint("A;" + lpattackguid + ";" + lpattacknum + ";" + attacker.pers["team"] + ";" + attacker.name + ";" + lpaction + ";" + aPos[0] + "," + aPos[1] + "," + aPos[2] + ";" + aAngle + ";" + aStance + "\n");
                } else if (isDefined(flagcarrier) || (self is_near_flag())
                        || (self is_near_carrier(self.pers["team"]))) {

                    // Victim was carrying or near the flag or near the teammate carrier (attacker assisted)
                    lpaction = getCvar("g_gametype") + "_assist";
                    logPrint("A;" + lpattackguid + ";" + lpattacknum + ";" + attacker.pers["team"] + ";" + attacker.name + ";" + lpaction + ";" + aPos[0] + "," + aPos[1] + "," + aPos[2] + ";" + aAngle + ";" + aStance + "\n");
                }
                if (isDefined(flagcarrier) || self is_near_flag() || self is_near_carrier()) {

                    // Victim was carrying or near the flag or near the carrier (victim fail)
                    lpaction = getCvar("g_gametype") + "_fail";
                    logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpaction + ";" + vPos[0] + "," + vPos[1] + "," + vPos[2] + ";" + vAngle + ";" + vStance + "\n");
                }
			}
		}
	}
	else // If you weren't killed by a player, you were in the wrong place at the wrong time
	{
		doKillcam = false;
		
		self.score--;

		lpattacknum = -1;
		lpattackname = "";
		lpattackguid = "";
		lpattackerteam = "world";
        aPos = (0, 0, 0);
        aAngle = "0";
        aStance = "none";
	}

    // Log the kill
	logPrint("K;" + lpselfguid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackguid + ";" + lpattacknum + ";" + lpattackerteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc+ ";" + vPos[0] + "," + vPos[1] + "," + vPos[2] + ";" + aPos[0] + "," + aPos[1] + "," + aPos[2] + ";" + vAngle + ";" + aAngle + ";" + vStance + ";" + aStance + "\n");

	// Stop thread if map ended on this death
	if(level.mapended)
		return;

	// Make the player drop his weapon
///// Removed by AWE /////
//	if (!isdefined (self.autobalance))
//		self dropItem(self getcurrentweapon());
//////////////////////////
	
	// Make the player drop health
	self dropHealth();
	self.autobalance = undefined;
///// Removed by AWE /////
//		body = self cloneplayer();
//////////////////////////		

	delay = 2;	// Delay the player becoming a spectator till after he's done dying
	wait delay;	// ?? Also required for Callback_PlayerKilled to complete before respawn/killcam can execute

	if((getCvarInt("scr_killcam") <= 0) || (level.forcerespawn > 0))
		doKillcam = false;
	
	if(doKillcam)
		self thread killcam(attackerNum, delay);
	else
		self thread respawn(level.respawntime);
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
		
	spawnpointname = "mp_uo_spawn_" + self.pers["team"];
	spawnpoints = getentarray(spawnpointname, "targetname");
	spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnpoints);

	if(isDefined(spawnpoint))
		spawnpoint maps\mp\gametypes\_spawnlogic::SpawnPlayer(self);
	else
		maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");

	self.statusicon = "";
	self.maxhealth = 100;
	self.health = self.maxhealth;
	
	if(isdefined(self.flagindicator))
		self.flagindicator destroy();

	if(isDefined(self.stopwatch))
		self.stopwatch destroy();

	self.pers["rank"] = maps\mp\gametypes\_rank_gmi::DetermineBattleRank(self);
	self.rank = self.pers["rank"];
	
	if(!isDefined(self.pers["savedmodel"]))
		maps\mp\gametypes\_teams::model();
	else
		maps\mp\_utility::loadModel(self.pers["savedmodel"]);

	// setup all the weapons
	self maps\mp\gametypes\_loadout_gmi::PlayerSpawnLoadout();
	
	Obj = "Grab the " + level.flagname + "!!!\n\nCapture the " + level.flagname + " and hold it for as long as possible to get points.\nReceive big score bonuses by using jeeps with your teammates.";

	if(self.pers["team"] == "allies")
		self setClientCvar("cg_objectiveText", Obj);
	else if(self.pers["team"] == "axis")
		self setClientCvar("cg_objectiveText", Obj);

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

	thread checkForFlags();

	self.awe_nohealthpack = undefined;		

    // Log the spawn event
	lpselfguid = self getGuid();
    lpselfnum = self getEntityNumber();
    lpplayerteam = self.pers["team"];
	lpselfname = self.name;
	lpweapon = self.pers["weapon"];
	lporigin = self.origin;
	lpangle = self.angles[1];
    logPrint("Spawn;" + lpselfguid + ";" + lpselfnum + ";" + lpplayerteam + ";" + lpselfname + ";" + lpweapon + ";" + lporigin[0] + "," + lporigin[1] + "," + lporigin[2] + ";" + lpangle + "\n");
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

	if(isDefined(self.stopwatch))
		self.stopwatch destroy();

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

    // Log the spectator event
	lpselfguid = self getGuid();
    lpselfnum = self getEntityNumber();
	lpselfname = self.name;
    logPrint("Spec;" + lpselfguid + ";" + lpselfnum + ";" + lpselfname + "\n");

	Obj = "Grab the " + level.flagname + "!!!\n\nCapture the " + level.flagname + " and hold it for as long as possible to get points.\nReceive big score bonuses by using jeeps with your teammates.";
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

respawn(waittime)
{
	if(!isDefined(self.pers["weapon"]))
		return;
	
	self endon("end_respawn");
	
	if(waittime)
		self stopwatch(waittime);

	if(level.forcerespawn > 0)
	{
		self thread waitForceRespawnTime(waittime);
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

waitForceRespawnTime(waittime)
{
	self endon("end_respawn");
	self endon("respawn");

	forcetime = level.forcerespawn;
	if(waittime<forcetime)
		wait(forcetime - waittime);
	else
		wait 0.05;

	self notify("respawn");
}

waitRespawnButton()
{
	self endon("end_respawn");
	self endon("respawn");
	
	wait 0; // Required or the "respawn" notify could happen before it's waittill has begun

	if ( level.forcerespawn == "1" )
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
	
		self thread respawn(level.respawntime);
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

	if ( level.forcerespawn != "1" )
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

	// Calculate remaining respawnwait
	if(self.killcamtimeused<level.respawntime)
		respawntime = level.respawntime - self.killcamtimeused;
	else
		respawntime = 0;

	self.killcamtimeused = undefined;

	self thread respawn(respawntime);
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

	self.killcamtimeused = 0.05;
	while(!(self useButtonPressed()))
	{
		wait .05;
		self.killcamtimeused += 0.05;  // Save the used killcam time
	}
	
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
			lpselfnum = player getEntityNumber();
			if((isDefined(player.pers["team"])) && (player.pers["team"] == winningteam))
					winners = (winners + ";" + lpselfnum + ";" + player.name);
			else if((isDefined(player.pers["team"])) && (player.pers["team"] == losingteam))
					losers = (losers + ";" + lpselfnum + ";" + player.name);
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

	// Respawn the flag if it is not touched for 80 seconds
    if (isDefined(level.flagtimestamp)) {
		flagtime = (getTime() - level.flagtimestamp) / 1000;
		if (flagTime >= 80) {
			level thread returnflag();
		}
	}

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

		timelimit = cvardef("scr_ftf_timelimit",20,0,1440,"float");
		if(level.timelimit != timelimit)
		{
			level.timelimit = timelimit;
//			setCvar("ui_tdm_timelimit", level.timelimit);
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

		scorelimit = cvardef("scr_ftf_scorelimit",10,0,9999,"int");
		if(level.scorelimit != scorelimit)
		{
			level.scorelimit = scorelimit;
//			setCvar("ui_tdm_scorelimit", level.scorelimit);
		}
		checkScoreLimit();

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
		
		// Balance mode
		level.mode = cvardef("scr_ftf_mode", 3, 0, 3, "int");

		// Max hold time
		level.holdtime = cvardef("scr_ftf_holdtime", 90, 0, 99999, "int");

		// Flag spawn delay
		level.flagspawndelay = cvardef("scr_ftf_flagspawndelay", 20, 0, 9999, "int");

		// Flag recover time
		level.flagrecovertime = cvardef("scr_ftf_flagrecovertime", 10, 0, 9999, "int");

		// Respawn wait time
		level.respawntime = cvardef("scr_ftf_respawntime", 0, 0, 60, "int");

		// Force respawning
		level.forcerespawn = cvardef("scr_forcerespawn",0,0,60,"int");

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

addBotClients()
{
	wait 5;
	
	for(;;)
	{
		if(getCvarInt("scr_numbots") > 0)
			break;
		wait 1;
	}
	
	iNumBots = getCvarInt("scr_numbots");
	for(i = 0; i < iNumBots; i++)
	{
		ent[i] = addtestclient();
		wait 0.5;

		if(isPlayer(ent[i]))
		{
			if(i & 1)
			{
				ent[i] notify("menuresponse", game["menu_team"], "axis");
				wait 0.5;
				ent[i] notify("menuresponse", game["menu_weapon_axis"], "kar98k_mp");
			}
			else
			{
				ent[i] notify("menuresponse", game["menu_team"], "allies");
				wait 0.5;
				ent[i] notify("menuresponse", game["menu_weapon_allies"], "springfield_mp");
			}
		}
	}
}

findGround(position)
{
	trace=bulletTrace(position+(0,0,10),position+(0,0,-1200),false,undefined);
	ground=trace["position"];
	return ground;
}

getFlagPoint()
{
	spawnpointname = "mp_teamdeathmatch_spawn";
	spawnpoints = getentarray(spawnpointname, "classname");
	maxdist = 0;
	p1 = spawnpoints[0];
	p2 = spawnpoints[0];
	for(i=0;i<spawnpoints.size;i++)
	{
		for(j=0;j<spawnpoints.size;j++)
		{
			if(i==j) continue;
			dist = distance(spawnpoints[i].origin,spawnpoints[j].origin);
			if(dist>maxdist)
			{
				maxdist = dist;
				p1 = spawnpoints[i];
				p2 = spawnpoints[j];
			}
		}
	}

	// Find center
	x = p1.origin[0] + (p2.origin[0] - p1.origin[0]) / 2;
	y = p1.origin[1] + (p2.origin[1] - p1.origin[1]) / 2;
	z = p1.origin[2] + (p2.origin[2] - p1.origin[2]) / 2;

	// Save teamsides for intitial spawning
	if(randomInt(2))
	{
		level.teamside["axis"] = p1.origin;
		level.teamside["allies"] = p2.origin;
	}
	else
	{
		level.teamside["axis"] = p2.origin;
		level.teamside["allies"] = p1.origin;
	}

	// Get nearest spawn
	return maps\mp\gametypes\_spawnlogic::NearestSpawnpoint(spawnpoints, (x,y,z));
}

setuphud()
{
	y = 10;
	barsize = 200;

	level.scoreback = newHudElem();
	level.scoreback.x = 320;
	level.scoreback.y = y;
	level.scoreback.alignX = "center";
	level.scoreback.alignY = "middle";
	level.scoreback.alpha = 0.3;
	level.scoreback.color = (0.2,0.2,0.2);
	level.scoreback setShader("white", barsize*2+4, 12);			

	level.scoreallies = newHudElem();
	level.scoreallies.x = 320;
	level.scoreallies.y = y;
	level.scoreallies.alignX = "right";
	level.scoreallies.alignY = "middle";
	level.scoreallies.color = (1,0,0);
	level.scoreallies.alpha = 0.5;
	level.scoreallies setShader("white", 1, 10);

	level.scoreaxis = newHudElem();
	level.scoreaxis.x = 320;
	level.scoreaxis.y = y;
	level.scoreaxis.alignX = "left";
	level.scoreaxis.alignY = "middle";
	level.scoreaxis.color = (0,0,1);
	level.scoreaxis.alpha = 0.5;
	level.scoreaxis setShader("white", 1, 10);

	level.iconallies = newHudElem();
	level.iconallies.x = 320 - barsize - 3;
	level.iconallies.y = y;
	level.iconallies.alignX = "right";
	level.iconallies.alignY = "middle";
	level.iconallies.color = (1,1,1);
	level.iconallies.alpha = 1;
	level.iconallies setShader(game["headicon_allies"], 18, 18);

	level.iconaxis = newHudElem();
	level.iconaxis.x = 320 + barsize + 3;
	level.iconaxis.y = y;
	level.iconaxis.alignX = "left";
	level.iconaxis.alignY = "middle";
	level.iconaxis.color = (1,1,1);
	level.iconaxis.alpha = 1;
	level.iconaxis setShader(game["headicon_axis"], 18, 18);

	level.numallies = newHudElem();
	level.numallies.x = 320 - barsize - 25;
	level.numallies.y = y-2;
	level.numallies.alignX = "right";
	level.numallies.alignY = "middle";
	level.numallies.color = (1,1,0);
	level.numallies.alpha = 1;
	level.numallies.fontscale = 1.2;
	level.numallies setValue(getTeamScore("allies"));

	level.numaxis = newHudElem();
	level.numaxis.x = 320 + barsize + 31;
	level.numaxis.y = y-2;
	level.numaxis.alignX = "right";
	level.numaxis.alignY = "middle";
	level.numaxis.color = (1,1,0);
	level.numaxis.alpha = 1;
	level.numaxis.fontscale = 1.2;
	level.numaxis setValue(getTeamScore("axis"));
}

updatehud()
{
	y = 10;
	barsize = 200;

	axis = level.teamholdtime["axis"] * barsize / (level.holdtime - 1) + 1;
	allies = level.teamholdtime["allies"] * barsize / (level.holdtime - 1) + 1;

	if(level.teamholdtime["allies"] != level.oldteamholdtime["allies"])
		level.scoreallies scaleOverTime(1,allies,10);
	if(level.teamholdtime["axis"] != level.oldteamholdtime["axis"])
		level.scoreaxis	scaleOverTime(1,axis,10);

	level.oldteamholdtime["allies"] = level.teamholdtime["allies"];
	level.oldteamholdtime["axis"] = level.teamholdtime["axis"];
}

returnflag()
{
	// Get map name
	mapname = getcvar("mapname");

	// See if map contains a predefined marker (not likely)
	flagspawnpoints = getentarray("ftf_flag_home","targetname");
    if (isDefined(flagspawnpoints) && isDefined(flagspawnpoints.size) && flagspawnpoints.size > 0) {
        level.flag["marker"] = flagspawnpoints[randomInt(flagspawnpoints.size)];
    }

	// No marker
	if(!isdefined(level.flag["marker"]))
	{
		// Look for cvars
		x = getcvar("scr_ftf_home_x_" + mapname);
		y = getcvar("scr_ftf_home_y_" + mapname);
		z = getcvar("scr_ftf_home_z_" + mapname);
		a = getcvar("scr_ftf_home_a_" + mapname);

		if(x != "" && y != "" && z != "" && a != "")
		{
			position = (x,y,z);
			angles = (0,a,0);
		}
		else
		{
			// No cvars...
			flagpoint = getFlagPoint();
			position = flagpoint.origin;
			angles = flagpoint.angles;
		}

		offset = (0,0,0);
		if(level.flagmodel == "xmodel/stalingrad_flag")
		{
			angles = (-90,angles[1],angles[2]);
			offset = (0,0,17);
		}

		if(level.flagmodel == "xmodel/mp_ctf_flag_gmi_wall")
	      {
                 angles = (angles[0],angles[1],75);
                 offset = (0,0,0);
	      } 

		level.flag["marker"] = spawn("script_origin", findGround(position) + offset);
		level.flag["marker"].targetname = "ftf_flag_home";
		level.flag["marker"].angles = angles;
		level.flag["marker"] hide();
	}

	// Remove spawns on flag points
	if(level.removeflagspawns && isDefined(flagpoint))
	{
		spawnpointname = "mp_teamdeathmatch_spawn";
		spawnpoints = getentarray(spawnpointname, "classname");
		for(i=0;i<spawnpoints.size;i++)
		{
			if(spawnpoints[i] == flagpoint)
				spawnpoints[i] delete();
		}
	}

	wait 0.05;

	if (!isDefined(level.spawnsInitialized)) {
		setuphud();
                level.spawnsInitialized = true;
        }

	level.currentflagteam = undefined;
	level.lastflagteam = undefined;
    level.flagtimestamp = getTime();

	// Delete flag if present
	if(isdefined(level.flag["flag"]))
		level.flag["flag"] delete();

	// Setup the flagspawn objective
	objective_delete(1);
	objective_delete(0);
	objective_add(0, "current", level.flag["marker"].origin, game["flagspawn"]);
	objective_team(0, "none");

	// Wait delay before spawning flag
	wait level.flagspawndelay + 0.05;

	// Do not spawn flag unless there are alive players in both teams
	while( !(alivePlayers("allies") && alivePlayers("axis")) )
		wait 1;

	angles = level.flag["marker"].angles;
	offset = (0,0,0);
	if(level.flagmodel == "xmodel/stalingrad_flag")
	{
		angles = (-90,angles[1],angles[2]);
		offset = (0,0,17);
	}

	if(level.flagmodel == "xmodel/mp_ctf_flag_gmi_wall")
	{
      	angles = (angles[0],angles[1],75);
      	offset = (0,0,0);
      } 

	dropFlagAt(level.flag["marker"].origin + offset, angles);
	level.flag["flag"].angles = angles;
	level.flag["flag"] setModel(level.flagmodel);
	level.flag["flag"] notify("returned");
}

checkForFlags()
{
	level endon("intermission");

	// What is my team?
	myteam = self.sessionteam;
	if(myteam == "allies")
		otherteam = "axis";
	else
		otherteam = "allies";
	
	while (isAlive(self) && self.sessionstate=="playing" && myteam == self.sessionteam) 
	{
		// Does other teams flag exist and is not currently being stolen?
		if(isdefined(level.flag["flag"]) && !isdefined(level.flag["flag"].stolen) )
		{
			// Am I touching it and it is not currently being stolen?
			if(self isTouchingFlag() && !isdefined(level.flag["flag"].stolen) )
			{
				level.flag["flag"].stolen = true;
		
				// Steal flag
				self.carrying = true;
				self.statusicon = game["statusicon_carrier_" + myteam];
				self.headicon = game["headicon_carrier_" + myteam];
				self.headiconteam = "none";

				self.flagindicator = newClientHudElem(self);	
				self.flagindicator.alpha = 0.65;
				self.flagindicator.alignX = "center";
				self.flagindicator.alignY = "middle";
				if(!cvardef("scr_ftf_flagicons", 1, 0, 1, "int"))
				{
					self.flagindicator.x = 600;
					self.flagindicator.y = 410;
					self.flagindicator setShader(game["headicon_carrier_" + myteam],40,40);
				}
				else
				{
					self.flagindicator.x = 608;
					self.flagindicator.y = 410;
					self.flagindicator setShader(game["headicon_carrier_" + myteam],56,32);
				}

				// Change objective to radio icon and make it visble only for my team
				objective_icon(0, game["radio_" + myteam]);
				objective_team(0, myteam);

				// Make an identical objective but for the other team
				objective_add(1, "current", self.origin, game["radio_" + myteam]);
				objective_team(1, otherteam);
				oldorigin = self.origin;

				level.flag["flag"] delete();

				self playsound("cell_door");

				if(!isdefined(level.lastflagteam) || level.lastflagteam != myteam)
				{
					self announce("^7stole the " + level.flagname + "^7!");
					// Get personal score
					self.score += 5;

					if(level.mode == 2)
						level.teamholdtime[otherteam] = 0;

					lpselfnum = self getEntityNumber();
					lpselfguid = self getGuid();
					lpaction = getCvar("g_gametype") + "_stole";
                    lpselfpos = self.origin;
                    lpselfangle = self.angles[1];
                    lpselfstance = self getStance();
					logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + myteam + ";" + self.name + ";" + lpaction + ";" + lpselfpos[0] + "," + lpselfpos[1] + "," + lpselfpos[2] + ";" + lpselfangle + ";" + lpselfstance + "\n");
				}
				else
				{
					self announce("^7picked up the " + level.flagname + "^7!");
				}
				
				level.lastflagteam = myteam;
				level.currentflagteam = myteam;

				if(myteam == "axis")
					level.iconaxis	scaleOverTime(1, 22, 22);
				else
					level.iconallies	scaleOverTime(1, 22, 22);

				count = 0;
			}
		}

		// Update objective on compass
		if(isdefined(self.carrying))
		{
			// Update the objective for my team
			objective_position(0, self.origin);		

			wait 0.05;

			level.flagtimestamp = getTime();

			// Increase teamscore every second
			count++;
			if(count>=20)
			{
				count = 0;
			
				// Update the other teams objective (lags 1 second behind)
				objective_position(1, oldorigin);		
				oldorigin = self.origin;
	
				if(level.mode == 1 && level.teamholdtime[otherteam])
					level.teamholdtime[otherteam]--;
				else
					level.teamholdtime[myteam]++;

				if(level.teamholdtime[myteam] >= level.holdtime)
				{
					iprintlnbold("The " + myteam + " scored by holding the " + level.flagname + " for " + level.holdtime + " seconds.");

					level.teamholdtime[myteam] = 0;
					if(level.mode == 3)
						level.teamholdtime[otherteam] = 0;

					// Get personal score
					self.score += 10;

					// Give all other team members 1 point
					players = getentarray("player", "classname");
					for(i = 0; i < players.size; i++)
					{
						player = players[i];
					
						if(!isDefined(player.pers["team"]) || player.pers["team"] != myteam || player == self)
							continue;
						player.score += 7;
					}

					lpselfnum = self getEntityNumber();
					lpselfguid = self getGuid();
					lpaction = getCvar("g_gametype") + "_scored";
                    lpselfpos = self.origin;
                    lpselfangle = self.angles[1];
                    lpselfstance = self getStance();
					logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + myteam + ";" + self.name + ";" + lpaction + ";" + lpselfpos[0] + "," + lpselfpos[1] + "," + lpselfpos[2] + ";" + lpselfangle + ";" + lpselfstance + "\n");

					// Get score
					myteamscore = getTeamScore(myteam);
					myteamscore++;
					setTeamScore(myteam, myteamscore);

					if(myteam == "allies")
						level.numallies setValue(getTeamScore("allies"));
					else
						level.numaxis setValue(getTeamScore("axis"));

					checkScoreLimit();

					// Clear flags
					self.carrying = undefined;	

					// Restore head and status icon
					if(level.drawfriend == 1)
					{
						if(level.battlerank)
						{
							self.statusicon = maps\mp\gametypes\_rank_gmi::GetRankStatusIcon(self);
							self.headicon = maps\mp\gametypes\_rank_gmi::GetRankHeadIcon(self);
							self.headiconteam = self.pers["team"];
						}
						else
						{
							self.headicon = game["headicon_" + myteam];
							self.headiconteam = myteam;
							self.statusicon = "";
						}
					}
					else
					{
						self.headicon = "";
						if(level.battlerank)
							self.statusicon = maps\mp\gametypes\_rank_gmi::GetRankStatusIcon(self);
						else
							self.statusicon = "";
					}

					// Clear hud
					if(isdefined(self.flagindicator))
						self.flagindicator destroy();

					// Return flag
					level thread returnflag();

					if(myteam == "axis")
						level.iconaxis	scaleOverTime(1, 18, 18);
					else
						level.iconallies	scaleOverTime(1, 18, 18);
				}
				updatehud();
			}
		}
		else
			wait 0.2;		

		// Make sure the headicon is not removed by rank system.
		if(isdefined(self.carrying))
		{
			self.statusicon = game["statusicon_carrier_" + myteam];
			self.headicon = game["headicon_carrier_" + myteam];
			self.headiconteam = "none";
		}
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
		thread returnflag();
		iprintlnbold("The " + level.flagname + " will be automaticly returned.");
		self.carrying = undefined;	
	}
	else
	{
		dropFlagAt(ground, self.angles);
		if(level.flagrecovertime)
			level.flag["flag"] thread autoReturnFlag();
		self.carrying = undefined;	
	
		self announce("^7dropped the " + level.flagname + "^7!");
	}

	// Restore head and status icon
	if(level.drawfriend == 1)
	{
		if(level.battlerank)
		{
			self.statusicon = maps\mp\gametypes\_rank_gmi::GetRankStatusIcon(self);
			self.headicon = maps\mp\gametypes\_rank_gmi::GetRankHeadIcon(self);
			self.headiconteam = self.pers["team"];
		}
		else
		{
			self.headicon = game["headicon_" + myteam];
			self.headiconteam = myteam;
			self.statusicon = "";
		}
	}
	else
	{
		self.headicon = "";
		if(level.battlerank)
			self.statusicon = maps\mp\gametypes\_rank_gmi::GetRankStatusIcon(self);
		else
			self.statusicon = "";
	}

	if(isdefined(self.flagindicator))
		self.flagindicator destroy();

	if(myteam == "axis")
		level.iconaxis	scaleOverTime(1, 18, 18);
	else
		level.iconallies	scaleOverTime(1, 18, 18);
}

autoReturnFlag()
{
	self endon("returned");
	
	// Wait before auto recovering a dropped flag
	wait level.flagrecovertime;
	
	// Return flag to starting point
	level thread returnflag();	
}

dropFlagAt(origin, angles)
{
	if( isdefined(level.flag["flag"]) )
		level.flag["flag"] delete();

	offset = (0,0,0);
	if(level.flagmodel_dropped == "xmodel/stalingrad_flag")
	{
		angles = (angles[0],angles[1],90);
		offset = (0,0,1);
	}

	level.flag["flag"] = spawn("script_model", origin + offset);
	level.flag["flag"].targetname = getCvar("g_gametype") + "_flag";

	if(level.flagmodel_dropped == "xmodel/uodropped" && isdefined(level.lastflagteam) )
	{
		if(level.lastflagteam == "axis")
		{
			level.flag["flag"] setmodel("xmodel/mp_ctf_flag_ge40");
		}
		else
		{
			switch(game["allies"])
			{
				case "british":
					level.flag["flag"] setmodel("xmodel/mp_ctf_flag_br40");
					break;
				case "russian":
					level.flag["flag"] setmodel("xmodel/mp_ctf_flag_ru40");
					break;
				default:
					level.flag["flag"] setmodel("xmodel/mp_ctf_flag_usa40");
					break;
			}
		}
	}
	else if(level.flagmodel_dropped == "xmodel/uo" && isdefined(level.lastflagteam) )
	{
		if(level.lastflagteam == "axis")
		{
			level.flag["flag"] setmodel("xmodel/mp_ctf_flag_ge60");
		}
		else
		{
			switch(game["allies"])
			{
				case "british":
					level.flag["flag"] setmodel("xmodel/mp_ctf_flag_br60");
					break;
				case "russian":
					level.flag["flag"] setmodel("xmodel/mp_ctf_flag_ru60");
					break;
				default:
					level.flag["flag"] setmodel("xmodel/mp_ctf_flag_usa60");
					break;
			}
		}
	}
	else
	{
		if(isdefined(level.lastflagteam))
			level.flag["flag"] setmodel( level.flagmodel_dropped );
	}

	level.flag["flag"].angles = angles;
	level.flag["flag"] show();

	objective_icon(0, game["flag"]);
	objective_position(0, origin);		
	objective_team(0, "none");
	objective_delete(1);

	level.currentflagteam = undefined;
}

isTouchingFlag()
{
	if(distance(self.origin, level.flag["flag"].origin) < 50)
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

// ----------------------------------------------------------------------------------
//	is_near_flag
//
// 	 	checks if the player is near a flag
// ----------------------------------------------------------------------------------
is_near_flag() {
    flag = level.flag["marker"];

    // Check if the player is close to the flag
    dist = distance(flag.origin, self.origin);
    if (dist < 750) {
        return true;
    }
    return false;
}

// ----------------------------------------------------------------------------------
//	is_near_flag_carrier
//
// 	 	checks if the player is near the enemy flag carrier
// ----------------------------------------------------------------------------------
is_near_carrier(team) {

    // If the attacker is the carrier then return false
    if (isDefined(self.carrying)) {
        return false;
    }

    players = getentarray("player", "classname");
    for (i = 0; i < players.size; i++) {
        player = players[i];
        if (isDefined(player.pers["team"]) && player.pers["team"] != "spectator"
                && self != player && isDefined(player.carrying)
                && (!isDefined(team) || team == player.pers["team"])) {

            // Check if the player is close to the flag carrier
            dist = distance(self.origin, player.origin);
            if (dist < 750) {
                return true;
            }
        }
    }
    return false;
}

stopwatch(time)
{
	if(isDefined(self.stopwatch))
		self.stopwatch destroy();
		
	self.stopwatch = newClientHudElem(self);
	self.stopwatch.x = 590; // 320;
	self.stopwatch.y = 380; // 380;
	self.stopwatch.alignX = "center";
	self.stopwatch.alignY = "middle";
	self.stopwatch.sort = 1;
	self.stopwatch setClock(time, 60, "hudStopwatch", 64, 64); // count down for 5 of 60 seconds, size is 64x64
	self.stopwatch.archived = false;

	wait (time);

	if(isDefined(self.stopwatch))
		self.stopwatch destroy();
}

// Adds a score bonus for players that kill while in a jeep
calculateScoreBonus(player) {

   // Make sure the player is valid
   if (!isDefined(player)) {
      return false;
   }

   // Check if the player is in a jeep
   if (!(player isInVehicle())) {
      return false;
   }

   // Get the jeep that the player is in
   jeep = findJeep(player);

   if (!isDefined(jeep)) {
      return false;
   }

   dScore = 0; // Driver score bonus
   gScore = 0; // Gunner score bonus
   pScore = 0; // Passenger score bonus

   if (isDefined(jeep.driver) && (jeep.driver == player)) {

      // The player is the jeep driver
      dScore = 9;
      gScore = 1;
      pScore = 1;
   } else if (isDefined(jeep.gunner) && (jeep.gunner == player)) {

      // The player is the jeep gunner
      dScore = 2;
      gScore = 3;
      pScore = 1;
   } else if (isDefined(jeep.passenger) && (jeep.passenger == player)) {

      // The player is the jeep passenger
      dScore = 2;
      gScore = 1;
      pScore = 3;
   } else {
      return false;
   }

   // Check if players get the full load bonus
   if (jeep.riding_count >= 3) {
      dScore++;
      gScore++;
      pScore++;
   }

   // Award the driver a score bonus
   if (isDefined(jeep.driver)) {
      jeep.driver.score += dScore;
   }

   // Award the gunner a score bonus
   if (isDefined(jeep.gunner)) {
      jeep.gunner.score += gScore;
   }

   // Award the passenger a score bonus
   if (isDefined(jeep.passenger)) {
      jeep.passenger.score += pScore;
   }

   return true;
}

// Returns which jeep the given player is in
findJeep(player) {

   // Get all the available vehicle objects
   vehicles = getentarray("script_vehicle", "classname");

   if (!isDefined(vehicles)) {
      return;
   }

   // Loop through each vehicle and look for jeeps
   for (i = 0; i < vehicles.size; i++) {

      // Check if the vehicle is a jeep
      if (vehicles[i].vehicletype == "willyjeep_mp" 
            || vehicles[i].vehicletype == "horch_mp" 
            || vehicles[i].vehicletype == "gaz67b_mp") {

         // Check if the player is in the jeep
         if (isDefined(vehicles[i].driver) && (vehicles[i].driver == player)) {
            return vehicles[i];
         }
         if (isDefined(vehicles[i].passenger) && (vehicles[i].passenger == player)) {
            return vehicles[i];
         }
         if (isDefined(vehicles[i].gunner) && (vehicles[i].gunner == player)) {
            return vehicles[i];
         }
      }
   }
}