function [u, c] = ompc_law_tracking(A,B,C,K,Sxc,Sc,Scr,umax,umin,xmax,xmin,ymax,ymin,nc,npred,ref,dist,x)
    
nx = size(A,1);
ny = size(C,1);
nu = size(B,2);

%oblicz stany ustalone
M = inv([C,zeros(ny, nu);A-eye(nx),B]);
Kxr = M(1:nx,1:ny); % nx × ny
Kur = M(nx+1:nx+ny,1:ny); % nu × ny

% Rozszerz referencje i zakłócenia na horyzont predykcji
REF = ref;
ref = REF(1:ny,1);
DIST = dist;
dist = DIST(1:ny,1);

% Oblicz stany ustalone i odchylenia
xss = Kxr * (ref - dist); % nx × 1
uss = Kur * (ref - dist); % nu × 1
xhat = x - xss; % nx × 1

% Predykcje oraz ograniczenia
[Px, Py, Pu, Hxc, Hyc, Huc, Qrx, Qry, Qru] = ompc_predictions(A, B, C, K, Kxr, Kur, nc, npred);
[CC, d, dd] = ompc_constraints(Px, Py, Pu, Hxc, Hyc, Huc, Qrx, Qry, Qru, npred, umax, umin, xmax, xmin, ymax, ymin);

%--------------------------------------------------------------------------
% Rozwiązanie problemu optymalizacji
%--------------------------------------------------------------------------
H = (Sc+Sc')/2;
f = xhat' * Sxc + (REF-DIST)' * Scr';

% Ograniczenia
A = CC;
b = d + dd * [x; ref - dist];
Aeq = zeros(0,length(f'));
beq = zeros(0,1);
    
% Opcje solvera
ctrl0 = zeros(nc*nu,1);
options = mpcInteriorPointOptions; options.Display = 'off'; options.MaxIterations = 100; options.ConstraintTolerance = 1.0e-2;
[ctrl, ~, exitflag] = mpcInteriorPointSolver(H, f', A, b, Aeq, beq, ctrl0, options);

% Sprawdź, czy rozwiązanie jest wykonalne
if exitflag == 0
    disp("The maximum number of iterations was reached. Solution x might be suboptimal or infeasible.");
elseif exitflag == -1
    disp("The problem appears to be infeasible.");
elseif exitflag == -2
    disp("An unrecoverable numerical error occurred.");
end

% Optymalne odchylenie sterowania
c = ctrl;
u = -K * xhat + uss + c(1:nu);

end