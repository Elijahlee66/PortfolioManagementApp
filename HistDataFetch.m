clear All;
clc;

initDate = '20-Dec-2019';
% initDate = '1-Nov-2019';
% endDate =  '1-Apr-2020';
endDate = datestr(now,'dd-mmm-yyyy');
Bench = '^GSPC';
MyPortfolio = {'SPY' 'SPYV' 'SPYG' 'BABA' 'BRK-B' 'AGG' 'COST' 'WMT'...
    'PGR' 'XLU' 'XLP' 'TCEHY' 'VTEB' 'VEA' 'KR' 'JD' 'DAL' 'AAPL'};
Weight = [8 3 11 4 6 2 1 2 3 2 2 5 3 1 1 1 2 1];
AveCost = [311.72 30.2 36.70 179.07 203.66 111.21 298.16 132.33 85.85 ...
    63.94 62.18 61.81 54.42 43.73 31.94 60.50 27.74 385.68];

Quantity = length(MyPortfolio);

% Set the benchmark
symbol = Bench;
BenchRaw = getMarketDataViaYahoo(symbol, initDate,endDate);
BenchHist_CloseAdj = table2array(BenchRaw(:,6));
BenchHist_Close = table2array(BenchRaw(:,5));
TDays = size(BenchHist_CloseAdj,1);
PortHist_CloseAdj = zeros(size(BenchHist_CloseAdj,1),Quantity);
PortHist_Close = zeros(size(BenchHist_CloseAdj,1),Quantity);

Timeline = datetime(table2array(BenchRaw(:,1)));
Timeline.Format = 'dd/MM/yyyy';
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


% Proposed New Portfolio
PropSelection = {'AAPL' 'JD' 'DAL' 'MCD' 'DG' 'KR' 'COST' 'TCEHY' 'PGR' ...
    'NUSI' 'KO' 'JNJ'};
PropQuantity = length(PropSelection);
PropPortHist_Close = zeros(TDays,PropQuantity);
PropPortHist_Close_Adj = zeros(TDays,PropQuantity);

for i = 1:PropQuantity
    symbol = PropSelection{i};
    prop = getMarketDataViaYahoo(symbol, initDate,endDate);
    PropPortHist_Close(:,i) = table2array(prop(:,5));
    PropPortHist_Close_Adj(:,i) = table2array(prop(:,6));
end


PropWeight = [2 1 5 3 5 20 3 4 5 3 10 3];
PropPortfolio = sum((PropWeight .* PropPortHist_Close),2);

% Why divide by mean? Because it is unrealistic to assume that I could have
% picked these stocks at 'initDate'. But it is relatively reasonable to
% assume I can make my cost at the average level of a certain period of
% time. 
PropPortfolio_Neutralized = PropPortfolio ./ PropPortfolio(1);


% Create Line Chart 
figure
plot(Timeline,PaperPortfolio_Neutralized);
hold on
plot(Timeline,PropPortfolio_Neutralized);
Figure1 = plot(Timeline, Benchmark_Neutralized,'-.');
hold off
title('Paper Portfolio vs Benchmark')
ylabel('Relative Price Change')
legend('Holding Portfolio','Proposed Portfolio','Benchmark',...
    'Location','southeast')


[DailyPaperReturn,DailyBenchReturn,DailyPropReturn] = deal(zeros(TDays -1,1));

% Calculate the return of my Holding. This not include the income
for i = 2:TDays
    
    DailyPaperReturn(i-1) = log(PaperPortfolio(i,:) ...
        ./ PaperPortfolio(i-1,:));
    DailyBenchReturn(i-1) = log(BenchHist_Close(i,:) ...
        ./ BenchHist_Close(i-1, :));
    DailyPropReturn(i-1) = log(PropPortfolio(i,:)...
        ./ PropPortfolio(i-1,:));
end

Rf = 0.01/360;
options = optimset('Display','iter');
% InitialWeight = ones(1,PropQuantity);
InitialWeight = PropWeight;
OptWeight = fminsearch(@MaxSharpeRatio,InitialWeight,options,PropPortHist_Close,Rf);
OptWeight = round(OptWeight);


OptPortfolio = sum((OptWeight .* PropPortHist_Close),2);
% Why divide by mean? Because it is unrealistic to assume that I could have
% picked these stocks at 'initDate'. But it is relatively reasonable to
% assume I can make my cost at the average level of a certain period of
% time. 
OptPortfolio_Neutralized = OptPortfolio ./ OptPortfolio(1);

% Display on Chart
figure
plot(Timeline,OptPortfolio_Neutralized);
hold on
plot(Timeline,PropPortfolio_Neutralized);
Figure2 = plot(Timeline,Benchmark_Neutralized,'-.');
hold off
title('Optimized Portfolio vs Proposed Portfolio')
ylabel('Relative Price Change')
legend('Optimized Portfolio','Proposed Portfolio','Benchmark',...
    'Location','southeast')
WeightComparison = table(PropSelection', PropWeight', OptWeight',...
    'VariableNames',{'Stock','ProposedWeight','OptimizedWeight'});
disp(WeightComparison);

% Only pick stocks that are not weighted 0
OptShares = OptWeight(OptWeight >0);
OptSelection = PropSelection(OptWeight>0);
OptHist_Close_Adj = PropPortHist_Close_Adj(:,(OptWeight>0));


% Manage the portfolio in the table
HisPrice = [BenchHist_CloseAdj OptHist_Close_Adj];
HisPrice_T = array2table(HisPrice, 'VariableNames',...
    ['SP500' string(OptSelection)]);
Timeline_Str = string(Timeline);
% HisPrice_T = table(HisPrice_T,'RowNames',Timeline_Str);
Timeline_T = table(Timeline,'VariableNames',{'DATA'});
HisPrice_T = [Timeline_T HisPrice_T];

% Create Return Table
HisReturn = zeros(TDays -1,length(OptSelection) + 1);
for i = 2:TDays
    HisReturn(i-1,:) = log(HisPrice(i,:) ./ HisPrice(i-1,:));
end
Timeline_R = Timeline_T.DATA(2:end);
HisReturn_R = array2table(HisReturn, 'VariableNames',...
    ['SP500' string(OptSelection)]);
Exp_Return = mean(HisReturn_R{:,:},1);
Vol_Return = std(HisReturn_R{:,:},1);
SharpeRatio = (Exp_Return - Rf) ./ Vol_Return;
Summary_T = array2table([Exp_Return;Vol_Return;SharpeRatio],'VariableNames',...
    ['SP500' string(OptSelection)]);
OptShares_T = array2table([0 OptShares],'VariableNames',...
    ['SP500' string(OptSelection)]);
Summary_T = [OptShares_T; Summary_T];
Summary_T.Properties.RowNames = {'#Shares','Exp_Return','Vol_Return',...
    'SharpeRatio'};

disp(Summary_T);