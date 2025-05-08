function [A,B,C,D,Z] = mergePumpBuilding(Am,Bm,Cm,Dm,Zm,vecStatesNum,roomEquipment,coefficients)

%Połącz model budynku z pompą ciepła + zbiornikiem buforowym (założono zawór centralny 3D)
nx = size(Am,1);
mat = table2array(roomEquipment);
alpha0 = coefficients(21);
Kv = coefficients(22);
k = Kv/(Kv+alpha0);

vbuf = 0;
for i = 1:size(mat(6,:),2)
    vbuf = vbuf + mat(6,i);
end
v = vbuf; %przepływ wody na wyjściu z rozdzielacza hydraulicznego
vbuf = vbuf*(1-k); %przepływ wody powracającej do bufora!

[Ap, Bp, Cp, ~, Zp] = heatPump(coefficients, vbuf);

A = [Am zeros(size(Am,1),size(Ap,1));
     zeros(size(Ap,1),size(Am,1)) Ap];

B = [Bm zeros(size(Bm,1),size(Bp,2));
     zeros(size(Bp,1),size(Bm,2)) Bp];

C = [Cm zeros(size(Cm,1),size(Cp,2));
     zeros(size(Cp,1),size(Cm,2)) Cp];

D = Dm;

Z = [Zm; zeros(size(Ap,1),size(Zm,2))];

%Przetransformuj na indeksy wody w strefie - pomiń strefy nieogrzewane
N = [];
for i = 1:size(vecStatesNum,2)-1

    %Strefy nieogrzewane nie posiadają wody!
    N = [N vecStatesNum(i+1)-1];
end
N = [N nx];

for i = 1:size(N,2)

    %Temperatura otaczająca bufor - strefa pierwsza lub druga;
    A(end,vecStatesNum(2)) = Zp(1,1);

    %Temperatura wody powracającej do bufora - średnia ważona z przepływów
    A(end,N(i)) = Zp(1,2) * (mat(6,i))/v;
end

end

