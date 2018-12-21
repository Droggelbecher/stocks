
import std.algorithm.iteration: map;
import std.array;
import std.csv;
import std.datetime;
import std.format;
import std.json: parseJSON, JSONValue;
import std.net.curl: get;
import std.regex;
import std.typecons: Tuple;
import std.typecons;
import std.uri;
import std.conv;
import std.stdio;

import stock_api;

class WallStreetJournal: StockAPI {
	this(JSONValue config) {
		super(config, "wsj");
	}

	override
	SymbolInfo[] search_symbol(string term) {
		return [];
	}

	override
	StockPrice[] historical(string symbol, DateTime from, DateTime to_) {
		auto url = format(
			"http://quotes.wsj.com/%s/historical-prices/download?MOD_VIEW=page&num_rows=6299.041666666667&range_days=6299.041666666667&startDate=%d/%d/%d&endDate=%d/%d/%d",
			symbol,
			from.month, from.day, from.year,
			to_.month, to_.day, to_.year
		);
		auto r = regex(r"(\d+)/(\d+)/(\d+)");
		return url.get
			.csvReader!(Tuple!(string, float, float, float, float))
			.array
			.map!(delegate(row) {
				auto cap = row[0].matchFirst(r);
				return StockPrice(
					DateTime(to!int(cap[2]), to!int(cap[0]), to!int(cap[1])),
					row[1], row[2], row[3], row[4]
				);
			})
			.array;
	}
}


