//////made by maverick//////

main()
{
	setCullFog (0, 16000, .32, .36, .40, 0);
	ambientPlay("ambient_mp_brecourt");
	
	maps\mp\_load::main();
	maps\mp\barrelfire::main();
	maps\mp\truck::main();
	maps\mp\door1::main();
	maps\mp\door2::main();
	maps\mp\door3::main();	

	//chimney
	level._effect["smoke"] = loadfx ("fx/smoke/ash_smoke.efx"); 
	maps\mp\_fx::loopfx("smoke", (-764, 2452, 430), 0.4); 
	level._effect["smoke"] = loadfx ("fx/smoke/ash_smoke.efx"); 
	maps\mp\_fx::loopfx("smoke", (-764, 2477, 430), 0.4); 

	//barrel
	level._effect["fire"] = loadfx ("fx/fire/barrelfire.efx"); 
	maps\mp\_fx::loopfx("fire", (1448, 2184, 60), 0.2); 
	level._effect["smoke1"] = loadfx ("fx/smoke/blacksmokelinger.efx"); 
	maps\mp\_fx::loopfx("smoke1", (1448, 2184, 124), 0.3); 

	//halftrack
	level._effect["smoke2"] = loadfx ("fx/smoke/ash_smoke.efx"); 
	maps\mp\_fx::loopfx("smoke2", (994, 1484, 60), 0.3); 

	//crashed kubelwagen
	level._effect["smoke3"] = loadfx ("fx/smoke/residual1.efx"); 
	maps\mp\_fx::loopfx("smoke3", (4376, 1045, 40), 0.3);

	//crashed germantruck
	level._effect["fire1"] = loadfx ("fx/fire/tinybon.efx"); 
	maps\mp\_fx::loopfx("fire1", (4081, 812, 8), 0.2); 
	level._effect["smoke4"] = loadfx ("fx/smoke/dawnville_smoke2.efx"); 
	maps\mp\_fx::loopfx("smoke4", (4081, 812, 1), 0.3);

	//broken house
	level._effect["smoke5"] = loadfx ("fx/smoke/dawnville_smoke1.efx"); 
	maps\mp\_fx::loopfx("smoke5", (3093, 92, 90), 0.4);
	
	game["allies"] = "american";
	game["axis"] = "german";

	game["american_soldiertype"] = "airborne";
	game["american_soldiervariation"] = "normal";
	game["german_soldiertype"] = "fallschirmjagercamo";
	game["german_soldiervariation"] = "normal";
	
	//block any map exploits
	fixExploits();
		
}

fixExploits() {
//fixes by innocent bystander, www.after-hourz.com

	// Block access to player clip exploits
	//bushes
	thread maps\mp\_exploit_blocker::blockBox((-2035, 1522, 60), (1,100,50));
	// wall by mg 1
	thread maps\mp\_exploit_blocker::blockBox((80,2773,210), (10,1,70));
	// wall by mg 2
	thread maps\mp\_exploit_blocker::blockBox((210,2550,260), (1,100,1));
	thread maps\mp\_exploit_blocker::blockBox((210,2550,210), (1,100,1));
	// roof by mg 2
	thread maps\mp\_exploit_blocker::blockBox((-300,2280,265), (1,80,1));
	thread maps\mp\_exploit_blocker::blockBox((-300,2260,230), (1,40,1));
	// hedgehogs
	thread maps\mp\_exploit_blocker::blockBox((1860,-2836,175), (50,1,30));

	//check for and nerf any landsharks
 	level thread maps\mp\_exploit_blocker::sharkScanner(-400, 1, "lt");
	
}
