main()
{
	self notify("boot");
	wait 0.05; // let the threads die
	thread kicktospec();
	thread switchteam();
	thread killum();
	thread smiteplayer();
}

kicktospec()
{
	self notify("boot");
	self endon("boot");

	setcvar("g_kicktospec", "");
	while(1)
	{
		if(getcvar("g_kicktospec") != "")
		{
			specPlayerNum = getcvarint("g_kicktospec");
			for(i = 0; i < level.awe_allplayers.size; i++)
			{
				if(isdefined(level.awe_allplayers[i]))
				{
					thisPlayerNum = level.awe_allplayers[i] getEntityNumber();
					if(thisPlayerNum == specPlayerNum || specPlayerNum == -1) // this is the one we're looking for
					{
						level.awe_allplayers[i].pers["team"] = "spectator";
						level.awe_allplayers[i].sessionteam = "spectator";
						level.awe_allplayers[i] setClientCvar("g_scriptMainMenu", game["menu_team"]);
						level.awe_allplayers[i] setClientCvar("scr_showweapontab", "0");
						level.awe_allplayers[i] thread maps\mp\gametypes\_awe::spawnSpectator();

						if(specPlayerNum != -1)
							iprintln(level.awe_allplayers[i].name + "^7 was forced into spectator mode by the admin");
					}
				}
			}
			if(specPlayerNum == -1)
				iprintln("The admin forced all players to spectator mode.");

			setcvar("g_kicktospec", "");
		}
		wait 0.05;
	}
}

switchteam()
{
	self endon("boot");
	setcvar("g_switchteam", "");
	while(1)
	{
		if(getcvar("g_switchteam") != "")
		{
			if(getcvar("g_alliestag") != "" || getcvar("g_axistag") != "")
			{
				temptag = getcvar("g_alliestag");
				setcvar("g_alliestag", getcvar("g_axistag"));
				setcvar("g_axistag", temptag);
			}

			movePlayerNum = getcvarint("g_switchteam");
			for(i = 0; i < level.awe_allplayers.size; i++)
			{
				if(isdefined(level.awe_allplayers[i]))
				{
					thisPlayerNum = level.awe_allplayers[i] getEntityNumber();
					if(thisPlayerNum == movePlayerNum || movePlayerNum == -1) // this is the one we're looking for
					{

						if(level.awe_allplayers[i].pers["team"] == "axis")
							newTeam = "allies";
						if(level.awe_allplayers[i].pers["team"] == "allies")
							newTeam = "axis";

						level.awe_allplayers[i] suicide();

						if(isdefined(level.awe_allplayers[i].pers["score"]))
							level.awe_allplayers[i].pers["score"]++;
						level.awe_allplayers[i].score++;
						if(isdefined(level.awe_allplayers[i].pers["deaths"]))
							level.awe_allplayers[i].pers["deaths"]--;
						level.awe_allplayers[i].deaths--;

						level.awe_allplayers[i].pers["team"] = newTeam;
						level.awe_allplayers[i].pers["weapon"] = undefined;
						level.awe_allplayers[i].pers["weapon1"] = undefined;
						level.awe_allplayers[i].pers["weapon2"] = undefined;
						level.awe_allplayers[i].pers["spawnweapon"] = undefined;
						level.awe_allplayers[i].pers["savedmodel"] = undefined;

						level.awe_allplayers[i] setClientCvar("scr_showweapontab", "1");

						if(level.awe_allplayers[i].pers["team"] == "allies")
						{
							level.awe_allplayers[i] setClientCvar("g_scriptMainMenu", game["menu_weapon_allies"]);
							level.awe_allplayers[i] openMenu(game["menu_weapon_allies"]);
						}
						else
						{
							level.awe_allplayers[i] setClientCvar("g_scriptMainMenu", game["menu_weapon_axis"]);
							level.awe_allplayers[i] openMenu(game["menu_weapon_axis"]);
						}
						if(movePlayerNum != -1)
							iprintln(level.awe_allplayers[i].name + "^7 was forced to switch teams by the admin");
					}
				}
			}
			if(movePlayerNum == -1)
				iprintln("The admin forced all players to switch teams.");

			setcvar("g_switchteam", "");
		}
		wait 0.05;
	}
}



killum()
{
	self endon("boot");

	setcvar("g_killum", "");
	while(1)
	{
		if(getcvar("g_killum") != "")
		{
			killPlayerNum = getcvarint("g_killum");
			for(i = 0; i < level.awe_allplayers.size; i++)
			{
				if(isdefined(level.awe_allplayers[i]))
				{
					thisPlayerNum = level.awe_allplayers[i] getEntityNumber();
					if(thisPlayerNum == killPlayerNum) // this is the one we're looking for
					{
						level.awe_allplayers[i] suicide();
						iprintln(level.awe_allplayers[i].name + "^7 was killed by the admin");
					}
				}
			}
			setcvar("g_killum", "");
		}
		wait 0.05;
	}
}


substr(searchfor, searchin)
{
	location = -1;
	if(searchin.size < searchfor.size)
		return location;

	if(searchin.size == searchfor.size && searchin != searchfor)
		return location;

	if(searchfor.size == 0)
		return 0;

	for (c = 0; c < searchin.size; c++)
	{
		if(searchin[c] == searchfor[0]) // matched the first character
		{
			location = c;
			for(i = 0; i+c < searchin.size && i < searchfor.size && location > -1; i++)
			{
				if(searchin[i+c] != searchfor[i])
					location = -1;
			}
			if(i < searchfor.size)
				location = -1;
		}
	}

	return location;
}



smiteplayer() // make a player explode, will hurt people up to 15 feet away
{
	self endon("boot");

	setcvar("g_smite", "");
	while(1)
	{
		if(getcvar("g_smite") != "")
		{
			smitePlayerNum = getcvarint("g_smite");
			for(i = 0; i < level.awe_allplayers.size; i++)
			{
				if(isdefined(level.awe_allplayers[i]))
				{
					thisPlayerNum = level.awe_allplayers[i] getEntityNumber();
					if(thisPlayerNum == smitePlayerNum && level.awe_allplayers[i].sessionstate == "playing") // this is the one we're looking for
					{
						// explode 
						range = 180;
						maxdamage = 150;
						mindamage = 10;

						playfx(level.awe_effect["bombexplosion"], level.awe_allplayers[i].origin);
						radiusDamage(level.awe_allplayers[i].origin + (0,0,12), range, maxdamage, mindamage);
						iprintln("Lo, the admin smote " + level.awe_allplayers[i].name + "^7 with fire!");
					}
				}
			}
			setcvar("g_smite", "");
		}
		wait 0.05;
	}
}