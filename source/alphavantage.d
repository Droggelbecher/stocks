
import std.format;
import std.json: parseJSON, JSONValue;
import std.net.curl: get;
import std.algorithm.iteration: map;
import std.array;
import std.uri;
import std.datetime;
import std.regex;
import std.stdio;
import std.conv;
import std.algorithm;

import stock_api;
import serialize;

class Alphavantage: StockAPI {

	this(JSONValue config) {
		super(config, "av");
	}

	override
	SymbolInfo[] search_symbol(string term) {
		auto url = format!"https://www.alphavantage.co/query?function=SYMBOL_SEARCH&keywords=%s&apikey=%s"(std.uri.encode(term), config["api_key"]);
				

		return url.get.parseJSON["bestMatches"]
			.array
			.map!(j => SymbolInfo(
				name ~ ":" ~ j["1. symbol"].str,
				j["8. currency"].str,
				j["2. name"].str
			)).array;
	}

	mixin CacheHistorical!get_historical;

	StockPrices get_historical(string symbol, DateTime from, DateTime to_) {
		auto url = format!"https://www.alphavantage.co/query?function=TIME_SERIES_MONTHLY&symbol=%s&apikey=%s"(std.uri.encode(symbol), config["api_key"]);
		auto re = regex(r"(\d{4})-(\d{2})-(\d{2})");

		writeln("Fetching: ", url);
		return //StockPrices(
			url.get
			.parseJSON["Monthly Time Series"]
			.object
			.byPair
			.map!((kv) {
				auto key = kv[0];
				auto value = kv[1];
				auto cap = key.matchFirst(re);
				//writeln("value=", value["1. open"]);
				StockPrice r = {
					date:  DateTime(cap[1].to!int, cap[2].to!int, cap[3].to!int),
					open:  value["1. open"].from_json!float,
					high:  value["2. high"].from_json!float,
					low:   value["3. low"].from_json!float,
					close: value["4. close"].from_json!float
				};
				return r;
			})
			// Values seem to be messed up sometimes on 31st decemeber here (eg factor 100 error on 31st dec 2018)
			// filter those out
			.filter!(sp => (sp.date.month != 12 || sp.date.day != 31))
			// Sometimes fields are randomly set to 0.000 (this dataset seems to be quite dirty)
			// "high" value does not seem to be affected, use that for correction
			.map!((sp) {
				StockPrice r = {
					date: sp.date,
					open: sp.open == 0.0 ? sp.high : sp.open,
					high: sp.high,
					low: sp.low == 0.0 ? sp.high : sp.low,
					close: sp.close == 0.0 ? sp.high : sp.close
				};
				return r;
			})
			.array
			.sort!"a.date <= b.date";
		//);
	}

}


