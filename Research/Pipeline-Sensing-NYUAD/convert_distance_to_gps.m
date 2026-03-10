function [lat_out, lon_out] = convert_distance_to_gps(distance_m, start_lat, start_lon, bearing_deg)
    a = 6378137.0;
    f_inv = 298.257223563;
    f = 1 / f_inv;
    e2 = 2*f - f^2;
    start_lat_rad = deg2rad(start_lat);
    start_lon_rad = deg2rad(start_lon);
    bearing_rad = deg2rad(bearing_deg);
    W = sqrt(1 - e2 * sin(start_lat_rad)^2);
    N = a / W;
    M = a * (1 - e2) / W^3;
    delta_lat_rad = (distance_m * cos(bearing_rad)) / M;
    delta_lon_rad = (distance_m * sin(bearing_rad)) / (N * cos(start_lat_rad));
    lat_out_rad = start_lat_rad + delta_lat_rad;
    lon_out_rad = start_lon_rad + delta_lon_rad;
    lat_out = rad2deg(lat_out_rad);
    lon_out = rad2deg(lon_out_rad);
    lat_out = max(-90, min(90, lat_out));
    if ~(exist('wrapTo180', 'builtin') == 5 || exist('wrapTo180', 'file') == 2)
        lon_out = mod(lon_out + 180, 360) - 180;
    end
end
