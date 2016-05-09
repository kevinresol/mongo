package mongo;

import mongo.topology.Types;
import mongo.topology.Topology;
import mongo.topology.Monitor;
import tink.tcp.Endpoint;
using Lambda;


class MongoClient {
	
	var topologyDescription:TopologyDescription;
	var configuration:Configuration;
	var monitors:Map<String, Monitor>;
	
	public function new(configuration:Configuration) {
		this.configuration = configuration;
		monitors = new Map();
		topologyDescription = {
			type: configuration.topologyDescription.topologyType,
			setName: configuration.topologyDescription.setName,
			maxSetVersion: null,
			maxElectionId: null,
			servers: configuration.topologyDescription.servers.map(Topology.getDefaultServerDescription),
			compatible: true,
			compatibilityError: null,
		}
	}
	
	public function init() {
		for(server in topologyDescription.servers) {
			addMonitor(server);
		}
	}
	
	public function handleServerDescription(serverDescription:ServerDescription) {
		
		switch [serverDescription.type, topologyDescription.type] {
			case [Unknown | RSGhost, Unknown]: // no-op
			case [Standalone, Unknown]: updateUnknownWithStandalone(serverDescription);
			case [Mongos, Unknown]: topologyDescription.type = Sharded;
			case [RSPrimary, Unknown]: updateRSFromPrimary(serverDescription);
			case [RSSecondary | RSArbiter | RSOther, Unknown]: topologyDescription.type = ReplicaSetNoPrimary; updateRSWithoutPrimary(serverDescription);
			
			case [Unknown | Mongos, Sharded]: // no-op
			case [_, Sharded]: removeServer(serverDescription.address);
			
			case [Unknown | RSGhost, ReplicaSetNoPrimary]: // no-op
			case [Standalone | Mongos, ReplicaSetNoPrimary]: removeServer(serverDescription.address);
			case [RSPrimary, ReplicaSetNoPrimary]: updateRSFromPrimary(serverDescription);
			case [RSSecondary | RSArbiter | RSOther, ReplicaSetNoPrimary]: updateRSWithoutPrimary(serverDescription);
			
			case [Unknown | RSGhost, ReplicaSetWithPrimary]: checkIfHasPrimary();
			case [Standalone | Mongos, ReplicaSetWithPrimary]: removeServer(serverDescription.address); checkIfHasPrimary();
			case [RSPrimary, ReplicaSetWithPrimary]: updateRSFromPrimary(serverDescription);
			case [RSSecondary | RSArbiter | RSOther, ReplicaSetWithPrimary]: updateRSWithPrimaryFromMember(serverDescription);
			
			case [_, Single]:
			case [PossiblePrimary, _]:
		}
	}
	
	function findServer(address:Endpoint) {
		return topologyDescription.servers.find(function(s) return s.address == address);
	}
	
	function removeServer(address:Endpoint) {
		var server = findServer(address);
		topologyDescription.servers.remove(server);
		var monitor = monitors[address];
		monitors.remove(address);
		monitor.stop();
	}
	
	function addServer(address:Endpoint) {
		var server = Topology.getDefaultServerDescription(address);
		topologyDescription.servers.push(server);
		addMonitor(server);
	}
	
	function addMonitor(server:ServerDescription) {
		var monitor = new Monitor(server);
		monitors[server.address] = monitor;
		monitor.checkServer().handle(function(o) switch o {
			case Success(serverDescription):
				untyped console.log(serverDescription);
				handleServerDescription(serverDescription);
			case Failure(err):
				trace(err);
		});
	}
	
	function replaceServer(server, address) {
		removeServer(server);
		addServer(address);
	}
	
	function updateUnknownWithStandalone(description:ServerDescription) {
		var server = findServer(description.address);
		if(server == null)
			return;
			
		if(configuration.topologyDescription.servers.length == 1) {
			topologyDescription.type = Single;
		} else {
			removeServer(server.address);
		}
	}
	
	function updateRSWithoutPrimary(description:ServerDescription) {
		var server = findServer(description.address);
		if(server == null)
			return;

		if(topologyDescription.setName == null)
			topologyDescription.setName = description.setName;
		else if(topologyDescription.setName != description.setName) {
			removeServer(server.address);
			return;
		}
		
		for(address in description.hosts.concat(description.passives).concat(description.arbiters)) {
			var s = findServer(address);
			if(s == null) {
				addServer(address);
			}
		}
		
		if(description.address != description.me) {
			removeServer(server.address);
			return;
		}
		
		if(description.primary != null) {
			var s = topologyDescription.servers.find(function(s) return s.address == description.primary);
			if(s != null && s.type == Unknown) s.type = PossiblePrimary;
		}
	}
	
	function updateRSWithPrimaryFromMember(description:ServerDescription) {
		var server = findServer(description.address);
		if(server == null)
			return;
			
		if(topologyDescription.setName != description.setName)
			removeServer(server.address);
			
		if(description.address != description.me) {
			removeServer(server.address);
			checkIfHasPrimary();
			return;
		}
		
		if(topologyDescription.servers.find(function(s) return s.type == RSPrimary) == null)
			topologyDescription.type = ReplicaSetNoPrimary;
			
		if(description.primary != null) {
			var s = topologyDescription.servers.find(function(s) return s.address == description.primary);
			if(s != null && s.type == Unknown) s.type = PossiblePrimary;
		}
	}
	
	function updateRSFromPrimary(description:ServerDescription) {
		var server = findServer(description.address);
		if(server == null)
			return;

		if(topologyDescription.setName == null)
			topologyDescription.setName = description.setName
		else if(topologyDescription.setName != description.setName) {
			// We found a primary but it doesn't have the setName
			// provided by the user or previously discovered.
			removeServer(server.address);
			checkIfHasPrimary();
			return;
			
		}
		
		if(description.setVersion != null && description.electionId != null) {
			
			// Election ids are ObjectIds, see
			// "using setVersion and electionId to detect stale primaries"
			// for comparison rules.
			if (topologyDescription.maxSetVersion != null &&
				topologyDescription.maxElectionId != null && (
					topologyDescription.maxSetVersion > description.setVersion || (
						topologyDescription.maxSetVersion == description.setVersion &&
						topologyDescription.maxElectionId > description.electionId
					)
				)
			) {
				// Stale primary.
				replaceServer(server.address, description.address);
				checkIfHasPrimary();
				return;
			}
			
			topologyDescription.maxElectionId = description.electionId;
		}

		if (description.setVersion != null &&
			(topologyDescription.maxSetVersion == null ||
				description.setVersion > topologyDescription.maxSetVersion))
			topologyDescription.maxSetVersion = description.setVersion;

		for(server in topologyDescription.servers)
			if(server.address != description.address)
				if(server.type == RSPrimary)
					// See note below about invalidating an old primary.
					replaceServer(server.address, description.address);

		var others = description.hosts.concat(description.passives).concat(description.arbiters);
		for(address in others) {
			var s = findServer(address);
			if(s == null)
				addServer(address);
		}
		for(server in topologyDescription.servers)
			if(others.find(function(s) return s == server.address) == null)
				removeServer(server.address);

		checkIfHasPrimary();
	}
	
	function checkIfHasPrimary() {
		for(server in topologyDescription.servers) {
			if(server.type == RSPrimary)
				topologyDescription.type = ReplicaSetWithPrimary;
		}
	}
}