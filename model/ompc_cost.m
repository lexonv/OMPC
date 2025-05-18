function [K,Sx,Sxc,Sxr,Sc,Sr,Scr] = ompc_cost(A,B,C,Q,R,nc,na)

nx = size(A,1);
ny = size(C,1);
nu = size(B,2);
nuc = nu*nc;
nya = ny*na;
dmp_factor = 0.999999999;

[K,~,~] = dlqr(A,B,Q,R,0);

%----------------------------------------------------------------------
M = pinv([C,zeros(ny, nu);A-eye(nx),B]);
Kxr = M(1:nx,1:ny); % nx × ny
Kur = M(nx+1:nx+nu,1:ny); % nu × ny
%----------------------------------------------------------------------
ID = diag(ones(1,(nc-1)*nu)); 
ID = [zeros((nc-1)*nu, nu), ID]; 
ID = [ID; zeros(nu, nu*nc)];  % (nuc x nuc)

Dr = diag(ones(1,(na-1)*ny)); 
Dr = [zeros((na-1)*ny, ny), Dr]; 
Dr = [Dr; [zeros(ny, ny*(na-1)), dmp_factor*eye(ny)]]; % (nya x nya)

Psi = [A - B*K,           [B, zeros(nx, (nc-1)*nu)],    [(eye(nx) - (A - B*K))*Kxr, zeros(nx, ny*(na-1))];
       zeros(nuc, nx),      ID,                         zeros(nuc, nya);
       zeros(nya, nx),      zeros(nya, nuc),            Dr ];
   
Kz = [-K, eye(nu), zeros(nu,(nc-1)*nu), [K*Kxr+Kur,zeros(nu,ny*(na-1))]];
Kxss = [eye(nx), zeros(nx,nuc), -Kxr, zeros(nx,ny*(na-1))];
Kzss = Kz - [zeros(nu,nx),zeros(nu, nuc), [Kur,zeros(nu,ny*(na-1))]];
%----------------------------------------------------------------------
W = Psi' * Kxss' * Q * Kxss * Psi + Kzss' * R * Kzss;
Spsi = dlyap(Psi', W);

% J = x'*Sx*x + 2*x'*Sxc*c + c'*Sc*c + R'*Sr*R + 2*x'*Sxr*R + 2*c'*Scr*R
Sx   = Spsi(1:nx, 1:nx);
Sxc  = Spsi(1:nx, nx+1:nx+nuc);
Sxr  = Spsi(1:nx, nx+nuc+1:end);
Sc   = Spsi(nx+1:nx+nuc, nx+1:nx+nuc);
Sr   = Spsi(nx+nuc+1:end, nx+nuc+1:end);
Scr  = Spsi(nx+1:nx+nuc, nx+nuc+1:end);

end
