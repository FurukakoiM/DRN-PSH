%% Cascade Dam Cluster and Pond Network Analysis
% Constraints:
% 1. Dams within 1.5km form cascade connections (comb-shaped topology)
% 2. Direct pond-to-pond connections are not allowed
% 3. Each pond can connect to at most one dam (no duplication)

clear all; close all;

%% Configuration Parameters
CASCADE_DISTANCE = 1.5;  % Maximum connection distance between dams (km)
POND_DISTANCE = 1.0;     % Maximum connection distance for ponds (km)
EARTH_RADIUS = 6371;     % Earth radius (km)

%% Data Loading and Preparation
% Pond data
pond_data = readtable('yamaguchi_pond.xlsx', 'VariableNamingRule', 'preserve');
pond_no = pond_data{:, 1};
pond_lat = pond_data{:, 6} + pond_data{:, 7}/60 + pond_data{:, 8}/3600;
pond_lon = pond_data{:, 9} + pond_data{:, 10}/60 + pond_data{:, 11}/3600;
pond_volume = pond_data{:, 14};

% Dam data
dam_data = readtable('yamaguchi_dam.xlsx', 'VariableNamingRule', 'preserve');
dam_code = dam_data{:, 2};
dam_lat = dam_data{:, 15};
dam_lon = dam_data{:, 16};
dam_volume = dam_data{:, 10};

% Integrate data
all_locations = table();
all_locations.lat = [dam_lat; pond_lat];
all_locations.lon = [dam_lon; pond_lon];
all_locations.volume = [dam_volume; pond_volume];
all_locations.type = [ones(length(dam_lat), 1); zeros(length(pond_lat), 1)];
all_locations.id = [dam_code; pond_no];

% Fix negative volumes to zero
all_locations.volume(all_locations.volume < 0) = 0;

% Dam and pond indices
dam_idx = find(all_locations.type == 1);
pond_idx = find(all_locations.type == 0);

%% Distance Matrix Calculation
n_locations = height(all_locations);
distances = zeros(n_locations, n_locations);

% Calculate distances using Haversine formula
for i = 1:n_locations
    for j = i+1:n_locations
        lat1 = all_locations.lat(i) * pi/180;
        lon1 = all_locations.lon(i) * pi/180;
        lat2 = all_locations.lat(j) * pi/180;
        lon2 = all_locations.lon(j) * pi/180;
        
        dlat = lat2 - lat1;
        dlon = lon2 - lon1;
        
        a = sin(dlat/2)^2 + cos(lat1) * cos(lat2) * sin(dlon/2)^2;
        c = 2 * atan2(sqrt(a), sqrt(1-a));
        dist = EARTH_RADIUS * c;
        
        distances(i, j) = dist;
        distances(j, i) = dist;
    end
end

%% Identify Cascade Dam Chains (Comb-shaped)
% Check dam connectivity (within 1.5km)
n_dams = length(dam_idx);
dam_connections = zeros(n_dams, n_dams);

for i = 1:n_dams
    for j = 1:n_dams
        if i ~= j && distances(dam_idx(i), dam_idx(j)) <= CASCADE_DISTANCE
            dam_connections(i, j) = 1;
        end
    end
end

% Identify comb-shaped (chain) dam groups
visited = false(n_dams, 1);
dam_chains = {};

% Calculate connection count for each dam
connection_counts = sum(dam_connections, 2);

% Start from endpoints (connection count = 1) and build chains
endpoints = find(connection_counts == 1);

for start_point = endpoints'
    if visited(start_point)
        continue;
    end
    
    % Build chain
    chain = [];
    current = start_point;
    
    while ~visited(current)
        visited(current) = true;
        chain = [chain, current];
        
        % Find unvisited adjacent dams
        neighbors = find(dam_connections(current, :) & ~visited');
        
        if isempty(neighbors)
            break;
        else
            current = neighbors(1);
        end
    end
    
    if ~isempty(chain)
        dam_chains{end+1} = chain;
    end
end

% Process remaining isolated dams
for i = 1:n_dams
    if ~visited(i)
        dam_chains{end+1} = i;
    end
end

%% Pond Connection (each pond connects to nearest dam)
n_ponds = length(pond_idx);
pond_assignments = zeros(n_ponds, 1);

for i = 1:n_ponds
    pond = pond_idx(i);
    dam_distances = distances(pond, dam_idx);
    
    % Find nearest dam within distance limit
    valid_dams = find(dam_distances <= POND_DISTANCE);
    
    if ~isempty(valid_dams)
        [~, nearest_idx] = min(dam_distances(valid_dams));
        pond_assignments(i) = dam_idx(valid_dams(nearest_idx));
    end
end

%% Create Cascade Clusters
cascade_clusters = struct('group_id', {}, 'dam_indices', {}, 'num_dams', {}, ...
                         'dam_info', {}, 'total_volume', {}, 'total_ponds', {});

for g = 1:length(dam_chains)
    chain = dam_chains{g};
    chain_dam_indices = dam_idx(chain);
    
    % Collect information for each dam in this chain
    dam_info = [];
    total_volume = 0;
    total_ponds = 0;
    
    for d = 1:length(chain_dam_indices)
        dam_index = chain_dam_indices(d);
        dam_code_value = all_locations.id(dam_index);
        dam_volume_value = all_locations.volume(dam_index);
        
        % Identify ponds connected to this dam
        connected_ponds = pond_idx(pond_assignments == dam_index);
        pond_volumes = all_locations.volume(connected_ponds);
        pond_ids = all_locations.id(connected_ponds);
        
        info = struct();
        info.dam_idx = dam_index;
        info.dam_code = dam_code_value;
        info.connected_ponds = connected_ponds;
        info.pond_ids = pond_ids;
        info.dam_volume = dam_volume_value;
        info.ponds_volume = sum(pond_volumes);
        info.total_volume = dam_volume_value + sum(pond_volumes);
        
        dam_info = [dam_info, info];
        total_volume = total_volume + info.total_volume;
        total_ponds = total_ponds + length(connected_ponds);
    end
    
    cluster = struct();
    cluster.group_id = g;
    cluster.dam_indices = chain_dam_indices;
    cluster.num_dams = length(chain_dam_indices);
    cluster.dam_info = dam_info;
    cluster.total_volume = total_volume;
    cluster.total_ponds = total_ponds;
    
    cascade_clusters(g) = cluster;
end

% Sort by number of dams (descending) and total volume (descending)
[~, sort_idx] = sortrows([-[cascade_clusters.num_dams]', -[cascade_clusters.total_volume]']);
cascade_clusters = cascade_clusters(sort_idx);

%% Display Results (Table 3)
fprintf('===== Cascade Dam Cluster Analysis Results =====\n\n');

for i = 1:length(cascade_clusters)
    cluster = cascade_clusters(i);
    fprintf('Cluster %d: %d dams, Total volume: %.1f thousand m³\n', ...
            i, cluster.num_dams, cluster.total_volume);
    
    % Display in chain order
    for d = 1:length(cluster.dam_info)
        dam = cluster.dam_info(d);
        fprintf('  Dam%d (Code:%d): ', d, dam.dam_code);
        fprintf('Volume=%.1f thousand m³, ', dam.dam_volume);
        fprintf('Connected ponds=%d', length(dam.connected_ponds));
        
        if ~isempty(dam.pond_ids)
            fprintf(' (No.');
            fprintf('%d', dam.pond_ids(1));
            for p = 2:length(dam.pond_ids)
                fprintf(',%d', dam.pond_ids(p));
            end
            fprintf(')');
        end
        
        fprintf(', Pond volume=%.1f thousand m³, ', dam.ponds_volume);
        fprintf('Total=%.1f thousand m³\n', dam.total_volume);
    end
    fprintf('\n');
end

%% Visualization Setup
% Set figure properties for IEEE publication standards
set(0, 'DefaultAxesFontName', 'Times New Roman');
set(0, 'DefaultTextFontName', 'Times New Roman');
set(0, 'DefaultAxesFontSize', 10);
set(0, 'DefaultTextFontSize', 10);
set(0, 'DefaultLineLineWidth', 1);

% Color setup
colors = lines(length(cascade_clusters));

% Yamaguchi Prefecture latitude/longitude range
lat_yamaguchi = [33.674 34.8428];
lon_yamaguchi = [130.725 132.538];

%% Figure 5(a): Overview Map of All Cascade Clusters
figure('Position', [100, 100, 500, 400]);
ax = worldmap(lat_yamaguchi, lon_yamaguchi);

% Load and display prefecture boundaries
try
    japan_prefectures = readgeotable('N03-20240101_35.shp');
    geoshow(japan_prefectures, 'FaceColor', 'none', 'EdgeColor', 'black');
catch
    warning('Prefecture boundary shapefile not found. Skipping boundary display.');
end

% Plot all ponds and dams as background
h1 = geoshow(all_locations.lat(pond_idx), all_locations.lon(pond_idx), ...
    'DisplayType', 'point', 'Marker', 'o', 'MarkerEdgeColor', 'blue', 'MarkerSize', 6);
h2 = geoshow(all_locations.lat(dam_idx), all_locations.lon(dam_idx), ...
    'DisplayType', 'point', 'Marker', 's', 'MarkerEdgeColor', 'black', ...
    'MarkerFaceColor', 'black', 'MarkerSize', 8);

% Display each chain with different colors
for i = 1:length(cascade_clusters)
    cluster = cascade_clusters(i);
    chain_indices = cluster.dam_indices;
    
    % Draw connection lines in chain order
    for j = 1:length(chain_indices)-1
        idx1 = chain_indices(j);
        idx2 = chain_indices(j+1);
        if distances(idx1, idx2) <= CASCADE_DISTANCE
            geoshow([all_locations.lat(idx1), all_locations.lat(idx2)], ...
                [all_locations.lon(idx1), all_locations.lon(idx2)], ...
                'Color', colors(i,:), 'LineWidth', 3);
        end
    end
    
    % Highlight cluster dams
    geoshow(all_locations.lat(chain_indices), all_locations.lon(chain_indices), ...
        'DisplayType', 'point', 'Marker', 's', 'MarkerEdgeColor', colors(i,:), ...
        'MarkerFaceColor', colors(i,:), 'MarkerSize', 10);
end

gridm on;
legend([h2, h1], {'Dam', 'Pond'}, 'Location', 'northeast');
set(gcf, 'Color', 'white');
box on;

%% Figure 5(b): Largest Dam Cluster Detail
largest_cluster = cascade_clusters(1);
figure('Position', [100, 100, 500, 400]);
ax = worldmap(lat_yamaguchi, lon_yamaguchi);

% Load prefecture boundaries
try
    japan_prefectures = readgeotable('N03-20240101_35.shp');
    geoshow(japan_prefectures, 'FaceColor', 'none', 'EdgeColor', 'black');
catch
    warning('Prefecture boundary shapefile not found. Skipping boundary display.');
end

% Background elements with lighter colors
h1 = geoshow(all_locations.lat(pond_idx), all_locations.lon(pond_idx), ...
    'DisplayType', 'point', 'Marker', 'o', 'MarkerEdgeColor', [0.8 0.8 1], 'MarkerSize', 4);
h2 = geoshow(all_locations.lat(dam_idx), all_locations.lon(dam_idx), ...
    'DisplayType', 'point', 'Marker', 's', 'MarkerEdgeColor', [0.8 0.8 0.8], 'MarkerSize', 6);

% Display largest cluster
chain_indices = largest_cluster.dam_indices;

% Chain connections
for j = 1:length(chain_indices)-1
    idx1 = chain_indices(j);
    idx2 = chain_indices(j+1);
    if distances(idx1, idx2) <= CASCADE_DISTANCE
        geoshow([all_locations.lat(idx1), all_locations.lat(idx2)], ...
            [all_locations.lon(idx1), all_locations.lon(idx2)], ...
            'Color', colors(1,:), 'LineWidth', 3);
    end
end

h3 = geoshow(all_locations.lat(chain_indices), all_locations.lon(chain_indices), ...
    'DisplayType', 'point', 'Marker', 's', 'MarkerEdgeColor', colors(1,:), ...
    'MarkerFaceColor', colors(1,:), 'MarkerSize', 10);

% Display connected ponds
pond_found = false;
for d = 1:length(largest_cluster.dam_info)
    dam = largest_cluster.dam_info(d);
    if ~isempty(dam.connected_ponds)
        if ~pond_found
            h4 = geoshow(all_locations.lat(dam.connected_ponds), ...
                all_locations.lon(dam.connected_ponds), ...
                'DisplayType', 'point', 'Marker', 'o', 'MarkerEdgeColor', colors(1,:), ...
                'MarkerFaceColor', colors(1,:), 'MarkerSize', 6);
            pond_found = true;
        else
            geoshow(all_locations.lat(dam.connected_ponds), ...
                all_locations.lon(dam.connected_ponds), ...
                'DisplayType', 'point', 'Marker', 'o', 'MarkerEdgeColor', colors(1,:), ...
                'MarkerFaceColor', colors(1,:), 'MarkerSize', 6);
        end
        
        % Draw connections to ponds
        for p = dam.connected_ponds'
            geoshow([all_locations.lat(dam.dam_idx), all_locations.lat(p)], ...
                [all_locations.lon(dam.dam_idx), all_locations.lon(p)], ...
                'Color', colors(1,:), 'LineWidth', 1.5, 'LineStyle', '--');
        end
    end
end

gridm on;
if pond_found
    legend([h2, h1, h3, h4], {'Background Dam', 'Background Pond', ...
        'Cluster Dam', 'Connected Pond'}, 'Location', 'northeast');
else
    legend([h2, h1, h3], {'Background Dam', 'Background Pond', 'Cluster Dam'}, ...
        'Location', 'northeast');
end
set(gcf, 'Color', 'white');
box on;

%% Figure 5(c): Zoomed View of Largest Cluster
figure('Position', [100, 100, 500, 400]);

% Determine zoom extent based on first dam in largest cluster
target_dam_idx = largest_cluster.dam_indices(1);
target_dam_lat = all_locations.lat(target_dam_idx);
target_dam_lon = all_locations.lon(target_dam_idx);

zoom_lat = [target_dam_lat-0.02, target_dam_lat+0.02]; 
zoom_lon = [target_dam_lon-0.02, target_dam_lon+0.02];

ax = worldmap(zoom_lat, zoom_lon);
setm(ax, 'MLabelLocation', 0.04);

% Load prefecture boundaries
try
    japan_prefectures = readgeotable('N03-20240101_35.shp');
    geoshow(japan_prefectures, 'FaceColor', 'none', 'EdgeColor', 'black');
catch
    warning('Prefecture boundary shapefile not found. Skipping boundary display.');
end

    %     waterways = readgeotable('waterway.shp');
    %     h_water = geoshow(waterways, 'Color', [0.7, 0.7, 1.0], 'LineWidth', 0.6);

% Background
h1 = geoshow(all_locations.lat(pond_idx), all_locations.lon(pond_idx), ...
    'DisplayType', 'point', 'Marker', 'o', 'MarkerEdgeColor', [0.8 0.8 1], 'MarkerSize', 4);
h2 = geoshow(all_locations.lat(dam_idx), all_locations.lon(dam_idx), ...
    'DisplayType', 'point', 'Marker', 's', 'MarkerEdgeColor', [0.8 0.8 0.8], 'MarkerSize', 6);

% Display largest cluster details
chain_indices = largest_cluster.dam_indices;

for j = 1:length(chain_indices)-1
    idx1 = chain_indices(j);
    idx2 = chain_indices(j+1);
    if distances(idx1, idx2) <= CASCADE_DISTANCE
        geoshow([all_locations.lat(idx1), all_locations.lat(idx2)], ...
            [all_locations.lon(idx1), all_locations.lon(idx2)], ...
            'Color', colors(1,:), 'LineWidth', 3);
    end
end

h3 = geoshow(all_locations.lat(chain_indices), all_locations.lon(chain_indices), ...
    'DisplayType', 'point', 'Marker', 's', 'MarkerEdgeColor', colors(1,:), ...
    'MarkerFaceColor', colors(1,:), 'MarkerSize', 10);

% Connected ponds
pond_found = false;
for d = 1:length(largest_cluster.dam_info)
    dam = largest_cluster.dam_info(d);
    if ~isempty(dam.connected_ponds)
        if ~pond_found
            h4 = geoshow(all_locations.lat(dam.connected_ponds), ...
                all_locations.lon(dam.connected_ponds), ...
                'DisplayType', 'point', 'Marker', 'o', 'MarkerEdgeColor', colors(1,:), ...
                'MarkerFaceColor', colors(1,:), 'MarkerSize', 6);
            pond_found = true;
        else
            geoshow(all_locations.lat(dam.connected_ponds), ...
                all_locations.lon(dam.connected_ponds), ...
                'DisplayType', 'point', 'Marker', 'o', 'MarkerEdgeColor', colors(1,:), ...
                'MarkerFaceColor', colors(1,:), 'MarkerSize', 6);
        end
        
        for p = dam.connected_ponds'
            geoshow([all_locations.lat(dam.dam_idx), all_locations.lat(p)], ...
                [all_locations.lon(dam.dam_idx), all_locations.lon(p)], ...
                'Color', colors(1,:), 'LineWidth', 1.5, 'LineStyle', '--');
        end
    end
end

gridm on;
if pond_found
    legend([h2, h1, h3, h4], {'Background Dam', 'Background Pond', ...
        'Cluster Dam', 'Connected Pond'}, 'Location', 'northeast');
else
    legend([h2, h1, h3], {'Background Dam', 'Background Pond', 'Cluster Dam'}, ...
        'Location', 'northeast');
end
set(gcf, 'Color', 'white');
box on;

%% Figure 6: Statistics - Number of Dams per Cluster
figure('Position', [100, 100, 500, 180]);
bar([cascade_clusters.num_dams], 'FaceColor', [0.3 0.6 0.5]);
xlabel('Cluster Number', 'FontWeight', 'bold');
ylabel('Number of Dams', 'FontWeight', 'bold');
grid on;
box on;

fprintf('\nAnalysis completed successfully.\n');