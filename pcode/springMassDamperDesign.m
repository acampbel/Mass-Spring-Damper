function design = springMassDamperDesign(mass)
% This is the proprietary design of our toolbox
% 
% You can't see inside but I can let you know 
% how to use it.

if nargin
  m = mass;
else
  m = 1500; % Need to know the mass to determine critical damping
end

design.k = 5e6;                  % Spring Constant
design.c = 5e5;
%design.c = 2*m*sqrt(design.k/m); % Damping Coefficient to be critically damped
