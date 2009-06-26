attachFromArray(a)
{
	self.awe_headmodel = character\_utility::randomElement(a);
	self attach(self.awe_headmodel, "", true);
}
