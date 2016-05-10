package mongo.topology;

import mongo.protocol.Protocol;
import mongo.protocol.Message;
import mongo.topology.Topology;
import mongo.topology.Types;
import tink.tcp.*;

using tink.CoreApi;

class Monitor {
	
	var protocol:Protocol;
	var isChecking:Bool;
	var db:Database;
	var serverDescription:ServerDescription;
	
	public function new(serverDescription:ServerDescription) {
		isChecking = false;
		protocol = new Protocol();
		db = new Database(protocol, 'local');
		this.serverDescription = serverDescription;
	}
	
	public function init() {
		return protocol.open(serverDescription.address);
	}
	
	public function stop() {
		// TODO;
	}
	
	public function checkServer() {
		
		function check() {
			var startTime = getTimestamp();
			return db.isMaster().flatMap(function(o) switch o {
				case Success(res):
					serverDescription.roundTripTime = Std.int((getTimestamp() - startTime) * 1000);
					parseIsMasterResponse(res[0]);
					return Future.sync(Success(serverDescription));
				case Failure(err):
					switch serverDescription.type {
						case Unknown | PossiblePrimary:
							serverDescription.error = err.message;
							return Future.sync(Failure(err));
						default:
							serverDescription.type = Unknown;
							return checkServer();
					}
			});
		}
		
		return if(!protocol.connected) init() >> function(_) return check() else check();
	}
	/**
		https://github.com/mongodb/specifications/blob/master/source/server-discovery-and-monitoring/server-discovery-and-monitoring.rst#parsing-an-ismaster-response
	**/
	function parseIsMasterResponse(res:ReplyIsMaster) {
		serverDescription.type = 
			if(res.ok != 1)
				Unknown;
			else if(res.msg != 'isdbgrid' && res.setName == null && res.isreplicaset != true)
				Standalone;
			else if(res.msg == 'isdbgrid')
				Mongos;
			else if(res.ismaster == true && res.setName != null)
				RSPrimary;
			else if(res.secondary == true && res.setName != null)
				RSSecondary;
			else if(res.arbiterOnly == true && res.setName != null)
				RSArbiter;
			else if(res.hidden == true && res.setName != null)
				RSOther;
			else if(res.isreplicaset == true)
				RSGhost;
			else
				Unknown;
			
		serverDescription.error = null;
		serverDescription.minWireVersion = res.minWireVersion;
		serverDescription.maxWireVersion = res.maxWireVersion;
		serverDescription.setName = res.setName;
		serverDescription.setVersion = res.setVersion;
		serverDescription.electionId = res.electionId;
		
		function parseAddress(addr:String):Endpoint {
			var s = addr.split(':');
			return {
				host: s[0],
				port: Std.parseInt(s[1]),
			}
		}
		
		if(res.me != null) serverDescription.me = parseAddress(res.me);
		if(res.primary != null) serverDescription.primary = parseAddress(res.primary);
		if(res.hosts != null) serverDescription.hosts = res.hosts.map(parseAddress);
		if(res.passives != null) serverDescription.passives = res.passives.map(parseAddress);
		if(res.arbiters != null) serverDescription.arbiters = res.arbiters.map(parseAddress);
		if(res.tags != null) serverDescription.tags = [for(f in Reflect.fields(res.tags)) f => Reflect.field(res.tags, f)];
	}
	
	// in seconds with fractions
	inline function getTimestamp():Float {
		return haxe.Timer.stamp();
	}
}

