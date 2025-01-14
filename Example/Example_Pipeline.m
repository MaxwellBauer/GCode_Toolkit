clear all
close all

% Parameters
nLayers        = 5;       % Number of layers
beamHeight     = 2;       % Height increment per layer
beamWidth      = 6;       % Distance between weld lines
sideLength     = 24;      % Length of each weld line
originCoords   = [13, 37.5, 0]; % Starting origin coordinate  
mainAxis       = [1, 0, 0];     % Weld lines run along +X
lineAxis       = [0, 1, 0];     % Next line offset in -Y
patternType    = 'zigzag';      % Chosen pattern
startLineIndex = 0;             % Initialize Line index, 0-indexed for Ansys

% Create the array to store all the coordinates 
allCoords = [];

% Assemble the coordinates
for i=1:nLayers
    %For the example alternating zigag, switch the main and line axes each
    %layer to get the alternating pattern

    % Odd vs Even layers
    if mod(i,2) == 1
        % Odd layer
        % Generate coordinates for this layer, main and line axes in normal input location:
        [layerCoords, startLineIndex] = CreateLayerCoords(...
        startLineIndex, 'zigzag', beamWidth, sideLength, originCoords, mainAxis, lineAxis);
    else
        % Even Line
        % Generate coordinates for this layer, main and line axes input locations swapped:
        [layerCoords, startLineIndex] = CreateLayerCoords(...
        startLineIndex, 'zigzag', beamWidth, sideLength, originCoords, lineAxis, mainAxis);
    end

    % Append the new layer's coordinates to the existing coord array
    allCoords = [allCoords; layerCoords];

    % Update Z-height for the next layer
    originCoords(3) = originCoords(3) + beamHeight;
end

% Generate G-Code for the allCoords array
GenerateGCode(allCoords, [0, 0, 0], 'generatedGcode.txt');

% Visualize the generated G-code
ReadAndPlotGCode('generatedGcode.txt', 'toolpath'); % toolpath is the video filename