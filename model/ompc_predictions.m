%x = Px*x + Hcx*c + Qrx*(r-d)
%y = Py*x + Hcy*c + Qry*(r-d)
%u = Pu*x + Hcu*c + Qru*(r-d)

function [Px,Py,Pu,Hxc,Hyc,Hcu,Qrx,Qry,Qru] = ompc_predictions(A,B,C,K,Kxr,Kur,nc,npred)

%--------------------------------------------------------------------------

p = A - B*K;
q = eye(size(A,1))-p;
I = eye(size(K*B,1));
%--------------------------------------------------------------------------

Pxtemp = p;
for i = 2:npred
    Pxtemp = [Pxtemp; p^i];
end
Px = Pxtemp;

Pytemp = C*p;
for i = 2:npred
    Pytemp = [Pytemp; C*p^i];
end
Py = Pytemp;

Putemp = -K;
for i = 1:npred-1
    Putemp = [Putemp; -K*p^i];
end
Pu = Putemp;
%--------------------------------------------------------------------------

Hxctemp = B;
for j = 2:npred
    Hxctemp = [Hxctemp; p^(j-1)*B];
end

cnt1 = size(B,1);
cnt2 = size(B,2);

row = [];

for k = 1:npred
    mat = Hxctemp(cnt1*(npred-k) + 1:cnt1*(npred-k+1),:);
    row = [row mat];
end
   
Hhxc = row;

for j = 1:npred-1
    mat = row(:,cnt2*j+1:end);
    mat = [mat zeros(cnt1, cnt2*j)];
    Hhxc = [mat; Hhxc];
end

Hxc = Hhxc(:,1:nc*cnt2);

%----

Hyctemp = C*B;
for j = 2:npred
    Hyctemp = [Hyctemp; C*p^(j-1)*B];
end

cnt1 = size(C,1);
cnt2 = size(B,2);

row = [];

for k = 1:npred
    mat = Hyctemp(cnt1*(npred-k) + 1:cnt1*(npred-k+1),:);
    row = [row mat];
end
   
Hhyc = row;
for j = 1:npred-1
    mat = row(:,cnt2*j+1:end);
    mat = [mat zeros(cnt1, cnt2*j)];
    Hhyc = [mat; Hhyc];
end

Hyc = Hhyc(:,1:nc*cnt2);

%----

Hcutemp = I;
for j = 1:npred-1
    Hcutemp = [Hcutemp; -K*p^(j-1)*B];
end

cnt1 = size(K*B,1);
cnt2 = size(K*B,2);

row = [];

for k = 1:npred
    mat = Hcutemp(cnt1*(npred-k) + 1:cnt1*(npred-k+1),:);
    row = [row mat];
end
   
Hhcu = row;
for j = 1:npred-1
    mat = row(:,cnt2*j+1:end);
    mat = [mat zeros(cnt1, cnt2*j)];
    Hhcu = [mat; Hhcu];
end

Hcu = Hhcu(:,1:nc*cnt2);

%--------------------------------------------------------------------------
%----

Qrx0 = q*Kxr;
Qry0 = C*q*Kxr;
Qru0 = K*Kxr+Kur;
QrxMAT = Qrx0;
QryMAT = Qry0;
QruMAT = Qru0;

for k = 1:npred-1
    tempQrx = Qrx0 + p^k*q*Kxr;
    tempQry = Qry0 + C*p^k*q*Kxr;
    tempQru = Qru0 - K*p^(k-1)*q*Kxr;

    QrxMAT = [QrxMAT;tempQrx];
    QryMAT = [QryMAT;tempQry];
    QruMAT = [QruMAT;tempQru];

    Qrx0 = tempQrx;
    Qry0 = tempQry;
    Qru0 = tempQru;
end

Qrx = QrxMAT;
Qry = QryMAT;
Qru = QruMAT;
