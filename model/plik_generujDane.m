clear;clc;
%--------------------------------------------------------------------------
% stałe parametry
scale = 1; %skala siatki macierzy
h1 = 3; %Convective Heat Transfer Coefficient [W/m2K] dla powietrza wewnątrz budynku
h2 = 20; %Convective Heat Transfer Coefficient [W/m2K] dla powietrza zewnętrznego (wiatr)
roofAngle = 0; %kąt nachylenia dachu [°]
Awin = 1.43*0.865; %powierzchnia okna [m^2]
Uwin = 0.95; %przenikalność cieplna okna [W/m2K]
SC = 1; %współczynnik zacienienia okna <1 - niezacienione>
alpha_wall = 0.3; %współczynnik absorpcji światła przez ściany (zależny od koloru)
alpha_floor = 0.5; %współczynnik absorpcji światła przez podłogę (brązowe panele winylowe)
cw = 4180; % ciepło właściwe wody
dw = 980; % gęstość wody
kw = 0.624; % przewodność cieplna wody
u = 0.000547; % lepkość wody
cp = 1005; % ciepło właściwe powietrza
dp = 1.1204; % gęstość powietrza
k_tube = 0.35; %współczynnik przewodzenia rur (PEX)
V_buf = 0.5; %objętość zbiornika buforowego
COP = 4; %współczynnik sprawności 
area_buf = 2 * pi * ((V_buf / (4 * pi))^(1/3))^2 + 2 * pi * ((V_buf / (4 * pi))^(1/3)) * 4 * (V_buf / (4 * pi))^(1/3); %powierzchnia styku bufor - temperatura na zewnątrz
U = 0.644; %współczynnik przenikania cieplnego zbiornika
coefficients = [scale h1 h2 roofAngle Awin Uwin 0 SC alpha_wall alpha_floor 0 cw dw kw u cp dp k_tube V_buf COP area_buf U];

% rozkład sekcji w budynku
matrix1 = [ones(10,5) 2*ones(10,5)];

matrix2 = [1 1 1 1 0 0 0 0 0 0; 
           1 1 1 1 0 0 0 0 0 0;
           1 1 1 1 0 0 0 0 2 2;
           1 1 1 1 2 2 2 2 2 2;
           1 1 1 1 2 2 2 2 2 2;
           1 1 4 4 4 2 2 2 2 2;
           4 4 4 4 4 2 2 2 2 2;
           4 4 4 4 4 2 2 2 2 2;
           4 4 4 4 4 2 2 2 2 2;
           4 4 4 4 4 2 2 2 2 2];

matrix3 = [1 1 1 1; 
           1 2 2 2; 
           2 2 2 2; 
           3 3 3 3];

matrixTable = table(matrix1,matrix1);

% wysokość pięter
H = 2.5;
heightTable = table(H,H);

% konfiguracja ocieplenia budynku
materialThickness = [0.07 0.0125 0.25 0.0125]; materialDensity = [50 1050 30 1050]; materialSpecificHeat = [1450 1200 1200 1200]; materialThermalCoeff = [0.035 0.45 0.045 0.45];
insulationExternal = [materialThickness;materialDensity;materialSpecificHeat;materialThermalCoeff];

materialThickness = [0.0125 0.05 0.0125]; materialDensity = [1050 700 1050]; materialSpecificHeat = [1200 1600 1200]; materialThermalCoeff = [0.45 0.15 0.45];
insulationInternal = [materialThickness;materialDensity;materialSpecificHeat;materialThermalCoeff];

materialThickness = [0.005 0.0125 ]; materialDensity = [1800 2000]; materialSpecificHeat = [1000 840]; materialThermalCoeff = [0.2 1.4];
insulationFloor = [materialThickness;materialDensity;materialSpecificHeat;materialThermalCoeff];

materialThickness = [0.05 0.0125 0.25 0.0125]; materialDensity = [30 1050 2500 1050]; materialSpecificHeat = [1500 1200 1000 1200]; materialThermalCoeff = [0.035 0.45 1.5 0.45];
insulationCeiling = [materialThickness;materialDensity;materialSpecificHeat;materialThermalCoeff];

materialThickness = [0.07 0.0125 0.25 0.0125]; materialDensity = [30 1050 30 1050]; materialSpecificHeat = [1500 1200 1200 1200]; materialThermalCoeff = [0.035 0.45 0.045 0.45];
insulationRoof = [materialThickness;materialDensity;materialSpecificHeat;materialThermalCoeff];

materialThickness = [0.1 0.2]; materialDensity = [50 2200]; materialSpecificHeat = [1450 1000]; materialThermalCoeff = [0.035 1.5];
insulationGround = [materialThickness;materialDensity;materialSpecificHeat;materialThermalCoeff];

insulationTable = table(insulationExternal, insulationInternal, insulationFloor, insulationCeiling, insulationRoof, insulationGround);

% konfiguracja pomieszczeń (okna, liczba okien w pomieszczeniu, średnica rur, grubość rur, rozstaw rur, przepływ [l/min])
floor1Equipment = [1 1; % Czy posiada okno
                   1 1; % ile okien
                   0.016 0.016; % średnica rur (zewnętrzna)
                   0.002 0.002; % grubość ścianki
                   0.2 0.2; % rozstaw rur
                   5 5]; % przepływ wody [l/min]
floor2Equipment = [1 1 1 0; % Czy posiada okno
                   1 1 1 0; % ile okien
                   0.016 0.016 0.016 0.016; % średnica rur (zewnętrzna)
                   0.002 0.002 0.002 0.002; % grubość ścianki
                   0.2 0.2 0.2 0.2; % rozstaw rur
                   3 3 3 3]; % przepływ wody [l/min]
floor3Equipment = [1 1 1; % Czy posiada okno
                   1 1 1; % ile okien
                   0.016 0.016 0.02; % średnica rur (zewnętrzna)
                   0.002 0.002 0.002; % grubość ścianki
                   0.2 0.2 0.2; % rozstaw rur
                   3 3 3]; % przepływ wody [l/min]];

roomEquipment = table(floor1Equipment,floor1Equipment);

[Am,Bm,Cm,Dm,Zm,N,exWalls,unheatedZones,roofSt] = generateBuilding(matrixTable,heightTable,insulationTable,coefficients,roomEquipment);
nx = size(Am,1); nu = size(Bm,2); ny = size(Cm,1); nz = size(Zm,2);
[A,B,C,D,Z] = mergePumpBuilding(Am,Bm,Cm,Dm,Zm,N,roomEquipment,coefficients);

%--------------------------------------------------------------------------
%%
%Parametry strojenia regulatora

%model dyskretny
Ts = 1320;
sys = ss(A,[B Z],C,D);
sysd = c2d(sys,Ts,'zoh');
[Ad,Bd,Cd,Dd] = ssdata(sysd);
Zd = Bd(:, size(B,2)+1:end);
Bd = Bd(:, 1:size(B, 2));

%parametry regulatora
nc = 64; npred = 108; na = 108;
time = 3600*24; %czas symulacji [s]
Q = 125*(C'*C); Q(end,end) = 1e-2;
R = 0.5*eye(size(B,2)); R(end,end) = 1e2;

%trajektorie referencyjne i zakłóceń
trajRef = [21 21;
           20.5 20.5;
           21 21;
           20.5 20.5;
           50 50];

trajDist = [-7.5 -5.5 -4.25 -4.5 -5.0 -4.5 -4.0 -3.0 -1.0 1.0 3.0 4.0 5.0 4.5 4.0 3.0 2.0 1.0 0.0 -1.0 -2.0 -2.5 -3.0 -3.5;
           0 0 0 0 0 0 5 20 55 170 230 300 380 340 310 225 120 50 10 0 0 0 0 0;
           10.07 10.04 10.00 9.96 9.93 9.96 10.00 10.07 10.15 10.23 10.30 10.35 10.40 10.38 10.35 10.30 10.25 10.23 10.20 10.15 10.10 10.06 10.04 10.02];
trajDist = [trajDist;zeros(nz-size(trajDist,1),size(trajDist,2))];

%--------------------------------------------------------------------------
%%
%Ograniczenia oraz warunki początkowe
Ta0 = 20; %temperatura sekcji
Tzi0 = 19.5; Tzo0 = 5; %temperatury wewnętrzna/zewnętrza ściany zewnętrznej
Twi0 = 19.5; Two0 = 19.5; %temperatury wewnętrzna/zewnętrza ściany wewnętrznej
Tp0 = 22; %temperatura podłogi
T_return0 = 25;

Ta_max = 25; Ta_min = 0; %ograniczenia temp. pomieszczen
Twall_max = 100; Twall_min = -100; %ograniczenia temp. scian
Tp_max = 27; Tp_min = 18; %ograniczenia temp. podlogi
T_return_max = 35; T_return_min = 18;

statesInit = [Ta0, Tzi0, Tzo0, Twi0, Two0, Tp0, T_return0];
statesConstr = [Ta_max, Ta_min, Twall_max, Twall_min, Tp_max, Tp_min, T_return_max, T_return_min];

%Ograniczenia i war. początkowe dla budynku
[x0,xmax,xmin] = initialStates(nx,statesInit, statesConstr, N, exWalls, unheatedZones, roofSt);
umax = 40*ones(nu,1);
umin = 20*ones(nu,1);
xmax = xmax';
xmin = xmin';
ymax = Ta_max*ones(ny,1);
ymin = Ta_min*ones(ny,1);

%Ograniczenia i war. początkowe dla pompy
T_buf = 50; T_bufMAX = 52.5; T_bufMIN = 47.5;
P_MAX = 100000; P_MIN = 1000;
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
C_measured = create_Cobserver_matrix(Cm, N); % Macierz C stanów mierzonych

%Wyznacz macierz pomiarową C dla układu pompy
C_measured = [C_measured; zeros(1, size(C_measured,2))];
C_measured = [C_measured zeros(size(C_measured,1),1)];
C_measured(end,end) = 1;

Z_known = Zd(:,1:3);
Z_unknown = Zd(:,4:end);
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
