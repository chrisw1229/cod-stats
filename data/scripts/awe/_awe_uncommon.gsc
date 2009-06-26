isUo()
{
	return true;
}

aweIsInVehicle()
{
	return self isInVehicle();
}

aweSetTakeDamage(flag)
{
	self setTakeDamage(flag);
}

aweIsAds()
{
	return self isAds();
}

aweShellshock(time)
{
	self thread maps\mp\gametypes\_shellshock_gmi::gmiShellShock(time, undefined, undefined, undefined, undefined, "default_mp");
}

shockme(damage, means)
{
	return;
}

aweGetWeaponBasedSmokeGrenadeCount(slot)
{
	return maps\mp\gametypes\_teams::getWeaponBasedSmokeGrenadeCount(slot);
}

aweGetRankHeadIcon(player)
{
	return maps\mp\gametypes\_rank_gmi::GetRankHeadIcon(player);
}

aweSetFatigue(value)
{
	self setFatigue(value);
}

aweGetFatigue()
{
	return self getFatigue();
}
