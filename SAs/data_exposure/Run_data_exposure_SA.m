
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
% Data exposure SA
clc;clear
fracs = 1:-0.1:0.1;
for case_study = {'c','e'}
    for i = 1:length(fracs)
        frac = fracs(i);
        fprintf('Case Study: %s, data exposure level  %d%% \n',case_study{1},frac*100)
        if i ~= 1
            T = Main_data_exposure(case_study{1}, frac);
            Scores.(T.Properties.VariableNames{1}) = T.Variables;
        else
            Scores = Main_data_exposure(case_study{1}, frac);
        end
    end
    switch case_study{1}
        case 'c'
            disp(Scores)
            writetable(Scores,'DataExposureSACtown.csv','WriteRowNames',true)
        case 'e'
            disp(Scores)
            writetable(Scores,'DataExposureSAEtown.csv','WriteRowNames',true)
    end
end
