initDate = '10-Mar-2017';
endDate = datestr(now,'dd-mmm-yyyy');
Bench = '^GSPC';
MyPortfolio = {'SPY' 'SPYV' 'SPYG' 'BABA' 'BRK-B' 'AGG' 'COST' 'WMT'...
    'PGR' 'XLU' 'XLP' 'TCEHY' 'VTEB' 'VEA' 'KR'};
Weight = [8 3 11 4 6 2 1 2 3 2 2 3 3 1 1];
AveCost = [311.72 30.2 36.70 179.07 203.66 111.21 298.16 132.33 85.85 ...
    63.94 62.18 57.52 54.42 43.73 31.94];

Quantity = length(MyPortfolio);

% Set the benchmark
symbol = Bench;
BenchRaw = getMarketDataViaYahoo(symbol, initDate,endDate);
BenchHist_CloseAdj = table2array(BenchRaw(:,6));
BenchHist_Close = table2array(BenchRaw(:,5));
TDays = size(BenchHist_CloseAdj,1);
PortHist_CloseAdj = zeros(size(BenchHist_CloseAdj,1),Quantity);
PortHist_Close = zeros(size(BenchHist_CloseAdj,1),Quantity);

% Download historical adjusted close data for my portfolio
for i = 1:Quantity

    symbol = MyPortfolio{i};
    raw = getMarketDataViaYahoo(symbol, initDate,endDate);
    PortHist_CloseAdj(:,i) = table2array(raw(:,6));
    PortHist_Close(:,i) = table2array(raw(:,5));

end

% Calculate the Return of Paper Portfolio

PriceChange = PortHist_CloseAdj(end,:) - PortHist_CloseAdj(1,:);
BenchChange = BenchHist_CloseAdj(end) - BenchHist_CloseAdj(1);

PaperReturn = sum(PriceChange .* Weight);
InitialInvestment = sum(PortHist_CloseAdj(1,:) .* Weight);
PaperReturnRate = PaperReturn/InitialInvestment;
BenchReturnRate = BenchChange/BenchHist_CloseAdj(1);

%Calculate the daily return of paper portfolio
PaperPortfolio = sum((Weight .* PortHist_Close),2);
PaperPortfolio_Neutralized = PaperPortfolio/(sum(PortHist_Close(1,:) .* Weight));
Benchmark_Neutralized = BenchHist_Close / BenchHist_Close(1);
DailyPaperReturn = zeros(TDays -1,1);
DailyBenchReturn = zeros(TDays -1,1);

for i = 2:TDays
    DailyPaperReturn(i-1) = log(PaperPortfolio(i,:) ...
        ./ PaperPortfolio(i-1,:));
    DailyBenchReturn(i-1) = log(BenchHist_Close(i,:) ...
        ./ BenchHist_Close(i-1, :));
end

% Proposed New Portfolio
PropSelection = {'VUG' 'AAPL' 'MEDP' 'JD' 'DAL' 'LULU' 'MCD' 'NFLX' 'DG' 'TCEHY' 'PGR'};
PropQuantity = length(PropSelection);
PropPortHist_Close = zeros(TDays,PropQuantity);

for i = 1:PropQuantity

    symbol = PropSelection{i};
    prop = getMarketDataViaYahoo(symbol, initDate,endDate);
    PropPortHist_Close(:,i) = table2array(prop(:,5));
end


PropWeight = [2 5 4 3 5 1 3 1 3 4 5];
PropPortfolio = sum((PropWeight .* PropPortHist_Close),2);
% Why divide by mean? Because it is unrealistic to assume that I could have
% picked these stocks at 'initDate'. But it is relatively reasonable to
% assume I can make my cost at the average level of a certain period of
% time. 
PropPortfolio_Neutralized = PropPortfolio ./ mean(PropPortfolio);


% Create Line Chart 
figure
plot(PaperPortfolio_Neutralized);
hold on
plot(PropPortfolio_Neutralized);
Figure1 = plot(Benchmark_Neutralized,'-.');
hold off
title('Paper Portfolio vs Benchmark')
ylabel('Relative Price Change')
legend('Holding Portfolio','Proposed Portfolio','Benchmark')


% Calculate the return of my Holding. This not include the income
