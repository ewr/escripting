This is a little command-line perl app to manage podcasts. Eventually my goal is to have hooks that allow, for instance, the app to automatically send new files to an mp3 player (such as via bluetooth). Currently, though, podcast just manages the files locally. Edit the config file to tell the app which podcasts you want to grab, where the audio files should go, and how many files to keep.

Requires:

* Cache::File
* DateTime
* DateTime::Format::HTTP
* MP3::Mplib
* Storable
* URI::Fetch
* XML::DOM
* XML::Simple

# -- podcast README -- #

Included in this tar file:

* podcast: the app
* config: an example config file
* cache/: an empty cache directory
* audio/: an empty audio directory

Start by opening up podcast and changing $cfg->{config} to have the correct 
path to the config file.

Next, open up the config file and change the paths for <cache> and <local> 
to point to a cache directory and a local audio directory, respectively.  
These could well be the empty directories created by untarring, or they 
could be elsewhere if you feel so-inclined.

Input the information for the feeds you're interested in, following the model 
in the included entries.
