%% 
% Who among us doesn't have issues, amirite? Let's just take a moment and
% acknowledge this fact and I think we can always be a bit more honest and
% understanding of all of our unique issues and the various idiosyncrasies
% we exhibit. While we can all offer understanding and grace to each other,
% some of the issues we face can be important to address quickly, and some
% we can perhaps choose to work on when the time is right.
% 
% ...and so it is with our code. Issues, bugs, and other sub-optimal
% constructs crop up all the time in any serious codebase. Many of you are
% already aware of the features of the Code Analyzer in MATLAB that do a
% great job of alerting you to your issues directly in the MATLAB editor.
% However, sometimes issues still can creep into a code base through a
% number of subtle means, even including simply failing to act when a
% helpful editor is trying to tell me I have a problem in my code.
%
% However, in R2022b there was a great improvement to the programmatic
% interface for identifying and addressing with these code issues. In fact,
% this new interface is itself a new function called
% <https://www.mathworks.com/help/matlab/ref/codeissues.html codeIssues>!
%
% This new API for the code analyzer is in a word - powerful. Let's explore
% how you can now use this to build quality into your project. Starting
% with another look at our standard mass-spring-damper mini-codebase. Most
% recently we talked about this when describing the
% <https://blogs.mathworks.com/developer/2022/10/17/building-blocks-with-buildtool/
% new MATLAB build tool>. This code base is pretty simple. It includes a
% simulator, a function to return some design constants (spring constant,
% damping coefficient, etc.), and some tests.
% 
% <<y2023ToolboxFoldersAndFiles.png>>
% 
% To get started on a codebase like this, just call codeIssues on the
% folder you want to analyze:
%
% <<y2023CodeIssuesOutput.png>>
%
% You can see that with just a simple call to codeIssues you can quickly
% get an overview of all the details a static analyzer dreams of. You can
% easily dig into the files that were analyzed, the configuration, and the
% very handy table of the issues found, as well as any issues that have
% been suppressed through suppression pragmas in the editor. If you are in
% MATLAB you can even click on each issue to get right to it in the MATLAB
% editor where it can be fixed or suppressed if needed.
%
% Now with this beautiful API at our fingertips, and with the build tool to
% boot, we can lock down our code in a much more robust, automated way. We
% can start roughly where we left off at the end of our build tool post
% with the following buildfile with a mex and a test task:
%
% <include>.hidden/starting_build/buildfile.m</include>
%
% Let's go ahead and add a "codeIssues" task to this build by creating a new
% local function called *|codeIssuesTask|*:
%
% <include>.hidden/codesnippets/codeIssuesTask1.m</include>
%
% This is quite simple, we just want to find all the issues under the
% "toolbox" folder and throw an assertion error if any of them are of
% Severity "error". This is just about the quickest win you can apply to a
% code base to build quality into it. This can find syntax and other errors
% statically, without even writing or running a single test. There really
% is no reason at all we shouldn't apply this task to every project. It
% costs virtually nothing and can be remarkably efficient at finding bugs.
% On that note, let's add it as a default task in our buildfile:
%
% <include>.hidden/codesnippets/defaultTasks.m</include>
%
% ...and with that we now have this check built right into our standard
% development process. To show this let's first put a file with an error
% into the code base and then we can call the build tool:
%
% <include>.changes/syntaxError.m</include>
% 
copyfile .changes/syntaxError.m toolbox/syntaxError.m
try
    buildtool
catch ex
    disp(ex.getReport("basic"));
end

%%
% The build tool has done its part in stopping our development process in
% its tracks when it sees we have some important syntax errors to address.
%
% Let's remove that bunk error so we can see our "codeIssues" task complete
% successfully. When we do this we also successfully execute the other
% "mex" and "test" tasks to complete the whole workflow.
delete toolbox/syntaxError.m
buildtool

%%
%
% *One last thing* 
%
% Now we have you all setup nice and cozy with the protection that static
% analysis gives you. However, while we fail on static analysis errors, I
% am still uncomfortable with how easy it is to continue to add constructs
% to my code that result in static analysis warnings, which often point to
% real problems in your program. We could also fail the build on warnings
% if we'd like, but I didn't want to start with that idea out of the gate.
%
% It is pretty clear that we want this protection with full-on-bonafide
% errors, which are almost always bugs. We run into a problem though when a
% code base already has an inventory of warnings. It would be fantastic to
% go through that inventory and fix all of those warnings as well. In fact,
% the new code analysis tooling makes that very easy in many cases!
% However, you may not be up for this right now. Your code base may be
% large, and you may want or need to invest a bit more time into this
% activity. So our first crack at this failed the build only for issues
% with an "error" Severity.
%
% However, if you know me you know I like to sneak one last thing in. What
% if we accepted all of our current warnings in the codebase, but wanted to
% lock down our code base such that we are protected from introducing new
% warnings? To me this sounds like a great idea. We can then ratchet down
% our warnings by preventing inflow of new warnings and can remove existing
% warnings over time through interacting with the codebase. How can we do
% this? We can leverage the power of the codeIssues programmatic API!
%
% We can do this by capturing and saving our existing warnings to a
% baseline of known issues. As MATLAB tables, theses issues are in a nice
% representation to save in a *.csv or *.xlsx file. Saving them in this
% format makes it really easy to tweak them, open them outside of MATLAB,
% or even remove issues that have been fixed.
% 
% To do this we just need to make a couple tweaks to the issues table. We
% need to overwrite the *|Location|* variable with relative paths to the
% files, remove the *|FullFilename|* variable, and make a quick datatype
% tweak to allow for nice CSV'ing. The relative filename adjustment is
% important because we want to be able to compare these results across
% different machines and the full path is likely to differ across
% environments. Such environments include the desktops of individual
% engineers as well as different build agents in a CI system. 
% 
% That function looks as follows:
%
% <include>.hidden/codesnippets/preprocessIssues.m</include>
%
% ...and now with this function we can create a new task in the buildfile
% to generate a new baseline:
%
% <include>.hidden/codesnippets/captureWarningsBaselineTask.m</include>
%
% Let's do it!
buildtool captureWarningsBaseline

%%
% Great I now see the csv files. We can take a peek:
type knownIssues.csv

%%
% Beautiful. In this case we just have two minor warnings that I don't want
% to look into quite yet. However, now we can adjust the "codeIssues" task
% to prevent me from introducing anything new:
%
% <include>.hidden/codesnippets/codeIssuesTask2.m</include>
%
% This now loads the issues and does a setdiff to ignore those that are
% already known and captured in our baseline CSV file. This way, at least
% from now on I won't introduce any new warnings to the code base. It can
% only get better from here. Also, if I change some file that has an
% existing warning, there is a decent chance that my build tooling is going
% to yell at me because the existing warning is slightly different. For
% example it might be on a different line due to changes made in the file.
%
% If this happens, great! Make me clean up or suppress the warning while I
% have the file open and modified. That's a feature not a bug. Worst case
% scenario, I can always capture a new baseline if I really can't look into
% it immediately, but I love this approach to help me clean my code through
% the process.
%
% What does this look like? Let's add a file to the codebase with a new
% warning:
%
% <include>.changes/codeWarning.m</include>
%
% ...and invoke the build:
copyfile .changes/codeWarning.m toolbox/codeWarning.m
try
    buildtool
catch ex
    disp(ex.getReport("basic"));
end

delete toolbox/codeWarning.m


%%
% Love it! I am now protected from myself. I can leverage this in my
% standard toolbox development process to help ensure that over time my
% code only gets better, not worse. You could also imagine tweaking this to
% fail or otherwise notify when a warning goes away from the known issues
% so that we have some pressure to help ensure the lockdown gets tighter
% and tighter as time goes on. For reference, here is the final buildfile
% used for this workflow discussed today:
%
% <include>buildfile.m</include>
%
% There you have it, a clean API for MATLAB's code analysis and a standard way
% to include this in the development process using the build tool. I can
% practically feel the quality getting higher!
%
% Folks, there is so much to blog about in the next little while. There's
% more to discuss here on how we can leverage new and improving tools to
% develop clean build and test pipelines for your MATLAB projects. Also, I
% am *so* excited for some really fantastic progress we will be able to
% share shortly. Buckle in, we are gonna be talking about high quality
% test and automation developments for a bit here on this blog. Chime in
% with your insights, tools, and workflows you use as you develop your
% professional MATLAB projects. 