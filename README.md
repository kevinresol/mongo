# mongo

Pure Haxe MongoDB driver that is meant to be truly cross platform.

# Background

There are [other](https://github.com/MattTuttle/mongo-haxe-driver) [Haxe drivers](https://bitbucket.org/yar3333/haxe-mongomod) out there but they uses `sys.net.Socket` which is not available on all targets. Also they use sync operations which is not suitable in single-thread environments.

This driver utilizes [tink_tcp](https://github.com/haxetink/tink_tcp) which provides async TCP operations across all targets in a consistent manner. So this driver should work on any targets that is supported by tink_tcp.

# Status

This is pretty much work in progress in a sense that not all database commands are implemented as a function call (e.g. `db.dropDatabase()` or `collection.find({})`). But you can run most, if not all, commands through `db.runCommand(command)` by following the [official manual](https://docs.mongodb.com/manual/reference/command).

In other words, `collection.find({filter:{a:1}})` is equivalent to:
```haxe
var cmd = new BsonDocument();
cmd.add('find', 'collection_name');
cmd.add('filter', {a:1});
db.runCommand(cmd);
```

# Usage

```haxe
Mongo.connect().handle(function(o) switch(o) {
	case Success(mongo):
		var db = mongo.db('test');
		var collection = db.collection('users');
		collection.find({filter:{username:'foo'}}).handle(function(o) trace(o));
	case Failure(err):
		trace(err);
});
```

More to come...


# Note

This library is the driver only. So, do expect that the commands and responses will be very "raw", though efforts has been made to properly typing them.

THis library does not include ORM, but they can be built based on this driver.