# Final Project Proposal

## General Description

This project will be stored and maintained in a GitHub private repository for now. We might make the repository public and open-source under MIT License (or other) depending on condition and contributors' agreement. Vision control will be done with git and managed by Ethan. There will be a general interface, or a middle layer, between the back-end classes and the GUI so that the same GUI program will run with different dice game (reach component) only depending on parameter passing and function calling. Settings and history (reach component) will be in JSON format, and data will be stored as CSV files.

### Members

* **Team Name**: Dice Game Group 6
* **Ethan He**: back-end developer who designs interface and abstraction. Also responsible for  functions under all the general abstract classes and data storage management.
* **Jingqiu Huang**
* **Xuan Huang**
* Yangqing Zhang (not responding)

## Project Description

We aim to design a highly diverse game for two players synchronously. This game is a competition intended. Two players will play in a dice game based on the given rule. This dice game of choice will be the main game for players to get their points. For each round, the winner will gain points whereas the loser will lose points. The game ends when one of the users reaches the maximum. When the player's point accumulated to a "peak" point, both players will enter the "subgame" mode. A subgame will be a single-player game that is short but interesting, for example, Minesweeper. If the player passes his subgame, he will gain points. If they lose, their points might be taken off.

This general game flow will be as following

![General Game Flowchart](./pics/doc/dice_game-general.png)

### Reach \& Special Features

* 2-3 simple dice game for users to choose.
* 3 subgames with variable difficulty level.
* Gaming history for users to check.
* If playing with the same people again, the players can choose to continue where they left off (if the game is not finished last time and is saved).

### Time Line








