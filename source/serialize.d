
import std.json;
import std.datetime;
import std.format;
import std.algorithm.iteration: map;
import std.array;
import std.traits;
import std.stdio;
import std.regex;
import std.conv;

JSONValue to_json(T)(T v)
	if(
			isScalarType!T
			|| is(T: JSONValue[])
			|| is(T: JSONValue[string])
			|| is(T: string)
			|| is(T: JSONValue)
	)
{
	return JSONValue(v);
}

/+
JSONValue to_json(T: JSONValue[])(T v) {
	return JSONValue(v);
}

JSONValue to_json(T: string)(T v) {
	return JSONValue(v);
}
+/

JSONValue to_json(T: V[], V)(T v)
	if(!is(T: string) && !is(V: JSONValue))
{
	return to_json(v.map!(to_json!V).array);
}

JSONValue to_json(T: DateTime)(T v) {
	return to_json(format!"%04d-%02d-%02d"(v.year, v.month, v.day));
}

JSONValue to_json(T)(T v)
	if(is(T == struct) || is(T == class))
{
	JSONValue[string] r;
 
	foreach(i, ref field; v.tupleof) {
		enum name = __traits(identifier, v.tupleof[i]);
		r[name] = to_json(field);
	}
	return to_json(r);
}

unittest {
	to_json(DateTime(2018, 12, 24));
	to_json([
			DateTime(2018, 12, 22),
			DateTime(2018, 12, 23),
			DateTime(2018, 12, 24),
	]);

	struct Foo {
		int x = 55;
		DateTime dt = DateTime(2018, 11, 17);
		float y = 3.0;
		string s = "Some String";
	};
	Foo foo;
	assert(to_json(foo) == `{"dt":"2018-11-17","s":"Some String","x":55,"y":3}`);
}

T from_json(T)(JSONValue v) if(is(T == struct)) {
	T r;
	foreach(i, ref field; r.tupleof) {
		enum name = __traits(identifier, r.tupleof[i]);
		r.tupleof[i] = from_json!(typeof(r.tupleof[i]))(v[name]);
	}
	return r;
}

T from_json(T)(JSONValue v)
	if(isScalarType!T) {
	switch(v.type) {
		case JSON_TYPE.INTEGER:
			return v.integer.to!T;
		case JSON_TYPE.UINTEGER:
			return v.uinteger.to!T;
		case JSON_TYPE.STRING:
			return v.str.to!T;
		case JSON_TYPE.FLOAT:
			return v.floating.to!T;
		case JSON_TYPE.TRUE:
			return true.to!T;
		case JSON_TYPE.FALSE:
			return false.to!T;
		default:
			assert(0);
	}
}

/+
T from_json(T: long)(JSONValue v) { return cast(T)v.integer; }

T from_json(T: string)(JSONValue v) { return v.str; }
+/
T from_json(T: DateTime)(JSONValue v) {
	auto re = regex(r"(\d{4})-(\d{2})-(\d{2})");
	auto cap = v.str.matchFirst(re);
	return DateTime(cap[1].to!int, cap[2].to!int, cap[3].to!int);
}

T from_json(T: V[], V)(JSONValue v) {
	return v.array.map!(from_json!V).array;
}

unittest {
	struct Foo {
		int x;
		DateTime dt;
		float y = 3.0;
		string s;
	};
	Foo foo;

	const string json = `{ "x": 3, "dt": "2018-12-24", "y": 3.14, "s": "Hello, World" }`;

	foo = json.parseJSON.from_json!Foo;
	assert(foo == Foo(3, DateTime(2018, 12, 24), 3.14, "Hello, World"));
}



