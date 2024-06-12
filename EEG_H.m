% written by Liangying, 3/3/2024

clear;
clc;
close all;

%%
% BUPKP9  DHSKHS   U81NPC  XX90XO  KZFYMX Visit1_20240305 Visit1_20240306 Visit2_20240312

%----------被试文件夹路径设置---------
id = 'BUPKP9';
visit = 'Visit1_20240305';
type = 'EEG';

rawDATA_dir = 'P:\anxiety-analysis\Subjects';
rawdata_path = fullfile(rawDATA_dir, id, visit, 'Physio');
Redcap_path = fullfile(rawDATA_dir, id, visit, 'Redcap');

DATA_dir = '';
DATA_EEG_dir = fullfile(DATA_dir, id, visit, type);
mkdir(DATA_EEG_dir);   % matlab支持直接创建多级文件夹

%%
%-----------EEG数据读入及参数设置--------------------
mat_files = dir(fullfile(rawdata_path, '*.mat'));
rawdata = extractfield(mat_files, 'name');
rawdata_mat_path = fullfile(rawdata_path, rawdata{1});
data_all = load(rawdata_mat_path);
data = data_all.data;
labels = data_all.labels;

%%

[r,c] = size(data);

startle_trigger_channel = 10;
EEG_channel = 6;
channel = EEG_channel;
EEG_data = data(:, EEG_channel);

pin = 5;
fs = 1000;

lowpass  = 30;  % Hz
highpass = 0.1;  % Hz
filter = 1;

%%
%-------------取startle event marker------------------
startle_time = find(data(:, startle_trigger_channel) == pin);
tmp = diff(startle_time);
startle_marker = startle_time(find(tmp > 100));
startle_marker = [startle_time(tmp(1)); startle_marker];
startle_marker = startle_marker + 10;

%%
%------------对总共的时间序列选择是否filtering，一般不直接对Epoch data做filtering-------------

if filter
    [b,a] = butter(3,[highpass/(fs/2) lowpass/(fs/2)],'bandpass');
    EEG_data_filt  = filtfilt(b,a,double(EEG_data));
end


%%
%------------------接下来进行 event epoch------------------
window = [-0.2, 1];
Data_epoch_EEG = [];
data_f = EEG_data_filt;

for et = 1:size(startle_marker, 1)

    if filter
        Data_epoch_EEG(:, et) = data_f(startle_marker(et) + window(1)*fs : startle_marker(et) + window(2)*fs);
    else
        Data_epoch_EEG(:, et) = data(startle_marker(et) + window(1)*fs : startle_marker(et) + window(2)*fs , channel);
    end
    
end

%--------------EEG baseline correction-----------------

baseline = mean(Data_epoch_EEG(1:abs(window(1)*fs), :));
% baseline(baseline > 0.02)
% find(baseline > 0.02)
Data_epoch_EEG_bc = Data_epoch_EEG(abs(window(1)*fs)+1:end, :) - baseline;  % vectorization 避免for循环, 注意这里就没有前面baseline 200ms的数据了
Data_epoch_EEG_bc = [Data_epoch_EEG(1:abs(window(1)*fs), :); Data_epoch_EEG_bc];  % 将前面200ms的数据拼接起来；


Data_epoch_EEG_bc = Data_epoch_EEG_bc * 1000;  % 将EEG量纲从mV转为μV， 注意在做完平均后再乘，因为可能会有影响
%%
% --------------------给所有的Trails加上Condition的标签，组成dataframe格式--------------------------------

% 根据redcap确定randomized order
redcap = dir(fullfile(Redcap_path, '*.csv'));
redcap_name = extractfield(redcap, 'name');
redcap_csv_path = fullfile(Redcap_path, redcap_name{1});
readcap_csv = readtable(redcap_csv_path);
order_first = str2double(readcap_csv{:, 9}{1}(1)); 

% condition labels
order1 = {'P','N','U','N','U','N','P'}; %order 1
order2 = {'U','N','P','N','P','N','U'}; %order 2

rep = 3;
orderRep1 = repelem(order1, rep);
orderRep2 = repelem(order2, rep);

habiN = 12;
habiRep12 = repmat({'H'}, 1, habiN);

habiN = 6;
habiRep6 = repmat({'H'}, 1, habiN);

if order_first == 1
    orderRep2_first = repelem(orderRep1, 2);
    orderRep2_second = repelem(orderRep2, 2);
else
    orderRep2_first = repelem(orderRep2, 2);
    orderRep2_second = repelem(orderRep1, 2);
end

orderRep2Cue_first = orderCueLabel(orderRep2_first);
orderRep2Cue_second = orderCueLabel(orderRep2_second);

CondLabels = [habiRep12, habiRep12, orderRep2Cue_first, habiRep6, orderRep2Cue_second];

CondLabels_H = [habiRep12, habiRep12];
CondLabels_Task = [orderRep2Cue_first, habiRep6, orderRep2Cue_second];

% channel label
label = labels(channel, :);

%% 
%  画二维子图

Hab_filt_bc_fig_path = fullfile(DATA_EEG_dir, 'Habituation_EEG_filt_bc_sub.jpg');
Task_filt_bc_fig_path = fullfile(DATA_EEG_dir, 'Task_EEG_filt_bc_sub.jpg');

start = -0.2;
End = 0.6;

start_idx = 1;
end_idx = (abs(start) + End)*fs;

Data_epoch_EEG_bc_Hab = Data_epoch_EEG_bc(start_idx:end_idx, 1:24);
Data_epoch_EEG_bc_Task = Data_epoch_EEG_bc(start_idx:end_idx, 25:end);

figure_trial(Data_epoch_EEG_bc_Hab, label, CondLabels_H, start, End, fs);
set(gcf, 'Position', [100, 100, 1536, 960]); 
saveas(gcf, Hab_filt_bc_fig_path);

figure_trial(Data_epoch_EEG_bc_Task, label, CondLabels_Task, start, End, fs);
set(gcf, 'Position', [100, 100, 1536, 960]); 
saveas(gcf, Task_filt_bc_fig_path);



%%
% 整合数据，注意EEG是时间序列，df的格式为(t1,t2...tn, Cond, Cue, id, visit)，不要将时间点弄成一列，那样太复杂了
n_trials = size(Data_epoch_EEG_bc, 2);
n_t = size(Data_epoch_EEG_bc, 1);

df_id = repmat({id}, n_trials, 1);
df_visit = repmat({visit}, n_trials, 1);

df_Cond = strrep(strrep(strrep(strrep(strrep(strrep(CondLabels, 'P noCue', 'P'), 'P Cue', 'P'), 'N noCue', 'N'), 'N Cue', 'N'), 'U noCue', 'U'), 'U Cue', 'U');
df_Cue = strrep(strrep(strrep(strrep(strrep(strrep(CondLabels, 'P noCue', 'noCue'), 'P Cue', 'Cue'), 'N noCue', 'noCue'), 'N Cue', 'Cue'), 'U noCue', 'noCue'), 'U Cue', 'Cue');

EEG_t_names = string(compose('t%d', 1:n_t));
df_EEG_bc_d = array2table(Data_epoch_EEG_bc');
df_EEG_bc_d = renamevars(df_EEG_bc_d, 1:n_t, EEG_t_names);

df_notes = cell2table([df_Cond', df_Cue', df_id, df_visit], 'VariableNames', {'Cond', 'Cue', 'id', 'visit'});

df_EEG_bc = horzcat(df_EEG_bc_d, df_notes);
%df_EEG_bc = cell2table([num2cell(Data_epoch_EEG_bc)', df_Cond', df_Cue', df_id, df_visit], 'VariableNames', {EEG_t_names, 'Cond', 'Cue', 'id', 'visit'});

% 修改pre post到Cue列
df_EEG_bc.Cue(1:12) = repmat({'pre'}, 12, 1);
df_EEG_bc.Cue(13:24) = repmat({'post'}, 12, 1);


EEG_csv_path = fullfile(DATA_EEG_dir, 'EEG_bc_H.csv');
EEG_mat_path = fullfile(DATA_EEG_dir, 'EEG_bc_H.mat');

%EMG_path = [DATA_EMG_dir, '\EMG_bc_peak_H.csv']; % 如果用字符串拼接，你就得自己加上\，用fullfile就不需要
save(EEG_mat_path, 'df_EEG_bc');
writetable(df_EEG_bc, EEG_csv_path);

%%
% 画热图和平均图, 一涉及到平均就需要Condition的labels了

N_data = df_EEG_bc(strcmp(df_EEG_bc.Cond, 'N'), 1:n_t);
P_data = df_EEG_bc(strcmp(df_EEG_bc.Cond, 'P'), 1:n_t);
U_data = df_EEG_bc(strcmp(df_EEG_bc.Cond, 'U'), 1:n_t);

H_pre_data = df_EEG_bc(strcmp(df_EEG_bc.Cue, 'pre'), 1:n_t);
H_post_data = df_EEG_bc(strcmp(df_EEG_bc.Cue, 'post'), 1:n_t);

% 绘制热图
figure_heatmap_task(N_data, P_data, U_data);

Task_EEG_heatmap_fig_path = fullfile(DATA_EEG_dir, 'Task_EEG_heatmap.jpg');
% get(gcf, 'Position');
% set(gcf, 'Position', [488, 338, 560, 420]); 
saveas(gcf, Task_EEG_heatmap_fig_path);

figure_heatmap_hab(H_pre_data, H_post_data);

Hab_EEG_heatmap_fig_path = fullfile(DATA_EEG_dir, 'Hab_EEG_heatmap.jpg');
% get(gcf, 'Position');
% set(gcf, 'Position', [488, 338, 560, 420]); 
saveas(gcf, Hab_EEG_heatmap_fig_path);

%%
% 绘制平均图

N_mean_data = mean(table2array(N_data), 1);
P_mean_data = mean(table2array(P_data), 1);
U_mean_data = mean(table2array(U_data), 1);

xtimes = linspace(window(1)*fs, window(2)*fs,  window(2)*fs - window(1)*fs + 1);

figure;

hold on;
plot(xtimes, N_mean_data, 'b', 'LineWidth', 2);
plot(xtimes, P_mean_data, 'r', 'LineWidth', 2);
plot(xtimes, U_mean_data, 'g', 'LineWidth', 2);
xlabel('times(ms)');
ylabel('μV');
title('');
legend('N', 'P', 'U');
set(gca,'YDir','reverse');
grid on;
hold off;

Task_EEG_ERP_fig_path = fullfile(DATA_EEG_dir, 'Task_EEG_ERP.jpg');
% get(gcf, 'Position');
%set(gcf, 'Position', [488, 338, 560, 420]); 
saveas(gcf, Task_EEG_ERP_fig_path);

H_pre_mean_data = mean(table2array(H_pre_data), 1);
H_post_mean_data = mean(table2array(H_post_data), 1);

figure;

hold on;
plot(xtimes, H_pre_mean_data, 'b', 'LineWidth', 2);
plot(xtimes, H_post_mean_data, 'r', 'LineWidth', 2);
xlabel('times(ms)');
ylabel('μV');
title('');
legend('Hab Pre', 'Hab Post');
set(gca,'YDir','reverse');
grid on;
hold off;

Hab_EEG_ERP_fig_path = fullfile(DATA_EEG_dir, 'Hab_EEG_ERP.jpg');
%set(gcf, 'Position', [488, 338, 560, 420]); 
saveas(gcf, Hab_EEG_ERP_fig_path);

close all;

%%
function  figure_trial(d, ChannelLabels, CondLabels, start, End , fs)

f = size(d, 2);

% 设置子图行和列的数量
num_rows = ceil(sqrt(f));
num_cols = ceil(f / num_rows);

figure;
sgtitle(ChannelLabels(1:25));

x = linspace(start*fs, End*fs, End*fs -  start*fs);
for i = 1:f
    subplot(num_rows, num_cols, i);
    plot(x, d(:, i));
    title([CondLabels{i}, ' ', num2str(i)]);
    %xlabel('time(s)');
    ylabel('μV');
    xlim([start*fs, End*fs]);
    ax1 = gca;
    set(ax1,'XTick',[],'FontSize',7);
    xticks([-100,0,200,400]);

    ylim([-20, 20]);

    set(gca,'YDir','reverse');
    grid on;
end

end


function figure_heatmap_task(d_N, d_P, d_U)

figure;
subplot(3, 1, 1);
imagesc(table2array(d_N));
title('N');
xlabel('time(ms)');
xticks([1, 201, 401, 601, 801, 1001, 1201]);
x_labels = {'-200', '0', '200', '400', '600', '800', '10000'};
xticklabels(x_labels);
ylabel('');
yticks('');

subplot(3, 1, 2);
imagesc(table2array(d_P));
title('P');
xlabel('time(ms)');
xticks([1, 201, 401, 601, 801, 1001, 1201]);
x_labels = {'-200', '0', '200', '400', '600', '800', '10000'};
xticklabels(x_labels);
ylabel('');
yticks('');

subplot(3, 1, 3);
imagesc(table2array(d_U));
title('U');
xlabel('time(ms)');
xticks([1, 201, 401, 601, 801, 1001, 1201]);
x_labels = {'-200', '0', '200', '400', '600', '800', '10000'};
xticklabels(x_labels);
ylabel('');
yticks('');

colorbar('Position', [0.935, 0.35, 0.02, 0.2]);  % 显示颜色条
end


function figure_heatmap_hab(d_pre, d_post)

figure;
subplot(2, 1, 1);
imagesc(table2array(d_pre));
title('Hab Pre');
xlabel('time(ms)');
xticks([1, 201, 401, 601, 801, 1001, 1201]);
x_labels = {'-200', '0', '200', '400', '600', '800', '10000'};
xticklabels(x_labels);
ylabel('');
yticks('');

subplot(2, 1, 2);
imagesc(table2array(d_post));
title('Hab Post');
xlabel('time(ms)');
xticks([1, 201, 401, 601, 801, 1001, 1201]);
x_labels = {'-200', '0', '200', '400', '600', '800', '10000'};
xticklabels(x_labels);
ylabel('');
yticks('');

colorbar('Position', [0.935, 0.35, 0.02, 0.2]);  % 显示颜色条
end



function  orderRep2Cue = orderCueLabel(orderRep2)
% 奇数位置添加noCue, 偶数位置添加Cue
      for i = 1:2:numel(orderRep2)
          orderRep2Cue{i} = [orderRep2{i}, ' noCue'];
          orderRep2Cue{i+1} = [orderRep2{i+1}, ' Cue'];
      end
end
