function [a, b, M, Sigma, model] = Reduce2D_and_Train(X, Y)
%% ####################################################################################################################
% Code for the paper:
% Detecting and Localizing Cyber-Physical Attack in Water Distribution Systems without Records of Labeled Attacks
% By Mashor Housh, Noy Kadosh, Jack Hadad

% University of Haifa, mhoush@univ.haifa.ac.il
%% ####################################################################################################################
% This code requires:
% svmpredict.mexw64
% svmtrain.mexw64
% Developed under Matlab 2018b
%% ####################################################################################################################

% Get Canonical Correlation Coefficients
[A,B,~,~,~,~] = canoncorr(X,Y);
c = 1;          % For maximum correlation
a=A(:,c);
b=B(:,c);

% Get variates
V1 = X*a;
V2 = Y*b;
V = [V1 V2];

% Scaling
M = mean(V);
Sigma = std(V);
Z = (V - M) ./ Sigma;

% Train SVDD
gamma = Tune_Gamma_Fast(Z);     % Tune Gamma (unspurvised)
model = svmtrain(-ones(length(Z),1), Z, sprintf('-s 5 -c %d -g %f -h 0 -q', 1, gamma));

end

