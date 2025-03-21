function [x_est, P] = KalmanFilter(y, u, x_est_prev, P_prev, A, B, C, Q, R)
% Funkcja wykonująca jeden krok estymacji za pomocą filtru Kalmana
% Wejścia:
%   y - aktualny pomiar (skalar lub wektor)
%   u - aktualne wejście sterujące (skalar lub wektor)
%   x_est_prev - poprzedni estymowany stan (n x 1)
%   P_prev - poprzednia macierz kowariancji błędu estymacji (n x n)
%   A - macierz stanu (n x n)
%   B - macierz wejść (n x m)
%   C - macierz pomiarów (p x n)
%   Q - macierz kowariancji szumu procesowego (n x n)
%   R - macierz kowariancji szumu pomiarowego (p x p)
% Wyjścia:
%   x_est - aktualny estymowany stan (n x 1)
%   P - aktualna macierz kowariancji błędu estymacji (n x n)

% Krok predykcji
x_pred = A * x_est_prev + B * u; % Predykcja stanu
P_pred = A * P_prev * A' + Q;    % Predykcja kowariancji

% Krok korekcji
K = P_pred * C' / (C * P_pred * C' + R); % Wzmocnienie Kalmana
x_est = x_pred + K * (y - C * x_pred);   % Korekcja stanu
P = (eye(size(A)) - K * C) * P_pred;     % Korekcja kowariancji
end