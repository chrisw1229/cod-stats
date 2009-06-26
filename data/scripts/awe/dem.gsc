/*
	Demolition v0.96b
		Designed and coded by Clifton Cline, a.k.a. [FLARE]_Ravir
		ravir@clan-flare.org

	Attackers objective: Bomb 1 or 2 positions, three bombs available for pickup to be carried to objective
	Defenders objective: Defend these 2 positions: Defuse enough bombs to prevent destruction of objectives, or kill all attackers
	Round ends:	When one team is eliminated, required objectives explode, enough bombs are defused, or roundlength time is reached
	Map ends:	When the one team completes the objectives, or time limit or round limit is reached
	Respawning:	Optional respawning:  none, in waves, or individually

	Level requirements
	------------------
		Allied Spawnpoints:
			classname		mp_searchanddestroy_spawn_allied
			Allied players spawn from these. Place atleast 16 of these relatively close together.

		Axis Spawnpoints:
			classname		mp_searchanddestroy_spawn_axis
			Axis players spawn from these. Place atleast 16 of these relatively close together.

		Spectator Spawnpoints:
			classname		mp_searchanddestroy_intermission
			Spectators spawn from these and intermission is viewed from these positions.
			Atleast one is required, any more and they are randomly chosen between.

		Bombzone A:
			classname		trigger_multiple
			targetname		bombzone_A
			script_gameobjectname	bombzone
			This is a volume of space in which the bomb can planted. Must contain an origin brush.
		
		Bombzone B:
			classname		trigger_multiple
			targetname		bombzone_B
			script_gameobjectname	bombzone
			This is a volume of space in which the bomb can planted. Must contain an origin brush.
			
	Level script requirements
	-------------------------
		Team Definitions:
			game["allies"] = "american";
			game["axis"] = "german";
			This sets the nationalities of the teams. Allies can be american, british, or russian. Axis can be german.
	
			game["attackers"] = "allies";
			game["defenders"] = "axis";
			This sets which team is attacking and which team is defending. Attackers plant the bombs. Defenders protect the targets.

		Non-standard maps require the following cvar's to place the explosives packs:
			explosives packs now spawn at random spawnpoints

			scr_dem_bombzonea_name      //name of this zone, default is Target A

			scr_dem_bombzoneb_name

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

		Exploder Effects:
			Setting script_noteworthy on a bombzone trigger to an exploder group can be used to trigger additional effects.

	Note
	----
		Setting "script_gameobjectname" to "bombzone" on any entity in a level will cause that entity to be removed in any gametype that
		does not explicitly allow it. This is done to remove unused entities when playing a map in other gametypes that have no use for them.
*/

main()
{
	spawnpointname = "mp_searchanddestroy_spawn_allied";
	spawnpoints = getentarray(spawnpointname, "classname");

	if(!spawnpoints.size)
	{
		maps\mp\gametypes\_callbacksetup::AbortLevel();
		return;
	}
	for(i = 0; i < spawnpoints.size; i++)
		spawnpoints[i] placeSpawnpoint();


	spawnpointname = "mp_searchanddestroy_spawn_axis";
	spawnpoints = getentarray(spawnpointname, "classname");

	if(!spawnpoints.size)
	{
		maps\mp\gametypes\_callbacksetup::AbortLevel();
		return;
	}
	for(i = 0; i < spawnpoints.size; i++)
		spawnpoints[i] placeSpawnpoint();
		

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

	level._effect["bombexplosion"] = loadfx("fx/explosions/pathfinder_explosion.efx"); // used by the player and bomb smite commands

	level.explosions = [];
	level.explosions[level.explosions.size]["name"] = "fx/explosions/flakkcannon_exploder.efx";
	level.explosions[level.explosions.size]["name"] = "fx/explosions/v2_exlosion.efx";
	level.explosions[level.explosions.size]["name"] = "fx/explosions/metal_b.efx";
	level.explosions[level.explosions.size]["name"] = "fx/explosions/new_explosions1.efx";
	level.explosions[level.explosions.size]["name"] = "fx/explosions/newmetal_b.efx";

	for(i = 0; i < level.explosions.size; i++)
		level.explosions[i]["effect"] = loadfx(level.explosions[i]["name"]);

	allowed[0] = "sd";
	allowed[1] = "bombzone";
	allowed[2] = "blocker";
	allowed[3] = "tdm";
	maps\mp\gametypes\_gameobjects::main(allowed);

	maps\mp\gametypes\_rank_gmi::InitializeBattleRank();
	maps\mp\gametypes\_secondary_gmi::Initialize();

	// Time limit per map
	level.timelimit = cvardef("scr_dem_timelimit", 0, "", 1440, "float");
	if(!isdefined(game["timeleft"]))
		game["timeleft"] = level.timelimit;

	// Score limit per map
	level.scorelimit = cvardef("scr_dem_scorelimit", 10, "", "", "int");
		
	// Round limit per map
	level.roundlimit = cvardef("scr_dem_roundlimit", 0, "", "", "int");

	// Time length of each round, minutes, maximium 30
	level.roundlength = cvardef("scr_dem_roundlength", 10, "", 30, "float");

	// Time at round start where spawning and weapon choosing is still allowed
	level.graceperiod = cvardef("scr_dem_graceperiod", 15, "", 60, "float");

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
	makeCvarServerInfo("cg_hudcompassMaxRange", "0");

////// Added by AWE ////	
	if(getCvar("scr_drophealth") == "")		// Drop health?
		setCvar("scr_drophealth", "1");
////////////////////////

	// Round Cam On or Off (Default 0 - off)
	cvardef("scr_roundcam", "0", "", "", "int");

	// Draws a team icon over teammates
	level.drawfriend = cvardef("scr_drawfriend", "0", "", "", "int");

	if(!isdefined(game["state"]))
		game["state"] = "playing";
	if(!isdefined(game["roundsplayed"]))
		game["roundsplayed"] = 0;
	if(!isdefined(game["matchstarted"]))
		game["matchstarted"] = false;
		
	if(!isdefined(game["alliedscore"]))
		game["alliedscore"] = 0;
	setTeamScore("allies", game["alliedscore"]);

	if(!isdefined(game["axisscore"]))
		game["axisscore"] = 0;
	setTeamScore("axis", game["axisscore"]);

	// turn off ceasefire
	level.ceasefire = 0;
	setCvar("scr_ceasefire", "0");

	// Auto-balance teams
	level.teambalance = cvardef("scr_teambalance", 0, "", "", "int");
	level.teambalancetimer = 0;

	// Respawn mode
	level.respawn = cvardef("scr_dem_respawn", "wave", "", "", "string");

	// Respawn delay in seconds
	level.respawndelay["default"] = cvardef("scr_dem_respawndelay", 30, "", "", "int");

	// Respawn delay in seconds for Allies
	level.respawndelay["allies"] = cvardef("scr_dem_respawndelay_allies", level.respawndelay["default"], "", "", "int");

	// Respawn delay in seconds for Axis
	level.respawndelay["axis"] = cvardef("scr_dem_respawndelay_axis", level.respawndelay["default"], "", "", "int");

	// Bonus for assisting
	level.assistbonus = cvardef("scr_dem_assistbonus", 1, "", "", "int");

	// Minimum delay in seconds before a dropped bomb explodes
	level.unstabledelaymin = cvardef("scr_dem_unstabledelaymin", 120, "", "", "int");

	// Maximum delay in seconds before a dropped bomb explodes
	level.unstabledelaymax = cvardef("scr_dem_unstabledelaymax", 180, level.unstabledelaymin+1, "", "int");
	
	// % chance of a bomb exploding immediately when carrier is killed
	level.kaboom = cvardef("scr_dem_kaboom", 5, "", "", "int");

	// kaboom delay in seconds, minimum 3, max 15
	level.kaboomdelay = cvardef("scr_dem_kaboomdelay", 3, 3, 15, "int");

	// seconds to plant a bomb
	level.planttime = cvardef("scr_dem_planttime", 5, "", "", "int");

	// seconds to defuse a bomb
	level.defusetime = cvardef("scr_dem_defusetime", 10, "", "", "int");

	// seconds for a bomb to explode
	level.countdown = cvardef("scr_dem_countdown", 60, "", "", "int");

	// Allow killcam
	level.killcam = cvardef("scr_killcam", "1", 0, 1, "int");

	// number of objectives required for the attackers to win
	level.requiredTargets = cvardef("scr_dem_requiredtargets", 1, "", "", "int");

	// bonus points for planting the bomb
	level.plantbonus = cvardef("scr_dem_plantbonus", 1, "", "", "int");

	// bonus points for the planter if the bomb goes off
	level.bombbonus = cvardef("scr_dem_bombbonus", 2, "", "", "int");

	// bonus points for defusing a bomb
	level.defusebonus = cvardef("scr_dem_defusebonus", 3, "", "", "int");

	// protect bombs that haven't been picked up yet
	level.protectspawnbombs = cvardef("scr_dem_protectspawnbombs", 0, "", "", "int");

	// number of explosives packs available
	level.numofpacks = cvardef("scr_dem_numofpacks", 3, 3, 10, "int");

	// maximum number of simultaneous plants on one bomb
	safenum = level.numofpacks + 1 - level.requiredTargets; // leave enough bombs for the rest of the targets
	level.maxplants = cvardef("scr_dem_maxplants", safenum, 1, safenum, "int");

	// delay between players being able to take explosives packs from the supply box
	level.packreleasetime = cvardef("scr_dem_pack_release_time", 1, 1, "", "int");

	// maximum number of explosives packs allowed out of the supply box at once. Does not count defused or planted packs
	level.packreleasemax = cvardef("scr_dem_pack_release_max", level.numofpacks, 1, level.numofpacks, "int");

	// allow free-floating spectators
	level.allowfreelook = cvardef("scr_freelook", 1, 0, 1, "int");

	// allow specating of enemies
	level.allowenemyspectate = cvardef("scr_spectateenemy", 1, 0, 1, "int");

	level.roundstarted = false;
	level.roundended = false;
	level.mapended = false;
	
	level.exist["allies"] = 0;
	level.exist["axis"] = 0;
	level.exist["teams"] = false;
	level.didexist["allies"] = false;
	level.didexist["axis"] = false;

	level.healthqueue = [];
	level.healthqueuecurrent = 0;

	level.minefield = getentarray("minefield", "targetname");

	if(level.killcam != 0)
		setarchive(true);

	thread smitebombmonitor();
	thread kicktospec();
}

Callback_StartGameType()
{

///////// Added for AWE //////////
	maps\mp\gametypes\_awe::Callback_StartGameType();
//////////////////////////////////

	// if this is a fresh map start, set nationalities based on cvars, otherwise leave game variable nationalities as set in the level script
	if(!isdefined(game["gamestarted"]))
	{
		// defaults if not defined in level script
		if(!isdefined(game["allies"]))
			game["allies"] = "american";
		if(!isdefined(game["axis"]))
			game["axis"] = "german";

		if(!isdefined(game["layoutimage"]))
			game["layoutimage"] = "default";
		layoutname = "levelshots/layouts/hud@layout_" + game["layoutimage"];
		precacheShader(layoutname);
		setcvar("scr_layoutimage", layoutname);
		makeCvarServerInfo("scr_layoutimage", "");

		// server cvar overrides
		if(getcvar("scr_allies") != "")
			game["allies"] = getcvar("scr_allies");	
		if(getcvar("scr_axis") != "")
			game["axis"] = getcvar("scr_axis");

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

		game["headicon_allies"] = "gfx/hud/headicon@allies.tga";
		game["headicon_axis"] = "gfx/hud/headicon@axis.tga";
		game["status_bombstar"] = "gfx/hud/headicon@re_objcarrier.tga";

		game["bomb_box"] = "xmodel/crate_russianrifle_open";
		game["bomb_ready"] = "xmodel/mp_bomb1";
		game["bomb_planted"] = "xmodel/mp_bomb1_defuse";

		precacheString(&"MPSCRIPT_PRESS_ACTIVATE_TO_SKIP");
		precacheString(&"MPSCRIPT_KILLCAM");
		precacheString(&"SD_MATCHSTARTING");
		precacheString(&"SD_MATCHRESUMING");
		precacheString(&"SD_ROUNDDRAW");
		precacheString(&"SD_TIMEHASEXPIRED");
		precacheString(&"SD_ALLIEDMISSIONACCOMPLISHED");
		precacheString(&"SD_AXISMISSIONACCOMPLISHED");
		precacheString(&"SD_ALLIESHAVEBEENELIMINATED");
		precacheString(&"SD_AXISHAVEBEENELIMINATED");

// Compass legend
		precacheString(&": Target A");
		precacheString(&": Target B");
		precacheString(&": Bomb planted!");
		precacheString(&": Bomb dropped!");
		precacheString(&": Bomb carrier");
		precacheString(&": Bomb being defused!");
		precacheString(&": Bomb supply");
// end legend

		precacheString(&"^1Explosives planted:");
		precacheString(&"^5|");
		precacheString(&"^3DEFUSED!");
		precacheString(&"^4SUCCESS!");

		precacheString(&"Reinforcements in:");
		precacheString(&"You will respawn in:");

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

		precacheShader("gfx/hud/headicon@american.tga");
		precacheShader("gfx/hud/headicon@british.tga");
		precacheShader("gfx/hud/headicon@russian.tga");
		precacheShader("gfx/hud/headicon@german.tga");

		precacheStatusIcon("gfx/hud/hud@status_dead.tga");
		precacheStatusIcon("gfx/hud/hud@status_connecting.tga");
		precacheStatusIcon(game["status_bombstar"]);

		precacheHeadIcon(game["headicon_allies"]);
		precacheHeadIcon(game["headicon_axis"]);
		precacheHeadIcon(game["status_bombstar"]);

		precacheShader("gfx/hud/hud@fire_ready.tga");
		precacheShader("hudScoreboard_mp");
		precacheShader("gfx/hud/hud@mpflag_spectator.tga");
		precacheShader("ui_mp/assets/hud@plantbomb.tga");
		precacheShader("ui_mp/assets/hud@defusebomb.tga");
		precacheShader("gfx/icons/hint_usable.tga");
		precacheShader("gfx/hud/hud@objectiveA.tga");
		precacheShader("gfx/hud/hud@objectiveA_up.tga");
		precacheShader("gfx/hud/hud@objectiveA_down.tga");
		precacheShader("gfx/hud/hud@objectiveB.tga");
		precacheShader("gfx/hud/hud@objectiveB_up.tga");
		precacheShader("gfx/hud/@objectiveB_down.tga");
		precacheShader("gfx/hud/objective.tga");
		precacheShader("gfx/hud/objective_up.tga");
		precacheShader("gfx/hud/objective_down.tga");
		precacheShader("gfx/hud/hud@objective_bel.tga");
		precacheShader("gfx/hud/hud@objective_bel_up.tga");
		precacheShader("gfx/hud/hud@objective_bel_down.tga");
		precacheShader("gfx/hud/hud@objectivegoal.tga");
		precacheShader("gfx/hud/hud@objectivegoal_up.tga");
		precacheShader("gfx/hud/hud@objectivegoal_down.tga");
		precacheShader("gfx/hud/hud@bombplanted.tga");
		precacheShader("gfx/hud/hud@bombplanted_up.tga");
		precacheShader("gfx/hud/hud@bombplanted_down.tga");
		precacheShader("gfx/hud/hud@bombplanted_down.tga");
		precacheShader("gfx/hud/hud@compassface.tga");
		precacheShader(game["status_bombstar"]);
		precacheShader(game["headicon_allies"]);
		precacheShader(game["headicon_axis"]);

		precacheItem("item_health");

		precacheModel(game["bomb_box"]);
		precacheModel(game["bomb_ready"]);
		precacheModel(game["bomb_planted"]);
		
		maps\mp\gametypes\_teams::precache();
		maps\mp\gametypes\_teams::scoreboard();
	}

	thread bombzones();
	thread placeExPacks();
	thread startGame();
	thread updateGametypeCvars();

	
	maps\mp\gametypes\_teams::modeltype();
	maps\mp\gametypes\_teams::initGlobalCvars();
	maps\mp\gametypes\_teams::initWeaponCvars();
	maps\mp\gametypes\_teams::restrictPlacedWeapons();
	maps\mp\gametypes\_teams::updateGlobalCvars();
	maps\mp\gametypes\_teams::updateWeaponCvars();

	setClientNameMode("manual_change");

	game["gamestarted"] = true;
	
}

pingo(message)
{
for(;;)
{
	wait 1;
	iprintln("pingo: " + message);
}
}


Callback_PlayerConnect()
{
	if(!isdefined(level.starttime))
		level.starttime = getTime();

	self.statusicon = "gfx/hud/hud@status_connecting.tga";
	self waittill("begin");
	self.statusicon = "";
	self.pers["teamTime"] = 0;
	self.carrying = false;
	self.wasAttacked = false;
	self.expacki = -1;

	if(!isdefined(self.pers["team"]))
		iprintln(&"MPSCRIPT_CONNECTED", self);

	lpselfnum = self getEntityNumber();
	lpselfguid = self getGuid();
	logPrint("J;" + lpselfguid + ";" + lpselfnum + ";" + self.name + "\n");

	// set the cvar for the map quick bind
	self setClientCvar("g_scriptQuickMap", game["menu_viewmap"]);

	// make sure that the rank variable is initialized
	if ( !isDefined( self.pers["rank"] ) )
		self.pers["rank"] = 0;

	if(game["state"] == "intermission")
	{
		spawnIntermission();
		return;
	}
	
/*	if (getCvar("g_autodemo") == "1")
	{
		self autoDemoStart();
	}*/

	level endon("intermission");

	// start the vsay thread
	self thread maps\mp\gametypes\_teams::vsay_monitor();

	if(isdefined(self.pers["team"]) && self.pers["team"] != "spectator")
	{
		self setClientCvar("ui_weapontab", "1");

		if(self.pers["team"] == "allies")
			self setClientCvar("g_scriptMainMenu", game["menu_weapon_allies"]);
		else
			self setClientCvar("g_scriptMainMenu", game["menu_weapon_axis"]);

		if(isdefined(self.pers["weapon"]))
			spawnPlayer();
		else
		{
			self.sessionteam = "spectator";

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
					
						if(!isdefined(player.pers["team"]) || player.pers["team"] == "spectator" || player == self)
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
				}
				//clan vs. non-clan match

				// enable clan tag limiting per side
				if(getcvar("g_alliestag") != "" && substr(getcvar("g_alliestag"), self.name) == -1 && response == "allies")
				{
					self iprintlnbold("You are not currently allowed to join this team.");
					continue;
				}
				if(getcvar("g_axistag") != "" && substr(getcvar("g_axistag"), self.name) == -1 && response == "axis")
				{
					self iprintlnbold("You are not currently allowed to join this team.");
					continue;
				}
				if(response == self.pers["team"] && self.sessionstate == "playing")
					break;
				
				if(response != self.pers["team"] && self.sessionstate == "playing")
					self suicide();

				self.pers["team"] = response;
				self.pers["teamTime"] = ((getTime() - level.starttime) / 1000);
				self.pers["weapon"] = undefined;
				self.pers["savedmodel"] = undefined;
				self.pers["weapon1"] = undefined;
				self.pers["weapon2"] = undefined;
				self.pers["spawnweapon"] = undefined;
				self.grenadecount = undefined;

				// set spectator permissions
				maps\mp\gametypes\_teams::SetSpectatePermissions();

				self.iswaiting = undefined; // they've changed teams
				if(isdefined(self.respawnhud))
				{
					self.respawnhud destroy();
					self.respawntimer destroy();
				}

				self setClientCvar("scr_showweapontab", "1");

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



			case "spectator":
				if(self.pers["team"] != "spectator")
				{
					if(isalive(self))
						self suicide();

					self.pers["team"] = "spectator";
					self.pers["teamTime"] = 0;
					self.pers["weapon"] = undefined;
					self.pers["weapon1"] = undefined;
					self.pers["weapon2"] = undefined;
					self.pers["spawnweapon"] = undefined;
					self.pers["savedmodel"] = undefined;
					self.grenadecount = undefined;
					
					self.sessionteam = "spectator";
					self setClientCvar("g_scriptMainMenu", game["menu_team"]);
					self setClientCvar("ui_showweapontab", "0");
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
			
			if(!isdefined(self.pers["team"]) || (self.pers["team"] != "allies" && self.pers["team"] != "axis"))
				continue;

			weapon = self maps\mp\gametypes\_teams::restrict(response);

			if(weapon == "restricted")
			{
				self openMenu(menu);
				continue;
			}
			
			self.pers["selectedweapon"] = weapon;

			if(isdefined(self.pers["weapon"]) && self.pers["weapon"] == weapon && !isdefined(self.pers["weapon1"]))
				continue;
				
//			menu_spawn(weapon);

			if(!game["matchstarted"]) // if match not has started
			{
				self.pers["weapon"] = weapon;
				self.spawned = undefined;
				spawnPlayer();
				self thread printJoinedTeam(self.pers["team"]);
				level checkMatchStart();
			}
			else if(!level.roundstarted) // round has not started
			{
				if(isdefined(self.pers["weapon"]))
				{
					self.pers["weapon"] = weapon;
					self setWeaponSlotWeapon("primary", weapon);
					self setWeaponSlotAmmo("primary", 999);
					self setWeaponSlotClipAmmo("primary", 999);
					self switchToWeapon(weapon);
				}
				else
				{				
					self.pers["weapon"] = weapon;
					if(!level.exist[self.pers["team"]])
					{
						self.spawned = undefined;
						spawnPlayer();
						self thread printJoinedTeam(self.pers["team"]);
						level checkMatchStart();
					}
					else
					{
						spawnPlayer();
						self thread printJoinedTeam(self.pers["team"]);
					}
				}
			}
			else // round has started
			{
				if(isdefined(self.pers["weapon"]))
					self.oldweapon = self.pers["weapon"];


				self.pers["weapon"] = weapon;
				self.sessionteam = self.pers["team"];

				if(self.sessionstate != "playing")
					self.statusicon = "gfx/hud/hud@status_dead.tga";
			
				if(self.pers["team"] == "allies")
					otherteam = "axis";
				else if(self.pers["team"] == "axis")
					otherteam = "allies";
					
				// if joining a team that has no opponents, just spawn
				if(!level.didexist[otherteam] && !level.roundended)
				{
					self.spawned = undefined;
					spawnPlayer();
					self thread printJoinedTeam(self.pers["team"]);
				}				
				else if(!level.didexist[self.pers["team"]] && !level.roundended)
				{ // or this there there was nobody on this team.
					self.spawned = undefined;
					spawnPlayer();
					self thread printJoinedTeam(self.pers["team"]);
					level checkMatchStart();
				}
				else  // both teams are already in action
				{
					weaponname = maps\mp\gametypes\_teams::getWeaponName(self.pers["weapon"]);

					if(self.pers["team"] == "allies" || self.pers["team"] == "axis")
					{
						if(maps\mp\gametypes\_teams::useAn(self.pers["weapon"]))
							self iprintln(&"MPSCRIPT_YOU_WILL_RESPAWN_WITH_AN", weaponname);
						else
							self iprintln(&"MPSCRIPT_YOU_WILL_RESPAWN_WITH_A", weaponname);
						if(self.sessionstate != "playing" && level.respawn != "none")	// they're not already playing
							self thread waitForRespawn(); // put 'em into the game
					}
				}
			}
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

///// Added by AWE ////////
	self maps\mp\gametypes\_awe::PlayerDisconnect();
///////////////////////////

	if(isdefined(self.carrying) && self.carrying == true)
	{
		i = self.expacki;
		level.expack[i] thread dropbomb();
	}

	iprintln(&"MPSCRIPT_DISCONNECTED", self);
	
	lpselfnum = self getEntityNumber();
	lpGuid = self getGuid();
	logPrint("Q;" + lpGuid + ";" + lpselfnum + ";" + self.name + "\n");

	if(game["matchstarted"])
		level thread updateTeamStatus();
}

Callback_PlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc)
{

	if(self.sessionteam == "spectator")
		return;

	// dont take damage during ceasefire mode
	// but still take damage from ambient damage (water, minefields, fire)
	if(level.ceasefire && sMeansOfDeath != "MOD_EXPLOSIVE" && sMeansOfDeath != "MOD_WATER")
		return;

	if(isplayer(eAttacker) && eAttacker.health > 100)
	{
		iDamage = iDamage * ( level.spawnadvantage / 100); // the damage is modified via cvar
	}

	if(self.carrying && self.pers["team"] == game["attackers"] && isplayer(eAttacker))
	{
		self notify("ouchie");
		self thread carrierHurt(eAttacker);
	}

	// Don't do knockback if the damage direction was not specified, or if they're under protection
	if(!isDefined(vDir) || self.health > 100)
		iDFlags |= level.iDFLAGS_NO_KNOCKBACK;

	eDamage = 0;

	// check for completely getting out of the damage
	if(!(iDFlags & level.iDFLAGS_NO_PROTECTION))
	{
		if(isPlayer(eAttacker) && (self != eAttacker) && (self.pers["team"] == eAttacker.pers["team"]))
		{
			if(level.friendlyfire == 0)
				return;
// Added for AWE
			if(level.friendlyfire == 1)
				eAttacker maps\mp\gametypes\_awe::teamdamage(self, iDamage);

			if(level.friendlyfire == 2 || isdefined(eAttacker.pers["awe_teamkiller"]) )
			{
				eDamage = iDamage * 0.5;
				iDamage = 0;
			}

			if( (level.friendlyfire == 3 || sMeansOfDeath == "MOD_CRUSH_TANK" || sMeansOfDeath == "MOD_CRUSH_JEEP") && !isdefined(eAttacker.pers["awe_teamkiller"]) )
			{
				iDamage = iDamage * 0.5;
				eDamage = iDamage;
			}
		}
	}

	// Apply the damage to the player
	if(iDamage > 0)
	{
		// Make sure at least one point of damage is done
		if(iDamage < 1)
			iDamage = 1;

		self finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc);

////////////// Added by AWE //////////////////
		self maps\mp\gametypes\_awe::DoPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc);
//////////////////////////////////////////////
	}
	if(eDamage > 0)
	{
		eAttacker.reflectdamage = true;

		// Make sure at least one point of damage is done
		if(eDamage < 1)
			eDamage = 1;

		if(isplayer(eAttacker))
		{
			eAttacker finishPlayerDamage(eInflictor, eAttacker, eDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc);
			eAttacker.reflectdamage = undefined;
		}
	}

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

		if(isdefined(reflect)) 
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
	self notify("killed");

/////////// Added by AWE ///////////
	self thread maps\mp\gametypes\_awe::PlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc);
////////////////////////////////////

	team = self.pers["team"];

	self thread compasslegend("off");

	self dropHealth();

	if(self.carrying)
	{
		i = self.expacki;
		kaboom = randomInt(100);
		if(kaboom <= level.kaboom)
			level.expack[i].kaboom = true;

		level.expack[i] thread dropbomb();
	}
	// no credit to teammates for killing an attacker if the bomb carrier died
	self.wasAttacked = false; 
	self.myattackerNum = -1;

	// check to see if this player had recently shot at an enemy carrier, if so, attacker may get an assist bonus
	thisPlayerNum = self getEntityNumber();
	if(isplayer(attacker))
		self.myattackerNum = attacker getEntityNumber();
	attackerGotBonus = false;

if(isplayer(attacker))
{
	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		if(	players[i].wasAttacked                        // found a live bomb carrier that had been recently attacked
			&& players[i].myattackerNum == thisPlayerNum  // carrier had been attacked by the killed player
			&& self.pers["team"] == game["defenders"]     // player killed was a defender
			&& attacker.pers["team"] == game["attackers"] // killer was an attacker
			&& attacker != players[i]                     // killer was not the bomb carrier (can't get points for protecting yourself)
		){
			iprintln(attacker.name + "^7 saved " + players[i].name + "^7 from " + self.name);

			lpattackernum = attacker getEntityNumber();
			logPrint("A;" + lpattackernum + ";" + game["attackers"] + ";" + attacker.name + ";" + "bomb_carrier_saved" + "\n"); 

			attackerGotBonus = true;
			break;
		}
	}

	// check to see if the attacker gets an assist bonus for defending a bomb
	if(!attackerGotBonus && level.assistbonus != 0) // bonus available, haven't gotten one yet
	for(i = 0; i < level.numofpacks && !attackerGotBonus; i++)
	{
		//was this player kiled by an attacker close to a bomb or carrier?
		dist = distance(attacker.origin, level.expack[i].origin);

		if(	dist < 240 && !attackerGotBonus                // attacker was within 20 feet of bomb, killer has not received a bonus yet
			&& self.pers["team"] == game["defenders"]      // player killed was a defender
			&& attacker.pers["team"] == game["attackers"]  // killer was an attacker
			&& self.myattackerNum != level.expack[i].playerNum  // killer was not the bomb carrier (can't get points for protecting yourself)
		){
			// bomb was live on a target, saved the bomb
			if(level.expack[i].status == "planted" || level.expack[i].status == "defusing")
			{
				iprintln(attacker.name + "^7 protected a bomb from " + self.name);

				lpattackernum = attacker getEntityNumber();
				logPrint("A;" + lpattackernum + ";" + game["attackers"] + ";" + attacker.name + ";" + "bomb_saved" + "\n"); 

				attackerGotBonus = true;
				break;
			}

			// bomb was being carried or planted, save the carrier
			if(level.expack[i].status == "carried" || level.expack[i].status == "planting")
			{
				iprintln(attacker.name + "^7 protected " + level.expack[i].player.name + "^7 from " + self.name);

				lpattackernum = attacker getEntityNumber();
				logPrint("A;" + lpattackernum + ";" + game["attackers"] + ";" + attacker.name + ";" + "bomb_carrier_saved" + "\n"); 

				attackerGotBonus = true;
				break;
			}
		}

		//was this player killed next to a bomb or carrier?
		dist = distance(self.origin, level.expack[i].origin);

		if(	dist < 240 && !attackerGotBonus                // player was killed within 20 feet of bomb, killer has not received a bonus yet
			&& self.pers["team"] == game["defenders"]      // player killed was a defender
			&& attacker.pers["team"] == game["attackers"]  // killer was an attacker
			&& self.myattackerNum != level.expack[i].playerNum  // killer was not the bomb carrier (can't get points for protecting yourself)
		){
			// bomb was live on a target, or had been dropped on the ground, saved the bomb
			if(level.expack[i].status == "planted" || 
				level.expack[i].status == "dropped" || 
				level.expack[i].status == "defusing" ||
				level.expack[i].status == "spawned")
			{
				iprintln(self.name + "^7's defusal was denied by " + attacker.name);

				lpattackernum = attacker getEntityNumber();
				logPrint("A;" + lpattackernum + ";" + game["attackers"] + ";" + attacker.name + ";" + "bomb_saved" + "\n"); 

				attackerGotBonus = true;
				break;
			}

			// bomb was being carried or planted, saved the carrier
			if(level.expack[i].status == "carried" || level.expack[i].status == "planting")
			{
				iprintln(attacker.name + "^7 kept " + self.name + "^7 away from " + level.expack[i].player.name);

				lpattackernum = attacker getEntityNumber();
				logPrint("A;" + lpattackernum + ";" + game["attackers"] + ";" + attacker.name + ";" + "bomb_carrier_saved" + "\n"); 

				attackerGotBonus = true;
				break;
			}
		}
	}

	if(attackerGotBonus)
	{
		attacker.pers["score"] += level.assistbonus;
		attacker.score = attacker.pers["score"];
	}
} // end if isplayer(attacker)

	if(self.sessionteam == "spectator")
		return;

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
//	if(attackerGotBonus == 0 && sMeansOfDeath != "MOD_MELEE")  // don't flood with redundant kill reports
//		obituary(self, attacker, sWeapon, sMeansOfDeath);
/////////////////////////////////

	if(sMeansOfDeath == "MOD_MELEE")
	{
		quip = randomint(5);
		switch(quip)
		{
			case 0:
				iprintln(attacker.name + "^7 gave a ^1Death Noogie^7 to " + self.name);
				break;
			case 1:
				iprintln(self.name + "^7 had their world ^4rocked^7 by " + attacker.name);
				break;
			case 2:
				iprintln(attacker.name + "^7 engaged in ^2aggressive negotiations^7 with " + self.name);
				break;
			case 3:
				iprintln(attacker.name + "^7 played " + self.name + "^7 like a ^5cheap drum");
				break;
			case 4:
				iprintln(self.name + "^7 has a headache ^6THIS BIG^7, thanks to " + attacker.name);
				break;
		}
	}

	attacker iprintlnbold("You killed " + self.name); // attacker still needs to know for sure

	self.sessionstate = "dead";
	self.statusicon = "gfx/hud/hud@status_dead.tga";
	self.headicon = "";
	self.noInactivityKick = 1;
	self.pers["deaths"]++;
	self.deaths = self.pers["deaths"];
	self.grenadecount = undefined;
	if(!isdefined(self.autobalance))
		self.deaths++;

	lpselfnum = self getEntityNumber();
	lpselfname = self.name;
	lpselfteam = self.pers["team"];
	lpattackerteam = "";

	attackerNum = -1;
	level.playercam = attacker getEntityNumber();

	if(isPlayer(attacker))
	{
		if(attacker == self) // killed himself
		{
			doKillcam = false;

			if(!isdefined(self.autobalance))
			{
				attacker.pers["score"]--;
				attacker.score = attacker.pers["score"];
			}
		}
		else
		{
			attackerNum = attacker getEntityNumber();
			doKillcam = true;

			if(self.pers["team"] == attacker.pers["team"]) // killed by a friendly
			{
				attacker.pers["score"]--;
				attacker.score = attacker.pers["score"];
// Added for AWE
				attacker maps\mp\gametypes\_awe::teamkill();
			}
			else
			{
				attacker.pers["score"]++;
				attacker.score = attacker.pers["score"];
			}
		}
		
		lpattacknum = attacker getEntityNumber();
		lpattackname = attacker.name;
		lpattackerteam = attacker.pers["team"];
	}
	else // If you weren't killed by a player, you were in the wrong place at the wrong time
	{
		doKillcam = false;

		self.pers["score"]--;
		self.score = self.pers["score"];

		lpattacknum = -1;
		lpattackname = "";
		lpattackerteam = "world";
	}

	logPrint("K;" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattacknum + ";" + lpattackerteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");

	// Make the player drop his weapon

///// Removed by AWE /////
//	if (!isdefined (self.autobalance))
//		self dropItem(self getcurrentweapon());
//////////////////////////

	self.pers["weapon1"] = undefined;
	self.pers["weapon2"] = undefined;
	self.pers["spawnweapon"] = undefined;

	self.autobalance = undefined;

///// Removed by AWE /////
//	if (!isdefined (self.autobalance))
//		body = self cloneplayer();
//////////////////////////

	updateTeamStatus();

	// TODO: Add additional checks that allow killcam when the last player killed wouldn't end the round (bomb is planted)
	if(!level.exist[self.pers["team"]] && level.respawn == "none") // If the last player on a team was just killed, don't do killcam
		doKillcam = false;

	delay = 2;	// Delay the player becoming a spectator till after he's done dying
	wait delay;	// ?? Also required for Callback_PlayerKilled to complete before killcam can execute

	if(doKillcam && !level.roundended && level.killcam == "1")
	{
		self thread killcam(attackerNum, delay);
	}
	else
	{
		currentorigin = self.origin;
		currentangles = self.angles;

		self thread spawnSpectator(currentorigin + (0, 0, 60), currentangles);

		if(level.respawn != "none" && self.pers["team"] == team) // respawn is allowed, wasn't killed by changing teams
			self thread waitForRespawn();
	}
}

blocksiamese()
{
	wait 5;
	self.inuse = undefined; // unlock this spawn point
}

spawnPlayer(spawnpoint)
{

	self notify("spawned");

	self.carrying = false;
	self.expacki = -1;
	self.iswaiting = undefined;
	if(isdefined(self.respawnhud))
	{
		self.respawnhud destroy();
		self.respawntimer destroy();
	}

	self thread compasslegend("on");

	resettimeout();

	self.sessionteam = self.pers["team"];
	self.spectatorclient = -1;
	self.archivetime = 0;
	self.reflectdamage = undefined;

	if(isdefined(self.spawned) && level.respawn == "none") // if respawning is not allowed, don't.
		return;

	self.sessionstate = "playing";
		
	if(self.pers["team"] == "allies")
		spawnpointname = "mp_searchanddestroy_spawn_allied";
	else
		spawnpointname = "mp_searchanddestroy_spawn_axis";

	if(!isdefined(spawnpoint))
	{
		spawnpoints = getentarray(spawnpointname, "classname");
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnpoints);

		// keep looking for a spawnpoint that hasn't been used recently
		while(isdefined(spawnpoint.inuse) || positionWouldTelefrag(spawnpoint.origin))
		{
			spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnpoints);
			wait 0.05; 
		}
		spawnpoint.inuse = true;
		spawnpoint thread blocksiamese();
	}

	self spawn(spawnpoint.origin, spawnpoint.angles);
	
	self.spawned = true;
	self.statusicon = "";
	self.maxhealth = 100;
	self.health = self.maxhealth;
	
	updateTeamStatus();
	
	if(!isdefined(self.pers["score"]))
		self.pers["score"] = 0;
	self.score = self.pers["score"];
	
	if(!isdefined(self.pers["deaths"]))
		self.pers["deaths"] = 0;
	self.deaths = self.pers["deaths"];
	
	if(!isdefined(self.pers["savedmodel"]))
		maps\mp\gametypes\_teams::model();
	else
		maps\mp\_utility::loadModel(self.pers["savedmodel"]);
	
	maps\mp\gametypes\_teams::givePistol();
	maps\mp\gametypes\_teams::giveGrenades(self.pers["weapon"]);

	// setup all the weapons
	self maps\mp\gametypes\_loadout_gmi::PlayerSpawnLoadout();

/*	if(isdefined(self.pers["weapon1"]) && isdefined(self.pers["weapon2"]))
	{
		self setWeaponSlotWeapon("primary", self.pers["weapon1"]);
		self setWeaponSlotAmmo("primary", 999);
		self setWeaponSlotClipAmmo("primary", 999);

		self setWeaponSlotWeapon("primaryb", self.pers["weapon2"]);
		self setWeaponSlotAmmo("primaryb", 999);
		self setWeaponSlotClipAmmo("primaryb", 999);

		self setSpawnWeapon(self.pers["spawnweapon"]);
	}
	else
	{
		self setWeaponSlotWeapon("primary", self.pers["weapon"]);
		self setWeaponSlotAmmo("primary", 999);
		self setWeaponSlotClipAmmo("primary", 999);

		self setSpawnWeapon(self.pers["weapon"]);
	}*/

	packLoseNum = level.numofpacks - level.requiredTargets + 1;
	attackObj = "Ravir's Demolition v0.96b\ndemolition.codcity.org\n\nGrab the explosive packs and plant them on the objectives.  You must destroy " + level.requiredTargets + " of the objectives to win.  If the Axis defuse " + packLoseNum + " of your packs, you lose.";
	defendObj = "Ravir's Demolition v0.96b\ndemolition.codcity.org\n\nPrevent the attackers from destroying " + level.requiredTargets + " of the objectives.  If you can defuse " + packLoseNum + " of their explosive packs, you win.";
	if(self.pers["team"] == game["attackers"])
		self setClientCvar("cg_objectiveText", attackObj);
	else if(self.pers["team"] == game["defenders"])
		self setClientCvar("cg_objectiveText", defendObj);
		
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

	wait 0.05;

// Added for AWE
	self maps\mp\gametypes\_awe::spawnPlayer();
}

spawnSpectator(origin, angles)
{
	if(self.carrying)
	{
		level.expack[self.expacki] thread dropbomb();
		self.carriericon destroy();
	}

	self notify("spawned");

	resettimeout();

	self.sessionstate = "spectator";
	self.spectatorclient = -1;
	self.archivetime = 0;
	self.reflectdamage = undefined;

	if(isdefined(self.respawnhud))
		self.respawnhud destroy();

	if(isdefined(self.respawntimer))
		self.respawntimer destroy();

	if(self.pers["team"] == "spectator")
		self.statusicon = "";

	maps\mp\gametypes\_teams::SetSpectatePermissions();

	if(isdefined(origin) && isdefined(angles))
		self spawn(origin, angles);
	else
	{
 		spawnpointname = "mp_searchanddestroy_intermission";
		spawnpoints = getentarray(spawnpointname, "classname");
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnpoints);

		if(isdefined(spawnpoint))
			self spawn(spawnpoint.origin, spawnpoint.angles);
		else
			maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");
	}

	updateTeamStatus();

	if(game["attackers"] == "allies")
		self setClientCvar("cg_objectiveText", "Ravir's Demolition v0.96b\ndemolition.codcity.org\n\nAllies: Destroy the enemy's vital installations with explosives.\n\nAxis: Prevent your installations being destroyed. If explosives are planted at an objective, defuse them before they explode.");
	else if(game["attackers"] == "axis")
		self setClientCvar("cg_objectiveText", "Ravir's Demolition v0.96b\ndemolition.codcity.org\n\nAxis: Destroy the enemy's vital installations with explosives.\n\nAllies: Prevent your installations being destroyed. If explosives are planted at an objective, defuse them before they explode.");
}

spawnIntermission()
{
	self notify("spawned");
	
	resettimeout();

	self.sessionstate = "intermission";
	self.spectatorclient = -1;
	self.archivetime = 0;
	self.reflectdamage = undefined;

	spawnpointname = "mp_searchanddestroy_intermission";
	spawnpoints = getentarray(spawnpointname, "classname");
	spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnpoints);

	if(isdefined(spawnpoint))
		self spawn(spawnpoint.origin, spawnpoint.angles);
	else
		maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");
}

killcam(attackerNum, delay)
{
	self endon("spawned");
	
	// killcam
	if(attackerNum < 0)
		return;

	self.sessionstate = "spectator";
	self.spectatorclient = attackerNum;
	self.archivetime = delay + 7;

	maps\mp\gametypes\_teams::SetKillcamSpectatePermissions();

	// wait till the next server frame to allow code a chance to update archivetime if it needs trimming
	wait 0.05;

	if(self.archivetime <= delay)
	{
		self.spectatorclient = -1;
		self.archivetime = 0;
	
		maps\mp\gametypes\_teams::SetSpectatePermissions();
		return;
	}

	self.killcam = true;

	if(!isdefined(self.kc_topbar))
	{
		self.kc_topbar = newClientHudElem(self);
		self.kc_topbar.archived = false;
		self.kc_topbar.x = 0;
		self.kc_topbar.y = 0;
		self.kc_topbar.alpha = 0.5;
		self.kc_topbar setShader("black", 640, 112);
	}

	if(!isdefined(self.kc_bottombar))
	{
		self.kc_bottombar = newClientHudElem(self);
		self.kc_bottombar.archived = false;
		self.kc_bottombar.x = 0;
		self.kc_bottombar.y = 368;
		self.kc_bottombar.alpha = 0.5;
		self.kc_bottombar setShader("black", 640, 112);
	}

	if(!isdefined(self.kc_title))
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

	if(!isdefined(self.kc_skiptext))
	{
		self.kc_skiptext = newClientHudElem(self);
		self.kc_skiptext.archived = false;
		self.kc_skiptext.x = 320;
		self.kc_skiptext.y = 70;
		self.kc_skiptext.alignX = "center";
		self.kc_skiptext.alignY = "middle";
		self.kc_skiptext.sort = 1; // force to draw after the bars
	}
	self.kc_skiptext setText(&"MPSCRIPT_PRESS_ACTIVATE_TO_SKIP");

	if(!isdefined(self.kc_timer))
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
	self.killcam = undefined;

	maps\mp\gametypes\_teams::SetSpectatePermissions();

	if(level.respawn != "none")
		self thread waitForRespawn();
}

waitKillcamTime()
{
	self endon("end_killcam");
	
	wait (self.archivetime - 0.05);
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
	if(isdefined(self.kc_topbar))
		self.kc_topbar destroy();
	if(isdefined(self.kc_bottombar))
		self.kc_bottombar destroy();
	if(isdefined(self.kc_title))
		self.kc_title destroy();
	if(isdefined(self.kc_skiptext))
		self.kc_skiptext destroy();
	if(isdefined(self.kc_timer))
		self.kc_timer destroy();
}

spawnedKillcamCleanup()
{
	self endon("end_killcam");

	self waittill("spawned");
	self removeKillcamElements();
}

roundcam(delay, winningteam)
{
	self endon("spawned");
	
	spawnSpectator();

	if(isdefined(level.bombcam))
		self thread spawnSpectator(level.bombcam.origin, level.bombcam.angles);
	else
		self.spectatorclient = level.playercam;
		
	self.archivetime = delay + 7;

	// wait till the next server frame to give the player the kill-cam huddraw elements
	wait 0.05;

	if (!isdefined(self.kc_topbar))
	{
		self.kc_topbar = newClientHudElem(self);
		self.kc_topbar.archived = false;
		self.kc_topbar.x = 0;
		self.kc_topbar.y = 0;
		self.kc_topbar.alpha = 0.5;
		self.kc_topbar setShader("black", 640, 112);
	}

	if (!isdefined(self.kc_bottombar))
	{
		self.kc_bottombar = newClientHudElem(self);
		self.kc_bottombar.archived = false;
		self.kc_bottombar.x = 0;
		self.kc_bottombar.y = 368;
		self.kc_bottombar.alpha = 0.5;
		self.kc_bottombar setShader("black", 640, 112);
	}

	if(!isdefined(self.kc_title))
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

	if(winningteam == "allies")
		self.kc_title setText(&"MPSCRIPT_ALLIES_WIN");
	else if(winningteam == "axis")
		self.kc_title setText(&"MPSCRIPT_AXIS_WIN");
	else
		self.kc_title setText(&"MPSCRIPT_ROUNDCAM");

	if(!isdefined(self.kc_skiptext))
	{
		self.kc_skiptext = newClientHudElem(self);
		self.kc_skiptext.archived = false;
		self.kc_skiptext.x = 320;
		self.kc_skiptext.y = 70;
		self.kc_skiptext.alignX = "center";
		self.kc_skiptext.alignY = "middle";
		self.kc_skiptext.sort = 1; // force to draw after the bars
	}
	self.kc_skiptext setText(&"MPSCRIPT_STARTING_NEW_ROUND");

	if(!isdefined(self.kc_timer))
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
	self.kc_timer setTimer(self.archivetime - 1.05);

	self thread spawnedKillcamCleanup();
	self thread waitSkipKillcamButton();
	wait (self.archivetime - 0.05);
	self removeKillcamElements();

	self.spectatorclient = -1;
	self.archivetime = 0;
	
	level notify("roundcam_ended");
}

startGame()
{
	level.starttime = getTime();
	thread startRound();
	result = defineSpawnPoints();
	if(level.respawn != "none")
	{
		thread reinforcements("allies");
		thread reinforcements("axis");
	}
	for(;;)
	{
		checkTimeLimit();
		wait 1;
	}
}

startRound()
{
	thread maps\mp\gametypes\_teams::sayMoveIn();
	thread announceObjectives();
//	if(level.teambalance == 1)
//		thread teambalance();

	level.clock = newHudElem();
	level.clock.x = 320;
	level.clock.y = 460;
	level.clock.alignX = "center";
	level.clock.alignY = "middle";
	level.clock.font = "bigfixed";
	level.clock setTimer(level.roundlength * 60);
	level.livebombs = 0;

	if(game["matchstarted"])
	{
		level.clock.color = (0, 1, 0);

		if((level.roundlength * 60) > level.graceperiod)
		{
			wait level.graceperiod;

			level.roundstarted = true;
			level.clock.color = (1, 1, 1);

			// Players on a team but without a weapon show as dead
			players = getentarray("player", "classname");
			for(i = 0; i < players.size; i++)
			{
				player = players[i];

				if(player.sessionteam != "spectator" && !isdefined(player.pers["weapon"]))
					player.statusicon = "gfx/hud/hud@status_dead.tga";
			}
		
			wait ((level.roundlength * 60) - level.graceperiod);
		}
		else
			wait (level.roundlength * 60);
	}
	else	
	{
		level.clock.color = (1, 1, 1);
		wait (level.roundlength * 60);
	}

	while(level.livebombs > 0) // don't stop if there's still a bomb active
		wait 0.05;
	
	if(level.roundended)
		return;

	level thread hud_announce(&"SD_TIMEHASEXPIRED");
	level thread endRound(game["defenders"], true);
}

checkMatchStart()
{
	oldvalue["teams"] = level.exist["teams"];
	level.exist["teams"] = false;

	// If teams currently exist
	if(level.exist["allies"] && level.exist["axis"])
		level.exist["teams"] = true;

	// If teams previously did not exist and now they do
	if(!oldvalue["teams"] && level.exist["teams"] && !level.roundended)
	{
		if(!game["matchstarted"])
		{
			level thread hud_announce(&"SD_MATCHSTARTING");
			level thread endRound("reset");
		}
		else
		{
			level thread hud_announce(&"SD_MATCHRESUMING");
			level thread endRound("draw");
		}

		return;
	}
}

resetScores()
{
	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		player.pers["score"] = 0;
		player.pers["deaths"] = 0;
	}

	game["alliedscore"] = 0;
	setTeamScore("allies", game["alliedscore"]);
	game["axisscore"] = 0;
	setTeamScore("axis", game["axisscore"]);
}

endRound(roundwinner, timeexpired)
{
	if(level.roundended)
		return;
	level.roundended = true;

	if(!isdefined(timeexpired))
		timeexpired = false;
	
	winners = "";
	losers = "";
	
	if(roundwinner == "allies")
	{
		game["alliedscore"]++;
		setTeamScore("allies", game["alliedscore"]);
		
		players = getentarray("player", "classname");
		for(i = 0; i < players.size; i++)
		{
			if ( (isdefined (players[i].pers["team"])) && (players[i].pers["team"] == "allies") )
				winners = (winners + ";" + players[i].name);
			else if ( (isdefined (players[i].pers["team"])) && (players[i].pers["team"] == "axis") )
				losers = (losers + ";" + players[i].name);
			players[i] playLocalSound("MP_announcer_allies_win");
		}
		logPrint("W;allies" + winners + "\n");
		logPrint("L;axis" + losers + "\n");
	}
	else if(roundwinner == "axis")
	{
		game["axisscore"]++;
		setTeamScore("axis", game["axisscore"]);

		players = getentarray("player", "classname");
		for(i = 0; i < players.size; i++)
		{
			if ( (isdefined (players[i].pers["team"])) && (players[i].pers["team"] == "axis") )
				winners = (winners + ";" + players[i].name);
			else if ( (isdefined (players[i].pers["team"])) && (players[i].pers["team"] == "allies") )
				losers = (losers + ";" + players[i].name);
			players[i] playLocalSound("MP_announcer_axis_win");
		}
		logPrint("W;axis" + winners + "\n");
		logPrint("L;allies" + losers + "\n");
	}
	else if(roundwinner == "draw")
	{
		players = getentarray("player", "classname");
		for(i = 0; i < players.size; i++)
			players[i] playLocalSound("MP_announcer_round_draw");
	}

	if((getcvar("scr_roundcam") == "1") && (!timeexpired) && (game["matchstarted"]))
	{
		if((isdefined(level.playercam) || isdefined(level.bombcam)) && roundwinner != "draw" && roundwinner != "reset")
		{
			delay = 2;	// Delay the player becoming a spectator
			wait delay;

			viewers = 0;
			for(i = 0; i < players.size; i++)
			{
				player = players[i];
				
				if((player.sessionstate != "playing") && (player getEntityNumber() != level.playercam) && !isdefined(player.killcam))
				{
					player thread roundcam(delay, roundwinner);
					viewers++;
				}
			}

			if(viewers)
				level waittill("roundcam_ended");
			else
				wait 7;
		}
		else
		{
			wait 5;
		}
	}
	else
	{
		wait 5;
	}

	if(game["matchstarted"])
	{
		checkScoreLimit();
		game["roundsplayed"]++;
		checkRoundLimit();
	}

	if(!game["matchstarted"] && roundwinner == "reset")
	{
		game["matchstarted"] = true;
		thread resetScores();
		game["roundsplayed"] = 0;
	}

	if(level.mapended)
		return;
	level.mapended = true;

	// for all living players store their weapons
	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		
		if(isdefined(player.pers["team"]) && player.pers["team"] != "spectator" && player.sessionstate == "playing")
		{
			primary = player getWeaponSlotWeapon("primary");
			primaryb = player getWeaponSlotWeapon("primaryb");

			// If a menu selection was made
			if(isdefined(player.oldweapon))
			{
				// If a new weapon has since been picked up (this fails when a player picks up a weapon the same as his original)
				if(player.oldweapon != primary && player.oldweapon != primaryb && primary != "none")
				{
					player.pers["weapon1"] = primary;
					player.pers["weapon2"] = primaryb;
					player.pers["spawnweapon"] = player getCurrentWeapon();
				} // If the player's menu chosen weapon is the same as what is in the primaryb slot, swap the slots
				else if(player.pers["weapon"] == primaryb)
				{
					player.pers["weapon1"] = primaryb;
					player.pers["weapon2"] = primary;
					player.pers["spawnweapon"] = player.pers["weapon1"];
				} // Give them the weapon they chose from the menu
				else
				{
					player.pers["weapon1"] = player.pers["weapon"];
					player.pers["weapon2"] = primaryb;
					player.pers["spawnweapon"] = player.pers["weapon1"];
				}
			} // No menu choice was ever made, so keep their weapons and spawn them with what they're holding, unless it's a pistol or grenade
			else
			{
				if(primary == "none")
					player.pers["weapon1"] = player.pers["weapon"];
				else
					player.pers["weapon1"] = primary;
					
				player.pers["weapon2"] = primaryb;

				spawnweapon = player getCurrentWeapon();
				if(!maps\mp\gametypes\_teams::isPistolOrGrenade(spawnweapon))
					player.pers["spawnweapon"] = spawnweapon;
				else
					player.pers["spawnweapon"] = player.pers["weapon1"];
			}
		}
	}

	if(level.timelimit > 0)
	{
		timepassed = (getTime() - level.starttime) / 1000;
		timepassed = timepassed / 60.0;

		game["timeleft"] = level.timelimit - timepassed;
	}


////////// Added by AWE //////////	
	maps\mp\gametypes\_awe::swapteams();
//////////////////////////////////

	map_restart(true);
}

endMap()
{

////// Added by AWE ///////////
	maps\mp\gametypes\_awe::endMap();
/////////////////////////////////

	game["state"] = "intermission";
	level notify("intermission");
	
	if(game["alliedscore"] == game["axisscore"])
		text = &"MPSCRIPT_THE_GAME_IS_A_TIE";
	else if(game["alliedscore"] > game["axisscore"])
		text = &"MPSCRIPT_ALLIES_WIN";
	else
		text = &"MPSCRIPT_AXIS_WIN";

	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		player closeMenu();
		player setClientCvar("g_scriptMainMenu", "main");
		player setClientCvar("cg_objectiveText", text);
		player spawnIntermission();
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
	
	if(timepassed < game["timeleft"])
		return;
	
	if(level.mapended)
		return;
	level.mapended = true;

	iprintln(&"MPSCRIPT_TIME_LIMIT_REACHED");
	endMap();
}

checkScoreLimit()
{
	if(level.scorelimit <= 0)
		return;
	
	if(game["alliedscore"] < level.scorelimit && game["axisscore"] < level.scorelimit)
		return;

	if(level.mapended)
		return;
	level.mapended = true;

	iprintln(&"MPSCRIPT_SCORE_LIMIT_REACHED");
	endMap();
}

checkRoundLimit()
{
	if(level.roundlimit <= 0)
		return;
	
	if(game["roundsplayed"] < level.roundlimit)
		return;
	
	if(level.mapended)
		return;
	level.mapended = true;

	iprintln(&"MPSCRIPT_ROUND_LIMIT_REACHED");
	endMap();
}

// monitor cvars that can change during gameplay
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

		// Time limit per map
		timelimit = cvardef("scr_dem_timelimit", 0, "", 1440, "float");
		if(level.timelimit != timelimit)
		{
			level.timelimit = timelimit;
			game["timeleft"] = timelimit;
			level.starttime = getTime();
			
			checkTimeLimit();
		}


		// Score limit per map
		scorelimit = cvardef("scr_dem_scorelimit", 10, "", "", "int");
		if(level.scorelimit != scorelimit)
		{
			level.scorelimit = scorelimit;

			if(game["matchstarted"])
				checkScoreLimit();
		}
		
		// Round limit per map
		roundlimit = cvardef("scr_dem_roundlimit", 0, "", "", "int");
		if(level.roundlimit != roundlimit)
		{
			level.roundlimit = roundlimit;

			if(game["matchstarted"])
				checkRoundLimit();
		}

		// Time length of each round, minutes, maximium 30
		level.roundlength = cvardef("scr_dem_roundlength", 10, "", 30, "float");

		// Time at round start where spawning and weapon choosing is still allowed
		level.graceperiod = cvardef("scr_dem_graceperiod", 15, "", 60, "float");

		// Round Cam On or Off (Default 0 - off)
		cvardef("scr_roundcam", "0", "", "", "int");

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

		if(!isdefined(game["alliedscore"]))
			game["alliedscore"] = 0;
		setTeamScore("allies", game["alliedscore"]);

		if(!isdefined(game["axisscore"]))
			game["axisscore"] = 0;
		setTeamScore("axis", game["axisscore"]);

		// Auto-balance teams
		teambalance = cvardef("scr_teambalance", 0, "", "", "int");
		if (level.teambalance != teambalance)
		{
			level.teambalance = teambalance;
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

		// Respawn delay in seconds
		respawndelay = cvardef("scr_dem_respawndelay", 30, "", "", "int");
		if(level.respawndelay["default"] != respawndelay)
		{
			level.respawndelay["default"] = respawndelay;

			level.respawndelay["allies"] = respawndelay;
			setcvar("scr_dem_respawndelay_allies", level.respawndelay["allies"]);

			level.respawndelay["axis"] = respawndelay;
			setcvar("scr_dem_respawndelay_axis", level.respawndelay["axis"]);
		}

		// Respawn delay in seconds for Allies
		level.respawndelay["allies"] = cvardef("scr_dem_respawndelay_allies", level.respawndelay["default"], "", "", "int");

		// Respawn delay in seconds for Axis
		level.respawndelay["axis"] = cvardef("scr_dem_respawndelay_axis", level.respawndelay["default"], "", "", "int");

		// Bonus for assisting
		level.assistbonus = cvardef("scr_dem_assistbonus", 1, "", "", "int");

		// Minimum delay in seconds before a dropped bomb explodes
		level.unstabledelaymin = cvardef("scr_dem_unstabledelaymin", 120, "", "", "int");

		// Maximum delay in seconds before a dropped bomb explodes
		level.unstabledelaymax = cvardef("scr_dem_unstabledelaymax", 180, level.unstabledelaymin+1, "", "int");
	
		// % chance of a bomb exploding immediately when carrier is killed
		level.kaboom = cvardef("scr_dem_kaboom", 5, "", "", "int");

		// kaboom delay in seconds, minimum 3, max 15
		level.kaboomdelay = cvardef("scr_dem_kaboomdelay", 3, 3, 15, "int");

		// seconds to plant a bomb
		level.planttime = cvardef("scr_dem_planttime", 5, "", "", "int");

		// seconds to defuse a bomb
		level.defusetime = cvardef("scr_dem_defusetime", 10, "", "", "int");

		// seconds for a bomb to explode
		level.countdown = cvardef("scr_dem_countdown", 60, "", "", "int");

		// Allow killcam
		level.killcam = cvardef("scr_killcam", "1", 0, 1, "int");

		// number of objectives required for the attackers to win
		level.requiredTargets = cvardef("scr_dem_requiredtargets", 1, "", "", "int");

		// bonus points for planting the bomb
		level.plantbonus = cvardef("scr_dem_plantbonus", 1, "", "", "int");

		// bonus points for the planter if the bomb goes off
		level.bombbonus = cvardef("scr_dem_bombbonus", 2, "", "", "int");

		// bonus points for defusing a bomb
		level.defusebonus = cvardef("scr_dem_defusebonus", 3, "", "", "int");

		// protect bombs that haven't been picked up yet
		level.protectspawnbombs = cvardef("scr_dem_protectspawnbombs", 0, "", "", "int");

		// maximum number of simultaneous plants on one bomb
		safenum = level.numofpacks - (level.requiredTargets - 1); // leave enough bombs for the rest of the targets
		level.maxplants = cvardef("scr_dem_maxplants", safenum, 1, safenum, "int");

		// delay between players being able to take explosives packs from the supply box
		level.packreleasetime = cvardef("scr_dem_pack_release_time", 1, 1, "", "int");

		// maximum number of explosives packs allowed out of the supply box at once. Does not count defused or planted packs
		level.packreleasemax = cvardef("scr_dem_pack_release_max", level.numofpacks, 1, level.numofpacks, "int");

		// allow free-floating spectators
		level.allowfreelook = cvardef("scr_freelook", 1, 0, 1, "int");

		// allow specating of enemies
		level.allowenemyspectate = cvardef("scr_spectateenemy", 1, 0, 1, "int");

		wait 1;
	}
}

updateTeamStatus()
{
	wait 0;	// Required for Callback_PlayerDisconnect to complete before updateTeamStatus can execute
	
	resettimeout();
	
	oldvalue["allies"] = level.exist["allies"];
	oldvalue["axis"] = level.exist["axis"];
	level.exist["allies"] = 0;
	level.exist["axis"] = 0;
	
	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		
		if(isdefined(player.pers["team"]) && player.pers["team"] != "spectator" && player.sessionstate == "playing")
			level.exist[player.pers["team"]]++;
	}

	if(level.exist["allies"])
		level.didexist["allies"] = true;
	if(level.exist["axis"])
		level.didexist["axis"] = true;

	if(level.roundended)
		return;

	if(level.respawn != "none") // respawning is allowed, don't quit 'cause of dead players
		return;

	if(oldvalue["allies"] && !level.exist["allies"] && oldvalue["axis"] && !level.exist["axis"])
	{  // everybody's dead
		if(level.packsLeft >= level.targetsLeft)
		{  // enough bombs planted, attackers win
			if(game["attackers"] == "allies")
			{
				level thread hud_announce(&"SD_ALLIEDMISSIONACCOMPLISHED");
				level thread endRound("allies");
			}
			else
			{
				level thread hud_announce(&"SD_AXISMISSIONACCOMPLISHED");
				level thread endRound("axis");
			}
			return;
		}
		else
		{  // not enough bombs planted, attackers lose
			if(game["attackers"] == "allies")
			{
				level thread hud_announce(&"SD_AXISMISSIONACCOMPLISHED");
				level thread endRound("axis");
			}
			else
			{
				level thread hud_announce(&"SD_ALLIEDMISSIONACCOMPLISHED");
				level thread endRound("allies");
			}
			return;
		}
	}

	if(oldvalue["allies"] && !level.exist["allies"])
	{
		// all allies are dead
		level thread hud_announce(&"SD_ALLIESHAVEBEENELIMINATED");

		if(game["attackers"] == "allies") // if the attackers are dead make sure there are no live bombs left behind
			while(level.livebombs > 0)
				wait 0.05;

		level thread hud_announce(&"SD_AXISMISSIONACCOMPLISHED");
		level thread endRound("axis");
		return;
	}
	
	if(oldvalue["axis"] && !level.exist["axis"])
	{
		// all axis are dead
		level thread hud_announce(&"SD_AXISHAVEBEENELIMINATED");

 		if(game["attackers"] == "axis") // if the attackers are dead make sure there are no live bombs left behind
			while(level.livebombs > 0)
				wait 0.05;
		
		level thread hud_announce(&"SD_ALLIEDMISSIONACCOMPLISHED");
		level thread endRound("allies");
		return;
	}	
}

bombzones()
{
	level.barsize = 288;

	level.targetsLeft	= 2;		// targets left to destroy

	if(getcvar("scr_dem_bombzonea_name") == "")
		setcvar("scr_dem_bombzonea_name", "Target A");
	if(getcvar("scr_dem_bombzoneb_name") == "")
		setcvar("scr_dem_bombzoneb_name", "Target B");

	level.targets[0] = getent("bombzone_A", "targetname");
	level.targets[0].objnum = 2;
	level.targets[0].icon = "gfx/hud/hud@objectiveA.tga";
	level.targets[0] thread bombzone_think();
	level.targets[0].i = 0;
	level.targets[0].myname = getcvar("scr_dem_bombzonea_name");
	level.targets[0].status = "live";

	level.targets[1] = getent("bombzone_B", "targetname");
	level.targets[1].objnum = 3;
	level.targets[1].icon = "gfx/hud/hud@objectiveB.tga";
	level.targets[1] thread bombzone_think();
	level.targets[1].i = 1;
	level.targets[1].myname = getcvar("scr_dem_bombzoneb_name");
	level.targets[1].status = "live";

	wait 1;	// TEMP: without this one of the objective icon is the default. Carl says we're overflowing something.
	objective_add(2, "current", level.targets[0].origin, "gfx/hud/hud@objectiveA.tga");
	objective_add(3, "current", level.targets[1].origin, "gfx/hud/hud@objectiveB.tga");
}



bombzone_think()
{
	self endon("destroyed");
	self.planted = 0;
	for(;;)
	{
		wait 0.05;

		self waittill("trigger", other);

		if(isPlayer(other) && !other.carrying) // they don't have the bomb, ignore 'em
			continue;

		if(self.planted == level.maxplants) // the maximum number of bombs has been planted
			continue;

		// they're carrying a bomb, show 'em the plant icon
		if(!isdefined(other.planticon))
		{
			// make a link between the bomb and the target zone
			other thread bombtarget(self);

			other.planticon = newClientHudElem(other);				
			other.planticon.alignX = "center";
			other.planticon.alignY = "middle";
			other.planticon.x = 320;
			other.planticon.y = 345;
			other.planticon setShader("ui_mp/assets/hud@plantbomb.tga", 64, 64);			

			// keep the icon on their screen while they're in the plant zone
			other thread check_hud_zone(self, other.planticon);

		}
	}
}



check_hud_zone(trigger, icon)
{
	self notify("kill_check_hud");
	self endon("kill_check_hud");
	
	while(isdefined(trigger) && self istouching(trigger) && isalive(self))
		wait 0.05;

	if(isdefined(icon))
		icon destroy();
}


check_hud_bomb(trigger, icon)
{
	self notify("kill_check_hud");
	self endon("kill_check_hud");
	
	while(isdefined(trigger) && distance(self.origin, trigger.origin) < trigger.maxdist && isalive(self))
		wait 0.05;

	if(isdefined(icon))
		icon destroy();
}


bomb_countdown(target)
{
	self endon("bomb_defused");
	
	self playLoopSound("bomb_tick");
	
	wait level.countdown;

	// bomb timer is up, KABOOM

	target notify("destroyed"); // can't plant on a dead target
	dabombs = [];
	dabombs[0] = self; 

	//first, stop any other countdowns on this target
	destroyThis = self.targeti;
	for(i = 0; i < level.numofpacks; i++)
	{
		dabomb = level.expack[i];
		if(isdefined(dabomb.targeti) && dabomb.targeti == destroyThis && dabomb.i != self.i)
		{
			dabombs[dabombs.size] = dabomb; // build the shorter list of bombs on this target
			dabomb notify("bomb_defused");
		}
	}

	objective_delete(self.objnum); // remove the objective


	// now do the chain reaction explosions
	for(i = 0; i < dabombs.size; i++)
	{
		dabomb = dabombs[i];

		dabomb hide();
		dabomb.status = "success"; 
		dabomb thread removeBombTimer();
		dabomb thread updatebombcounter();

		if(isdefined(dabomb.planter) && isplayer(dabomb.planter))
		{
			dabomb.planter.pers["score"] += level.bombbonus; // bonus points to the player that planted the bomb
			dabomb.planter.score = dabomb.planter.pers["score"];
		}

		// explode bomb
		// each explosion gets slightly bigger
		range = 360 + (i * 120); // 30 feet, + 10 feet per additional bomb
		maxdamage = 300 + (i * 100); // 300 damage + 100 per additional bomb
		mindamage = 10;
		earthquake(0.5, 3, self.origin, 1200+(360*i));
		
		dabomb stopLoopSound();

		x = randomInt(level.explosions.size);
		if(i == dabombs.size-1)
			playfx(level.explosions[x]["effect"], dabomb.origin);
		else
			playfx(level._effect["bombexplosion"], dabomb.origin);

		dabomb playSound("explo_metal_rand");

		radiusDamage(dabomb.origin + (0,0,12), range, maxdamage, mindamage);
		level.packsleft--; // and no longer in play
		target.status = "dead";
		wait 0.5; // chain reaction delay
	}

	
	// trigger exploder if it exists
	// only do this once, after the last bomb
	if(isdefined(level.bombexploder[self.objnum]))
		maps\mp\_utility::exploder(level.bombexploder[self.objnum]);

	iprintlnbold(self.myname + " has been destroyed");
	level.targetsLeft--; // kaboom'd
	if(level.requiredTargets == 2 - level.targetsLeft)
	{
		if(game["attackers"] == "axis")
			level thread hud_announce(&"SD_AXISMISSIONACCOMPLISHED");
		else
			level thread hud_announce(&"SD_ALLIEDMISSIONACCOMPLISHED");
		level thread endRound(game["attackers"]);
	}

	level.livebombs -= dabombs.size; // no longer planted.
}

hud_announce(text)
{
	level notify("kill_hud_announce");
	level endon("kill_hud_announce");

	if(!isdefined(level.announce))
	{
		level.announce = newHudElem();
		level.announce.alignX = "center";
		level.announce.alignY = "middle";
		level.announce.x = 320;
		level.announce.y = 185;
	}	
	level.announce setText(text);

	wait 4;
	level.announce fadeOverTime(1);

	wait .9;

	if(isdefined(level.announce))
		level.announce destroy();	
}

printJoinedTeam(team)
{
	if(team == "allies")
		iprintln(&"MPSCRIPT_JOINED_ALLIES", self);
	else if(team == "axis")
		iprintln(&"MPSCRIPT_JOINED_AXIS", self);
}

spawn_model(model,name,origin,angles)
{
	if (!isdefined(model) || !isdefined(name) || !isdefined(origin))
		return undefined;

	if (!isdefined(angles))
		angles = (0,0,0);

	spawn = spawn ("script_model",(0,0,0));
	spawn.origin = origin;
	spawn setmodel (model);
	spawn.targetname = name;
	spawn.angles = angles;

	return spawn;
}


placeExPacks()
{
	wait 1;
	if(game["attackers"] == "allies")
		spawnnames = "mp_searchanddestroy_spawn_allied";
	else
		spawnnames = "mp_searchanddestroy_spawn_axis";

	spawnpoints = getentarray(spawnnames, "classname");

	level.bombbox = spawn_model(game["bomb_box"], "supplybox", spawnpoints[0].origin, (0,0,0));

	objective_add(4, "current", level.bombbox.origin, "gfx/hud/hud@objectivegoal.tga");
	objective_team(4, game["attackers"]);

	// parameters set, activate the bombs
	level.packsleft = level.numofpacks;
	level.expack = [];
	alternate = 0;
	for(i = 0; i < level.numofpacks; i++){
		// stack the expacks inside each other in the box
		// it'll look like 3 expacks until it gets down to 2, then 1, then none
		// When they were stacked vertically, it looked very odd 'cause players can still walk through them
		alternate++;
		switch(alternate)
		{
			case 1:
				origin = spawnpoints[0].origin + (0,-14,0);
				angles = (0,-14,0);
				break;
			case 2:
				origin = spawnpoints[0].origin + (0,0,0);
				angles = (0,0,0);
				break;
			case 3:
				origin = spawnpoints[0].origin + (0,14,0);
				angles = (0,14,0);
				alternate = 0;
				break;
		}
		level.expack[i] = spawn_model(game["bomb_ready"], "expack", origin, angles);
		level.expack[i].startorigin = origin;
		level.expack[i].startangles = angles;
		level.expack[i] thread startExPack(i);

	}
	thread addbombcounterHUD();
	thread nextExPack();
	wait 0.05;
	level notify("nextExPack");
}

// find the next expack in the supply box, and start the thinker code for it
nextExPack()
{
	for(;;)
	{
		self waittill("nextExPack");
		for(i = level.numofpacks-1; i >= 0; i--)
		{
			if(level.expack[i].status == "spawned")
			{
				level.expack[i] thread expackThinker();
				break;
			}
		}
		wait 0.05;
	}
}

// wait before the next expack goes live
timerelease()
{
	wait level.packreleasetime;

	fielded = level.packreleasemax;
	while(fielded >= level.packreleasemax)
	{
		fielded = 0;
		for(i = 0; i < level.numofpacks; i++)
		{
			if(level.expack[i].status == "dropped" ||
				level.expack[i].status == "carried" ||
				level.expack[i].status == "planting" ||
				level.expack[i].status == "defusing"
				)
				fielded++;
		}
		wait 0.05;
	}
	level notify("nextExPack");
}

startExPack(i)
{
	self.player = undefined;
	self.playerNum = -1;
	self.status = "spawned";
	self.oldstatus = "spawned";
	self.kaboom = false;
	self.i = i;
	self.protect = level.protectspawnbombs;

	self.objnum = i+5;// start at 5, bomb objectives are 3 and 4, spawn box is 2, spawn indicators are 0, 1
	objective_add(self.objnum, "current", self.origin, "gfx/hud/objective.tga");
	objective_icon(self.objnum, "gfx/hud/objective.tga");
	objective_team(self.objnum, game["attackers"]);
	objective_position(self.objnum, self.origin);
	objective_onEntity(self.objnum, self);
}


expackThinker()
{
	self.maxdist = 50;
	self endon("smote");
	self endon("spawned");

	while(self.status != "defused" && self.status != "exploded" && self.status != "success") // thinking loop, not needed if defused or exploded
	{
		while(self.status == "carried") // bomb is being carried
		{
			wait 0.05;
			if(self.status != "carried")
				continue;  // redundancy, to safely account for the attackButtonPressed code

			//planting the bomb
			while(isdefined(self.player) && 
				isalive(self.player) && 
				isdefined(self.player.planticon) && 
				self.player isOnGround() && 
				self.player useButtonPressed())
			{
				self.status = "planting";

				if(self.player attackButtonPressed() || self.player meleeButtonPressed())
				{
					self.status = "carried";
					wait 0.95; // they're trying to plant, but firing a weapon
					continue;
				}


				if(!isdefined(self.progressbackground))
				{
					self.progressbackground = newClientHudElem(self.player);				
					self.progressbackground.alignX = "center";
					self.progressbackground.alignY = "middle";
					self.progressbackground.x = 320;
					self.progressbackground.y = 385;
					self.progressbackground.alpha = 0.5;
				}
				self.progressbackground setShader("black", (level.barsize + 4), 12);		

				if(!isdefined(self.progressbar))
				{
					self.progressbar = newClientHudElem(self.player);				
					self.progressbar.alignX = "left";
					self.progressbar.alignY = "middle";
					self.progressbar.x = (320 - (level.barsize / 2.0));
					self.progressbar.y = 385;
				}
				self.progressbar setShader("white", 0, 8);
				self.progressbar scaleOverTime(level.planttime, level.barsize, 8);

				self.player playsound("MP_bomb_plant");
				self.player linkTo(self.targetZone); // self.targetZone created by bombtarget(), called by bombzone_think()

				self.targetZone.planted++;
				level.livebombs++; // time won't run out during a plant, or if a bomb is ticking

				progresstime = 0;
				while(isalive(self.player)
					&& self.player istouching(self.targetZone) 
					&& self.player useButtonPressed() 
					&& !(self.player attackButtonPressed()) 
					&& !(self.player meleeButtonPressed()) 
					&& (progresstime < level.planttime))
				{
					progresstime += 0.05;
					wait 0.05;
				}
	
				if(progresstime >= level.planttime)
				{
					self.player.planticon destroy();
					self.progressbackground destroy();
					self.progressbar destroy();

					self thread plantExPack(self.targetZone, self.player); //plant the bomb
				}
				else
				{
					self.progressbackground destroy();
					self.progressbar destroy();
					if(isalive(self.player))
					{
						self.player unlink();  // LET GO OF ME
						self.status = "carried"; // mark the expack as still being carried
					}
					// if the player is dead, "dropbomb()" was called to set the status and update the HUD
					self.targetZone.planted--;
					level.livebombs--;
				}
				wait 0.05;
			}
			if(self.status == "planted") // if it got planted, don't do the "drop" code
				continue;

			// the player is killed, the "dropbomb()" is called, don't do it here
			if(!isdefined(self.player) || !isalive(self.player))
				continue;

			// player disconnected, or has pressed the USE key
			if (self.player.sessionstate=="playing" && self.player usebuttonpressed() && !(isdefined(self.player.awe_sprinting)) && self.player isOnGround())
			{
				self.holdtime = 0;
				if(self.player usebuttonpressed() && !(self.player attackButtonPressed()) && !(self.player meleeButtonPressed()) && !(isdefined(self.player.awe_sprinting)) && self.player isOnGround()) // set up the "dropping bomb" animation
				{
					// first, don't wanna do anything if they just tap USE to pick something up
					pausetime = 0;
					while(isalive(self.player) 
						&& self.player usebuttonpressed() 
						&& !(self.player attackButtonPressed()) 
						&& !(self.player meleeButtonPressed())
						&& !(isdefined(self.player.awe_sprinting))
						&& self.player isOnGround() 
						&& pausetime < 0.5)
					{
						pausetime += 0.05;
						wait 0.05;
					}
					if(pausetime < 0.5) // if they just tapped it, not holding for a half-second
						continue;

					if(self.status != "carried") //may be planting
						continue;

					self notify("stopcleanbombhud");
					if(isdefined(self.player) && isalive(self.player) && !isdefined(self.player.carriericon))
					{
						self.player.carriericon = newClientHudElem(self.player);				
						self.player.carriericon.alignX = "center";
						self.player.carriericon.alignY = "middle";
						self.player.carriericon.x = 600;
						self.player.carriericon.y = 410;
						self.player.carriericon.alpha = 1;
						self.player.carriericon setShader(game["status_bombstar"], 32, 32);
					}
					if(isdefined(self.player.bombdrop))
						self.player.bombdrop destroy();
					self.player.bombdrop = newClientHudElem(self.player);				
					self.player.bombdrop.alignX = "center";
					self.player.bombdrop.alignY = "middle";
					self.player.bombdrop.x = 600;
					self.player.bombdrop.y = 240;
					self.player.bombdrop.alpha = 0;
					self.player.bombdrop setShader(game["status_bombstar"], 64, 64);

					self.player.bombdrop fadeOverTime(.5);
					self.player.bombdrop.alpha = .25;

					self.player.carriericon moveOverTime(1);
					self.player.carriericon.y = 240;
					self.player.carriericon scaleOverTime(1, 64, 64);
				}
				while (isdefined(self.player) 
						&& self.player.sessionstate == "playing" 
						&& self.player usebuttonpressed() 
						&& self.status == "carried" 
						&& !(self.player attackButtonPressed()) 
						&& !(self.player meleeButtonPressed()) 
						&& self.player isOnGround()
						&& self.holdtime < 1)
				{
					self.holdtime += 0.05;
					wait 0.05; //this will also give plant code time to take effect
				}
				self thread cleanBombDropHUD();

				// if you're not still carrying it, or you're in the air, or didn't hold USE for a full 1 second
				if((isdefined(self.player) && isalive(self.player) && self.holdtime < 1) 
					|| self.status != "carried" 
					|| (isdefined(self.player) && isalive(self.player) && !(self.player isOnGround())) ) 
				{
					continue;
				}

				self dropbomb();

				wait 2;
			}
		}

		while(self.status == "dropped" || self.status == "planted" || self.status == "spawned") // bomb is waiting on pickup or defuse
		{
			// not being carried, wait for player to pick it up
			players = getentarray("player", "classname");
			for(p = 0; p < players.size; p++)
			{
				player = players[p];

				if(!isdefined(player.pers["team"]) || player.sessionstate != "playing") // not playing, ignore 'em
					continue;

				if(player.carrying) // already carrying a bomb, ignore 'em
					continue;

				if(player.expacki != -1 && player.expacki != self.i) // busy with another pack
					continue;

				dist = distance(player.origin,self.origin); // calculate distance

				if(dist<self.maxdist) // player is in range
				{
					if(	   isPlayer(player) 
						&& isdefined(player.pers["team"]) 
						&& player.pers["team"] == game["attackers"]
						&& player.sessionstate == "playing"
					)
						self thread pickmeup(player);

					player.expacki = self.i; // mark this player as touching this pack

					// defenders defuse the packs
					if(isPlayer(player) 
						&& (player.pers["team"] == game["defenders"]) 
						&& player isOnGround()
						&& !(player attackButtonPressed())
						&& !(player meleeButtonPressed())
						&& self.protect == 0)
					{
						if(!isdefined(player.defuseicon))
						{
							player.defuseicon = newClientHudElem(player);				
							player.defuseicon.alignX = "center";
							player.defuseicon.alignY = "middle";
							player.defuseicon.x = 320;
							player.defuseicon.y = 345;
							player.defuseicon setShader("ui_mp/assets/hud@defusebomb.tga", 64, 64);	
						}
			
						while(dist < self.maxdist 
							&& isalive(player) 
							&& player useButtonPressed() 
							&& !(player attackButtonPressed())
							&& !(player meleeButtonPressed())  )
						{
							player notify("kill_check_hud");

							if(!isdefined(self.progressbackground))
							{
								self.progressbackground = newClientHudElem(player);				
								self.progressbackground.alignX = "center";
								self.progressbackground.alignY = "middle";
								self.progressbackground.x = 320;
								self.progressbackground.y = 385;
								self.progressbackground.alpha = 0.5;
							}
							self.progressbackground setShader("black", (level.barsize + 4), 12);		

							if(!isdefined(self.progressbar))
							{
								self.progressbar = newClientHudElem(player);				
								self.progressbar.alignX = "left";
								self.progressbar.alignY = "middle";
								self.progressbar.x = (320 - (level.barsize / 2.0));
								self.progressbar.y = 385;
							}
							self.progressbar setShader("white", 0, 8);			
							self.progressbar scaleOverTime(level.defusetime, level.barsize, 8);

							player playsound("MP_bomb_defuse");
							player linkTo(self);

							if(level.drawfriend == 1)
							{
								player.headicon = game["status_bombstar"];
								player.headiconteam = player.pers["team"];
							}
							if(self.status == "dropped")
								objective_team(self.objnum, "none"); // let the defenders know where the dropped bomb is

							progresstime = 0;
							self.oldstatus = self.status;
							self.status = "defusing";

							while(isalive(player) 
								&& player useButtonPressed() 
								&& !(player attackButtonPressed()) 
								&& !(player meleeButtonPressed()) 
								&& (progresstime < level.defusetime))
							{
								progresstime += 0.05;
								wait 0.05;
							}
							if(level.drawfriend == 1)
							{
								headicon = "headicon_" + player.pers["team"];
								player.headicon = game[headicon];
								player.headiconteam = player.pers["team"];
							}
							
							if(progresstime >= level.defusetime)
							{
								player.defuseicon destroy();
								self.progressbackground destroy();
								self.progressbar destroy();

								lpselfnum = player getEntityNumber();
								logPrint("A;" + lpselfnum + ";" + game["defenders"] + ";" + player.name + ";" + "bomb_defuse" + "\n");
					
								tellplayers = getentarray("player", "classname");
								for(i = 0; i < tellplayers.size; i++)
									tellplayers[i] playLocalSound("MP_announcer_bomb_defused");

								self thread defuseExPack(player); // set the bomb's properties for defuse
								player.pers["score"] += level.defusebonus; // 3 bonus points for defusing the bomb
								player.score = player.pers["score"];

								player unlink();

								player.defusing = undefined;
								player.expacki = -1;  //release the player for other packs
								return; // if it's defused, might as well stop here
							}
							else
							{
								objective_team(self.objnum, game["attackers"]);
								self.progressbackground destroy();
								self.progressbar destroy();
								player unlink();
								if(self.status != "exploded" && self.status != "success")
								{
									self.status = self.oldstatus;
									self.oldstatus = undefined;
								}

								if(isalive(player) && player useButtonPressed() 
									&& (player attackButtonPressed() || player meleeButtonPressed()) )
								{
									wait 1; // player fired a weapon while trying to defuse
								}
							}
				
							wait .05;
							dist = distance(player.origin,self.origin); // calculate distance
						}

						player.defusing = undefined;
						player thread check_hud_bomb(self, player.defuseicon);
						player.expacki = -1;  //release the player for other packs
					}

					// attackers pick up the expacks
					if(player.pers["team"] == game["attackers"] && player usebuttonpressed() && (self.status == "dropped" || self.status == "spawned"))
					{
						if(isdefined(player) && player.sessionstate == "playing")
						{ // they're still alive

							self notify("stabilized"); // in case it had been dropped
							self notify("stopcleanbombhud"); // don't delete the carrier icon
							self.status = "carried";
							self.player = player;
							self.playerNum = player getEntityNumber();
							objective_onentity(self.objnum, player);
							self thread updatebombcounter();
							self.protect = 0; // this can now be defused if dropped

							player.carrying = true;
							player.expacki = self.i;
							player playsound("grenade_pickup");
							
							player thread keepicons();

							if(isdefined(player.carriericon))
								player.carriericon destroy();
							player thread animateCarrierIcon();

							self hide();

							while (isdefined(self.player) && self.player.sessionstate == "playing" && self.player usebuttonpressed())
								wait 0.05;
							// continue the thread 'till the USE key is released
						}
					}
				}
				else  // not in range
				{
					if(player.expacki == self.i)
						player.expacki = -1;  //release the player for other packs
				}
			}
			wait 0.05;
		}
		
		wait 0.05; // pause the loop for 1/20th of a second, approx. 1 game frame
	}
}

keepicons()
{
	self endon("lostbomb");
	self endon("killed");

	while(isdefined(self) && isAlive(self) && isPlayer(self) && self.sessionstate == "playing" && isdefined(self.carrying) && self.carrying)
	{
		self.statusicon = game["status_bombstar"];
		if(level.drawfriend)
		{
			self.headicon = game["status_bombstar"];
			self.headiconteam = self.sessionteam;
		}
		wait 0.2;
	}
}


pickmeup(player)
{
	if(!isdefined(player.pickupicon))
	{
		player.pickupicon = newClientHudElem(player);				
		player.pickupicon.alignX = "center";
		player.pickupicon.alignY = "middle";
		player.pickupicon.x = 320;
		player.pickupicon.y = 345;
		player.pickupicon setShader("gfx/icons/hint_usable.tga", 64, 64);	
	}

	while(distance(self.origin, player.origin) < self.maxdist
		&& isalive(player) 
		&& (self.status == "dropped" || self.status == "spawned")
	){
		wait 0.05;
	}

	if(isdefined(player.pickupicon))
		player.pickupicon destroy();
}

cleanBombDropHUD()
{
	self notify("stopcleanbombhud");
	self endon("stopcleanbombhud");
	self endon("killed");

	if(!isdefined(self.player))
		return;

	player = self.player;
	if(isdefined(player.bombdrop))
	{
		player.bombdrop destroy();
	}
	if(self.holdtime < 1 && isdefined(player.carriericon))
	{
		player.carriericon scaleOverTime(.5, 32, 32);
		player.carriericon moveOverTime(.5);
		player.carriericon.y = 410;
	}
	if(self.holdtime >= 1 && isdefined(player.carriericon))
	{
		player.carriericon scaleOverTime(1, 128, 128);
		player.carriericon fadeOverTime(1);
		player.carriericon.alpha = 0;
		wait 1;

		if(isdefined(player.carriericon))
			player.carriericon destroy();
	}
}


animateCarrierIcon()
{
	self endon("lostbomb");

	if(isdefined(self.carriericon))
	{
		self.carriericon destroy();
	}

	self.carriericon = newClientHudElem(self);				
	self.carriericon.alignX = "center";
	self.carriericon.alignY = "middle";
	self.carriericon.x = 600;
	self.carriericon.y = 240;
	self.carriericon.alpha = 0;
	self.carriericon setShader(game["status_bombstar"], 64, 64);

	self.carriericon fadeOverTime(1);
	self.carriericon.alpha = 1;
	self.carriericon scaleOverTime(1, 32, 32);
	self.carriericon moveOverTime(1);
	self.carriericon.y = 410;
}



plantExPack(target, player)
{
	self.timer = addBombTimer(target.icon);

/*	if(level.drawfriend == 1)
	{
		headicon = "headicon_" + player.pers["team"];
		player.headicon = game[headicon];
		player.headiconteam = player.pers["team"];
	}*/

	if(level.drawfriend)
	{
		if(level.battlerank)
		{
			player.statusicon = maps\mp\gametypes\_rank_gmi::GetRankStatusIcon(player);
			player.headicon = maps\mp\gametypes\_rank_gmi::GetRankHeadIcon(player);
		}
		else
		{
			player.statusicon = "";
			player.headicon = game["headicon_" + player.sessionteam];
		}
		player.headiconteam = player.sessionteam;
	}
	else
	{
		if(level.battlerank)
		{
			player.headicon = "";
			player.statusicon = maps\mp\gametypes\_rank_gmi::GetRankStatusIcon(player);
		}	
		else
		{
			player.headicon = "";
			player.statusicon = "";
		}
	}

	player.carrying = false;
	player.expacki = -1;
	player.pers["score"] += level.plantbonus; // bonus point for planting
	player.score = player.pers["score"];
//	player.statusicon = "";

	objective_delete(self.objnum);
	iprintlnbold(player.name + "^7 has planted a bomb on ^2" + target.myname);

	self.status = "planted";
	self.objnum = target.objnum;
	self.icon = target.icon;
	self.targeti = target.i;
	self.myname = target.myname;
	self.planter = player;
	objective_onentity(self.objnum, self);
	objective_icon(self.objnum,"gfx/hud/hud@bombplanted.tga");
	objective_team(self.objnum, "none"); // just to make sure

	self thread updatebombcounter();

	self.player = undefined;
	self.playerNum = -1;

//	target.planted++;

// START moved from expackthinker
	level.bombcam = getent(target.target, "targetname");
	level.bombexploder[target.objnum] = target.script_noteworthy;
					
	player unlink(); // LET GO OF ME!
	
	plant = player maps\mp\_utility::getPlant();

	self.origin = plant.origin;
	self.angles = plant.angles;
	self playSound("Explo_plant_no_tick");

	self setmodel(game["bomb_planted"]);
	self show();

	level.bombcam.angles = vectortoangles(self.origin - level.bombcam.origin);
					
	lpselfnum = player getEntityNumber();
	logPrint("A;" + lpselfnum + ";" + game["attackers"] + ";" + player.name + ";" + "bomb_plant" + "\n");
					
	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
		players[i] playLocalSound("MP_announcer_bomb_planted");

	self thread bomb_countdown(target); // countdown knows who planted the bomb
// END moved from expackthinker

	if(isdefined(player.carriericon))
	{
		player.carriericon scaleOverTime(1, 128, 128);
		player.carriericon fadeOverTime(1);
		player.carriericon.alpha = 0;
		wait 1;

		player.carriericon destroy();
	}

}


defuseExPack(player)
{
	level.packsLeft--;
	self notify("stabilized");  // so there won't be a non-existent bomb blowing up later
	if(self.status == "defusing" && self.oldstatus == "planted") // it was put into action, not just dropped
	{
		self notify("bomb_defused"); // stop the countdown
		self stopLoopSound(); // stop the ticking sound
		if(self.targetZone.planted == 1) // this is the last bomb on the target, reset the objective icon
			objective_icon(self.objnum, self.icon); 
		level.livebombs--;
		iprintlnbold(player.name + "^7 has defused a bomb on ^2" + self.myname);
		self.targetZone.planted--;
		self.targeti = -1;
	}

	if(self.status == "defusing" && (self.oldstatus == "dropped" || self.oldstatus == "spawned")){
		objective_delete(self.objnum); // defused from the ground, expack objective deleted
		iprintlnbold(player.name + "^7 has disabled a bomb");
	}

	self.status = "defused";
//	self.oldstatus = "undefined";
	self hide();
	self thread updatebombcounter();
	if(self.oldstatus == "planted")
		self thread removeBombTimer();
	

	// check remaining number of targets, and remaining number of explosive packs
	if(level.requiredTargets - (2 - level.targetsLeft) > level.packsLeft)
	{ // too many exPacks have been defused for attackers to win
		players = getentarray("player", "classname");
		for(i = 0; i < players.size; i++)
			players[i] playLocalSound("MP_announcer_bomb_defused");
		wait 2;
		level thread hud_announce(&"SD_AXISMISSIONACCOMPLISHED");
		level thread endRound(game["defenders"]);
	}
}


unstableBomb(thisPlayer)
{
	playername = thisPlayer.name;
	self endon("stabilized");
	if(self.kaboom)
	{ // random chance happened, it should go kaboom
		wait level.kaboomdelay;
	}
	else
	{
		wait level.unstabledelaymin;
		unstability = level.unstabledelaymax - level.unstabledelaymin;
		unstability = randomInt(unstability);
		wait unstability;
	}

	// bomb timer is up, KABOOM
	objective_delete(self.objnum);

	level.packsLeft--;

	// explode bomb
	range = 360;
	maxdamage = 300;
	mindamage = 10;


	playfx(level._effect["bombexplosion"], self.origin);
	radiusDamage(self.origin + (0,0,12), range, maxdamage, mindamage);
	
	self hide();
	self.status = "exploded";
	self thread updatebombcounter();
	iprintlnbold("The bomb dropped by " + playername + "^7 has exploded.");

	// check remaining number of targets, and remaining number of explosive packs
	if(level.requiredTargets - (2 - level.targetsLeft) > level.packsLeft)
	{ // too many exPacks have been defused for attackers to win
		if(game["defenders"] == "axis")
			level thread hud_announce(&"SD_AXISMISSIONACCOMPLISHED");
		else
			level thread hud_announce(&"SD_ALLIESMISSIONACCOMPLISHED");
		level thread endRound(game["defenders"]);
	}
}

announceObjectives()
{
	wait 3;
	if(game["attackers"] == "allies")
		iprintlnbold("The Allies must destroy " + level.requiredTargets + " of the objectives");
	else
		iprintlnbold("The Axis must destroy " + level.requiredTargets + " of the objectives");
}


forceSpectator()
{		
	nextSpecButton = false;
	prevSpecButton = false;
	
	nextSpec = false;
	prevSPec = false;
	
	for (;;)
	{
			wait 0.05;

			if (self.sessionstate != "spectator" || self.archivetime != 0 || (getcvar("g_ioteamspec") != "1"))
				continue;

			if (!nextSpecButton && self attackButtonPressed())
				nextSpecButton = true;
			else if (nextSpecButton && !(self attackButtonPressed()))
			{
				nextSpecButton = false;
				nextSpec = true;
			}

			if (!prevSpecButton && self meleeButtonPressed())
				prevSpecButton = true;
			else if (prevSpecButton && !(self meleeButtonPressed()))
			{
				prevSpecButton = false;
				prevSpec = true;
			}

			players = getentarray("player", "classname");

			nextClient = self.spectatorclient;

			if (nextClient == -1)
			{
				for(i = 0; i < players.size; i++)
				{
					player = players[i];

					if(!isdefined(player.pers["team"]) || player.pers["team"] == "spectator" || player == self || player.sessionstate == "spectator" || player.pers["team"] != self.pers["team"])
						continue;

					if (nextClient == -1)
					{
						nextClient = player getEntityNumber();					
					}						
				}					
			}
			else 
			{
				j = -1;				

				for(i = 0; i < players.size; i++)
				{
					if (players[i] getEntityNumber() == nextClient)
						j = i;
				}
				
				if ( j == -1 )
				{
					nextClient = -1;
				}
				else
				{				
					player = players[j];

					if(nextSpec || prevSpec || !isdefined(player.pers["team"]) || player.pers["team"] == "spectator" || player.sessionstate == "spectator" || player == self || player.pers["team"] != self.pers["team"])				
					{								
						lowestClient = -1;
						highestClient = -1;
						prevClient = -1;
						afterClient = -1;
 				
						for(i = 0; i < players.size; i++)
						{					
							player = players[i];
						
							if(isdefined(player.pers["team"]) && player.pers["team"] == self.pers["team"] && player.sessionstate != "spectator")
							{
								playerNum = player getEntityNumber();

								if ( playerNum > nextClient && (afterClient == -1 || playerNum < afterClient))
								{
									afterClient = playerNum;
								}
								if ( playerNum < nextClient && (prevClient == -1 || playerNum > prevClient))
								{
									prevClient = playerNum;
								}
								if ( playerNum < lowestClient || lowestClient == -1 )
								{
									lowestClient = playerNum;
								}
								if ( playerNum > highestClient || highestClient == -1 )
								{
									highestClient = playerNum;
								}
							}
						}	

						if (nextSpec && afterClient != -1)
							nextClient = afterClient;
						else if (prevSpec && prevClient != -1)
							nextClient = prevClient;
						else if (nextSpec)
							nextClient = lowestClient;
						else
							nextClient = highestClient;													
					
					}
				}
			}

			

			if ( nextClient != -1 && self.spectatorClient != nextClient)
			{		
				self.spectatorClient = nextClient;

			}
			else if (nextClient == -1)
			{
				self.spectatorClient = -1;
			}

			nextSpec = false;
			prevSpec = false;
	}
}


reinforcements(team)
{
	level.respawnTimeLeft[team] = level.respawndelay[team];
	if(level.respawnTimeLeft[team] < 1)
		level.respawnTimeLeft[team] = 1;

	reinforcehud = newTeamHudElem(team);
	reinforcehud.archived = false;
	reinforcehud.x = 300;
	reinforcehud.y = 450;
	reinforcehud.alignX = "center";
	reinforcehud.alignY = "middle";
	reinforcehud.fontScale = 1;
	reinforcehud.sort = 1;
	reinforcehud setText(&"Reinforcements in:");


	teamtimer = newTeamHudElem(team);
	teamtimer.archived = false;
	teamtimer.x = 365;
	teamtimer.y = 450;
	teamtimer.alignX = "center";
	teamtimer.alignY = "middle";
	teamtimer.fontScale = 1;
	teamtimer.sort = 1;

	teamtimer setTimer(level.respawndelay[team]);

	for(;;)
	{
		while(level.respawnTimeLeft[team] > 0)
		{
			wait 1;
			level.respawnTimeLeft[team]--;
		}
		if(team == game["attackers"])
			spawnlist = reviseAttackerSpawnPoints();
		else
			spawnlist = reviseDefenderSpawnPoints();

		spawnlist = sortByDist(spawnlist, spawnlist[spawnlist.size-1]); // sort 'em by distance from the farthest forward point
		thread goteamgo(team, spawnlist); // delayed spawn in a thread so it doesn't actually delay the waves

		teamtimer setTimer(level.respawndelay[team]);
		level.respawnTimeLeft[team] = level.respawndelay[team];
	}
}

goteamgo(team, spawnlist)
{
	players = getentarray("player", "classname");
	spawni = 0;
	for(p = 0; p < players.size; p++)
	{
		if(isdefined(players[p].pers["team"]) && players[p].pers["team"] == team && isdefined(players[p].iswaiting))
		{
			while(positionWouldTelefrag(spawnlist[spawni].origin))
				spawni++;
			players[p] thread spawnplayer(spawnlist[spawni]);
			spawni++;
			wait 0.05; // avoid siamese twins
		}
	}
}


defineSpawnPoints()
{
	// internal shorthand for team definitions
	att = game["attackers"];
	def = game["defenders"];

	if(!isdefined(level.tdmspawn))
	{
		level.tdmspawn = [];

		// create spawnpoint arrays for the attackers and defenders, including S&D and TDM points
		if(att == "allies")
		{
			att_sd = getentarray("mp_searchanddestroy_spawn_allied", "classname");
			def_sd = getentarray("mp_searchanddestroy_spawn_axis", "classname");
		}
		else
		{
			att_sd = getentarray("mp_searchanddestroy_spawn_axis", "classname");
			def_sd = getentarray("mp_searchanddestroy_spawn_allied", "classname");
		}
		// add TDM spawnpoints onto each team's possible list
		tdm_spawnpoints = getentarray("mp_teamdeathmatch_spawn", "classname");

		level.tdmspawn[att] = sortByDist(tdm_spawnpoints, att_sd[0]);

		// defenders get 1/2 of the map for forced displacement, doesn't change
		temp = [];
		j = 0;
		for(i = 0; i < tdm_spawnpoints.size; i++)
		{
			// skip points that are closer to the attacker's spawn than they are to defenders
			if(distance(tdm_spawnpoints[i].origin, def_sd[0].origin) > distance(tdm_spawnpoints[i].origin, att_sd[0].origin))
				continue;

			temp[j] = tdm_spawnpoints[i];
			j++;
		}

		level.tdmspawn[def] = temp;
	}

	return true;
}

reviseDefenderSpawnPoints()
{
	// this is a test
	att = game["attackers"];
	def = game["defenders"];

	// get this team's S&D spawnpoints
	def_spawn = [];
	att_spawn = [];
	if(def == "allies")
	{
		def_spawn = getentarray("mp_searchanddestroy_spawn_allied", "classname");
		att_spawn = getentarray("mp_searchanddestroy_spawn_axis", "classname");
	}
	else
	{
		def_spawn = getentarray("mp_searchanddestroy_spawn_axis", "classname");
		att_spawn = getentarray("mp_searchanddestroy_spawn_allied", "classname");
	}

	// if both targets are planted, use S&D points
	if(	   level.targets[0].planted > 0 && level.targets[1].status == "live" 
		&& level.targets[1].planted > 0 && level.targets[1].status == "live" )
	{
		return def_spawn;  // both targets planted, use S&D spawns 
	}

	// if no bombs are in play, use S&D points
	inplay = 0;
	for(i = 0; i < level.expack[i].size; i++)
	{
		if(	   level.expack[i].status == "carried"
			|| level.expack[i].status == "dropped"
			|| level.expack[i].status == "planted"
			|| level.expack[i].status == "planting"
			|| level.expack[i].status == "defusing"
			|| level.expack[i].status == "minefield" )
		{
			inplay++;
		}
	}
	if(inplay == 0)
		return def_spawn;

	// if less than both targets were planted, gotta use smarter stuff, continue thinking
	
	// create seperate lists of the current attacking and defending players currently alive
	a = 0;
	d = 0;
	att_players = [];
	def_players = [];
	players = getentarray("player", "classname");
	for(p = 0; p < players.size; p++)
	{
		if(!isdefined(players[p].pers["team"]) || players[p].sessionstate != "playing")
			continue;
		if(players[p].pers["team"] == att)
		{
			att_players[a] = players[p];
			a++;
		}
		if(players[p].pers["team"] == def)
		{
			def_players[d] = players[p];
			d++;
		}
	}

	// find the best spawn point for the defending team
	// RULES:
	// 1. No forward mobility, unless forced by attacker's control of a target
	// 2. Don't spawn at a TDM past any existing players
	/////////////////////////////////////////////////////////////////////////////

	dist_target = 1000000;
	dist_enemy = 1000000;
	dist_friend = 1000000;

	def_spawn_tdm = level.tdmspawn[def];

	// 1. Check for attacker control of targets

	// if an attacker's within 75 feet of Target A , it's "contested"
	att_proximityA = sortByDist(att_players, level.targets[0], 900);
	if(isdefined(att_proximityA[0]))
	{
		// tdm spawn points at least 100 feet away from the target
		def_spawn_tdm = sortByDist(def_spawn_tdm, level.targets[0], undefined, 1200); 
	}

	// if an attacker's within 75 feet of Target , it's "contested"
	att_proximityB = sortByDist(att_players, level.targets[1], 900); 
	if(isdefined(att_proximityB[0]))
	{
		// tdm spawn points at least 100 feet away from the target
		def_spawn_tdm = sortByDist(def_spawn_tdm, level.targets[1], undefined, 1200); 
	}

	if(isdefined(def_spawn_tdm[0]))
	{
		for(i = 0; i < def_spawn_tdm.size; i++)
		{
			att_proximity = sortByDist(att_players, def_spawn_tdm[i], 600); // use maximum of 600 inches, 50 feet
			if(isdefined(att_proximity[0]))
				continue; // there are enemies within 50 feet, don't spawn here
			def_spawn[def_spawn.size] = def_spawn_tdm[i];
		}
	}
/*
	if(isdefined(att_proximityA[0]) && !isdefined(att_proximityB[0]))
		def_spawn = sortByDist(def_spawn, level.targets[0]);

	if(isdefined(att_proximityB[0]) && !isdefined(att_proximityA[0]))
		def_spawn = sortByDist(def_spawn, level.targets[1]);
*/

	return def_spawn;
}

reviseAttackerSpawnPoints()
{
	// internal shorthand for team definitions
	att = game["attackers"];
	def = game["defenders"];

	// get this team's S&D spawnpoints
	att_spawn = [];
	if(att == "allies")
		att_spawn = getentarray("mp_searchanddestroy_spawn_allied", "classname");
	else
		att_spawn = getentarray("mp_searchanddestroy_spawn_axis", "classname");

	// create seperate lists of the current attacking and defending players currently alive
	a = 0;
	d = 0;
	att_players = [];
	def_players = [];
	players = getentarray("player", "classname");
	for(p = 0; p < players.size; p++)
	{
		if(!isdefined(players[p].pers["team"]) || players[p].sessionstate != "playing")
			continue;
		if(players[p].pers["team"] == att)
		{
			att_players[a] = players[p];
			a++;
		}
		if(players[p].pers["team"] == def)
		{
			def_players[d] = players[p];
			d++;
		}
	}


	// find the best spawn point for the attacking team
	// RULES:
	// 1. Farthest forward spawn is 1/3-rd the distance to the closest live target
	// 2. Don't spawn at a TDM past any existing players or fielded bombs
	/////////////////////////////////////////////////////////////////////////////

	dist_target = 1000000;
	dist_enemy =  1000000;
	dist_friend = 1000000;
	dist_bomb =   1000000;

	// 1. Find the closest target
	targets = sortByDist(level.targets, att_spawn[0]); //
	dist_target = distance(att_spawn[0].origin, targets[1].origin) / 3; // assume farthest target as marker
	if(targets[0].status == "live")
		dist_target = distance(att_spawn[0].origin, targets[0].origin) / 2; // adjust, closest target as marker
	
	// 2a. Find the closest defender	
	def_proximity = sortByDist(def_players, att_spawn[0]);
	if(isdefined(def_proximity[0]))
		dist_enemy = distance(att_spawn[0].origin, def_proximity[0].origin); // closest enemy

	// 2b. Find the closest attacker
	att_proximity = sortByDist(att_players, att_spawn[0]);
	if(isdefined(att_proximity[0]))
		dist_friend = distance(att_spawn[0].origin, att_proximity[0].origin); // closest friend

	// 2c. Find the closest bomb
	bomb_proximity = sortByDist(level.expack, att_spawn[0]);
	if(isdefined(bomb_proximity[0]))
	{
		for(i = 0; i < bomb_proximity.size; i++)
		{
			if(	   bomb_proximity[i].status == "carried"
				|| bomb_proximity[i].status == "dropped"
				|| bomb_proximity[i].status == "planted"
				|| bomb_proximity[i].status == "planting"
				|| bomb_proximity[i].status == "defusing"
				|| bomb_proximity[i].status == "minefield"
			)
			{
				if(bomb_proximity[i].status == "carried")
					b_origin = bomb_proximity[i].player.origin;
				else
					b_origin = bomb_proximity[i].origin;

				dist = distance(att_spawn[0].origin, b_origin); // distance to bomb
				if(dist < dist_bomb)
					dist_bomb = dist; // closest bomb
			}
		}
		// bombs were defined, were there any out of the box?
		if(dist_bomb == 1000000)
			return att_spawn; // nope.  Use S&D spawns.
	}

 	// compare the results
	maxdist = dist_target; // farthest possible point
dtype = "target";
	if(dist_enemy < maxdist)
	{
dtype = "enemy";
		maxdist = dist_target;
	}
	if(dist_friend < maxdist)
	{
dtype = "friend";
		maxdist = dist_friend;
	}
	if(dist_bomb < maxdist)
	{
dtype = " bomb ";
		maxdist = dist_bomb;
	}
	// get all the TDM spawnpoints in range, away from enemies
	for(i = 0; i < level.tdmspawn[att].size && distance(att_spawn[0].origin, level.tdmspawn[att][i].origin) <= maxdist; i++)
	{
		def_proximity = sortByDist(def_players, level.tdmspawn[att][i], 600); // use maximum of 600 inches, 50 feet
		if(isdefined(def_proximity[0]))
			continue; // there are enemies within 50 feet, don't spawn here

		att_spawn[att_spawn.size] = level.tdmspawn[att][i];
	}
 // iprintln("type: " + dtype + ", range: " + maxdist);
 // iprintln("friend: " + dist_friend);
 // iprintln("S&D: " + sd + ", TDM: "+ level.tdmspawn[att].size + ", Final: " + att_spawn.size);
	return att_spawn;
}




// sort a list of entities with ".origin" properties in ascending order by their distance from the "startpoint"
// "points" is the array to be sorted
// "startpoint" (or the closest point to it) is the first entity in the returned list
// "maxdist" is the farthest distance allowed in the returned list
// "mindist" is the nearest distance to be allowed in the returned list
sortByDist(points, startpoint, maxdist, mindist)
{
	if(!isdefined(points))
		return undefined;
	if(!isdefineD(startpoint))
		return undefined;

	if(!isdefined(mindist))
		mindist = -1000000;
	if(!isdefined(maxdist))
		maxdist = 1000000; // almost 16 miles, should cover everything.

	sortedpoints = [];

	max = points.size-1;
	for(i = 0; i < max; i++)
	{
		nextdist = 1000000;
		next = undefined;

		for(j = 0; j < points.size; j++)
		{
			thisdist = distance(startpoint.origin, points[j].origin);
			if(thisdist <= nextdist && thisdist <= maxdist && thisdist >= mindist)
			{
				next = j;
				nextdist = thisdist;
			}
		}

		if(!isdefined(next))
			break; // didn't find one that fit the range, stop trying

		sortedpoints[i] = points[next];

		// shorten the list, fewer compares
		points[next] = points[points.size-1]; // replace the closest point with the end of the list
		points[points.size-1] = undefined; // cut off the end of the list
	}

	sortedpoints[sortedpoints.size] = points[0]; // the last point in the list

	return sortedpoints;
}



showTeamSpawnPoint(team, objnum)
{
	objective_add(objnum, "current", level.tdmspawn[team][0].origin, "gfx/hud/hud@objectivegoal.tga");
	objective_team(objnum, team);


	for(;;)
	{
		wait 3;
		if(team == game["attackers"])
			spawnlist = reviseAttackerSpawnPoints();
		else
			spawnlist = reviseDefenderSpawnPoints();

		objective_position(objnum, spawnlist[spawnlist.size-1].origin);

	}
}


waitForRespawn(team)
{
	if(isdefined(self.iswaiting))
		return;

	self.iswaiting = true;

	if(isdefined(self.respawnhud))
	{
		self.respawnhud destroy();
		self.respawntimer destroy();
	}

	team = self.pers["team"];

	if(level.respawnTimeLeft[team] < 1)
		return;

	self.respawnhud = newClientHudElem(self);
	self.respawnhud.archived = false;
	self.respawnhud.x = 170;
	self.respawnhud.y = 100;
	self.respawnhud.alignX = "left";
	self.respawnhud.alignY = "middle";
	self.respawnhud.fontScale = 2;
	self.respawnhud.sort = 1;
	self.respawnhud setText(&"You will respawn in:");

	self.respawntimer = newClientHudElem(self);
	self.respawntimer.archived = false;
	self.respawntimer.x = 420;
	self.respawntimer.y = 100;
	self.respawntimer.alignX = "center";
	self.respawntimer.alignY = "middle";
	self.respawntimer.fontScale = 2;
	self.respawntimer.sort = 1;

	self.respawntimer setTimer(level.respawnTimeLeft[team]);
}



carrierHurt(attacker)
{
	self notify("ouchie");
	self endon("ouchie");
	self endon("killed");

	self.wasAttacked = true;
	self.myattackerNum = attacker getEntityNumber();

	wait 5;  // for the next 5 seconds, if a teammate kills the attacker, they get bonus points
	
	self.wasAttacked = false;
	self.myattackerNum = -1;
}


substr(searchfor, searchin)
{
	return maps\mp\gametypes\_user_Ravir_admin::substr(searchfor, searchin);
}


addbombcounterHUD()
{
	for(i = 0; i < level.numofpacks; i++)
	{
		level.hudbombs[i] = newHudElem();
		level.hudbombs[i].x = 320;
		level.hudbombs[i].y = 380;
		level.hudbombs[i].alignX = "center";
		level.hudbombs[i].alignY = "middle";
		level.hudbombs[i].alpha = 0;
		level.hudbombs[i] setShader(game["status_bombstar"], 128, 128);
	}

	wait 3;

	for(i = 0; i < level.numofpacks; i++)
	{
		level.hudbombs[i] moveOverTime(0.5);
		level.hudbombs[i].x = 320-((i*32));
		level.hudbombs[i].y = 25;
		level.hudbombs[i] fadeOverTime(0.5);
		level.hudbombs[i].alpha = .5;
		if(level.expack[i].status == "carried") // in case someone grabbed one before the anim started
			level.hudbombs[i] scaleOverTime(0.5, 24, 24);
		else
			level.hudbombs[i] scaleOverTime(0.5, 20, 20);

		wait 0.25;
	}
}

updatebombcounter()
{
	self notify("changebombcounter");
	self endon("changebombcounter");

	if(self.status == "success")
	{
		level.hudbombs[self.i] scaleOverTime(.25, 54, 54);
		wait .5;
		level.hudbombs[self.i] fadeOverTime(.5);
		level.hudbombs[self.i].alpha = .25;
		level.hudbombs[self.i] scaleOverTime(.5, 36, 36);
	}

	if(self.status == "defused" || self.status == "exploded")
	{
		iconname = "headicon_" + game["defenders"];
		level.hudbombs[self.i] scaleOverTime(0.25, 1, 1);
		wait 0.25;
		level.hudbombs[self.i] setShader(game[iconname], 1, 1);
		level.hudbombs[self.i] scaleOverTime(.25, 54, 54);
		wait .5;
		level.hudbombs[self.i] fadeOverTime(.5);
		level.hudbombs[self.i].alpha = .25;
		level.hudbombs[self.i] scaleOverTime(.5, 36, 36);
		if(isdefined(self.oldstatus) && self.oldstatus == "spawned") // if it was defused from the supply box
		{
			self.oldstatus = undefined;
			thread timerelease();
		}
	}

	if(self.status == "carried")
	{
		objective_icon(self.objnum, "gfx/hud/objective.tga"); // in case it had been dropped
		iconname = "headicon_" + game["attackers"];
		level.hudbombs[self.i] scaleOverTime(0.25, 1, 1);
		wait 0.25;
		level.hudbombs[self.i] setShader(game[iconname], 1, 1);
		level.hudbombs[self.i] scaleOverTime(0.25, 24, 24);
		level.hudbombs[self.i] fadeOverTime(.25);
		level.hudbombs[self.i].alpha = 1;
		if(isdefined(self.oldstatus) && self.oldstatus == "spawned") // if it was picked up  from the supply box
		{
			self.oldstatus = undefined;
			thread timerelease();
		}
	}

	if(self.status == "dropped")
	{
		objective_icon(self.objnum, "gfx/hud/hud@objective_bel.tga");
		level.hudbombs[self.i] scaleOverTime(0.25, 1, 1);
		wait 0.25;
		level.hudbombs[self.i] setShader(game["status_bombstar"], 1, 1);
		level.hudbombs[self.i] scaleOverTime(0.25, 36, 36);
		level.hudbombs[self.i] fadeOverTime(.25);
		level.hudbombs[self.i].alpha = 1;
	}

	if(self.status == "spawned")
	{
		level.hudbombs[self.i] scaleOverTime(0.25, 1, 1);
		wait 0.25;
		level.hudbombs[self.i] setShader(game["status_bombstar"], 1, 1);
		level.hudbombs[self.i] scaleOverTime(0.25, 20, 20);
		level.hudbombs[self.i] fadeOverTime(.25);
		level.hudbombs[self.i].alpha = 0.5;
	}

	if(self.status == "planted")
	{
		level.hudbombs[self.i] scaleOverTime(0.25, 40, 40);
		level.hudbombs[self.i] fadeOverTime(0.25);
		level.hudbombs[self.i].alpha = 1;
	}
}

dropHealth()
{

//////// Added by AWE ///////
	if ( !getcvarint("scr_drophealth") )
		return;
		
	if(isdefined(self.awe_nohealthpack))
		return;
	self.awe_nohealthpack = true;
/////////////////////////////

	if(isdefined(level.healthqueue[level.healthqueuecurrent]))
		level.healthqueue[level.healthqueuecurrent] delete();
	
	level.healthqueue[level.healthqueuecurrent] = spawn("item_health", self.origin + (0, 0, 1));
	level.healthqueue[level.healthqueuecurrent].angles = (0, randomint(360), 0);

	level.healthqueuecurrent++;
	
	if(level.healthqueuecurrent >= 16)
		level.healthqueuecurrent = 0;
}

dropbomb()
{
	self.player notify ("lostbomb");
	self endon("nomines");

//	if(!isalive(self.player))
//		wait 0.1;

	self.player playsound("grenade_pickup");
	self.player.carrying = false;
	self.player.expacki = -1;

	if(level.drawfriend)
	{
		if(level.battlerank)
		{
			self.player.statusicon = maps\mp\gametypes\_rank_gmi::GetRankStatusIcon(self.player);
			self.player.headicon = maps\mp\gametypes\_rank_gmi::GetRankHeadIcon(self.player);
		}
		else
		{
			self.player.statusicon = "";
			self.player.headicon = game["headicon_" + self.player.sessionteam];
		}
		self.player.headiconteam = self.player.sessionteam;
	}
	else
	{
		if(level.battlerank)
		{
			self.player.headicon = "";
			self.player.statusicon = maps\mp\gametypes\_rank_gmi::GetRankStatusIcon(self.player);
		}	
		else
		{
			self.player.headicon = "";
			self.player.statusicon = "";
		}
	}

/*	if(level.drawfriend == 1)
	{
		headicon = "headicon_" + self.player.pers["team"];
		self.player.headicon = game[headicon];
		self.player.headiconteam = self.player.pers["team"];
	}

	if(self.player.statusicon == game["status_bombstar"])
		self.player.statusicon = "";*/

	if(isdefined(self.player.carriericon))
		self.player.carriericon destroy();

	if(isdefined(self.player.bombdrop))
		self.player.bombdrop destroy();

	objective_onentity(self.objnum, self);
	self.status = "dropped";
	self thread unstablebomb(self.player);
	self thread updatebombcounter();

	plant = self.player maps\mp\_utility::getPlant();
	self.origin = plant.origin;
	self.angles = plant.angles;

	self show();

	self.player = undefined;
	self.playerNum = -1;
	
	for (i = 0; i < level.minefield.size; i++)
	{
		if (self istouching(level.minefield[i]))
		{
			self notify("stabilized");  // keep it from blowin up
			self notify("spawned"); // stop the expack's thinker
			self.status = "minefield"; // let the nextexpack code find it and restart the thinker

			wait 60; // sits in the minefield for 60 seconds before respawning
			self.origin = (self.startorigin);
			self.angles = (self.startangles);	
			self.oldstatus = "spawned";
			self.status = "spawned";
			break;
		}
	}
}


debuggo(mystring)
{
	if(getcvarint("scr_debug") == 1)
		iprintln(mystring);
}


kicktospec()
{
	setcvar("g_kicktospec", "");
	for(;;)
	{
		if(getcvar("g_kicktospec") != "")
		{
			specPlayerNum = getcvarint("g_kicktospec");
			players = getentarray("player", "classname");
			for(i = 0; i < players.size; i++)
			{
				thisPlayerNum = players[i] getEntityNumber();
				if(thisPlayerNum == specPlayerNum || specPlayerNum == -1) // this is the one we're looking for
				{
					players[i].pers["team"] = "spectator";
					players[i].sessionteam = "spectator";
					players[i] setClientCvar("g_scriptMainMenu", game["menu_team"]);
					players[i] setClientCvar("scr_showweapontab", "0");
					players[i] thread spawnSpectator();

					if(specPlayerNum != -1)
						iprintln(players[i].name + "^7 was forced into spectator mode by the admin");
				}
			}
			if(specPlayerNum == -1)
				iprintln("The admin forced all players to switch teams.");

			setcvar("g_kicktospec", "");
		}
		wait 0.05;
	}
}

smitebombmonitor()
{
	setcvar("g_dem_smitebomb", "");
	for(;;)
	{
		wait 0.05;
		if(getcvar("g_dem_smitebomb") != "")
		{
			bombnum = getcvarint("g_dem_smitebomb");
			if(bombnum < 1 || bombnum > level.expack.size)
			{
				setcvar("g_dem_smitebomb", "");
				continue;
			}
			bombnum = level.expack.size - bombnum; // for admins counting left to right on HUD

			dabomb = level.expack[bombnum];

			if(dabomb.status != "success"
				&& dabomb.status != "exploded"
				&& dabomb.status != "defused")
			{
				dabomb thread smitebomb();
			}

			setcvar("g_dem_smitebomb", "");
		}
	}
}


smitebomb() // make a bomb explode, in case of bug preventing gameplay
{
	if(isdefined(self.player))  // make the carrier drop the bomb, cleanup code
	{
		self thread dropbomb();
		wait 0.05; // let it drop
	}

	// stop all bomb thinker processes that could be running
	self notify("smote");  // expackthinker
	self notify("bomb_defused"); // bomb_countdown
	self notify("nomines"); // avoid a probably impossible bug
	self notify("stabilized"); // make sure it's not unstable

	// if this bomb had been planted, clean up after it
	if(self.status == "planted" 
		|| (isdefined(self.oldstatus) && self.oldstatus == "planted"))
	{
		self stopLoopSound(); // stop the ticking sound
		targeti = self.targeti;
		level.targets[targeti] thread bombzone_think();  // let the bombzone think again
		objective_icon(self.objnum, self.icon);  
		level.livebombs--;
	}
	else
	{
		// if not planted, just delete the objective for this bomb
		objective_delete(self.objnum);
	}

	if(isdefined(self.progressbar))
		self.progressbar destroy();
	if(isdefined(self.progressbackground))
		self.progressbackground destroy();


	level.packsLeft--;

	// explode bomb
	range = 360;
	maxdamage = 300;
	mindamage = 10;

	boomorigin = self.origin + (0,0,12);

	playfx(level._effect["bombexplosion"], boomorigin);
	radiusDamage(boomorigin, range, maxdamage, mindamage);

	self hide();
	self.status = "exploded";
	self thread updatebombcounter();
	iprintlnbold("Lo, the admin smote a bomb!");

	// check remaining number of targets, and remaining number of explosive packs
	if(level.targetsLeft > level.packsLeft)
	{ // too many exPacks have been defused for attackers to win
		if(game["defenders"] == "axis")
			level thread hud_announce(&"SD_AXISMISSIONACCOMPLISHED");
		else
			level thread hud_announce(&"SD_ALLIESMISSIONACCOMPLISHED");
		level thread endRound(game["defenders"]);
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
	mapname = getcvar("mapname");  // "mp_dawnville", "mp_rocket", etc.

//	if(getcvar(varname) == "") // if the cvar is blank
//		setcvar(varname, vardefault); // set the default

	mapvar = varname + "_" + mapname; // i.e., scr_teambalance becomes scr_teambalance_mp_dawnville
	if(getcvar(mapvar) != "") // if the map override is being used
		varname = mapvar; // use the map override instead of the standard variable

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


// create an entity reference between the expack and the target zone
// self = player holding the bomb
bombtarget(zone)
{
	expack = level.expack[self.expacki];
	expack.targetZone = zone;
}

teambalance()
{
	wait 3; // make sure everybody gets connected after a round starts

	players = getentarray("player", "classname");

	p_axis = [];
	axis = 0;
	p_allies = [];
	allies = 0;

	for(i = 0; i < players.size; i++)
	{
		if(isdefined(players[i].pers["team"]) && players[i].pers["team"] == "axis")
		{
			p_axis[axis] = players[i];
			axis++;
		}
		if(isdefined(players[i].pers["team"]) && players[i].pers["team"] == "allies")
		{
			p_allies[allies] = players[i];
			allies++;
		}
	}

	while(p_axis.size > allies + 1)
	{
		p_axis = teamswitchplayer(p_axis); // remove one from axis
		allies++; // added one to alles
	}

	while(p_allies.size > axis + 1)
	{
		p_allies = teamswitchplayer(p_allies); // remove one from allies
		axis++; // added one to axis
	}
}


teamswitchplayer(team)
{
	playernum = randomint(team.size);
	player = team[playernum];

	if(player.pers["team"] == "axis")
		newTeam = "allies";
	if(player.pers["team"] == "allies")
		newTeam = "axis";

	if(player.sessionstate == "playing")
	{
		player suicide();

		player.pers["score"]++;
		player.score = player.pers["score"];
		player.pers["deaths"]--;
		player.deaths = player.pers["deaths"];
	}

	player.pers["team"] = newTeam;
	player.pers["weapon"] = undefined;
	player.pers["weapon1"] = undefined;
	player.pers["weapon2"] = undefined;
	player.pers["spawnweapon"] = undefined;
	player.pers["savedmodel"] = undefined;

	player setClientCvar("scr_showweapontab", "1");

	if(player.pers["team"] == "allies")
	{
		player setClientCvar("g_scriptMainMenu", game["menu_weapon_allies"]);
		player openMenu(game["menu_weapon_allies"]);
	}
	else
	{
		player setClientCvar("g_scriptMainMenu", game["menu_weapon_axis"]);
		player openMenu(game["menu_weapon_axis"]);
	}
	iprintln(player.name + "^7 was forced to switch teams by the auto-balancer");

	// remove this player from the current team
	for(i = playernum; i < team.size - 1; i++)
		teams[i] = team[i+1];
	team[team.size-1] = undefined; // shorten the array

	return team;
}

compasslegend(state)
{
	// off or on, always check first, then clear it
	if(isdefined(self.legend))
	{
		for(i = 0; i < self.legend.size; i++)
		{
			self.legend[i] destroy();
		}
		self.legend = undefined;
	}

	if(state == "on")
	{
		self.legend = [];
		if(self.pers["team"] == game["attackers"])
		{
			self.legend[0] = newClientHudElem(self);
			self.legend[0].archived = true;
			self.legend[0].x = 5;
			self.legend[0].y = 365;
			self.legend[0].alignX = "left";
			self.legend[0].alignY = "middle";
			self.legend[0].alpha = 0.5;
			self.legend[0].sort = -3;
			self.legend[0] setShader("gfx/hud/hud@objectiveA.tga", 22, 22);

			self.legend[1] = newClientHudElem(self);
			self.legend[1].archived = true;
			self.legend[1].x = 20;
			self.legend[1].y = 365;
			self.legend[1].alignX = "left";
			self.legend[1].alignY = "middle";
			self.legend[1].alpha = 0.5;
			self.legend[1].sort = -3;
			self.legend[1].fontScale = 0.75;
			self.legend[1] setText(&": Target A");

			self.legend[2] = newClientHudElem(self);
			self.legend[2].archived = true;
			self.legend[2].x = 70;
			self.legend[2].y = 365;
			self.legend[2].alignX = "left";
			self.legend[2].alignY = "middle";
			self.legend[2].alpha = 0.5;
			self.legend[2].sort = -3;
			self.legend[2] setShader("gfx/hud/hud@objectiveB.tga", 22, 22);

			self.legend[3] = newClientHudElem(self);
			self.legend[3].archived = true;
			self.legend[3].x = 85;
			self.legend[3].y = 365;
			self.legend[3].alignX = "left";
			self.legend[3].alignY = "middle";
			self.legend[3].alpha = 0.5;
			self.legend[3].sort = -3;
			self.legend[3].fontScale = 0.75;
			self.legend[3] setText(&": Target B");

			self.legend[4] = newClientHudElem(self);
			self.legend[4].archived = true;
			self.legend[4].x = 95;
			self.legend[4].y = 380;
			self.legend[4].alignX = "left";
			self.legend[4].alignY = "middle";
			self.legend[4].alpha = 0.5;
			self.legend[4].sort = -3;
			self.legend[4] setShader("gfx/hud/hud@bombplanted.tga", 22, 22);

			self.legend[5] = newClientHudElem(self);
			self.legend[5].archived = true;
			self.legend[5].x = 110;
			self.legend[5].y = 380;
			self.legend[5].alignX = "left";
			self.legend[5].alignY = "middle";
			self.legend[5].alpha = 0.5;
			self.legend[5].sort = -3;
			self.legend[5].fontScale = 0.75;
			self.legend[5] setText(&": Bomb planted!");

			self.legend[6] = newClientHudElem(self);
			self.legend[6].archived = true;
			self.legend[6].x = 105+24;
			self.legend[6].y = 395;
			self.legend[6].alignX = "left";
			self.legend[6].alignY = "middle";
			self.legend[6].alpha = 0.5;
			self.legend[6].sort = -3;
			self.legend[6] setShader("gfx/hud/objective.tga", 22, 22);

			self.legend[7] = newClientHudElem(self);
			self.legend[7].archived = true;
			self.legend[7].x = 120+24;
			self.legend[7].y = 395;
			self.legend[7].alignX = "left";
			self.legend[7].alignY = "middle";
			self.legend[7].alpha = 0.5;
			self.legend[7].sort = -3;
			self.legend[7].fontScale = 0.75;
			self.legend[7] setText(&": Bomb carrier");

			self.legend[8] = newClientHudElem(self);
			self.legend[8].archived = true;
			self.legend[8].x = 105+24;
			self.legend[8].y = 410;
			self.legend[8].alignX = "left";
			self.legend[8].alignY = "middle";
			self.legend[8].alpha = 0.5;
			self.legend[8].sort = -3;
			self.legend[8] setShader("gfx/hud/hud@objective_bel.tga", 20, 20);

			self.legend[9] = newClientHudElem(self);
			self.legend[9].archived = true;
			self.legend[9].x = 123+24;
			self.legend[9].y = 410;
			self.legend[9].alignX = "left";
			self.legend[9].alignY = "middle";
			self.legend[9].alpha = 0.5;
			self.legend[9].sort = -3;
			self.legend[9].fontScale = 0.75;
			self.legend[9] setText(&": Bomb dropped!");

			self.legend[10] = newClientHudElem(self);
			self.legend[10].archived = true;
			self.legend[10].x = 105+24;
			self.legend[10].y = 427;
			self.legend[10].alignX = "left";
			self.legend[10].alignY = "middle";
			self.legend[10].alpha = 0.5;
			self.legend[10].sort = -3;
			self.legend[10] setShader("gfx/hud/hud@objectivegoal.tga", 20, 20);

			self.legend[11] = newClientHudElem(self);
			self.legend[11].archived = true;
			self.legend[11].x = 123+24;
			self.legend[11].y = 427;
			self.legend[11].alignX = "left";
			self.legend[11].alignY = "middle";
			self.legend[11].alpha = 0.5;
			self.legend[11].sort = -3;
			self.legend[11].fontScale = 0.75;
			self.legend[11] setText(&": Bomb supply");
		}
		else
		{
			self.legend[0] = newClientHudElem(self);
			self.legend[0].archived = true;
			self.legend[0].x = 5;
			self.legend[0].y = 365;
			self.legend[0].alignX = "left";
			self.legend[0].alignY = "middle";
			self.legend[0].alpha = 0.5;
			self.legend[0].sort = -3;
			self.legend[0] setShader("gfx/hud/hud@objectiveA.tga", 22, 22);

			self.legend[1] = newClientHudElem(self);
			self.legend[1].archived = true;
			self.legend[1].x = 20;
			self.legend[1].y = 365;
			self.legend[1].alignX = "left";
			self.legend[1].alignY = "middle";
			self.legend[1].alpha = 0.5;
			self.legend[1].sort = -3;
			self.legend[1].fontScale = 0.75;
			self.legend[1] setText(&": Target A");

			self.legend[2] = newClientHudElem(self);
			self.legend[2].archived = true;
			self.legend[2].x = 70;
			self.legend[2].y = 365;
			self.legend[2].alignX = "left";
			self.legend[2].alignY = "middle";
			self.legend[2].alpha = 0.5;
			self.legend[2].sort = -3;
			self.legend[2] setShader("gfx/hud/hud@objectiveB.tga", 22, 22);

			self.legend[3] = newClientHudElem(self);
			self.legend[3].archived = true;
			self.legend[3].x = 85;
			self.legend[3].y = 365;
			self.legend[3].alignX = "left";
			self.legend[3].alignY = "middle";
			self.legend[3].alpha = 0.5;
			self.legend[3].sort = -3;
			self.legend[3].fontScale = 0.75;
			self.legend[3] setText(&": Target B");

			self.legend[4] = newClientHudElem(self);
			self.legend[4].archived = true;
			self.legend[4].x = 95;
			self.legend[4].y = 380;
			self.legend[4].alignX = "left";
			self.legend[4].alignY = "middle";
			self.legend[4].alpha = 0.5;
			self.legend[4].sort = -3;
			self.legend[4] setShader("gfx/hud/hud@bombplanted.tga", 22, 22);

			self.legend[5] = newClientHudElem(self);
			self.legend[5].archived = true;
			self.legend[5].x = 110;
			self.legend[5].y = 380;
			self.legend[5].alignX = "left";
			self.legend[5].alignY = "middle";
			self.legend[5].alpha = 0.5;
			self.legend[5].sort = -3;
			self.legend[5].fontScale = 0.75;
			self.legend[5] setText(&": Bomb planted!");

			self.legend[6] = newClientHudElem(self);
			self.legend[6].archived = true;
			self.legend[6].x = 105+24;
			self.legend[6].y = 395;
			self.legend[6].alignX = "left";
			self.legend[6].alignY = "middle";
			self.legend[6].alpha = 0.5;
			self.legend[6].sort = -3;
			self.legend[6] setShader("gfx/hud/hud@objective_bel.tga", 20, 20);

			self.legend[7] = newClientHudElem(self);
			self.legend[7].archived = true;
			self.legend[7].x = 122+24;
			self.legend[7].y = 395;
			self.legend[7].alignX = "left";
			self.legend[7].alignY = "middle";
			self.legend[7].alpha = 0.5;
			self.legend[7].sort = -3;
			self.legend[7].fontScale = 0.75;
			self.legend[7] setText(&": Bomb being defused!");
		}
	}
}


addBombTimer(targeticon)
{
	if(!isdefined(level.bombtimers))
	{
		level.bombtimers = [];
		level.bombtimers[0] = newHudElem();
		level.bombtimers[0].archived = true;
		level.bombtimers[0].x = 630;
		level.bombtimers[0].y = 75;
		level.bombtimers[0].alignX = "right";
		level.bombtimers[0].alignY = "middle";
		level.bombtimers[0].alpha = 1;
		level.bombtimers[0].sort = -3;
		level.bombtimers[0].fontScale = 1;
		level.bombtimers[0] setText(&"^1Explosives Planted:");
	}

	// find the first hole in the array
	i = 1;
	while(isdefined(level.bombtimers[i]))
		i++;
	
	level.bombtimers[i] = [];

	level.bombtimers[i]["icon"] = newHudElem();
	level.bombtimers[i]["icon"].archived = true;
	level.bombtimers[i]["icon"].x = 560;
	level.bombtimers[i]["icon"].y = 75+(i*16);
	level.bombtimers[i]["icon"].alignX = "right";
	level.bombtimers[i]["icon"].alignY = "middle";
	level.bombtimers[i]["icon"].alpha = 1;
	level.bombtimers[i]["icon"].sort = -3;
	level.bombtimers[i]["icon"] setShader(targeticon, 32, 32);

	level.bombtimers[i]["text"] = newHudElem();
	level.bombtimers[i]["text"].archived = true;
	level.bombtimers[i]["text"].x = 558;
	level.bombtimers[i]["text"].y = 75+(i*16)-2;
	level.bombtimers[i]["text"].alignX = "right";
	level.bombtimers[i]["text"].alignY = "middle";
	level.bombtimers[i]["text"].alpha = 1;
	level.bombtimers[i]["text"].sort = -3;
	level.bombtimers[i]["text"].fontScale = 1.5;
	level.bombtimers[i]["text"] setText(&"^5|");

	level.bombtimers[i]["timer"] = newHudElem();
	level.bombtimers[i]["timer"].archived = true;
	level.bombtimers[i]["timer"].x = 560;
	level.bombtimers[i]["timer"].y = 75+(i*16)-2;
	level.bombtimers[i]["timer"].alignX = "left";
	level.bombtimers[i]["timer"].alignY = "middle";
	level.bombtimers[i]["timer"].alpha = 1;
	level.bombtimers[i]["timer"].sort = -3;
	level.bombtimers[i]["timer"].fontScale = 1.25;
	level.bombtimers[i]["timer"].color = (0,1,0);
	level.bombtimers[i]["timer"] setTimer(level.countdown);

	return i;
}

removeBombTimer()
{
	i = self.timer;

	if(self.status == "defused" || self.status == "success")
	{
		level.bombtimers[i]["timer"] destroy();
		level.bombtimers[i]["timer"] = newHudElem();
		level.bombtimers[i]["timer"].archived = true;
		level.bombtimers[i]["timer"].x = 560;
		level.bombtimers[i]["timer"].y = 75+(i*16)-2;
		level.bombtimers[i]["timer"].alignX = "left";
		level.bombtimers[i]["timer"].alignY = "middle";
		level.bombtimers[i]["timer"].alpha = 1;
		level.bombtimers[i]["timer"].sort = -3;
		level.bombtimers[i]["timer"].fontScale = 1.25;
		level.bombtimers[i]["timer"].color = (0,1,0);
	} 

	if(self.status == "defused")
		level.bombtimers[i]["timer"] setText(&"^3DEFUSED!");
	if(self.status == "success")
		level.bombtimers[i]["timer"] setText(&"^4SUCCESS!");
	wait 2;

	level.bombtimers[i]["icon"] fadeOverTime(0.5);
	level.bombtimers[i]["icon"].alpha = 0;
	level.bombtimers[i]["text"] fadeOverTime(0.5);
	level.bombtimers[i]["text"].alpha = 0;
	level.bombtimers[i]["timer"] fadeOverTime(0.5);
	level.bombtimers[i]["timer"].alpha = 0;
	wait 0.5;

	level.bombtimers[i]["icon"] destroy();
	level.bombtimers[i]["text"] destroy();
	level.bombtimers[i]["timer"] destroy();
	level.bombtimers[i] = undefined;

	if(level.bombtimers.size == 1)
	{
		level.bombtimers[0] destroy();
		level.bombtimers = undefined;
	}
}
