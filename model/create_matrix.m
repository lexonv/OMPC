function M = create_matrix(Kz, na)
    [rows, cols] = size(Kz);
    num_blocks = na;

    M = zeros(num_blocks * rows, num_blocks * cols);
    for i = 1:num_blocks
        row_idx = (i-1)*rows + 1;
        col_idx = (i-1)*cols + 1;
        M(row_idx:row_idx+rows-1, col_idx:col_idx+cols-1) = Kz;
    end
end