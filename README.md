# Jumpers
Jumpers was made as a project for an undergratuate introduction to AI class. It uses hill climbing to find the best angle and force with which to throw a round object to knock down a tower. It definitely does not resemble any company's copywritten intellectual property.


## Introduction
For this project I implemented a simplified simulation based on a popular computer and cell phone game.  The objective of this game is simple: pigs have stolen a group of birds’ eggs, and it is the job of the player to throw birds at the pigs’ fortifications until they topple to the ground and the pigs are all dead (or perhaps sleeping, as this is a children’s game).

I have reduced this game down to its core element, which is a physics-based simulation in which balls are thrown at structures to topple them to the ground. In the game itself, things get quite a bit more complicated. The objects forming the fortifications are made of different materials (wood, ice, and stone, for example), some of which are destructible (meaning that, if struck hard enough, they will disappear instantly).  The pigs are destructible as well, and destroying the pigs is the main way of winning a level. For the purposes of this project, all materials are wooden (or porcine), and none are destructible.

## Playing the Game
At the heart of the game is the mechanic of pulling back a slingshot to a particular position. This allows the player to specify a particular angle (between the bird and the top of the slingshot) and force (proportional to the distance drawn back on the slingshot itself) to attack the pigs’ structures. The basic scenario of each level is that the user tries to find the right force and angle with which to destroy the structure and get all the pigs to proceed to the next level.

## Using Artificial Intelligence
Because of the nature of the input, either hill-climbing or local beam search seemed like the ideal way to solve the problem using artificial intelligence.  Because of the specific library I used for the physical simulations, I chose to go with hill-climbing to find local maxima because performing multiple simultaneous simulations would be too processor intensive.
 
The basic implementation is as follows:
1.  Create the world: a tower built out of wooden boards with a pig on the top level.
2.  Generate the initial state: randomly choose a value for the angle and the force at which the bird will be thrown.
3.  Simulate that state: this requires letting the world’s physics turn on, applying the impulse that “throws” the bird, and seeing what happens.
4.  Record the results: after a sufficient amount of time, record the average height of the objects in the world. This will give us a rough measure of how much damage was done.
5.  Generate successor states: Each state has four successors: one with a lower and one with a higher trajectory, and one with a weaker and one with a stronger throwing force.
6.  Simulate those states and choose the best one.
7.  Repeat this process until a local maximum has been found.
 
## The Task Environment
More technically, the agent is specified using PEAS as follows:

### Performance Measure
The agent’s performance measure is the average height in meters of the non-bird bodies (i.e. the wood and the pig) in the simulation after seven seconds of in-world time have passed (in-world meaning that this could be shorter or longer, measured in real-world time, depending on the performance of the system). A lower number is more desirable.

### Environment
The environment consists of the wood building the tower, the pig in the tower, and the world boundaries (the top, left, and bottom edges of the screen, with the right side of the world being off screen to the right). The environment is partially observable—all the agent knows is the average height of the bodies in the environment.  It is single agent, deterministic, and episodic (although, one could add the ability to throw multiple birds in a row without resetting the simulation, making it sequential). It is static, and it is continuous to the degree that 32 bit floating point arithmetic allows.

### Actuators
The agent can specify two sets of actions. It can increase or decrease its trajectory by 0.01 radians and it can increase or decrease the force with which it is thrown by 2 units.

### Sensors
After 7 seconds of in-world time have passed, the agent can measure the average height of the bodies in the system.
 
## Using the System
I developed the implementation as an OS X application using the Box2D physics library (the same library the game that inspired this project uses). The simplest way of running a simulation is simply to open the included XCode project file and run the program. Once the program is running, pressing the space bar begins the simulation.  Specific details about each state tested are written to the console, and the results of the final state are displayed in the program’s window.

## Conclusion
Writing this program was quite interesting.  I was initially drawn to the visual nature of the simulation, but tweaking the little things like finding an appropriate step size for the angle and force, verifying that the program worked with towers of different sizes, and other things of that nature took by far the most time.  Moving forward, I will probably see what benefits I can get from multithreading to implement local beam search (which, as previously mentioned, was simply too computationally intensive for my i5 processor to manage).  Other interesting applications would be identifying weak points in the structure and targeting these specifically—this could even lead to a tool which would help game developers design levels such as these in similar games.  The task domain is pretty interesting, and I look forward to continue working on it.