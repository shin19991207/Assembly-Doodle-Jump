# Assembly-DoodleJump
A Doodle Jump like game made in Mips assembly code using the Mars Mips simulator.

# Install MARS
If you haven’t downloaded it already, get MARS v4.5  http://courses.missouristate.edu/kenvollmar/mars/download.htm.

# How to Get Started
This program requires the Keyboard and Display MMIO and the Bitmap Display to be connected to MIPS.

## Set Up Bitmap Display
1. Tools > Bitmap display

2. Bitmap Display Settings:

- Unit Width: 8

- Unit Height: 8

- Display Width: 256

- Display Height: 256

- Base Address for Display: 0x10008000 ($gp)

3. Click “Connect to MIPS” once these are set. 

## Set Up Keyboard and Display MMIO

- Tools > Keyboard and Display MMIO Simulator > Click “Connect to MIPS” 

## Build and Run
- Open the file doodlejump.s > Assemble > Run

- Input the character j (go the the left) or k (go to the right) or s (start/restart) in Keyboard area in Keyboard and Display MMIO Simulator window

# Clone this Repository
`git clone https://github.com/shin19991207/Assembly-DoodleJump.git`

# Insight

