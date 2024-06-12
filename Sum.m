% written by Liangying, 3/7/2024

clear;
clc;

DATA_dir = '';
sub_dir = fullfile(DATA_dir, 'Subjects');
type = 'EMG';

combined_data = table();
combined_data_path = fullfile(DATA_dir, 'All', type);

cd(sub_dir);
subs = dir;
subs_name = extractfield(subs, 'name');
subs_name = subs_name(1,3:end)'; % delete . and .. names
subs_num = length(subs_name);

for isub = 1:subs_num

    sub_path = fullfile(sub_dir, subs_name{isub});

    visit = dir(sub_path);
    visit_name = extractfield(visit, 'name');
    visit_name = visit_name(1,3:end)'; % delete . and .. names
    visit_num = length(visit_name);

    for ivisit = 1:visit_num
        visit_path = fullfile(sub_path, visit_name{ivisit});
        sub_visit_EMG_path = dir(fullfile(visit_path, type, '*.csv'));
        tmp = extractfield(sub_visit_EMG_path, 'name');
        sub_visit_EMG_path = fullfile(visit_path, type,tmp{1});
        sub_visit_EMG = readtable(sub_visit_EMG_path);
        
        combined_data = vertcat(combined_data, sub_visit_EMG);
    end

end

combined_data_mat_path = fullfile(combined_data_path, 'all_subs_EMG.mat');
combined_data_csv_path = fullfile(combined_data_path, 'all_subs_EMG.csv');

save(combined_data_mat_path, 'combined_data');
writetable(combined_data, combined_data_csv_path);
