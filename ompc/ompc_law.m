function [u,c] = ompc_law(A,B,C,K,Sx,Sxc,Sc,umax,umin,xmax,xmin,ymax,ymin,nc,npred,ref,dist,ctrl0,x)

nx = size(A,1);
ny = size(C,1);
nu = size(B,2);

%oblicz stany ustalone
M = inv([C,zeros(ny,nu);A-eye(nx),B]);
Kxr = M(1:nx,1:ny);
Kur = M(nx+1:nx+ny,1:ny);

xss = Kxr * (ref-dist);
uss = Kur * (ref-dist);
xhat = x - xss;

%przeprowadź predykcje oraz wyznacz ograniczenia
[Px,Py,Pu,Hxc,Hyc,Huc,Qrx,Qry,Qru] = ompc_predictions(A,B,C,K,Kxr,Kur,nc,npred);
[CC,d,dd] = ompc_constraints(Px,Py,Pu,Hxc,Hyc,Huc,Qrx,Qry,Qru,npred,umax,umin,xmax,xmin,ymax,ymin);
%rozwiaz zadanie optymalizacji
%x = quadprog(H,f,A,b,Aeq,beq,lb,ub,x0,options)
%min 0.5*x'*H*x+f'*x, A*x <= b
% f = x'*Sx*x + x'*Sxc*c + c'*Sc*c 

opt = optimoptions('quadprog','Algorithm','active-set');
Sc=(Sc+Sc')/2;
[ctrl,~,exitflag] = quadprog(Sc,xhat'*Sxc/2,CC,d + dd*[x;ref-dist],[],[],[],[],ctrl0,opt);
if exitflag==-2
    disp('Problem jest nie do rozwiązania');
end

c = ctrl;
u = -K * xhat + uss + c(1:size(B,2),:);
end

