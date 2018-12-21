/+

class Investopedia {
	string name = "ip";
	
	this(JSONValue config) {
		this.config = config;
	}

	SymbolInfo[] search_symbol(string term) {
		return SymbolInfo[];
	}

	StockPrice[] historical(string symbol, DateTime from, DateTime to) {
		auto url = format(
			//"https://www.investopedia.com/markets/api/partial/historical/?Symbol=%s&Type=Historical+Prices&Timeframe=Monthly&StartDate=Nov+28%2C+2017&EndDate=Dec+05%2C+2017
			"https://www.investopedia.com/markets/api/partial/historical/?Symbol=%s&Type=Historical+Prices&Timeframe=Monthly&StartDate=%s+%d%%2C+%d&EndDate=%s+%d%%2C+%d",
			symbol,
			from.month.str, from.day, from.year,
			to.month.str, to.day, to.year
		);
		auto content = parseJS
	}
}

+/
