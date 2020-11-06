# Dice Game API

* [Player](# Player)
* [Dice](# Dice)
* [Dice Game](# DiceGame)
* [Subgame](# Subgame)



# Player

## Properties

|property|type|usage|
|:--|:--|:--|
|ID|Integer|1or 2, telling which play this is|
|score|Integer|0-100, default is 0.|
|name|string|nickname entered by the player|

## Methods

### `Player(ID,name,score)`

Constructor who creates a Player object.

#### Usage

1. `ID` is the only requirement. If the constructor is only called with `ID`, the object will be as following

    ```matlab
    >> p1 = Player(0)
    
    ```

p1 = 
    
      Player with properties:
    
           ID: 0
        score: []
         name: "Anonymous Player"
    ```

2. When the game starts with ==no history loaded==, `Player()` should be called with 2 parameters.

   ```matlab
   >> p1 = Player(0, "Player 1")
   
   p1 = 
   
     Player with properties:
   
          ID: 0
       score: []
        name: "Player 1"
   ```

3. If history record is loaded (reach component), call `Player()` with 3 parameters.

   ```matlab
   >> p1 = Player(0,"Player 1",56)
   
   p1 = 
   
     Player with properties:
   
          ID: 0
       score: 56
        name: "Player 1"
   ```

### `integer getID()`

Return the ID of this player.

### `integer getScore()`

Return the score of this player.

### `string getName()`

Return the user name of this player.

### `void addScore(num: int)`

Add `num` to player's `score`.

### `JSON dumpJ()`

Convert the player object to a JSON object with all the current status.



# Dice

## Properties

|property|type|usage|
|:--|:--|:--|
|frontFace|Integer|the points this player gets for this roll|

## Methods

### `void roll()`



# DiceGame



# Subgame



