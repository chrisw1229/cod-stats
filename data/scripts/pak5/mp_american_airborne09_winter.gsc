// THIS FILE IS AUTOGENERATED, DO NOT MODIFY
main()
{
	self setModel("xmodel/playerbody_american_airborne_winter");
	character\_utility::attachFromArray(xmodelalias\head_allied::main());
	self.hatModel = "xmodel/USAirborneHelmet";
	self attach(self.hatModel);
	self setViewmodel("xmodel/viewmodel_hands_uswinter");
	if (character\_utility::useOptionalModels())
	{
		self attach("xmodel/gear_US_load3");
		self attach("xmodel/gear_US_frntknklknfe");
		self attach("xmodel/gear_US_ammobelt");
	}
	self.voice = "american";
}

precache()
{
	precacheModel("xmodel/playerbody_american_airborne_winter");
	character\_utility::precacheModelArray(xmodelalias\head_allied::main());
	precacheModel("xmodel/USAirborneHelmet");
	precacheModel("xmodel/viewmodel_hands_uswinter");
	if (character\_utility::useOptionalModels())
	{
		precacheModel("xmodel/gear_US_load3");
		precacheModel("xmodel/gear_US_frntknklknfe");
		precacheModel("xmodel/gear_US_ammobelt");
	}
}
