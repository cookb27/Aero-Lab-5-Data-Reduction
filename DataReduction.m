% Lab 5 Data Reduction

% Read all Tare Files
% Read all Data Files
% Extract forces and moments
% Quantify Uncertainties
% Note: Value = Raw - (Image - Invert)

clear; close all; clc

%% Find Files
directory = pwd;
tare_dir  = [directory,'\AE315_S24\Lab5_AeroTareData_Original'];
data_dir  = [directory,'\AE315_S24\Sec04'];
tare_csvs = dir([tare_dir,'/*.csv']);
data_csvs = dir([data_dir,'/*.csv']);

clear directory;

%% Read Tares
% Plan is to store run data as: 
%   - Speed
%   - Yaw Angle
%   - Data Filename
%   - Image Filename
%   - Invert Filename

NameArray = cell(4,5);

for j = 1:size(tare_csvs,1)
    if contains(tare_csvs(j).name,'Image')
        RunType = "Image";
    else
        RunType = "Invert";
    end

    if contains(tare_csvs(j).name,'Yaw0') || contains(tare_csvs(j).name,'yaw0')
        YawType = 1;
    elseif contains(tare_csvs(j).name,'Yaw-10')
        YawType = 2;
    else
        YawType = 0;
    end

    if contains(tare_csvs(j).name,'_75fps')
        RunSpeed = 75;
    elseif contains(tare_csvs(j).name,'_100fps')
        RunSpeed = 100;
    else
        RunSpeed = 0;
    end

    tare_csvs_nums(j,1) = RunType;
    tare_csvs_nums(j,2) = YawType;
    tare_csvs_nums(j,3) = RunSpeed;
end

clear RunType YawType RunSpeed j

tare_csvs(tare_csvs_nums(:,2)=='0') = [];
tare_csvs_nums(tare_csvs_nums(:,2)=='0',:) = [];

tare_csvs(tare_csvs_nums(:,3)=='0') = [];
tare_csvs_nums(tare_csvs_nums(:,3)=='0',:) = [];

tare_csvs_nums(tare_csvs_nums(:,2)=='1',2) = "0";
tare_csvs_nums(tare_csvs_nums(:,2)=='2',2) = "10";

for i = 3:size(data_csvs,1)
    dataArrayIndexer = i-2;
    nameVar = data_csvs(i).name;

    Numbers  = extract(nameVar,digitsPattern);
    YawAngle = Numbers(5);

    if any(strcmp(Numbers,'75')) % Find 75 fps runs
        flowspeed = "75";
    elseif any(strcmp(Numbers,'100')) % find 100 fps runs
        flowspeed = "100";
    end

    ImageBool = all([tare_csvs_nums(:,1) == "Image", ...
        tare_csvs_nums(:,2) == YawAngle, ...
        tare_csvs_nums(:,3) == flowspeed]');

    InvertBool = all([tare_csvs_nums(:,1) == "Invert", ...
        tare_csvs_nums(:,2) == YawAngle, ...
        tare_csvs_nums(:,3) == flowspeed]');

    NameArray{dataArrayIndexer,1} = flowspeed; % Flow Speed
    NameArray{dataArrayIndexer,2} = str2double(YawAngle); % Yaw Angle
    NameArray{dataArrayIndexer,3} = nameVar; % Data filename
    NameArray{dataArrayIndexer,4} = tare_csvs(ImageBool).name; % Image Filename
    NameArray{dataArrayIndexer,5} = tare_csvs(InvertBool).name; % Invert Filename
end
clear i dataArrayIndexer nameVar flowspeed YawAngle;
clear ImageBool InvertBool data_csvs Numbers tare_csvs_nums tare_csvs

%% Open Data Tables
