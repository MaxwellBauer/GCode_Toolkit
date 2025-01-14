function GenerateGCode(coords, originCoord, filename)
% GenerateGCode Generates G-code with multiple weld lines.
%
% INPUTS:
%   coords: An Nx4 matrix of coordinates [lineIndex, X, Y, Z].
%           - lineIndex: A unique index for each weld line.
%           - X, Y, Z: Coordinates of the tool path points.
%           Example:
%               coords = [
%                   1,  0,  0,  0;   % Weld line 1
%                   1, 10,  0,  0;
%                   2,  5,  5,  0;   % Weld line 2
%                   2, 10,  5,  0;
%               ];
%
%   originCoord: A 1×3 vector [x0, y0, z0] specifying the origin shift 
%                for the coordinates. If empty or not provided, the origin
%                defaults to [0, 0, 0].
%
%   filename: The name of the output G-code file (e.g., 'output.gcode').
%
% OUTPUT:
%   A G-code file is generated with the specified tool paths. The file
%   includes:
%       - A G00 command to move to the first point of each weld line.
%       - A sequence of G01 commands to draw the rest of the weld line.
%
% HOW IT WORKS:
%   - The function shifts all input coordinates by the specified originCoord.
%   - Each unique lineIndex in coords corresponds to one weld line.
%   - For each weld line:
%       1) The first point is printed as a G00 command (rapid move).
%       2) Subsequent points are printed as G01 commands (deposition moves).
%   - The output is written to the specified file.

% ------------------ Validate Inputs ------------------
if size(coords, 2) < 4
    error('coords must have at least 4 columns: [lineIndex, X, Y, Z].');
end

if nargin < 3 || isempty(originCoord) %if number of arguments less than 3 or no coord input
    % Default origin = (0, 0, 0) => No shift
    originCoord = [0, 0, 0];
end

if length(originCoord) ~= 3
    error('originCoord must be a 3-element vector: [x0, y0, z0].');
end

% ------------------ Apply Origin Shift ------------------
% Shift all X/Y/Z columns by originCoord
coords(:,2) = coords(:,2) + originCoord(1);  % X
coords(:,3) = coords(:,3) + originCoord(2);  % Y
coords(:,4) = coords(:,4) + originCoord(3);  % Z

% Open file
fid = fopen(filename, 'w');
if fid == -1
    error('Could not open file: %s', filename);
end

% Extract the line indices
allLines = coords(:,1);               % 1st column = lineIndex
uniqueLines = unique(allLines, 'stable'); % preserve order they appear
%Gets rid of repeated indexes

for iLine = 1:length(uniqueLines) % for each weld line
    currentLine = uniqueLines(iLine);

    % Extract rows for this line, cool way of getting all rows where it
    % is the current line
    lineRows = (allLines == currentLine);
    lineData = coords(lineRows, :);

    % The FIRST point in this line => G00
    xFirst = lineData(1, 2);  % 2nd column = X
    yFirst = lineData(1, 3);  % 3rd column = Y
    zFirst = lineData(1, 4);  % 4th column = Z

    %print to file
    fprintf(fid, 'G00 X%.3f Y%.3f Z%.3f  ; (Start new weld line %g)\n', xFirst, yFirst, zFirst, currentLine);

    % The rest => G01
    for iPt = 2:size(lineData,1) % for each row, after the first point of the weld line, hence 2
        xVal = lineData(iPt, 2); % 2nd column = X
        yVal = lineData(iPt, 3); % 3rd column = Y
        zVal = lineData(iPt, 4); % 4th column = Z
        fprintf(fid, 'G01 X%.3f Y%.3f Z%.3f\n', xVal, yVal, zVal);
    end
end

fclose(fid);
disp(['Multi-line G-code file generated: ', filename]);
end