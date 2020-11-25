
% =================================================
%               Liar's_Dice-CLI
%   Author: Yifeng (Ethan) He
%   Date:   11/20/2020
% =================================================

addpath src
% addpath API

% ==========
%   buffers 
% ==========

disp("Welcome to the command line version of the Liar's Dice!");
pause(0.5);
disp("Now, Let's Roll!");
pause(0.5);

%% ! ------------------------- initialize game ------------------------------
isPlaying = input('Accept our invitation (y/n) $ ', 's') == 'y';
if ~isPlaying
    return;
end
ID = input('Your are player (1/2)? $ ');
name = string(input('How should I call you? $ ', 's'));
game = DiceGame(ID, name);
currentScore = game.getScore();
starting = ID == 1;
%% ! ------------------------------------------------------------------------

%% --------------------- initialize the server ------------------------------

% player 1 is responsible to init the server
if ID == 1
    resp = uploadJSON(fileread('./API/DiceGame.json'));
else
    pause(16);
end
% READ_KEY = '0KXU1T6U20YA4DYJ';
% CHANNEL_ID = 1236394;
% aaa = char(thingSpeakRead(CHANNEL_ID, 'ReadKey', READ_KEY, 'OutputFormat', 'timetable').desp);
% disp(aaa);
% return;
%% --------------------------------------------------------------------------

pause(0.5);
disp("Hello, " + name);
pause(0.5);

while isPlaying
    game = game.rollAllDice();
    disp(game.getDiceFronts());
    serverResponse = game.syncUp();
    game = game.syncDown();
    disp(game.getDiceFronts());
    game = game.getResults();
    prompt = game.getPrompt();
    isPlaying = input(prompt, 's') == 'y';
    game = game.addScore(5);
end
