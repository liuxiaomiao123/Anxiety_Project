% written by Liangying, 3/28/2024

clear;
clc;

DATA_dir = '';
sub_dir = fullfile(DATA_dir, '');
type = 'Behav';

combined_data = table();
combined_data_path = fullfile(DATA_dir, 'All', type);
mkdir(combined_data_path);

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
        sub_visit_Behav_path = dir(fullfile(visit_path, type, '*.xlsx'));
        tmp = extractfield(sub_visit_Behav_path, 'name');
        sub_visit_Behav_path1 = fullfile(visit_path, type,tmp{1});
        sub_visit_Behav_path2 = fullfile(visit_path, type,tmp{2});

        sub_visit_Behav1 = readtable(sub_visit_Behav_path1);
        sub_visit_Behav2 = readtable(sub_visit_Behav_path2);

        sub_visit_Behav = vertcat(sub_visit_Behav1, sub_visit_Behav2);    % combine response1 and response2
        
        % 加上id和visit列
        id = repmat(subs_name{isub}, size(sub_visit_Behav, 1), 1);
        visit = repmat(visit_name{ivisit}, size(sub_visit_Behav, 1), 1);

        sub_visit_Behav = addvars(sub_visit_Behav, id, visit, 'NewVariableNames', {'id', 'visit'});

        combined_data = vertcat(combined_data, sub_visit_Behav);
    end

end

combined_data.Cue = replace(replace(replace(replace(replace(replace(combined_data.type, 'P_noCue', 'noCue'), 'P_Cue', 'Cue'), 'N_noCue', 'noCue'),'N_Cue', 'Cue'), 'U_noCue', 'noCue'), 'U_Cue', 'Cue');
combined_data.Cond = replace(replace(replace(replace(replace(replace(combined_data.type, 'P_noCue', 'P'), 'P_Cue', 'P'), 'N_noCue', 'N'),'N_Cue', 'N'), 'U_noCue', 'U'), 'U_Cue', 'U');
%combined_data.key2 =
%replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(combined_data.key,
%49, 0), 50, 1), 51, 2), 52, 3), 53, 4), 54, 5), 56, 6), 57, 7), 48, 8),
%97, 9), 98, 10);  replace must need text

combined_data.key2(combined_data.key == 49) = 0;
combined_data.key2(combined_data.key == 50) = 1;
combined_data.key2(combined_data.key == 51) = 2;
combined_data.key2(combined_data.key == 52) = 3;
combined_data.key2(combined_data.key == 53) = 4;
combined_data.key2(combined_data.key == 54) = 5;
combined_data.key2(combined_data.key == 56) = 6;
combined_data.key2(combined_data.key == 57) = 7;
combined_data.key2(combined_data.key == 48) = 8;
combined_data.key2(combined_data.key == 97) = 9;
combined_data.key2(combined_data.key == 98) = 10;

combined_data_mat_path = fullfile(combined_data_path, 'all_subs_behav.mat');
combined_data_csv_path = fullfile(combined_data_path, 'all_subs_behav.csv');

save(combined_data_mat_path, 'combined_data');
writetable(combined_data, combined_data_csv_path);