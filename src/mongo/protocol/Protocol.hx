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
	var reply:Signal<ReplyMessage>;
	var replyTrigger:SignalTrigger<ReplyMessage>;
	
	public function new() {
		
		reply = replyTrigger = Signal.trigger();
		
	}
	
	public function open(endpoint:Endpoint):Surprise<Noise, Error> {
		
		if(connection != null) throw 'Cannot connect twice';
		
		return Connection.tryEstablish(endpoint #if sys ,Worker.EAGER, Worker.EAGER #end) >>
			function(c:Connection) {
				connection = c;
				connection.source.parseStream(new ReplyMessageParser()).forEach(function(o){
					replyTrigger.trigger(o);
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
	
	public function query(collection:String, ?query:{}, ?projection:{}, skip = 0, number = 0, flags = 0) {
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
	
	function request(opcode:Opcode, data:Bytes, responseTo:Int = 0) {
		
		if(connection == null) throw 'Not connected';
		
		var out = new BytesOutput();
		
		// standard message header
		out.writeInt32(data.length + 16); // include header length
		out.writeInt32(requestId++);
		out.writeInt32(responseTo);
		out.writeInt32(opcode);
		
		// body
		out.write(data);
		
		return Future.async(function(cb) {
			
			var id = requestId - 1; // make sure it is a private copy
			var link:CallbackLink = null;
			
			link = reply.handle(function(m) {
				if(m.responseTo == id) {
					link.dissolve();
					cb(Success(m));
				}
			});
			
			// TODO: investigate what will happen if multi-pipe happen at the same time
			var source:Source = out.getBytes();
			source.pipeTo(connection.sink).handle(function(o) switch o {
				case AllWritten:
					// trace('all written');
				case SinkFailed(e) | SourceFailed(e):
					link.dissolve();
					cb(Failure(e));
				case SinkEnded:
					link.dissolve();
					cb(Failure(new Error('sink ended')));
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
	var OP_GETMORE      = 2005;
	var OP_DELETE       = 2006;
	var OP_KILL_CURSORS = 2007;
}
