function Cobserver = create_Cobserver_matrix(C, statesIndex)

nx = size(C,2);
ny =  2*size(statesIndex,2); %mierzone stany - temperatura sekcji i temperatura wody powracającej
Cobserver = zeros(ny,nx);
statesIndex = [statesIndex nx+1];

observable_states = [];
for i = 1:size(statesIndex,2)-1
    observable_states = [observable_states statesIndex(i) statesIndex(i+1)-1]; 
end

for i = 1:size(observable_states,2)
    Cobserver(i,observable_states(i)) = 1;
end