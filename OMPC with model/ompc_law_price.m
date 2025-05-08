function [u, c] = ompc_law_price(A,B,C,K,Sxc,Sc,Scr,umax,umin,xmax,xmin,ymax,ymin,w,nc,npred,price,ref,dist,x)

nx = size(A,1);
ny = size(C,1);
nu = size(B,2);

M = pinv([C,zeros(ny,nu);A-eye(nx),B]);
Kxr = M(1:nx,1:ny); % nx × ny
Kur = M(nx+1:nx+nu,1:ny); % nu × ny

REF = ref;
ref = REF(1:ny,1);
DIST = dist;
dist = DIST(1:ny,1);

xss = Kxr * (ref - dist);  % nx x 1
uss = Kur * (ref - dist);  % nu x 1
xhat = x - xss;

[Px, Py, Pu, Hxc, Hyc, Huc, Qrx, Qry, Qru] = ompc_predictions(A, B, C, K, Kxr, Kur, nc, npred);
[CC, d, dd] = ompc_constraints(Px, Py, Pu, Hxc, Hyc, Huc, Qrx, Qry, Qru, npred,umax, umin, xmax, xmin, ymax, ymin);

%----------------------------------------------------------------------
H = (Sc+Sc')/2;
f_base = xhat' * Sxc + (REF-DIST)' * Scr';

%Kara za wysokie ceny energii
f_price = zeros(1,nu*nc);
for i = 1:nc
    f_price(nu*i) = price(i);
end

%Wprowadź karę
f = f_base + w * f_price;

Aineq = CC;
bineq = d + dd * [x; ref - dist];
Aeq = zeros(0,length(f'));
beq = zeros(0,1);

% Opcje solvera
ctrl0 = zeros(nc*nu,1);
options = mpcInteriorPointOptions('double'); 
options.Display = 'off'; 
options.MaxIterations = 150; 
options.ConstraintTolerance = 5.0e-1; 
options.StepTolerance = 1.0e-8;
options.OptimalityTolerance = 1.0e-2;
options.ComplementarityTolerance = 1.0e-4;

[ctrl, ~, exitflag] = mpcInteriorPointSolver(H, f', Aineq, bineq, Aeq, beq, ctrl0, options);

if exitflag == 0
    disp("The maximum number of iterations was reached. The solution might be suboptimal or infeasible.");
elseif exitflag == -1
    disp("The problem appears to be infeasible.");
elseif exitflag == -2
    disp("An unrecoverable numerical error occurred.");
end

% Optymalne odchylenie sterowania
c = ctrl;
u = -K * xhat + uss + c(1:nu);

end
