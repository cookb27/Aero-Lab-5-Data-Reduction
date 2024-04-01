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

%% Read Tares
% Plan is to store run data as: 
%   - Speed
%   - Yaw Angle
%   - Data Filename
%   - Image Filename
%   - Invert Filename

NameArray = cell(4,5);

for i = 3:size(data_csvs,2)
    dataArrayIndexer = i-2;
    nameVar = data_csvs(i).name;

    if contains(nameVar,75)
        NameArray(i,1) = 75;
    elseif contains(nameVar,100)
        NameArray(i,1) = 100;
    end
end
clear dataArrayIndexer nameVar;