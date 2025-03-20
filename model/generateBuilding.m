function [A,B,C,D,Z,statesVector] = generateBuilding(matrixTable,heightTable,insulationTable,coefficients,roomEquipment)

% matrixTable - przechowuje rozmieszczenie sekcji na każdym z pięter
% scaleLength - skala siatki w macierzach
% insulationTable - przechowuje dane materiałowe ścian, stropów, podłogi
% heightTable - przechowuje wysokości każdego z pięter

matrixNeighbors = [];
sectionsNum = [];
for m = 1:size(matrixTable,2)-1
    %odczytaj kolejne macierze
    currMat = table2array(matrixTable(:,m));
    nextMat = table2array(matrixTable(:,m+1));
    
    %wygeneruj wektor zawierający jedynie sekcje znajdujące się na piętrze dolnym
    sections = reshape(currMat,1,[]); sections = transpose(sections);
    sections = sections.'; sections(:); reshape(sections.',1,[]);
    sections = sort(sections); sectionsCurr = unique(sections);

    sections = reshape(nextMat,1,[]); sections = transpose(sections);
    sections = sections.'; sections(:); reshape(sections.',1,[]);
    sections = sort(sections); sectionsNext = unique(sections);

    %wiersze -> piętro górne, kolumny -> piętro dolne
    conjuctionsMatrix = zeros(size(sectionsNext,2),size(sectionsCurr,2));
    
    for sec = 1:size(sectionsCurr,2)
        k = sectionsCurr(sec);
        for i = 1:size(nextMat,1)
            for j = 1:size(nextMat,1)
                if k == currMat(i,j)
                    conjuctionsMatrix(sectionsNext==nextMat(i,j), sec) = conjuctionsMatrix(sectionsNext==nextMat(i,j), sec) + 1;
                end
            end
        end
    end

matrixNeighbors = [matrixNeighbors zeros(size(matrixNeighbors,1), size(conjuctionsMatrix,2));
                    zeros(size(conjuctionsMatrix,1), size(matrixNeighbors,2)) conjuctionsMatrix];

val1 = size(matrixNeighbors,1) - size(conjuctionsMatrix,1) + 1;
val2 = size(matrixNeighbors,2) - size(conjuctionsMatrix,2) + 1;
sectionsNum = [sectionsNum [val1;val2]];
end

sectionsNum = [sectionsNum [size(matrixNeighbors,1)+1; size(matrixNeighbors,2)+1]];

%Wygeneruj modele każdego piętra i połącz je we wspólne macierze
A = [];
B = [];
C = [];
D = [];
Z = [];
statesVector = [];
flag = [0 ones(1,size(matrixTable,2)-2) 2];
if size(matrixTable,2) == 1 && size(heightTable,2) == 1
        % Budynek posiada pojedyncze piętro
        flag = -1;
        H = table2array(heightTable(:,1));
        matrix = table2array(matrixTable(:,1));
        insulations = [insulationTable(:,1:3) insulationTable(:,5:end)];
        equipment = table2array(roomEquipment(:,1));
        [Am,Bm,Cm,Dm,Zm,N] = generateFloor(matrix, H, insulations, coefficients, equipment, flag);
        nA = size(A,1); nAm = size(Am,1);
        nB = size(B,2); nBm = size(Bm,2);
        nC = size(C,1); nCm = size(Cm,1);
        nZ = size(Z,1); nZcol = size(Z,2); nZm = size(Zm,1); nZmcol = size(Zm,2);
        A = [A zeros(nA, nAm); zeros(nAm, nA) Am];
        B = [B zeros(nA, nBm); zeros(nAm, nB) Bm];  
        C = [C zeros(nC, nAm); zeros(nCm, nA) Cm]; 
        D = Dm;
        Z = [Z zeros(nZ, nZmcol-2); Zm(:,1) zeros(nZm, nZcol-2) Zm(:,2:end)];
        statesVector = [statesVector N+size(A,1)-size(Am,1)];
elseif size(matrixTable,2) > 1 && size(heightTable,2) > 1

    % dla piętra pierwszego do przedostatniego - posiadają stropy
    for i = 1:size(matrixTable,2)-1
        H = table2array(heightTable(:,i));
        matrix = table2array(matrixTable(:,i));
        insulations = [insulationTable(:,1:end-2) insulationTable(:,end)];
        equipment = table2array(roomEquipment(:,i));
        f = flag(i);
        [Am,Bm,Cm,~,Zm,N] = generateFloor(matrix, H, insulations, coefficients, equipment, f);
        nA = size(A,1); nAm = size(Am,1);
        nB = size(B,2); nBm = size(Bm,2);
        nC = size(C,1); nCm = size(Cm,1);
        nZ = size(Z,1); nZcol = size(Z,2); nZm = size(Zm,1); nZmcol = size(Zm,2);
        A = [A zeros(nA, nAm); zeros(nAm, nA) Am];
        B = [B zeros(nA, nBm); zeros(nAm, nB) Bm];  
        C = [C zeros(nC, nAm); zeros(nCm, nA) Cm]; 
        Z = [Z zeros(nZ, nZmcol-2); Zm(:,1) zeros(nZm, nZcol-2) Zm(:,2:end)];
        statesVector = [statesVector N+size(A,1)-size(Am,1)];
    end

    %dla ostatniego piętra - posiada dach zamiast stropu
    H = table2array(heightTable(:,end));
    matrix = table2array(matrixTable(:,end));
    insulations = [insulationTable(:,1:3) insulationTable(:,5:end)];
    equipment = table2array(roomEquipment(:,end));
    f = flag(end);
    [Am,Bm,Cm,Dm,Zm,N] = generateFloor(matrix, H, insulations, coefficients, equipment, f);
    nA = size(A,1); nAm = size(Am,1);
    nB = size(B,2); nBm = size(Bm,2);
    nC = size(C,1); nCm = size(Cm,1);
    nZ = size(Z,1); nZcol = size(Z,2); nZm = size(Zm,1); nZmcol = size(Zm,2);
    A = [A zeros(nA, nAm); zeros(nAm, nA) Am];
    B = [B zeros(nA, nBm); zeros(nAm, nB) Bm];  
    C = [C zeros(nC, nAm); zeros(nCm, nA) Cm]; 
    D = Dm;
    Z = [Z zeros(nZ, nZmcol-2); Zm(:,1) zeros(nZm, nZcol-2) Zm(:,2:end)];
    statesVector = [statesVector N+size(A,1)-size(Am,1)];
else
    disp("Błąd danych podczas tworzenia piętra -> upewnij się, że poprawnie wprowadzono dane")
end

%tutaj kod realizujący łączenie sekcji pomiędzy piętrami
%Zastąp z piętra poniżej stan z sekcji będący temperaturą zewnętrzną stropu
%temperaturą podłogi sekcji znajdującej się powyżej

%statesVector - wektor indeksów od których rozpoczynają się konkretne sekcje
%sectionsNum - wektory indeksów połączeń z macierzy matrixNeighbors
%matrixNeighbors - macierz połączeń pomiędzy sekcjami piętra dolnego oraz
%z sekcjami piętra górnego
%vecStatesNum - wektor indeksów pięter w macierzach

if size(matrixTable,2) > 1 && size(heightTable,2) > 1
    [A,B,C,Z] = model_levelConjuction(A,B,C,Z,matrixNeighbors,sectionsNum,statesVector,insulationTable);
end

end

