% Enforce the constraint that the offset timing is at least 15% later than
% the peak timing. 
function tf = xconstraint(X)

tf = X.offset_timing >= X.peak_timing + 15.0;

end