function design = springMassDamperDesign(mass)

if nargin
  m = mass;
else
  m = 1500; % Need to know the mass to determine critical damping
end

design.k = 5e6; % Spring Constant
design.c = 1.1e5; % Damping coefficient

