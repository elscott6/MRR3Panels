function [mp] = LCH_Spiral( nc, np, offset, reverse, L_range)
%LCH_SPIRAL Generates a monotonic luminance colormap with maximum color
%saturation all based on the spherical CIE L*c*h colorsystem.
%
%   [mp] = LCH_Spiral( nc, np, offset );
%
%   nc          Number of colors (length of the colormap). Default = 64.
%   np          Number of time to cycle through hue values. Default = 1.
%   offset      Offset in degrees for the initial hue value
%   reverse     If reverse == 1, the hue values will cycle backwards
%               (R,B,G). If reverse == 0, the hue values will cycle
%               normally (R,G,B).
%   L_range     2 element array. Range of lightness values (i.e. [startL endL]).
%               Acceptable range is 0 to 100 inclusive. If startL is less
%               than endL the color table will move from dark to light.
%               Otherwise, the opposite is true. Default = [100 0].
%
%   mp    Color map output in RGB
%
%   This function returns an n x 3 matrix containing the RGB entries
%   used for colormaps in MATLAB figures. The colormap is designed
%   to have a monotonically increasing luminance, while maximizing
%   the color saturation. This is achieved by generating a line through the
%   Lch colorspace that ranges from RBG = [0 0 0] to RGB = [1 1 1]. The
%   luminance is based on human perception unlike the lightness value in
%   the HSL color system or the RGB component average intensity.
%
%Inspired By:
%   J. McNames, "An effective color scale for simultaneous color and
%   gray-scale publications," IEEE Signal Processing Magazine, 2006.
%
%Written By: Matthew Miller, NCSU, 2010
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This code is part of a suite of software developed under the guidance of
% Dr. Sandra Yuter and the Cloud Precipitation Processes and Patterns Group
% at North Carolina State University.
% Copyright (C) 2013 Matt Miller, Spencer Rhodes, and Andrew Hall
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%specify defaults
if nargin < 1
    nc = 64; %default to 64 colors
end
if nargin < 2
    np = 1; %default to 1 hue cycle
end
if nargin < 3
    offset = 0; %default to 0 degrees initial hue offset
end
if nargin < 4
    reverse = 0; %set hue cycling to normal
end
if nargin < 5
    L_range = [100 0]; %set lightness range and direction
end

%argument checking
if nargin > 5
    error('too many input arguments')
end
if np <= 0
    error('np (color period(s) must be a positive number')
end
if offset < 0
    error('hue offset value must be a positive degree value')
end
if nc <1 || nc > 256
    error('Please specify an integer number of colors between 1 and 256')
end
if reverse ~= 0 && reverse ~= 1
    error('reverse variable must be 0 for normal hue cycling or 1 for backwards hue cycling')
end
if numel(L_range) ~= 2 && isnumeric(L_range) ~= 1
    error('lightness range variable must be a 2 element numerical array')
end

%define Lch colormap

L = linspace(L_range(1),L_range(2),nc);
%L = linspace(100,0,nc);
%C = linspace(100,100,nc);
C = sqrt(50^2-(L-50).^2);
%C = (-0.04.*(L-50).^2)+100;
if reverse == 1
    H = linspace(360*np,0,nc)+offset;
else
    H = linspace(0,360*np,nc)+offset;
end

while sum(H>360)>0
    H(H>360)=H(H>360)-360;
end

%convert to RGB
mp = colorspace('LCH->RGB',[L' C' H']);

end
