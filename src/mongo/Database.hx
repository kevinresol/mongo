package mongo;

import bson.BsonDocument;
import mongo.protocol.Protocol;
import mongo.protocol.Message;

using tink.CoreApi;

@:allow(mongo)
@:build(mongo.Macro.buildDatabase())
class Database implements Dynamic<Collection> {
	
	public var name(default, null):String;
	public var mongo(default, null):Mongo;
	
	var protocol(get, never):Protocol;
	
	public function new(mongo:Mongo, name:String) {
		this.mongo = mongo;
		this.name = name;
	}
	
	public function runCommand(command:BsonDocument):Surprise<ReplyMessage, Error> {
		return protocol.query(name + ".$cmd", command, null, 0, -1);
	}
	
	public inline function collection(name:String) {
		return resolve(name);
	}
	
	public function resolve(name:String):Collection {
		return new Collection(this, name);
	}
	
	inline function get_protocol()
		return mongo.protocol;
}