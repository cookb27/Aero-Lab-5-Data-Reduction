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
    C_bar = 9.88; % in

    % F_Aero = F_Data - (F_Image - F_Invert)
    % Build Table For Found Forces
    AeroValues        = table;

    AeroValues.Pitch  = NameArray{i,6}.Pitch;
    AeroValues.Q      = NameArray{i,6}.("Dynamic Pressure");
    AeroValues.Re     = NameArray{i,6}.("Reynolds Number per ft");

    % AeroValues.PUnc   = 0.01.*AeroValues.Pitch; % Constant Percentage of
    % Angle Uncertainty
    AeroValues.PUnc   = 0.00.*ones(size(AeroValues.Pitch)); % Constant Small Angle Uncertainty
    AeroValues.QUnc   = 0.01.*AeroValues.Q;

    AeroValues.DragF  = NameArray{i,6}.("WAFMC Drag")  - (NameArray{i,7}.("WAFMC Drag")  - NameArray{i,8}.("WAFMC Drag"));
    AeroValues.SideF  = NameArray{i,6}.("WAFMC Side")  - (NameArray{i,7}.("WAFMC Side")  - NameArray{i,8}.("WAFMC Side"));
    AeroValues.LiftF  = NameArray{i,6}.("WAFMC Lift")  - (NameArray{i,7}.("WAFMC Lift")  - NameArray{i,8}.("WAFMC Lift"));
    AeroValues.RollM  = NameArray{i,6}.("WAFMC Roll")  - (NameArray{i,7}.("WAFMC Roll")  - NameArray{i,8}.("WAFMC Roll"));
    AeroValues.PitchM = NameArray{i,6}.("WAFMC Pitch") - (NameArray{i,7}.("WAFMC Pitch") - NameArray{i,8}.("WAFMC Pitch"));
    AeroValues.YawM   = NameArray{i,6}.("WAFMC Yaw")   - (NameArray{i,7}.("WAFMC Yaw")   - NameArray{i,8}.("WAFMC Yaw"));

    % 1% Uncertainties in All Recorded Forces and Moments
    AeroValues.DUnc   = 0.01.*sqrt(NameArray{i,6}.("WAFMC Drag").^2  + NameArray{i,7}.("WAFMC Drag").^2  + NameArray{i,8}.("WAFMC Drag").^2);
    AeroValues.SUnc   = 0.01.*sqrt(NameArray{i,6}.("WAFMC Side").^2  + NameArray{i,7}.("WAFMC Side").^2  + NameArray{i,8}.("WAFMC Side").^2);
    AeroValues.LUnc   = 0.01.*sqrt(NameArray{i,6}.("WAFMC Lift").^2  + NameArray{i,7}.("WAFMC Lift").^2  + NameArray{i,8}.("WAFMC Lift").^2);
    AeroValues.RMUnc  = 0.01.*sqrt(NameArray{i,6}.("WAFMC Roll").^2  + NameArray{i,7}.("WAFMC Roll").^2  + NameArray{i,8}.("WAFMC Roll").^2);
    AeroValues.PMUnc  = 0.01.*sqrt(NameArray{i,6}.("WAFMC Pitch").^2 + NameArray{i,7}.("WAFMC Pitch").^2 + NameArray{i,8}.("WAFMC Pitch").^2);
    AeroValues.YMUnc  = 0.01.*sqrt(NameArray{i,6}.("WAFMC Yaw").^2   + NameArray{i,7}.("WAFMC Yaw").^2   + NameArray{i,8}.("WAFMC Yaw").^2);

    % Coefficients * Areas
    AeroValues.CDA    = AeroValues.DragF./AeroValues.Q;  % C_D * A
    AeroValues.CNA    = AeroValues.SideF./AeroValues.Q;  % C_N * A (Sideslip)
    AeroValues.CLA    = AeroValues.LiftF./AeroValues.Q;  % C_L * A
    AeroValues.CMRA   = AeroValues.RollM./AeroValues.Q;  % C_M_Roll * A
    AeroValues.CMPA   = AeroValues.PitchM./AeroValues.Q; % C_M_Pitch * A
    AeroValues.CMYA   = AeroValues.YawM./AeroValues.Q;   % C_M_Yaw * A

    % Uncertainty in Coefficients * Areas
    AeroValues.CDAUnc  = sqrt((AeroValues.DUnc./AeroValues.Q).^2  + (AeroValues.DragF.*AeroValues.QUnc./(AeroValues.Q.^2)).^2);
    AeroValues.CNAUnc  = sqrt((AeroValues.SUnc./AeroValues.Q).^2  + (AeroValues.SideF.*AeroValues.QUnc./(AeroValues.Q.^2)).^2);
    AeroValues.CLAUnc  = sqrt((AeroValues.LUnc./AeroValues.Q).^2  + (AeroValues.LiftF.*AeroValues.QUnc./(AeroValues.Q.^2)).^2);
    AeroValues.CMRAUnc = sqrt((AeroValues.RMUnc./AeroValues.Q).^2 + (AeroValues.RollM.*AeroValues.QUnc./(AeroValues.Q.^2)).^2);
    AeroValues.CMPAUnc = sqrt((AeroValues.PMUnc./AeroValues.Q).^2 + (AeroValues.PitchM.*AeroValues.QUnc./(AeroValues.Q.^2)).^2);
    AeroValues.CMYAUnc = sqrt((AeroValues.YMUnc./AeroValues.Q).^2 + (AeroValues.YawM.*AeroValues.QUnc./(AeroValues.Q.^2)).^2);

    % Coefficients Alone
    AeroValues.CD     = AeroValues.CDA./S_w; % C_Drag
    AeroValues.CN     = AeroValues.CNA./S_w; % C_Normal (SideForce)
    AeroValues.CL     = AeroValues.CLA./S_w; % C_Lift
    AeroValues.CMR    = AeroValues.CMRA./(S_w*C_bar); % C_M_Roll
    AeroValues.CMP    = AeroValues.CMPA./(S_w*C_bar); % C_M_Pitch
    AeroValues.CMY    = AeroValues.CMYA./(S_w*C_bar); % C_M_Yaw

    % Uncertainty in Coefficients
    AeroValues.CDUnc  = AeroValues.CDAUnc./S_w;
    AeroValues.CNUnc  = AeroValues.CNAUnc./S_w;
    AeroValues.CLUnc  = AeroValues.CLAUnc./S_w;
    AeroValues.CMRUnc = AeroValues.CMRAUnc./(S_w*C_bar);
    AeroValues.CMPUnc = AeroValues.CMPAUnc./(S_w*C_bar);
    AeroValues.CMYUnc = AeroValues.CMYAUnc./(S_w*C_bar);

    % CL/CD Unc
    AeroValues.CLCDUnc = sqrt((AeroValues.CLUnc./AeroValues.CD).^2 + (AeroValues.CL.*AeroValues.CDUnc./(AeroValues.CD.^2)).^2);

    NameArray{i,9}    = AeroValues;

    % If you need to see the header names, use this in the command window:
    % NameArray{1,9}.Properties.VariableNames
end
clear i data_dir tare_dir AeroValues
clear S_w C_bar

%% Plotting
% Plot 1 - Forces, Moments Vs Alpha  75 fps (Both 0, 10 deg Yaw)
% Plot 2 - Forces, Moments Vs Alpha 100 fps (Both 0, 10 deg Yaw)
% Plot 3 - Cl,Cd vs Alpha, All Run Cases
% Plot 4 - Drag Polar, All Run Cases
% Plot 5 - Cl/Cd vs Alpha, All Run Cases
% Plot 6 - CM_Pitch vs Alpha, All Run Cases
% Plot 7 - CN, CM_Roll, CM_Yaw vs Alpha, All Run Cases

% Need to extablish simple color & symbol assignment per dataset
% Run Symbols
% -  0 Beta,  75fps - Circle   - MarkerVec(1,:)
% - 10 Beta,  75fps - Plus     - MarkerVec(2,:)
% -  0 Beta, 100fps - Triangle - MarkerVec(3,:)
% - 10 Beta, 100fps - "X"      - MarkerVec(4,:)
% Data Color
% - Lift         - ColorVec(1,:)
% - Drag         - ColorVec(2,:)
% - Sideforce    - ColorVec(3,:)
% - Pitch Moment - ColorVec(4,:)
% - Yaw Moment   - ColorVec(5,:)
% - Roll Moment  - ColorVec(6,:)
% - C_L          - ColorVec(7,:)
% - C_D          - ColorVec(8,:)
% - C_N          - ColorVec(9,:)
% - C_M_P        - ColorVec(10,:)
% - C_M_Y        - ColorVec(11,:)
% - C_M_R        - ColorVec(12,:)

% Plots 1 and 2 will be unique code
% Plots 3-7 will be using a for loop
% Note: Consider storing as graphics objects array
F1 = figure;  T1 = tiledlayout(1,2,Parent=F1); Ax1_1 = nexttile; Ax1_2 = nexttile;
F2 = figure;  T2 = tiledlayout(1,2,Parent=F2); Ax2_1 = nexttile; Ax2_2 = nexttile;
F3 = figure; Ax3 = axes(Parent=F3);
F4 = figure; Ax4 = axes(Parent=F4);
F5 = figure; Ax5 = axes(Parent=F5);
F6 = figure; Ax6 = axes(Parent=F6);
F7 = figure;  T7 = tiledlayout(1,2,Parent=F7); Ax7_1 = nexttile; Ax7_2 = nexttile;

Ax1_1.NextPlot = "add";
Ax1_2.NextPlot = "add";
Ax2_1.NextPlot = "add";
Ax2_2.NextPlot = "add";
Ax3.NextPlot = "add";
Ax4.NextPlot = "add";
Ax5.NextPlot = "add";
Ax6.NextPlot = "add";
Ax7_1.NextPlot = "add";
Ax7_2.NextPlot = "add";


% Creating Vector of Strings for plotting Symbols
MarkerVec    = ["o";"+";"^";"x"];
LineStyleVec = ["-";"--";":";"-."];

% Creating vector of colors for plotting
ColorVec = (  1.*[0.0000,0.4470,0.7410; ...
                  0.8500,0.3250,0.0980; ...
                  0.9290,0.6940,0.1250; ...
                  0.4940,0.1840,0.5560; ...
                  0.4660,0.6740,0.1880; ...
                  0.6350,0.0780,0.9330; ...
                  1.0000,0.0000,0.0000; ...
                  0.5000,0.0000,0.5000; ...
                  0.0000,0.0000,1.0000; ...
                  0.0000,0.0000,0.0000; ...
                  0.4648,0.5313,0.5977; ...
                  0.0000,0.0000,1.0000]);

%% For Loop Containing All Plots
for i = 1:4
    if i < 3
        %% Plot 1
        axes(Ax1_1); %#ok<*LAXES>

        if i == 1
            % Plot 1a
            grid on;
            title("Forces for 75 fps Runs");
            xlabel("Alpha (deg)");
            ylabel("Force (lbs)");
        end

        runName   = sprintf("%.0f Beta",NameArray{i,2});
        
        % Create aeroTable as temporary variable to access Table Values
        aeroTable = NameArray{i,9};
        tempMarker = MarkerVec(i,:);
        tempStyle  = LineStyleVec(i,:);
    
        errorbar(aeroTable.Pitch,aeroTable.DragF,...
            aeroTable.DUnc,aeroTable.DUnc,...
            aeroTable.PUnc,aeroTable.PUnc,...
            DisplayName=sprintf("%s Drag",runName),...
            Color=ColorVec(2,:),Marker=tempMarker,LineStyle=tempStyle, ...
            LineWidth=1.5,MarkerSize=8);
        errorbar(aeroTable.Pitch,aeroTable.SideF,...
            aeroTable.SUnc,aeroTable.SUnc,...
            aeroTable.PUnc,aeroTable.PUnc,...
            DisplayName=sprintf("%s Side Force",runName),...
            Color=ColorVec(3,:),Marker=tempMarker,LineStyle=tempStyle,...
            LineWidth=1.5,MarkerSize=8);
        errorbar(aeroTable.Pitch,aeroTable.LiftF,...
            aeroTable.LUnc,aeroTable.LUnc,...
            aeroTable.PUnc,aeroTable.PUnc,...
            DisplayName=sprintf("%s Lift",runName),...
            Color=ColorVec(1,:),Marker=tempMarker,LineStyle=tempStyle, ...
            LineWidth=1.5,MarkerSize=8);

        axes(Ax1_2)

        if i == 1
            % Plot 1b
            grid on;
            title("Moments for 75 fps Runs");
            xlabel("Alpha (deg)");
            ylabel("Moment (ft*lbs)");
        end

        runName   = sprintf("%.0f Beta",NameArray{i,2});

        % Create aeroTable as temporary variable to access Table Values
        aeroTable = NameArray{i,9};
        tempMarker = MarkerVec(i,:);
        tempStyle  = LineStyleVec(i,:);

        errorbar(aeroTable.Pitch,aeroTable.PitchM,...
            aeroTable.PMUnc,aeroTable.PMUnc,...
            aeroTable.PUnc,aeroTable.PUnc,...
            DisplayName=sprintf("%s Pitch Moment",runName),...
            Color=ColorVec(4,:),Marker=tempMarker,LineStyle=tempStyle, ...
            LineWidth=1.5,MarkerSize=8);
        errorbar(aeroTable.Pitch,aeroTable.YawM,...
            aeroTable.YMUnc,aeroTable.YMUnc,...
            aeroTable.PUnc,aeroTable.PUnc,...
            DisplayName=sprintf("%s Yaw Moment",runName),...
            Color=ColorVec(5,:),Marker=tempMarker,LineStyle=tempStyle, ...
            LineWidth=1.5,MarkerSize=8);
        errorbar(aeroTable.Pitch,aeroTable.RollM,...
            aeroTable.RMUnc,aeroTable.RMUnc,...
            aeroTable.PUnc,aeroTable.PUnc,...
            DisplayName=sprintf("%s Roll Moment",runName),...
            Color=ColorVec(6,:),Marker=tempMarker,LineStyle=tempStyle, ...
            LineWidth=1.5,MarkerSize=8);
    elseif i > 2
        %% Plot 2
        axes(Ax2_1);

        if i == 3
            % Plot 2a
            grid on;
            title("Forces for 100 fps Runs");
            xlabel("Alpha (deg)");
            ylabel("Force (lbs)");
        end

        runName   = sprintf("%.0f Beta",NameArray{i,2});

        % Create aeroTable as temporary variable to access Table Values
        aeroTable = NameArray{i,9};
        tempMarker = MarkerVec(i,:);
        tempStyle  = LineStyleVec(i,:);

        errorbar(aeroTable.Pitch,aeroTable.DragF,aeroTable.DUnc,...
            DisplayName=sprintf("%s Drag",runName),...
            Color=ColorVec(2,:),Marker=tempMarker,LineStyle=tempStyle, ...
            LineWidth=1.5,MarkerSize=8);
        errorbar(aeroTable.Pitch,aeroTable.SideF,aeroTable.SUnc,...
            DisplayName=sprintf("%s Side Force",runName),...
            Color=ColorVec(3,:),Marker=tempMarker,LineStyle=tempStyle, ...
            LineWidth=1.5,MarkerSize=8);
        errorbar(aeroTable.Pitch,aeroTable.LiftF,aeroTable.LUnc,...
            DisplayName=sprintf("%s Lift",runName),...
            Color=ColorVec(1,:),Marker=tempMarker,LineStyle=tempStyle, ...
            LineWidth=1.5,MarkerSize=8);

        axes(Ax2_2);

        if i == 3
            % Plot 2b
            grid on;
            title("Moments for 100 fps Runs");
            xlabel("Alpha (deg)");
            ylabel("Moment (ft*lbs)");
        end

        runName   = sprintf("%.0f Beta",NameArray{i,2});

        % Create aeroTable as temporary variable to access Table Values
        aeroTable = NameArray{i,9};
        tempMarker = MarkerVec(i,:);
        tempStyle  = LineStyleVec(i,:);

        errorbar(aeroTable.Pitch,aeroTable.PitchM,aeroTable.PMUnc,...
            DisplayName=sprintf("%s Pitch Moment",runName),...
            Color=ColorVec(4,:),Marker=tempMarker,LineStyle=tempStyle, ...
            LineWidth=1.5,MarkerSize=8);
        errorbar(aeroTable.Pitch,aeroTable.YawM,aeroTable.YMUnc,...
            DisplayName=sprintf("%s Yaw Moment",runName),...
            Color=ColorVec(5,:),Marker=tempMarker,LineStyle=tempStyle, ...
            LineWidth=1.5,MarkerSize=8);
        errorbar(aeroTable.Pitch,aeroTable.RollM,aeroTable.RMUnc,...
            DisplayName=sprintf("%s Roll Moment",runName),...
            Color=ColorVec(6,:),Marker=tempMarker,LineStyle=tempStyle, ...
            LineWidth=1.5,MarkerSize=8);
    end

    %% Plot 3
    axes(Ax3);

    if i == 1
        % Plot 3
        grid on;
        xlabel("Alpha (deg)");
        yyaxis left
        ylabel("C_L");
        title("Lift and Drag Coefficients Over Angles of Attack");
        yyaxis right
        ylabel("C_D");
        Ax3.YAxis(1).Color = 'black';
        Ax3.YAxis(2).Color = 'black';
        legend;
    end

    runName   = sprintf("%s fps, %.0f Beta",NameArray{i,1},NameArray{i,2});

    % Create aeroTable as temporary variable to access Table Values
    aeroTable = NameArray{i,9};
    tempMarker = MarkerVec(i,:);
    tempStyle  = LineStyleVec(i,:);

    yyaxis left
    % plot(aeroTable.Pitch,aeroTable.CL,DisplayName=sprintf("%s CL",runName),...
    %     Color=ColorVec(7,:),Marker=tempMarker,LineStyle=tempStyle, ...
    %     LineWidth=1.5,MarkerSize=8);
    errorbar(aeroTable.Pitch,aeroTable.CL,...
        aeroTable.CLUnc,aeroTable.CLUnc,...
        aeroTable.PUnc,aeroTable.PUnc,...
        DisplayName=sprintf("%s CL",runName),...
        Color=ColorVec(7,:),Marker=tempMarker,LineStyle=tempStyle, ...
        LineWidth=1.5,MarkerSize=8);

    yyaxis right
    errorbar(aeroTable.Pitch,aeroTable.CD,...
        aeroTable.CDUnc,aeroTable.CDUnc,...
        aeroTable.PUnc,aeroTable.PUnc,...
        DisplayName=sprintf("%s CD",runName),...
        Color=ColorVec(8,:),Marker=tempMarker,LineStyle=tempStyle, ...
        LineWidth=1.5,MarkerSize=8);

    %% Plot 4
    axes(Ax4);

    if i == 1
        % Plot 4
        grid on;
        xlabel("C_D");
        ylabel("C_L");
        title("Drag Polars");
        legend;
    end

    % plot(aeroTable.CD,aeroTable.CL,DisplayName=sprintf("%s",runName),...
    %     Color='black',Marker=tempMarker,LineStyle=tempStyle, ...
    %     LineWidth=1.5,MarkerSize=8);
    errorbar(aeroTable.CD,aeroTable.CL,...
        aeroTable.CLUnc,aeroTable.CLUnc,...
        aeroTable.CDUnc,aeroTable.CDUnc,...
        DisplayName=sprintf("%s",runName),...
        Color='black',Marker=tempMarker,LineStyle=tempStyle, ...
        LineWidth=1.5,MarkerSize=8);

    %% Plot 5
    axes(Ax5);

    if i == 1
        % Plot 5
        grid on;
        xlabel("Alpha (deg)");
        ylabel("C_L/C_D");
        title("Lift to Drag Ratios Over Angles of Attack");
        legend;
    end

    % plot(aeroTable.Pitch,aeroTable.CL./aeroTable.CD,DisplayName=sprintf("%s",runName),...
    %     Color='black',Marker=tempMarker,LineStyle=tempStyle, ...
    %     LineWidth=1.5,MarkerSize=8);
    errorbar(aeroTable.Pitch,aeroTable.CL./aeroTable.CD,...
        aeroTable.CLCDUnc,aeroTable.CLCDUnc,...
        aeroTable.PUnc,aeroTable.PUnc,...
        DisplayName=sprintf("%s",runName),...
        Color='black',Marker=tempMarker,LineStyle=tempStyle, ...
        LineWidth=1.5,MarkerSize=8);

    %% Plot 6
    axes(Ax6);

    if i == 1
        % Plot 6
        grid on;
        xlabel("Alpha (deg)");
        ylabel("C_M Pitch");
        title("Pitching Coefficient Over Angles of Attack");
        legend;
    end

    % plot(aeroTable.Pitch,aeroTable.CMP,DisplayName=sprintf("%s",runName),...
    %     Color='black',Marker=tempMarker,LineStyle=tempStyle, ...
    %     LineWidth=1.5,MarkerSize=8);

    errorbar(aeroTable.Pitch,aeroTable.CMP,...
        aeroTable.CMPUnc,aeroTable.CMPUnc,...
        aeroTable.PUnc,aeroTable.PUnc,...
        DisplayName=sprintf("%s",runName),...
        Color='black',Marker=tempMarker,LineStyle=tempStyle, ...
        LineWidth=1.5,MarkerSize=8);

    %% Plot 7
    axes(Ax7_1);

    if i == 1
        % Plot 7a
        grid on;
        xlabel("Alpha (deg)");
        ylabel("Force (lbs)");
        title("Side Force Over Angles of Attack");
    end

    % plot(aeroTable.Pitch,aeroTable.SideF,DisplayName=sprintf("%s Side Force",runName),...
    %     Color=ColorVec(3,:),Marker=tempMarker,LineStyle=tempStyle, ...
    %     LineWidth=1.5,MarkerSize=8);

    errorbar(aeroTable.Pitch,aeroTable.SideF,...
        aeroTable.SUnc,aeroTable.SUnc,...
        aeroTable.PUnc,aeroTable.PUnc,...
        DisplayName=sprintf("%s Side Force",runName),...
        Color=ColorVec(3,:),Marker=tempMarker,LineStyle=tempStyle, ...
        LineWidth=1.5,MarkerSize=8);

    axes(Ax7_2);

    if i == 1
        % Plot 7b
        grid on;
        xlabel("Alpha (deg)");
        ylabel("Coefficient");
        title("C_M Yaw and C_M Roll Over Angles of Attack");
    end

    % plot(aeroTable.Pitch,aeroTable.CMY,DisplayName=sprintf("%s C_M Yaw",runName),...
    %     Color=ColorVec(11,:),Marker=tempMarker,LineStyle=tempStyle, ...
    %     LineWidth=1.5,MarkerSize=8);
    % plot(aeroTable.Pitch,aeroTable.CMR,DisplayName=sprintf("%s C_M Roll",runName),...
    %     Color=ColorVec(12,:),Marker=tempMarker,LineStyle=tempStyle, ...
    %     LineWidth=1.5,MarkerSize=8);

    errorbar(aeroTable.Pitch,aeroTable.CMY,...
        aeroTable.CMYUnc,aeroTable.CMYUnc,...
        aeroTable.PUnc,aeroTable.PUnc,...
        DisplayName=sprintf("%s C_M Yaw",runName),...
        Color=ColorVec(11,:),Marker=tempMarker,LineStyle=tempStyle, ...
        LineWidth=1.5,MarkerSize=8);
    errorbar(aeroTable.Pitch,aeroTable.CMR,...
        aeroTable.CMRUnc,aeroTable.CMRUnc,...
        aeroTable.PUnc,aeroTable.PUnc,...
        DisplayName=sprintf("%s C_M Roll",runName),...
        Color=ColorVec(12,:),Marker=tempMarker,LineStyle=tempStyle, ...
        LineWidth=1.5,MarkerSize=8);
end

clear i runName aeroTable tempMarker MarkerVec ColorVec tempStyle LineStyleVec

%% General Formatting
Ax1_1.FontSize = 18;
Ax1_2.FontSize = 18;
Ax2_1.FontSize = 18;
Ax2_2.FontSize = 18;
Ax3.FontSize = 18;
Ax4.FontSize = 18;
Ax5.FontSize = 18;
Ax6.FontSize = 18;
Ax7_1.FontSize = 18;
Ax7_2.FontSize = 18;

Ax3.YAxis(2).Limits = Ax3.YAxis(1).Limits;

axes(Ax1_1); legend(NumColumns=2);
axes(Ax1_2); legend(NumColumns=2);
axes(Ax2_1); legend(NumColumns=2);
axes(Ax2_2); legend(NumColumns=2);
axes(Ax7_1); legend(NumColumns=2);
axes(Ax7_2); legend(NumColumns=2);

Ax1_1.Legend.Location = 'northwest';
Ax1_2.Legend.Location = 'northwest';
Ax2_1.Legend.Location = 'northwest';
Ax2_2.Legend.Location = 'northwest';
Ax3.Legend.Location   = 'northwest';
Ax4.Legend.Location   = 'northwest';
Ax5.Legend.Location   = 'northwest';
Ax6.Legend.Location   = 'northwest';
Ax7_1.Legend.Location = 'northeast';
Ax7_2.Legend.Location = 'southwest';
