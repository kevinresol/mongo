package mongo;

import haxe.Int64;

// https://docs.mongodb.com/manual/reference/write-concern/
typedef WriteConcern = {
	w:Dynamic,
	j:Bool,
	wtimeout:Int
}
// https://docs.mongodb.com/manual/reference/read-concern/
typedef ReadConcern = {
	level:String,
}

/* Aggregate commands */
typedef CountOptions = {
	@:optional var query:Dynamic;
	@:optional var limit:Int;
	@:optional var skip:Int;
	@:optional var hint:Dynamic; // string or document
	@:optional var readConcern:ReadConcern;
}

/* Query and Write Operation Commands */

typedef FindOptions = {
	@:optional var filter:Dynamic;
	@:optional var sort:Dynamic;
	@:optional var projection:Dynamic;
	@:optional var hint:Dynamic; // document or string
	@:optional var skip:Int;
	@:optional var limit:Int;
	@:optional var batchSize:Int;
	@:optional var singleBatch:Bool;
	@:optional var comment:String;
	@:optional var maxScan:Int;
	@:optional var maxTimeMS:Int;
	@:optional var readConcern:ReadConcern;
	@:optional var max:Dynamic;
	@:optional var min:Dynamic;
	@:optional var returnKey:Bool;
	@:optional var showRecordId:Bool;
	@:optional var snapshot:Bool;
	@:optional var tailable:Bool;
	@:optional var oplogReplay:Bool;
	@:optional var noCursorTimeout:Bool;
	@:optional var awaitData:Bool;
	@:optional var allowPartialResults:Bool;
}

typedef InsertOptions = {
	var documents:Array<Dynamic>;
	@:optional var ordered:Bool;
	@:optional var writeConcern:WriteConcern;
	@:optional var bypassDocumentValidation:Bool;
}

typedef UpdateOptions = {
	var updates:Array<{q:Dynamic, u:Dynamic, upsert:Bool, multi:Bool}>;
	@:optional var ordered:Bool;
	@:optional var writeConcern:WriteConcern;
	@:optional var bypassDocumentValidation:Bool;
}

typedef DeleteOptions = {
	var deletes:Array<{q:Dynamic, limit:Int}>;
	@:optional var ordered:Bool;
	@:optional var writeConcern:WriteConcern;
}

typedef FindAndModifyOptions = {
	@:optional var query:Dynamic;
	@:optional var sort:Dynamic;
	@:optional var remove:Bool; // must specify either `remove` or `update`
	@:optional var update:Dynamic; // must specify either `remove` or `update`
	@:optional @:rename("new") var new_:Bool;
	@:optional var fields:Dynamic;
	@:optional var upsert:Bool;
	@:optional var bypassDocumentValidation:Bool;
	@:optional var writeConcern:Dynamic;
}

typedef GetMoreOptions = {
	@:skip var cursorId:Int64;
	@:optional var batchSize:Int;
	@:optional var maxTimeMS:Int;
}

typedef GetLastErrorOptions = {
	> WriteConcern,
}

/* Instance Administration Commands */

typedef ListCollectionsOptions = {
	@:optional var filter:Dynamic;
}

typedef CreateIndexesOptions = {
	var indexes:Array<{
		key:Dynamic,
		name:String,
		?background:Bool,
		?unique:Bool,
		?partialFilterExpression:Dynamic,
		?sparse:Bool,
		expireAfterSeconds:Int,
		storageEngine:Dynamic,
		weights:Dynamic,
		default_language:String,
		language_override:String,
		textIndexVersion:Int,
		// 2dsphereIndexVersion:Int, // invalid haxe identifier...
		bits:Int,
		min:Float,
		max:Float,
		bucketSize:Float,
	}>;
}