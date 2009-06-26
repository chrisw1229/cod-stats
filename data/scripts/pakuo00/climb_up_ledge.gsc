// climb_up_ledge.gsc
// Makes the character climb up a 60 unit ledge. Made for Kharkov2, at the end of the level.

#using_animtree ("generic_human");

main()
{
	// do not do code prone in this script
	self.desired_anim_pose = "stand";
	animscripts\utility::UpdateAnimPose();
	
	self endon("killanimscript");
	self traverseMode("nogravity");
	self traverseMode("noclip");

	self setFlaggedAnimKnoballRestart("wall_climb",%c_climb_60units_dock, %body, 1, .1, 1);
//	self playsound("dive_wall");
//	self waittillmatch("wall_climb", "gravity on");
//	self traverseMode("nogravity");
//	self waittillmatch("wall_climb", "noclip");
//	self traverseMode("noclip");
//	self waittillmatch("wall_climb", "gravity on");
//	self traverseMode("gravity");
	self animscripts\shared::DoNoteTracks("wall_climb");
	self.anim_movement = "run";
	self.anim_alertness = "casual";
	self setAnimKnobAllRestart(self.anim_crouchrunanim, %body, 1, 0.1, 1);
}

