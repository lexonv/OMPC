function [A,B,C,Z] = model_levelConjuction(A0,B0,C0,Z0,matrixNeighbors,sectionsNum,statesVector,insulationsTable)
% Zmodyfikuj indeksy początkowe sekcji aby wskazywały na ostatni stan w sekcji
statesVector_modified = statesVector;
for i = 1:size(statesVector_modified,2)-1
    statesVector_modified(i) = statesVector_modified(i+1) - 1;
end
statesVector_modified(end) = size(A0,2);

matrixEnums = [];
for k = 1:size(sectionsNum,2)-1
    matrix = matrixNeighbors(sectionsNum(1,k):sectionsNum(1,k+1)-1, sectionsNum(2,k):sectionsNum(2,k+1)-1);
    template = zeros(size(matrix,1), size(matrix,2));
    cnt = 1;
    for i = 1:size(matrix,2)
        for j = 1:size(matrix,1)
            x = matrix(j,i);
            if x ~= 0
                template(j,i) = cnt;
            end
            cnt = cnt + 1;
        end
        cnt = 1;
    end
    matrixEnums = [matrixEnums zeros(size(matrixEnums,1), size(template,2));zeros(size(template,1), size(matrixEnums,2)) template];
end

for k = 1:size(sectionsNum,2)-1
    matrix = matrixEnums(sectionsNum(1,k):sectionsNum(1,k+1)-1, sectionsNum(2,k):sectionsNum(2,k+1)-1);
    offset_lower = sectionsNum(2,2) - sectionsNum(2,1);
    
    indexUpper_end = statesVector_modified(offset_lower+sectionsNum(1,k):offset_lower+sectionsNum(1,k+1)-1);
    indexLower_end = statesVector_modified(sectionsNum(2,k):sectionsNum(2,k+1)-1);

    for col = 1:size(matrix,2)
        for row = 1:size(matrix,1)
            x = matrix(row,col);

            if x ~= 0
                idx_overwritting = indexUpper_end(row)-1; %wskazuje na podłogę sekcji górnej
                idx_overwrite = indexLower_end(col) - 2; %wskazuje na część zewnętrzną stropu sekcji dolnej
                

                vecParam = table2array(insulationsTable(:,4));
                l_mid = sum(vecParam(1,:))/2;
                val = 0; idx = 0;
                for i = 1:size(vecParam(1,:),2)
                    if val <= l_mid
                        val = val + vecParam(1,i);
                        idx = idx + 1;
                    end
                end
                Cso = (sum(vecParam(1,idx:end) * vecParam(2,idx:end)' * vecParam(3,idx:end)) + abs(l_mid - sum(vecParam(1,idx:end)))*vecParam(2,idx)*vecParam(3,idx));
                Rso = 0;
                for i = idx:size(vecParam,2)
                    Rso = Rso + vecParam(1,i)/vecParam(4,i);
                end
                
                vecParam = table2array(insulationsTable(:,3));

                Cp = sum(vecParam(1,:) * vecParam(2,:)' * vecParam(3,:));

                Rp = 0;
                for i = 1:size(vecParam,2)
                    Rp = Rp + vecParam(1,i)/vecParam(4,i);
                end

                % łączenie stropu zewnętrznego (sekcja dolna) z podłogą (sekcja górna)
                A0(idx_overwrite,idx_overwritting) = 1/Cso * 1/(Rp+Rso);

                % łączenie podłogi (sekcja górna) z stropem zewnętrznym (sekcja dolna)
                A0(idx_overwritting,idx_overwrite) = 1/Cp * 1/(Rp+Rso);
            end
        end
    end
end

A = A0;
B = B0;
C = C0;
Z = Z0;
end

