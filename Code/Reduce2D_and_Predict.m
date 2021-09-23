function [DV] = Reduce2D_and_Predict(X, Y, a, b, M, Sigma, model, varargin)
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

% Get variates
V1 = X*a;
V2 = Y*b;
V = [V1 V2];

% Scaling
Z = (V - M) ./ Sigma;

% Get DVs
[~, ~, DV]  = svmpredict(-ones(size(Z,1), 1), Z, model, '-q');

%% Plot boundary if requested
if ~cellfun('isempty',varargin(1))
    if varargin{1}
        figure('Name', varargin{2})
        plotboundary((DV > 0)*1, Z, model)
    end
end

end

