function [u,c] = ompc_law(A,B,C,K,Sx,Sxc,Sc,umax,umin,xmax,xmin,ymax,ymin,nc,npred,ref,dist,x)

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
%min 0.5*x'*H*x + f'*x, A*x <= b
% f = x'*Sx*x + x'*Sxc*c + c'*Sc*c 
Sc=(Sc+Sc')/2;

%%
H = Sc;
f = xhat'*Sxc/2; f = f';
A = CC;
b = d + dd*[x;ref-dist];
Aeq = zeros(0,length(f));
beq = zeros(0,1);
iA0 = false(size(b));
ctrl0 = zeros(nc*nu,1);
options = mpcInteriorPointOptions; options.MaxIterations = 100; options.ConstraintTolerance = 1.0e-2;
[ctrl,exitflag] = mpcInteriorPointSolver(H,f,A,b,Aeq,beq,ctrl0,options);
% options = mpcActiveSetOptions; options.MaxIterations = 100; options.ConstraintTolerance = 1.0e-2;
% [ctrl,exitflag] = mpcActiveSetSolver(H,f,A,b,Aeq,beq,iA0,options);
if exitflag == 0
    disp("The maximum number of iterations was reached. Solution x might be suboptimal or infeasible.")
elseif exitflag == -1
    disp("The problem appears to be infeasible.")
elseif exitflag == -2
    disp("An unrecoverable numerical error occurred.")
end

c = ctrl;
u = -K * xhat + uss + c(1:nu,:);
end

