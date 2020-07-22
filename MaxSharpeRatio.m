function SharpeRatio = MaxSharpeRatio(Weight, Hist_Close, Rf)
    Weight = abs(Weight);
    PaperPortfolio = sum((Weight .* Hist_Close),2);

    TDays = size(PaperPortfolio,1);
    DailyReturn = zeros(TDays -1,1);
    
    for i = 2:TDays
        DailyReturn(i-1) = log(PaperPortfolio(i,:) ...
            ./ PaperPortfolio(i-1,:));
    end
    
    AveReturn = mean(DailyReturn);
    Volatility = std(DailyReturn);
    
    if min(Weight) >= 1 && max(Weight) <= 30
        SharpeRatio = -((AveReturn-Rf)/Volatility);
    else
        SharpeRatio = 100;
    end
    