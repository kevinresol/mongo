package mongo;

import bson.BsonDocument;
import mongo.Options;
import mongo.protocol.Protocol;
import mongo.protocol.Message;

using tink.CoreApi;
using Reflect;

@:build(mongo.Macro.buildCollection())
class Collection {
	
	public var db(default, null):Database;
	public var name(default, null):String;
	public var fullname(default, null):String;
	
	var protocol(get, never):Protocol;
	
	public function new(db:Database, name:String) {
		this.db = db;
		this.name = name;
		fullname = db.name + '.$name';
		
	}
	
	inline function get_protocol()
		return db.protocol;
}
