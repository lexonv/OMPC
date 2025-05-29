clc;clear; close all;


set(groot, 'DefaultAxesFontSize', 16);       % :contentReference[oaicite:0]{index=0}
set(groot, 'DefaultTextFontSize', 16);       % :contentReference[oaicite:1]{index=1}
set(groot, 'DefaultLegendFontSize', 16);     % :contentReference[oaicite:2]{index=2}

data1 = load('sim11.mat');
data2 = load('sim12.mat');
data3 = load('sim13.mat');

timeRAW = data1.out.tout; time = timeRAW'; time = time / 3600;

dataRef = load('trajRef1.mat');
trajRef = dataRef.trajRef;
[trajRef,~,~] = generateTrajectory(trajRef,1,timeRAW(end),1200,1,1);

ctrl1 = data1.out.ctrl;
ctrl2 = data2.out.ctrl;
ctrl3 = data3.out.ctrl;

output1 = data1.out.output;
output2 = data2.out.output;
output3 = data3.out.output;

u1 = reorder(ctrl1, 2);
u2 = reorder(ctrl2, 4);
u3 = reorder(ctrl3, 6);

y1 = output1';
y2 = output2';
y3 = output3';

%Wybierz strefę:
zone = 3;

zonesLegend = "Temp. powietrza w strefie B" + (1:3) + "-S" + zone;
zonesS4S5Legend = ["Temp. powietrza w strefie B3-S4" "Temp. powietrza w strefie B3-S5"];
valvesLegend = "Temp. zasilania strefy B" + (1:3) + "-S" + zone;
valvesS4S5Legend = ["Temp. zasilania strefy B3-S4" "Temp. zasilania strefy B3-S5"];
buforLegend = "Temp. wody w zbiorniku buforowym budynku B" + (1:3);
pumpLegend = "Moc pompy ciepła budynku B" + (1:3);
%--------------------------------------------------------------------------

% figure;
% plot(time,y1(zone,:), 'LineWidth', 1.5)
% hold on;
% plot(time,y2(zone,:), 'LineWidth', 1.5)
% plot(time,y3(zone,:), 'LineWidth', 1.5)
% stairs(time,trajRef(zone,:),'LineStyle','--','LineWidth', 1.5,'Color',"black")
% hold off;
% title("Przebiegi zmian temperatur powietrza w strefach S" + zone + " budynków B1, B2, B3")
% xlabel("Godzina [h]")
% ylabel("Temperatura [°C]")
% ylim([20.25,21.4])
% xlim([0,time(end)])
% legend([zonesLegend, "Trajektoria referencyjna"])
% grid on;
% xticks(0:1:24);
% xticklabels(arrayfun(@(h) sprintf('%02d:00',h), 0:24, 'UniformOutput',false));
% xtickangle(45);

figure;
plot(time,y3(4,:), 'LineWidth', 1.5)
hold on;
plot(time,y3(5,:), 'LineWidth', 1.5)
stairs(time,trajRef(4,:),'LineStyle','--','LineWidth', 1.5, 'Color', "blue")
stairs(time,trajRef(5,:),'LineStyle','--','LineWidth', 1.5, 'Color', "red")
hold off;
title("Przebiegi zmian temperatur powietrza w strefach S4 i S5")
xlabel("Godzina [h]")
ylabel("Temperatura [°C]")
ylim([20.4,21.4])
xlim([0,time(end)])
legend([zonesS4S5Legend, "Trajektoria referencyjna S4", "Trajektoria referencyjna S5"])
grid on;
xticks(0:1:24);
xticklabels(arrayfun(@(h) sprintf('%02d:00',h), 0:24, 'UniformOutput',false));
xtickangle(45);
%--------------------------------------------------------------------------

% figure;
% stairs(time,u1(1,:), 'LineWidth', 1.5)
% hold on;
% stairs(time,u2(zone,:), 'LineWidth', 1.5)
% stairs(time,u3(zone,:), 'LineWidth', 1.5)
% hold off;
% title("Przebiegi zmian temperatury wody wprowadzanych do obiegów grzewczych S" + zone + " budynków B1, B2, B3")
% xlabel("Godzina [h]")
% ylabel("Temperatura [°C]")
% legend(valvesLegend)
% ylim([19,40])
% xlim([0,time(end)])
% grid on;
% xticks(0:1:24);
% xticklabels(arrayfun(@(h) sprintf('%02d:00',h), 0:24, 'UniformOutput',false));
% xtickangle(45);

% figure;
% stairs(time,u3(4,:), 'LineWidth', 1.5)
% hold on;
% stairs(time,u3(5,:), 'LineWidth', 1.5)
% hold off;
% title("Przebiegi zmian temperatury wody wprowadzanych do obiegów grzewczych S4, S5 w budynku B3")
% xlabel("Godzina [h]")
% ylabel("Temperatura [°C]")
% ylim([21,31])
% xlim([0,time(end)])
% legend(valvesS4S5Legend)
% grid on;
% xticks(0:1:24);
% xticklabels(arrayfun(@(h) sprintf('%02d:00',h), 0:24, 'UniformOutput',false));
% xtickangle(45);
%--------------------------------------------------------------------------

% figure;
% plot(time,y1(end,:), 'LineWidth', 1.5)
% hold on;
% plot(time,y2(end,:), 'LineWidth', 1.5)
% plot(time,y3(end,:), 'LineWidth', 1.5)
% stairs(time,trajRef(end,:),'LineStyle','--','LineWidth', 1.5,'Color',"black")
% hold off;
% title("Przebiegi zmian temperatury wody w zbiornikach buforowych budynków B1, B2, B3")
% xlabel("Godzina [h]")
% ylabel("Temperatura [°C]")
% ylim([48,52])
% xlim([0,time(end)])
% legend(buforLegend)
% grid on;
% xticks(0:1:24);
% xticklabels(arrayfun(@(h) sprintf('%02d:00',h), 0:24, 'UniformOutput',false));
% xtickangle(45);
%--------------------------------------------------------------------------

% figure;
% plot(time,u1(end,:), 'LineWidth', 1.5)
% hold on;
% plot(time,u2(end,:), 'LineWidth', 1.5)
% plot(time,u3(end,:), 'LineWidth', 1.5)
% hold off;
% title("Przebiegi zmian mocy elektrycznej pompy ciepła w budynkach B1, B2, B3")
% xlabel("Godzina [h]")
% ylabel("Moc [W]")
% legend(pumpLegend)
% xlim([0,time(end)])
% grid on;
% xticks(0:1:24);
% xticklabels(arrayfun(@(h) sprintf('%02d:00',h), 0:24, 'UniformOutput',false));
% xtickangle(45);
%--------------------------------------------------------------------------

IAE1 = zeros(3,1);
IAE2 = zeros(3,1);
IAE3 = zeros(5,1);

for i = 1:size(time,2)
    IAE1 = IAE1 + abs(trajRef(1:3,i) - y1(1:3,i));
    IAE2 = IAE2 + abs(trajRef(1:3,i) - y2(1:3,i));
    IAE3 = IAE3 + abs(trajRef(1:5,i) - y3(1:5,i));
end

disp("=== Współczynnik IAE dla budynku B1 ===")
disp(IAE1')
disp("=== Współczynnik IAE dla budynku B2 ===")
disp(IAE2')
disp("=== Współczynnik IAE dla budynku B3 ===")
disp(IAE3')

%--------------------------------------------------------------------------

function u = reorder(ctrl, Nctrl)
    u = [];
    uTEMP = [];
    for i = 1:size(ctrl,1)/Nctrl
        for j = 1:Nctrl
            uTEMP = [uTEMP; ctrl(j + (i-1)*Nctrl)]; 
        end
        u = [u uTEMP];
        uTEMP = [];
    end
end