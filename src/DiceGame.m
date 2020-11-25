classdef DiceGame

    % =============================================
    %       Interaction Keys to ThingSpeak
    % =============================================
    properties (Constant)
        WRITE_KEY = 'BJ0V9DMXEXXEH6QT';
        READ_KEY = '0KXU1T6U20YA4DYJ';
        CHANNEL_ID = 1236394;
    end

    properties (Access = private)
        ID;     % id of this client, 1 or 2
        score;  % score of this client
        pointThisRound;  % boolean, currently believe or not
        name;   % user name of this client
        status; % char array of json, game status, sync from server
        dice;   % vector of 5 Dice objects
    end

    methods (Access = public)
        % =============================================
        %       Interaction to Object Fields
        % =============================================
        function obj = DiceGame(ID, name)
            obj.ID = ID;
            obj.score = 0;
            obj.name = "Anonymous Player";
            obj.dice = [
                    Dice()
                    Dice()
                    Dice()
                    Dice()
                    Dice()
                    ];
            obj.status = char(thingSpeakRead(obj.CHANNEL_ID, 'ReadKey', obj.READ_KEY, 'OutputFormat', 'timetable').desp);
            if nargin == 2
                obj.name = name;
            end
        end

        function isMyRound = isMyRound(obj)
            readStatus = thingSpeakRead(obj.CHANNEL_ID, 'Fields', 1, 'ReadKey', obj.READ_KEY);
            isMyRound = (readStatus == obj.ID);
        end
        
        function ID = getID(obj)
            ID = obj.ID;
        end

        function name = getName(obj)
            name = obj.name;
        end

        function score = getScore(obj)
            score = obj.score;
        end

        function prompt = getPrompt(obj)
            prompt = obj.name ...
                + " #" + string(obj.ID) ...
                + " (" + string(obj.score) + ")" ...
                + " $ ";
        end

        function obj = addScore(obj, num)
            obj.score = obj.score + num;
        end

        function obj = getResults(obj)
            disp("====");
            disp(obj.status)
            disp("====");
            s = jsondecode(obj.status);
            switch obj.ID
            case 1
                opponentDice = s.client2.dice;
            case 2
                opponentDice = s.client1.dice;
            end
            myPoint = getListPoint(obj.dice);
            opponentPoint = getListPoint(opponentDice);

            % display the points and dice
            disp("My dice, point = " + string(myPoint));
            disp(obj.dice);
            disp("Opponent's Dice, point = " + string(opponentPoint));
            disp(opponentDice);

            if myPoint >= opponentPoint
                obj.score = obj.score + myPoint;
            end
        end

        % =============================================
        %       Dice Functions
        % =============================================
        function dice = getDice(obj, index)

            switch nargin
                case 1
                    dice = obj.dice.getFront();
                case 2
                    dice = obj.dice(index);
            end

        end

        function diceFronts = getDiceFronts(obj, index)

            switch nargin
                case 1
                    diceFronts = zeros(1, 5); %   as defined, there are only 5 dices

                    for i = 1:5
                        diceFronts(i) = obj.dice(i).getFront();
                    end

                case 2
                    diceFronts = obj.dice(index).getFront();
            end

        end

        function obj = rollAllDice(obj, rollTimes)

            switch nargin
                case 1
                    t = 1;
                case 2
                    t = rollTimes;
            end

            % roll all the dice!
            for i = 1:t

                for j = 1:5
                    obj.dice(i) = obj.dice(i).roll();
                end

            end

        end

        % =============================================
        %       JSON factions
        % =============================================
        function json_txt = dumpJ(obj)
            s = struct("ID", obj.ID, "score", obj.score, "name", obj.name, "dice", obj.dice);
            json_txt = jsonencode(s);
        end

        % =============================================
        %       Server factions
        % =============================================
        function obj = syncUp(obj)
            % disp("====");
            disp(obj.status)
            % disp("====");
            % return;
            gameStatus = jsondecode(obj.status)
            % theOtherPlayID = 0;


            switch obj.ID
                case 1
                    if isempty(gameStatus.client1.name)
                        gameStatus.client1.name = obj.name;
                    end
                    gameStatus.client1.score = obj.score;
                    gameStatus.client1.dice = obj.dice;
                    theOtherPlayID = 2;
                case 2
                    if isempty(gameStatus.client2.name)
                        gameStatus.client2.name = obj.name;
                    end
                    gameStatus.client2.score = obj.score;
                    gameStatus.client2.dice = obj.dice;
                    theOtherPlayID = 1;
            end

            % disp(gameStatus.client1.dice(1).getFront());
            obj.status = jsonencode(gameStatus);
            % disp("***");
            % disp(obj.status);
            thingSpeakWrite(obj.CHANNEL_ID, {theOtherPlayID, obj.status}, 'WriteKey', obj.WRITE_KEY);
            % disp("***");
            pause(15);
        end

        function obj = syncDown(obj)
            readStatus = thingSpeakRead(obj.CHANNEL_ID,'ReadKey', obj.READ_KEY, 'OutputFormat', 'timetable');
            obj.status = char(readStatus.desp)
        end

    end

end
