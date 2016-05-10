package;

import mongo.*;
import buddy.*;

using buddy.Should;
using Lambda;

class TestMongoClient extends BuddySuite {
	public function new() {
		describe("Test Protocol", {
			
			it("Connect DB", function(done) {
				var client = new MongoClient({
					topologyDescription: {
						servers:[{host:'localhost', port:27017}],
						topologyType: Unknown,
						setName: null,
					},
					heartbeatFrequencyMS: 10000,
					socketCheckIntervalMS: 10000,
				});
				
				client.init();
				haxe.Timer.delay(function() {
					untyped console.log(@:privateAccess client.topologyDescription);
					done();
				}, 2000);
			});
			
			
		});
	}
}