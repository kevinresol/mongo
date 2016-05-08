package;

import mongo.*;
import buddy.*;

using buddy.Should;
using Lambda;

class TestProtocol extends BuddySuite {
	public function new() {
		describe("Test Protocol", {
			
			var mongo = null;
			var db = null;
			var collection = null;
			
			it("Connect DB", function(done) {
				Mongo.connect().handle(function(o) switch o {
					case Success(s):
						mongo = s;
						db = mongo.db('test');
						collection = db.collection('users');
						done();
					case Failure(f):
						fail(f);
				});
			});
			
			it("Empty a collection", function(done) {
				collection.delete({
					deletes: [{q:{}, limit:0}]
				}).handle(function (o) switch o {
					case Success(s):
						done();
					case Failure(f):
						fail(f);
				});
			});
			
			it("Check collection is empty", function(done) {
				collection.count({}).handle(function (o) switch o {
					case Success(s):
						s[0].n.should.be(0);
						done();
					case Failure(f):
						fail(f);
				});
			});
			
			it("Insert data", function(done) {
				collection.insert({
					documents:[{a:1, b:1}]
				}).handle(function (o) switch o {
					case Success(s):
						done();
					case Failure(f):
						fail(f);
				});
			});
			
			it("Count is 1", function(done) {
				collection.count({}).handle(function (o) switch o {
					case Success(s):
						s[0].n.should.be(1);
						done();
					case Failure(f):
						fail(f);
				});
			});
			
			it("Insert again", function(done) {
				collection.insert({
					documents:[{c:1, d:1}]
				}).handle(function (o) switch o {
					case Success(s):
						done();
					case Failure(f):
						fail(f);
				});
			});
			
			it("Count is 2", function(done) {
				collection.count({}).handle(function (o) switch o {
					case Success(s):
						s[0].n.should.be(2);
						done();
					case Failure(f):
						fail(f);
				});
			});
			
			it("Filtered count", function(done) {
				collection.count({
					query: {a:1}
				}).handle(function (o) switch o {
					case Success(s):
						s[0].n.should.be(1);
						done();
					case Failure(f):
						fail(f);
				});
			});
			
			it("Drop collection", function(done) {
				collection.drop().handle(function (o) switch o {
					case Success(s):
						done();
					case Failure(f):
						fail(f);
				});
			});
			
			it("List collections", function(done) {
				db.listCollections({}).handle(function (o) switch o {
					case Success(s):
						s[0].cursor.firstBatch.find(function(c) return c.name == 'users').should.be(null);
						done();
					case Failure(f):
						fail(f);
				});
			});
			
		});
	}
}