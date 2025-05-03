function [A,B,C,D,Z] = mergePumpBuilding(Am,Bm,Cm,Dm,Zm,vecStatesNum,roomEquipment,coefficients)

nx = size(Am,1);
mat = table2array(roomEquipment);
v = sum(mat(6,:));

[Ap, Bp, Cp, ~, Zp] = heatPump(coefficients, v);

A = [Am zeros(size(Am,1),size(Ap,1));
     zeros(size(Ap,1),size(Am,1)) Ap];

B = [Bm zeros(size(Bm,1),size(Bp,2));
     zeros(size(Bp,1),size(Bm,2)) Bp];

C = [Cm zeros(size(Cm,1),size(Cp,2));
     zeros(size(Cp,1),size(Cm,2)) Cp];

D = Dm;

Z = [Zm; zeros(size(Ap,1),size(Zm,2))];

N = [];
for i = 1:size(vecStatesNum,2)-1
    N = [N vecStatesNum(i+1)-vecStatesNum(i)];
end
N = [N nx];

for i = 1:size(N,2)
    
    %Temperatura otaczająca bufor - strefa pierwsza;
    A(end,1) = Zp(1,1);

    %Temperatura wody powracającej do bufora - średnia ważona temperatur z
    %sekcji
    A(end,N(i)) = Zp(1,2) * (mat(6,i))/v;
end

end

