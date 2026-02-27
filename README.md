# Neurofeedback City Walk Game

A MATLAB-based neurofeedback game where a character walks through a city 
scene only when the participant's brainwave activity falls within the target 
frequency band.

## Target Frequency
Default: Alpha band (8–12 Hz) - Adjustable

## Requirements
- MATLAB
- Signal Processing Toolbox (I use BrainProducts Recorder + RecView). Ensure remote data access is selected
- EEG
- Animation UI, such as BioEra or OpenViBE

## How to Use
1. Open neurofeedback_city_game.m in MATLAB
2. Adjust TARGET_FREQ_LOW and TARGET_FREQ_HIGH to your desired band
3. Set THRESHOLD based on client needs (default 0.5)
4. Connect EEG device and set EEG parameters within code under EEG INPUT SECTION
5. Press Escape to end session

## Notes
Developed for in-office neurofeedback sessions with adult clients.
Not intended for unsupervised use.
