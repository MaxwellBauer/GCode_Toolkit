function [layerCoords, startLineIndex] = CreateLayerCoords(startLineIndex, patternType, beamWidth, sideLength, originCoord, mainAxis, lineAxis)
% CreateLayerCoords creates a matrix of coordinates [lineIndex, X, Y, Z]
% for ONE layer with a chosen pattern (e.g. 'zigzag') and Direction Vectors.
%
%INPUTS:
%   startLineIndex   : The first lineIndex to use (to build off previous lines), 0 if first line.
%   patternType      : A string, e.g. 'zigzag' or 'raster'
%   beamWidth        : Width of each weld line
%   sideLength       : The sidelength of the sample's square cross-section.
%   originCoord      : The Z-level at which this layer is printed.
%   mainAxis         : A 1×3 vector specifying the primary direction of each weld line.
%                      E.g., [1 0 0] for +X, [0 -1 0] for -Y, etc.
%   lineAxis         : A 1×3 vector specifying how successive lines are offset
%                      relative to each other (perpendicular or angled).
%                      E.g., [0 1 0] for +Y, [0 0 1] for +Z, etc.
% OUTPUT:
%   layerCoords   : An N×4 matrix: [lineIndex, X, Y, Z]
%                   Summarizing the lineIndex and coordinates of all weld lines.
%
% EXAMPLE USE:
%   % Pattern: zigzag
%   % Lines in +X (mainAxis = [1 0 0]), stepping in -Y (lineAxis = [0 -1 0])
%   patternType        = 'zigzag';
%   beamWidth          = 6;
%   beamLength         = 25;
%   zHeight            = 0;
%   startLineIndex     = 1;
%   mainAxis           = [1 0 0];    % lines go along +X
%   lineAxis           = [0 -1 0];   % next line is offset in -Y
%   coordsLayer1 = createLayerCoords(startLineIndex, patternType, beamWidth, sideLength, originCoord, mainAxis, lineAxis);

% Check that input axis are 3-element vectors
if numel(mainAxis) ~= 3 || numel(lineAxis) ~= 3
    error('mainAxis and lineAxis must be 3-element vectors [x, y, z].');
end

% Check that dimensions of square sample are wholey divisible by beamWidth
if rem(sideLength, beamWidth) ~= 0
    error('sideLength should be wholey divisible by beamWidth');
end

% Make sure the axis are unit vector
mainAxis = mainAxis / norm(mainAxis);
lineAxis = lineAxis / norm(lineAxis);

% Use cells for flexible storage
coordsCell = {}; % collect each weld line in a cell array
lineCount = 0;   % count how many weld lines are created

% Determine how many lines to generate for the selected pattern
switch patternType
    case 'zigzag'
        % The zigzag pattern involves consecutive lines proceeding in
        % opposite directions.
        %   - odd lines go from "start" to "start + mainAxis*sideLength"
        %   - even lines travel from "start + mainAxis*sideLength" to "start"
        % Each line is shifted over by beamWidth from the previous line

        %How many lines in this pattern?
        nLines = sideLength/beamWidth;

        %Assemble the coordinates for each line
        for i = 1:nLines
            lineCount = lineCount +1; % new weld line
            lineIdx   = startLineIndex + lineCount; % store line index for coord array

            % where does line i start?
            % create line offset to track motion in lineAxis direction
            lineOffset = lineAxis * (i - 1) * beamWidth; % (i-1) so that first line is not offset

            % the beam should start at the middle of the beam: 
            % assume the beam midpoint is beamWidth/2 from the originCoord in
            % the lineAxis unit vector direction:
            beamOffset = lineAxis * beamWidth/2; % start beam at beamWidth midpoint

            % Odd vs Even Lines
            if mod(i,2) == 1
                % Odd line
                startVec = originCoord + lineOffset + beamOffset; % where weld line starts
                endVec   = originCoord + lineOffset + beamOffset + mainAxis*sideLength; % weld end
            else
                % Even Line
                % Starts near endVec of previous line
                startVec = originCoord + lineOffset + beamOffset + mainAxis*sideLength; % weld start
                endVec   = originCoord + lineOffset + beamOffset; % weld end
            end

            % Store the start and end vectors for that line as coordinates
            coordsCell{end+1} = [
                lineIdx, startVec(1), startVec(2), startVec(3);
                lineIdx, endVec(1),   endVec(2),   endVec(3)
                ];
        end

    case 'raster'
        % the raster pattern involves consecutive lines proceeding in the
        % same direction. Consecutive lines will be offset by the beamWidth.
        nLines = sideLength/beamWidth;

        % Assemble the coordinates for each line
        for i = 1:nLines
            lineCount = lineCount +1; % new weld line
            lineIdx   = startLineIndex + lineCount -1; % store line index for coord array

            % Offset for line i along the lineAxis
            lineOffset = lineAxis*(i-1)*beamWidth; % (i-1) so that first line is not offset

            % the beam should start at the middle of the beam: 
            % assume the beam midpoint is beamWidth/2 from the originCoord in
            % the lineAxis unit vector direction:
            beamOffset = lineAxis * beamWidth/2; % start beam at beamWidth midpoint

            % Create the start and stop vectors for each weld line
            startVec = originCoord + beamOffset + lineOffset; % where weld line starts
            endVec   = originCoord + beamOffset + lineOffset + mainAxis*sideLength; % weld end

            % Store the start and end vectors for that line as coordinates
            coordsCell{end+1} = [
                lineIdx, startVec(1), startVec(2), startVec(3);
                lineIdx, endVec(1),   endVec(2),   endVec(3)
                ];
        end
    otherwise
        error('Unknown patternType: %s', patternType);
    end

% Concatenate all cell entries into one numeric array
% Puts the cell content into the desired coord format for generating Gcode
% That is Nx4 => [lineIndex, X, Y, Z].
layerCoords = vertcat(coordsCell{:});

% Update the startLineIndex variable to be the current lineIdx
startLineIndex = lineIdx;
end
