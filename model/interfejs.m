function [N] = interfejs(matrix)

%N - ile pomieszczeń
N = 0;
column = size(matrix,2);
row = size(matrix,1);

%oblicz liczbę pomieszczeń
for i = 1:row
    for j = 1:column
        if matrix(i,j) == 1
            N = N + 1;
        end
    end
end

for i = 1:row
    for j = 1:column

        %1) sprawdź czy aktualne indeksy wskazują na rogi macierzy4
        %2) sprawdź czy znajdują się 1 obok aktualnego adresu

        if i == 1 && j == 1
            column_down = matrix(i+1,j);
            row_right = matrix(i,j+1);
            disp(string(i) + " " + string(j) + "-> corner")
        elseif i == size(matrix,1) && j == 1
            column_up = matrix(i-1,j);
            row_right = matrix(i,j+1);
            disp(string(i) + " " + string(j) + "-> corner")
        elseif i == 1 && j == size(matrix,2)
            column_down = matrix(i+1,j);
            row_left = matrix(i,j-1);
            disp(string(i) + " " + string(j) + "-> corner")
        elseif i == size(matrix,1) && j == size(matrix,2)
            column_up = matrix(i-1,j);
            row_left = matrix(i,j-1);
            disp(string(i) + " " + string(j) + "-> corner")
        elseif i == 1 && j ~= 1 && j ~= size(matrix,2)
            column_down = matrix(i+1,j);
            row_left = matrix(i,j-1);
            row_right = matrix(i,j+1);
            disp(string(i) + " " + string(j) + "-> edge")
        elseif i == size(matrix,1) && j ~= 1 && j ~= size(matrix,2)
            column_up = matrix(i-1,j);
            row_left = matrix(i,j-1);
            row_right = matrix(i,j+1);
            disp(string(i) + " " + string(j) + "-> edge")
        elseif i ~= 1 && i ~= size(matrix,1) && j == 1
            column_up = matrix(i-1,j);
            column_down = matrix(i+1,j);
            row_right = matrix(i,j+1);
            disp(string(i) + " " + string(j) + "-> edge")
        elseif i ~= 1 && i ~= size(matrix,1) && j == size(matrix,2)
            column_up = matrix(i-1,j);
            column_down = matrix(i+1,j);
            row_left = matrix(i,j-1);
            disp(string(i) + " " + string(j) + "-> edge")
        else
            row_left = matrix(i,j-1);
            row_right = matrix(i,j+1);
            column_up = matrix(i-1,j);
            column_down = matrix(i+1,j);
            disp(string(i) + " " + string(j) + "-> normal")
        end
    end
end


end

