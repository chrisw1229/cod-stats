// THIS FILE IS AUTOGENERATED, DO NOT MODIFY
main()
{
	self setModel("xmodel/character_german_wehrmact_W");
	character\_utility::attachFromArray(xmodelalias\head_axis::main());
	self.hatModel = "xmodel/germanhelmet_winter";
	self attach(self.hatModel);
	self.voice = "german";
}

precache()
{
	precacheModel("xmodel/character_german_wehrmact_W");
	character\_utility::precacheModelArray(xmodelalias\head_axis::main());
	precacheModel("xmodel/germanhelmet_winter");
}
