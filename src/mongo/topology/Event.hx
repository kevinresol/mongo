package mongo.topology;

import haxe.Int64;
import mongo.topology.Types;

/**
 * Published when server description changes, but does NOT include changes to the RTT.
 */
typedef ServerDescriptionChangedEvent = {

	/**
	 * Returns the address (host/port pair) of the server.
	 */
	var address:ServerAddress;

	/**
	 * Returns a unique identifier for the topology.
	 */
	var topologyId:Dynamic;

	/**
	 * Returns the previous server description.
	 */
	var previousDescription:ServerDescription;

	/**
	 * Returns the new server description.
	 */
	var newDescription:ServerDescription;
 }

/**
 * Published when server is initialized.
 */
typedef ServerOpeningEvent = {

	/**
	 * Returns the address (host/port pair) of the server.
	 */
	var address:ServerAddress;

	/**
	 * Returns a unique identifier for the topology.
	 */
	var topologyId:Dynamic;
 }

/**
 * Published when server is closed.
 */
typedef ServerClosedEvent = {

	/**
	 * Returns the address (host/port pair) of the server.
	 */
	var address:ServerAddress;

	/**
	 * Returns a unique identifier for the topology.
	 */
	var topologyId:Dynamic;
 }

 /**
 * Published when topology description changes.
 */
typedef TopologyDescriptionChangedEvent = {

	/**
	 * Returns a unique identifier for the topology.
	 */
	var topologyId:Dynamic;

	/**
	 * Returns the old topology description.
	 */
	var previousDescription:TopologyDescription;

	/**
	 * Returns the new topology description.
	 */
	var newDescription:TopologyDescription;
 }

 /**
 * Published when topology is initialized.
 */
typedef TopologyOpeningEvent = {

	/**
	 * Returns a unique identifier for the topology.
	 */
	var topologyId:Dynamic;
 }

 /**
 * Published when topology is closed.
 */
typedef TopologyClosedEvent = {

	/**
	 * Returns a unique identifier for the topology.
	 */
	var topologyId:Dynamic;
 }

/**
 * Fired when the server monitor’s ismaster command is started - immediately before
 * the ismaster command is serialized into raw BSON and written to the socket.
 */
typedef ServerHeartbeatStartedEvent = {

	/**
	 * Returns the connection id for the command. The connection id is the unique
	 * identifier of the driver’s Connection Dynamic that wraps the socket. For languages that
	 * do not have this Dynamic, this MUST a string of “hostname:port” or an Dynamic that
	 * that contains the hostname and port as attributes.
	 *
	 * The name of this field is flexible to match the Dynamic that is returned from the driver.
	 * Examples are, but not limited to, ‘address’, ‘serverAddress’, ‘connectionId’,
	 */
	var serverAddress:ServerAddress;

 }

 /**
 * Fired when the server monitor’s ismaster succeeds.
 */
typedef ServerHeartbeatSucceededEvent = {

	/**
	 * Returns the execution time of the event in the highest possible resolution for the platform.
	 * The calculated value MUST be the time to send the message and receive the reply from the server,
	 * including BSON serialization and deserialization. The name can imply the units in which the
	 * value is returned, i.e. durationMS, durationNanos. The time measurement used
	 * MUST be the same measurement used for the RTT calculation.
	 */
	var duration:Int64;

	/**
	 * Returns the command reply.
	 */
	var reply:Dynamic;

	/**
	 * Returns the connection id for the command. For languages that do not have this,
	 * this MUST return the driver equivalent which MUST include the server address and port.
	 * The name of this field is flexible to match the Dynamic that is returned from the driver.
	 */
	var serverAddress:ServerAddress;

 }

 /**
 * Fired when the server monitor’s ismaster fails, either with an “ok:0” or a socket exception.
 */
typedef ServerHearbeatFailedEvent = {

	/**
	 * Returns the execution time of the event in the highest possible resolution for the platform.
	 * The calculated value MUST be the time to send the message and receive the reply from the server,
	 * including BSON serialization and deserialization. The name can imply the units in which the
	 * value is returned, i.e. durationMS, durationNanos.
	 */
	var duration:Int64;

	/**
	 * Returns the failure. Based on the language, this SHOULD be a message string,
	 * exception Dynamic, or error document.
	 */
	var failure:Dynamic; //String,Exception,Document;

	/**
	 * Returns the connection id for the command. For languages that do not have this,
	 * this MUST return the driver equivalent which MUST include the server address and port.
	 * The name of this field is flexible to match the Dynamic that is returned from the driver.
	 */
	var serverAddress:ServerAddress;
 }

 /**
 * Describes the current topology.
 */
typedef TopologyDescription = {

	/**
	 * Determines if the topology has a readable server available.
	 */
	function hasReadableServer(readPreference:ReadPreference):Bool

	/**
	 * Determines if the topology has a writable server available.
	 */
	function hasWritableServer():Bool
 }