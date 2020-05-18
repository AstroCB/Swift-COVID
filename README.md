# Swift Playground COVID Tracker
This is a Swift Playground that contains an interactive map showing the progression of active COVID-19 cases relative to state population over the course of several months from the first case in the US.

It was created for Apple's [Swift Student Challenge](https://developer.apple.com/wwdc20/swift-student-challenge/). This challenge requires submissions to run offline, so the data only goes up to the submission deadline, May 17.

## Contents
This repo contains the Playground file, which has all of the required resources to run bundled with it. It also contains several preprocessing scripts used to rearrange the data I've collected for this project into another format that runs more efficiently or conveniently for the purposes used in the Playground, along with the original data sources themselves. If you run these scripts, it will output them directly into the Playground's bundled Resources folder.

## Data sources
- COVID data from: [The COVID Tracking Project](https://covidtracking.com/)
- State border data from: [US Census Bureau](https://catalog.data.gov/dataset/tiger-line-shapefile-2017-nation-u-s-current-state-and-equivalent-national)
- Population data from: [US Census Bureau](http://www.census.gov/programs-surveys/acs/)