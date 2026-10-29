The ultimate goal of this project is to be able to write simple C and assembly programs
for the Mycro-1 computer. 

It started out as an experiment with ChatGPT, and the current state is clearly work in 
progress. I'm sharing it in the current state in case bits and pieces from it 
could be useful for somebody else. 

There are a few different things here: 
- experiments writing pure assembly programs
- examples of calling mycrop functions
- experiments with different levels of support necessary for writing C programs. 
- cross-compiler/target setup for z88dk to provide the necessary bits for 
  compiling C programs with the Mycron computer as a target (crt0, minimal stdlib etc)


The z88dk-local directory contains the cross compiler/target setup and code. 

