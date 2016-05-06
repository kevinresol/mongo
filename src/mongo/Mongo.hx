package mongo;

import mongo.protocol.Protocol;
import tink.tcp.Endpoint;

using tink.CoreApi;

@:allow(mongo)
class Mongo implements Dynamic<Database> {
	
	var protocol:Protocol;
	
	public static function connect(?endpoint:Endpoint) {
		if(endpoint == null) endpoint = {host: 'localhost', port: 27017};
		var mongo = new Mongo();
		return mongo.protocol.open(endpoint) >> function(_) return mongo;
	}
	
	function new() {
		protocol = new Protocol();
	}
	
	public inline function db(name:String):Database {
		return resolve(name);
	}
	
	public function resolve(name:String) {
		return new Database(this, name);
	}
}