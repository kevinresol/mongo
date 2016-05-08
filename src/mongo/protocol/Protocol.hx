package mongo.protocol;

import bson.Bson;
import haxe.Int64;
import haxe.io.Bytes;
import haxe.io.BytesOutput;
import mongo.protocol.Message;
import tink.io.Source;
import tink.io.Sink;
import tink.io.Worker;
import tink.tcp.Endpoint;
import tink.tcp.Connection;

using tink.CoreApi;
using StringTools;

class Protocol {
	
	var connection:Connection;
	var requestId:Int = 0;
	var triggers:Map<Int, FutureTrigger<Outcome<ReplyMessage, Error>>>;
	var queue:List<{id:Int, bytes:Bytes}>;
	var piping:Bool = false;
	
	public function new() {
		
		triggers = new Map();
		queue = new List();
		
	}
	
	public function open(endpoint:Endpoint):Surprise<Noise, Error> {
		
		if(connection != null) throw 'Cannot connect twice';
		
		return Connection.tryEstablish(endpoint #if sys ,Worker.EAGER, Worker.EAGER #end) >>
			function(c:Connection) {
				connection = c;
				connection.source.parseStream(new ReplyMessageParser()).forEach(function(o) {
					triggerId(o.responseTo, Success(o));
					return true;
				});
				return Noise;
			}
	}
	
	public function close() {
		if(connection != null) {
			connection.close();
			connection = null;
		}
	}
	
	public function update(collection:String, query:Dynamic, data:Dynamic, flags = 0) {
		var out = new BytesOutput();
		out.writeInt32(0); // reserved
		out.writeString(collection);
		out.writeByte(0x00);
		out.writeInt32(flags);
		out.write(Bson.encode(query));
		out.write(Bson.encode(data));
		
		return request(OP_UPDATE, out.getBytes());
	}
	
	public function insert(collection:String, documents:Array<Dynamic>, flags = 0) {
		var out = new BytesOutput();
		out.writeInt32(flags);
		out.writeString(collection);
		out.writeByte(0x00);
		out.write(Bson.encodeMultiple(documents));
		
		return request(OP_INSERT, out.getBytes());
	}
	
	public function query(collection:String, ?query:Dynamic, ?projection:Dynamic, skip = 0, number = 0, flags = 0) {
		var out = new BytesOutput();
		out.writeInt32(flags);
		out.writeString(collection);
		out.writeByte(0x00);
		out.writeInt32(skip);
		out.writeInt32(number);
		
		if(query == null) query = {};
		out.write(Bson.encode(query));
		
		if(projection != null)
			out.write(Bson.encode(projection));
		
		return request(OP_QUERY, out.getBytes());
	}
	
	public function getMore(collection:String, cursorId:Int64, numReturn = 0) {
		var out = new BytesOutput();
		out.writeInt32(0); // reserved
		out.writeString(collection);
		out.writeByte(0x00);
		out.writeInt32(numReturn);
		out.writeInt32(cursorId.high);
		out.writeInt32(cursorId.low);
		
		return request(OP_GET_MORE, out.getBytes());
	}
	
	public function delete(collection:String, ?selector:Dynamic, flags = 0) {
		var out = new BytesOutput();
		out.writeInt32(0); // reserved
		out.writeString(collection);
		out.writeByte(0x00);
		out.writeInt32(flags);
		
		if(selector == null) selector = {};
		out.write(Bson.encode(selector));
		
		return request(OP_DELETE, out.getBytes());
	}
	
	public function killCursors(cursorIds:Array<Int64>) {
		var out = new BytesOutput();
		out.writeInt32(0); // reserved
		out.writeInt32(cursorIds.length);
		
		for(id in cursorIds) {
			out.writeInt32(id.high);
			out.writeInt32(id.low);
		}
		
		return request(OP_KILL_CURSORS, out.getBytes());
	}
	
	function request(opcode:Opcode, data:Bytes, responseTo:Int = 0):Surprise<ReplyMessage, Error> {
		
		if(connection == null) throw 'Not connected';
		
		var out = new BytesOutput();
		
		// standard message header
		out.writeInt32(data.length + 16); // include header length
		out.writeInt32(requestId++);
		out.writeInt32(responseTo);
		out.writeInt32(opcode);
		
		// body
		out.write(data);
		
		var trigger = Future.trigger();
		
		var id = requestId - 1; // make sure it is a private copy
		triggers[id] = trigger;
		addToQueue(id, out.getBytes());
		return trigger;
	}
	
	function addToQueue(id, bytes) {
		queue.add({id:id, bytes:bytes});
		if(!piping) pipe();
	}
	
	function pipe() {
		if(queue.length == 0) {
			piping = false;
			return;
		}
		piping = true;
		var item = queue.pop();
		(item.bytes:Source).pipeTo(connection.sink).handle(function(o) switch o {
			case AllWritten:
				pipe();
			case SinkFailed(e) | SourceFailed(e):
				triggerId(item.id, Failure(e));
			case SinkEnded:
				triggerId(item.id, Failure(new Error('sink ended')));
		});
	}
	
	function triggerId(id:Int, outcome:Outcome<ReplyMessage, Error>) {
		var t = triggers[id];
		if(t == null) return;
		t.trigger(outcome);
		triggers.remove(id);
	}
}

@:enum
abstract Opcode(Int) to Int
{
	var OP_REPLY        = 1; // used by server
	var OP_MSG          = 1000; // not used
	var OP_UPDATE       = 2001;
	var OP_INSERT       = 2002;
	// var OP_GET_BY_OID   = 2003;
	var OP_QUERY        = 2004;
	var OP_GET_MORE      = 2005;
	var OP_DELETE       = 2006;
	var OP_KILL_CURSORS = 2007;
}
