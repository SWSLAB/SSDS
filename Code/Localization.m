%% ####################################################################################################################
% Code for the paper:
% Detecting and Localizing Cyber-Physical Attack in Water Distribution Systems without Records of Labeled Attacks
% By Mashor Housh, Noy Kadosh, Jack Hadad

% University of Haifa, mhoush@univ.haifa.ac.il
%% ####################################################################################################################
% Developed under Matlab 2018b
%% ####################################################################################################################
clc
clear all
close all

% Get Events
[~,~,~, NumDMAs,~,~,~, ev_test1, ev_test2] = Load_Data('c');

% Get Alarms and DVs
[~,~, DV_tst1, DV_tst2]=Main('c');

% Define true targeted DMAs based on Batadal description
True_DMAs_tst1 = [5 5 1 1 2 2 2];
True_DMAs_tst2 = [3 1 1 1 1 5 2];

% Split DVs to DMAs
for i=1:NumDMAs
    DV_WSA_tst1{i}=DV_tst1.WSA(:,(1:6)+6*(i-1));
    DV_WSA_tst2{i}=DV_tst2.WSA(:,(1:6)+6*(i-1));
    DV_WTA_tst1{i}=DV_tst1.WTA(:,i);
    DV_WTA_tst2{i}=DV_tst2.WTA(:,i);
end
cnt=1;
for i=1:NumDMAs
    for j=i+1:NumDMAs
        DV_BSA_tst1{i,j}=DV_tst1.BSA(:,cnt);
        DV_BSA_tst2{i,j}=DV_tst2.BSA(:,cnt);
        DV_BSA_tst1{j,i}=DV_BSA_tst1{i,j};
        DV_BSA_tst2{j,i}=DV_BSA_tst2{i,j};
        cnt = cnt + 1;
    end
end
for i=1:NumDMAs
    DV_BSA_tst11{i}=cell2mat(DV_BSA_tst1(i,:));
    DV_BSA_tst22{i}=cell2mat(DV_BSA_tst2(i,:));
end

% Find the identified DMA from each module
for i=1:NumDMAs
    for j=1:length(ev_test1)
        Sum_Pos_DV_WSA_tst1(i,j)=sum(sum(max(DV_WSA_tst1{i}(ev_test1{j},:),0)));
        Sum_Pos_DV_WTA_tst1(i,j)=sum(sum(max(DV_WTA_tst1{i}(ev_test1{j},:),0)));
        Sum_Pos_DV_BSA_tst1(i,j)=sum(sum(max(DV_BSA_tst11{i}(ev_test1{j},:),0)));
    end
    for j=1:length(ev_test2)
        Sum_Pos_DV_WSA_tst2(i,j)=sum(sum(max(DV_WSA_tst2{i}(ev_test2{j},:),0)));
        Sum_Pos_DV_WTA_tst2(i,j)=sum(sum(max(DV_WTA_tst2{i}(ev_test2{j},:),0)));
        Sum_Pos_DV_BSA_tst2(i,j)=sum(sum(max(DV_BSA_tst22{i}(ev_test2{j},:),0)));
    end
end
[~,Targted_DMA_WSA_tst1]=max(Sum_Pos_DV_WSA_tst1);
[~,Targted_DMA_WSA_tst2]=max(Sum_Pos_DV_WSA_tst2);
[~,Targted_DMA_WTA_tst1]=max(Sum_Pos_DV_WTA_tst1);
[~,Targted_DMA_WTA_tst2]=max(Sum_Pos_DV_WTA_tst2);
[~,Targted_DMA_BSA_tst1]=max(Sum_Pos_DV_BSA_tst1);
[~,Targted_DMA_BSA_tst2]=max(Sum_Pos_DV_BSA_tst2);

% Arrange in table
T_tst1=table;
T_tst1.Identified_DMA_WSA=Targted_DMA_WSA_tst1';
T_tst1.Identified_DMA_WTA=Targted_DMA_WTA_tst1';
T_tst1.Identified_DMA_BSA=Targted_DMA_BSA_tst1';

T_tst2=table;
T_tst2.Identified_DMA_WSA=Targted_DMA_WSA_tst2';
T_tst2.Identified_DMA_WTA=Targted_DMA_WTA_tst2';
T_tst2.Identified_DMA_BSA=Targted_DMA_BSA_tst2';


T=[T_tst1;T_tst2];
T.Majority_Vote=mode(T{:,:},2);
T.True_DMA=[True_DMAs_tst1';True_DMAs_tst2'];
T.Properties.RowNames="Event " +(1:length(ev_test1)+length(ev_test2));

disp(T)
writetable(T,'LocalizationCtown.csv','WriteRowNames',true)



