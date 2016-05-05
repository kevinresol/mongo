package;

class RunTests {
	
	static function main() {
		
		#if nodejs
		var s = js.Lib.require('source-map-support');
		s.install();
		haxe.CallStack.wrapCallSite = s.wrapCallSite;
		#end
		
		trace('test');
		new mongo.Mongo();
		
	}
}