import std.stdio;
import std.format;
import std.getopt;
import std.file: readText;
import std.json: parseJSON, JSONValue;
import std.meta;
import std.typecons: Tuple;
import std.datetime;
import std.regex;

import stock_api;

import alphavantage;
import wallstreetjournal;

StockAPI[] apis;

JSONValue parseConfig(string filename) {
	auto json_data = readText(filename);
	return parseJSON(json_data);
}

StockAPI findAPI(string prefix) {
	foreach(api; apis) {
		if(api.name == prefix) {
			return api;
		}
	}
	assert(0);
}

void search_symbol(string term) {
	SymbolInfo[] r;
	foreach(api; apis) {
		r ~= api.search_symbol(term);
	}

	foreach(SymbolInfo si; r) {
		writeln("  %12s %6s '%s'".format(si.symbol, si.currency, si.name));
	}
}

void historical(string symbol, DateTime from, DateTime to_) {
	auto m = matchFirst(symbol, regex(`(\w+):(\w+)`));
	string prefix = m[1];
	string symb = m[2];

	writeln(findAPI(prefix).historical(symb, from, to_));
}

void parse_args(JSONValue config, string[] args) {
	auto command = args[1];

	switch(command) {
		case "search":
			search_symbol(args[2]);
			break;
		case "historical":
			historical(args[2], DateTime(2000, 1, 1), DateTime(2018, 12, 31));
			break;
		default:
			break;
	}
}


void main(string[] args) {
	auto config = parseConfig("config.json");
	apis = [
		new Alphavantage(config),
		new WallStreetJournal(config)
	];

	parse_args(config, args);
}
