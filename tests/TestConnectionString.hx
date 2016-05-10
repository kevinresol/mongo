package;

import mongo.*;
import buddy.*;
import sys.io.File;
import sys.FileSystem;
import haxe.Json;
import mongo.protocol.ConnectionString;

using tink.CoreApi;
using haxe.io.Path;
using buddy.Should;
using Lambda;
using Reflect;
using StringTools;

class TestConnectionString extends BuddySuite {
	
	static inline var FOLDER = "spec/source/connection-string/tests/";
	
	public function new() {
		for(file in FileSystem.readDirectory(FOLDER)) {
			if(file.extension() == 'json') {
				describe(file, {
					for(t in getTests(file.withoutExtension())) {
						it(t.description, {
							switch ConnectionStringParser.parse(t.uri) {
								case Success(parsed):
									true.should.be(t.valid);
									if(t.hosts != null) {
										parsed.hosts.length.should.be(t.hosts.length);
										for(i in 0...parsed.hosts.length) {
											var host = parsed.hosts[i];
											switch host.name.split(']') {
												case [v]:
													v.urlDecode().should.be(t.hosts[i].host);
													// 'ipv4'.should.be(t.hosts[i].type);
												case [v, _]:
													v.substr(1).urlDecode().should.be(t.hosts[i].host);
													// 'ipv6'.should.be(t.hosts[i].type);
											}
											host.port.should.be(t.hosts[i].port);
										}
									}
									if(t.options != null) {
										for(key in parsed.options.fields()) {
											var value = parsed.options.field(key);
											if(Std.is(value, String))
												(value:String).should.be(t.options.field(key));
											else {
												for(subkey in value.fields()) {
													var subvalue = value.field(subkey);
													(subvalue:String).should.be(t.options.field(key).field(subkey));
												}
											}
										}
									}
								case Failure(err):
									false.should.be(t.valid);
							}
						});
					}
				});
			}
		}
	}
	
	function getTests(name:String):Array<ConnectionStringTestCase> {
		var path = FileSystem.absolutePath('spec/source/connection-string/tests/$name.json');
		var content = File.getContent(path);
		return Json.parse(content).tests;
	}
}

private typedef ConnectionStringTestCase = {
	auth: {
		db:String,
		password:String,
		username:String,
	}, 
	description:String,
	hosts:Array<{
		host:String,
		port:Int,
		type:String,
	}>,
	options:Dynamic, 
	uri:String, 
	valid:Bool,
	warning:Bool,
}