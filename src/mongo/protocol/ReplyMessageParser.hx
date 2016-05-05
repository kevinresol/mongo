package mongo.protocol;

import bson.Bson;
import haxe.Int64;
import haxe.ds.Option;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.BytesBuffer;
import mongo.protocol.Message;
import tink.io.StreamParser;
import tink.io.Buffer;

using tink.CoreApi;

class ReplyMessageParser implements StreamParser<ReplyMessage> {
	
	var length = 0;
	var result:Option<ReplyMessage>;
	var out:BytesBuffer;
	
	public function new() {
		
		
	}
	
	public function minSize() 
		return 4;
	
	public function eof():Outcome<ReplyMessage, Error> {
		return Success(null); // TODO: will this ever happen?
	}
	
	public function progress(buffer:Buffer):Outcome<Option<ReplyMessage>, Error> {
		buffer.writeTo(this);
		return Success(result);
	}
	
	function writeBytes(bytes:Bytes, start:Int, len:Int) {
		
		if(length == 0) {
			result = None;
			length = bytes.getInt32(start);
			out = new BytesBuffer();
		}
		
		inline function min(a:Int, b:Int) return a > b ? b : a;
		
		var readLen = min(length - out.length, len);
		out.addBytes(bytes, start, readLen);
		if(out.length == length) {
			result = Some(constructMessage(out.getBytes()));
			length = 0;
		}
		return readLen;
	}
	
	function constructMessage(bytes:Bytes) {
		
		var input = new BytesInput(bytes);
		
		var length = input.readInt32();
		var requestId = input.readInt32();
		var responseTo = input.readInt32();
		var opcode = input.readInt32();
		var flags = input.readInt32();
		var cursorId = {
			var high = input.readInt32();
			var low = input.readInt32();
			Int64.make(high, low);
		}
		var startingFrom = input.readInt32();
		var numReturned = input.readInt32();
		var data = input.readAll();
		
		return {
			length: length,
			requestId: requestId,
			responseTo: responseTo,
			opcode: opcode,
			flags: flags,
			cursorId: cursorId,
			startingFrom: startingFrom,
			numReturned: numReturned,
			documents: Bson.decodeMultiple(data, numReturned),
		}
	}
}