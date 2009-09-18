main() {

    // Setup teams
    game["allies"] = "american";
    game["axis"] = "german"; 

    // Setup models for each team
    game["american_soldiertype"] = "airborne";
    game["american_soldiervariation"] = "normal";
    game["german_soldiertype"] = "wehrmacht";
    game["german_soldiervariation"] = "normal";

   // Play ambient background sound
   ambientplay("ambient_mp_pavlov");
}
