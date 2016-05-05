package mongo;

import mongo.protocol.Protocol;
import tink.tcp.Endpoint;

class Mongo {
	
	var protocol:Protocol;
	
	public function new(?endpoint:Endpoint) {
		
		if(endpoint == null) endpoint = {host: 'localhost', port: 27017};
		protocol = new Protocol();
		protocol.open(endpoint).handle(function(o) {
			trace(o);
			protocol.query('test.users').handle(function(o) trace('1' + o));
			protocol.query('test.users').handle(function(o) trace('2' + o));
			// protocol.query('test.users');
		});
		
	}
}