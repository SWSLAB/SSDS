function [S, S_TTD, S_cm, F1, prec, recall] = Perf_Score(SSDS_flag, ev, True_flags)
%% ####################################################################################################################
% Code for the paper:
% Detecting and Localizing Cyber-Physical Attack in Water Distribution Systems without Records of Labeled Attacks
% By Mashor Housh, Noy Kadosh, Jack Hadad

% University of Haifa, mhoush@univ.haifa.ac.il
%% ####################################################################################################################
% Developed under Matlab 2018b
%% ####################################################################################################################

% dtev calculates each event duration
for i = 1:length(ev)
    dtev(i) = ev{i}(end) - ev{i}(1)+1;
end

%% Performance measures calculation

% TTD finds the time take to detect each event
for i = 1:length(ev)
    TTD(i) = dtev(i);
    for j = ev{i}
        if SSDS_flag(j) == 1
            TTD(i) = j - ev{i}(1);
            break
        end
    end
end

% S_TTD
S_TTD=1 - sum(TTD ./ dtev) / length(ev);

% Get confusion matrix
C = confusionmat(True_flags, SSDS_flag, 'Order', [0 1]);      % Order = ['Safe', 'Under-attack']

% S_CM
S_cm = (C(1,1) / sum(C(1,:)) + C(2,2) / sum(C(2,:))) / 2;

% S score
S = (S_cm + S_TTD) / 2;

% Precision
prec = C(2,2) / sum(C(:,2));

% Sensitivity or Recall
recall = C(2,2) / sum(C(2,:));

% F1
F1 = (2 * prec * recall) / (prec + recall);





