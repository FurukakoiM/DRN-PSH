% Cascade Pumped Hydro Storage System - MILP Model (Optimization Version)
clear all;

load('DataAll.mat','solar_annual_scaled','chugoku_price_2018','annual_hourly_flow')

CasePara=[1;1;1];
%   [0;0;0] - w/o PSH
%   [1;0;0] - S-PSH (Single-stage)
%   [1;1;0] - C-PSH (Cascade)
%   [1;1;1] - DRN-PSH (Distributed Reservoir Network)

%% Parameter Settings - Basic System
numReservoirs = 3;      % Number of main reservoirs
numPumpUnits = 2;       % Number of main pumping units
T = 8760;               % Time steps (hours)
dt = 1;                 % Time interval (hours)
%MaxCut = 7500*5;       % Maximum curtailment
MaxCut = 0;      % Maximum curtailment
TimeEX = 3600;          % Seconds → Hours conversion
LineMax = 250;          % kW
Solar = solar_annual_scaled(1:T);

Vmain=[246000, 450000, 1550000];% Maximum capacity of each main reservoir (unit: m3)
Vsub1=[350000, 100, 0];

% Main reservoir parameters
V_max = Vmain*0.9;     
V_min = Vmain*0.1;      % Minimum capacity of each main reservoir (unit: m3)
V_init = Vmain/2;       % Initial capacity of each main reservoir (unit: m3)

% Natural inflow (m³/h) = Catchment area (km2) × Rainfall (mm/h) ÷ 1000
I_nat = zeros(numReservoirs, T);
I_nat(1,:) = annual_hourly_flow(1:T);    % Natural inflow to upper reservoir
I_nat(2,:) = annual_hourly_flow(1:T);    % Natural inflow to middle reservoir
I_nat(3,:) = annual_hourly_flow(1:T);    % Natural inflow to lower reservoir

% Generation and pumping efficiency and flow limits
eta_gen = 0.85;              % Generation efficiency
eta_pump = 0.75;             % Pumping efficiency
Q_max_gen = [0.195, 0.260];  % Maximum generation flow rate (m³/s)
Q_max_pump = [0.195, 0.260]; % Maximum pumping flow rate (m³/s)
Q_max_spill  = [10, 10, 10];     % (m³/s)
In_max_spill  = [Inf, Inf, Inf];    % (m³/h)

High1 = 37.9; % Effective head of generator 1 (m)
High2 = 40.0; % Effective head of generator 2 (m)

%% Small Reservoir Settings
% Small reservoir parameters - Capacity related
VS1_max = Vsub1*0.9;     % Maximum capacity of small reservoir (unit: m3)
VS1_min = Vsub1*0.1;           % Minimum capacity of each small reservoir (unit: m3)
VS1_init = Vsub1/2;            % Initial capacity of each small reservoir (unit: m3)

%% Grid Power Price and Demand/Solar Generation Settings
% Grid power price (by time zone) (Yen/kWh)
price = chugoku_price_2018(1:T)';

% Solar generation (kW)
solar_output = Solar;

%% Optimization Model Construction
% Main reservoir variable definitions
V1 = optimvar('V1', T+1, 'LowerBound', V_min(1), 'UpperBound', V_max(1));
V2 = optimvar('V2', T+1, 'LowerBound', V_min(2), 'UpperBound', V_max(2));
V3 = optimvar('V3', T+1, 'LowerBound', V_min(3), 'UpperBound', V_max(3));

% Pumping unit variable definitions
Q_gen1 = optimvar('Q_gen1', T, 'LowerBound', 0, 'UpperBound', Q_max_gen(1)*CasePara(1));
Q_gen2 = optimvar('Q_gen2', T, 'LowerBound', 0, 'UpperBound', Q_max_gen(2)*CasePara(2));
Q_pump1 = optimvar('Q_pump1', T, 'LowerBound', 0, 'UpperBound', Q_max_pump(1)*CasePara(1));
Q_pump2 = optimvar('Q_pump2', T, 'LowerBound', 0, 'UpperBound', Q_max_pump(2)*CasePara(2));

Q_spill1 = optimvar('Q_spill1', T, 'LowerBound', 0, 'UpperBound', Q_max_spill(1));
Q_spill2 = optimvar('Q_spill2', T, 'LowerBound', 0, 'UpperBound', Q_max_spill(2));
Q_spill3 = optimvar('Q_spill3', T, 'LowerBound', 0, 'UpperBound', Q_max_spill(3));

u_gen1 = optimvar('u_gen1', T, 'Type', 'integer', 'LowerBound', 0, 'UpperBound', 1);
u_gen2 = optimvar('u_gen2', T, 'Type', 'integer', 'LowerBound', 0, 'UpperBound', 1);
u_pump1 = optimvar('u_pump1', T, 'Type', 'integer', 'LowerBound', 0, 'UpperBound', 1);
u_pump2 = optimvar('u_pump2', T, 'Type', 'integer', 'LowerBound', 0, 'UpperBound', 1);

P_gen1 = optimvar('P_gen1', T, 'LowerBound', 0);
P_gen2 = optimvar('P_gen2', T, 'LowerBound', 0);
P_pump1 = optimvar('P_pump1', T, 'LowerBound', 0);
P_pump2 = optimvar('P_pump2', T, 'LowerBound', 0);

% System-related variables (unused variables removed)
solar_curtailment = optimvar('solar_curtailment', T, 'LowerBound', 0, 'UpperBound', solar_output);

% Small reservoir-related variables
VS1 = optimvar('VS1', T+1, 'LowerBound', VS1_min(1), 'UpperBound', VS1_max(1));
VS2 = optimvar('VS2', T+1, 'LowerBound', VS1_min(2), 'UpperBound', VS1_max(2));
VS3 = optimvar('VS3', T+1, 'LowerBound', VS1_min(3), 'UpperBound', VS1_max(3));

Q_main_to_small1 = optimvar('Q_main_to_small1', T, 'LowerBound', 0, 'UpperBound', Q_max_spill(1)*CasePara(3));
Q_main_to_small2 = optimvar('Q_main_to_small2', T, 'LowerBound', 0, 'UpperBound', Q_max_spill(1)*CasePara(3));
Q_main_to_small3 = optimvar('Q_main_to_small3', T, 'LowerBound', 0, 'UpperBound', Q_max_spill(1)*CasePara(3));

Q_small_to_main1 = optimvar('Q_small_to_main1', T, 'LowerBound', 0, 'UpperBound', Q_max_spill(1)*CasePara(3));
Q_small_to_main2 = optimvar('Q_small_to_main2', T, 'LowerBound', 0, 'UpperBound', Q_max_spill(1)*CasePara(3));
Q_small_to_main3 = optimvar('Q_small_to_main3', T, 'LowerBound', 0, 'UpperBound', Q_max_spill(1)*CasePara(3));

% Problem creation
prob = optimproblem;

% Objective function setting
revenue = sum(P_gen1 .* price') + sum(P_gen2 .* price');
cost = sum(P_pump1 .* price') + sum(P_pump2 .* price');

% Penalty
penalty_solar = 0;     % Yen/kWh
cost = cost + penalty_solar * sum(solar_curtailment);

profit = revenue - cost;
prob.Objective = profit;
prob.ObjectiveSense = 'maximize';

%% Constraint Settings (Accelerated by vectorization)

% 1. Initial and final conditions for main reservoirs
prob.Constraints.initialVolume1 = V1(1) == V_init(1);
prob.Constraints.initialVolume2 = V2(1) == V_init(2);
prob.Constraints.initialVolume3 = V3(1) == V_init(3);
prob.Constraints.finalVolume1 = V1(T+1) == V_init(1);
prob.Constraints.finalVolume2 = V2(T+1) == V_init(2);
prob.Constraints.finalVolume3 = V3(T+1) == V_init(3);

% 2. Initial and final conditions for small reservoirs
prob.Constraints.smallInitVolume1 = VS1(1) == VS1_init(1);
prob.Constraints.smallInitVolume2 = VS2(1) == VS1_init(2);
prob.Constraints.smallInitVolume3 = VS3(1) == VS1_init(3);

% 3. Water balance constraints (Accelerated by vectorization)
% Pre-calculation of inflow and outflow
outflow_to_small1 = Q_main_to_small1 + Q_main_to_small2 + Q_main_to_small3;
inflow_from_small1 = Q_small_to_main1 + Q_small_to_main2 + Q_small_to_main3;

% Upper reservoir (1)
prob.Constraints.waterBalance1 = V1(2:T+1) == V1(1:T)  + ...
    (- Q_gen1 + Q_pump1 - Q_spill1 - outflow_to_small1 + inflow_from_small1 + I_nat(1,:)')*TimeEX;
 
% Middle reservoir (2)
prob.Constraints.waterBalance2 = V2(2:T+1) == V2(1:T)   + ...
    (Q_gen1 - Q_pump1 - Q_gen2 + Q_pump2 + Q_spill1 - Q_spill2 )*TimeEX;

% Lower reservoir (3)
prob.Constraints.waterBalance3 = V3(2:T+1) == V3(1:T)   + ...
    (Q_gen2 - Q_pump2 + Q_spill2 - Q_spill3 )*TimeEX;

% 4. Water balance constraints for small reservoirs (vectorization)
prob.Constraints.smallWaterBalance1 = VS1(2:T+1) == VS1(1:T) + ...
    (Q_main_to_small1 - Q_small_to_main1)*TimeEX;
prob.Constraints.smallWaterBalance2 = VS2(2:T+1) == VS2(1:T) + ...
    (Q_main_to_small2 - Q_small_to_main2)*TimeEX;
prob.Constraints.smallWaterBalance3 = VS3(2:T+1) == VS3(1:T) + ...
    (Q_main_to_small3 - Q_small_to_main3)*TimeEX;

% 5. Generation and pumping flow limits
prob.Constraints.genFlowLimit1 = Q_gen1 <= Q_max_gen(1) * u_gen1;
prob.Constraints.pumpFlowLimit1 = Q_pump1 <= Q_max_pump(1) * u_pump1;
prob.Constraints.genFlowLimit2 = Q_gen2 <= Q_max_gen(2) * u_gen2;
prob.Constraints.pumpFlowLimit2 = Q_pump2 <= Q_max_pump(2) * u_pump2;

% 6. Exclusive operation mode constraints
prob.Constraints.exclusiveMode1 = u_gen1 + u_pump1 <= 1;
prob.Constraints.exclusiveMode2 = u_gen2 + u_pump2 <= 1;

% 7. Generation and pumping power calculation
prob.Constraints.genPower1 = P_gen1 == 9.8 * Q_gen1 * High1 * eta_gen;
prob.Constraints.pumpPower1 = P_pump1 == 9.8 * Q_pump1 * High1 / eta_pump;
prob.Constraints.genPower2 = P_gen2 == 9.8 * Q_gen2 * High2 * eta_gen;
prob.Constraints.pumpPower2 = P_pump2 == 9.8 * Q_pump2 * High2 / eta_pump;

% 8. Transmission line constraints (integrated as absolute value constraints)
netPower = P_gen1 + P_gen2 - P_pump1 - P_pump2 + (solar_output - solar_curtailment);
prob.Constraints.pb1 = netPower <= LineMax;
prob.Constraints.pb2 = netPower >= -LineMax;

% 9. Solar curtailment upper limit
prob.Constraints.SumCurtailment = sum(solar_curtailment) <= MaxCut;

%% Solver Option Optimization
disp('Starting optimization...');
options = optimoptions('intlinprog', ...
    'Display', 'iter', ...
    'MaxTime', 7200, ...          % Maximum computation time (seconds)
    'RelativeGapTolerance', 0.01,... % Relative gap tolerance (1%)
    'AbsoluteGapTolerance', 1e-3); 

sol = solve(prob, 'Options', options);

%% Result Processing
disp('Processing results...');

% Assign variables
xV1 = sol.V1;
xV2 = sol.V2;
xV3 = sol.V3;
xQ_gen1 = sol.Q_gen1;
xQ_gen2 = sol.Q_gen2;
xQ_pump1 = sol.Q_pump1;
xQ_pump2 = sol.Q_pump2;
xQ_spill1 = sol.Q_spill1;
xQ_spill2 = sol.Q_spill2;
xQ_spill3 = sol.Q_spill3;
xu_gen1 = sol.u_gen1;
xu_gen2 = sol.u_gen2;
xu_pump1 = sol.u_pump1;
xu_pump2 = sol.u_pump2;
xP_gen1 = sol.P_gen1;
xP_gen2 = sol.P_gen2;
xP_pump1 = sol.P_pump1;
xP_pump2 = sol.P_pump2;
xsolar_curtailment = sol.solar_curtailment;

% Small reservoir-related results
xVS1 = sol.VS1;
xVS2 = sol.VS2;
xVS3 = sol.VS3;
xQ_main_to_small1 = sol.Q_main_to_small1;
xQ_main_to_small2 = sol.Q_main_to_small2;
xQ_main_to_small3 = sol.Q_main_to_small3;
xQ_small_to_main1 = sol.Q_small_to_main1;
xQ_small_to_main2 = sol.Q_small_to_main2;
xQ_small_to_main3 = sol.Q_small_to_main3;

%% Calculate and Output Objective Function Values
% Revenue calculation
total_revenue_main = sum(xP_gen1 .* price') + sum(xP_gen2 .* price');
total_revenue = total_revenue_main;

% Cost calculation
pump_cost_main = sum(xP_pump1 .* price') + sum(xP_pump2 .* price');
pump_cost = pump_cost_main;

% Penalty cost calculation
solar_penalty_cost = penalty_solar * sum(xsolar_curtailment);
total_penalty_cost = solar_penalty_cost;

% Total cost
total_cost = pump_cost + total_penalty_cost;

% Total profit
total_profit = total_revenue - total_cost;
profit_woPena = total_profit + total_penalty_cost;

%% Display results (Table 5)
fprintf('\n=== Objective Function Breakdown ===\n');
fprintf('Total Revenue: %.2f Yen\n', total_revenue);
fprintf('  Main generation revenue: %.2f Yen\n', total_revenue_main);
fprintf('Total Cost: %.2f Yen\n', total_cost);
fprintf('  Pumping cost: %.2f Yen\n', pump_cost);
fprintf('    - Main pumping cost: %.2f Yen\n', pump_cost_main);
fprintf('  Penalty cost: %.2f Yen\n', total_penalty_cost);
fprintf('    - Solar curtailment penalty: %.2f Yen\n', solar_penalty_cost);
fprintf('Total Profit: %.2f Yen\n', total_profit);
fprintf('Total Profit (without penalty): %.2f Yen\n', profit_woPena);
fprintf('Curtailment: %.2f kWh\n', sum(xsolar_curtailment));
fprintf('Spillage: %.2f m³\n', sum(xQ_spill3));

%% Result Visualization
%% Common figure settings for IEEE Transactions on Power Systems
set(0, 'DefaultAxesFontName', 'Times New Roman');
set(0, 'DefaultTextFontName', 'Times New Roman');
set(0, 'DefaultAxesFontSize', 10);
set(0, 'DefaultTextFontSize', 10);
set(0, 'DefaultLineLineWidth', 1.5);
set(0, 'DefaultAxesLineWidth', 1);
set(0, 'DefaultAxesBox', 'on');

%% Target date settings
day_start = 148;
day_end = 150;
% Annual data range
annual_range = 1:8760;
time_axis_annual = annual_range;

% Convert days to hours for plotting (for figures 3 and 4)
start_hour = (day_start - 1) * 24 + 1;  % First hour of day 148
end_hour = day_end * 24;                % Last hour of day 150
plot_range_3days = start_hour:end_hour;

%% Figure 4(a): Solar Power Generation (Annual)
figure('Position', [100, 100, 500, 180]);
plot(time_axis_annual, solar_annual_scaled(annual_range), 'b-', 'LineWidth', 1);
xlabel('Time [hour]');
ylabel('Power [kW]'); 
grid on;
%title('Annual Solar Power Generation');
% X-axis labels for 1000-hour intervals
xticks([0, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000]);
xticklabels({'0', '1000', '2000', '3000', '4000', '5000', '6000', '7000', '8000'});
xlim([0 8760]);

%% Figure 4(b): flow (Annual) 
figure('Position', [100, 100, 500, 180]);
plot(time_axis_annual, annual_hourly_flow(annual_range)*3600, 'b-', 'LineWidth', 1);
xlabel('Time [hour]');
ylabel('Flow [m^3/h]'); 
grid on;
%title('Annual Rainfall');
% X-axis labels for 1000-hour intervals
xticks([0, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000]);
xticklabels({'0', '1000', '2000', '3000', '4000', '5000', '6000', '7000', '8000'});
xlim([0 8760]);

%% Figure 4(c): Electricity Price (Annual)
figure('Position', [100, 100, 500, 180]);
plot(time_axis_annual, price(annual_range)', 'b-', 'LineWidth', 1);
xlabel('Time [hour]');
ylabel('Price [JPY/kWh]'); 
grid on;
% X-axis labels for 1000-hour intervals
xticks([0, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000]);
xticklabels({'0', '1000', '2000', '3000', '4000', '5000', '6000', '7000', '8000'});
xlim([0 8760]);

%% Figure 7: Water Reservoir Annual Volume Transitions (8760 hours)
figure('Position', [100, 100, 400, 400]); 

% Reservoir 1
subplot(3,1,1);
plot(time_axis_annual, xV1(annual_range+1), 'b-', 'LineWidth', 1); hold on;
plot(time_axis_annual, [V_min(1) V_min(1)*ones(1,length(annual_range)-1)], 'r--', 'LineWidth', 1);
plot(time_axis_annual, [V_max(1) V_max(1)*ones(1,length(annual_range)-1)], 'r--', 'LineWidth', 1);
xlabel('Time [hour]');
ylabel('Dam#1 [m^3]');
%leg1 = legend('Water Level', 'Limits', 'Location', 'best');
%set(leg1, 'FontSize', 8);
grid on;
% X-axis labels for 1000-hour intervals
xticks([0, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000]);
xticklabels({'0', '1000', '2000', '3000', '4000', '5000', '6000', '7000', '8000'});
xlim([0 8760]);
ylim([0 Vmain(1)])

% Reservoir 2
subplot(3,1,2);
plot(time_axis_annual, xV2(annual_range+1), 'b-', 'LineWidth', 1); hold on;
plot(time_axis_annual, [V_min(2) V_min(2)*ones(1,length(annual_range)-1)], 'r--', 'LineWidth', 1);
plot(time_axis_annual, [V_max(2) V_max(2)*ones(1,length(annual_range)-1)], 'r--', 'LineWidth', 1);
xlabel('Time [hour]');
ylabel('Dam#2 [m^3]');
%leg2 = legend('Water Level', 'Limits', 'Location', 'best');
%set(leg2, 'FontSize', 8);
grid on;
% X-axis labels for 1000-hour intervals
xticks([0, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000]);
xticklabels({'0', '1000', '2000', '3000', '4000', '5000', '6000', '7000', '8000'});
xlim([0 8760]);
ylim([0 Vmain(2)])

% Reservoir 3
subplot(3,1,3);
plot(time_axis_annual, xV3(annual_range+1), 'b-', 'LineWidth', 1); hold on;
plot(time_axis_annual, [V_min(3) V_min(3)*ones(1,length(annual_range)-1)], 'r--', 'LineWidth', 1);
plot(time_axis_annual, [V_max(3) V_max(3)*ones(1,length(annual_range)-1)], 'r--', 'LineWidth', 1);
xlabel('Time [hour]');
ylabel('Dam#3 [m^3]');
%leg3 = legend('Water Level', 'Limits', 'Location', 'best');
%set(leg3, 'FontSize', 8);
grid on;
% X-axis labels for 1000-hour intervals
xticks([0, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000]);
xticklabels({'0', '1000', '2000', '3000', '4000', '5000', '6000', '7000', '8000'});
xlim([0 8760]);
ylim([0 Vmain(3)])

%% Figure 8: Small Reservoir Annual Volume Transitions
figure('Position', [100, 100, 400, 250]); 

% Small Reservoir 1
subplot(2,1,1);
plot(time_axis_annual, xVS1(annual_range+1), 'b-', 'LineWidth', 1); hold on;
plot(time_axis_annual, [VS1_min(1) VS1_min(1)*ones(1,length(annual_range)-1)], 'r--', 'LineWidth', 1);
plot(time_axis_annual, [VS1_max(1) VS1_max(1)*ones(1,length(annual_range)-1)], 'r--', 'LineWidth', 1);
xlabel('Time [hour]');
ylabel('Pond#1 [m^3]');
%leg1 = legend('Water Level', 'Limits', 'Location', 'best');
%set(leg1, 'FontSize', 8);
grid on;
% X-axis labels for 1000-hour intervals
xticks([0, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000]);
xticklabels({'0', '1000', '2000', '3000', '4000', '5000', '6000', '7000', '8000'});
xlim([0 8760]);
ylim([0 Vsub1(1)])

% Small Reservoir 2
subplot(2,1,2);
plot(time_axis_annual, xVS2(annual_range+1), 'b-', 'LineWidth', 1); hold on;
plot(time_axis_annual, [VS1_min(2) VS1_min(2)*ones(1,length(annual_range)-1)], 'r--', 'LineWidth', 1);
plot(time_axis_annual, [VS1_max(2) VS1_max(2)*ones(1,length(annual_range)-1)], 'r--', 'LineWidth', 1);
xlabel('Time [hour]');
ylabel('Pond#2 [m^3]');
%leg1 = legend('Water Level', 'Limits', 'Location', 'best');
%set(leg1, 'FontSize', 8);
grid on;
% X-axis labels for 1000-hour intervals
xticks([0, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000]);
xticklabels({'0', '1000', '2000', '3000', '4000', '5000', '6000', '7000', '8000'});
xlim([0 8760]);
ylim([0 Vsub1(2)])

%% Figure 9: Power Supply-Demand Balance (3-day period)
figure('Position', [100, 100, 700, 180]);

% Data adjustment for 3-day period
supply = [xP_gen1(plot_range_3days), xP_gen2(plot_range_3days), solar_output(plot_range_3days)];
demand = [-xP_pump1(plot_range_3days), -xP_pump2(plot_range_3days), -xsolar_curtailment(plot_range_3days)];

% IEEE-friendly colors
colors_supply = [0, 0.4470, 0.7410;   % Blue
                 0.4660, 0.6740, 0.1880;   % Green
                 0.9290, 0.6940, 0.1250];  % Yellow

colors_demand = [0.8500, 0.3250, 0.0980;   % Orange
                 0.4940, 0.1840, 0.5560;   % Purple
                 0.6350, 0.0780, 0.1840];  % Dark Red

% Create stacked bar plots with custom colors
h1 = bar(plot_range_3days, supply, 'stacked'); hold on;
for i = 1:length(h1)
    h1(i).FaceColor = colors_supply(i,:);
end

h2 = bar(plot_range_3days, demand, 'stacked');
for i = 1:length(h2)
    h2(i).FaceColor = colors_demand(i,:);
end

% Day separator lines with day labels
for day = day_start:day_end
    day_hour = (day - 1) * 24 + 1;
    y_min = min(min(sum(demand, 2)));
    y_max = max(max(sum(supply, 2)));
    plot([day_hour day_hour], [y_min y_max], 'k:', 'LineWidth', 0.5);
    
    % Add day labels above the plot at day boundaries
    if day >= day_start
        text(day_hour+12, 400*1.07, ['Day ', num2str(day)], 'FontSize', 9, 'HorizontalAlignment', 'center');
    end
end
% % Add first day label
% text(start_hour, max(max(sum(supply, 2)))*1.03, ['Day ', num2str(day_start)], 'FontSize', 9, 'HorizontalAlignment', 'center');

% Transmission line limit
plot([start_hour end_hour], [LineMax LineMax], 'r:', 'LineWidth', 1.5); 
ylim([-200 400])
xlabel('Time [hour]');
ylabel('Power [kW]');
leg = legend([h1(1), h1(2), h1(3), h2(1), h2(2), h2(3)], ...
       {'Generation 1', 'Generation 2', 'PV', 'Pumping 1', 'Pumping 2', 'Curtailment'}, ...
       'Location', 'eastoutside', 'Orientation', 'horizontal', 'NumColumns', 1);
set(leg, 'FontSize', 9);
grid on;

% X-axis ticks at meaningful points - beginning of each day and end of period
day_hours = [(day_start-1)*24+1, day_start*24+1, (day_start+1)*24+1, (day_start+2)*24];
labels = {'3553', '3577', '3601'};  % Hour numbers within year
xticks(day_hours);
xticklabels(labels);

% Annotate X-axis to indicate days
annotation('textbox', [0.5, 0.01, 0, 0], 'String', 'Operation for Days 148-150', ...
           'FontSize', 10, 'FontName', 'Times New Roman', 'HorizontalAlignment', 'center', ...
           'EdgeColor', 'none');

