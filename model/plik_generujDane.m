clear;clc;
%--------------------------------------------------------------------------
%Rozkłady stref w budynku
%Kierunki przyjęte:
%
%      N
%    W-|-E
%      S
%
matrix1 = [1 1 1 1 1 1 1 1 1 1;
           1 1 1 1 1 1 1 1 1 1;
           1 1 1 1 1 1 1 1 1 1;
           1 1 1 3 3 3 3 3 3 3;
           2 2 2 3 3 3 3 3 3 3;
           2 2 2 3 3 3 3 3 3 3;
           2 2 2 2 2 -1 -1 -1 -1 -1;
           2 2 2 2 2 -1 -1 -1 -1 -1;
           2 2 2 2 2 -1 -1 -1 -1 -1;
           2 2 2 2 2 -1 -1 -1 -1 -1];

matrix2 = [1 1 1 1 1 1 1 1 1 1;
           1 1 1 1 1 1 1 1 1 1;
           1 1 1 1 1 1 1 1 1 1;
           1 1 1 1 1 1 1 1 1 1;
           2 2 2 2 2 2 2 2 2 2;
           2 2 2 2 2 2 2 2 2 2;
           2 2 2 2 2 -1 -1 -1 -1 -1;
           2 2 2 2 2 -1 -1 -1 -1 -1;
           2 2 2 2 2 -1 -1 -1 -1 -1;
           2 2 2 2 2 -1 -1 -1 -1 -1];

matrix3 = [1 1 1 1 1 1 1 1 1 1;
           1 1 1 1 1 1 1 1 1 1;
           1 1 1 1 1 1 1 1 1 1;
           1 1 1 1 1 1 1 1 1 1;
           1 1 1 1 1 1 1 1 1 1;
           1 1 1 1 1 1 1 1 1 1;
           1 1 1 1 1 -1 -1 -1 -1 -1;
           1 1 1 1 1 -1 -1 -1 -1 -1;
           1 1 1 1 1 -1 -1 -1 -1 -1;
           1 1 1 1 1 -1 -1 -1 -1 -1];

matrixTable = table(matrix1,matrix2);

%Wysokość pięter
H = 2.5;
heightTable = table(H,H);

%Konfiguracja ocieplenia budynku
materialThickness = [0.0125 0.25 0.0125 0.007]; materialDensity = [1250 160 1250 40]; materialSpecificHeat = [1100 750 1100 1460]; materialThermalCoeff = [0.32 0.045 0.32 0.045];
insulationExternal = [materialThickness;materialDensity;materialSpecificHeat;materialThermalCoeff];

materialThickness = [0.0125 0.25 0.0125 0.007]; materialDensity = [1250 160 1250 40]; materialSpecificHeat = [1100 750 1100 1460]; materialThermalCoeff = [0.32 0.045 0.32 0.045];
insulationInternal = [materialThickness;materialDensity;materialSpecificHeat;materialThermalCoeff];

materialThickness = [0.005 0.0125]; materialDensity = [2000 2100]; materialSpecificHeat = [1280 840]; materialThermalCoeff = [0.25 1.4];
insulationFloor = [materialThickness;materialDensity;materialSpecificHeat;materialThermalCoeff];

materialThickness = [0.0125 0.25 0.0125 0.05]; materialDensity = [1250 1.204 1250 40]; materialSpecificHeat = [1100 1012 1100 1460]; materialThermalCoeff = [0.32 0.026 0.32 0.045];
insulationCeiling = [materialThickness;materialDensity;materialSpecificHeat;materialThermalCoeff];

materialThickness = [0.0125 0.25 0.05]; materialDensity = [1250 160 32]; materialSpecificHeat = [1100 750 1400]; materialThermalCoeff = [0.32 0.045 0.022];
insulationRoof = [materialThickness;materialDensity;materialSpecificHeat;materialThermalCoeff];

materialThickness = [0.2 0.2]; materialDensity = [40 2400]; materialSpecificHeat = [1460 880]; materialThermalCoeff = [0.045 1.7];
insulationGround = [materialThickness;materialDensity;materialSpecificHeat;materialThermalCoeff];

insulationTable = table(insulationExternal, insulationInternal, insulationFloor, insulationCeiling, insulationRoof, insulationGround);

%Konfiguracja pomieszczeń (okna, liczba okien w pomieszczeniu, średnica rur, grubość rur, rozstaw rur, przepływ [l/min])
floor1Equipment = [1 0 1; % ile okien północnych
                   0 1 0; % ile okien południowych
                   0 0 1; % ile okien wschodnich
                   1 1 0; % ile okien zachodnich
                   0.016 0.016 0.016; % średnica rur (zewnętrzna)
                   0.002 0.002 0.002; % grubość ścianki
                   0.15 0.15 0.15; % rozstaw rur
                   4 3 3]; % przepływ wody [l/min]
floor2Equipment = [0 0; % ile okien północnych
                   0 1 % ile okien południowych
                   1 0 % ile okien wschodnich
                   1 1; % ile okien zachodnich
                   0.02 0.02; % średnica rur (zewnętrzna)
                   0.002 0.002; % grubość ścianki
                   0.15 0.15; % rozstaw rur
                   5 5]; % przepływ wody [l/min]
floor3Equipment = [0 0 0; % ile okien północnych
                   0 0 0; % ile okien południowych
                   0 0 0; % ile okien wschodnich
                   0 0 0; % ile okien zachodnich
                   0.016 0.016 0.02; % średnica rur (zewnętrzna)
                   0.002 0.002 0.002; % grubość ścianki
                   0.2 0.2 0.2; % rozstaw rur
                   3 3 3]; % przepływ wody [l/min]];

floor4Equipment = [1;
                   1;
                   2;
                   2;
                   0.016;
                   0.002;
                   0.2;
                   10];

roomEquipment = table(floor1Equipment,floor2Equipment);

%Stałe parametry
scale = 1.2; %skala siatki macierzy [1]
h1 = 3; %Convective Heat Transfer Coefficient [W/m2K] dla powietrza wewnątrz budynku [2]
h2 = 20; %Convective Heat Transfer Coefficient [W/m2K] dla powietrza zewnętrznego (wiatr) [3]
roofAngle = 0; %kąt nachylenia dachu [°] [4]
Awin = 1.43*0.865; %powierzchnia okna [m^2] [5]
Uwin = 0.9; %przenikalność cieplna okna [W/m2K] [6]
SHGC = 0.4; %Solar Heat Gain Coefficient [7]
alpha_floor = 0.7; %współczynnik absorpcji światła przez podłogę (brązowe panele winylowe) [8]
cw = 4180; % ciepło właściwe wody [9]
dw = 980; % gęstość wody [10]
kw = 0.624; % przewodność cieplna wody [11]
u = 0.000547; % lepkość wody [12]
cp = 1005; % ciepło właściwe powietrza [13]
dp = 1.1204; % gęstość powietrza [14]
k_tube = 0.35; %współczynnik przewodzenia rur (PEX) [15]
V_buf = 0.1; %objętość zbiornika buforowego [m^3] [16]
COP = 4; %współczynnik sprawności pompy ciepła [17]
area_buf = 2*pi*((V_buf/(4*pi))^(1/3))^2 + 2*pi*((V_buf/(4*pi))^(1/3))*4*(V_buf/(4*pi))^(1/3); %powierzchnia styku bufor - temperatura na zewnątrz [18]
U_buf = 0.531; %współczynnik przenikania cieplnego zbiornika [19]
coefficients = [scale h1 h2 roofAngle Awin Uwin SHGC alpha_floor cw dw kw u cp dp k_tube V_buf COP area_buf U_buf];

[Am,Bm,Cm,Dm,Zm,N,exWalls,roofSt,vecUnheatedFloors] = generateBuilding(matrixTable,heightTable,insulationTable,coefficients,roomEquipment);
nx = size(Am,1); nu = size(Bm,2); ny = size(Cm,1); nz = size(Zm,2);
[A,B,C,D,Z] = mergePumpBuilding(Am,Bm,Cm,Dm,Zm,N,vecUnheatedFloors,roomEquipment,coefficients);

%Dyskretyzacja modelu
Ts = 1200;
sys = ss(A,[B Z],C,D);
sysd = c2d(sys,Ts,'zoh');
[Ad,Bd,Cd,Dd] = ssdata(sysd);
Zd = Bd(:, size(B,2)+1:end);
Bd = Bd(:, 1:size(B, 2));

%--------------------------------------------------------------------------
%%
%Parametry strojenia regulatora
nc = 48; npred = 72; na = 72;
time = 3600*24; %czas symulacji [s]
w_PumpCost = 0.01; %współczynnik kosztów cen energii
Q = 2000*(C'*C); Q(end,end) = 125;
R = 0.5*eye(size(B,2)); R(end,end) = 0.01;

%Trajektorie referencyjne i zakłóceń (ENEA Taryfa G12 w 2025 r.)
trajPrice = [
    0.4056, 0.4056, 0.4056, 0.4056, 0.4056, 0.4056, ... % godz. 00:00–06:00 (nocna)
    0.7506, 0.7506, 0.7506, 0.7506, 0.7506, 0.7506, ... % godz. 06:00–12:00 (dzienna)
    0.7506, 0.7506, 0.7506, 0.7506, 0.7506, 0.7506, ... % godz. 12:00–18:00 (dzienna)
    0.7506, 0.7506, 0.7506, 0.7506 ...                  % godz. 18:00–22:00 (dzienna)
    0.4056, 0.4056                                      % godz. 22:00–24:00 (nocna)
];
priceCost = trajPrice;
% priceCost = [priceCost priceCost priceCost priceCost priceCost priceCost priceCost];
[priceCost,~,~] = generateTrajectory(priceCost,1,time,Ts,na,1);
trajPrice = trajPrice - min(trajPrice);
trajPrice = trajPrice/max(trajPrice); %normalizacja względem maksymalnej ceny <0-1>

trajRef = [21 21;
           21 21;
           21 21;
           21 21;
           21 21;
           50 50];

trajDist = [-7.5 -5.5 -4.25 -4.5 -5.0 -4.5 -4.0 -3.0 -1.0 1.0 3.0 4.0 5.0 4.5 4.0 3.0 2.0 1.0 0.0 -1.0 -2.0 -2.5 -3.0 -3.5;
           0 0 0 0 0 0 0 2 5 8 10 12 10 8 5 2 1 0 0 0 0 0 0 0;
           0 0 0 0 5 20 50 90 140 190 230 260 230 190 140 90 50 20 5 0 0 0 0 0;
           0 0 0 5 20 60 120 180 160 100 40 10 2 0 0 0 0 0 0 0 0 0 0 0;
           0 0 0 0 0 0 0 2 10 30 70 130 180 200 160 100 50 20 5 0 0 0 0 0;
           10.07 10.04 10.00 9.96 9.93 9.96 10.00 10.07 10.15 10.23 10.30 10.35 10.40 10.38 10.35 10.30 10.25 10.23 10.20 10.15 10.10 10.06 10.04 10.02];
trajDist = [trajDist;zeros(nz-size(trajDist,1),size(trajDist,2))];

% trajPrice = [trajPrice trajPrice trajPrice trajPrice trajPrice trajPrice trajPrice];
% trajRef = [trajRef trajRef trajRef trajRef trajRef trajRef trajRef];
% trajDist = [trajDist trajDist trajDist trajDist trajDist trajDist trajDist];
%--------------------------------------------------------------------------
%%
%Ograniczenia oraz warunki początkowe
Ta0 = 20; %temperatura sekcji
Tzi0 = 20; Tzo0 = 5; %temperatury wewnętrzna/zewnętrza ściany zewnętrznej
Twi0 = 20; Two0 = 20; %temperatury wewnętrzna/zewnętrza ściany wewnętrznej
Tp0 = 20; %temperatura podłogi
T_return0 = 22;

Ta_max = 21.5; Ta_min = 19.5; %ograniczenia temp. pomieszczen
Twall_max = 100; Twall_min = -100; %ograniczenia temp. scian
Tp_max = 27; Tp_min = 18; %ograniczenia temp. podlogi
T_return_max = 35; T_return_min = 20;

statesInit = [Ta0, Tzi0, Tzo0, Twi0, Two0, Tp0, T_return0];
statesConstr = [Ta_max, Ta_min, Twall_max, Twall_min, Tp_max, Tp_min, T_return_max, T_return_min];

%Ograniczenia i war. początkowe dla budynku
[x0,xmax,xmin] = initialStates(nx,statesInit,statesConstr,N,exWalls,roofSt,vecUnheatedFloors);
umax = 40*ones(nu,1);
umin = T_return_min*ones(nu,1);
xmax = xmax';
xmin = xmin';
ymax = Ta_max*ones(ny,1);
ymin = Ta_min*ones(ny,1);

%Ograniczenia i war. początkowe dla pompy
T_buf = 49.5; T_bufMAX = 52.5; T_bufMIN = 47.5;
P_MAX = 3000; P_MIN = 0;
x0 = [x0;T_buf];
xmax = [xmax; T_bufMAX];
xmin = [xmin; T_bufMIN];
umax = [umax; P_MAX];
umin = [umin; P_MIN];
ymax = [ymax; T_bufMAX];
ymin = [ymin; T_bufMIN];

%--------------------------------------------------------------------------
%%
%Wygeneruj dane do regulatora
[K,Sx,Sxc,Sxr,Sc,Sr,Scr] = ompc_cost(Ad,Bd,Cd,Q,R,nc,na);

%--------------------------------------------------------------------------
%%
%Obserwator zakłóceń oraz stanów (ESO)

%Wyznacz macierz pomiarową C dla budynku
C_measured = create_Cobserver_matrix(Cm, N, vecUnheatedFloors); % Macierz C stanów mierzonych

%Wyznacz macierz pomiarową C dla układu pompy
C_measured = [C_measured; zeros(1, size(C_measured,2))];
C_measured = [C_measured zeros(size(C_measured,1),1)];
C_measured(end,end) = 1;

Z_known = Zd(:,1:6);
Z_unknown = Zd(:,7:end);
n_states = size(Ad, 1);
n_disturbances = size(Z_unknown, 2);
A_bar = [Ad, Z_unknown; zeros(n_disturbances, n_states), zeros(n_disturbances)];
B_bar = [Bd; zeros(n_disturbances, size(Bd, 2))];
Z_bar_known = [Z_known; zeros(n_disturbances, size(Z_known, 2))];
C_bar = [C_measured, zeros(size(C_measured, 1), n_disturbances)];
L = dlqr(A_bar', C_bar', 100*eye(size(A_bar,1)), 1e-5*eye(size(C_measured,1))); L = L';

%--------------------------------------------------------------------------
%%
%Stwórz macierz Kz (macierz odpowiedzi impulsowej układu)
Kz = create_Kz_matrix(Ad, Cd, Zd, na);

%--------------------------------------------------------------------------
%%
%Zaktualizuj do aktualnych wymiarów dla symulacji
nx = size(A,1); nu = size(B,2); ny = size(C,1); nz = size(Z,2);

%Wyznacz wektor wskazujący na indeksy powracającej wody
zoneWaterIndex = [];
for i = 2:size(N,2)
    if vecUnheatedFloors(i-1) == 0
        zoneWaterIndex = [zoneWaterIndex N(i) - N(i-1)];
    end
end
if vecUnheatedFloors(end) == 0
    zoneWaterIndex = [zoneWaterIndex size(A,1)-1];
end
