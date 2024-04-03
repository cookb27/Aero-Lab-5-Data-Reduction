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
%   - Data File Table
%   - Image File Table
%   - Invert File Table

NameArray = cell(4,9);

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
for i = 1:size(NameArray,1)
    NameArray{i,6} = readtable([data_dir,'\',NameArray{i,3}],...
        VariableNamingRule="Preserve");
    NameArray{i,7} = readtable([tare_dir,'\',NameArray{i,4}],...
        VariableNamingRule="Preserve");
    NameArray{i,8} = readtable([tare_dir,'\',NameArray{i,5}],...
        VariableNamingRule="Preserve");

    % This finds the closest matching (negative) pitch values for the tare
    % files and removes all other values. 
    NameArray{i,7}(~ismember(round(NameArray{i,7}.Pitch),-round(NameArray{i,6}.Pitch)),:) = [];
    NameArray{i,8}(~ismember(round(NameArray{i,8}.Pitch),-round(NameArray{i,6}.Pitch)),:) = [];

    % F_Aero = F_Data - (F_Image - F_Invert)
    % Build Table For Found Forces
    AeroValues        = table;
    AeroValues.Pitch  = NameArray{i,6}.Pitch;
    AeroValues.Q      = NameArray{i,6}.("Dynamic Pressure");
    AeroValues.DragF  = NameArray{i,6}.("WAFBC Drag")  - (NameArray{i,7}.("WAFBC Drag")  - NameArray{i,8}.("WAFBC Drag"));
    AeroValues.SideF  = NameArray{i,6}.("WAFBC Side")  - (NameArray{i,7}.("WAFBC Side")  - NameArray{i,8}.("WAFBC Side"));
    AeroValues.LiftF  = NameArray{i,6}.("WAFBC Lift")  - (NameArray{i,7}.("WAFBC Lift")  - NameArray{i,8}.("WAFBC Lift"));
    AeroValues.RollM  = NameArray{i,6}.("WAFBC Roll")  - (NameArray{i,7}.("WAFBC Roll")  - NameArray{i,8}.("WAFBC Roll"));
    AeroValues.PitchM = NameArray{i,6}.("WAFBC Pitch") - (NameArray{i,7}.("WAFBC Pitch") - NameArray{i,8}.("WAFBC Pitch"));
    AeroValues.YawM   = NameArray{i,6}.("WAFBC Yaw")   - (NameArray{i,7}.("WAFBC Yaw")   - NameArray{i,8}.("WAFBC Yaw"));
    AeroValues.CDA    = AeroValues.DragF./AeroValues.Q;  % C_D * A
    AeroValues.CNA    = AeroValues.SideF./AeroValues.Q;  % C_N * A (Sideslip)
    AeroValues.CLA    = AeroValues.LiftF./AeroValues.Q;  % C_L * A
    AeroValues.CMRA   = AeroValues.RollM./AeroValues.Q;  % C_M_Roll * A
    AeroValues.CMPA   = AeroValues.PitchM./AeroValues.Q; % C_M_Pitch * A
    AeroValues.CMYA   = AeroValues.YawM./AeroValues.Q;   % C_M_Yaw * A

    NameArray{i,9}    = AeroValues;
end
clear i data_dir tare_dir AeroValues

%% Plotting