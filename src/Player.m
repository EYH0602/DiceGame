classdef Player
    properties (Access = private)
        ID;         % int
        score = 0;  % int
        name = "Anonymous Player";   % string
    end

    methods
        % constructor
        function obj = Player(ID,name,score)
            if nargin == 1
                obj.ID = ID;
            elseif nargin == 2
                obj.ID = ID;
                obj.name = name;
            elseif nargin == 3
                obj.ID = ID;
                obj.name = name;
                obj.score = score;
            else
                error("Invalid Player!");
                error("Usage: Player(ID,name,score)")
                error(" see documentation for more detial!")
            end
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

        function obj = addScore(obj, num)
            obj.score = obj.score + num;
        end

        function json_txt = dumpJ(obj)
            s = struct("name", obj.name, "score", obj.score);
            json_txt = jsonencode(s)
        end


    end

end