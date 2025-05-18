function Cobserver = create_Cobserver_matrix(C, statesIndex, vecUnheatedFloors)

statesIndex = [statesIndex size(C,2)+1];

observable_states = [];
for i = 1:size(statesIndex,2)-1
    if vecUnheatedFloors(i) == 1
        observable_states = [observable_states statesIndex(i)];
    elseif vecUnheatedFloors(i) == 0
        observable_states = [observable_states statesIndex(i) statesIndex(i+1)-1];
    end 
end

Cobserver = zeros(size(observable_states,2),size(C,2));

for i = 1:size(observable_states,2)
    Cobserver(i,observable_states(i)) = 1;
end