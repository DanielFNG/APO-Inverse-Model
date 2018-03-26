function y = generateAssistiveProfile(...
    n_points, peak_force, peak_timing, offset_timing)

% Initialise x and y.
y = zeros(n_points,1);
x = linspace(0.0,100.0,n_points);

% Set the rising region of y.
lambda = (pi/2)/peak_timing;
peak_point = round((peak_timing/100)*n_points);
y(1:peak_point) = peak_force*sin(lambda*x(1:peak_point));

% Set the falling region of y. 
lambda = (pi/2)/(offset_timing - peak_timing);
offset_point = round((offset_timing/100)*n_points);
y(peak_point+1:offset_point-1) = ...
    peak_force*cos(lambda*x(2:offset_point-peak_point));

% Set the region of y which is identically zero. 
y(offset_point+1:end) = 0;

end



