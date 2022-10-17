%% 
% My people! Oh how I have missed you. It has been such a long time since
% we have talked about some developer workflow goodness here on the blog. I
% have found it hard to sit down and write up more thoughts and musings on
% these topics, but the silver lining here is a big reason for my lack of
% time is that we have been hard at work delivering development
% infrastructure for MATLAB.
%
% One of those things is the new build tool for MATLAB that included in
% R2022b! We are super excited about this tool's rookie release, but
% even more excited for all the value that will come of it as you begin
% using it for your MATLAB projects. 
%
% What is this thing anyway? Well in short it is a standard interface for
% you to build and collaborate on your MATLAB projects. "Build?", you say?
%
% Yes, "Build!", I say. Anyone developing serious, shareable, production
% grade MATLAB code knows that even though MATLAB is an "easy-to-leverage"
% language that typically doesn't require an actual "compile" step, it
% still requires a development process that includes tasks like testing,
% quality gates, and bumping a release number. Also it turns out that there
% are many ways in which MATLAB does indeed _*build*_ something. Think mex
% files, p-code, code generation, toolbox packages, doc pages, or producing
% artifacts from MATLAB Compiler and Compiler SDK. These are all build
% steps.
%
% The issue though, has been that there has been no standard API for MATLAB
% projects to organize these build steps. It usually ends up looking
% something like this:
%
% <<y2022JustAdHocScripts.png>>
% 
% Does this look familiar? It does to me. All of these scripts grow in a
% project or repo for doing these specific tasks. Each one looks a little
% different because one was written on Tuesday and the other the following
% Monday. If we are lucky, we remember how these all work when we need to
% interact with them. However, sometimes we are not lucky. Sometimes we go
% back to our code and haven't the foggiest idea how we built it, in what
% order, and with which scripts. 
%
% Also, know who is _never_ so lucky? A new contributor. Someone who wants
% to contribute to your code and hasn't learned the system you have put in
% place to develop the project. Some projects are rigorous and do indeed
% have their own custom-authored build framework put in place. This is
% great for them, but requires more maintenance, and even in these cases a
% new developer on the project needs to learn this custom system, which is
% different than all the other systems to build MATLAB code.
%
% Well, not anymore. Starting in
% <https://www.mathworks.com/help/matlab/build-automation.html?s_tid=CRUX_lftnav
% R2022b we now have a standard interface and build framework> that enables
% project owners to easily produce their build in a way that anyone else
% can consume, no matter how complicated the build pipeline is. We now can
% move from ad-hoc scripts and custom build systems to a known, structured,
% and standard framework.
%
% <<y2022AdHoc2BuildTool.png>>
%
% Let's take my favorite simple Mass-Spring-Damper example (looks like I am
% still a mechanical engineer at heart). This is a simple example "toolbox"
% that has 3 components, a design script *|springMassDamperDesign.m|* that
% defines stiffness and damping constants for the system, a function
% *|simulateSystem.m|* that simulates the system from an initial condition
% outside of equilibrium to show a step response, and a mex file
% *|convec.c|* that convolves two arrays, which might be a useful utility
% for a dynamic system such as this. It also has a couple tests to ensure
% all is well and good as the code changes.
%
% <<y2022ToolboxFoldersAndFiles.png>>
%
% Hopefully the author of this code knows all about these components and
% why they were written as they were. However, if I am a contributor for
% the first time to this code base I have no idea. My workflow might look
% something like this:
%
% # Get the code
% # Use the toolbox
% # See there is something I want to change about the toolbox, a feature to
% add or a tweak to the design
% # Make the change
% # Submit the change for the win!!
% 
% Seems like I am setting myself up for a solid contribution, and I am very
% proud of myself. After getting the code I see the initial design looks
% like so:
%
% <include>springMassDamperDesign.m</include>
%
% ...and when simulating using the included function:
% 
% <include>simulateSystem.m</include>
% 
% ...it yields the following response:
[t,y] = simulateSystem(springMassDamperDesign);
plot(y,t)

%%
% Pretty decent, but I think that there is room for improvement. I think we
% can get back to equilibrium sooner, and I like a nice smooth shift that
% slightly overshoots. Because I am an excellent mechanical engineer, this
% is a clearly preferable design, we just need to have a little less
% damping: 
%
addpath .changes/round1

%%
% <include>.changes/round1/springMassDamperDesign.m</include>
%
[t,y] = simulateSystem(springMassDamperDesign);
plot(y,t)

%% 
% ...and submit. This is when I get a dose of humility and experience a
% world of pain. The toolbox maintainer declines my submission because this
% design fails a test already put in place intended to limit the overshoot
% of the response. See?
runtests("tests/designTest.m")

%%
% In retrospect this is easy to predict, there were tests after all. I
% should have run them before submitting. But there was nothing pointing me
% in their direction and I just missed it. For a simple example repo that
% might seem obvious, but for a "real" toolbox this can be hard to see.
% 
% Alright clearly there is more work to do after my contribution was
% declined tersely by an overworked toolbox author. But I am still up to
% the task. After learning that there is an overshoot requirement I can
% tweak my design to fit within these constraints:
addpath .changes/round2

%%
% <include>.changes/round2/springMassDamperDesign.m</include>
%
[t,y] = simulateSystem(springMassDamperDesign);
plot(y,t)

%%
% Looks good, does it pass the test?
runtests("tests/designTest.m")

%% 
% Yes! Finally I must be done. However, when I submit this code I get
% another rejection because there is still a test failing for the mex file
% utility that I didn't even know about:
runtests("tests")

%% 
% Alright, at this point I see that there is some utility that I wasn't
% changing, using, or even familiar with and it's test is failing.
% Furthermore, I realize that it is failing because it isn't compiled. I
% have no idea how to compile this mex file, and at this point I give up
% because I hadn't planned to invest this much time into this contribution.
% I don't have time to learn all the details of this repo (I just wanted to
% tweak the damping coefficient!). After giving up I leave with a bad taste
% in my mouth. I am probably done trying to contribute to this code base,
% and actually may even think twice before trying to contribute to some
% other code base. Not good. No buena. Nicht gut.

%%
% *Enter buildtool* 
%
% All of this pain can be addressed through using this new build tool. As a
% new contributor, all I need to know is that I need to invoke the build
% tool to go through the author's intended development workflow. I need to
% learn this the first time, but once I am familiar with this standard
% framework I can interact with *any other project* that is also using the
% build tool. Once I see that the root of the project has a file called
% *|buildfile.m|* I know I am in business and I can do anything the author
% intended, including things like running tests and compiling mex files, by
% simply invoking the tool. Let's try it:
buildtool

%%
% Isn't that beautiful? I didn't have to know anything about how the project
% is built and I could get rolling quickly. I can make my small change,
% everything that needs to happen (e.g. building a mex file) happens and
% then we can confirm it doesn't fail the tests. *It makes baking in high
% quality easy(er).*
%
%%
%
% *How's it done?* 
%
% I have been focusing on the perspective of the unfamiliar contributor.
% How can the author/owner use this to set up for success? Well this is
% super simple and leverages an easy to work with scriptable MATLAB
% interface as the fundamental framework. You start by creating your
% *|buildfile.m|*, which is a function that creates your build plan.
%
% <include>.hidden/buildfileSnippet1.m</include>
%
% Passing all of the local functions when you create your build plan makes
% it easy to define simple tasks. This enables you to create tasks from any
% function that ends in the word *|Task|* (or *|task|* or *|_task|* or
% *|tAsK|*, etc). The first comment in the function (the H1 line) gives a
% task description. For this case we have 3 tasks we'd like to add.
%
%%
% *A setup task*
%
% <include>.hidden/buildfileSnippet2.m</include>
%
% This task ensures that the right paths are in place for the build. You
% might ask whether this should be done using a MATLAB Project, and the
% answer is yes absolutely! That is a better way. For now we are building this
% in but will projectify it in a later post.
%
% *A mex task*
%
% <include>.hidden/buildfileSnippet3.m</include>
%
% This is a pretty simple compile in this example, but for many projects
% this step can be more involved. Simple or complex, here is where you
% can make it trivial for the newcomer.
%
% *A test task*
%
% <include>.hidden/buildfileSnippet4.m</include>
%
% Straightforward. Now that those tasks are defined and automatically
% included in your build file anyone can see what tasks can be run:
buildtool -tasks

%% 
% Great, we can see our 3 tasks, but as you might predict that these tasks
% can't be run in just any order. The tests won't pass unless the proper
% code is on the path and the mex file is built. These task dependency
% relationships can be defined in the main function as you setup your plan.
% We need to add these dependencies, and while we are at it, let's setup a
% default task so that
% *|buildtool|* will work without even passing any arguments.
%
% <include>.hidden/buildfileSnippet5.m</include>
%
% Now we can invoke it by default by just calling *|buildtool|* (as we did
% above) or we can invoke a specific task we'd like to run such as mex and
% it will just run what is required for that task:
buildtool mex

%% 
% Here is the full buildfile for your reference:
%
% <include>buildfile.m</include>
%
% Alright with that I am going or send you off to begin your MATLAB project
% development adventures with the new build tool. We'd love to hear your
% feedback. Let's make this a series! I am going to blog a few more times
% on this so you can see this project grow in capabilities and really start
% to leverage this build framework. Also, we are working like crazy on
% future capabilities for this tool. So on multiple fronts this is just the
% beginning of much more to come.
