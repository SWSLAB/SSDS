function [X_train_dma, X_test1_dma, X_test2_dma, NumDMAs, Fvars, Pvars, Tvars, ev_test1, ev_test2, Y_test1, Y_test2] = Load_Data(case_study)
%% ####################################################################################################################
% Code for the paper:
% Detecting and Localizing Cyber-Physical Attack in Water Distribution Systems without Records of Labeled Attacks
% By Mashor Housh, Noy Kadosh, Jack Hadad

% University of Haifa, mhoush@univ.haifa.ac.il
%% ####################################################################################################################
% Developed under Matlab 2018b
%% ####################################################################################################################

if case_study == 'c'
    
    % Load Data
    X = load('../Data/C_Town/raw_ds3_4_5.mat');
    X_train = X.X3_raw;             %train - No Events train data
    X_test1 = X.X4_raw;             %test1 - With Events
    X_test2 = X.X5_raw;             %test2 - With Events
    clear X
    
    % Prepare Data
    % Every id is the relevant column in the database based on the DMAs 1-5.
    % if a pump in a DMA did not work in the training dataset then it was excluded from the group
    % flow is the location of pump flow in the id vector, levels is location of tanks in the id vector
    NumDMAs = 5;
    id = cell(NumDMAs, 1);
    
    id{1} = [1,2,8,10,32,33,30,42,43];                                      % t1 t2 f_p1 f_p2 p_j280 p_j269 f_v2 p_j14 p_j422
    id{2} = [4,18,20,36,37];                                                % t4 f_p6 f_p7 P_J289	P_J415
    id{3} = [3,14,34,35];                                                   % t3 f_p4 P_J300	P_J256
    id{4} = [5,22,38,39];                                                   % t5 f_p8 P_J302	P_J306
    id{5} = [6,7,26,28,40,41];                                              % t6 t7 f_p10 f_p11 P_J307 P_J317
    
    % Partitioning data into DMAs
    X_train_dma = cell(NumDMAs, 1);
    X_test1_dma = cell(NumDMAs, 1);
    X_test2_dma = cell(NumDMAs, 1);
    
    for i=1:NumDMAs
        X_train_dma{i} = X_train(:, id{i});
        X_test1_dma{i} = X_test1(:, id{i});
        X_test2_dma{i} = X_test2(:, id{i});
    end
    
    % Sensors Type: the values are position in the id vector
    Fvars = cell(NumDMAs, 1);
    Pvars = cell(NumDMAs, 1);
    Tvars = cell(NumDMAs, 1);
    
    Fvars{1} = [3 4 7]; Pvars{1} = [5 6 8 9];  Tvars{1} = [1 2];
    Fvars{2} = [2 3];   Pvars{2} = [4 5];      Tvars{2} = [1];
    Fvars{3} = [2];     Pvars{3} = [3 4];      Tvars{3} = [1];
    Fvars{4} = [2];     Pvars{4} = [3 4];      Tvars{4} = [1];
    Fvars{5} = [3 4];   Pvars{5} = [ 5 6];     Tvars{5}=[1 2];
    
    % Define Events Vectors
    ev_test1 = cell(7, 1);
    ev_test2 = cell(7, 1);
    Y_test1 = zeros(size(X_test1, 1), 1);
    Y_test2 = zeros(size(X_test2, 1), 1);
    
    ev_test1{1} = 1728 : 1777;                                              % True values of flags in dataset 4
    ev_test1{2} = 2028 : 2051;
    ev_test1{3} = 2338 : 2397;
    ev_test1{4} = 2828 : 2921;
    ev_test1{5} = 3498 : 3557;
    ev_test1{6} = 3728 : 3821;
    ev_test1{7} = 3928 : 4037;
    
    Y_test1([ev_test1{1} ev_test1{2} ev_test1{3} ev_test1{4} ev_test1{5} ev_test1{6} ev_test1{7}]) = 1;  % Events flags for test1
    Y_test1 = Y_test1(1:end-1);                                                                          % -1 to have full days in the dataset
    
    ev_test2{1} = 298 : 367;                                                % True values of flags in dataset 5
    ev_test2{2} = 633 : 697;
    ev_test2{3} = 868 : 898;
    ev_test2{4} = 938 : 968;
    ev_test2{5} = 1230 : 1329;
    ev_test2{6} = 1575 : 1654;
    ev_test2{7} = 1941 : 1970;
    
    Y_test2([ev_test2{1} ev_test2{2} ev_test2{3} ev_test2{4} ev_test2{5} ev_test2{6} ev_test2{7}])=1;    % Events flags for test2
    Y_test2 = Y_test2(1:end-1);                                                                          % -1 to have full days in the dataset
    
elseif case_study == 'e'
    
    % Load Data
    X = load('../Data/E_Town/SCADA_readings.mat'); % Load raw datasets
    DMAs = load('../Data/E_Town/DMAs.mat');
    DMAs=DMAs.DMAs;                                % Load features grouping map based on DMAs ==>
    
    % Prepare Data
    NumDMAs=length(DMAs);
    for i=1:NumDMAs
        if ~isempty(DMAs{i, 1})
            X_train_dma{i}=table2array(X.SCADA_train(:,DMAs{i,1}));
            X_test1_dma{i}=table2array(X.SCADA_test1(:,DMAs{i,1}));
            X_test2_dma{i}=table2array(X.SCADA_test2(:,DMAs{i,1}));
        end
    end
    
    % Define Sensors Type
    Tvars=cell(23,1);Pvars=cell(23,1);Fvars=cell(23,1);
    for i=1:NumDMAs
        names=DMAs{i,1};
        for j=1:length(names)
            name=names(j);
            name=char(name);
            if name(1)=='F'
                Fvars{i}(end+1)=j;
            end
            switch name(1:3)
                case "P_J"
                    Pvars{i}(end+1)=j;
                case "P_T"
                    Tvars{i}(end+1)=j;
            end
        end
    end
    
    % Define Events Vectors
    ev_test1 = cell(10,1);
    ev_test2 = cell(10,1);
    Y_test1 = zeros(height(X.SCADA_test1),1);
    Y_test2=zeros(height(X.SCADA_test2),1);
    
    ev_test1{1} = 600 : 630;
    ev_test1{2} = 1000 : 1040;
    ev_test1{3} = 1400 : 1500;
    ev_test1{4} = 2000 : 2100;
    ev_test1{5} = 2600 : 2700;
    ev_test1{6} = 2600 : 2700;
    ev_test1{7} = 3300 : 3400;
    ev_test1{8} = 3350 : 3450;
    ev_test1{9} = 3400 : 3500;
    ev_test1{10}= 4000 : 4050;
    
    Y_test1([ev_test1{1} ev_test1{2} ev_test1{3} ev_test1{4} ev_test1{5} ev_test1{6} ev_test1{7} ev_test1{8} ev_test1{9} ev_test1{10}]) = 1; % Events flags for test1
    Y_test1=Y_test1(1:end-1);                                                                                                                % -1 to have full days in the dataset
    
    ev_test2{1} = 387 : 487;
    ev_test2{2} = 937 : 987;
    ev_test2{3} = 1387 : 1407;
    ev_test2{4} = 1887 : 2037;
    ev_test2{5} = 2687 : 2737;
    ev_test2{6} = 2712 : 2762;
    ev_test2{7} = 2907 : 3057;
    ev_test2{8} = 3187 : 3257;
    ev_test2{9} = 3887 : 3967;
    ev_test2{10} = 3887 : 3977;
    
    Y_test2([ev_test2{1} ev_test2{2} ev_test2{3} ev_test2{4} ev_test2{5} ev_test2{6} ev_test2{7} ev_test2{8} ev_test2{9} ev_test2{10}])=1;   % Events flags for test2
    Y_test2=Y_test2(1:end-1);                                                                                                                % -1 to have full days in the dataset
    
end


