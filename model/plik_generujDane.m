clear;clc;
%--------------------------------------------------------------------------
% stałe parametry
scale = 5; %skala siatki macierzy
coeffInside = 3; %Convective Heat Transfer Coefficient [W/m2K] dla powietrza wewnątrz budynku
coeffOutside = 20; %Convective Heat Transfer Coefficient [W/m2K] dla powietrza zewnętrznego (wiatr)
roofAngle = 40; %kąt nachylenia dachu [°]
waterVelocity = 0.5; %prędkość wody [m/s]
pipeDiameter = 0.016; %średnica rurek podłogowych [m]
pipeThickness = 0.002; %grubość ścianek rurek podłogowych [m]
Awin = 1.43*0.865; %powierzchnia okna [m^2]
Uwin = 0.95; %przenikalność cieplna okna [W/m2K]
coefficients = [scale coeffInside coeffOutside roofAngle waterVelocity pipeDiameter pipeThickness Awin Uwin];

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

roomEquipment = table(level1Equipment,level2Equipment);

[A,B,C,D,Z,N] = generateBuilding(matrixTable,heightTable,insulationTable,coefficients,roomEquipment);

%%

nx = size(A,1);
nu = size(B,2);
ny = size(C,1);

%model dyskretny
Ts = 60;
sys = ss(A,[B Z],C,D);
sysd = c2d(sys,Ts,'zoh');
[Ad,Bd,Cd,Dd] = ssdata(sysd);

Zd = Bd(:, size(B, 2)+1:end);
Bd = Bd(:, 1:size(B, 2));

%parametry regulatora
nc = 20;
npred = 100;
na = 10;
time = 3600*2; %czas symulacji [s]
Q = 150*(C'*C);
R = 0.5*eye(size(B,2));

%--------------------------------------------------------------------------
%%

%Ograniczenia oraz warunki początkowe
Ta0 = 18; %temperatura sekcji
Tzi0 = 18; Tzo0 = 18; %temperatury wewnętrzna/zewnętrza ściany zewnętrznej
Twi0 = 18; Two0 = 18; %temperatury wewnętrzna/zewnętrza ściany wewnętrznej
Tp0 = 20; %temperatura podłogi

Ta_max = 25; Ta_min = 0;
Twall_max = 100; Twall_min = -100;
Tp_max = 35; Tp_min = 0;
%pętla tworząca wektor stanów początkowych:
x0 = [];
xmax = [];
xmin = [];
for i = 2:size(N,2)
    m = N(i-1);
    n = N(i);
    cnt = ((n - m) - 4 )/2;
    states0 = [];
    xmax0 = [];
    xmin0 = [];
    for j = 1:cnt
        states0 = [states0 Twi0 Two0];
        xmax0 = [xmax0 Twall_max Twall_max];
        xmin0 = [xmin0 Twall_min Twall_min];
    end
    x0 = [x0 [Ta0 Tzi0 Tzo0 states0 Tp0]];
    xmax = [xmax [Ta_max Twall_max Twall_max xmax0 Tp_max]];
    xmin = [xmin [Ta_min Twall_min Twall_min xmin0 Tp_min]];
end

cnt = ((nx - size(x0,2))-2)/2;
states0 = [];
xmax0 = [];
xmin0 = []; 
for j = 1:cnt
    states0 = [states0 Twi0 Two0];
    xmax0 = [xmax0 Twall_max Twall_max];
    xmin0 = [xmin0 Twall_min Twall_min];
end
x0 = [x0 [Ta0 states0 Tp0]];
x0 = x0';
xmax = [xmax [Ta_max xmax0 Tp_max]];
xmin = [xmin [Ta_min xmin0 Tp_min]]; 

%Ograniczenia
umax = 50*ones(nu,1);
umin = 0*ones(nu,1);
xmax = xmax';
xmin = xmin';
ymax = Ta_max*ones(ny,1);
ymin = Ta_min*ones(ny,1);
%--------------------------------------------------------------------------
%%
%wygeneruj dane do regulatora
% [K,Sx,Sxc,Sc] = ompc_cost(Ad,Bd,Q,R,nc);
[K,Sx,Sxc,Sxr,Sc,Sr,Scr] = ompc_cost_tracking(Ad,Bd,Cd,Q,R,nc,na);

%%
%Obserwator zakłóceń oraz stanów
nz = size(Zd,2);
Ao = [Ad Zd; zeros(nz,nx) zeros(nz,nz)];
Bo = [Bd; zeros(nz,nu)];
Co = [Cd zeros(ny,nz)];
Go = dlqr(Ao', Co', 1e1*eye(nx+nz), 1e-4*eye(ny)); Go = Go';
Kz = pinv(Bd)*Zd;


