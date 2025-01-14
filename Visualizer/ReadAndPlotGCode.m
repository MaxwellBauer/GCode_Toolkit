function ReadAndPlotGCode(filename, videoFilename)
% ReadAndPlotGCode reads a G-code file with G00/G01 commands and visualizes
% the toolpath as a 3D plot. The visualization includes:
%   - Green circles marking the start of each segment
%   - Red crosses marking the end of each segment
%   - Blue lines connecting each segment
%
% The plotting sequence is animated and recorded as an MP4.
%
% INPUTS:
%   filename: A string specifying the name of the input G-code file.
%
%   videoFilename: A string specifying the name of the output video file.
%                  Example: 'output.mp4'
%
% OUTPUT:
%   - A 3D plot of the G-code path with markers for start and end points.
%   - An MP4 video file showing the toolpath being plotted sequentially.
%
% HOW IT WORKS:
%   - The function parses the G-code file to extract toolpath coordinates 
%     into separate arrays for each weld line.
%   - Each G00 command starts a new weld line.
%   - Each G01 command appends a point to the current weld line.
%   - After parsing, the toolpath is visualized in 3D.
%   - The visualization is animated, and each frame is recorded in real-time 
%     and saved as a video file.

% ------------------- OPEN FILE -------------------
fid = fopen(filename, 'r');
if fid == -1
    error('Could not open file: %s', filename);
end

% Cell arrays for storing each weld line
Xweld = {};   % Xweld{i} will be a vector of X coords for weld line i
Yweld = {};   % Yweld{i} ...
Zweld = {};   % Zweld{i} ...

lineIndex = 0;  % how many weld lines so far, Gcode starts with G00 therefore will make lineIndex = 1 at start

% while haven't found end of file
while ~feof(fid)
    % parse line next line (removing leading and trailing white spaces)
    line = strtrim(fgetl(fid));

    %safety check if end of file
    if ~ischar(line)
        break;
    end

    % Skip empty or comment lines (often start with ';')
    if isempty(line) || startsWith(line,';')
        continue; % go to next iteration of loop
    end

    %Ignore anything after a semicolon ----------------
    semicolonPos = strfind(line, ';');
    if ~isempty(semicolonPos)
        line = strtrim(line(1 : semicolonPos(1)-1));
    end

    % Check if line has 'G00' or 'G01' (case-insensitive)
    isG00 = contains(line, 'G00', 'IgnoreCase', true);
    isG01 = contains(line, 'G01', 'IgnoreCase', true);

    % Check if line contains "G00" or "G01" (case-insensitive)
    if isG00 || isG01

        % Split line by spaces or tabs, collapse delimiters: ignore consecutive delimiters
        tokens = strsplit(line,{' ', '\t'}, 'CollapseDelimiters', true);

        % Parse each token (e.g. G-1, X1.0, Y2.0, Z3.0)
        for iTok = 1:numel(tokens)

            token = upper(tokens{iTok}); %make string upper case

            if startsWith(token, 'X')
                xVal = str2double(token(2:end)); %start at 2 cause X is first
            elseif startsWith(token, 'Y')
                yVal = str2double(token(2:end)); %start at 2 cause Y is first
            elseif startsWith(token, 'Z')
                zVal = str2double(token(2:end)); %start at 2 cause Z is first
            end
        end

        if isG00
            % We encountered a G00 => Start a new weld line
            lineIndex = lineIndex + 1;

            %Create the cell for this new weld line
            Xweld{lineIndex} = [];
            Yweld{lineIndex} = [];
            Zweld{lineIndex} = [];

            % Store the G00 position as the first point
            % in the new line so we know where it starts:
            Xweld{lineIndex}(end+1) = xVal;
            Yweld{lineIndex}(end+1) = yVal;
            Zweld{lineIndex}(end+1) = zVal;

        elseif isG01
            % G01 => Append to the CURRENT weld line
            % (assuming at least one G00 was encountered first)
            if lineIndex == 0
                % Edge case: if the file starts with G01 for weird reason
                % and we haven't started a line yet:
                lineIndex = 1;
                Xweld{lineIndex} = [];
                Yweld{lineIndex} = [];
                Zweld{lineIndex} = [];
            end

            Xweld{lineIndex}(end+1) = xVal;
            Yweld{lineIndex}(end+1) = yVal;
            Zweld{lineIndex}(end+1) = zVal;
        end
    end
end

fclose(fid);

% -------- OPTIONAL SETUP PLOT RECORDER --------
v = VideoWriter(videoFilename, 'MPEG-4');
v.FrameRate = 5;  % Set frame rate (10 frames per second)
v.Quality = 100;  % Maximum quality
open(v);

% -------- PLOT ALL WELD LINES --------
% Establish the figure and set the sizing so that the recording is HD
figure('Name', 'G-code Weld Path', 'NumberTitle', 'off', ...
                 'Position', [100, 100, 1920, 1080]); 

hold on;  % so we can plot multiple lines

grid on;
xlabel('X', 'FontSize', 16, 'FontWeight', 'bold');
ylabel('Y', 'FontSize', 16, 'FontWeight', 'bold');
zlabel('Z', 'FontSize', 16, 'FontWeight', 'bold');
title('G-code Path with Sequential Plotting', 'FontSize', 25, 'FontWeight', 'bold');
set(gca, 'FontSize', 14, 'FontWeight', 'bold');  % Increase font size for axes ticks
set(gca, 'Color', 'white');  % Set the axes background color to white
set(gcf, 'Color', 'white');  % Set the figure background color to white
axis equal;

% Set an isometric (3D) view
view(3);  % or use view([45 30]) for a custom angle

% Loop over each weld line and plot
for iLine = 1:lineIndex
    xData = Xweld{iLine};
    yData = Yweld{iLine};
    zData = Zweld{iLine};

    % Animate each segment of this line
    % If we have 1 point, we just plot a marker
    if length(xData) < 2
        % Single point
        plot3(xData, yData, zData, 'ro', 'MarkerSize', 6);
        drawnow;
        pause(0.1);
    else
        % Multiple points => plot each segment in real time
        for iPt = 2:length(xData)
            % Plot start/stop location of each line sequentially to see
            % directionaliy

            % Plot start point (green circle)
            plot3(xData(iPt-1), yData(iPt-1), zData(iPt-1), 'go', 'MarkerSize', 8, 'LineWidth', 2);

            % Pause for visualization and capture frame
            pause(0.3);
            frame = getframe(gcf);
            writeVideo(v, frame);

            % Plot end point (red cross)
            plot3(xData(iPt), yData(iPt), zData(iPt), 'rx', 'MarkerSize', 8, 'LineWidth', 2);
            % Plot the connecting line
            plot3(xData(iPt-1:iPt), yData(iPt-1:iPt), zData(iPt-1:iPt), 'b-', 'LineWidth', 3);
            
            drawnow;      % force immediate drawing
            % Pause for visualization and capture frame
            pause(0.3);
            frame = getframe(gcf);
            writeVideo(v, frame);
        end
    end
end

hold off;

% -------- CLOSE VIDEO WRITER --------
close(v);
disp(['Video saved to: ', videoFilename]);
end