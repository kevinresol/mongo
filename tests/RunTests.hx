package;

import buddy.*;
import mongo.Mongo;
using tink.CoreApi;

class RunTests implements Buddy<[
	TestProtocol
]>{
	#if nodejs	
	static function main() {
		var s = js.Lib.require('source-map-support');
		s.install();
		haxe.CallStack.wrapCallSite = s.wrapCallSite;
	}
	#end
}