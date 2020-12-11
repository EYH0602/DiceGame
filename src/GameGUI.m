classdef GameGUI < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                        matlab.ui.Figure
        ROLLButton                      matlab.ui.control.Button
        Player1ScoreEditFieldLabel      matlab.ui.control.Label
        Player1ScoreEditField           matlab.ui.control.NumericEditField
        Play1PreviousRollsListBoxLabel  matlab.ui.control.Label
        Play1PreviousRollsListBox       matlab.ui.control.ListBox
        THISROLLEditFieldLabel          matlab.ui.control.Label
        THISROLLEditField               matlab.ui.control.EditField
        HTML                            matlab.ui.control.HTML
        Player2ScoreEditFieldLabel      matlab.ui.control.Label
        Player2ScoreEditField           matlab.ui.control.NumericEditField
        YourPlayerIDisButtonGroup       matlab.ui.container.ButtonGroup
        Player1Button                   matlab.ui.control.ToggleButton
        Player2Button                   matlab.ui.control.ToggleButton
    end

    
    properties (Access = private)
        game = DiceGame(1); % game object
        diceRecord = [];    % keep record of all numbers rolled to get points for each round
    end
    
    methods (Access = private)
        
        function displayDice(app, points)
            str = app.game.getDiceStr();
            app.THISROLLEditField.Value = str + "    ==>    " + string(points);
            app.pushToQueue(str);
        end
        
        function pushToQueue(app, str)
            app.Play1PreviousRollsListBox.Items{end+1} = char(str);
        end
        
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function init(app)
            app.Play1PreviousRollsListBox.Items = {};
            app.Player1ScoreEditField.Value = 0;
            
            % set play 2's ID to 2 is Player Button is selected
            if app.Player2Button.Value == true
                app.game = app.game.setID(2);
            end
        end

        % Button pushed function: ROLLButton
        function ROLLButtonPushed(app, event)
            
            
            
            % roll all the dice
            [xr,fs]=audioread('./music/ShakeAndRollDice.mp3'); % init sound
            sound(xr,fs);
            app.game = app.game.rollAllDice();
            
            % add a random number to an random index
            i = randi([1,5],1,1);
            num = randi([-10,10],1,1);
            app.game = app.game.setDieFront(i, num + app.game.getDice(i).getFront());  
            % push back the newly rolled 5 dice to the record
            app.diceRecord = [app.diceRecord app.game.getDiceFronts()];
            % calculate the points get from current record
            points = lengthOfLIS(app.diceRecord);
            % show the result in GUI
            app.displayDice(points);
            % sp=actxserver('SAPI.SpVoice');  
            
            app.game.updateRound(points);   % send the points of this round to server
            app.game.updateStatus(1);
            app.game.waitForOtherPlayer();
            app.game.updateStatus(0);
            
            % calculate the global score
            otherPlayerPoint = app.game.getOtherPlayerRoundPoint();
            if (points > otherPlayerPoint)
                app.Player1ScoreEditField.Value = app.Player1ScoreEditField.Value + points;
            end
            app.Player2ScoreEditField.Value = app.game.getOtherPlayerScore();   % read other player's score from server
            
            
            
            
            % ================================================= enter subgame =================================================================
            winSubgame = false;
            enteredSubgame = false;
            if app.Player1ScoreEditField.Value ~= 0 && mod(app.Player1ScoreEditField.Value,10) == 0   % if get multiple of 10, enter the subgame
                enteredSubgame = true;
                subgame = Minesweeper();
                [xr1,fs1]=audioread('./music/openSubgame.m4a');
                sound(xr1,fs1);
                while ~subgame.isGameOver % wait until the subgame is finished
                    % display Minesweeper GUI
                    drawnow;
                end
                winSubgame = subgame.isSolved;
            end
            % calculate result after subgame: win +14, lost -33
            if enteredSubgame
                if winSubgame
                    app.Player1ScoreEditField.Value = app.Player1ScoreEditField.Value + 14;
                    [xr2,fs2]=audioread('./music/successSubgame.m4a');
                    sound(xr2,fs2);
                    % sp.Speak('Nice，You did a great job');
                else
                    app.Player1ScoreEditField.Value = app.Player1ScoreEditField.Value - 33;
                    [xr3,fs3]=audioread('./music/failSubgame.m4a');
                    sound(xr3,fs3);
                    % sp.Speak('Don''t lose heart, keep up the good work');
                end
            end
            
            if (app.Player1ScoreEditField.Value >=100||app.Player2ScoreEditField.Value >=100)
                load handel;
                sound(y,Fs);
            end
            
            % update scores to the server
            app.game.updateGlobalScore(app.Player1ScoreEditField.Value);
            
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 584 571];
            app.UIFigure.Name = 'MATLAB App';

            % Create ROLLButton
            app.ROLLButton = uibutton(app.UIFigure, 'push');
            app.ROLLButton.ButtonPushedFcn = createCallbackFcn(app, @ROLLButtonPushed, true);
            app.ROLLButton.Position = [267 85 217 81];
            app.ROLLButton.Text = 'ROLL!';

            % Create Player1ScoreEditFieldLabel
            app.Player1ScoreEditFieldLabel = uilabel(app.UIFigure);
            app.Player1ScoreEditFieldLabel.HorizontalAlignment = 'right';
            app.Player1ScoreEditFieldLabel.Position = [255 376 88 22];
            app.Player1ScoreEditFieldLabel.Text = 'Player 1 Score:';

            % Create Player1ScoreEditField
            app.Player1ScoreEditField = uieditfield(app.UIFigure, 'numeric');
            app.Player1ScoreEditField.Position = [249 355 100 22];

            % Create Play1PreviousRollsListBoxLabel
            app.Play1PreviousRollsListBoxLabel = uilabel(app.UIFigure);
            app.Play1PreviousRollsListBoxLabel.HorizontalAlignment = 'right';
            app.Play1PreviousRollsListBoxLabel.Position = [32 446 119 22];
            app.Play1PreviousRollsListBoxLabel.Text = 'Play 1 Previous Rolls';

            % Create Play1PreviousRollsListBox
            app.Play1PreviousRollsListBox = uilistbox(app.UIFigure);
            app.Play1PreviousRollsListBox.Position = [19 19 171 424];

            % Create THISROLLEditFieldLabel
            app.THISROLLEditFieldLabel = uilabel(app.UIFigure);
            app.THISROLLEditFieldLabel.HorizontalAlignment = 'right';
            app.THISROLLEditFieldLabel.Position = [340 278 71 22];
            app.THISROLLEditFieldLabel.Text = 'THIS ROLL!';

            % Create THISROLLEditField
            app.THISROLLEditField = uieditfield(app.UIFigure, 'text');
            app.THISROLLEditField.Position = [228 201 295 78];

            % Create HTML
            app.HTML = uihtml(app.UIFigure);
            app.HTML.HTMLSource = '<center><h1> Load On Dice Game</h1></center>';
            app.HTML.Position = [61 449 475 66];

            % Create Player2ScoreEditFieldLabel
            app.Player2ScoreEditFieldLabel = uilabel(app.UIFigure);
            app.Player2ScoreEditFieldLabel.HorizontalAlignment = 'right';
            app.Player2ScoreEditFieldLabel.Position = [416 376 88 22];
            app.Player2ScoreEditFieldLabel.Text = 'Player 2 Score:';

            % Create Player2ScoreEditField
            app.Player2ScoreEditField = uieditfield(app.UIFigure, 'numeric');
            app.Player2ScoreEditField.Position = [410 355 100 22];

            % Create YourPlayerIDisButtonGroup
            app.YourPlayerIDisButtonGroup = uibuttongroup(app.UIFigure);
            app.YourPlayerIDisButtonGroup.Title = 'Your Player ID is:';
            app.YourPlayerIDisButtonGroup.Position = [285 394 196 54];

            % Create Player1Button
            app.Player1Button = uitogglebutton(app.YourPlayerIDisButtonGroup);
            app.Player1Button.Text = 'Player 1';
            app.Player1Button.Position = [1 3 100 22];
            app.Player1Button.Value = true;

            % Create Player2Button
            app.Player2Button = uitogglebutton(app.YourPlayerIDisButtonGroup);
            app.Player2Button.Text = 'Player 2';
            app.Player2Button.Position = [96 3 100 22];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = GameGUI

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @init)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end