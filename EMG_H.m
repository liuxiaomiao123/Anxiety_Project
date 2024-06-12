% written by Liangying, 2/8/2024

clear;
clc;
close all;

%%
% BUPKP9  DHSKHS   U81NPC  XX90XO  KJKOJF Visit1_20240305 Visit1_20240306
% Visit1_20240314
% Visit2_20240312  Visit2_20240313 

%----------被试文件夹路径设置---------
id = 'XX90XO';
visit = 'Visit1_20240307';
type = 'EMG';

rawDATA_dir = 'P:\anxiety-analysis\Subjects';
rawdata_path = fullfile(rawDATA_dir, id, visit, 'Physio');
Redcap_path = fullfile(rawDATA_dir, id, visit, 'Redcap');

DATA_dir = '';
DATA_EMG_dir = fullfile(DATA_dir, id, visit, type);
mkdir(DATA_EMG_dir);   % matlab支持直接创建多级文件夹


%-----------EMG数据读入及参数设置--------------------
mat_files = dir(fullfile(rawdata_path, '*.mat'));
rawdata = extractfield(mat_files, 'name');
rawdata_mat_path = fullfile(rawdata_path, rawdata{1});
data_all = load(rawdata_mat_path);
data = data_all.data;
labels = data_all.labels;

[r,c] = size(data);

startle_trigger_channel = 10;
EMG_channel = c-2;
channel = EMG_channel;
EMG_data = data(:, EMG_channel);

pin = 5;
fs = 1000;

filter = 1;

%%
%-------------取startle event marker------------------
startle_time = find(data(:, startle_trigger_channel) == pin);
tmp = diff(startle_time);
startle_marker = startle_time(find(tmp > 100));
startle_marker = [startle_time(tmp(1)); startle_marker];
startle_marker = startle_marker + 10;


% x = linspace(0, 1, r);
% 
% figure;
% plot(x, data(:, EMG_channel));

%%
%------------对总共的时间序列选择是否filtering，一般不直接对Epoch data做filtering-------------

if filter

    % fourth-order 28 Hz Butterworth filter
    % High-pass filter parameters
    highpass_cutoff = 28;  % High-pass filter cutoff frequency
    highpass_order = 4;    % Filter order
    
    % Low-pass filter parameters
    lowpass_cutoff = 30;   % Low-pass filter cutoff frequency
    lowpass_order = 4;     % Filter order
    
    % Design high-pass filter
    [highpass_b, highpass_a] = butter(highpass_order, highpass_cutoff / (fs / 2), 'high');
   
    % Design low-pass filter
    [lowpass_b, lowpass_a] = butter(lowpass_order, lowpass_cutoff / (fs / 2), 'low');
    
    filtered_data_hp = [];
    rectified_data = [];
    smoothed_data_lp = [];
    
    % Apply high-pass filter forward and backward
    filtered_data_hp = filtfilt(highpass_b, highpass_a, EMG_data);

    % Rectify the signal (absolute value)
    rectified_data = abs(filtered_data_hp);

    % Apply low-pass filter forward and backward
    smoothed_data_lp = filtfilt(lowpass_b, lowpass_a, rectified_data);

end

%%
%------------------接下来进行Event Epoch-------------------
window = [-0.05, 0.3];
Data_epoch_EMG = [];

if filter
    data_f = smoothed_data_lp;
else
    data_f = EMG_data;
end


for et = 1:size(startle_marker, 1)
    Data_epoch_EMG(:, et) = data_f(startle_marker(et) + window(1)*fs : startle_marker(et) + window(2)*fs);  % 注意这里+1， 因为这里包含了0
    
    % 这个为了后面画图用
    Data_epoch_EMG_raw(:, et) = EMG_data(startle_marker(et) + window(1)*fs : startle_marker(et) + window(2)*fs); 
end



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
%-------画raw data，这样能看见前50ms的baseline，从而决定拒绝哪些trials--------

Hab_raw_fig_path = fullfile(DATA_EMG_dir, 'Habituation_EMG_raw.jpg');
Task_raw_fig_path = fullfile(DATA_EMG_dir, 'Task_EMG_raw.jpg');

% Data_epoch_EMG_raw本身就是从[-0.05, 0.3]这个窗口取的
figure_trial_raw(Data_epoch_EMG_raw(:,1:24), label, CondLabels_H, -0.05, 0.3, fs);
set(gcf, 'Position', [100, 100, 1536, 960]);   % screensize = get(0, 'ScreenSize'); 查看屏幕最大尺寸
saveas(gcf, Hab_raw_fig_path);

figure_trial_raw(Data_epoch_EMG_raw(:,25:end), label, CondLabels_Task, -0.05, 0.3, fs);
set(gcf, 'Position', [100, 100, 1536, 960]); 
saveas(gcf, Task_raw_fig_path);

%%
%--------取前50ms作为basline，删除baseline过于noise的trials, 然后进行baseline correction--------------

baseline = max(Data_epoch_EMG(1:50, :));  % 不是mean，是max
% baseline(baseline > 0.02)

% Trials were rejected if data in the 50 ms pre-probe baseline contained greater than 40 μV deflections (Bradford et al., 2014).
% 这个评判标准不太对，因为平滑后很多就看不出来?
et_bc_to_delete = find(baseline > 0.04)';

%  其实我没必要再去存储reject完后的df，因为我已经mark哪些trials为rejected了，直接在R中做筛选即可
% if ~isempty(et_bc_to_delete)
%     baseline_rj(:, et_bc_to_delete) = [];
%     Data_epoch_EMG_rj(:, et_bc_to_delete) = [];
%     Data_epoch_EMG_bc_rj = Data_epoch_EMG_rj(51:300, :) - baseline_rj;  % vectorization 避免for循环
% end

Data_epoch_EMG_bc = Data_epoch_EMG(51:300, :) - baseline;   % vectorization 避免for循环
EMG_bc_peak = max(Data_epoch_EMG_bc(20:end, :));  % 取[20, 250]之间的最大值
EMG_raw_peak = max(Data_epoch_EMG_raw(71:300, :)); % 注意rawdata前面有50ms是baseline



%%
%-----------转成R需要的dataframe形式----------------
df_id = repmat({id}, size((EMG_bc_peak)'));
df_visit = repmat({visit}, size((EMG_bc_peak)'));

df_Cond = strrep(strrep(strrep(strrep(strrep(strrep(CondLabels, 'P noCue', 'P'), 'P Cue', 'P'), 'N noCue', 'N'), 'N Cue', 'N'), 'U noCue', 'U'), 'U Cue', 'U');
df_Cue = strrep(strrep(strrep(strrep(strrep(strrep(CondLabels, 'P noCue', 'noCue'), 'P Cue', 'Cue'), 'N noCue', 'noCue'), 'N Cue', 'Cue'), 'U noCue', 'noCue'), 'U Cue', 'Cue');
df_EMG_peak = cell2table([num2cell(EMG_bc_peak)',num2cell(EMG_raw_peak)', df_Cond', df_Cue', df_id, df_visit], 'VariableNames', {'EMG_filt_bc_peak', 'EMG_raw_peak', 'Cond', 'Cue', 'id', 'visit'});

% mark baseline noise rejection trials, reject = 1, otherwise = 0
n = height(df_EMG_peak);
bs_reject = zeros(n, 1);
bs_reject(et_bc_to_delete) = 1;

df_EMG_peak = addvars(df_EMG_peak, bs_reject, 'NewVariableNames', 'bs_reject');

EMG_csv_path = fullfile(DATA_EMG_dir, 'EMG_peak_H.csv');
EMG_mat_path = fullfile(DATA_EMG_dir, 'EMG_peak_H.mat');

%EMG_path = [DATA_EMG_dir, '\EMG_bc_peak_H.csv']; % 如果用字符串拼接，你就得自己加上\，用fullfile就不需要
save(EMG_mat_path, 'df_EMG_peak');
writetable(df_EMG_peak, EMG_csv_path);

%%
%-------------画filter，且baseline correction的data---------------
%figure_trial(EMG_30_250_notch, label, CondLabels, -0.05, 0.3, fs);
%figure_trial_raw(Data_epoch_EMG_raw, label, CondLabels, -0.05, 0.3, fs);

Hab_filt_bc_fig_path = fullfile(DATA_EMG_dir, 'Habituation_EMG_filt_bc.jpg');
Task_filt_bc_fig_path = fullfile(DATA_EMG_dir, 'Task_EMG_filt_bc.jpg');

% 而Data_epoch_EMG_bc是从[0, 0.3]这个窗口取的，所以start = 0, End = 0.25
figure_trial_bc(Data_epoch_EMG_bc(:,1:24), label, CondLabels_H, 0, 0.25, fs);
set(gcf, 'Position', [100, 100, 1536, 960]); 
saveas(gcf, Hab_filt_bc_fig_path);

figure_trial_bc(Data_epoch_EMG_bc(:,25:end), label, CondLabels_Task, 0, 0.25, fs);
set(gcf, 'Position', [100, 100, 1536, 960]); 
saveas(gcf, Task_filt_bc_fig_path);

close all;

%%
function  figure_trial_bc(d, ChannelLabels, CondLabels, start, End , fs)

f = size(d, 2);

% 设置子图行和列的数量
num_rows = ceil(sqrt(f));
num_cols = ceil(f / num_rows);

figure;
%sgtitle(ChannelLabels(1:25));
sgtitle('EMG (28 - 30 Hz w/notch)');

x = linspace(start*fs, End*fs, End*fs -  start*fs);
for i = 1:f
    subplot(num_rows, num_cols, i);
    plot(x, d(:, i));
    title([CondLabels{i}, ' ', num2str(i)]);
    xlabel('time(ms)');
    ylabel('mV');
    xlim([start*fs, End*fs]);
    xticks([0,100,200]);
    ylim([-0.05, 0.05]);
    grid on;
end

end


function  figure_trial_raw(d, ChannelLabels, CondLabels, start, End , fs)

f = size(d, 2);

% 设置子图行和列的数量
num_rows = ceil(sqrt(f));
num_cols = ceil(f / num_rows);

figure;
sgtitle(ChannelLabels(1:25));

x = linspace(start*fs, End*fs, End*fs -  start*fs + 1);
for i = 1:f
    subplot(num_rows, num_cols, i);
    plot(x, d(:, i));
    title([CondLabels{i}, ' ', num2str(i)]);
    %xlabel('time(ms)');
    ylabel('mV');
    xlim([start*fs, End*fs]);
    xticks([-50,0,100,200]);
    ylim([-0.05, 0.05]);
    grid on;
end

end


function  orderRep2Cue = orderCueLabel(orderRep2)
% 奇数位置添加noCue, 偶数位置添加Cue
      for i = 1:2:numel(orderRep2)
          orderRep2Cue{i} = [orderRep2{i}, ' noCue'];
          orderRep2Cue{i+1} = [orderRep2{i+1}, ' Cue'];
      end
end




%---------------有了marker的时间戳，就可以画图了。这是总共的图---------------------
% x = linspace(0, 1, r);
% 
% figure;
% plot(x, data(:, channel));
% hold on;
% % 遍历垂直线位置数组，绘制每条垂直线
% for i = 1:length(startle_marker)
%     px = startle_marker(i);
%     line([x(px), x(px)], [-0.2,0.2], 'Color', 'red', 'LineWidth', 1); 
% end
% hold off;