function [x0,xmax,xmin] = initialStates(nx,statesInit,statesConstr,statesIndex,exWalls,roofSt,vecUnheatedFloors)

Ta0 = statesInit(1); %temperatura sekcji
Tzi0 = statesInit(2); Tzo0 = statesInit(3); %temperatury wewnętrzna/zewnętrza ściany zewnętrznej
Twi0 = statesInit(4); Two0 = statesInit(5); %temperatury wewnętrzna/zewnętrza ściany wewnętrznej
Tp0 = statesInit(6); %temperatura podłogi
T_return0 = statesInit(7);

Ta_max = statesConstr(1); Ta_min = statesConstr(2); %ograniczenia temp. pomieszczen
Twall_max = statesConstr(3); Twall_min = statesConstr(4); %ograniczenia temp. scian
Tp_max = statesConstr(5); Tp_min = statesConstr(6); %ograniczenia temp. podlogi
T_return_max = statesConstr(7); T_return_min = statesConstr(8);
N = statesIndex;

x0 = [];
xmax = [];
xmin = [];
for i = 2:size(N,2)
    m = N(i-1);
    n = N(i);
    cnt = ((n - m) - 5 )/2; %liczba ścian zewnętrznych + wewnętrznych
    exwall = exWalls(i-1);
    unheated = vecUnheatedFloors(i-1);
    roof = roofSt(i-1);
    states0 = [];
    xmax0 = [];
    xmin0 = [];

    if exwall == 1
        states0 = [states0 Tzi0 Tzo0];
        xmax0 = [xmax0 Twall_max Twall_max];
        xmin0 = [xmin0 Twall_min Twall_min];
        for j = 1:cnt-1
            states0 = [states0 Twi0 Two0];
            xmax0 = [xmax0 Twall_max Twall_max];
            xmin0 = [xmin0 Twall_min Twall_min];
        end
        if roof == 1
            if unheated == 1
                x0 = [x0 [Ta0 states0 Tzi0 Tzo0 Tp0 T_return0]];
                xmax = 10000*abs([xmax [Ta_max xmax0 Twall_max Twall_max Tp_max T_return_max]]);
                xmin = -10000*abs([xmin [Ta_min xmin0 Twall_min Twall_min Tp_min T_return_min]]);
            else
                x0 = [x0 [Ta0 states0 Tzi0 Tzo0 Tp0 T_return0]];
                xmax = [xmax [Ta_max xmax0 Twall_max Twall_max Tp_max T_return_max]];
                xmin = [xmin [Ta_min xmin0 Twall_min Twall_min Tp_min T_return_min]];
            end
        else
            if unheated == 1
                x0 = [x0 [Ta0 states0 Twi0 Two0 Tp0 T_return0]];
                xmax = 10000*abs([xmax [Ta_max xmax0 Twall_max Twall_max Tp_max T_return_max]]);
                xmin = -10000*abs([xmin [Ta_min xmin0 Twall_min Twall_min Tp_min T_return_min]]);
            else
                x0 = [x0 [Ta0 states0 Twi0 Two0 Tp0 T_return0]];
                xmax = [xmax [Ta_max xmax0 Twall_max Twall_max Tp_max T_return_max]];
                xmin = [xmin [Ta_min xmin0 Twall_min Twall_min Tp_min T_return_min]];
            end
        end
    else
    for j = 1:cnt
        states0 = [states0 Twi0 Two0];
        xmax0 = [xmax0 Twall_max Twall_max];
        xmin0 = [xmin0 Twall_min Twall_min];
    end
        if roof == 1
            if unheated == 1
                x0 = [x0 [Ta0 states0 Tzi0 Tzo0 Tp0 T_return0]];
                xmax = 10000*abs([xmax [Ta_max xmax0 Twall_max Twall_max Tp_max T_return_max]]);
                xmin = -10000*abs([xmin [Ta_min xmin0 Twall_min Twall_min Tp_min T_return_min]]);
            else
                x0 = [x0 [Ta0 states0 Tzi0 Tzo0 Tp0 T_return0]];
                xmax = [xmax [Ta_max xmax0 Twall_max Twall_max Tp_max T_return_max]];
                xmin = [xmin [Ta_min xmin0 Twall_min Twall_min Tp_min T_return_min]];
            end
        else
            if unheated == 1
                x0 = [x0 [Ta0 states0 Twi0 Two0 Tp0 T_return0]];
                xmax = 10000*abs([xmax [Ta_max xmax0 Twall_max Twall_max Tp_max T_return_max]]);
                xmin = -10000*abs([xmin [Ta_min xmin0 Twall_min Twall_min Tp_min T_return_min]]);
            else
                x0 = [x0 [Ta0 states0 Twi0 Two0 Tp0 T_return0]];
                xmax = [xmax [Ta_max xmax0 Twall_max Twall_max Tp_max T_return_max]];
                xmin = [xmin [Ta_min xmin0 Twall_min Twall_min Tp_min T_return_min]];
            end
        end
    end
end

cnt = ((nx - size(x0,2))-4)/2;
exwall = exWalls(end);
roof = roofSt(end);
unheated = vecUnheatedFloors(end);
states0 = [];
xmax0 = [];
xmin0 = []; 
if exwall == 1
    states0 = [states0 Tzi0 Tzo0];
    xmax0 = [xmax0 Twall_max Twall_max];
    xmin0 = [xmin0 Twall_min Twall_min];
        for j = 1:cnt-1
            states0 = [states0 Twi0 Two0];
            xmax0 = [xmax0 Twall_max Twall_max];
            xmin0 = [xmin0 Twall_min Twall_min];
        end
        if roof == 1
            if unheated == 1
                x0 = [x0 [Ta0 states0 Tzi0 Tzo0 Tp0 T_return0]];
                xmax = 10000*[xmax [Ta_max xmax0 Twall_max Twall_max Tp_max T_return_max]];
                xmin = -10000*abs([xmin [Ta_min xmin0 Twall_min Twall_min Tp_min T_return_min]]);
            else
                x0 = [x0 [Ta0 states0 Tzi0 Tzo0 Tp0 T_return0]];
                xmax = [xmax [Ta_max xmax0 Twall_max Twall_max Tp_max T_return_max]];
                xmin = [xmin [Ta_min xmin0 Twall_min Twall_min Tp_min T_return_min]];
            end
        else
            if unheated == 1
                x0 = [x0 [Ta0 states0 Twi0 Two0 Tp0 T_return0]];
                xmax = 10000*abs([xmax [Ta_max xmax0 Twall_max Twall_max Tp_max T_return_max]]);
                xmin = -10000*abs([xmin [Ta_min xmin0 Twall_min Twall_min Tp_min T_return_min]]);
            else
                x0 = [x0 [Ta0 states0 Twi0 Two0 Tp0 T_return0]];
                xmax = [xmax [Ta_max xmax0 Twall_max Twall_max Tp_max T_return_max]];
                xmin = [xmin [Ta_min xmin0 Twall_min Twall_min Tp_min T_return_min]];
            end
        end
else
    for j = 1:cnt
        states0 = [states0 Twi0 Two0];
        xmax0 = [xmax0 Twall_max Twall_max];
        xmin0 = [xmin0 Twall_min Twall_min];
    end
        if roof == 1
            if unheated == 1
                x0 = [x0 [Ta0 states0 Tzi0 Tzo0 Tp0 T_return0]];
                xmax = 10000*abs([xmax [Ta_max xmax0 Twall_max Twall_max Tp_max T_return_max]]);
                xmin = -10000*abs([xmin [Ta_min xmin0 Twall_min Twall_min Tp_min T_return_min]]);
            else
                x0 = [x0 [Ta0 states0 Tzi0 Tzo0 Tp0 T_return0]];
                xmax = [xmax [Ta_max xmax0 Twall_max Twall_max Tp_max T_return_max]];
                xmin = [xmin [Ta_min xmin0 Twall_min Twall_min Tp_min T_return_min]];
            end
        else
            if unheated == 1
                x0 = [x0 [Ta0 states0 Twi0 Two0 Tp0 T_return0]];
                xmax = 10000*abs([xmax [Ta_max xmax0 Twall_max Twall_max Tp_max T_return_max]]);
                xmin = -10000*abs([xmin [Ta_min xmin0 Twall_min Twall_min Tp_min T_return_min]]);
            else
                x0 = [x0 [Ta0 states0 Twi0 Two0 Tp0 T_return0]];
                xmax = [xmax [Ta_max xmax0 Twall_max Twall_max Tp_max T_return_max]];
                xmin = [xmin [Ta_min xmin0 Twall_min Twall_min Tp_min T_return_min]];
            end
        end
end
x0 = x0';