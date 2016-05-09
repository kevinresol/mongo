package mongo.protocol;

import haxe.Int64;

typedef MessageHeader = {
	length:Int,
	requestId:Int,
	responseTo:Int,
	opcode:Int,
}

typedef ReplyMessage = ReplyMessageOf<Dynamic>;

typedef ReplyMessageOf<T> = {
	> MessageHeader,
	flags:Int,
	cursorId:Int64,
	startingFrom:Int,
	numReturned:Int,
	documents:Array<T>,
}

typedef UpdateMessage = {
	> MessageHeader,
	fullCollectionName:String,
	flags:Int,
	selector:Dynamic,
	update:Dynamic,
}

typedef InsertMessage = {
	> MessageHeader,
	flags:Int,
	fullCollectionName:String,
	documents:Array<Dynamic>,
}

typedef QueryMessage = {
	> MessageHeader,
	flags:Int,
	fullCollectionName:String,
	numberToSkip:Int,
	numberToReturn:Int,
	query:Dynamic,
	?projection:Dynamic,
}

typedef GetMoreMessage = {
	> MessageHeader,
	fullCollectionName:String,
	numberToReturn:Int,
	cursorId:Int64,
}

typedef DeleteMessage = {
	> MessageHeader,
	flags:Int,
	fullCollectionName:String,
	selector:Dynamic,
}

typedef KillCursorsMessage = {
	> MessageHeader,
	numCursors:Int,
	cursorIds:Array<Int64>,
}

/* Reply */

typedef Cursor<T> = {
	firstBatch:Array<T>,
	id:Int64,
	ns:String,
}

/* Aggregate commands */
typedef ReplyCount = {
	ok:Int,
	n:Int,
}

/* Query and Write Operation Commands */
typedef ReplyFind = {
	ok:Int, // 0 = failure, 1 = success
	waitedMS:Int64,
	cursor:Cursor<Dynamic>,
}

typedef ReplyInsert = {
	ok:Int,
	n:Int,
	?writeErrors:Array<WriteError>,
	?writeConcernError:WriteConcernError,
}
typedef ReplyUpdate = {
	ok:Int,
	n:Int,
	nModified:Int,
	?upserted:Array<Dynamic>,
	?writeErrors:Array<WriteError>,
	?writeConcernError:WriteConcernError,
}

typedef WriteError = {
	index:Int,
	code:Int,
	errmsg:String,
}
typedef WriteConcernError = {
	code:Int,
	errmsg:String,
}

typedef ReplyDelete = {
	ok:Int,
	n:Int,
	?writeErrors:Array<WriteError>,
	?writeConcernError:WriteConcernError,
}

typedef ReplyFindAndModify = {
	ok:Int,
	value:Dynamic,
	lastErrorObject: {updatedExisting:Bool, upserted:Dynamic, n:Int},
}

typedef ReplyGetMore = {
	> ReplyFind,
}

typedef ReplyGetLastError = {
	ok:Int,
	err:String,
	errmsg:String,
	code:Int,
	connectionId:Int, // TODO: unsure about the type
	lastOp:Int64, // TODO: unsure about the type
	n:Int,
	syncMillis:Int,
	shards:Array<String>, // TODO: unsure about the type
	shard:String, // TODO: unsure about the type
	updatedExisting:Bool,
	upserted:Dynamic,
	wnote:Dynamic, // TODO: unsure about the type
	wtimeout:Bool,
	waited:Int, // TODO: unsure about the type
	wtime:Int, // TODO: unsure about the type
	writtenTo:Array<Dynamic>, // TODO: unsure about the type
}

// typedef ReplyGetPrevError = {
// 	// no doc...
// }


/* Instance Administration Commands */

typedef ReplyListCollections = {
	ok:Int,
	cursor:Cursor<{name:String, options:Dynamic}>,
}

typedef ReplyCreateIndexes = {
	ok:Int,
	createdCollectionAutomatically:Bool,
	numIndexesBefore:Int,
	numIndexesAfter:Int,
	note:String,
	errmsg:String,
	code:Int,
}

typedef ReplyListIndexes = {
	ok:Int,
	cursor:Cursor<Dynamic>,
}

/* Replication Commands */
typedef ReplyIsMaster = {
	// all instances
	ok:Int,
	ismaster:Bool,
	maxBsonObjectSize:Int,
	maxMessageSizeBytes:Int,
	localTime:Date,
	minWireVersion:Int,
	maxWireVersion:Int,
	
	// sharded instances
	msg:String,
	
	// replica sets
	isreplicaset:Bool,
	setName:String,
	setVersion:Dynamic,
	secondary:Bool,
	hosts:Array<String>, // in the format 'host:port'
	passives:Array<String>, // in the format 'host:port'
	arbiters:Array<String>, // in the format 'host:port'
	primary:String, // in the format 'host:port'
	arbiterOnly:Bool,
	passive:Bool,
	hidden:Bool,
	tags:Dynamic, // figure out the type
	me:String, // in the format 'host:port'
	electionId:Dynamic, // figure out the type
}