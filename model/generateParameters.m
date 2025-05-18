function [param,n] = generateParameters(vecNeighbors, area, H, flag, insulationsTable, coefficients, eq)

scale = coefficients(1); %skala siatki macierzy
roofAngle = coefficients(4);
cw = coefficients(9); % ciepło właściwe wody
dw = coefficients(10); % gęstość wody
kw = coefficients(11); % przewodność cieplna wody
u = coefficients(12); % lepkość
cp = coefficients(13);
dp = coefficients(14);
k_tube = coefficients(15);

%przeskaluj dane aby otrzymać odpowiednie długości w jednostkach SI
area = scale^2 * area;
vecNeighbors = scale * vecNeighbors;

%jeżeli piętro jest ostatnie lub jedyne - zastosuj dach ze skosem
if flag == -1 || flag == 2
    alphaRad = roofAngle/180*pi;
    if mod(roofAngle,180) == 0
        roofArea = area;
    else
        roofArea = 2*area*abs(sin((pi-alphaRad)/2)/sin(alphaRad));
    end
else
    roofArea = area;
end

%pojemność cieplna sekcji (powietrza)
Ca = cp*dp*area*H;

%pojemnosc cieplna scian zewnetrznych
L = vecNeighbors(1,1); %długość ściany zewnętrznej (sąsiedniczącej z otoczeniem zewnętrznym)
vecParam = table2array(insulationsTable(:,1));

l_mid = sum(vecParam(1,:))/2;
val = 0; idx = 0;
for i = 1:size(vecParam(1,:),2)
    if val <= l_mid
        val = val + vecParam(1,i);
        idx = idx + 1;
    end
end

Czi = (sum(vecParam(1,1:idx-1) * vecParam(2,1:idx-1)' * vecParam(3,1:idx-1)) + abs(l_mid - sum(vecParam(1,1:idx-1)))*vecParam(2,idx)*vecParam(3,idx)) * (L*H);
Czo = (sum(vecParam(1,idx:end) * vecParam(2,idx:end)' * vecParam(3,idx:end)) + abs(l_mid - sum(vecParam(1,idx:end)))*vecParam(2,idx)*vecParam(3,idx)) * (L*H);

%opór cieplny ściany zewnętrznej
Rz = 0;
for i = 1:size(vecParam,2)
    Rz = Rz + vecParam(1,i)/vecParam(4,i);
end

%pojemnosc cieplna scian wewnetrznych
vecParam = table2array(insulationsTable(:,2));
Cwi = [];
Cwo = [];

l_mid = sum(vecParam(1,:))/2;
val = 0; idx = 0;
for i = 1:size(vecParam(1,:),2)
    if val <= l_mid
        val = val + vecParam(1,i);
        idx = idx + 1;
    end
end

for i = 2:size(vecNeighbors,2)
    W = vecNeighbors(1,i); %długość sciany wewnętrznej sąsiadującej z sekcją
    CwiTemp = (sum(vecParam(1,1:idx-1) * vecParam(2,1:idx-1)' * vecParam(3,1:idx-1)) + abs(l_mid - sum(vecParam(1,1:idx-1)))*vecParam(2,idx)*vecParam(3,idx)) * (W*H);
    CwoTemp = (sum(vecParam(1,idx:end) * vecParam(2,idx:end)' * vecParam(3,idx:end)) + abs(l_mid - sum(vecParam(1,idx:end)))*vecParam(2,idx)*vecParam(3,idx)) * (W*H);
    if CwiTemp ~= 0 && CwoTemp ~= 0
        Cwi = [Cwi,CwiTemp];
        Cwo = [Cwo,CwoTemp];
    end
end

%opory cieplne ścian wewnętrznych
Rw_vec = [];
Rw = 0;
k = size(nonzeros(vecNeighbors(2:end))',2);
for i = 1:k
    for j = 1:size(vecParam,2)
        Rw = Rw + vecParam(1,j)/vecParam(4,j);
    end
    Rw_vec = [Rw_vec Rw];
end

%pojemność cieplna podłogi
vecParam = table2array(insulationsTable(:,3));
Cp = sum(vecParam(1,:) * vecParam(2,:)' * vecParam(3,:)) * area;

%opór cieplny podłogi
Rp = 0;
for i = 1:size(vecParam,2)
    Rp = Rp + vecParam(1,i)/vecParam(4,i);
end

%pojemnosc cieplna stropu/dachu
vecParam = table2array(insulationsTable(:,4));

l_mid = sum(vecParam(1,:))/2;
val = 0; idx = 0;
for i = 1:size(vecParam(1,:),2)
    if val <= l_mid
        val = val + vecParam(1,i);
        idx = idx + 1;
    end
end

Csi = (sum(vecParam(1,1:idx-1) * vecParam(2,1:idx-1)' * vecParam(3,1:idx-1)) + abs(l_mid - sum(vecParam(1,1:idx-1)))*vecParam(2,idx)*vecParam(3,idx)) * roofArea;
Cso = (sum(vecParam(1,idx:end) * vecParam(2,idx:end)' * vecParam(3,idx:end)) + abs(l_mid - sum(vecParam(1,idx:end)))*vecParam(2,idx)*vecParam(3,idx)) * roofArea;

%opór cieplny stropu/dachu
Rs = 0;
for i = 1:size(vecParam,2)
    Rs = Rs + vecParam(1,i)/vecParam(4,i);
end

vecParam = table2array(insulationsTable(:,5));

%opór cieplny podłoża
Rb = 0;
for i = 1:size(vecParam,2)
    Rb = Rb + vecParam(1,i)/vecParam(4,i);
end

%------------------------
pipeDiameter = eq(5);
pipeThickness = eq(6);
d = (pipeDiameter - 2*pipeThickness); %16 [mm] średnica zewnętrzna - 2 * 2 [mm] grubość ścianek
waterVelocity = eq(8)/60000 / (pi*(d/2)^2); % [m/s]

Re = dw * waterVelocity * d/u; % Liczba Reynoldsa
if Re < 2300
    %przepływ laminarny
    Nu = 3.66;
elseif Re >= 2300
    %przepływ turbulentny lub przejściowy
    Pr = cw*u/kw; % Liczba Prandtla
    Nu = 0.023*Re^0.8 * Pr^0.3; % Liczba Nusselta
end
hw = kw/d*Nu;

R_water = 1/(hw*pi*d); % Opór konwekcyjny

%Opór cieplny rurki PEX
R_tube = log(pipeDiameter/(pipeDiameter-2*pipeThickness))/(2*pi*k_tube); % Opór cieplny rurek PEX

U_conv = 1/(R_water + R_tube);

param = [Ca,Czi,Czo,Cwi,Cwo,Csi,Cso,Cp,Rz,Rw_vec,Rs,Rp,U_conv,Rb];
n = size(Rw_vec,2);

end

