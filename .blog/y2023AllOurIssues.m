%% 
% Who doesn't have issues amirite? Let's just take a moment and acknowledge
% this fact and I think we will all be a bit more honest and understanding
% of all of our unique issues and the various idiosyncracies we all
% exhibit. Thank you for living with my issues, and I will try to return
% the favor and offer grace and patience with yours. Some of these issues
% are pretty important to address quickly, and some we can perhaps choose
% to work on them when the time is right.
% 
% ...and so it is with our code as well. Issues crop up all the time in any
% serious codebase. Most of you are probably quite aware of the great
% features of the Code Analyzer in MATLAB that does a great job of alerting
% you to your issues directly in the MATLAB editor. However, sometimes
% issues still can creep into a code base through a number of subtle means,
% even including my own personal issue of failing to action a helpful
% editor trying to tell me I have a problem in my code.
%
% However, in R2022b there was a great improvement to the programmatic
% interface for identifying and addressing with these code issues. In fact,
% this new interface is itself a new function called
% <https://www.mathworks.com/help/matlab/ref/codeissues.html codeIssues>!
%
% This new programmatic interface to the code analyzer is in a word
% powerful. Let's explore how you can now use this to build in quality to
% your project. Let's take another look at our standaard mass-spring-damper
% mini-codebase. Most recently we talked about this when describing the
% <https://blogs.mathworks.com/developer/2022/10/17/building-blocks-with-buildtool/
% new MATLAB build tool>. This code base is pretty simple. A simulator, a
% function to return some design constants (spring constant, damping
% coefficent, etc), and some tests.
% 
% <<y2023ToolboxFoldersAndFiles.png>>
% 
% To get started, just call codeIssues on the folder you want to analyze:
myIssues = codeIssues("toolbox")

%%
% You can see that with just a simple call to codeIssues you can quickly
% get an overview of all the details a static analyzer dreams of. You can
% easily dig into the files that were analyzed, the configuration, and also
% a very handy table of the issues found, as well as any issues that have
% been suppressed through suppression pragmas in the editor.
%
% Now with this beautiful API at our fingertips, and with the build tool to
% boot, we can lock down our code in a much more robust, automated way. We
% can start roughly where we left off at the end of our build tool post
% with the following buildfile with a mex and a test task:
%
% <include>.hidden/starting_build/buildfile.m</include>
%
% Let's go ahead and add a "codeIssues" task to this build by creating a new
% localfunction called *|codeIssuesTask|*
%
% <include>.hidden/codesnippets/codeIssuesTask1.m</include>
%
% This is quite simple, we just want to find all the issues under the
% toolbox folder and throw an assertion error if any of them are of
% Severity "error". This is just about the quickest win you can apply to a
% code base to build quality into it. This can find syntax and other errors
% statically, without even writing a single test. There is really no reason
% we shouldn't apply this task to every development process in every
% project. It costs virtualy nothing and can only find bugs. On that note,
% let's add it as a default task in our buildfile:
%
% <include>.hidden/codesnippets/defaultTasks.m</include>
%
% ...and with that we now have this check built right into our standard
% development process. To show this first let's put a file with an error
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
% Once we remove that bunk error you can see not only do we get passed our
% "codeIssues" task we also complete the other "mex" and "test" tasks to complete
% the whole workflow.
delete toolbox/syntaxError.m
buildtool

%%
%
% *One last thing* 
%
% Now we have you all setup nice and cozy with the protection that static
% analysis gives you. We could also fail the build on warnings if we'd
% like, but I didn't want to start with that idea out of the gate. It is
% pretty clear that we want this protection with full-on-bonafide errors,
% which are almost always bugs (and we can suppress those that are
% deliberate). However, your code base may already have an inventory of
% warnings. Yes, it would be fantastic to go through that inventory and fix
% all of those warnings as well (the new code analysis tooling makes that
% very easy in many cases!). However, you may not be up for this right now.
% Your code base may be large, and you may want or need to invest a bit
% more time into this activity. So our first crack at this failed the build
% only for issues with an "error" Severity.
%
% However, if you know me you know I like to sneak one last thing in. What
% if we accepted all of our current warnings in the codebase, but wanted to
% lock down our code base such that we are protected from introducing new
% warnings? To me this sounds like a great idea. We can then ratchet down
% our warnings by preventing inflow of new warnings and can remove existing
% warnings over time through interacting with the codebase. How can we do
% this? We can leverage the power of the codeIssues programmatic api!
%
% We are going to do this by saving our existing warnings to a baseline of
% known issues. Being a MATLAB table, a really nice representation so save
% these known issues is a *.csv or *.xls file. Saving the known issues in
% this format makes it really easy to tweak them, open them outside of
% MATLAB, or even remove issues that have been fixed.
% 
% To do this we just need to make a couple tweaks to the issues table, such
% as removing the *|Location|* variable, adjusting the *|FullFilename|*
% variable to contain a *|RelativeFilename|* array, and various datatype
% tweaks to make for good CSV'ing. The relative filename is an important
% tweak, because we want to be able to compare from the project root
% folder, but the full path is likely to differ from machine to machine,
% whether that is two engineer trying to collaborate or different build
% agents in a CI system. That function looks as follows:
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

type knownIssues.csv

%%
% Beautiful. In this case we just have two minor warnings that I don't want
% to look into quite yet. However, now we can adjust the "codeIssues" task
% to prevent me from introducing anything new:
%
% <include>.hidden/codesnippets/codeIssuesTask2.m</include>
% <include>.changes/codeWarning.m</include>
copyfile .changes/codeWarning.m toolbox/codeWarning.m
try
    buildtool
catch ex
    disp(ex.getReport("basic"));
end

delete toolbox/codeWarning.m
