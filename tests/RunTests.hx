package;

import buddy.*;
import mongo.Mongo;
using tink.CoreApi;

class RunTests implements Buddy<[
	TestProtocol,
	TestConnectionString,
	TestMongoClient,
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
// 
// class RunTests {
// 	static function main() {
// 		var s = js.Lib.require('source-map-support');
// 		s.install();
// 		haxe.CallStack.wrapCallSite = s.wrapCallSite;
// 		var client = new mongo.MongoClient({
// 			topologyDescription: {
// 				servers:[{host:'localhost', port:27017}],
// 				topologyType: Single,
// 				setName: null,
// 			},
// 			heartbeatFrequencyMS: 10000,
// 			socketCheckIntervalMS: 10000,
// 		});
// 		
// 		client.init();
// 	}
// }