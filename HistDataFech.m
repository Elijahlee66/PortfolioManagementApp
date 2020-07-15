initDate = '1-Dec-2019';
endDate = '4-Mar-2020';
Bench = '^GSPC';
MyPortfolio = {'SPY' 'BABA' 'BRK-B' 'AGG' 'VO' 'COST' 'WMT' 'PGR' 'XLU'...
    'XLP' 'TCEHY' 'VTEB' 'VEA' 'KR'};
Weight = [8 4 6 2 0 1 2 3 2 2 2 3 1 1];
AveCost = [311.72 179.07 203.66 111.21 0 298.16 132.33 85.85 63.94 62.18...
    57.52 54.42 43.73 31.94];

Num = length(MyPortfolio);

% Set the benchmark
symbol = Bench;
BenchRaw = getMarketDataViaYahoo(symbol, initDate);
BenchHist_CloseAdj = table2array(BenchRaw(:,6));
BenchHist_Close = table2array(BenchRaw(:,5));

PortHist_CloseAdj = zeros(size(BenchHist_CloseAdj,1),Num);
PortHist_Close = zeros(size(BenchHist_CloseAdj,1),Num);

% Download historical adjusted close data for my portfolio
for i = 1:Num

    symbol = MyPortfolio{i};
    raw = getMarketDataViaYahoo(symbol, initDate);
    PortHist_CloseAdj(:,i) = table2array(raw(:,6));
    PortHist_Close(:,i) = table2array(raw(:,5));

end

% Calculate Holding Period Return

PriceChange = PortHist_CloseAdj(end,:) - PortHist_CloseAdj(1,:);
BenchChange = BenchHist_CloseAdj(end) - BenchHist_CloseAdj(1);

HoldingReturn = sum(PriceChange .* Weight);
InitialInvestment = sum(PortHist_CloseAdj(1,:) .* Weight);
HoldingReturnRate = HoldingReturn/InitialInvestment;
BenchReturnRate = BenchChange/BenchHist_CloseAdj(1);
