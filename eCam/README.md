eCam is the second (or is it third? i can't remember) generation of eWorld webcam. Since the eWorld webcam network has grown to three cams, and they're positioned behind a firewall, it's no longer possible for the cameras to be request driven (well... i guess it is *possible*, but not practical). Therefore, the new eCam architecture uploads changed images to a MySQL database every 10 seconds.

Also, since the eWorld cams are running off IRIX (not the world's most friendly OS to get things compiled on), I went ahead and wrote a client-server archtitecture so that only the core image grabbing functions occur on the IRIX machines, and image comparison and db functions occur on my Linux machine.

The server attempts to be bandwidth friendly by using Fred Wheeler's [ICMP utility](https://web.archive.org/web/20000919000113/http://www.cipr.rpi.edu/students/wheeler/icmp/) to determine the mean difference of the new image and the last one uploaded. It only uploads if the mean difference is great enough.

__2000-10-21:__

For people only running one camera, I've combined webcam and client-cam into unicam. It does all that the other does, only without the sockets and multiple hosts.

__2000-07-10:__

I redid the image fetching query in camera.jpg to eliminate it having to go through the entire table just to get one image. It feels infinitely faster now.

__2000-07-09:__

There's a new version of webcam up. This one uses a low priority write lock on the cam table to let reads take priority.

## Requires:

* Perl
* DBI
* MySQL
* djpeg (from libjpeg)

With no further ado, here are the components of the camera architecture:

* cams.dump: db dump of the cams table
* camera.jpg: feeds the images to web clients
* webcam: the server backend (gets images and feeds to db)
* client-cam: the camera client. Written for IRIX, but very easy to port.
* icmp.c: hacked ICMP. Assumes stdin image is ppm.
* unicam: combined webcam and client-cam. capture routine is written for Linux.