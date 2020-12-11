% Jingqiu Huang
% When the whole game ends, a window pops up showing the winning player. It also contains his name and score.

function varout = WinnerScreen(varin)
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @WinnerScreen_OpeningFcn, ...
                   'gui_OutputFcn',  @WinnerScreen_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varin{1})
    gui_State.gui_Callback = str2func(varin{1});
end

if nargout
    [varout{1:nargout}] = gui_mainfcn(gui_State, varin{:});
else
    gui_mainfcn(gui_State, varin{:});
end
function WinnerScreen_OpeningFcn(hObject, eventdata, handles, varin)
% This function has no output args
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data
% varin   command line arguments to WinnerScreen

global winnerPlayer;
global winnerScore;
handles.output = hObject;
guidata(hObject, handles);
set(handles.winnerplayer, 'String', winnerPlayer);
set(handles.chipcount, 'String', winnerScore);

function varout = WinnerScreen_OutputFcn(hObject, eventdata, handles)
varout{1} = handles.output;

function playagain_Callback(hObject, evenrdata, handles)
close(WinnerScreen);
run('openingGUI');

function quit_Callback(hObject, eventdata, handles)
close(WinnerScreen);


        
 
