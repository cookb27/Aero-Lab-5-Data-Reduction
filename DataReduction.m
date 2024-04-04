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

    % Hard Coding Wing Area and Span Length
    S_w   = 242.01; % in2
    c_bar = 9.88; % in

    % F_Aero = F_Data - (F_Image - F_Invert)
    % Build Table For Found Forces
    AeroValues        = table;
    AeroValues.Pitch  = NameArray{i,6}.Pitch;
    AeroValues.Q      = NameArray{i,6}.("Dynamic Pressure");
    AeroValues.DragF  = NameArray{i,6}.("WAFMC Drag")  - (NameArray{i,7}.("WAFMC Drag")  - NameArray{i,8}.("WAFMC Drag"));
    AeroValues.SideF  = NameArray{i,6}.("WAFMC Side")  - (NameArray{i,7}.("WAFMC Side")  - NameArray{i,8}.("WAFMC Side"));
    AeroValues.LiftF  = NameArray{i,6}.("WAFMC Lift")  - (NameArray{i,7}.("WAFMC Lift")  - NameArray{i,8}.("WAFMC Lift"));
    AeroValues.RollM  = NameArray{i,6}.("WAFMC Roll")  - (NameArray{i,7}.("WAFMC Roll")  - NameArray{i,8}.("WAFMC Roll"));
    AeroValues.PitchM = NameArray{i,6}.("WAFMC Pitch") - (NameArray{i,7}.("WAFMC Pitch") - NameArray{i,8}.("WAFMC Pitch"));
    AeroValues.YawM   = NameArray{i,6}.("WAFMC Yaw")   - (NameArray{i,7}.("WAFMC Yaw")   - NameArray{i,8}.("WAFMC Yaw"));
    AeroValues.CDA    = AeroValues.DragF./AeroValues.Q;  % C_D * A
    AeroValues.CNA    = AeroValues.SideF./AeroValues.Q;  % C_N * A (Sideslip)
    AeroValues.CLA    = AeroValues.LiftF./AeroValues.Q;  % C_L * A
    AeroValues.CMRA   = AeroValues.RollM./AeroValues.Q;  % C_M_Roll * A
    AeroValues.CMPA   = AeroValues.PitchM./AeroValues.Q; % C_M_Pitch * A
    AeroValues.CMYA   = AeroValues.YawM./AeroValues.Q;   % C_M_Yaw * A
    AeroValues.CD     = AeroValues.CDA./S_w; % C_D
    AeroValues.CN     = AeroValues.CNA./S_w; % C_D
    AeroValues.CL     = AeroValues.CLA./S_w; % C_D
    AeroValues.CMR    = AeroValues.CMRA./S_w; % C_D
    AeroValues.CMP    = AeroValues.CMPA./S_w; % C_D
    AeroValues.CMY    = AeroValues.CMYA./S_w; % C_D

    % NOTE: Need to add uncertainties to all values (1% of readings per)

    NameArray{i,9}    = AeroValues;

    % If you need to see the header names, use this in the command window:
    % NameArray{1,9}.Properties.VariableNames
end
clear i data_dir tare_dir AeroValues
clear S_w c_bar

%% Plotting
% Plot 1 - Forces, Moments Vs Alpha  75 fps (Both 0, 10 deg Yaw)
% Plot 2 - Forces, Moments Vs Alpha 100 fps (Both 0, 10 deg Yaw)
% Plot 3 - Cl,Cd vs Alpha, All Run Cases
% Plot 4 - Drag Polar, All Run Cases
% Plot 5 - Cl/Cd vs Alpha, All Run Cases
% Plot 6 - CM_Pitch vs Alpha, All Run Cases
% Plot 7 - CN, CM_Roll, CM_Yaw vs Alpha, All Run Cases

% Plots 1 and 2 will be unique code
% Plots 3-7 will be using a for loop
% Note: Consider storing as graphics objects array
F1 = figure; Ax1 = axes(Parent=F1);
F2 = figure; Ax2 = axes(Parent=F2);
F3 = figure; Ax3 = axes(Parent=F3);
F4 = figure; Ax4 = axes(Parent=F4);
F5 = figure; Ax5 = axes(Parent=F5);
F6 = figure; Ax6 = axes(Parent=F6);
F7 = figure; Ax7 = axes(Parent=F7);

%% Plot 1
axes(Ax1);
hold on;
grid on;
title("Forces and Moments for 75 fps Runs");
xlabel("Alpha (deg)");
ylabel("Force (lbs)")
for i = 1:2
    runName   = sprintf("%.0f Beta",NameArray{i,2});
    
    % Create aeroTable as temporary variable to access Table Values
    aeroTable = NameArray{i,9};

    yyaxis left
    plot(aeroTable.Pitch,aeroTable.DragF,DisplayName=sprintf("%s Drag",runName));
    plot(aeroTable.Pitch,aeroTable.SideF,DisplayName=sprintf("%s Side Force",runName));
    plot(aeroTable.Pitch,aeroTable.LiftF,DisplayName=sprintf("%s Lift",runName));

    yyaxis right
    plot(aeroTable.Pitch,aeroTable.PitchM,DisplayName=sprintf("%s Pitch Moment",runName));
    plot(aeroTable.Pitch,aeroTable.YawM,DisplayName=sprintf("%s Yaw Moment",runName));
    plot(aeroTable.Pitch,aeroTable.RollM,DisplayName=sprintf("%s Roll Moment",runName));
end
legend(NumColumns=2,Location='northwest');
ylabel("Moment (ft*lbs)");

%% Plot 2
axes(Ax2);
hold on;
grid on;
title("Forces and Moments for 100 fps Runs");
xlabel("Alpha (deg)");
ylabel("Force (lbs)");

for i = 3:4
    runName   = sprintf("%.0f Beta",NameArray{i,2});
    
    % Create aeroTable as temporary variable to access Table Values
    aeroTable = NameArray{i,9};

    yyaxis left
    plot(aeroTable.Pitch,aeroTable.DragF,DisplayName=sprintf("%s Drag",runName));
    plot(aeroTable.Pitch,aeroTable.SideF,DisplayName=sprintf("%s Side Force",runName));
    plot(aeroTable.Pitch,aeroTable.LiftF,DisplayName=sprintf("%s Lift",runName));

    yyaxis right
    plot(aeroTable.Pitch,aeroTable.PitchM,DisplayName=sprintf("%s Pitch Moment",runName));
    plot(aeroTable.Pitch,aeroTable.YawM,DisplayName=sprintf("%s Yaw Moment",runName));
    plot(aeroTable.Pitch,aeroTable.RollM,DisplayName=sprintf("%s Roll Moment",runName));
end

legend(NumColumns=2,Location='northwest');
ylabel("Moment (ft*lbs)");

%% Plot 3
axes(Ax3);
hold on;
grid on;
xlabel("Alpha (deg)");
ylabel("CL");
title("Lift and Drag Coefficients Over Angles of Attack");

for i = 1:4
    runName   = sprintf("%s fps, %.0f Beta",NameArray{i,1},NameArray{i,2});
    
    % Create aeroTable as temporary variable to access Table Values
    aeroTable = NameArray{i,9};

    yyaxis left
    plot(aeroTable.Pitch,aeroTable.CL,DisplayName=sprintf("%s CL",runName));

    yyaxis right
    plot(aeroTable.Pitch,aeroTable.CD,DisplayName=sprintf("%s CD",runName));
end

legend(Location='northwest');
ylabel("CD");

%% Plot 4
axes(Ax4);
hold on;
grid on;
xlabel("CD");
ylabel("CL");
title("Drag Polars");

for i = 1:4
    runName   = sprintf("%s fps, %.0f Beta",NameArray{i,1},NameArray{i,2});
    
    % Create aeroTable as temporary variable to access Table Values
    aeroTable = NameArray{i,9};

    plot(aeroTable.CD,aeroTable.CL,DisplayName=sprintf("%s",runName));
end

legend(Location='northwest');

%% Plot 5
axes(Ax5);
hold on;
grid on;
xlabel("Alpha (deg)");
ylabel("CL/CD");
title("Lift to Drag Ratios Over Angles of Attack");

for i = 1:4
    runName   = sprintf("%s fps, %.0f Beta",NameArray{i,1},NameArray{i,2});
    
    % Create aeroTable as temporary variable to access Table Values
    aeroTable = NameArray{i,9};

    plot(aeroTable.Pitch,aeroTable.CL./aeroTable.CD,DisplayName=sprintf("%s",runName));
end

legend(Location='northwest');

%% Plot 6
axes(Ax6);
hold on;
grid on;
xlabel("Alpha (deg)");
ylabel("C_M Pitch");
title("Pitching Coefficient Over Angles of Attack");

for i = 1:4
    runName   = sprintf("%s fps, %.0f Beta",NameArray{i,1},NameArray{i,2});
    
    % Create aeroTable as temporary variable to access Table Values
    aeroTable = NameArray{i,9};

    plot(aeroTable.Pitch,aeroTable.CMP,DisplayName=sprintf("%s",runName));
end

legend(Location='northwest');

%% Plot 7
axes(Ax7);
hold on;
grid on;
xlabel("Alpha (deg)");
ylabel("Force (lbs)");
title("Side Force, C_M Yaw, C_M Roll Over Angles of Attack");

for i = 1:4
    runName   = sprintf("%s fps, %.0f Beta",NameArray{i,1},NameArray{i,2});
    
    % Create aeroTable as temporary variable to access Table Values
    aeroTable = NameArray{i,9};

    yyaxis left
    plot(aeroTable.Pitch,aeroTable.SideF,DisplayName=sprintf("%s Side Force",runName));

    yyaxis right
    plot(aeroTable.Pitch,aeroTable.CMY,DisplayName=sprintf("%s C_M Yaw",runName));
    plot(aeroTable.Pitch,aeroTable.CMR,DisplayName=sprintf("%s C_M Roll",runName));
end

legend(Location='northwest');
ylabel("Coefficient");