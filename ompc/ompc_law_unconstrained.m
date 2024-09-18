function [u,c] = ompc_law_unconstrained(A,B,C,K,Sx,Sxc,Sc,ref,dist, x)

%--------------------------------------------------------------------------

%oblicz stany ustalone
M = inv([C,zeros(size(C,1),size(B,2));A-eye(size(A,1)),B]);
M1 = M(1:size(A,1),1:size(C,1));
M2 = M(size(A,1)+1:size(A,1)+size(C,1),1:size(C,1));

xss = M1 * (ref-dist);
uss = M2 * (ref-dist);
xhat = x - xss;
disp(xhat)
%--------------------------------------------------------------------------

%wyznacz prawo sterowania
c = -inv(Sc) * Sxc'*xhat;
u = -K * xhat + uss + c(size(B,2),1);
