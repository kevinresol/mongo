package mongo.topology;

import bson.*;
import mongo.topology.Types;
import tink.tcp.Endpoint;

// https://github.com/mongodb/specifications/blob/master/source/server-discovery-and-monitoring/server-discovery-and-monitoring.rst

class Topology {
	public static function getDefaultServerDescription(address:Endpoint):ServerDescription 
		return {
			address: address,
			error: null,
			roundTripTime: -1,
			type: Unknown,
			minWireVersion: 0,
			maxWireVersion: 0,
			me: null,
			hosts: [],
			passives: [],
			arbiters: [],
			tags: new Map(),
			setName: null,
			setVersion: null,
			electionId: null,
			primary: null,
		}
}
