function varargout = shed(varargin)
% SHED M-file for shed.fig
%      SHED, by itself, creates a new SHED or raises the existing
%      singleton*.
%
%      H = SHED returns the handle to a new SHED or the handle to
%      the existing singleton*.
%
%      SHED('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SHED.M with the given input arguments.
%
%      SHED('Property','Value',...) creates a new SHED or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before shed_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to shed_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help shed

% Last Modified by GUIDE v2.5 14-Feb-2013 14:20:30

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @shed_OpeningFcn, ...
                   'gui_OutputFcn',  @shed_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before shed is made visible.
function shed_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to shed (see VARARGIN)

% Choose default command line output for shed
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes shed wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% --- initialize shed environment ---
shed_init();

% --- initialize GUI objects ---
shed_init_gui(handles);

% --- update parameter displays ---
shed_update_gui(handles);
return




% --- Outputs from this function are returned to the command line.
function varargout = shed_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on slider movement.
function slider_SLICE_Callback(hObject, eventdata, handles)
% hObject    handle to slider_SLICE (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

global params
global actmap underlay regions nx ny nz

if (isempty(actmap) && isempty(underlay))
    params.slicenum = -1;
else
    params.slicenum = fix(get(hObject,'Value') * (nz-1) + 1);
    draw_image();
end
shed_update_gui(handles);

% --- Executes during object creation, after setting all properties.
function slider_SLICE_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider_SLICE (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function slider_PASS_Callback(hObject, eventdata, handles)
% hObject    handle to slider_PASS (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

global params
global actmap underlay regions nx ny nz

params.passnum = fix(get(hObject,'Value'));
if (~isempty(regions))
    draw_image();
end
shed_update_gui(handles);



% --- Executes during object creation, after setting all properties.
function slider_PASS_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider_PASS (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in button_GO.
function button_GO_Callback(hObject, eventdata, handles)
% hObject    handle to button_GO (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global params
global actmap underlay regions nx ny nz

if (isempty(actmap))
    warndlg('You must load an Activation Map first','CreateMode','modal'); 
    uiwait(gcf);
    return
end

regions = [];
draw_image();
  
params.remove_isolated_sheds = get( handles.radio_REMOVE,'Value');   
params.recover_lost_clusters = get( handles.radio_RECOVER,'Value');   
params.restore_cluster_edges = get( handles.radio_RESTORE,'Value') * 20;                                               
params.use26                 = get( handles.radio_USE26,'Value');  
params.save_inter            = get( handles.radio_SAVEINTER,'Value'); 

set(handles.figure1, 'pointer', 'watch'); drawnow;
regions = shed_engine(actmap.zmap, params);
set(handles.figure1, 'pointer', 'arrow'); drawnow;

set(handles.slider_PASS,'Value',get(handles.slider_PASS, 'Max'));
params.passnum = fix(get(handles.slider_PASS,'Value'));
shed_update_gui(handles);

draw_image();
return


% --- Executes on button press in button_LOADMAP.
function button_LOADMAP_Callback(hObject, eventdata, handles)
% hObject    handle to button_LOADMAP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global params
global actmap underlay regions nx ny nz

%[file, path] = uigetfile({'*.nii';'*.nii.gz'},'Select a Nifti file with the Activation Map',params.niipath1);
[file, path] = uigetfile({'*.nii;*.nii.gz','NIFTIs (*.nii, *.nii.gz)'},'Select a Nifti file with the Activation Map',params.niipath1);
if isequal(file,0), return; end
params.niipath1 = path;
params.actfile  = file;
load_actmap([path file],params.reorient_images);
params.slicenum = fix(get(handles.slider_SLICE,'Value') * (nz-1) + 1);
regions = [];   % remove existing watersheds map
draw_image();
return

function text_THRESH1_Callback(hObject, eventdata, handles)
% hObject    handle to text_THRESH1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of text_THRESH1 as text
%        str2double(get(hObject,'String')) returns contents of text_THRESH1 as a double

global params

val = check_stringnum(get(hObject,'String'),0,100);
if (~isempty(val)), params.thresh1 = val; end
shed_update_gui(handles);
draw_image();
return

% --- Executes during object creation, after setting all properties.
function text_THRESH1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text_THRESH1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in button_LOADUNDER.
function button_LOADUNDER_Callback(hObject, eventdata, handles)
% hObject    handle to button_LOADUNDER (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global params
global actmap underlay regions nx ny nz

[file, path] = uigetfile({'*.nii;*.nii.gz','NIFTIs (*.nii, *.nii.gz)'},'Select a Nifti file for the Underlay image',params.niipath2);
if isequal(file,0), return; end
params.niipath2 = path;
load_underlay([path file],params.reorient_images);
params.slicenum = fix(get(handles.slider_SLICE,'Value') * (nz-1) + 1);
draw_image();
return

function text_THRESH2_Callback(hObject, eventdata, handles)
% hObject    handle to text_THRESH2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of text_THRESH2 as text
%        str2double(get(hObject,'String')) returns contents of text_THRESH2 as a double

global params

val = check_stringnum(get(hObject,'String'),0,100);
if (~isempty(val)), params.thresh2 = val; end
shed_update_gui(handles);


% --- Executes during object creation, after setting all properties.
function text_THRESH2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text_THRESH2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function text_EXTENT1_Callback(hObject, eventdata, handles)
% hObject    handle to text_EXTENT1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of text_EXTENT1 as text
%        str2double(get(hObject,'String')) returns contents of text_EXTENT1 as a double

global params

val = check_stringnum(get(hObject,'String'),0,1e6,1);
if (~isempty(val)), params.extent1 = val; end
shed_update_gui(handles);
return

% --- Executes during object creation, after setting all properties.
function text_EXTENT1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text_EXTENT1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function text_SMOOTH_Callback(hObject, eventdata, handles)
% hObject    handle to text_SMOOTH (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of text_SMOOTH as text
%        str2double(get(hObject,'String')) returns contents of text_SMOOTH as a double

global params

val = check_stringnum(get(hObject,'String'),0);
if (~isempty(val)), params.smooth = val; end
shed_update_gui(handles);

% --- Executes during object creation, after setting all properties.
function text_SMOOTH_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text_SMOOTH (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in radio_RESTORE.
function radio_RESTORE_Callback(hObject, eventdata, handles)
% hObject    handle to radio_RESTORE (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radio_RESTORE


% --- Executes on button press in radio_RECOVER.
function radio_RECOVER_Callback(hObject, eventdata, handles)
% hObject    handle to radio_RECOVER (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radio_RECOVER


% --- Executes on button press in radio_REMOVE.
function radio_REMOVE_Callback(hObject, eventdata, handles)
% hObject    handle to radio_REMOVE (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radio_REMOVE


% --- Executes on button press in radio_USE26.
function radio_USE26_Callback(hObject, eventdata, handles)
% hObject    handle to radio_USE26 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radio_USE26


% --- Executes on button press in button_SAVE.
function button_SAVE_Callback(hObject, eventdata, handles)
% hObject    handle to button_SAVE (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global params
global actmap underlay regions nx ny nz

if (isempty(regions))
    warndlg('No Watershed result to save.','CreateMode','modal'); 
    uiwait(gcf);
    return
end

params.save_inter = get( handles.radio_SAVEINTER,'Value');  
save_result();
return

% --- Executes on button press in radio_SAVEINTER.
function radio_SAVEINTER_Callback(hObject, eventdata, handles)
% hObject    handle to radio_SAVEINTER (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radio_SAVEINTER



function text_EXTENT2_Callback(hObject, eventdata, handles)
% hObject    handle to text_EXTENT2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of text_EXTENT2 as text
%        str2double(get(hObject,'String')) returns contents of text_EXTENT2 as a double

global params

val = check_stringnum(get(hObject,'String'),0,1e6,1);
if (~isempty(val)), params.extent2 = val; end
shed_update_gui(handles);

% --- Executes during object creation, after setting all properties.
function text_EXTENT2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text_EXTENT2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




% -----------------------------------------------------------------------
% -----------------------------------------------------------------------
% User-written routines that interact with the GUI
% (above here is autogenerated code from the GUIDE app)
% -----------------------------------------------------------------------
% -----------------------------------------------------------------------

% -----------------------------------------------------------------------
function shed_init_gui(handles)

global params
global axes1 axes2

set(handles.slider_SLICE,'Value',0.5);
set(handles.slider_PASS,'Value',get(handles.slider_PASS, 'Max'));
params.passnum = fix(get(handles.slider_PASS,'Value'));
axes1 = handles.axes1;
axes2 = handles.axes2;
axis([axes1,axes2],'off');
axis([axes1,axes2],'image');
datacursormode(handles.figure1); % enable the data cursor in all axes windows
obj = datacursormode(handles.figure1);
set(obj,'UpdateFcn',@datacursor_func)

 % set(handles.uipanel2,'BackgroundColor','none'); % doesn't work!!
return

% -----------------------------------------------------------------------
function shed_update_gui(handles)

global params

set(handles.text_THRESH1,'string',sprintf('%7.3f',params.thresh1));
set(handles.text_THRESH2,'string',sprintf('%7.3f',params.thresh2));
set(handles.text_EXTENT1,'string',sprintf('%1d',fix(params.extent1)));
set(handles.text_EXTENT2,'string',sprintf('%1d',fix(params.extent2)));
set(handles.text_SMOOTH, 'string',sprintf('%1d',fix(params.smooth)));

set(handles.radio_RESTORE,  'Value',(params.restore_cluster_edges ~= 0));
set(handles.radio_RECOVER,  'Value',params.recover_lost_clusters);
set(handles.radio_REMOVE,   'Value',params.remove_isolated_sheds);
set(handles.radio_USE26,    'Value',params.use26);
set(handles.radio_SAVEINTER,'Value',params.save_inter);

set(handles.text_PASSNUM,  'string',sprintf('%1d',get(handles.slider_PASS, 'Value')));
if (params.slicenum < 0)
    set(handles.text_SLICENUM,  'string','-');
else
    set(handles.text_SLICENUM,  'string',sprintf('%1d',params.slicenum));
end
return

% -----------------------------------------------------------------------
function txt = datacursor_func(~,obj)

global axes1 axes2
global actmap underlay regions nx ny nz
global params

target = get(obj,'Target');
window = get(target,'Parent');
pos    = get(obj,'Position');
txt    = sprintf('x,y = %1d,%1d',pos(1),pos(2)); 
if (isequal(window,axes1))
    if (~isempty(actmap))
        zval = actmap.zmap(pos(2),pos(1),params.slicenum); % note y,x transpose!
        txt  = { txt sprintf('z = %1.2f',zval) };
    end
elseif (isequal(window,axes2))
    if (~isempty(regions))
        reg = regions(pos(2),pos(1),params.slicenum,params.passnum); % note y,x transpose!
        txt = { txt sprintf('region %1d',reg) };
    end
end
return


% -----------------------------------------------------------------------
% -----------------------------------------------------------------------
% User-written routines that DO NOT interect with the GUI
% -----------------------------------------------------------------------
% -----------------------------------------------------------------------

% -----------------------------------------------------------------------
function shed_init()

global params
global actmap underlay regions nx ny nz
global templut regionlut graylut lutN

params.thresh1               = 5;
params.thresh2               = 10;
params.extent1               = 200;
params.extent2               = 100;
params.smooth                = 0;                 
params.remove_isolated_sheds = 1;   
params.recover_lost_clusters = 1;   
params.restore_cluster_edges = 20;                                               
params.use26                 = 1; 
params.save_inter            = 0;

if (ispc())
    params.niipath1          = [getenv('HOME') '\Documents\DATA\'];
elseif (isunix())
    params.niipath1          = '~/data/';
elseif (ismac())
    params.niipath1          = '';
else
    params.niipath1          = '';
end
params.niipath2 = params.niipath1;

params.slicenum              = -1;
params.passnum               = -1;
params.reorient_images = 1; % orient images so they display right (assumes axials!)

underlay = [];
actmap   = [];
regions  = [];

lutN      = 256;
templut   = colormap(hot(lutN));
graylut   = colormap(gray(lutN));
%regionlut = colormap(lines(lutN));
regionlut = rand(lutN,3);
regionlut(1,:) = 0;
return

% -----------------------------------------------------------------------
function val = check_stringnum(stringv,minv,maxv,make_integer)

val = str2double(stringv);
if (isnan(val))
    warndlg('Input must be a number','CreateMode','modal'); 
    uiwait(gcf);
    val = [];
    return
end
if (nargin > 1)
    if (val < minv)
        warndlg(sprintf('Input value must be >= %g',minv),'CreateMode','modal'); 
        uiwait(gcf);
        val = []; 
        return
    end
end
if (nargin > 2)
    if (val > maxv)
        warndlg(sprintf('Input value must be <= %g',maxv),'CreateMode','modal'); 
        uiwait(gcf);
        val = []; 
        return
    end
end
if (nargin < 4), make_integer = 0; end
if (make_integer), val = fix(val); end
return

% -----------------------------------------------------------------------
function load_actmap(filename,reorient)

global actmap underlay nx ny nz
global templut regionlut graylut lutN

if (nargin < 2), reorient = 0; end

actmap = read_nifti(filename);

img  = actmap.img;
img(img < 0) = 0;                               % only consider positive actmap voxels
if (reorient)
    %img = flipdim(permute(img,[2,1,3]),1);     % make axials display right (for YDir = reverse)
    img = permute(img,[2,1,3]);                 % make axials display right (for YDir = normal)
end
actmap.zmap = img;                              % copy of actmap to work with
actmap.maxZ = max(actmap.zmap(:));              
actmap.pic  = scale_image_for_LUT(img, lutN);   % copy for indexing into a LUT

[nx1,ny1,nz1] = size(actmap.zmap);
if (~isempty(underlay))
    if (nx1 ~= nx) || (ny1 ~= ny) || (nz1 ~= nz)
         warndlg(sprintf('Structural image dimensions do not match activation. Discarding Structura'));
         underlay = [];
    end     
end
nx = nx1; ny = ny1; nz = nz1;
return

% -----------------------------------------------------------------------
function load_underlay(filename,reorient)

global actmap underlay nx ny nz
global templut regionlut graylut lutN

if (nargin < 2), reorient = 0; end

underlay = read_nifti(filename);
img      = underlay.img;
if (reorient)
    img  = permute(img,[2,1,3]);                 % make axials display right
end
underlay.pic = scale_image_for_LUT(img, lutN);   % copy for indexing into a LUT

[nx1,ny1,nz1] = size(underlay.pic);
if (~isempty(actmap))
    if (nx1 ~= nx) || (ny1 ~= ny) || (nz1 ~= nz)
         warndlg(sprintf('Underlay image dimensions dont match actmap. Ignoring underlay'));
         underlay = [];
    end     
end
nx = nx1; ny = ny1; nz = nz1;
return

% -----------------------------------------------------------------------
function vol = read_nifti(filename)

[path,root,ext] = fileparts(filename);
if (isequal(ext,'.gz'))
    newfile = gunzip(filename,getenv('TEMP'));
    newfile = newfile{1};
else
    newfile = filename;
end
vol = load_untouch_nii(newfile);
return

% -----------------------------------------------------------------------
function save_result()

global params
global actmap underlay regions nx ny nz

[tmp, name] = fileparts(params.actfile);
regions_hdr = actmap;

defname = sprintf('%s%s_shed_%1.2f_%1.2f_%1d_%1d.nii',params.niipath1,name,params.thresh1,params.thresh2,params.extent1,params.extent2);
% [file,path] = uiputfile('*.nii','Save result as...',defname);
% if (isequal(file,0)), return; end
% newfile = [path file];
newfile = defname;

fprintf('\nWriting out Watershed labels to file %s\n',newfile);
%regions_hdr.img = single(regions);  % pretty sure that save_untouch_nii() converts data to header type on fwrite()
if (params.reorient_images)
    regions_hdr.img = permute(regions(:,:,:,5),[2,1,3]); % undo reorient
else
    regions_hdr.img = regions(:,:,:,5);
end
save_untouch_nii(regions_hdr, newfile);

if (~params.save_inter), return, end
defname = sprintf('%s%s_dist_%1.2f_%1.2f_%1d_%1d.nii',params.niipath1,name,params.thresh1,params.thresh2,params.extent1,params.extent2);
newfile = defname;
fprintf('Writing out Watershed voxel distances to file %s\n',newfile);
if (params.reorient_images)
    regions_hdr.img = permute(regions(:,:,:,6),[2,1,3]); % undo reorient
else
    regions_hdr.img = regions(:,:,:,6);
end
save_untouch_nii(regions_hdr, newfile);

return

% -----------------------------------------------------------------------
function pic = scale_image_for_LUT(img, lutrange)
% Scale an image to go from [1,lutrange]
% for use in indexing into a color LUT (MATLAB indexes 1..N)

pic  = double(img);
maxv = max(pic(:));
minv = min(pic(:));
pic  = round( (pic-minv)/(maxv-minv) * (lutrange-1) ) + 1;

return

% -----------------------------------------------------------------------
function draw_image()

global params
global actmap underlay regions nx ny nz
global axes1 axes2
global templut regionlut graylut lutN

zthresh = params.thresh1;
slice   = params.slicenum;

if (~isempty(regions))
    labels = regions(:,:,:,params.passnum);
end

% --- Draw the activation and underlay images ---
axes(axes1);
if (isempty(underlay) && isempty(actmap))
    cla % erases window
else
    if (isempty(underlay))
        pic = actmap.pic(:,:,slice);
        pic(actmap.zmap(:,:,slice) < zthresh) = 1; % lowest index into LUT
        rgbimg = templut(pic,:);
        
    elseif (isempty(actmap))
        rgbimg = graylut(underlay.pic(:,:,slice),:);
    else
        rgbimg = graylut(underlay.pic(:,:,slice),:);
        p = find(actmap.zmap(:,:,slice) >= zthresh);
        if (~isempty(p))
            pic = actmap.pic(:,:,slice);
            rgbimg(p,:) = templut(pic(p),:);
        end
    end

    rgbimg = reshape(rgbimg,nx,ny,3);
    image(rgbimg);
    set(gca,'YDir','normal')
    axis off
    axis image
end

% --- Draw the watershed regions ---
axes(axes2);
if (isempty(regions))
    cla
else
    if (isempty(underlay))
        index  = mod(labels(:,:,slice),lutN) + 1 ; % index into LUT, with wrap if more regions than color entries
        rgbimg = regionlut(index,:);
    else
        rgbimg = graylut(underlay.pic(:,:,slice),:);
        p = find(labels(:,:,slice) > 0);
        if (~isempty(p))
            index = mod(labels(:,:,slice),lutN) + 1 ; % index into LUT, with wrap if more regions than color entries
            rgbimg(p,:) = regionlut(index(p),:);
        end
    end
    
    rgbimg = reshape(rgbimg,nx,ny,3);
    image(rgbimg);
    set(gca,'YDir','normal')
    axis off
    axis image
end

drawnow
return
