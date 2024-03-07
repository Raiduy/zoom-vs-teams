# zoom-vs-teams
Experiment regarding the laptop energy consumption in video conferencing tools

## Platform
- OS: Windows 11 Pro (Build 22621.ni release20506-1250)
- Laptop: ThinkPad X1 Carbon 7th
- CPU: Intel Core i7-8665U CPU @ 1.90GHz
- RAM: 16GB DDR3
- Video Conferencing Tools: Zoom, Microsoft Teams

## Dependencies
- [Intel Performance Counter Monitor](https://github.com/intel/pcm)

## Experiment
The experiment is to measure the energy consumption of the laptop running on battery power while using Zoom and Microsoft Teams for video conferencing.
The energy consumption is measured using the Intel Performance Counter Monitor (PCM) tool.

The experiment consists of 10 runs for each video conferencing tool, each run lasting for 10 minutes, with 10 minutes of idle time between each run.

## Experiment Setup
* Bluetooth, and all other background applications are turned off.
* The laptop is running on battery power.
* One participant is present in the video conferencing tool, camera on and unmuted with voices in the background.
* Volume is set to 0
* Brightness is set to minimum
* Battery saver off, and starting with 100% battery.
* Open tabs:
  - Google Chrome (script accesses the Zoom link to open the Zoom app)
  - VS Code
  - PowerShell (with always on top option)
