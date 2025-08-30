# VGA Pet Rock Game  

## Overview  
The **VGA Pet Rock Game** is an interactive digital system designed to simulate the experience of caring for a virtual pet. Inspired by Tamagotchi, the project uses an FPGA board to drive a VGA display and allows users to interact with a “pet rock” through physical pushbuttons.  

The goal of the project was to create a **responsive, visually clear system** that integrates the key concepts learned throughout the course, including **RTL design, VGA graphics, and hardware implementation**, into one cohesive project.  

---

## Features  
- **Virtual Pet Simulation**: The pet rock moves through emotional and behavioral states such as **Happy, Bored, Mad, Sad, and Dead**.  
- **User Interaction**: Pushbuttons allow the player to:  
  - **Start** a new game  
  - **Pet** the rock  
  - **Feed** the rock  
  - **Revive** the rock after it dies  
  - **Quit** the game  
- **Dual-purpose Control**: A hardware switch functions as both the **video-on toggle** and the **reset signal**.  
- **State Graphics**: Each pet state is represented by a unique graphic displayed on the VGA screen.  
- **Timed Transitions**: The pet’s states evolve over time or in response to player interaction.  
- **Edge Case Handling**:  
  - Reviving the pet after it dies  
  - Blanking the screen when video is turned off  

---

## System Design  
- **Inputs**:  
  - Start, Pet, Feed, Revive, Quit (pushbuttons)  
  - Video-on/Reset (switch)  
- **Outputs**:  
  - VGA display output (state graphics)  
- **Core Components**:  
  - **Behavioral FSM**: Tracks the pet’s state (Happy, Bored, Mad, Sad, Dead).  
  - **Graphics Manager**: Selects and outputs VGA graphics for the current state.  
  - **Timers**: Drive automatic state transitions over time.  
  - **Control Logic**: Handles input events, reset behavior, and revive/quit conditions.  

---

## Technologies Used  
- **Hardware**: FPGA board with pushbuttons, VGA output  
- **Design Methodology**: RTL design, FSM-based control  
- **Graphics**: VGA-based custom pixel graphics  

---

## Future Improvements  
- Add more pet behaviors and states for richer interaction  
- Implement scoring or coin collection system  
- Improve graphics resolution and animation support  


