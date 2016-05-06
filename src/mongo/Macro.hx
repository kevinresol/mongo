package mongo;

import haxe.macro.Context;
import haxe.macro.Expr;
using tink.MacroApi;

class Macro {
	public static function buildCollection() {
		
		var commands:Array<Command> = [
			{
				name: 'find'
			},
			{
				name: 'insert'
			},
			{
				name: 'update'
			},
			{
				name: 'findAndModify',
			},
			{
				name: 'getMore', 
				cmd: [
					{key: 'getMore', expr: macro options.cursorId},
					{key: 'collection', expr: macro name},
				],
			},
			{
				name: 'getLastError',
				cmd: [{key: 'getLastError', expr: macro 1}]
			},
			{
				name: 'getPrevError',
				cmd: [{key: 'getPrevError', expr: macro 1}]
			},
			{
				name: 'createIndexes',
			},
			{
				name: 'listIndexes',
			},
			{
				name: 'drop',
				cmd:[{key: 'drop', expr: macro 1}],
			},
			{
				name: 'count',
			},
		];
		
		return build(macro db.runCommand, commands);
	}
	
	public static function buildDatabase() {
		
		// return null;
		var commands = [
			{
				name: 'dropDatabase',
				cmd:[{key: 'dropDatabase', expr: macro 1}],
			},
			{
				name: 'listCollections',
				cmd:[{key: 'listCollections', expr: macro 1}],
			},
		];
		return build(macro runCommand, commands);
	}
	
	static function build(runCommand:Expr, commands:Array<Command>) {
		var pos = Context.currentPos();
		
		return ClassBuilder.run([
			function(cb:ClassBuilder) {
				for(command in commands) {
					
					var cmd = command.name;
					var cap = cmd.substr(0, 1).toUpperCase() + cmd.substr(1);
					var ct = 'mongo.Options.${cap}Options'.asComplexType();
					var map = new Map<String, Expr>();
					var noOptions = switch ct.toType() {
						case Success(_.reduce() => TAnonymous(_.get() => a)):
							for(f in a.fields) {
								var skip = f.meta.has(':skip');
								if(skip)
									map.set(f.name, macro continue);
								
								var rename = f.meta.extract(':rename');
								if(rename != null && rename.length > 0) {
									if(skip) throw "Cannot define both @:skip and @:rename";
									if(rename[0].params.length != 1) throw "@:rename needs exactly one parameter";
									map.set(f.name, rename[0].params[0]);
								}
							}
							false;
						default:
							true;
					}
					var reply = 'mongo.protocol.Message.Reply$cap'.asComplexType();
					if(!reply.toType().isSuccess()) reply = macro:Dynamic;
					var ret = macro:tink.CoreApi.Surprise<mongo.protocol.Message.ReplyMessageOf<$reply>, tink.CoreApi.Error>;
					
					var cases = [for(key in map.keys()) {values: [macro $v{key}], expr: ${map[key]}, guard: null}];
					
					if(command.cmd == null) command.cmd = [{key: cmd, expr: macro name}];
					
					var func = 
						if(noOptions)
							macro function():$ret {
								var cmd = new BsonDocument();
								$b{[for(e in command.cmd) macro cmd.add($v{e.key}, ${e.expr})]}
								return $runCommand(cmd);
							}
						else
							macro function(options:$ct):$ret {
								var cmd = new BsonDocument();
								$b{[for(e in command.cmd) macro cmd.add($v{e.key}, ${e.expr})]}
								for(field in Reflect.fields(options)) {
									var key = ${cases.length > 0 ? ESwitch(macro field, cases, macro field).at() : macro field}
									cmd.add(key, Reflect.field(options, field));
								}
								return $runCommand(cmd);
							}
					
					cb.addMember({
						pos: pos,
						name: cmd,
						kind: FFun(func.getFunction().sure()),
						access: [APublic],
						doc: 'https://docs.mongodb.com/manual/reference/command/$cmd'
					});
				}
			}
		]);
	}
}

typedef Command = {
	name:String,
	?cmd:Array<{key:String, expr:Expr}>,
}