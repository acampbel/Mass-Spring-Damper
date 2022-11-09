function mexTask(~)
% Compile mex files

mex mex/convec.c -outdir toolbox/;
end