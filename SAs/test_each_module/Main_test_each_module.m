function [T] = Main_test_each_module(case_study)
% ####################################################################################################################
% Code for the paper:
% Detecting and Localizing Cyber-Physical Attack in Water Distribution Systems without Records of Labeled Attacks
% By Mashor Housh, Noy Kadosh, Jack Hadad

% University of Haifa, mhoush@univ.haifa.ac.il
% ####################################################################################################################
% This code requires:
% svmpredict.mexw64
% svmtrain.mexw64
% Developed under Matlab 2018b
% ####################################################################################################################
startFolder = pwd;
cd('../../Code/')

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
            X_train_dma1{i}(:,j)=diff(X_train_dma{i}(:,j));
            X_test1_dma1{i}(:,j)=diff(X_test1_dma{i}(:,j));
            X_test2_dma1{i}(:,j)=diff(X_test2_dma{i}(:,j));
        else
            X_train_dma1{i}(:,j)=X_train_dma{i}(1:end-1,j);
            X_test1_dma1{i}(:,j)=X_test1_dma{i}(1:end-1,j);
            X_test2_dma1{i}(:,j)=X_test2_dma{i}(1:end-1,j);
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
        [a, b, M, Sigma, model] = Reduce2D_and_Train(X_train_dma1{i}(:,idX{j}),X_train_dma1{i}(:,idY{j}));
        name = "WSA" + string(cnt);                  % For plotting only
        DV_WSA_tr(:, cnt) = Reduce2D_and_Predict(X_train_dma1{i}(:,idX{j}),X_train_dma1{i}(:,idY{j}), a, b, M, Sigma, model, false);
        DV_WSA_tst1(:, cnt) = Reduce2D_and_Predict(X_test1_dma1{i}(:,idX{j}), X_test1_dma1{i}(:,idY{j}), a, b, M, Sigma, model, plotb, name);
        DV_WSA_tst2(:, cnt) = Reduce2D_and_Predict(X_test2_dma1{i}(:,idX{j}), X_test2_dma1{i}(:,idY{j}), a, b, M, Sigma, model, plotb, name);
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
        [a, b, M, Sigma, model] = Reduce2D_and_Train(X_train_dma1{i}, X_train_dma1{j});
        name =  "BSA" + string(cnt);  % For plotting only
        DV_BSA_tr(:,cnt) = Reduce2D_and_Predict(X_train_dma1{i}, X_train_dma1{j}, a, b, M, Sigma, model, false);
        DV_BSA_tst1(:,cnt) = Reduce2D_and_Predict(X_test1_dma1{i}, X_test1_dma1{j}, a, b, M, Sigma, model, plotb, name);
        DV_BSA_tst2(:,cnt) = Reduce2D_and_Predict(X_test2_dma1{i}, X_test2_dma1{j}, a, b, M, Sigma, model, plotb, name);
        cnt = cnt + 1;
    end
end
%% Test Individual modules

win = 12;                                                                     % Smoothing window size
col_names = ["WSA", "WTA", "BSA", "All"];

% Create table to store scores
T = table('RowNames',["S_test1", "S_TTD_test1", "S_cm_test1", "F1_test1", "Prec_test1", "Sens_test1", ...
    "S_test2", "S_TTD_test2", "S_cm_test2", "F1_test2", "Prec_test2", "Sens_test2"]);

for i=1:length(col_names)
    switch col_names(i)
        case "WSA"
            DV_tr = DV_WSA_tr;
            DV_tst1 = DV_WSA_tst1;
            DV_tst2 = DV_WSA_tst2;
        case "WTA"
            DV_tr = DV_WTA_tr;
            DV_tst1 = DV_WTA_tst1;
            DV_tst2 = DV_WTA_tst2;
        case "BSA"
            DV_tr = DV_BSA_tr;
            DV_tst1 = DV_BSA_tst1;
            DV_tst2 = DV_BSA_tst2;
        case "All"
            DV_tr = [DV_WSA_tr DV_WTA_tr DV_BSA_tr];
            DV_tst1 = [DV_WSA_tst1 DV_WTA_tst1 DV_BSA_tst1];
            DV_tst2 = [DV_WSA_tst2 DV_WTA_tst2 DV_BSA_tst2];
    end
    
    % Get precision of the DV in train
    prec = mean(DV_tr(DV_tr>0))*size(DV_tr,2);                              % Multiplied by Dim2 of DV because of the summation in the aggregation rule
    
    DV_tst1_agg = sum(max(DV_tst1,0), 2);
    DV_tst2_agg = sum(max(DV_tst2,0), 2);
    
    DV_tst1_MA = movmean(DV_tst1_agg,[win 0],1,'Endpoints','shrink');       % Shrink - reduce the window size on edges
    DV_tst2_MA = movmean(DV_tst2_agg,[win 0],1,'Endpoints','shrink');
    
    Alarm_tst1 = (DV_tst1_MA > prec);
    Alarm_tst2 = (DV_tst2_MA > prec);
    
    [S_test1, S_TTD_test1, S_cm_test1, F1_test1, Prec_test1, Sens_test1] = Perf_Score(Alarm_tst1*1,ev_test1,Y_test1);
    [S_test2, S_TTD_test2, S_cm_test2, F1_test2, Prec_test2, Sens_test2] = Perf_Score(Alarm_tst2*1,ev_test2,Y_test2);
    
    T.(col_names(i)) = [S_test1, S_TTD_test1, S_cm_test1, F1_test1, Prec_test1, Sens_test1, ...
        S_test2, S_TTD_test2, S_cm_test2, F1_test2, Prec_test2, Sens_test2]';
    
end

cd(startFolder)
warning('on')

writetable(T, upper(case_study) + "town_each_module_SA.csv", 'WriteRowNames',true)

end

