
import std.conv;
import std.typecons;
import std.json: parseJSON, JSONValue;
import std.net.curl: get;
import std.regex;
import std.algorithm.iteration: map;
import std.array;
import std.csv;
import std.datetime;
import std.math: isNaN;
import std.stdio;

import stock_api;

class Stooq: StockAPI {
	this(JSONValue config) {
		super(config, "stooq");
	}

	mixin CacheHistorical!get_historical;

	StockPrices get_historical(string symbol, DateTime from, DateTime to_) {
		// ishares dow jones sus global: igsg.uk
		auto url = format(
				"https://stooq.com/q/d/l/?s=%s&i=m",
				symbol
		);
		auto re = regex(r"(\d{4})-(\d{2})-(\d{2})");
		writeln("Fetching: ", url);
		return StockPrices(
			url.get
			.csvReader!
				(Tuple!(string, float, float, float, float, float))
				(["Date", "Open", "High", "Low", "Close", "Volume"])
			.array
			.map!((row) {
				auto cap = row[0].matchFirst(re);
				StockPrice r = {
					date: DateTime(cap[1].to!int, cap[2].to!int, cap[3].to!int),
					open: row[1].to!float,
					high: row[2].to!float,
					low: row[3].to!float,
					close: row[4].to!float
				};
				return r;
			})
			.array
		);
	}

}

