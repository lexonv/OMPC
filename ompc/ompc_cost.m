function [K,Sx,Sxc,Sc] = ompc_cost(A,B,Q,R,nc)
%--------------------------------------------------------------------------

%oblicz wzmocnienie reg. LQR (dla OMPC)
[K,~,~] = dlqr(A,B,Q,R,0);
%--------------------------------------------------------------------------

%stwórz rozszerzony model
nx = size(B,1);
nu = size(B,2);
nuc = nu*nc;

ID = diag(ones(1,(nc-1)*nu));
ID = [zeros((nc-1)*nu,nu), ID];
ID = [ID;zeros(nu,nu*nc)];

Psi = [A-B*K, [B zeros(nx,(nc-1)*nu)];zeros(size(ID,1),nx),ID];
Gamma = [eye(nx),zeros(nx,nuc)];
Kz = [K,-eye(nu),zeros(nu,(nc-1)*nu)];
%--------------------------------------------------------------------------

%rozwiązanie problemu bez ograniczeń:
%Z równania Lyapunova
W = Psi'*Gamma'*Q*Gamma*Psi+Kz'*R*Kz;
Spsi = dlyap(Psi',W);

%podziel macierz na odpowiednie części
Sx = Spsi(1:nx,1:nx);
Sxc = Spsi(1:nx,nx+1:end);
Sc = Spsi(nx+1:end,nx+1:end);
%--------------------------------------------------------------------------
