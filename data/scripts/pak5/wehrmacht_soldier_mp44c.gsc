// THIS FILE IS AUTOGENERATED, DO NOT MODIFY
main()
{
	character\_utility::setModelFromArray(xmodelalias\body_wehrmact_soldier::main());
	character\_utility::attachFromArray(xmodelalias\head_axis::main());
	self.hatModel = "xmodel/gear_german_helmet";
	self attach(self.hatModel);
	if (character\_utility::useOptionalModels())
	{
		self attach("xmodel/gear_german_mp44_w");
		self attach("xmodel/gear_german_load3_w");
	}
	self.voice = "german";
}

precache()
{
	character\_utility::precacheModelArray(xmodelalias\body_wehrmact_soldier::main());
	character\_utility::precacheModelArray(xmodelalias\head_axis::main());
	precacheModel("xmodel/gear_german_helmet");
	if (character\_utility::useOptionalModels())
	{
		precacheModel("xmodel/gear_german_mp44_w");
		precacheModel("xmodel/gear_german_load3_w");
	}
}
