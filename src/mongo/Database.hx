package mongo;

import bson.BsonDocument;
import mongo.protocol.Protocol;
import mongo.protocol.Message;

using tink.CoreApi;

@:allow(mongo)
@:build(mongo.Macro.buildDatabase())
class Database implements Dynamic<Collection> {
	
	public var name(default, null):String;
	
	var protocol:Protocol;
	
	public function new(protocol:Protocol, name:String) {
		this.protocol = protocol;
		this.name = name;
	}
	
	public inline function runCommand<T>(command:BsonDocument):Surprise<Array<T>, Error> {
		return protocol.runCommand(name, command);
	}
	
	public inline function collection(name:String) {
		return resolve(name);
	}
	
	public function resolve(name:String):Collection {
		return new Collection(this, name);
	}
}