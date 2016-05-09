package mongo.topology;

import bson.*;
import tink.tcp.Endpoint;

typedef ServerAddress = Endpoint;


enum TopologyType {
	Single;
	ReplicaSetNoPrimary;
	ReplicaSetWithPrimary;
	Sharded;
	Unknown;
}

enum ServerType {
	Standalone;
	Mongos;
	PossiblePrimary;
	RSPrimary;
	RSSecondary;
	RSArbiter;
	RSOther;
	RSGhost;
	Unknown;
}

typedef TopologyDescription = {
	/** a TopologyType enum value. The default is Unknown. **/
	var type:TopologyType;
	/** the replica set name. Default null. **/
	var setName:String;
	/** an integer or null. The largest setVersion ever reported by a primary. Default null. **/
	var maxSetVersion:Null<Int>;
	/** an ObjectId or null. The largest electionId ever reported by a primary. Default null. **/
	var maxElectionId:ObjectId;
	/** a set of ServerDescription instances. Default contains one server: "localhost:27017", ServerType Unknown. **/
	var servers:Array<ServerDescription>;
	/** a boolean for single-threaded clients, whether the topology must be re-scanned. **/
	// var stale:Bool;
	/** a boolean. False if any server's wire protocol version range is incompatible with the client's. Default true. **/
	var compatible:Bool;
	/** a string. The error message if "compatible" is false, otherwise null. **/
	var compatibilityError:String;

}

typedef ServerDescription = {
	/** the hostname or IP, and the port number, that the client connects to. Note that this is not the server's ismaster.me field, in the case that the server reports an address different from the address the client uses. **/
	var address:Endpoint;
	/** information about the last error related to this server. Default null. **/
	var error:String;
	/** the duration of the ismaster call. Default null. **/
	var roundTripTime:Int;
	/** a ServerType enum value. Default Unknown. **/
	var type:ServerType;
	/** the wire protocol version range supported by the server. Both default to 0. Use min and maxWireVersion only to determine compatibility. **/
	var minWireVersion:Int;
	var maxWireVersion:Int;
	/** The hostname or IP, and the port number, that this server was configured with in the replica set. Default null. **/
	var me:Endpoint;
	/** Sets of addresses. This server's opinion of the replica set's members, if any. These hostnames are normalized to lower-case. Default empty. The client monitors all three types of servers in a replica set. **/
	var hosts:Array<Endpoint>;
	var passives:Array<Endpoint>;
	var arbiters:Array<Endpoint>;
	/** map from string to string. Default empty. **/
	var tags:Map<String, String>;
	/** string or null. Default null. **/
	var setName:String;
	/** integer or null. Default null. **/
	var setVersion:Int;
	/** an ObjectId, if this is a MongoDB 2.6+ replica set member that believes it is primary. See using setVersion and electionId to detect stale primaries. Default null. **/
	var electionId:ObjectId;
	/** an address. This server's opinion of who the primary is. Default null. **/
	var primary:Endpoint;
}

typedef Configuration = {
	topologyDescription: {
		servers:Array<Endpoint>,
		topologyType:TopologyType,
		setName:String,
		// TODO: https://github.com/mongodb/specifications/blob/master/source/server-discovery-and-monitoring/server-discovery-and-monitoring.rst#allowed-configuration-combinations
	},
	heartbeatFrequencyMS:Int,
	socketCheckIntervalMS:Int,
	
}