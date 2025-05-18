function [A, B, C, D, Z] = heatPump(coefficients, Q_flow)

%parametry
cw = coefficients(9);
dw = coefficients(10);
V_buf = coefficients(16);
COP = coefficients(17);
area_buf = coefficients(18);
U = coefficients(19);

% Punkt pracy
m_dot = dw.*Q_flow./60000; %[kg/s]
C_bufor = cw * dw * V_buf;

A = -area_buf*U/C_bufor;
B = COP/C_bufor; %[P_el]
C = 1; %[Tbufor]
D = 0;
Z = [area_buf*U -m_dot.*cw m_dot.*cw]/C_bufor; % [Tsp; Treturn]

end

