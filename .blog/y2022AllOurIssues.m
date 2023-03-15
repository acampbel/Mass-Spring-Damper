%% 
% Who doesn't have issues amirite? Let's just take a moment and acknowledge
% this fact and I think we will all be a bit more honest and understanding
% of said issues and the various idiosyncracies we all exhibit. Thank you
% for living with my issues, and I will try to return the favor and offer
% grace and patience with yours. Some of these issues are pretty important
% to address quickly, and some we can perhaps choose to work on them when
% the time is right.
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
% To get started, let's just call codeIssues from the root of this project:
codeIssues