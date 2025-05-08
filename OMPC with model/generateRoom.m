%strefa - odrębna przestrzeń w budynku dla której realizujemy regulację temperatury

%przyjęta kolejność stanów:
%temperatura pomieszczenia (strefy grzewczej)
%temperatury ścian zewnętrznych (Tzi i Tzo)
%temperatury ścian wewnętrznych (Tw1i, Tw1o, Tw2i, Tw2o...)
%temperatura sufitu lub stropu (Tsi, Tsoi)
%temperatura podłogi
%temperatura wody ogrzewającej podłogę (jeden obwód grzewczy)

%przyjęta kolejność w wektorze parametrów:
%1. pojemnosc cieplna sekcji (powietrza)
%2. pojemnosc cieplna sciany zewnetrznej (wnetrze)
%3. pojemnosc cieplna sciany zewnetrznej (zewnetrze)
%-------------------------------------------------
%4. pojemnosc cieplna sciany wewnetrznej (wnetrze)
%5. pojemnosc cieplna sciany wewnetrznej (zewnetrze)
%-------------------------------------------------
%5. pojemnosc cieplna stropu/dachu (wnetrze)
%6. pojemnosc cieplna stropu/dachu (zewnetrze)
%7. pojemnosc cieplna podlogi
%8. opór cieplny sekcji
%9. opór cieplny ściany zewnętrznej
%-------------------------------------------------
%10. opór cieplny ściany wewnętrznej
%-------------------------------------------------
%11. opór cieplny stropu/sufitu
%12. opór cieplny podłogi
%13. opór cieplny wody powracającej
%14. pojemność cieplna wody w strefie 

function [A,B,C,D,Z] = generateRoom(param, n, H, vecNeighbors, area, is_controlled, floorType, insulationsTable, coefficients, eq)

%stałe parametry
scale = coefficients(1);
h1 = coefficients(2); %Convective Heat Transfer Coefficient [W/m2K] dla powietrza wewnątrz budynku
h2 = coefficients(3); %Convective Heat Transfer Coefficient [W/m2K] dla powietrza zewnętrznego (wiatr)
roofAngle = coefficients(4);
Awin = eq(1,:)*coefficients(5)*eq(2,:); %powierzchnia okien
Uwin = coefficients(6);
SC = coefficients(7); %współczynnik zacienienia okna
alpha_wall = coefficients(8); %współczynnik absorpcji ściany (zależny od koloru)
alpha_floor = coefficients(9);
cw = coefficients(10);
dw = coefficients(11);

%przeskaluj dane
area = scale^2 * area;
vecNeighbors = scale * vecNeighbors;

%dach ze skosem (dla budynku z jednym piętrem lub dla ostatniego piętra)
if floorType == -1 || floorType == 2
    alphaRad = roofAngle/180*pi;
    if mod(roofAngle,180) == 0
        roofArea = area;
    else
        roofArea = 2*area*abs(sin((pi-alphaRad)/2)/sin(alphaRad));
    end
else
    roofArea = area;
end

%n - liczba ścian wewnętrznych w strefie
L = vecNeighbors(1,1);
Ca = param(1);
Czi = param(2);
Czo = param(3);
Cwi = param(4:4+n-1);
Cwo = param(4+n:4+n+(n-1));
Csi = param(4+2*n);
Cso = param(5+2*n);
Cp = param(6+2*n);
Rz = param(7+2*n);
Rw = param(8+2*n:8+2*n+(n-1));
Rs = param(8+3*n);
Rp = param(9+3*n);
U_conv = param(10+3*n);
Rb = param(11+3*n);

% Czy ściana zewnętrzna strefy posiada okno?
if eq(1,:) == 1

    % Zaktualizuj opór cieplny wprowadzając opór okna
    Uz = (L*H-Awin)/(L*H)*1/Rz + Awin/(L*H)*Uwin;
    Rz = 1/Uz;

    vecParam = table2array(insulationsTable(:,1));
    l_mid = sum(vecParam(1,:))/2;
    val = 0; idx = 0;
    for i = 1:size(vecParam(1,:),2)
        if val <= l_mid
            val = val + vecParam(1,i);
            idx = idx + 1;
        end
    end

    % Zaktualizuj pojemności cieplne usuwając objętość okna
    Czi = Czi - (sum(vecParam(1,1:idx-1) * vecParam(2,1:idx-1)' * vecParam(3,1:idx-1)) + abs(l_mid - sum(vecParam(1,1:idx-1)))*vecParam(2,idx)*vecParam(3,idx))*Awin*eq(2,:);
    Czo = Czo - (sum(vecParam(1,idx:end) * vecParam(2,idx:end)' * vecParam(3,idx:end)) + abs(l_mid - sum(vecParam(1,idx:end)))*vecParam(2,idx)*vecParam(3,idx))*Awin*eq(2,:);
end

% Sformatuj wektor vecNeighbors w taki sposób, aby usunąć wszystkie 
% zerowe wartości, nie zmieniając kolejności!
vecNeighbors = vecNeighbors(2:end);
new_vecNeighbors = [];
for i = 1:size(vecNeighbors,2)
    val = vecNeighbors(i);
    if val ~= 0
        new_vecNeighbors = [new_vecNeighbors val];
    end
end
vecNeighbors = new_vecNeighbors;

%----------------------------------
%Macierz A

% Jeżeli L=0 to oznacza, że strefa nie posiada ścian zewnętrznych (strefa okrążona jest przez inne strefy)
% w ramach łatwiejszej identyfikacji zdecydowano o pozostawieniu zerowych wierszy

sectionEq_p1 = 0;
for i = 1:n
    sectionEq_p1 = sectionEq_p1 + (h1*(vecNeighbors(1,i)*H));
end

sectionEq_p2 = [];
for i = 1:n
    sectionEq_p2 = [sectionEq_p2 1/Ca*(h1*(vecNeighbors(1,i)*H)) 0];
end

%Sprawdź czy parametry nie są zerowe, wynoszą Inf albo NaN
%sprawdzenie czy tworzona sekcja posiada jedynie ściany wewnętrzne
if L==0 || L==Inf || isnan(L)
    sectionEq = [-1/Ca*(sectionEq_p1+(h1*roofArea)+(h1*area)) 0 0 sectionEq_p2 1/Ca*(h1*roofArea) 0 1/Ca*(h1*area) 0];
else
    sectionEq = [-1/Ca*((h1*H*L)+sectionEq_p1+(h1*roofArea)+(h1*area)) 1/Ca*(h1*H*L) 0 sectionEq_p2 1/Ca*(h1*roofArea) 0 1/Ca*(h1*area) 0];
end

%-----------
%Sprawdź czy parametry nie są zerowe, wynoszą Inf albo NaN'
%sprawdzenie czy tworzona sekcja posiada jedynie ściany wewnętrzne
if L==0 || L==Inf || isnan(L)
    exteriorWallEq = zeros(2,size(sectionEq,2));
else
    exteriorWallEq = [1/Czi*(h1*H*L) -(h1*H*L/Czi + H*L/Rz/Czi) H*L/Rz/Czi zeros(1,2*n) 0 0 0 0;
                            0 H*L/Rz/Czo -(h2*H*L/Czo + H*L/Rz/Czo) zeros(1,2*n) 0 0 0 0];
end

%-----------
interiorWallEq = [];
for i = 1:n
    interiorWallEq = [interiorWallEq;
                        h1*vecNeighbors(1,i)*H/Cwi(i) 0 0 zeros(1,2*(i-1)) -(h1*vecNeighbors(1,i)*H/Cwi(i) + vecNeighbors(1,i)*H/Rw(i)/Cwi(i)) vecNeighbors(1,i)*H/Rw(i)/Cwi(i) zeros(1,2*n-2*i) 0 0 0 0;
                        0 0 0 zeros(1,2*(i-1)) vecNeighbors(1,i)*H/(Rw(i)*Cwo(i)) -(h1*(vecNeighbors(1,i)*H)/Cwo(i) + vecNeighbors(1,i)*H/(Rw(i)*Cwo(i))) zeros(1,2*n-2*i) 0 0 0 0];
end

%-----------

if floorType == 0
    % Jeżeli sekcja znajduje się na pierwszym piętrze budynku wielopiętrowego
    roofEq = [h1*roofArea/Csi 0 0 zeros(1,2*n) -(h1*roofArea/Csi+roofArea/Rs/Csi) roofArea/Rs/Csi 0 0;
    0 0 0 zeros(1,2*n) roofArea/Rs/Cso -(roofArea/Rs/Cso) 0 0];

    floorEq = [h1*area/Cp 0 0 zeros(1,2*n) 0 0 -1/Cp*(U_conv*area + h1*area + area/(Rp+Rb)) U_conv*area/Cp];
elseif floorType == 1
    % Jeżeli sekcja znajduje się na drugim -> przedostatnim piętrze budynku wielopiętrowego
    roofEq = [h1*roofArea/Csi 0 0 zeros(1,2*n) -(h1*roofArea/Csi+roofArea/Rs/Csi) roofArea/Rs/Csi 0 0;
    0 0 0 zeros(1,2*n) roofArea/Rs/Cso -(roofArea/Rs/Cso) 0 0];

    floorEq = [h1*area/Cp 0 0 zeros(1,2*n) 0 0 -1/Cp*(U_conv*area + h1*area) U_conv*area/Cp];
elseif floorType == 2
    % Jeżeli sekcja znajduje się na ostatnim piętrze budynku wielopiętrowego
    roofEq = [h1*roofArea/Csi 0 0 zeros(1,2*n) -(h1*roofArea/Csi+roofArea/Rs/Csi) roofArea/Rs/Csi 0 0;
    0 0 0 zeros(1,2*n) roofArea/Rs/Cso -(h2*roofArea/Cso + roofArea/Rs/Cso) 0 0];
    
    floorEq = [h1*area/Cp 0 0 zeros(1,2*n) 0 0 -1/Cp*(U_conv*area + h1*area) U_conv*area/Cp];
elseif floorType == -1
    % Jeżeli sekcja znajduje się w budynku jednopiętrowym
    roofEq = [h1*roofArea/Csi 0 0 zeros(1,2*n) -(h1*roofArea/Csi+roofArea/Rs/Csi) roofArea/Rs/Csi 0 0;
    0 0 0 zeros(1,2*n) roofArea/Rs/Cso -(h2*roofArea/Cso + roofArea/Rs/Cso) 0 0];

    floorEq = [h1*area/Cp 0 0 zeros(1,2*n) 0 0 -1/Cp*(U_conv*area + h1*area + area/(Rp+Rb)) U_conv*area/Cp];
end

%-----------
d = eq(5); % rozstaw rur [m]
L_total = 1.1*area/d;
pipeDiameter = eq(3);
pipeThickness = eq(4);
Vwater = pi*((pipeDiameter - 2*pipeThickness)/2)^2 * L_total;
Cwater = dw*cw*Vwater;
pipeRadius = (pipeDiameter - 2*pipeThickness);
waterVelocity = eq(6)/60000 / (pi*(pipeRadius)^2); % [l/min] -> [m/s]

m_dot = dw*pi*(pipeRadius)^2*waterVelocity;

%Cwater * dT_water(t)/dt = m_dot*cw*(T_supply(t)-T_return(t)) + area/Rp*(T_floor(t)-T_return(t))
returnWaterEq = [0 0 0 zeros(1,2*n) 0 0 area/Rp/Cwater -(m_dot*cw/Cwater + area/Rp/Cwater)];

A = [sectionEq;exteriorWallEq;interiorWallEq;roofEq;floorEq;returnWaterEq];

%----------------------------------
%Macierz B
if is_controlled == 1
    B = [0;0;0;zeros(2*n,1);0;0;0;m_dot*cw/Cwater];
elseif is_controlled == 0
    B = zeros(size(A,1),1);
end
%----------------------------------
%Macierz C
if is_controlled == 1
    C = [1 0 0 zeros(1,2*n) 0 0 0 0];
elseif is_controlled == 0
    C = zeros(1, size(A,1));
end

%----------------------------------
%Macierz D
D = 0;

%----------------------------------
%Macierz Z
% zakłócenia: 
% 1) temperatura na zewnątrz [K],
% 2) natężenie światła [W/m^2]
% 3) temperatura podłoża [K],
% 4) straty/zyski energii (moc cieplna) [W]

coeffFloor = 1/Cp*Awin*SC*alpha_floor;
coeffWall = 1/Czo*(L*H - Awin)*alpha_wall;

%Sprawdź czy parametry nie są zerowe, wynoszą Inf albo NaN
%sprawdzenie czy tworzona sekcja posiada jedynie ściany wewnętrzne
if L==0 || L==Inf || isnan(L)
    % sekcja nie posiada ścian zewnętrznych (posiada tylko wewnętrzne)
    if floorType == 0
        Z = [0 0 0 1/Ca;
        0 0 0 0;
        0 0 0 0;
        zeros(2*n,4);
        0 0 0 0;
        0 0 0 0;
        0 0 area/(Rp+Rb)/Cp 0;
        0 0 0 0];
    elseif floorType == 1
        Z = [0 0 0 1/Ca;
        0 0 0 0;
        0 0 0 0;
        zeros(2*n,4);
        0 0 0 0;
        0 0 0 0;
        0 0 0 0;
        0 0 0 0];
    elseif floorType == 2
        Z = [0 0 0 1/Ca;
        0 0 0 0;
        0 0 0 0;
        zeros(2*n,4);
        0 0 0 0;
        h2*roofArea/Cso 0 0 0;
        0 0 0 0;
        0 0 0 0];
    elseif floorType == -1
        Z = [0 0 0 1/Ca;
        0 0 0 0;
        0 0 0 0;
        zeros(2*n,4);
        0 0 0 0;
        h2*roofArea/Cso 0 0 0;
        0 0 area/(Rp+Rb)/Cp 0;
        0 0 0 0];
    end
else
    % sekcja posiada ściany zewnętrzne
    if floorType == 0
        Z = [0 0 0 1/Ca;
        0 0 0 0;
        h2*H*L*1/Czo coeffWall 0 0;
        zeros(2*n,4);
        0 0 0 0;
        0 0 0 0;
        0 coeffFloor area/(Rp+Rb)/Cp 0;
        0 0 0 0];
    elseif floorType == 1
        Z = [0 0 0 1/Ca;
        0 0 0 0;
        h2*H*L*1/Czo coeffWall 0 0;
        zeros(2*n,4);
        0 0 0 0;
        0 0 0 0;
        0 coeffFloor 0 0;
        0 0 0 0];
    elseif floorType == 2
        Z = [0 0 0 1/Ca;
        0 0 0 0;
        h2*H*L*1/Czo coeffWall 0 0;
        zeros(2*n,4);
        0 0 0 0;
        h2*roofArea/Cso 0 0 0;
        0 coeffFloor 0 0;
        0 0 0 0];
    elseif floorType == -1
        Z = [0 0 0 1/Ca;
        0 0 0 0;
        h2*H*L*1/Czo coeffWall 0 0;
        zeros(2*n,4);
        0 0 0 0;
        h2*roofArea/Cso 0 0 0;
        0 coeffFloor area/(Rp+Rb)/Cp 0;
        0 0 0 0];
    end
end

end