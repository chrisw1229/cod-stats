main() {

    // Load scripts for explosions (mines)
    maps\mp\_load::main();

    // Load the core tank script also needed for jeeps
    level thread maps\mp\_tankdrive_gmi::main();
    level thread maps\mp\_jeepdrive_gmi::main();

    // Setup teams
    game["allies"] = "american";
    game["axis"] = "german"; 

    // Setup models for each team
    game["american_soldiertype"] = "airborne";
    game["american_soldiervariation"] = "normal";
    game["german_soldiertype"] = "wehrmacht";
    game["german_soldiervariation"] = "normal";

    // Load overhead quick map
    game["layoutimage"] = "jeeparena";

    // Set the idle time limit until vehicles self destruct
    setCvar("scr_selfDestructTankTime", "10");
    setCvar("scr_selfDestructJeepTime", "10");

   // Play ambient background sound
   ambientplay("ambient_mp_pavlov");
}