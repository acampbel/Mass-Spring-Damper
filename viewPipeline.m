function viewPipeline(plan, varargin)

tg = matlab.buildtool.TaskGraph.fromPlan(plan, varargin{:});
oldState = warning("off","MATLAB:structOnObject");
cleaner = onCleanup(@() warning(oldState));
stg = struct(tg);
g = stg.Digraph;
plot(flipedge(g),"ArrowSize",24,"NodeFontSize",24,"LineWidth",8,"MarkerSize",24,"Layout","layered","Direction","right")