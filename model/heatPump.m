function [A, B, C, D, Z] = heatPump(coefficients, v)

% Model pompy ciepła z buforem
% C_buf*dT_buf/dt = COP * P_el + U*area*(T_amb - T_buf) + m_dot*cw*(T_ret - T_buf) 

V_buf = coefficients(19);
COP = coefficients(20);
area_buf = coefficients(21);
U = coefficients(22);

cw = coefficients(12);
dw = coefficients(13);
C_bufor = cw * dw * V_buf;
m_dot = v/60000*dw;

A = -(U*area_buf + m_dot*cw)/C_bufor; %[T_buf]
B = COP/C_bufor; %[P_el]
C = 1; % [T_buf]
D = 0;
Z = [U*area_buf m_dot*cw]/C_bufor; % [T_amb; T_ret]

end