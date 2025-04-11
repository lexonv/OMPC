function [K,Sx,Sxc,Sxr,Sc,Sr,Scr] = ompc_cost_tracking(A,B,C,Q,R,nc,na)

nx = size(A,1);
ny = size(C,1);
nu = size(B,2);
nuc = nu*nc;
nya = ny*na;
dmp_factor = 0.999999999;

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
Dr = diag(ones(1,(na-1)*ny)); Dr = [zeros((na-1)*ny,ny), Dr]; Dr = [Dr;[zeros(ny,ny*(na-1)), dmp_factor*eye(ny)]]; 

Psi = [A-B*K, [B zeros(nx,(nc-1)*nu)], [(eye(nx)-(A-B*K))*Kxr zeros(nx,nya-nu)];
    zeros(nuc,nx), ID, zeros(nuc,nya);
    zeros(nya,nx), zeros(nya,nuc), Dr];

Kz = [-K,eye(nu),zeros(nu,(nc-1)*nu),[K*Kxr+Kur zeros(nu,nya-nu)]];
Kxss = [eye(nx),zeros(nx,nuc),-Kxr,zeros(nx,nya-nu)];
Kzss = Kz - [zeros(nu,nx),zeros(nu,nuc),[Kur,zeros(nu,nya-nu)]];

%--------------------------------------------------------------------------

%rozwiązanie problemu bez ograniczeń:
%Z równania Lyapunova
W = Psi'*Kxss'*Q*Kxss*Psi+Kzss'*R*Kzss;
Spsi = dlyap(Psi',W);

%podziel macierz na odpowiednie części
%J = x'*Sx*x + 2*x'*Sxc*c + c'*Sc*c + R'*Sr*R + 2*x'*Sxr*R + 2*c'*Scr*R
%gdzie: R = R - L*d
%J = c'*Sc*c + 2*x'*Sxc*c + 2*c'*Scr*R
Sx = Spsi(1:nx,1:nx);
Sxc = Spsi(1:nx,nx+1:nx+nuc);
Sxr = Spsi(1:nx,nx+nuc+1:end);
Sc = Spsi(nx+1:nx+nuc,nx+1:nx+nuc);
Sr = Spsi(nx+nuc+1:end,nx+nuc+1:end);
Scr = Spsi(nx+1:nx+nuc,nx+nuc+1:end);
%--------------------------------------------------------------------------

