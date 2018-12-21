
import std.format;
import std.json: parseJSON, JSONValue;
import std.net.curl: get;
import std.algorithm.iteration: map;
import std.array;
import std.uri;
import std.datetime;

import stock_api;

class Alphavantage: StockAPI {

	this(JSONValue config) {
		super(config, "av");
	}

	override
	SymbolInfo[] search_symbol(string term) {
		auto url = format("https://www.alphavantage.co/query?function=SYMBOL_SEARCH&keywords=%s&apikey=%s", std.uri.encode(term), config["api_key"]);
				
		auto content = parseJSON(get(url));

		return content["bestMatches"]
			.array
			.map!(j => SymbolInfo(
				name ~ ":" ~ j["1. symbol"].str,
				j["8. currency"].str,
				j["2. name"].str
			)).array;
	}

	override
	StockPrice[] historical(string symbol, DateTime from, DateTime to_) {
		return [];
	}
}


