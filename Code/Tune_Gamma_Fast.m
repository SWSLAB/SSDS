function [gamma]=Tune_Gamma_Fast(X)
%% ####################################################################################################################
% Code for the paper:
% Detecting and Localizing Cyber-Physical Attack in Water Distribution Systems without Records of Labeled Attacks
% By Mashor Housh, Noy Kadosh, Jack Hadad

% University of Haifa, mhoush@univ.haifa.ac.il
%% ####################################################################################################################
% This code requires:
% Matlab Optimizatin toolbox
% Developed under Matlab 2018b
%% ####################################################################################################################
SumVar=sum(var(X));
n=size(X,1);
fun=@(delta)(delta-(log(n-1)-2*log(delta))^-1.5);
options = optimoptions('fsolve','Display','off');
delta=fsolve(fun,0.01,options);
r=log((n-1)/delta^2);
s=sqrt(2*n*SumVar/(n-1)/r);
gamma=0.5/s^2;
end