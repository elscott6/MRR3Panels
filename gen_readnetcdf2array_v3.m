function [dim_cell data_struct ] = gen_readnetcdf2array_v3(filepath, varargin )
%% Documentation Section
% Function:  readnetcdf2array.m
% Author:  Jeff Cunningham (edited for missing_value retrieval and global
% constants by Andrew Hall)
% Version Date:  June 08, 2010
% Purpose:  The purpose of this function is to read in fields from a NETCDF
% file and convert them to arrays.
% Matlab Requirements:  2008b or later.
% Input Arguments:  1) filepath - the complete path of the input file
% including the filename (in string format), 2) missingdatavalue - allows
% the user to replace values in fields that are equivalent to misssing data
% with NaNs, and 3) varargin - the NETCDF fields user wants to retrieve
% (as few as one or as many fields as necessary may be entered).
% ---varargin: one of two forms should be used.  For actual data use
% --- ...,'netcdfdataname', 'distanceR'
% --- to retrieve global constants (such as base-date or lat/lon
% --- ...,'GLBL.netcdfglobalname',... i.e. ...,'GLBL.base_date',...
% Output Arguments:  1) dimname - cell array of the dimension names, 2)
% cell array of dimension lengths, and 3) vargout - NETCDF fields converted
% to arrays, GLOBAL values are returned as strings
% Example usage:  [dimname dimlen maxdz radvel lat] = readnetcdf2array('/home/disk/valen2/zeb-data/oregon/krtx_3d_1km/KRTX.20051201.060458.cdf',-32768,'maxdz', 'radvel', 'lat');
% Important Note:  Output arguments must be in the same order as the input
% arguments!
%% Prep Section
% Default missing value
replacevalue = NaN;
missingdatavalue = NaN;

%This "hard coded" variable correspond to the following netCDF data types in matlab format
% ['NC_BYTE', 'NC_CHAR', 'NC_SHORT', 'NC_INT', 'NC_FLOAT', 'NC_DOUBLE'] at
% the time of coding these are the only supported variable types for netcdf
% files.  The below variable types correspond 1-to-1 to their matlab types
% below
variable_types = {'int8', 'char', 'int16', 'int32', 'single', 'double'};


% Open NETCDF file
ncid = netcdf.open(filepath,'NC_NOWRITE');

% Request the number of dimensions in the NETCDF file
[numdims, ~, numgatts] = netcdf.inq(ncid);

% Request dimensions
dimname=cell(numdims,1);
dimlen=cell(numdims,1);

for k = 0:numdims-1
    
    % Get name and length of dimensions
    [dimname{k+1}, dimlen{k+1}] = netcdf.inqDim(ncid,k);
    dim_cell{k+1,1} = dimname{k+1};
    dim_cell{k+1,2} = dimlen{k+1};
    dim_cell{k+1,3} = k;
    
end



%% Loop through all the input arguements and then through each attributes
% of each input argument
for i = 1:length(varargin)
    
    % Check to see if a Global Constant or Variable is being requested
    if ~strncmp(varargin{i},'GLBL',4)
        
        varID = netcdf.inqVarID(ncid,varargin{i});
        [name type dimvar natts] = netcdf.inqVar(ncid,varID);
        var_list{i} = [varID name variable_types(type) dimvar natts 0 0];
        data_struct(i).name = var_list{i}{2};
        data_struct(i).type = [variable_types(type) type];
        data_struct(i).dimIDs = dimvar;
        
        cur_ID = var_list{i}{1};
        cur_type = var_list{i}{3};
        
        for matlabIndex = 1:var_list{i}{5}
            
            ncidIndex = matlabIndex - 1;
            
            data_struct(i).attributes{matlabIndex,1} = netcdf.inqAttName(ncid,cur_ID,ncidIndex);
            data_struct(i).attributes{matlabIndex,2} = netcdf.getAtt(ncid,cur_ID,data_struct(i).attributes{matlabIndex,1});
            data_struct(i).attributes{matlabIndex,3} = ncidIndex;
            
            % Checks for various attributes
            % First check to see if int is unsigned or not
            if strcmp(cur_type,'int8') && strcmp(data_struct(i).attributes{matlabIndex,1},'_Unsigned') && strcmp(data_struct(i).attributes{matlabIndex,2},'true')
                var_list{i}{3} = 'uint8';
            end
            
            % Check to see if a 'missing_value' is pres_valueent and sets it.
            if strcmp(data_struct(i).attributes{matlabIndex,1},'missing_value')
                missingdatavalue = data_struct(i).attributes{matlabIndex,2};
                if missingdatavalue == [1 0]
                    missingdatavalue = 1;
                end
            end
            
            %Logic to check for presence of scale/offset correction of packed data
            if strcmp(data_struct(i).attributes{matlabIndex,1},'scale_factor')
                var_list{i}{6} = data_struct(i).attributes{matlabIndex,2};
            end
            if strcmp(data_struct(i).attributes{matlabIndex,1},'add_offset')
                var_list{i}{7} = data_struct(i).attributes{matlabIndex,2};
            end
        end
        
        % Read variable from NETCDF file into variable number of outputs
        data_struct(i).data = netcdf.getVar(ncid,cur_ID,char(var_list{i}{3}));
        
        % Logic for replacing missing values and any special case replacement.
        % The below is required because matlab does not support NaN for uint8
        if var_list{i}{6} ~= 0
            data_struct(i).data = single(data_struct(i).data);
            data_struct(i).data(data_struct(i).data==missingdatavalue)=replacevalue;
            data_struct(i).data = data_struct(i).data * single(var_list{i}{6}) + single(var_list{i}{7}); % Modified by JC to make scale and offset singles
        else
            data_struct(i).data(data_struct(i).data==missingdatavalue)=replacevalue;
        end
        
        %code used for global constant retrieval
    elseif strncmp(varargin{i},'GLBL',4)
        if strcmp(varargin{i},'GLBL.ALLGLOBALS')
            
            for matlabindex = 1:numgatts
                ncidindex = matlabindex -1;
                data_struct(i).attributes{matlabindex,1} = netcdf.inqAttName(ncid,netcdf.getConstant('NC_GLOBAL'),ncidindex);
                data_struct(i).attributes{matlabindex,2} = netcdf.getAtt(ncid,netcdf.getConstant('NC_GLOBAL'),data_struct(i).attributes{matlabindex,1});
                data_struct(i).attributes{matlabindex,3} = ncidindex;
            end
        else
            global_type = regexp(varargin{i},'\.', 'split');
            data_struct(i).name = char(global_type(2));
            data_struct(i).data = netcdf.getAtt(ncid,netcdf.getConstant('NC_GLOBAL'),char(global_type(2)));
        end
    end
end

% Close NETCDF file
netcdf.close(ncid);
end

