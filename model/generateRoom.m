%"sekcja" - odrębna przestrzeń w budynku dla której realizujemy regulację temperatury

%przyjęta kolejność stanów:
%temperatura pomieszczenia (sekcji)
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
%5. pojemnosc cieplna stropu/sufitu (wnetrze)
%6. pojemnosc cieplna stropu/sufitu (zewnetrze)
%7. pojemnosc cieplna podlogi
%8. opór cieplny sekcji
%9. opór cieplny ściany zewnętrznej
%-------------------------------------------------
%10. opór cieplny ściany wewnętrznej
%-------------------------------------------------
%11. opór cieplny stropu/sufitu
%12. opór cieplny podłogi
%13. opór cieplny wody powracającej
%14. pojemność cieplna wody w systemie 

function [A,B,C,D,Z] = generateRoom(param, n, H, vecNeighbors, area, typ, flag, insulationsTable, coefficients, eq)

%stałe parametry
scale = coefficients(1);
h2 = coefficients(2); %Convective Heat Transfer Coefficient [W/m2K] dla powietrza wewnątrz budynku
h1 = coefficients(3); %Convective Heat Transfer Coefficient [W/m2K] dla powietrza zewnętrznego (wiatr)
roofAngle = coefficients(4);
k = coefficients(10); %współczynnik proporcjonalności energii przechodzącej do całkowitej
Awin = coefficients(8)*eq(2,:); %powierzchnia okien
SC = coefficients(11); %współczynnik zacienienia okna
alpha = coefficients(12); %współczynnik absorpcji ściany (zależny od koloru)
%f - orientacja

%przeskaluj dane
area = scale^2 * area;
vecNeighbors = scale * vecNeighbors;

%dach ze skosem
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

%n - liczba ścian wewnętrznych w sekcji
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
hw = param(10+3*n);
Rb = param(11+3*n);

%czy ściana zewnętrzna posiada okno
if eq(1,:) == 1
    Uz = (L*H-coefficients(8)*eq(2,:))/(L*H)*1/Rz + coefficients(8)*eq(2,:)/(L*H)*coefficients(9);
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
    Czi = Czi - (sum(vecParam(1,1:idx-1) * vecParam(2,1:idx-1)' * vecParam(3,1:idx-1)) + abs(l_mid - sum(vecParam(1,1:idx-1)))*vecParam(2,idx)*vecParam(3,idx))*Awin*eq(2,:);
    Czo = Czo - (sum(vecParam(1,idx:end) * vecParam(2,idx:end)' * vecParam(3,idx:end)) + abs(l_mid - sum(vecParam(1,idx:end)))*vecParam(2,idx)*vecParam(3,idx))*Awin*eq(2,:);
end

%sformatuj wektor vecNeighbors w taki sposób, aby usunąć wszystkie 
%zerowe wartości nie zmieniając kolejności!
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

%Jeżeli L=0 to oznacza, że sekcja nie posiada ścian zewnętrznych (okrążona jest innymi sekcjami)
%w ramach łatwiejszej identyfikacji zdecydowano o pozostawieniu zerowych wierszy

sectionEq_p1 = 0;
for i = 1:n
    sectionEq_p1 = sectionEq_p1 + (h2*(vecNeighbors(1,i)*H));
end

sectionEq_p2 = [];
for i = 1:n
    sectionEq_p2 = [sectionEq_p2 1/Ca*(h2*(vecNeighbors(1,i)*H)) 0];
end
%Sprawdź czy parametry nie są zerowe, wynoszą Inf albo NaN
%sprawdzenie czy tworzona sekcja posiada jedynie ściany wewnętrzne
if L==0 || L==Inf || isnan(L)
    sectionEq = [-1/Ca*(sectionEq_p1+(h2*roofArea)+(h2*area)) 0 0 sectionEq_p2 1/Ca*(h2*roofArea) 0 1/Ca*(h2*area) 0];
else
    sectionEq = [-1/Ca*((h2*H*L)+sectionEq_p1+(h2*roofArea)+(h2*area)) 1/Ca*(h2*H*L) 0 sectionEq_p2 1/Ca*(h2*roofArea) 0 1/Ca*(h2*area) 0];
end

%-----------
%Sprawdź czy parametry nie są zerowe, wynoszą Inf albo NaN'
%sprawdzenie czy tworzona sekcja posiada jedynie ściany wewnętrzne
if L==0 || L==Inf || isnan(L)
    exteriorWallEq = zeros(2,size(sectionEq,2));
else
    exteriorWallEq = [1/Czi*(h2*H*L) -(h2*H*L/Czi + H*L/Rz/Czi) H*L/Rz/Czi zeros(1,2*n) 0 0 0 0;
                            0 H*L/Rz/Czo -(h1*H*L/Czo + H*L/Rz/Czo) zeros(1,2*n) 0 0 0 0];
end

%-----------
interiorWallEq = [];
for i = 1:n
    interiorWallEq = [interiorWallEq;
                        h2*vecNeighbors(1,i)*H/Cwi(i) 0 0 zeros(1,2*(i-1)) -(h2*vecNeighbors(1,i)*H/Cwi(i) + vecNeighbors(1,i)*H/Rw(i)/Cwi(i)) vecNeighbors(1,i)*H/Rw(i)/Cwi(i) zeros(1,2*n-2*i) 0 0 0 0;
                        0 0 0 zeros(1,2*(i-1)) vecNeighbors(1,i)*H/(Rw(i)*Cwo(i)) -(h2*(vecNeighbors(1,i)*H)/Cwo(i) + vecNeighbors(1,i)*H/(Rw(i)*Cwo(i))) zeros(1,2*n-2*i) 0 0 0 0];
end

%-----------
vecParam = table2array(insulationsTable(:,4));
l_mid = sum(vecParam(1,:))/2;
val = 0; idx = 0;
for i = 1:size(vecParam(1,:),2)
    if val <= l_mid
        val = val + vecParam(1,i);
        idx = idx + 1;
    end
end

Rso = 0;
for i = idx:size(vecParam,2)
    Rso = Rso + vecParam(1,i)/vecParam(4,i);
end

if flag == 0
    %jeżeli sekcja znajduje się na pierwszym piętrze budynku wielopiętrowego
    roofEq = [h2*roofArea/Csi 0 0 zeros(1,2*n) -(h2*roofArea/Csi+roofArea/Rs/Csi) roofArea/Rs/Csi 0 0;
    0 0 0 zeros(1,2*n) roofArea/Rs*1/Cso -(roofArea/(Rp+Rso)/Cso + roofArea/Rs/Cso) 0 0];

    floorEq = [h2*area/Cp 0 0 zeros(1,2*n) 0 0 -1/Cp*(hw*area + h2*area + area/(Rp+Rb)) hw*area/Cp];
elseif flag == 1
    % jeżeli sekcja znajduje się na drugim -> przedostatnim piętrze budynku wielopiętrowego
    roofEq = [h2*roofArea/Csi 0 0 zeros(1,2*n) -(h2*roofArea/Csi+roofArea/Rs/Csi) roofArea/Rs/Csi 0 0;
    0 0 0 zeros(1,2*n) roofArea/Rs/Cso -(roofArea/(Rp+Rso)/Cso + roofArea/Rs/Cso) 0 0];

    floorEq = [h2*area/Cp 0 0 zeros(1,2*n) 0 0 -1/Cp*(hw*area + h2*area + area/(Rp+Rso)) hw*area/Cp];
elseif flag == 2
    % jeżeli sekcja znajduje się na ostatnim piętrze budynku wielopiętrowego
    roofEq = [h2*roofArea/Csi 0 0 zeros(1,2*n) -(h2*roofArea/Csi+roofArea/Rs/Csi) roofArea/Rs/Csi 0 0;
    0 0 0 zeros(1,2*n) roofArea/Rs/Cso -(h1*roofArea/Cso + roofArea/Rs/Cso) 0 0];
    
    floorEq = [h2*area/Cp 0 0 zeros(1,2*n) 0 0 -1/Cp*(hw*area + h2*area + area/(Rp+Rso)) hw*area/Cp];
elseif flag == -1
    % jeżeli sekcja znajduje się w budynku jednopiętrowym
    roofEq = [h2*roofArea/Csi 0 0 zeros(1,2*n) -(h2*roofArea/Csi+roofArea/Rs/Csi) roofArea/Rs/Csi 0 0;
    0 0 0 zeros(1,2*n) roofArea/Rs/Cso -(h1*roofArea/Cso + roofArea/Rs/Cso) 0 0];

    floorEq = [h2*area/Cp 0 0 zeros(1,2*n) 0 0 -1/Cp*(hw*area + h2*area + area/(Rp+Rb)) hw*area/Cp];
end

%-----------
d = coefficients(13); % rozstaw rur [m]
L_total = area/d;
Vwater = pi*(coefficients(6)/2 - coefficients(7))^2 * L_total;
cw = coefficients(14);
dw = coefficients(15);
Cwater = dw*cw*Vwater;

m_dot = dw*pi*(coefficients(6)/2 - coefficients(7))^2*coefficients(5);

%Cwater * dT_water(t)/dt = m_dot*cw*(T_supply(t)-T_return(t)) + area/Rp*(T_floor(t)-T_return(t))
returnWaterEq = [0 0 0 zeros(1,2*n) 0 0 area/Rp/Cwater -(m_dot*cw/Cwater + area/Rp/Cwater)];

%-----------
A = [sectionEq;exteriorWallEq;interiorWallEq;roofEq;floorEq;returnWaterEq];

%----------------------------------
%Macierz B
if typ == "sekcja"
    B = [0;0;0;zeros(2*n,1);0;0;0;m_dot*cw/Cwater];
else
    B = zeros(size(A,1),1);
end
%----------------------------------
%Macierz C
C = [1 0 0 zeros(1,2*n) 0 0 0 0];

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

coeffRoom = 1/Ca*Awin*k*SC;
coeffWall = 1/Czo*L*H*alpha;

%Sprawdź czy parametry nie są zerowe, wynoszą Inf albo NaN
%sprawdzenie czy tworzona sekcja posiada jedynie ściany wewnętrzne
if L==0 || L==Inf || isnan(L)
    % sekcja nie posiada ścian zewnętrznych (posiada tylko wewnętrzne)
    if flag == 0
        Z = [0 0 0 1/Ca;
        0 0 0 0;
        0 0 0 0;
        zeros(2*n,4);
        0 0 0 0;
        0 0 0 0;
        0 0 area/(Rp+Rb)/Cp 0;
        0 0 0 0];
    elseif flag == 1
        Z = [0 0 0 1/Ca;
        0 0 0 0;
        0 0 0 0;
        zeros(2*n,4);
        0 0 0 0;
        0 0 0 0;
        0 0 0 0;
        0 0 0 0];
    elseif flag == 2
        Z = [0 0 0 1/Ca;
        0 0 0 0;
        0 0 0 0;
        zeros(2*n,4);
        0 0 0 0;
        h1*roofArea/Cso 0 0 0;
        0 0 0 0;
        0 0 0 0];
    elseif flag == -1
        Z = [0 0 0 1/Ca;
        0 0 0 0;
        0 0 0 0;
        zeros(2*n,4);
        0 0 0 0;
        h1*roofArea/Cso 0 0 0;
        0 0 area/(Rp+Rb)/Cp 0;
        0 0 0 0];
    end
else
    % sekcja posiada ściany zewnętrzne
    if flag == 0
        Z = [0 coeffRoom 0 1/Ca;
        0 0 0 0;
        h1*H*L*1/Czo coeffWall 0 0;
        zeros(2*n,4);
        0 0 0 0;
        0 0 0 0;
        0 0 area/(Rp+Rb)/Cp 0;
        0 0 0 0];
    elseif flag == 1
        Z = [0 coeffRoom 0 1/Ca;
        0 0 0 0;
        h1*H*L*1/Czo coeffWall 0 0;
        zeros(2*n,4);
        0 0 0 0;
        0 0 0 0;
        0 0 0 0;
        0 0 0 0];
    elseif flag == 2
        Z = [0 coeffRoom 0 1/Ca;
        0 0 0 0;
        h1*H*L*1/Czo coeffWall 0 0;
        zeros(2*n,4);
        0 0 0 0;
        h1*roofArea/Cso 0 0 0;
        0 0 0 0;
        0 0 0 0];
    elseif flag == -1
        Z = [0 coeffRoom 0 1/Ca;
        0 0 0 0;
        h1*H*L*1/Czo coeffWall 0 0;
        zeros(2*n,4);
        0 0 0 0;
        h1*roofArea/Cso 0 0 0;
        0 0 area/(Rp+Rb)/Cp 0;
        0 0 0 0];
    end
end

end