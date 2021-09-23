function [Alarm_tst1 Alarm_tst2 DV_tst1 DV_tst2]=Main(case_study)
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
if case_study == 'c'
    % Load C-Town's Data
    [X_train_dma, X_test1_dma, X_test2_dma, NumDMAs, Fvars, ...
        Pvars, Tvars, ev_test1, ev_test2, Y_test1, Y_test2] = Load_Data('c');
    warning('off')
elseif case_study == 'e'
    % Load E-Town's Data
    [X_train_dma, X_test1_dma, X_test2_dma, NumDMAs, Fvars, ...
        Pvars, Tvars, ev_test1, ev_test2, Y_test1, Y_test2] = Load_Data('e');
    warning('off')
else
    error('Choose network, e for E-town or c for C-Town')
end

%% Kolmogorov-Smirnov test
for i=1:NumDMAs
    for j=1:size(X_train_dma{i},2)
        half = length(X_train_dma{i})/2;
        h{i}(j) = kstest2(X_train_dma{i}(1:half,j),X_train_dma{i}(half+1:end,j),'Alpha',0.01);
        if h{i}(j)==1
            X_train_dma_mod{i}(:,j)=diff(X_train_dma{i}(:,j));
            X_test1_dma_mod{i}(:,j)=diff(X_test1_dma{i}(:,j));
            X_test2_dma_mod{i}(:,j)=diff(X_test2_dma{i}(:,j));
        else
            X_train_dma_mod{i}(:,j)=X_train_dma{i}(1:end-1,j);
            X_test1_dma_mod{i}(:,j)=X_test1_dma{i}(1:end-1,j);
            X_test2_dma_mod{i}(:,j)=X_test2_dma{i}(1:end-1,j);
        end
    end
    % Reduce by 1 to have full days
    X_train_dma{i}=X_train_dma{i}(1:end-1,:);
    X_test1_dma{i}=X_test1_dma{i}(1:end-1,:);
    X_test2_dma{i}=X_test2_dma{i}(1:end-1,:);
end

%% Within-DMA Spatial Analysis (WSA)
plotb = false;                                       % Plot boundary flag
cnt = 1;
for i=1:NumDMAs
    % Define type-combinations
    idX{1}=[Tvars{i}]; idY{1}=[Fvars{i}];            % WaterTable-Flow interaction
    idX{2}=[Tvars{i}]; idY{2}=[Pvars{i}];            % WaterTable-Pressure interaction
    idX{3}=[Fvars{i}]; idY{3}=[Pvars{i}];            % Flow-Pressure interaction
    idX{4}=[Tvars{i}]; idY{4}=[Fvars{i} Pvars{i}];   % WaterTable-Rest interaction
    idX{5}=[Fvars{i}]; idY{5}=[Tvars{i} Pvars{i}];   % Flow-Rest interaction
    idX{6}=[Pvars{i}]; idY{6}=[Tvars{i} Fvars{i}];   % Pressure-Rest interaction
    
    % Delete type-combinations if they are unavailable in DMA i
    flag = (~cellfun(@isempty, idX)) & (~cellfun(@isempty, idY));
    idX = idX(flag);
    idY = idY(flag);
    
    % Train and Predict
    for j=1:length(idX)
        [a, b, M, Sigma, model] = Reduce2D_and_Train(X_train_dma_mod{i}(:,idX{j}),X_train_dma_mod{i}(:,idY{j}));
        name = "WSA" + string(cnt);                  % For plotting only
        DV_WSA_tr(:, cnt) = Reduce2D_and_Predict(X_train_dma_mod{i}(:,idX{j}),X_train_dma_mod{i}(:,idY{j}), a, b, M, Sigma, model, false);
        DV_WSA_tst1(:, cnt) = Reduce2D_and_Predict(X_test1_dma_mod{i}(:,idX{j}), X_test1_dma_mod{i}(:,idY{j}), a, b, M, Sigma, model, plotb, name);
        DV_WSA_tst2(:, cnt) = Reduce2D_and_Predict(X_test2_dma_mod{i}(:,idX{j}), X_test2_dma_mod{i}(:,idY{j}), a, b, M, Sigma, model, plotb, name);
        cnt = cnt + 1;
    end
end

%% Within-DMA Temporal Analysis (WTA)
plotb = false;                                                              % Plot boundary flag
cnt = 1;
for i=1:NumDMAs
    % Get daily regime curves of the sensors
    for j=1:size(X_train_dma{i},2)
        tmp=reshape(X_train_dma{i}(:,j),24,[]);                             % Reshape each sensor in the DMA from 8760 to 24 x 365
        tmp1{i}(:,j)=mean(tmp,2);                                           % Store the mean of each hour of the day of each sensor
    end
    RC{i} = repmat(tmp1{i},size(X_train_dma{i},1)/24,1);                    % Repeat copies of the daily mean values to 8760 x 1
    
    % Train and Predict
    [a, b, M, Sigma, model] = Reduce2D_and_Train(RC{i}, X_train_dma{i});
    name = "WTA" + string(cnt);                                             % For plotting only
    DV_WTA_tr(:, cnt) = Reduce2D_and_Predict(RC{i}, X_train_dma{i}, a, b, M, Sigma, model, false);
    DV_WTA_tst1(:, cnt) = Reduce2D_and_Predict(RC{i}(1:length(X_test1_dma{i}), :), X_test1_dma{i}, a, b, M, Sigma, model, plotb, name);
    DV_WTA_tst2(:, cnt) = Reduce2D_and_Predict(RC{i}(1:length(X_test2_dma{i}), :), X_test2_dma{i}, a, b, M, Sigma, model, plotb, name);
    cnt = cnt + 1;
end

%% Between-DMAs Spatial Analysis (BSA)
plotb = false;                        % Plot boundary flag
cnt=1;
for i=1:NumDMAs
    for j=i+1:NumDMAs
        % Train and Predict
        [a, b, M, Sigma, model] = Reduce2D_and_Train(X_train_dma_mod{i}, X_train_dma_mod{j});
        name =  "BSA" + string(cnt);  % For plotting only
        DV_BSA_tr(:,cnt) = Reduce2D_and_Predict(X_train_dma_mod{i}, X_train_dma_mod{j}, a, b, M, Sigma, model, false);
        DV_BSA_tst1(:,cnt) = Reduce2D_and_Predict(X_test1_dma_mod{i}, X_test1_dma_mod{j}, a, b, M, Sigma, model, plotb, name);
        DV_BSA_tst2(:,cnt) = Reduce2D_and_Predict(X_test2_dma_mod{i}, X_test2_dma_mod{j}, a, b, M, Sigma, model, plotb, name);
        cnt = cnt + 1;
    end
end

%% Synthesis from WSA-WTA-BSA
win = 12;                                                             % Smoothing window size
DV_tr = [DV_WSA_tr DV_WTA_tr DV_BSA_tr];
DV_tst1 = [DV_WSA_tst1 DV_WTA_tst1 DV_BSA_tst1];
DV_tst2 = [DV_WSA_tst2 DV_WTA_tst2 DV_BSA_tst2];

% Get precision of the DV in train
prec = mean(DV_tr(DV_tr > 0)) * size(DV_tr, 2);                       % Multiplied by Dim2 of DV because of the summation in the aggregation rule

% Get aggregated DV
DV_tst1_agg = sum(max(DV_tst1,0),2);
DV_tst2_agg = sum(max(DV_tst2,0),2);

% Get moving average of DV
DV_tst1_MA = movmean(DV_tst1_agg,[win 0],1,'Endpoints','shrink');     % Shrink - reduce the window size on edges
DV_tst2_MA = movmean(DV_tst2_agg,[win 0],1,'Endpoints','shrink');

% Get Alarms
Alarm_tst1 = (DV_tst1_MA > prec);
Alarm_tst2 = (DV_tst2_MA > prec);

%% Get Performance
[S_test1, ~, ~, F1_test1]=Perf_Score(Alarm_tst1*1,ev_test1,Y_test1);
[S_test2, ~, ~, F1_test2]=Perf_Score(Alarm_tst2*1,ev_test2,Y_test2);

fprintf('Test 1 S-Score is %.3f\nTest 1 F1-Score is %.3f\n###########################\n',round(S_test1,4),round(F1_test1,4));
fprintf('Test 2 S-Score is %.3f\nTest 2 F1-Score is %.3f\n###########################\n',round(S_test2,4),round(F1_test2,4));

% [S, S_TTD, S_cm, F1, prec, recall] = Perf_Score(Alarm_tst1*1,ev_test1,Y_test1);
% fprintf('Test 1\nS-Score: %.3f, S-CM: %.3f, S-TTD: %.3f\nF1-Score %.3f, Prec: %.3f, Recall: %.3f\n',S, S_cm, S_TTD, F1, prec, recall)
% [S, S_TTD, S_cm, F1, prec, recall] = Perf_Score(Alarm_tst2*1,ev_test2,Y_test2);
% fprintf('Test 2\nS-Score: %.3f, S-CM: %.3f, S-TTD: %.3f\nF1-Score %.3f, Prec: %.3f, Recall: %.3f\n',S, S_cm, S_TTD, F1, prec, recall)

% Output DV for Localization
DV_tst1 = struct("WSA", DV_WSA_tst1, "WTA", DV_WTA_tst1, "BSA", DV_BSA_tst1);
DV_tst2 = struct("WSA", DV_WSA_tst2, "WTA", DV_WTA_tst2, "BSA", DV_BSA_tst2);

%% Plot Detection
space=0.3;
figure
plot(Alarm_tst1, 'LineWidth', 1)
hold all
plot(Y_test1+1+space, 'LineWidth', 1);
xlabel('Time [H]','FontSize', 12)
yticks([0 1 1+space 2+space])
yticklabels({'Safe', 'Alarm', 'Normal', 'Under Attack'})
ytickangle(45)
set(gca,'YTickLabel',get(gca,'YTickLabel'),'fontsize',12)
axis([0 inf -0.1 2+space+0.1])

figure
plot(Alarm_tst2, 'LineWidth', 1)
hold all
plot(Y_test2+1+space, 'LineWidth', 1);
xlabel('Time [H]','FontSize', 12)
yticks([0 1 1+space 2+space])
yticklabels({'Safe', 'Alarm', 'Normal', 'Under Attack'})
ytickangle(45)
set(gca,'YTickLabel',get(gca,'YTickLabel'),'fontsize',12)
axis([0 inf -0.1 2+space+0.1])

end

