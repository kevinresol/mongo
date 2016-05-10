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
	
	var connections:ConnectionPool;
	var requestId:Int = 0;
	
	public function new() {
		
		
	}
	
	public function open(endpoint:Endpoint):Surprise<Noise, Error> {
		
		if(connections != null) throw 'Cannot connect twice';
		return Connection.tryEstablish(endpoint) >>
			function(c:Connection) {
				c.close();
				connections = new ConnectionPool(endpoint);
				return Noise;
			}
		
	}
	
	public function close() {
		if(connections != null) {
			connections.close();
			connections = null;
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
		
		if(connections == null) throw 'Not connected';
		
		var out = new BytesOutput();
		
		// standard message header
		out.writeInt32(data.length + 16); // include header length
		out.writeInt32(requestId++);
		out.writeInt32(responseTo);
		out.writeInt32(opcode);
		
		// body
		out.write(data);
		
		return Future.async(function(cb) {
			var cnx = connections.get();
			function fail(err:Error) {
				cnx.close();
				return Failure(err);
			}
			
			// TODO: pool the parsers?
			cnx.source.parse(new ReplyMessageParser()).handle(function(o) switch o {
				case Success(d): 
					cb(Success(d.data)); 
					connections.put(cnx);
				case Failure(f): 
					cb(fail(f));
			});
			
			(out.getBytes():Source).pipeTo(cnx.sink).handle(function(o) switch o {
				case SinkFailed(e) | SourceFailed(e):
					cb(fail(e));
				case SinkEnded:
					cb(fail(new Error('sink ended')));
				case AllWritten:
			});
		});
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

class ConnectionPool {
	
	var endpoint:Endpoint;
	var connections:List<Connection>;
	var closed = false;
	
	public function new(endpoint:Endpoint) {
		this.endpoint = endpoint;
		connections = new List();
	}
	
	public function get():Connection {
		if(closed) throw 'This connection pool has been closed';
		if(connections.length == 0)
			return Connection.establish(endpoint);
		else
			return connections.pop();
	}
	
	public function put(cnx:Connection) {
		if(closed)
			cnx.close();
		else
			connections.add(cnx);
	}
	
	public function close() {
		closed = true;
		for(c in connections) c.close();
	}
}
