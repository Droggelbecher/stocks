
import std.datetime;
import std.json;

struct SymbolInfo {
	string symbol;
	string currency;
	string name;
}

struct StockPrice {
	DateTime date;
	float open;
	float high;
	float low;
	float close;
}

class StockAPI {
	string name;
	JSONValue config;

	this(JSONValue config, string name) {
		this.name = name;
		this.config = config[this.name];
	}

	abstract StockPrice[] historical(string symbol, DateTime from, DateTime to_);
	abstract SymbolInfo[] search_symbol(string term);
}

