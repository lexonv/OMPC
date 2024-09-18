clear;clc;

%Pomieszczenie
syms Ti To Tnw Tsw Tww Tew Qin Qs t I
syms Cp Rp Rnw Rsw Rww Rew
syms Cnw Csw Cww Cew
syms Tidot Tnwdot Tswdot Twwdot Tewdot

%WARTOŚĆI PARAMETRÓW

    %ściany zewnętrzne
    %wełna mineralna 25 cm, płyta stropianowa 7cm, folia paroizolacyjna (około 2 mm)

    %ściany wewnętrzne
    %wełna mineralna 25 cm, folia paroizolacyjna (około 2 mm)

    %R = 1/U, U -współczynnik przenikania ciepła
    % ściany zewnętrzne U = 0.2 W/(m2*K) 
    % ściany wewnętrzne U = 0.15 W/(m2*K)
    % dach U = 0.15 W/(m2*K)
    % podłoga na gruncie U = 0.2 W/(m2*K)
    % strop U = 0.15 W/(m2*K) 

Cnw = (1300*50*0.25 + 1200*12*0.07 + 1800*926*0.004)*5*2; %(welna + stropian + folia)*długość*wysokosc
Csw = (1300*50*0.25 + 1200*12*0.07 + 1800*926*0.004)*5*2; % (cieplo wlasciwe x gestosc x grubosc)
Cww = (1300*50*0.25 + 1200*12*0.07 + 1800*926*0.004)*5*2;
Cew = (1300*50*0.25 + 1200*12*0.07 + 1800*926*0.004)*5*2;
Cposadzka = (1200*12*0.2 + 1800*980*0.0003 + 840*2500*0.2)*5*2;%(stropian + folia + żelbet)
Cstrop = (1200*13.5*0.05 + 1800*980*0.002)*5*2;%(stropian + folia)
Cp = Cnw + Csw + Cww + Cew + Cposadzka + Cstrop;
Rnw = 1/0.2;
Rsw = 1/0.2;
Rww = 1/0.2;
Rew = 1/0.2;
Rposadzka = 1/0.2;
Rstrop = 1/0.15;
Rp = Rnw + Rsw + Rww + Rew + Rposadzka + Rstrop;

    %WEJŚCIA
    z = 0; ws = 1; I = 0; A = 10;
    Qs = z * ws * I * A;
    c = 4200; %[J/kgK]
    S = 1;
    m = 1 * S;
%     Qin = c * m * (Twater - Ti);
    

%Parametry
    a11 = -(1/(Cp*Rp)+1/(Cp*Rnw)+1/(Cp*Rsw)+1/(Cp*Rww)+1/(Cp*Rew));
    a12 = 1/(Cp*Rnw);
    a13 = 1/(Cp*Rsw);
    a14 = 1/(Cp*Rww);
    a15 = 1/(Cp*Rew);
    a21 = 1/(Cnw*Rnw);
    a22 = -1/(Cnw*Rnw);
    a23 = 0;
    a24 = 0;
    a25 = 0;
    a31 = 1/(Csw*Rsw);
    a32 = 0;
    a33 = -1/(Csw*Rsw);
    a34 = 0;
    a35 = 0;
    a41 = 1/(Cww*Rww);
    a42 = 0;
    a43 = 0;
    a44 = -1/(Cww*Rww);
    a45 = 0;
    a51 = 1/(Cew*Rew);
    a52 = 0;
    a53 = 0;
    a54 = 0;
    a55 = -1/(Cew*Rew);
%..........................................................................%
%MODEL W PRZESTRZENI STANU
A = [a11,a12,a13,a14,a15;a21,a22,a23,a24,a25;a31,a32,a33,a34,a35;a41,a42,a43,a44,a45;a51,a52,a53,a54,a55];

b12 = 1/(Cp*Rp);

B = [1/Cp*100,b12,1/Cp;0,0,0;0,0,0;0,0,0;0,0,0];

C = [1 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0];

D = [0 0 0; 0 0 0; 0 0 0];

sys = ss(A,B,C,D);

clearvars -except A B C D

