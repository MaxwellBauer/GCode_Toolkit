# GCode_Toolkit
**A MATLAB-based toolkit for generating, parsing, and visualizing G-code paths for additive manufacturing applications.** This repository provides tools to:
- Generate custom G-code using predefined patterns (e.g., zigzag, ratchet).
- Visualize and animate G-code paths in 3D.

This toolkit was ultimately created to generate G-code paths for the ANSYS Mechanical DED Process simulation - informing the simulator how to perform the element birth technique to mimic material deposition.

Here is a demo of the G-code visualization:

<div align="center">
  <img src="https://github.com/user-attachments/assets/d632cc56-9b1c-47bb-97ec-81db8348196a" alt="Toolpath Visualization" width="800"/>
</div>

## Features

### G-code Generation
- Create G-code files with layer-specific custom toolpaths:
  - **Zigzag**, **ratchet**, or other custom tool patterns.
  - Configurable layer height, beam width, and path direction.
  - Supports origin shifts and multi-layer structures.
- Modular and flexible MATLAB functions for generating combinatiosn of layer-specific toolpaths.

### G-code Visualization
- Parse and visualize G-code paths with `G00` (rapid moves / deposit start location) and `G01` (linear moves / deposit end location).
- Sequentially animate the toolpath in 3D, showing:
  - **Start points** (green circles).
  - **End points** (red crosses).
  - **Connecting lines** (blue).
- Export animations as high-resolution MP4 videos.

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/MaxwellBauer/GCode_Toolkit.git
   
## Usage
1. Generating G-code
   Use the CreateLayerCoords and GenerateGCode functions to generate custom toolpaths.

   **Example: Generating a Zigzag Toolpath**
   ```matlab
   % Parameters
   startLineIndex = 1;
   patternType = 'zigzag';
   beamWidth = 6;
   sideLength = 25;
   originCoord = [0, 0, 0];
   mainAxis = [1, 0, 0];  % Lines along +X
   lineAxis = [0, -1, 0]; % Offset in -Y

   % Generate layer coordinates
   [layerCoords, startLineIndex] = CreateLayerCoords( ...
    startLineIndex, patternType, beamWidth, sideLength, originCoord, mainAxis, lineAxis);



   % Export G-code
   GenerateGCode(layerCoords, [0, 0, 0], 'zigzagGcode.txt');
   ```
2. Visualizing and Recording G-code Path
   Use the ReadAndPlotGCode function to visualize a G-code file and save the animation as an MP4 video.

   **Example: Visualizing a Toolpath**
   ```matlab
   ReadAndPlotGCode('sampleGcode.txt', 'video_filename'); 
   ```
3. Full Pipeline
   
    **Example: Combine Generation and Visualization for Single Layer ZigZag**
   ```matlab
   % Generate a zigzag path
   [layerCoords, startLineIndex] = CreateLayerCoords(1, 'zigzag', 6, 25, [0, 0, 0], [1, 0, 0], [0, -1, 0]);
   GenerateGCode(layerCoords, [0, 0, 0], 'generatedGcode.txt');

   % Visualize the generated G-code
   ReadAndPlotGCode('generatedGcode.txt', 'toolpath'); % toolpath is the video filename
   ```

   **Example: Combine Generation and Visualization for Multiple, Alternating Layer ZigZag**
   ```matlab
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
   GenerateGCode(allCoords, [0, 0, 0], 'alternating_zigzag_pattern.txt');

   % Visualize the generated G-code
   ReadAndPlotGCode('generatedGcode.txt', 'toolpath'); % toolpath is the video filename
   ```
