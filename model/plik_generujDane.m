clear;clc;
%--------------------------------------------------------------------------
% stałe parametry
scale = 10; %skala siatki macierzy
coeffInside = 3; %Convective Heat Transfer Coefficient [W/m2K] dla powietrza wewnątrz budynku
coeffOutside = 20; %Convective Heat Transfer Coefficient [W/m2K] dla powietrza zewnętrznego (wiatr)
roofAngle = 40; %kąt nachylenia dachu [°]
waterVelocity = 0.5; %prędkość wody [m/s]
pipeDiameter = 0.016; %średnica rurek podłogowych [m]
pipeThickness = 0.002; %grubość ścianek rurek podłogowych [m]
Awin = 1.43*0.865; %powierzchnia okna [m^2]
Uwin = 0.95; %przenikalność cieplna okna [W/m2K]
k = 0.7; %współczynnik proporcjonalności energii przechodzącej do całkowitej
SC = 1; %współczynnik zacienienia okna
a = 0.3; %współczynnik absorpcji światła przez ściany (zależny od koloru)
d = 0.2; % rozstaw rur ogrzewania pod. [m]
cw = 4180; % ciepło właściwe wody
dw = 980; % gęstość wody

coefficients = [scale coeffInside coeffOutside roofAngle waterVelocity pipeDiameter pipeThickness Awin Uwin k SC a d cw dw];

% rozkład sekcji w budynku
matrix1 = [1 1 2 2; 
           1 1 2 2; 
           1 1 2 2; 
           1 1 2 2];

matrix2 = [2 2 2 3; 
           1 1 3 3; 
           1 1 3 4; 
           4 4 4 4];

matrix3 = [1 1 1 1; 
           1 2 2 2; 
           2 2 2 2; 
           3 3 3 3];

matrixTable = table(matrix1);

% wysokość pięter
heightTable = table(2.6);

% konfiguracja ocieplenia budynku
materialThickness = [0.07 0.0125 0.25 0.0125]; materialDensity = [50 1050 30 1050]; materialSpecificHeat = [1450 1200 1200 1200]; materialThermalCoeff = [0.035 0.45 0.045 0.45];
insulationExternal = [materialThickness;materialDensity;materialSpecificHeat;materialThermalCoeff];

materialThickness = [0.0125 0.05 0.0125]; materialDensity = [1050 700 1050]; materialSpecificHeat = [1200 1600 1200]; materialThermalCoeff = [0.45 0.15 0.45];
insulationInternal = [materialThickness;materialDensity;materialSpecificHeat;materialThermalCoeff];

materialThickness = [0.005 0.0125]; materialDensity = [1800 2000]; materialSpecificHeat = [1000 840]; materialThermalCoeff = [0.2 1.4];
insulationFloor = [materialThickness;materialDensity;materialSpecificHeat;materialThermalCoeff];

materialThickness = [0.05 0.0125 0.25 0.0125]; materialDensity = [30 1050 2500 1050]; materialSpecificHeat = [1500 1200 1000 1200]; materialThermalCoeff = [0.035 0.45 1.5 0.45];
insulationCeiling = [materialThickness;materialDensity;materialSpecificHeat;materialThermalCoeff];

materialThickness = [0.07 0.0125 0.25 0.0125]; materialDensity = [30 1050 30 1050]; materialSpecificHeat = [1500 1200 1200 1200]; materialThermalCoeff = [0.035 0.45 0.045 0.45];
insulationRoof = [materialThickness;materialDensity;materialSpecificHeat;materialThermalCoeff];

materialThickness = [0.2]; materialDensity = [50]; materialSpecificHeat = [1450]; materialThermalCoeff = [0.035]; %#ok<*NBRAK2> 
insulationGround = [materialThickness;materialDensity;materialSpecificHeat;materialThermalCoeff];

insulationTable = table(insulationExternal, insulationInternal, insulationFloor, insulationCeiling, insulationRoof, insulationGround);

% konfiguracja pomieszczeń (okna, liczba okien w pomieszczeniu, <reszta>)
level1Equipment = [1 1 1 0 1;
                   1 1 1 1 1];
level2Equipment = [0 1 0 1;
                   0 2 0 2];
level3Equipment = [0 0 0;
                   0 0 0];

roomEquipment = table(level1Equipment);

[A,B,C,D,Z,N,exWalls,roofSt] = generateBuilding(matrixTable,heightTable,insulationTable,coefficients,roomEquipment);
nx = size(A,1); nu = size(B,2); ny = size(C,1); nz = size(Z,2);

%%

%model dyskretny
Ts = 70;
sys = ss(A,[B Z],C,D);
sysd = c2d(sys,Ts,'zoh');
[Ad,Bd,Cd,Dd] = ssdata(sysd);
Zd = Bd(:, size(B, 2)+1:end);
Bd = Bd(:, 1:size(B, 2));

%parametry regulatora
nc = 20;
npred = 120;
na = 60;
time = 3600*24; %czas symulacji [s]
Q = 100*(C'*C);
R = 0.5*eye(size(B,2));

%trajektorie referencyjne i zakłóceń
trajRef = [21 21 20 20; 
           20 20 21 21;];
trajDist = [7 5.5 3.25 5.75 6.1 6.5 4.5; 
            10 10.05 10.15 10.275 10.215 10.15 10.05; 
            0 0 0 0 0 0 0; 
            0 0 0 0 0 0 0];

%--------------------------------------------------------------------------
%%

%Ograniczenia oraz warunki początkowe
Ta0 = 18; %temperatura sekcji
Tzi0 = 18; Tzo0 = 5; %temperatury wewnętrzna/zewnętrza ściany zewnętrznej
Twi0 = 18; Two0 = 18; %temperatury wewnętrzna/zewnętrza ściany wewnętrznej
Tp0 = 25; %temperatura podłogi
T_return0 = 25;

Ta_max = 25; Ta_min = 0; %ograniczenia temp. pomieszczen
Twall_max = 100; Twall_min = -100; %ograniczenia temp. scian
Tp_max = 35; Tp_min = 18; %ograniczenia temp. podlogi
T_return_max = 50; T_return_min = 18;

statesInit = [Ta0, Tzi0, Tzo0, Twi0, Two0, Tp0, T_return0];
statesConstr = [Ta_max, Ta_min, Twall_max, Twall_min, Tp_max, Tp_min, T_return_max, T_return_min];

[x0,xmax,xmin] = initialStates(A,statesInit, statesConstr, N, exWalls, roofSt);
umax = 45*ones(nu,1);
umin = 18*ones(nu,1);
xmax = xmax';
xmin = xmin';
ymax = Ta_max*ones(ny,1);
ymin = Ta_min*ones(ny,1);
%--------------------------------------------------------------------------
%%
%wygeneruj dane do regulatora
% [K,Sx,Sxc,Sc] = ompc_cost(Ad,Bd,Q,R,nc);
[K,Sx,Sxc,Sxr,Sc,Sr,Scr] = ompc_cost_tracking(Ad,Bd,Cd,Q,R,nc,na);

%--------------------------------------------------------------------------
%%
%Obserwator zakłóceń oraz stanów (ESO)
Kz = -Cd*inv(Ad)*Zd;

Z_unknown = Zd(:,3:end);
Z_known = Zd(:,1:2);
n_states = size(Ad, 1);
n_disturbances = size(Z_unknown, 2);
A_bar = [Ad, Z_unknown; zeros(n_disturbances, n_states), zeros(n_disturbances)];
B_bar = [Bd; zeros(n_disturbances, size(Bd, 2))];
Z_bar_known = [Z_known; zeros(n_disturbances, size(Z_known, 2))];
C_bar = [Cd, zeros(size(Cd, 1), n_disturbances)];
L = dlqr(A_bar', C_bar', 100*eye(size(A_bar,1)), 1e-5*eye(nu)); L = L';

% Ao = [Ad Zd; zeros(nz,nx) zeros(nz,nz)];
% Bo = [Bd; zeros(nz,nu)];
% Co = [Cd zeros(ny,nz)];
% Go = dlqr(Ao', Co', 0.1*eye(nx+nz), 1e4*eye(nu)); Go = Go';
