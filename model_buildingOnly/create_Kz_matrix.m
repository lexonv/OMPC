function Kz = create_Kz_matrix(A, C, Z, na)
[nx, ~] = size(A);
[ny, ~] = size(C);
[~, nd] = size(Z);
Kz = zeros(ny * na, nd * na);

A_power_Z = cell(na, 1);
for k = 1:na
    A_power_Z{k} = zeros(nx, nd);
end
A_power_Z{1} = Z;

for k = 2:na
    A_power_Z{k} = A * A_power_Z{k-1}; % Oblicz A^(k-1) * Z
end

% Wypełnianie macierzy Kz
for i = 1:na
    for j = 1:na
        if j < i
            exponent = i - j - 1;
            Kz_block = C * A_power_Z{exponent + 1};
        else
            Kz_block = zeros(ny, nd);
        end

        row_range = (i-1)*ny + 1 : i*ny;
        col_range = (j-1)*nd + 1 : j*nd;
        Kz(row_range, col_range) = Kz_block;
    end
end
end