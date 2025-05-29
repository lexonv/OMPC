function [CC,d,dd] = ompc_constraints(Px,Py,Pu,Hxc,Hyc,Huc,Qrx,Qry,Qru,npred,umax,umin,xmax,xmin,ymax,ymin,Qflow,zoneWaterIndex,nx,x,ref,dist)

%Notacja:
%CC*ck <= d + [dd][xk;ref-dist] 

%CC
Cumax = Huc;
Cumin = -Huc;
Cxmax = Hxc;
Cxmin = -Hxc;
Cymax = Hyc;
Cymin = -Hyc;

%d
dumax = umax;
dumin = umin;
dxmax = xmax;
dxmin = xmin;
dymax = ymax;
dymin = ymin;
for i = 1:npred-1
    dumax = [dumax;umax];
    dumin = [dumin;umin];
    dxmax = [dxmax;xmax];
    dxmin = [dxmin;xmin];
    dymax = [dymax;ymax];
    dymin = [dymin;ymin];
end

%-------------------------------------------------------
% Wprowadź jako ograniczenie dumin predykcje temperatur wody w strefie
x_predicted = Px*x + Qrx*(ref-dist); %oblicz predykcje przy c = 0
x_predicted = [x; x_predicted(1:size(x_predicted,1)-size(x,1),:)];
% num = size(zoneWaterIndex,1);
numCtrl = size(Pu,1)/npred - 1;
numOutput = size(Py,1)/npred - 1;
umin_base = zeros(numCtrl+1,1);
VECTOR = zeros(npred*(numCtrl+1),1);
for i = 1:npred

    %Zczytaj predykcje wody powracającej
    %UWAGA: Możliwe sterowanie jednostrefowe (war. pierwszy) oraz
    %wielostrefowe (war. drugi)
    if numCtrl < numOutput && numCtrl == 1
        %Jeżeli instalacja jednostrefowa (liczba wejść < liczba wyjść i liczba wejść = 1)
        retTempVEC = 0;
        for j = 1:numOutput
            retTempVEC = retTempVEC + Qflow(j)/sum(Qflow)*x_predicted(zoneWaterIndex(j)+(i-1)*nx);
        end
        umin_base(1) = retTempVEC;
    else
        %Jeżeli instalacja wielostrefowa (liczba wejść = liczba wyjść)
        for j = 1:numCtrl
            umin_base(j) = x_predicted(zoneWaterIndex(j)+(i-1)*nx); 
        end
    end
    umin_base(end) = umin(end);

    for k = 1:size(umin_base,1)
        VECTOR(k+size(umin_base,1)*(i-1)) = umin_base(k);
    end
end
dumin = VECTOR;
%-------------------------------------------------------

%dd
ddumax = -[Pu Qru];
ddumin = [Pu Qru];
ddxmax = -[Px Qrx];
ddxmin = [Px Qrx];
ddymax = -[Py Qry];
ddymin = [Py Qry];

CC = [Cumax;Cumin;Cxmax;Cxmin;Cymax;Cymin];
d = [dumax;-dumin;dxmax;-dxmin;dymax;-dymin];
dd = [ddumax;ddumin;ddxmax;ddxmin;ddymax;ddymin];

end

