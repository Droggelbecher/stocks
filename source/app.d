import std.stdio;
import std.format;
import std.getopt;
import std.file: readText;
import std.json: parseJSON, JSONValue;
import std.meta;
import std.typecons;
import std.datetime;
import std.regex;
import std.algorithm;
import std.array;

import stock_api;

import alphavantage;
import wallstreetjournal;
import stooq;

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

StockPrices[string] historical(string[] symbols, DateTime from, DateTime to_) {
	StockPrices[string] charts;

	foreach(symbol; symbols) {
		auto m = matchFirst(symbol, regex(`([^:]+):([^:]+)`));
		string prefix = m[1];
		string symb = m[2];

		charts[symbol] = findAPI(prefix).historical(symb, from, to_);
	}
	return charts;
}

void plot(StockPrices[string] charts, Flag!"performance" performance) {
	import ggplotd.aes: aes;
	import ggplotd.axes: xaxisLabel, yaxisLabel;
	import ggplotd.ggplotd: GGPlotD, putIn;
	import ggplotd.geom: geomPoint, geomLine;
	import ggplotd.scale: scale;
	import ggplotd.legend: discreteLegend;
	import ggplotd.colour: colourGradient;
	import ggplotd.colourspace: XYZ;
	import std.range;
	import std.array;

	auto colors = ["red", "blue", "green", "orange", "black"]; //0.1, 0.9];

	GGPlotD gg;
	foreach(string k, StockPrices vs, color; zip(charts.byPair, colors)) {
		writefln("%10s: %s", color, k);
		gg = vs
			.map!(x => aes!("x", "y", "label", "colour")(
				cast(float)x.date.year + ((x.date.month - 1) / 12.0),
				performance ? 100.0 * x.close / vs[0].close : x.close,
				k,
				color
			))
			//.map!(x => aes!("x", "y")(x.date, x.close))
			.geomLine
			.putIn(gg);
	}
	//gg = gg + scale();
	//gg = gg.put(discreteLegend);
	gg.save("/home/henning/host/Desktop/test.png");
}

StockPrices[string] common_span(StockPrices[string] charts) {
	auto latest_start = maxElement(charts.values.map!(x => x[0].date));
	auto earliest_end = minElement(charts.values.map!(x => x[$-1].date));

	StockPrice start = { date: latest_start };
	StockPrice end = { date: earliest_end };

	StockPrices[string] r;
	foreach(k, v; charts) {
		r[k] = v.lowerBound(end).upperBound(start);
	}
	//writeln("r=", r, latest_start, earliest_end);
	return r;
}

void parse_args(JSONValue config, string[] args) {
	auto command = args[1];

	switch(command) {
		case "search":
			search_symbol(args[2]);
			break;
		case "historical":
			auto charts = historical(args[2 .. $], DateTime(2010, 1, 1), DateTime(2018, 11, 30));
			//charts = common_span(charts);
			plot(charts, Yes.performance);
			break;
		default:
			break;
	}
}


void main(string[] args) {
	auto config = parseConfig("config.json");
	apis = [
		new Alphavantage(config),
		new WallStreetJournal(config),
		new Stooq(config),
	];

	parse_args(config, args);
}
