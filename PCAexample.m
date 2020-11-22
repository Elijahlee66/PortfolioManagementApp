load ovariancancer;
[U,S,V] = svd(obs,'econ');

figure 
subplot(1,2,1)
semilogy(diag(S),'k-o','LineWidth',2.0)
set(gca,'FontSize',15),axis tight, grid on
subplot(1,2,2)
plot(cumsum(diag(S))./sum(diag(S)),'k-o','LineWidth',2.0)
set(gca,'FontSize',15),axis tight, grid on
% set(gcf,'Position',[1400 100 3*600 3*250])

for i = size(obs,1)
    x = V(:,1)'*
