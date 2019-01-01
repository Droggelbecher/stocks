
import std.datetime;
import std.json;
import std.regex;
import std.range;
import std.algorithm.setops: multiwayUnion;

import serialize;

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

	// Workaround for bugzilla #18320
	// https://issues.dlang.org/show_bug.cgi?id=18230
	int opCmp(const ref StockPrice other) {
		return date.opCmp(other.date);
	}
}

alias SortedRange!(StockPrice[], "a.date <= b.date") StockPrices;

class StockAPI {
	string name;
	JSONValue config;

	this(JSONValue config, string name) {
		this.name = name;
		this.config = config[this.name];
	}

	StockPrices historical(string symbol, DateTime from, DateTime to_) { return StockPrices([]); }
	SymbolInfo[] search_symbol(string term) { return []; }
}

mixin template CacheHistorical(alias get_historical) {
	override StockPrices historical(string symbol, DateTime from, DateTime to_) {
		string cache_name = this.name ~ "_" ~ symbol;

		StockPrices cache_prices = cache_get(cache_name, from, to_);
		StockPrices fresh_prices = [];
		StockPrices all = cache_prices;

		if(cache_prices.length == 0
				|| (cache_prices[0].date > from)
				|| (cache_prices[$ - 1].date < to_)) {

			fresh_prices = get_historical(symbol, from, to_);
			//all = multiwayUnion!"a.date < b.date"([cache_prices, fresh_prices]);
			all = StockPrices(multiwayUnion([cache_prices, fresh_prices]).array);

			cache_write(cache_name, all);
		}

		StockPrice r_from = { date: from };
		StockPrice r_to = { date: to_ };
		return all.upperBound(r_from).lowerBound(r_to);
	}
}

const string cache_dir = "stock_cache";

StockPrices cache_get(string name, DateTime from, DateTime to_) {
	import std.file;
	if(!exists(cache_dir)) { return StockPrices([]); }

	string filename = cache_dir ~ "/" ~ name ~ ".json";
	if(!exists(filename)) { return StockPrices([]); }

	auto r = regex(r"(\d{4})-(\d{2})-(\d{2})");
	return StockPrices(
		filename
		.readText.parseJSON["stock_price"]
		.from_json!(StockPrice[])
	);
}

void cache_write(string name, StockPrices prices) {
	import std.file;
	// TODO
	if(!exists(cache_dir)) {
		mkdir(cache_dir);
	}

	string filename = cache_dir ~ "/" ~ name ~ ".json";

	StockPrice[] prices_ = prices.release;
	JSONValue j = ["stock_price": prices_.to_json];
	prices = StockPrices(prices_);

	write(filename, j.toString);
}


