// THIS FILE IS AUTOGENERATED, DO NOT MODIFY
main()
{
	character\_utility::setModelFromArray(xmodelalias\body_falshirmjager::main());
	character\_utility::attachFromArray(xmodelalias\head_axis::main());
	self.hatModel = character\_utility::randomElement(xmodelalias\helmet_falshrm_camo::main());
	self attach(self.hatModel);
	if (character\_utility::useOptionalModels())
	{
		self attach("xmodel/gear_german_bandolier");
		self attach("xmodel/gear_german_load2_falshrm");
	}
	self.voice = "german";
}

precache()
{
	character\_utility::precacheModelArray(xmodelalias\body_falshirmjager::main());
	character\_utility::precacheModelArray(xmodelalias\head_axis::main());
	character\_utility::precacheModelArray(xmodelalias\helmet_falshrm_camo::main());
	if (character\_utility::useOptionalModels())
	{
		precacheModel("xmodel/gear_german_bandolier");
		precacheModel("xmodel/gear_german_load2_falshrm");
	}
}
