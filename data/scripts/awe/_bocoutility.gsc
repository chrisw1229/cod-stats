checkMapForCompatibility(gametype)
{
	entitytypes = getentarray();
	isCompat = false;
	for(i = 0; i < entitytypes.size; i++)
	{
		if(isdefined(entitytypes[i].script_gameobjectname))
		{
			if(entitytypes[i].script_gameobjectname == gametype)
			{
				isCompat = true;
				break;
			}
		}
	}
	return isCompat;
}

getPistol( team )
{
	switch( team )
	{
		case "american":
			pistol = "colt_mp";
			break;
		case "british":
			pistol = "colt_mp";
			break;
		case "russian":
			pistol = "luger_mp";
			break;
		case "german":
			pistol = "luger_mp";
			break;
		default:
			pistol = "colt_mp";
	}
	return pistol;
}

getGrenade( team )
{
	switch( team )
	{
		case "american":
			grenade = "fraggrenade_mp";
			break;
		case "british":
			grenade = "mk1britishfrag_mp";
			break;
		case "russian":
			grenade = "rgd-33russianfrag_mp";
			break;
		case "german":
			grenade = "stielhandgranate_mp";
			break;
		default:
			grenade = "fraggrenade_mp";
	}
	return grenade;
}

getWeaponClip( weapon )
{
	switch( weapon )
	{
		case "m1carbine_mp":
			weaponclip = 15;
			break;

		case "luger_mp":
		case "m1garand_mp":
			weaponclip = 8;
			break;

		case "colt_mp":
			weaponclip = 7;
			break;

		case "fg42_mp":
		case "bar_mp":
			weaponclip = 20;
			break;

		case "enfield_mp":
			weaponclip = 10;
			break;

		case "springfield_mp":
		case "mosin_nagant_mp":
		case "mosin_nagant_sniper_mp":
		case "kar98k_mp":
		case "kar98k_sniper_mp":
			weaponclip = 5;
			break;

		case "sten_mp":
		case "mp40_mp":
			weaponclip = 32;
			break;

		case "ppsh_mp":
			weaponclip = 71;
			break;

		case "thompson_mp":
		case "bren_mp":
		case "mp44_mp":
		default:
			weaponclip = 30;
			break;
	}

	return weaponclip;
}

getWeaponClipB( weapon )
{
	switch( weapon )
	{
		case "fraggrenade_mp":
			if ( getcvar("b_clip_fraggrenade") != "" )
				weaponclip = getcvarint("b_clip_fraggrenade");
			else if ( getcvar("b_clip_default") != "" )
				weaponclip = getcvarint("b_clip_default");
			else
				weaponclip = 0;
			break;

		case "mk1britishfrag_mp":
			if ( getcvar("b_clip_mk1britishfrag") != "" )
				weaponclip = getcvarint("b_clip_mk1britishfrag");
			else if ( getcvar("b_clip_default") != "" )
				weaponclip = getcvarint("b_clip_default");
			else
				weaponclip = 0;
			break;

		case "rgd-33russianfrag_mp":
			if ( getcvar("b_clip_rgd-33russianfrag") != "" )
				weaponclip = getcvarint("b_clip_rgd-33russianfrag");
			else if ( getcvar("b_clip_default") != "" )
				weaponclip = getcvarint("b_clip_default");
			else
				weaponclip = 0;
			break;

		case "stielhandgranate_mp":
			if ( getcvar("b_clip_stielhandgranate") != "" )
				weaponclip = getcvarint("b_clip_stielhandgranate");
			else if ( getcvar("b_clip_default") != "" )
				weaponclip = getcvarint("b_clip_default");
			else
				weaponclip = 0;
			break;

		case "colt_mp":
			if ( getcvar("b_clip_colt") != "" )
				weaponclip = getWeaponClip( weapon ) * getcvarint("b_clip_colt");
			else if ( getcvar("b_clip_default") != "" )
				weaponclip = getWeaponClip( weapon ) * getcvarint("b_clip_default");
			else
				weaponclip = 0;
			break;

		case "luger_mp":
			if ( getcvar("b_clip_luger") != "" )
				weaponclip = getWeaponClip( weapon ) * getcvarint("b_clip_luger");
			else if ( getcvar("b_clip_default") != "" )
				weaponclip = getWeaponClip( weapon ) * getcvarint("b_clip_default");
			else
				weaponclip = 0;
			break;

		case "m1carbine_mp":
			if ( getcvar("b_clip_m1carbine") != "" )
				weaponclip = getWeaponClip( weapon ) * getcvarint("b_clip_m1carbine");
			else if ( getcvar("b_clip_default") != "" )
				weaponclip = getWeaponClip( weapon ) * getcvarint("b_clip_default");
			else
				weaponclip = 0;
			break;

		case "m1garand_mp":
			if ( getcvar("b_clip_m1garand") != "" )
				weaponclip = getWeaponClip( weapon ) * getcvarint("b_clip_m1garand");
			else if ( getcvar("b_clip_default") != "" )
				weaponclip = getWeaponClip( weapon ) * getcvarint("b_clip_default");
			else
				weaponclip = 0;
			break;

		case "bar_mp":
			if ( getcvar("b_clip_bar") != "" )
				weaponclip = getWeaponClip( weapon ) * getcvarint("b_clip_bar");
			else if ( getcvar("b_clip_default") != "" )
				weaponclip = getWeaponClip( weapon ) * getcvarint("b_clip_default");
			else
				weaponclip = 0;
			break;

		case "enfield_mp":
			if ( getcvar("b_clip_enfield") != "" )
				weaponclip = getWeaponClip( weapon ) * getcvarint("b_clip_enfield");
			else if ( getcvar("b_clip_default") != "" )
				weaponclip = getWeaponClip( weapon ) * getcvarint("b_clip_default");
			else
				weaponclip = 0;
			break;

		case "springfield_mp":
			if ( getcvar("b_clip_springfield") != "" )
				weaponclip = getWeaponClip( weapon ) * getcvarint("b_clip_springfield");
			else if ( getcvar("b_clip_default") != "" )
				weaponclip = getWeaponClip( weapon ) * getcvarint("b_clip_default");
			else
				weaponclip = 0;
			break;

		case "mosin_nagant_mp":
			if ( getcvar("b_clip_nagant") != "" )
				weaponclip = getWeaponClip( weapon ) * getcvarint("b_clip_nagant");
			else if ( getcvar("b_clip_default") != "" )
				weaponclip = getWeaponClip( weapon ) * getcvarint("b_clip_default");
			else
				weaponclip = 0;
			break;

		case "mosin_nagant_sniper_mp":
			if ( getcvar("b_clip_nagantsniper") != "" )
				weaponclip = getWeaponClip( weapon ) * getcvarint("b_clip_nagantsniper");
			else if ( getcvar("b_clip_default") != "" )
				weaponclip = getWeaponClip( weapon ) * getcvarint("b_clip_default");
			else
				weaponclip = 0;
			break;

		case "kar98k_mp":
			if ( getcvar("b_clip_kar98k") != "" )
				weaponclip = getWeaponClip( weapon ) * getcvarint("b_clip_kar98k");
			else if ( getcvar("b_clip_default") != "" )
				weaponclip = getWeaponClip( weapon ) * getcvarint("b_clip_default");
			else
				weaponclip = 0;
			break;

		case "kar98k_sniper_mp":
			if ( getcvar("b_clip_kar98ksniper") != "" )
				weaponclip = getWeaponClip( weapon ) * getcvarint("b_clip_kar98ksniper");
			else if ( getcvar("b_clip_default") != "" )
				weaponclip = getWeaponClip( weapon ) * getcvarint("b_clip_default");
			else
				weaponclip = 0;
			break;

		case "sten_mp":
			if ( getcvar("b_clip_sten") != "" )
				weaponclip = getWeaponClip( weapon ) * getcvarint("b_clip_sten");
			else if ( getcvar("b_clip_default") != "" )
				weaponclip = getWeaponClip( weapon ) * getcvarint("b_clip_default");
			else
				weaponclip = 0;
			break;

		case "mp40_mp":
			if ( getcvar("b_clip_mp40") != "" )
				weaponclip = getWeaponClip( weapon ) * getcvarint("b_clip_mp40");
			else if ( getcvar("b_clip_default") != "" )
				weaponclip = getWeaponClip( weapon ) * getcvarint("b_clip_default");
			else
				weaponclip = 0;
			break;

		case "ppsh_mp":
			if ( getcvar("b_clip_ppsh") != "" )
				weaponclip = getWeaponClip( weapon ) * getcvarint("b_clip_ppsh");
			else if ( getcvar("b_clip_default") != "" )
				weaponclip = getWeaponClip( weapon ) * getcvarint("b_clip_default");
			else
				weaponclip = 0;
			break;

		case "thompson_mp":
			if ( getcvar("b_clip_thompson") != "" )
				weaponclip = getWeaponClip( weapon ) * getcvarint("b_clip_thompson");
			else if ( getcvar("b_clip_default") != "" )
				weaponclip = getWeaponClip( weapon ) * getcvarint("b_clip_default");
			else
				weaponclip = 0;
			break;

		case "bren_mp":
			if ( getcvar("b_clip_bren") != "" )
				weaponclip = getWeaponClip( weapon ) * getcvarint("b_clip_bren");
			else if ( getcvar("b_clip_default") != "" )
				weaponclip = getWeaponClip( weapon ) * getcvarint("b_clip_default");
			else
				weaponclip = 0;
			break;

		case "mp44_mp":
			if ( getcvar("b_clip_mp44") != "" )
				weaponclip = getWeaponClip( weapon ) * getcvarint("b_clip_mp44");
			else if ( getcvar("b_clip_default") != "" )
				weaponclip = getWeaponClip( weapon ) * getcvarint("b_clip_default");
			else
				weaponclip = 0;
			break;

		default:
			if ( getcvar("b_clip_default") != "" )
				weaponclip = 30 * getcvarint("b_clip_default");
			else
				weaponclip = 0;
			break;
	}

	return weaponclip;
}

getTeamRifle( team )
{
	switch ( team )
	{
		case "american":
			rifle = "m1garand_mp";
			break;
		case "british":
			rifle = "enfield_mp";
			break;
		case "russian":
			rifle = "mosin_nagant_mp";
			break;
		case "german":
			rifle = "kar98k_mp";
			break;
	}
	return rifle;
}