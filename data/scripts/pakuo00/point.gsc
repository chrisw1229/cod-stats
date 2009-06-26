#using_animtree ("generic_human");
point(point_direction, orientate_to_player, dialogue, vec)
{
	self endon("death");

	if(!isdefined(point_direction) && !isdefined(vec))
	{
		println("^1POINT_DIRECTION is not specified");
		return;
	}

	if(!isdefined(point_direction))
	{
		vec_direction = vectorToAngles(vec - self.origin);
		point_direction = vec_direction[1];
	}

	point_forward = (%c_pointing_standing_straight_A);
	point_right = (%c_pointing_standing_right_A);
	point_back = (%c_pointing_standing_back_A);
	point_left = (%c_pointing_standing_left_A);

	crouch_point_forward = (%c_pointing_crouch_straight_A);
	crouch_point_right = (%c_pointing_crouch_right_A);
	crouch_point_back = (%c_pointing_crouch_back_A);
	crouch_point_left = (%c_pointing_crouch_left_A);

	// Orientation to the player.
	if(isdefined(orientate_to_player) && orientate_to_player)
	{
		self animscripts\shared::LookAtEntity(level.player, 1, "alert", eyesOnly, interruptOthers);
		fake_angles = vectorToAngles(level.player.origin - self.origin);
		diff = point_direction - fake_angles[1];
	}
	else
	{
		diff = point_direction - self.angles[1];
	}

	if(diff < 0)
	{
		diff = diff + 360;
	}

	if(diff <= 45 || diff >= 315)
	{
		if(self.anim_pose == "crouch")
		{
			println("^2POINT STRAIGHT! (crouching)");
			point = crouch_point_forward;
		}
		else
		{
			println("^2POINT STRAIGHT! (standing)");
			point = point_forward;
		}
		point_angle = 0;
	}
	else if(diff >= 45 && diff <= 135)
	{
		if(self.anim_pose == "crouch")
		{
			println("^2POINT LEFT! (crouching)");
			point = crouch_point_left;
		}
		else
		{
			println("^2POINT LEFT! (standing)");
			point = point_left;
		}
		point_angle = 90;
	}
	else if(diff >= 135 && diff <= 225)
	{
		if(self.anim_pose == "crouch")
		{
			println("^2POINT BACK! (crouching)");
			point = crouch_point_back;
		}
		else
		{
			println("^2POINT BACK! (standing)");
			point = point_back;
		}
		point_angle = 180;
	}
	else if(diff >= 225  && diff <= 315)
	{
		if(self.anim_pose == "crouch")
		{
			println("^2POINT RIGHT! (crouching)");
			point = crouch_point_right;
		}
		else
		{
			println("^2POINT RIGHT! (standing)");
			point = point_right;
		}
		point_angle = 270;
	}

	if(isdefined(orientate_to_player) && orientate_to_player)
	{
		point_diff = (diff - point_angle);
		self OrientMode("face angle", (fake_angles[1] + point_diff));
		wait 0.5;
	}
	else
	{
		point_diff = (diff - point_angle);
		self OrientMode("face angle", (self.angles[1] + point_diff));
		wait 0.5;
	}

	playbackrate = 0.75 + randomfloat(0.5);
//	self setFlaggedAnimKnobAllRestart("animdone", point, %body, 1, 0.1, playbackrate);
	self animscripted("point_anim", self.origin, self.angles, point);

	if(isdefined(dialogue))
	{
		doFacialanim = false;
		doDialogue = false;
		if((isdefined (level.scr_face[self.animname])) && (isdefined (level.scr_face[self.animname][dialogue])))
		{
			doFacialanim = true;
			facialAnim = level.scr_face[self.animname][dialogue];
		}

		if((isdefined (level.scrsound[self.animname])) && (isdefined (level.scrsound[self.animname][dialogue])))
		{
			doDialogue = true;
			s_alias = level.scrsound[self.animname][dialogue];
		}

		if((doFacialanim) || (doDialogue))
		{
			self animscripts\face::SaySpecificDialogue(facialAnim, s_alias, 1.0);
		}
	}

	self waittillmatch("point_anim", "end");

	self notify("finished_pointing");
}