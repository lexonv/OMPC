%Przyjete oznaczenia sekcji:
% -1 - czesc zewnetrzna (otoczenie), duze wahania temperatur
%  0 - czesc wewnetrzna nieogrzewana (nie posiada wejścia)
% 1:N - czesc wewnetrzna ogrzewana

%1) Kroki do wygenerowania odrębnych modeli sekcji:
    %- odczytaj z macierzy matrix ilość sekcji dla pojedynczego piętra
    %- policz dla każdej sekcji, ile znajduje się przypisanych do niej pól (oblicz pole powierzchni sekcji)
    %- sprawdź dla każdej sekcji sąsiedzctwo sekcji N z pozostałymi sekcjami i oblicz długość pól tworzących sąsiedztwo
    %- wygeneruj parametry zgodnie z wprowadzonymi wymiarami sekcji, ścian
    %  zewnętrznych, wewnętrznych itd.
    %- wygeneruj odrębne modele sekcji, zapisz informacje o liczbie stanów
    %  wygenerowanej sekcji do odrębnego wektora
    %- połącz uzyskane modele we wspólne macierze A,B,C,D,Z
%2) Kroki do wygenerowania jednolitego modelu budynku
    %- na podstawie uzyskanych macierzy A,B,C,D,Z oraz macierzy opisującej
    %  sąsiedzctwo pomiędzy sekcjami (vecNeighbors) jak i macierzy
    %  określającej indeks w którym dana sekcja się rozpoczyna w macierzy A
    %  (wektor vecStatesNum) przeprowadź proces łączenia sekcji
    %- na podstawie macierzy vecNeighbors stwórz nową macierz (matrixWallsEnum) opisującą
    %  kolejność występowania ścian wewnętrznych w i-tej sekcji. Zamień tą
    %  macierz na dwie macierze: trójkątną dolną oraz trójkątną górną.
    %- z macierzy matrixWallsEnum odczytaj połączenie 

%UWAGA: Algorytm nie jest przystosowany do interpretacji sekcji typu:
%
% [1 1 1 1 1]
% [1 2 2 1 1]
% [1 1 1 1 1]
% [1 1 2 2 1]
% [1 1 1 1 1]
% 
% oraz gdzie w macierzy znajduje się tylko jedna sekcja (np. same jedynki):
% 
% [1 1 1]
% [1 1 1]
% [1 1 1]
%
% Sekcje rozdzielone (sekcja nr 2), czyli bezpośrednio niełączące się w całość
% interpretowane są jako jedna sekcja.
%
% Kolejność sekcji w macierzy A, B, C, Z jest numeryczna, tzn. na pierwszym miejscu
% jest sekcja 0, potem sekcja 1, 2, 3 itd.
%
% parametr scaleLength - decyduje o rozdziałce macierzy (długości)
% parametr H - decyduje o wysokości sekcji (np. wysokość piętra)
% przykładowo:
% dla scaleLength = 1 pojedyncze pole w macierzy to 1x1 [m]
% dla scaleLength = 0.5 pojedyncze pole w macierzy to 0.5x0.5 [m]
% dla scaleLength = 0.25 pojedyncze pole w macierzy to 0.25x0.25 [m]
% scaleLength dotyczy macierzy/wektorów:
%   1) vecArea (pole sekcji)
%   2) vecNeighbors (sąsiedztwa sekcji oraz długości ścian)

% matrix = [0 0 2 2; 1 1 3 2; 1 3 3 4; 1 3 3 4];
% materialThickness = [0.07 0.0125 0.25 0.0125]; materialDensity = [30 1050 30 1050]; materialSpecificHeat = [1500 1200 1200 1200]; materialThermalCoeff = [0.035 0.45 0.045 0.45];
% insulationExternal = [materialThickness;materialDensity;materialSpecificHeat;materialThermalCoeff];
% 
% materialThickness = [0.0125 0.05 0.0125]; materialDensity = [1050 700 1050]; materialSpecificHeat = [1200 1600 1200]; materialThermalCoeff = [0.45 0.15 0.45];
% insulationInternal = [materialThickness;materialDensity;materialSpecificHeat;materialThermalCoeff];
% 
% materialThickness = [0.005 0.0125]; materialDensity = [1800 2000]; materialSpecificHeat = [1000 840]; materialThermalCoeff = [0.2 1.4];
% insulationFloor = [materialThickness;materialDensity;materialSpecificHeat;materialThermalCoeff];
% 
% materialThickness = [0.05 0.0125 0.25 0.0125]; materialDensity = [30 1050 2500 1050]; materialSpecificHeat = [1500 1200 1000 1200]; materialThermalCoeff = [0.035 0.45 1.5 0.45];
% insulationCeiling = [materialThickness;materialDensity;materialSpecificHeat;materialThermalCoeff];
% 
% materialThickness = [0.07 0.0125 0.25 0.0125]; materialDensity = [30 1050 30 1050]; materialSpecificHeat = [1500 1200 1200 1200]; materialThermalCoeff = [0.035 0.45 0.045 0.45];
% insulationRoof = [materialThickness;materialDensity;materialSpecificHeat;materialThermalCoeff];
% 
% insulationTable = table(insulationExternal, insulationInternal, insulationFloor, insulationCeiling, insulationRoof);
% H = 1;
% flag = -1;
% [A,B,C,D,Z,vecStatesNum] = generateFloor(matrix, H, insulationTable, coefficients, flag);


function [A,B,C,D,Z,vecStatesNum,exteriorWaLLStates] = generateFloor(matrix, H, insulations, coefficients, equipment, flag)

%wprowadź otoczenie do macierzy (wartości -1 na obrysach macierzy jako otoczenie zewnętrzne)
n = size(matrix,1);
matrix = [-ones(1,n);matrix];
matrix = [matrix,-ones(n+1,1)];
matrix = [matrix;-ones(1,n+1)];
matrix = [-ones(n+2,1),matrix];

%-----------------------

col = size(matrix,2);
row = size(matrix,1);

%------------------------
%kolejność [0 -1 [sekcje ogrzewane]]
sections = reshape(matrix,1,[]);
sections = transpose(sections);
sections = sections.';
sections(:);
reshape(sections.',1,[]);
sections = [0, sections]; %dodaj 0 dla elementów wewnętrznych nieogrzewanych (nawet jak ich nie ma)
sections = sort(sections);
sections = unique(sections);
%------------------------

vecArea = zeros(1,size(sections,2));
n = 0;
for sec = 1:size(sections,2)
    k = sections(sec);
    n = n+1;
    for i = 1:row
        for j = 1:col
            if matrix(i,j) == k
                vecArea(1,n) = vecArea(1,n) + 1;
            end
        end
    end
end

vecNeighbors = zeros(size(sections,2),size(sections,2));
n = 0;
for sec = 1:size(sections,2)
k = sections(sec);
disp(" ")
disp("=== Dla elementu: " + k + "===")
n = n+1;
    for i = 1:row
        for j = 1:col
            if matrix(i,j) == k
                %lewy górny róg
                if i == 1 && j == 1
                    checkRight = matrix(i,j+1);
                    checkDown = matrix(i+1,j);
                    disp("---------")
                    disp("Element: " + k + " ("+i+","+j+")");
                    disp("checkRight: " + checkRight);
                    disp("checkDown: " + checkDown);
                    if checkRight ~= k
                        vecNeighbors(n,sections==checkRight) = vecNeighbors(n,sections==checkRight) + 1;
                    end
                    if checkDown ~= k
                        vecNeighbors(n,sections==checkDown) = vecNeighbors(n,sections==checkDown) + 1;
                    end
                %prawy górny róg
                elseif i == 1 && j == col
                    checkLeft = matrix(i,j-1);
                    checkDown = matrix(i+1,j);
                    disp("checkLeft: " + checkLeft);
                    disp("checkDown: " + checkDown);
                    if checkLeft ~= k
                        vecNeighbors(n,sections==checkLeft) = vecNeighbors(n,sections==checkLeft) + 1;
                    end
                    if checkDown ~= k
                        vecNeighbors(n,sections==checkDown) = vecNeighbors(n,sections==checkDown) + 1;
                    end
                %prawy dolny róg
                elseif i == row && j == col
                    checkLeft = matrix(i,j-1);
                    checkUp = matrix(i-1,j);
                    disp("---------")
                    disp("Element: " + k + " ("+i+","+j+")");
                    disp("checkLeft: " + checkLeft);
                    disp("checkUp: " + checkUp);
                    if checkLeft ~= k
                        vecNeighbors(n,sections==checkLeft) = vecNeighbors(n,sections==checkLeft) + 1;
                    end
                    if checkUp ~= k
                        vecNeighbors(n,sections==checkUp) = vecNeighbors(n,sections==checkUp) + 1;
                    end
                %lewy dolny róg
                elseif i == row && j == 1
                    checkRight = matrix(i,j+1);
                    checkUp = matrix(i-1,j);
                    disp("---------")
                    disp("Element: " + k + " ("+i+","+j+")");
                    disp("checkRight: " + checkRight);
                    disp("checkUp: " + checkUp);
                    if checkRight ~= k
                        vecNeighbors(n,sections==checkRight) = vecNeighbors(n,sections==checkRight) + 1;
                    end
                    if checkUp ~= k
                        vecNeighbors(n,sections==checkUp) = vecNeighbors(n,sections==checkUp) + 1;
                    end
                %górna krawędź
                elseif i == 1 && j ~= 1 && j ~= col
                    checkRight = matrix(i,j+1);
                    checkLeft = matrix(i,j-1);
                    checkDown = matrix(i+1,j);
                    disp("---------")
                    disp("Element: " + k + " ("+i+","+j+")");
                    disp("checkRight: " + checkRight);
                    disp("checkLeft: " + checkLeft);
                    disp("checkDown: " + checkDown);
                    if checkRight ~= k
                        vecNeighbors(n,sections==checkRight) = vecNeighbors(n,sections==checkRight) + 1;
                    end
                    if checkLeft ~= k
                        vecNeighbors(n,sections==checkLeft) = vecNeighbors(n,sections==checkLeft) + 1;
                    end
                    if checkDown ~= k
                        vecNeighbors(n,sections==checkDown) = vecNeighbors(n,sections==checkDown) + 1;
                    end
                %prawa krawędź
                elseif i ~= 1 && i ~= row  && j == col
                    checkLeft = matrix(i,j-1);
                    checkUp = matrix(i-1,j);
                    checkDown = matrix(i+1,j);
                    disp("---------")
                    disp("Element: " + k + " ("+i+","+j+")");
                    disp("checkLeft: " + checkLeft);
                    disp("checkUp: " + checkUp);
                    disp("checkDown: " + checkDown);
                    if checkLeft ~= k
                        vecNeighbors(n,sections==checkLeft) = vecNeighbors(n,sections==checkLeft) + 1;
                    end
                    if checkUp ~= k
                        vecNeighbors(n,sections==checkUp) = vecNeighbors(n,sections==checkUp) + 1;
                    end
                    if checkDown ~= k
                        vecNeighbors(n,sections==checkDown) = vecNeighbors(n,sections==checkDown) + 1;
                    end
                %dolna krawędź
                elseif i == row && j ~= 1 && j ~= col
                    checkRight = matrix(i,j+1);
                    checkLeft = matrix(i,j-1);
                    checkUp = matrix(i-1,j);
                    disp("---------")
                    disp("Element: " + k + " ("+i+","+j+")");
                    disp("checkRight: " + checkRight);
                    disp("checkLeft: " + checkLeft);
                    disp("checkUp: " + checkUp);
                    if checkRight ~= k
                        vecNeighbors(n,sections==checkRight) = vecNeighbors(n,sections==checkRight) + 1;
                    end
                    if checkLeft ~= k
                        vecNeighbors(n,sections==checkLeft) = vecNeighbors(n,sections==checkLeft) + 1;
                    end
                    if checkUp ~= k
                        vecNeighbors(n,sections==checkUp) = vecNeighbors(n,sections==checkUp) + 1;
                    end
                %lewa krawędź
                elseif i ~= 1 && i ~= row  && j == 1
                    checkRight = matrix(i,j+1);
                    checkUp = matrix(i-1,j);
                    checkDown = matrix(i+1,j);
                    disp("---------")
                    disp("Element: " + k + " ("+i+","+j+")");
                    disp("checkRight: " + checkRight);
                    disp("checkUp: " + checkUp);
                    disp("checkDown: " + checkDown);
                    if checkRight ~= k
                        vecNeighbors(n,sections==checkRight) = vecNeighbors(n,sections==checkRight) + 1;
                    end
                    if checkUp ~= k
                        vecNeighbors(n,sections==checkUp) = vecNeighbors(n,sections==checkUp) + 1;
                    end
                    if checkDown ~= k
                        vecNeighbors(n,sections==checkDown) = vecNeighbors(n,sections==checkDown) + 1;
                    end
                %środek
                elseif i ~= 1 && i ~= row  && j ~= 1 && j ~= col
                    checkRight = matrix(i,j+1);
                    checkLeft = matrix(i,j-1);
                    checkUp = matrix(i-1,j);
                    checkDown = matrix(i+1,j);
                    disp("---------")
                    disp("Element: " + k + " ("+i+","+j+")");
                    disp("checkRight: " + checkRight);
                    disp("checkLeft: " + checkLeft);
                    disp("checkUp: " + checkUp);
                    disp("checkDown: " + checkDown);
                    if checkRight ~= k
                        vecNeighbors(n,sections==checkRight) = vecNeighbors(n,sections==checkRight) + 1;
                    end
                    if checkLeft ~= k
                        vecNeighbors(n,sections==checkLeft) = vecNeighbors(n,sections==checkLeft) + 1;
                    end
                    if checkUp ~= k
                        vecNeighbors(n,sections==checkUp) = vecNeighbors(n,sections==checkUp) + 1;
                    end
                    if checkDown ~= k
                        vecNeighbors(n,sections==checkDown) = vecNeighbors(n,sections==checkDown) + 1;
                    end
                %obsługa błędu
                else
                    error("[ERROR] Błąd w pętli - nie zidentyfikowano elementu macierzy")
                end
            end
        end
    end
end

%Generacja modeli sekcji (ster. temp.)
%param - wektor parametrow
%vecNeighbors - wektor dlugosci (powierzchni) scian sasiadujacych
%vecArea - wektor powierzchni sekcji
%sekcje rozpoczynają się od indeksu "3"
A = [];
B = [];
C = [];
D = [];
Z = [];
vecStatesNum = []; %zapis liczby stanów
m = 1;
%wygeneruj sekcje dla której nie będzie realizowane ogrzewanie (może to być np. korytarz)
%indeks takiej sekcji to 2 i oznakowane jest jako 0. Główna różnica jest w
%macierzy B, ponieważ nie istnieje wejście dla tej sekcji. Jeżeli wektor vecNeighbors jest
%zerowy (tzn. nie ma w budynku sekcji nieogrzewanej), to pomiń jej tworzenie.

if vecNeighbors(2,:) == zeros(1,size(vecNeighbors,2))
    %pomiń tworzenie sekcji zerowej
else
    eq = equipment(:,m); m = m+1;
    [param,n] = model_parameters(vecNeighbors(2,:), vecArea(1,2), H, flag, insulations, coefficients);
    [Am,Bm,Cm,Dm,Zm] = generateRoom(param,n,H,vecNeighbors(2,:),vecArea(1,2),"nieogrzewana",flag,insulations,coefficients,eq);
    nA = size(A,1); nAm = size(Am,1);
    nB = size(B,2); nBm = size(Bm,1);
    nC = size(C,1); nCm = size(Cm,1);
    nZ = size(Z,1); nZcol = size(Z,2); nZm = size(Zm,1);

    A = [Am zeros(nAm, nA); zeros(nA, nAm) A];
    B = [zeros(nBm,nB); B];  
    C = [zeros(nC,nCm);C];
    D = Dm;
    Z = [Z zeros(nZ,1); Zm(:,1:2) zeros(nZm,nZcol-2) Zm(:,3)];
    vecStatesNum = [vecStatesNum size(A,1)-size(Am,1)];
end

%Wygeneruj pozostałe sekcje
for i = 3:size(vecNeighbors,2)
    eq = equipment(:,m); m = m+1;
    [param,n] = model_parameters(vecNeighbors(i,:), vecArea(1,i), H, flag, insulations, coefficients);
    [Am,Bm,Cm,Dm,Zm] = generateRoom(param,n,H,vecNeighbors(i,:),vecArea(1,i),"sekcja",flag,insulations,coefficients,eq);
    nA = size(A,1); nAm = size(Am,1);
    nB = size(B,2); nBm = size(Bm,2);
    nC = size(C,1); nCm = size(Cm,1);
    nZ = size(Z,1); nZcol = size(Z,2); nZm = size(Zm,1);
    A = [A zeros(nA, nAm); zeros(nAm, nA) Am];
    B = [B zeros(nA, nBm); zeros(nAm, nB) Bm];  
    C = [C zeros(nC, nAm); zeros(nCm, nA) Cm]; 
    D = Dm;
    Z = [Z zeros(nZ,1); Zm(:,1:2) zeros(nZm,nZcol-2) Zm(:,3)];
    vecStatesNum = [vecStatesNum size(A,1)-size(Am,1)];
end

vecStatesNum = vecStatesNum + 1; %przesun o jeden aby indeksy sie zgadzaly

%Upraszczanie modelu i łączenie sekcji tworzących piętro budynku:
% - vecNeighbors przechowuje informacje na temat ilości ścian wewnętrznych
%   w sekcji oraz połączeń pomiędzy sekcjami. 
% - Ignorujemy pierwszy wiersz vecNeighbors ponieważ dotyczy on połączeń sekcja<->otoczenie zewnętrzne.
% - Wiersz drugi zostanie obsłużony na końcu - dotyczy sekcji budynku nieposiadającej ogrzewania
% - Jeżeli piętro posiada tylko jedno pomieszczenie, pomiń łączenie
if size(vecStatesNum,2) > 1
    if vecNeighbors(2,:) == zeros(1,size(vecNeighbors,2))
        %Jeżeli model nie zawiera sekcji nieogrzewanych (oznaczonych jako 0):
        innerSections = vecNeighbors(3:end,1);
        [A,B,C,Z,vecStatesNum] = model_floorConjuction(A,B,C,Z,vecNeighbors(3:end,3:end),insulations,coefficients,vecStatesNum,innerSections);
    else
        %Jeżeli model zawiera sekcje nieogrzewane (oznaczone jako 0):
        innerSections = vecNeighbors(2:end,1);
        [A,B,C,Z,vecStatesNum] = model_floorConjuction(A,B,C,Z,vecNeighbors(2:end,2:end),insulations,coefficients,vecStatesNum,innerSections);
    end
end

% Wygeneruj wektor przechowujący informację które pomieszczenia posiadają
% ściany zewnętrzne
exteriorWaLLStates = [];
for i = 2:size(vecNeighbors,1)
    if vecNeighbors(i,:) == zeros(1,size(vecNeighbors,2))
    else
        check = vecNeighbors(i,1);
        if check > 0
            exteriorWaLLStates = [exteriorWaLLStates 1];
        else
            exteriorWaLLStates = [exteriorWaLLStates 0];
        end
    end
end

end
