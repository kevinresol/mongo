package mongo.protocol;

import haxe.Int64;

typedef MessageHeader = {
	length:Int,
	requestId:Int,
	responseTo:Int,
	opcode:Int,
}

typedef ReplyMessage = {
	> MessageHeader,
	flags:Int,
	cursorId:Int64,
	startingFrom:Int,
	numReturned:Int,
	documents:Array<Dynamic>,
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