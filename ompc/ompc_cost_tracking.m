function [K,Sx,Sxc,Sxr,Sc,Sr,Scr] = ompc_cost_tracking(A,B,C,Q,R,nc,na)

nx = size(A,1);
ny = size(C,1);
nu = size(B,2);
nuc = nu*nc;
nua = nu*na;

%--------------------------------------------------------------------------

%oblicz wzmocnienie reg. LQR (dla OMPC)
[K,~,~] = dlqr(A,B,Q,R,0);
%--------------------------------------------------------------------------

%oblicz stany ustalone
M = inv([C,zeros(ny,nu);A-eye(nx),B]);
Kxr = M(1:nx,1:ny);
Kur = M(nx+1:nx+ny,1:ny);

%stwórz rozszerzony model
%Rk - Ld = Dr(R-Ld)
%Zk+1 = Psi*Zk
%uk = Kz*Zk
ID = diag(ones(1,(nc-1)*nu)); ID = [zeros((nc-1)*nu,nu), ID]; ID = [ID;zeros(nu,nu*nc)];
Dr = diag(ones(1,(na-1)*nu)); Dr = [zeros((na-1)*nu,nu), Dr]; Dr = [Dr;[zeros(nu,nu*(na-1)),0.999*eye(nu)]]; 

p = A-B*K;

Psi = [p, [B zeros(nx,(nc-1)*nu)], [(eye(nx)-p)*Kxr zeros(nx,nua-nu)];
    zeros(nuc,nx), ID, zeros(nuc,nua);
    zeros(nua,nx), zeros(nua,nuc), Dr];
Kz = [-K,eye(nu),zeros(nu,(nc-1)*nu),K*Kxr+Kur, zeros(nu,nua-nu)];
% Gamma = [eye(nx),zeros(nx,size(Psi,1)-nx)];

Kxss = [eye(nx),zeros(nx,nuc),-Kxr]; Kxss = [Kxss,zeros(nx,size(Psi,1)-size(Kxss,2))];
Kzss = Kz - [zeros(nu,nx),zeros(nu,nuc),Kur,zeros(nu,size(Psi,1)-nx-nuc-size(Kur,2))];
%--------------------------------------------------------------------------

%rozwiązanie problemu bez ograniczeń:
%Z równania Lyapunova
W = Psi'*Kxss'*Q*Kxss*Psi+Kzss'*R*Kzss;
Spsi = dlyap(Psi',W);

%podziel macierz na odpowiednie części
Sx = Spsi(1:nx,1:nx);
Sxc = Spsi(1:nx,nx+1:nx+nuc);
Sxr = Spsi(1:nx,nx+nuc+1:end);
Sc = Spsi(nx+1:nx+nuc,nx+1:nx+nuc);
Sr = Spsi(nx+nuc+1:end,nx+nuc+1:end);
Scr = Spsi(nx+1:nx+nuc,nx+nuc+1:end);

%J = x'*Sx*x + 2*x'*Sxc*c + c'*Sc*c + R'*Sr*R + 2*x'*Sxr*R + 2*c'*Scr*R
%gdzie: R = R - L*d
%--------------------------------------------------------------------------

