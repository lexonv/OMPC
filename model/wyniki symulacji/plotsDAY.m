clear;clc; close all;

%wczytaj dane
data = load('sym13.mat');

%odczytaj dane z Simulinka
ctrl = data.out.ctrl;
output = data.out.output;
time = data.out.tout;
time = time';
time_h = time / 3600; % [s] -> [h]

%liczba wejść/wyjść
N = size(ctrl,1)/numel(time);

%odczytaj wektor zakłóceń (format 24 godzin)
data = load('trajDist.mat');
trajDist = data.trajDist;
[trajDist, ~, ~] = generateTrajectory(trajDist,2,time(end),1200,1,1);
trajRefVALVES = 21*ones(N-1,24);
[trajRefVALVES, ~, ~] = generateTrajectory(trajRefVALVES,1,time(end),1200,1,1);
trajRefPUMP = 50*size(1,24);
[trajRefPUMP, ~, ~] = generateTrajectory(trajRefPUMP,1,time(end),1200,1,1);


%rozdziel wektor wejść i wyjść na N wierszy
u = [];
uTEMP = [];
y = [];
yTEMP = [];
for i = 1:size(ctrl,1)/N
    for j = 1:N
        uTEMP = [uTEMP; ctrl(j + (i-1)*N)]; 
        yTEMP = [yTEMP; output(j + (i-1)*N)];
    end
    u = [u uTEMP];
    uTEMP = [];
    y = [y yTEMP];
    yTEMP = [];
end

%%

zonesLegend = "Strefa grzewcza nr " + (1:N-1);
valvesLegend = "Temp. wyjściowa z zaworu nr " + (1:N-1);
intensityLegend = ["Natężenie promieniowania od strony północnej","Natężenie promieniowania od strony południowej", "Natężenie promieniowania od strony wschodniej", "Natężenie promieniowania od strony zachodniej"];
outdoorLegend = ["Temperatura na zewnątrz budynku", "Temperatura gruntu/fundamentów"];

set(groot, 'DefaultAxesFontSize', 16);       % :contentReference[oaicite:0]{index=0}
set(groot, 'DefaultTextFontSize', 16);       % :contentReference[oaicite:1]{index=1}
set(groot, 'DefaultLegendFontSize', 16);     % :contentReference[oaicite:2]{index=2}

figure;
plot(time_h,y(1:N-1,:), 'LineWidth', 1.2)
hold on;
plot(time_h,trajRefVALVES,'LineStyle','--')
hold off;
title("Przebieg temperatury powietrza w strefach grzewczych")
xlabel("Godzina [h]")
ylabel("Temperatura [°C]")
legend([zonesLegend, "Trajektoria zadana temperatury"])
grid on;
xticks(0:1:24);
xticklabels(arrayfun(@(h) sprintf('%02d:00',h), 0:24, 'UniformOutput',false));
xtickangle(45);

figure;
plot(time_h,y(N,:), 'LineWidth', 1.2)
hold on;
plot(time_h,trajRefPUMP,'LineStyle','--')
hold off;
title("Przebieg temperatury wody w zbiorniku buforowym")
xlabel("Godzina [h]")
ylabel("Temperatura [°C]")
legend("Temperatura wody w zbiorniku buforowym", "Trajektoria zadana temperatury")
grid on;
xticks(0:1:24);
xticklabels(arrayfun(@(h) sprintf('%02d:00',h), 0:24, 'UniformOutput',false));
xtickangle(45);

figure;
plot(time_h,u(1:N-1,:), 'LineWidth', 1.2)
title("Przebieg zmian temperatury wody wprowadzanej do obiegów grzewczych")
xlabel("Godzina [h]")
ylabel("Temperatura [°C]")
legend(valvesLegend)
grid on;
xticks(0:1:24);
xticklabels(arrayfun(@(h) sprintf('%02d:00',h), 0:24, 'UniformOutput',false));
xtickangle(45);

figure;
plot(time_h,u(N,:), 'LineWidth', 1.2)
title("Przebieg zmian mocy pompy ciepła")
xlabel("Godzina [h]")
ylabel("Moc [W]")
legend("Moc pompy ciepła")
grid on;
xticks(0:1:24);
xticklabels(arrayfun(@(h) sprintf('%02d:00',h), 0:24, 'UniformOutput',false));
xtickangle(45);

%%

% figure;
% plot(time_h,trajDist(2:5,:), 'LineWidth', 1.2)
% title("Przebieg zmian natężenia słonecznego w ciągu dnia")
% xlabel("Godzina [h]")
% ylabel("Natężenie promieniowania słonecznego [W/m^2]")
% legend(intensityLegend)
% grid on;
% xticks(0:1:24);
% xticklabels(arrayfun(@(h) sprintf('%02d:00',h), 0:24, 'UniformOutput',false));
% xtickangle(45);

% figure;
% plot(time_h,trajDist(1,:),time_h,trajDist(6,:), 'LineWidth', 1.2)
% title("Przebieg zmian temperatur powietrza na zewnątrz oraz gruntu w ciągu dnia")
% xlabel("Godzina [h]")
% ylabel("Temperatura [°C]")
% legend(outdoorLegend)
% grid on;
% xticks(0:1:24);
% xticklabels(arrayfun(@(h) sprintf('%02d:00',h), 0:24, 'UniformOutput',false));
% xtickangle(45);

%%
%Oblicz współczynnik ISE
ISE = zeros(N-1,1);
for i = 1:size(y,2)
    ISE = ISE + (trajRefVALVES(:,i) - y(1:end-1,i)).^2;
end

