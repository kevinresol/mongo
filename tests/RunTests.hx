package;

import buddy.*;
import mongo.Mongo;
using tink.CoreApi;

class RunTests implements Buddy<[
	TestProtocol,
	TestConnectionString,
]>{
	#if nodejs	
	static function main() {
		if(Sys.getEnv('TRAVIS') != 'true') {
			var s = js.Lib.require('source-map-support');
			s.install();
			haxe.CallStack.wrapCallSite = s.wrapCallSite;
		}
	}
	#end
}