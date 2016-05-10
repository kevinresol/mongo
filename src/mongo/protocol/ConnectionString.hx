package mongo.protocol;

import haxe.ds.Option;
import tink.url.*;
import tink.Url;

using tink.CoreApi;

typedef ConnectionString = {
	host:Host,
	hosts:Array<Host>,
	auth:Auth,
	options:Dynamic,
}

class ConnectionStringParser {
	
	static var optionDataTypes = [
		'w' => OInt,
		'authmechanismproperties.CANONICALIZE_HOST_NAME' => OBool,
		'authmechanismproperties.SERVICE_NAME' => OString,
		'wtimeoutms' => OInt,
		'replicaset' => OString,
		'authmechanism' => OString,
	];
	
	public static function parse(s:String):Outcome<ConnectionString, Error> {
		
		inline function fail(msg:String) return Failure(new Error(msg));
		
		try {
			var url:Url = s;
			
			if(url.hosts.length == 0 || url.host == '') return fail('Missing host');
			if(url.auth != null && (url.auth:String).split(':').length > 2) return fail('Unescaped colon');
			if(url.host != null && url.host.name.indexOf('@') != -1) return fail('Unescaped at-sign');
			if(url.scheme != 'mongodb') return fail('Invalid scheme');
			
			var options = 
				switch url.query {
					case null: null;
					case v:
						var o = {};
						var map = v.toMap();
						for(key in map.keys()) {
							var value = map[key];
							if(value == '') return fail('Incomplete key value pair');
							key = key.toLowerCase();
							switch value.indexOf(':') {
								case -1: 
									switch parseOption(key, value) {
										case Success(None): continue;
										case Success(Some(v)): Reflect.setField(o, key, v);
										case Failure(f): return Failure(f);
									}
								default:
									var sub = {};
									for(param in Query.parseString(value, ',', ':')) {
										switch parseOption('$key.' + param.name, param.value) {
											case Success(None): continue;
											case Success(Some(v)): Reflect.setField(sub, param.name, v);
											case Failure(f): return Failure(f);
										}
									}
									Reflect.setField(o, key.toLowerCase(), sub);
							}
						}
						o;
				}
			
			return Success({
				host: url.host,
				hosts: url.hosts,
				auth: url.auth,
				options: options,
			});
		} catch (e:Dynamic) {
			return fail(Std.string(e));
		}
	}
	
	static function parseOption(key, value):Outcome<Option<Dynamic>, Error> {
		inline function fail(msg:String) return Failure(new Error(msg));
		return switch [optionDataTypes[key], value] {
			case [OBool, 'true']: Success(Some(true));
			case [OBool, 'false']: Success(Some(false));
			case [OBool, _]: return fail('Invalid value for options "$key" ("$value")');
			case [OInt, Std.parseInt(_) => v]: if(v == null) return fail('Invalid value for options "$key" ("$value")') else Success(Some(v));
			case [OString, v]: Success(Some(v));
			case [null, _]: Success(None); // unknown options are ignored // TODO: warning message
		}
	}
	
	
}

enum OptionDataType {
	OBool;
	OInt;
	OString;
}