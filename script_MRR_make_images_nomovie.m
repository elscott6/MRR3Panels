%% Documentation
% Author: Emma Scott
% Created: 7/14/2017
% Last modified: 7/14/17 by Emma Scott
% Purpose: This script is used to read in MRR and MASC data in order to
% create 3-panel charts that display MRR reflectivity, spectral width, and doppler velocity with 
% overlays of MASC snowflake data.  Image creation is done at the end of the script
% by calling  MRR_Add_Storms_nohmtl_nomovie.m.  
%
% This script generates a single image for one storm.  If you want to make a movie, use script_MRR_make_images_redo4movies.m.
%
%
% Necessary Functions: 
% - MRR_Add_Storms_nohtml_redo4movies.m
%   - LCH_Spiral.m
%     - colorspace.m
%   - makeColorMap.m
% - caller_MRR_read_ukoln_nc.m
%   - MRR_read_ukoln_nc.m
%     - gen_readnetcdf2array_v3.m
%
% Inputs: 
%  - A .mat file with in-focus snowflake data from the MASC table in the MASC
% database, as well as a .mat file of all snowflakes from the same
% database.  These can be created by downloading tab-delimited data from
% the database, importing to excel and saving as csv, and then importing
% the csv data to MATLAB and saving the new variable to a .mat file
% - A directory where MRR data can be found, given as "directory"
% - A start and endtime for the storm, given as "starttime" and "endtime"
%
% Outputs:
% - None

%% STEP 1
% Make a new, empty folder called "storms" in your working directory. This folder will store the
% graph images. If you want to save anywhere else create any necessary
% folders and change the save path at the end of
% MRR_Add_Storms_nohtml_nomovie.m 

%% STEP 2
%Define directory where MRR data is held
directory='/home/disk/molari2/mrr/stonybrook/Reproc/2015/';

%%%%%CHANGE%%%%%%%%%%
%Set start and end time for plotting
starttime='02/01/2015 23:09';
endtime='02/02/2015 23:00';
%load data sets- in focus 1st as rawdata, then all data
load('rawdata20150202.mat');       
cellarray=rawdata20150202;
load('alldata20150202.mat');     
cellarray2=alldata20150202;    
%%%%CHANGE%%%%%%%%%%%

%Convert times to datenumber 
startinput=datenum(starttime,'mm/dd/yyyy HH:MM');
endinput=datenum(endtime,'mm/dd/yyyy HH:MM');
%Pull out the start and end day so that MRR data for those days can be
%pulled (MRR data is saved in full days)
datestart=datestr(startinput,'yyyymmdd');
dateend=datestr(endinput,'yyyymmdd');
%Set filename descriptors
prefix = 'sbu_';
suffix = '.ukoln.mrr.nc';

% Call the read_ukoln_nc function to get the MRR data:
MRR_fromukoln = caller_MRR_read_ukoln_nc(directory,prefix,datestart,dateend,suffix,1440); 
MRR = MRR_fromukoln; clear MRR_fromsimp MRR_fromukoln


%convert dates from the actual data into usable date numbers
getdates=datenum(cellarray(:,2),'mm/dd/yyyy HH:MM');
%add 2000 years, because matlab reads 3/5/15 as Mar 5 0015
Dates=getdates+datenum(2000,0,0,0,0,0);
%regular expression for the filepath up to the end of the flake number
%(common to all camera angles and reprocessed images), for use in loop
dateformflakenum='\d{4}.\d{2}.\d{2}_\d{2}.\d{2}.\d{2}.+\d+\d[^.]';
%five minute time step for use with finding occurrences of aggregates and
%graupel
fiveminstep=datenum(0,0,0,0,5,0);
%add zeros to keep structure sizes the same
MRR.diameter(1:length(MRR.dates),1)=0;
MRR.radial(1:length(MRR.dates),1)=0;
MRR.count(1:length(MRR.dates),1)=0;
MRR.graupel(1:length(MRR.dates),1)=0;
MRR.aggregates(1:length(MRR.dates),1)=0;
%loop checks each date in the MRR structure for matches in the loaded flake
%data. 
for q=1:5:length(MRR.dates)
    matchdate=MRR.dates(q);
    matchdateend=matchdate+fiveminstep;
    timeindex=find((matchdate<=Dates)&(matchdateend>Dates));
    if isempty(timeindex)
        continue         %go to next time interval if there aren't any flakes
    end
    
%pull and save radial variance and diameter for time matches into
%structure
radial=cell2mat(cellarray(timeindex,47));
radlength=length(radial);
MRR.radial(q,1:radlength)=radial;
%Find and save diameters to the start of each 5-min period
diameter=cell2mat(cellarray(timeindex,13));
dilength=length(diameter);
MRR.diameter(q,1:dilength)=diameter;

%Create non-cell structure like cellarray for graupel check
tempstor(1:length(timeindex),1)=diameter;  %diameter in first column
tempstor(1:length(timeindex),2)=cell2mat(cellarray(timeindex,46));  %solidity in column 2
tempstor(1:length(timeindex),3)=radial;  %radial variance in column 3
tempstor(1:length(timeindex),4)=cell2mat(cellarray(timeindex,44));  %frac in column 4
%tempstor(1:length(timeindex),5)=cell2mat(cellarray(timeindex,20));  %focus in column 5

%graupel check based on database query of robust minimum graupel results
graupelindex=find((2<=tempstor(:,1)<=5)&(tempstor(:,2)>0.75)&(tempstor(:,3)<6)&(tempstor(:,4)>1.6));
%count graupel results and save to MRR structure
graupelcount=length(graupelindex);
MRR.graupel(q:q+4,1)=graupelcount;    %Save the graupel count to the row that matches q as well as the next 4 rows

%Find aggregates, save separately (every minute in the five minute period
%has the same number of aggregates)
aggindex=diameter>5;
aggcount=length(diameter(aggindex));
MRR.aggregates(q:q+4,1)=aggcount;      %Save the aggregate count to the row that matches q as well as the next 4 rows
end


%Count flakes per minute from larger dataset
%load data set of ALL FLAKES


%convert dates to an easier to use format
getdates2=datenum(cellarray2(:,2),'mm/dd/yyyy HH:MM');
%add 2000 years, because matlab reads 3/5/15 as Mar 5 0015
fullsetDates=getdates2+datenum(2000,0,0,0,0,0);

for q=1:5:length(MRR.dates)
    %set start of period
    matchdate=MRR.dates(q);
    %set end of period to be +5 minutes
    matchdateend=MRR.dates(q)+datenum(0,0,0,0,5,0);
    %find matching dates
    timeindex=find((matchdate<=fullsetDates)&(matchdateend>fullsetDates));
    %process to count only unique values of flake number for each interval 
    %pull file names that match the times within the five minute interval
    fullfilepath=cellarray2(timeindex,8);
    %pull out part of file path controlled by dateforflakenum
    matches=regexp(fullfilepath,dateformflakenum,'match');
    %convert to array
    matches=[matches{:}]';
    %find and count unique values
    flakes=unique(matches);
    flakecount=length(flakes);
    %save the count
    MRR.count(q:q+4,1)=flakecount;    %Save the count to the row that matches q as well as the next 4 rows
end


%% STEP 3
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% DATE RANGE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Determine the date range over which to plot, then run data through 
%filters that handle Alta data and set extraneous dBZ
% values to NAN.  

settings.rows_per_day = 1440; % Usually, MRR data is recorded on a per
                             % minute basis. 60 mins * 24 hours = 1440 rows.
                             %Used in MRR_Add_Storms_nohtml.

%Save the indices and datenumbers  of the start and end date to the date_range structure. 
date_range = struct([]);
date_range(1).row_start=find(startinput==MRR.dates(:,1));
date_range(1).start=MRR.dates(date_range.row_start(1));
date_range(1).row_end=find(endinput==MRR.dates(:,1));
date_range(1).end=MRR.dates(date_range.row_end(1));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% DATA FILTERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Sets dBZ values that are less than 0 or greater than 75 to NaN.

% Checks if data provided includes second MRR (for Alta processing)
if isfield(settings, 'MRR2')
    MRR1 = MRR; clear MRR
    MRR2 = settings.MRR2;
    
    MRR.header = MRR1.header;
    MRR1.Z = MRR1.Z(:,6:20);
    MRR1.W = MRR1.W(:,6:20);
    MRR1.SW = MRR1.SW(:,6:20);
    counter = length(MRR1.Z(1,:));
    i = 1;
    while counter
        MRR1.Z = [MRR1.Z(:,1:i-1), repmat(MRR1.Z(:,i),1,6), MRR1.Z(:,i+1:end)];
        MRR1.W = [MRR1.W(:,1:i-1), repmat(MRR1.W(:,i),1,6), MRR1.W(:,i+1:end)];
        MRR1.SW = [MRR1.SW(:,1:i-1), repmat(MRR1.SW(:,i),1,6), MRR1.SW(:,i+1:end)];
        i = i + 6;
        counter = counter - 1;
    end
    MRR.dates = MRR1.dates;
    MRR.Z = [MRR2.Z(:,1:30), MRR1.Z];
    MRR.W = [MRR2.W(:,1:30), MRR1.W];
    MRR.SW = [MRR2.SW(:,1:30), MRR1.SW];
%     echoTopFilterStart = 121;
    
% Checks if data provided is from Alta
elseif isfield(settings, 'is_alta')
    MRR.Z = MRR.Z(:,1:21);
    MRR.W = MRR.W(:,1:21);
    MRR.SW = MRR.SW(:,1:21);
%     echoTopFilterStart = 22;
    
% Use to cut the top off of the data
elseif isfield(settings, 'choptop')
    MRR.Z = MRR.Z(:,1:24);
    MRR.W = MRR.W(:,1:24);
    MRR.SW = MRR.SW(:,1:24);
end

%Filter for reflectivity outside of reasonable range
filter_low = MRR.Z < -5;
if isfield(settings, 'miami')
    filter_high = MRR.Z > 50;
else
    filter_high = MRR.Z > 45;
end

filter = filter_low | filter_high;

MRR.Z(filter) = NaN;


%% STEP 4
% Run MRR_Add_Storms_nohtml using the filtered MRR struct and the dates struct
% defined in step 3. This creates the images.


MRR_Add_Storms_nohtml_nomovie(MRR,date_range,settings)


