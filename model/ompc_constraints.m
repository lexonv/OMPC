function [CC,d,dd] = ompc_constraints(Px,Py,Pu,Hxc,Hyc,Huc,Qrx,Qry,Qru,npred,umax,umin,xmax,xmin,ymax,ymin,zoneWaterIndex,nx,x,ref,dist)

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
num = size(zoneWaterIndex,1);
umin_base = zeros(num+1,1);
VECTOR = zeros(npred*(num+1),1);
for i = 1:npred
    for j = 1:num
        umin_base(j) = x_predicted(zoneWaterIndex(j)+(i-1)*nx); 
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

% CC = [Cumax;Cumin;Cymax;Cymin];
% d = [dumax;-dumin;dymax;-dymin];
% dd = [ddumax;ddumin;ddymax;ddymin];

% CC = [Cumax;Cumin];
% d = [dumax;-dumin];
% dd = [ddumax;ddumin];

end

