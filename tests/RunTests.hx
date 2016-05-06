package;

import mongo.Mongo;

class RunTests {
	
	static function main() {
		
		#if nodejs
		var s = js.Lib.require('source-map-support');
		s.install();
		haxe.CallStack.wrapCallSite = s.wrapCallSite;
		#end
		
		Mongo.connect().handle(function(o) switch(o) {
			case Success(mongo):
				var db = mongo.db('test');
				var collection = db.collection('users');
				collection.find({filter:{username:'foo'}}).handle(function(o) trace(o));
			case Failure(err):
				trace(err);
		});
		
	}
}