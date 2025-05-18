function [A,B,C,D,Z] = mergePumpBuilding(Am,Bm,Cm,Dm,Zm,vecStatesNum,vecUnheatedFloors,roomEquipment,coefficients)

%Połącz model budynku z pompą ciepła + zbiornikiem buforowym (założono zawór centralny 3D)
nx = size(Am,1);
Q_flow = table2array(roomEquipment(8,:));

%Zabezpieczenie przed strefami nieogrzewanymi
if sum(vecUnheatedFloors) > 0
    QflowTEMP = [];
    for i = 1:size(Q_flow,2)
        if vecUnheatedFloors(i) == 0
            QflowTEMP = [QflowTEMP Q_flow(i)];
        end
    end
    Q_flow = QflowTEMP;
end

Q_total = sum(Q_flow); %przepływ wody powracającej do bufora [l/min]

[Ap, Bp, Cp, ~, Zp] = heatPump(coefficients, Q_flow);

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

%Zabezpieczenie przed strefami nieogrzewanymi
if sum(vecUnheatedFloors) > 0
    N_temp = [];
    for i = 1:size(N,2)
        if vecUnheatedFloors(i) == 0
            N_temp = [N_temp N(i)];
        end
    end
    N = N_temp;
end

for i = 1:size(N,2)
    %Temperatura otaczająca bufor - strefa pierwsza lub druga;
    strefa = vecStatesNum(1);
    A(end,strefa) = Zp(1);

    %Temperatura wody powracającej do bufora - średnia ważona z przepływów
    A(end,N(i)) = Zp(i + 1 + size(N,2)) * Q_flow(i)/Q_total;

    %Temperatura wody na wyjściu z zaworu wpływająca na temp. bufora
    B(end,i) = Zp(i+1) * Q_flow(i)/Q_total;
end

end

