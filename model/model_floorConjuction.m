function [A,B,C,Z,vecStatesNum_edited] = model_floorConjuction(A0,B0,C0,Z0,vecNeighbors,insulations,coefficients,vecStatesNum,innerSections)

%Przetransformuj vecNeighbors w taki sposób, aby kolejne występowania ścian
%wewnętrznych w sekcji były oznakowane jako 1 (pierwsze wystąpienie), 2 (drugie wystąpienie)
%3 (trzecie wystąpienie) itd.

cnt = 1;
matrixWallsEnum = zeros(size(vecNeighbors,1),size(vecNeighbors,1));
for i = 1:size(vecNeighbors,1)
    for j = 1:size(vecNeighbors,2)
        x = vecNeighbors(j,i);
        if x ~= 0
            matrixWallsEnum(j,i) = cnt;
            cnt = cnt + 1;
        end
    end
    cnt = 1;
end

%-------------------------------------------------------

%Znajdź indeksy ściany wewnętrznej sekcji oraz odpowiadającej jej indeksy
%ściany wewnętrznej innej sekcji

%Na podstawie macierzy matrixWallsEnum stwórz macierz trójkątną dolną
[rows, cols] = size(matrixWallsEnum);
lowerWallsEnum = zeros(rows, cols);
for i = 1:rows
    for j = 1:cols
        if i >= j
            lowerWallsEnum(i, j) = matrixWallsEnum(i, j);
        end
    end
end

%Na podstawie macierzy matrixWallsEnum stwórz macierz trójkątną górną
upperWallsEnum = zeros(rows, cols); % Inicjalizacja macierzy zerami
for i = 1:rows
    for j = 1:cols
        if i <= j
            upperWallsEnum(i, j) = matrixWallsEnum(i, j);
        end
    end
end

%Dokonaj połączenia sekcji poprzez przepisanie współczynników ściany
%wewnętrznej sekcji nadpisującej do sekcji nadpisywanej
%Kolejność oraz która sekcja jest "nadpisująca", a która nadpisywana jest
%decydowana przez macierz lowerWallsEnum (będąca macierzą trójkątną dolną z matrixWallsEnum)
del_index = [];
for i = 1:size(lowerWallsEnum,1)
    for j = 1:size(lowerWallsEnum,1)
        sectionOverwrittenIndex = vecStatesNum(i);
        sectionOverwrittingIndex = vecStatesNum(j);
        x = lowerWallsEnum(j,i);
        y = upperWallsEnum(i,j);
        if x ~= 0
            idx1_overwritten = sectionOverwrittenIndex + 3 + 2*(x-1);
            idx2_overwritten = sectionOverwrittenIndex + 3 + 2*(x-1) + 1;
            idx2_overwritting = sectionOverwrittingIndex + 3 + 2*(y-1) + 1;

            %Wytłumaczenie: łączymy ścianę wewnętrzną sekcji przyległej z
            %ścianą wewnętrzną aktualnej sekcji. Łączymy poprzez wpływ
            %części zewnętrznej ściany na sekcję aktualną i wpływ aktualnej
            %sekcji na ścianę zewnętrzną.

            %parametry
            vecParam = table2array(insulations(:,2));
            l_mid = sum(vecParam(1,:))/2;
            val = 0; idx = 0;
            for m = 1:size(vecParam(1,:),2)
                if val <= l_mid
                    val = val + vecParam(1,m);
                    idx = idx + 1;
                end
            end
            
            h2 = coefficients(2);
            Cwi = (sum(vecParam(1,1:idx-1) * vecParam(2,1:idx-1)' * vecParam(3,1:idx-1)) + abs(l_mid - sum(vecParam(1,1:idx-1)))*vecParam(2,idx)*vecParam(3,idx));
            Cwo = (sum(vecParam(1,idx:end) * vecParam(2,idx:end)' * vecParam(3,idx:end)) + abs(l_mid - sum(vecParam(1,idx:end)))*vecParam(2,idx)*vecParam(3,idx));

            %wplyw części zewnętrznej na temperaturę sekcji aktualnej
            A0(sectionOverwrittenIndex, idx2_overwritting) = h2/Cwi;
            
            %wpływ temperatury sekcji aktualnej na część zewnętrzną ściany
            A0(idx2_overwritting, sectionOverwrittenIndex) = h2/Cwo;

            %zapisz numery indeksów, które należy usunąć
            del_index = [del_index; idx1_overwritten idx2_overwritten];
        end
    end
end

%-------------------------------------------------------
%Dokonaj korekty macierzy poprzez usunięcie zerowych wierszy i
%kolumn, powstałych z łączenia sekcji w macierzy A oraz usunięcia
%odpowiadających macierzy A wierszy/kolumn z macierzy B, C oraz Z
%Uwaga: teoretycznie można pozostawić zerowe kolumny/wiersze
%kolejność usuwania: kolumny -> wiersze
%numery indeksów do usunięcia: macierz del_index

    %Usuń zerowe wiersze i kolumny dotyczące ścian zewnętrznych w sekcjach
    %nieposiadających ścian zewnętrznych. Wykorzystaj do tego wektor
    %innerSections zawierający informacje czy sekcja jest wewnętrzna.
    %Dopisz do wektora del_index odpowiednie indeksy
    for i = 1:size(innerSections,1)
        check_inner = innerSections(i);
        if check_inner > 0
            %to nic nie rób, sekcja zawiera ściany zewnętrzne
        else
            %do wektora del_index dodaj adresy do usunięcia
            del_index = [vecStatesNum(i)+1 vecStatesNum(i)+2; del_index];
        end
    end

%od lewej kolumny odejmij 1, a do prawej dodaj 1 -> indeksy informują,
%które kolumny/wiersze powinny zostać
%posortuj del_index
del_index(:,1) = del_index(:,1)-1;
del_index(:,2) = del_index(:,2)+1;
del_index = sort(del_index,1);

%zmodyfikuj wektor vecStatesNum, aby indeksy sekcji odzwierciedlały te po modyfikacji macierzy
vecStatesNum_edited = vecStatesNum;
for k = 2:size(vecStatesNum,2)
    check_lowerVal = vecStatesNum(k-1);
    check_higherVal = vecStatesNum(k);

    for i = 1:size(del_index,1)
        val1 = del_index(i,1);
        val2 = del_index(i,2);

        if check_lowerVal <= val1 && check_higherVal >= val2
            vecStatesNum_edited(k:end) = vecStatesNum_edited(k:end) - (val2-val1-1); 
        end
    end
end

%----------------------------------------------------

%kolumny A
A0_part1 = A0(:,1:del_index(1,1));
A0_part2 = [];
for i = 2:size(del_index,1)
    mat = [A0(:,del_index(i-1,2):del_index(i,1))];
    A0_part2 = [A0_part2 mat];
end
A0_part3 = A0(:,del_index(end,end):end);
A0 = [A0_part1 A0_part2 A0_part3];

%wiersze A
A0_part1 = A0(1:del_index(1,1),:);
A0_part2 = [];
for i = 2:size(del_index,1)
    mat = A0(del_index(i-1,2):del_index(i,1),:);
    A0_part2 = [A0_part2; mat];
end
A0_part3 = A0(del_index(end,end):end,:);
A0 = [A0_part1; A0_part2; A0_part3];
%----------------------------------------------------

%wiersze B
B0_part1 = B0(1:del_index(1,1),:);
B0_part2 = [];
for i = 2:size(del_index,1)
    mat = B0(del_index(i-1,2):del_index(i,1),:);
    B0_part2 = [B0_part2; mat];
end
B0_part3 = B0(del_index(end,end):end,:);
B0 = [B0_part1; B0_part2; B0_part3];
%----------------------------------------------------

%kolumny C
C0_part1 = C0(:,1:del_index(1,1));
C0_part2 = [];
for i = 2:size(del_index,1)
    mat = [C0(:,del_index(i-1,2):del_index(i,1))];
    C0_part2 = [C0_part2 mat];
end
C0_part3 = C0(:,del_index(end,end):end);
C0 = [C0_part1 C0_part2 C0_part3];
%----------------------------------------------------

%wiersze Z
Z0_part1 = Z0(1:del_index(1,1),:);
Z0_part2 = [];
for i = 2:size(del_index,1)
    mat = Z0(del_index(i-1,2):del_index(i,1),:);
    Z0_part2 = [Z0_part2; mat];
end
Z0_part3 = Z0(del_index(end,end):end,:);
Z0 = [Z0_part1; Z0_part2; Z0_part3];
%----------------------------------------------------

A = A0;
B = B0;
C = C0;
Z = Z0;

end

