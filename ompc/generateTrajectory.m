function [trajFull, trajHorizon, trajCurrent] = generateTrajectory(values,flag,time,Ts,na,index)

%flag = 1 ~ przebieg prostokątny
%flag = 2 ~ interpolacja liniowa
N = size(values,2);
M = size(values,1);
trajSingle = zeros(1,0);
trajFull = zeros(N,0);
trajExtended = zeros(N,0);
trajHorizon = zeros(0,1);
idx = index;

if flag == 1
    %Wygeneruj pełne trajektorie
    for i = 1:M
        for j = 1:N
            trajSingle = [trajSingle linspace(values(i,j),values(i,j),ceil(time/Ts/N))];
        end
        trajFull = [trajFull;trajSingle];
        trajSingle = zeros(1,0);
    end
    
    %Wydłuż wektor trajFull o na kroków
    for i = 1:M
        trajSingle = [trajSingle linspace(values(i,end),values(i,end),na)];
        trajExtended = [trajExtended;trajSingle];
        trajSingle = zeros(1,0);
    end
    trajFull = [trajFull trajExtended];
else
    %Wygeneruj pełne trajektorie
    for i = 1:M
        for j = 2:N
            trajSingle = [trajSingle linspace(values(i,j-1),values(i,j),ceil(time/Ts/N))];
        end
        trajFull = [trajFull;trajSingle];
        trajSingle = zeros(1,0);
    end
    for i = 1:M
        trajSingle = [trajSingle linspace(values(i,end),values(i,end),ceil(time/Ts/N))];
        trajExtended = [trajExtended;trajSingle];
        trajSingle = zeros(1,0);
    end
    trajFull = [trajFull trajExtended];
    trajExtended = zeros(N,0);
    
    %Wydłuż wektor trajFull o 'na' kroków
    for i = 1:M
        trajSingle = [trajSingle linspace(values(i,end),values(i,end),na)];
        trajExtended = [trajExtended;trajSingle];
        trajSingle = zeros(1,0);
    end
    trajFull = [trajFull trajExtended];
    
    % Wygładź przebiegi
    trajFull(1,:) = movmean(trajFull(1,:),5);
    trajFull(2,:) = movmean(trajFull(2,:),1);
end

%Wygeneruj trajektorie dla horyzontu od 'index' do 'na'
for k = 1:na
    trajHorizon = [trajHorizon; trajFull(:,idx)];
    idx = idx+1;
end

%Wygeneruj wektor aktualnych wartości zadanych
trajCurrent = trajFull(:,index);


