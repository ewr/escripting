geCam is a Gtk-Perl client for taking pictures and sticking them into a database. It supports now supports an auto-mode, for taking pictures every thirty seconds, as well as captions and super-imposing a timestamp on the image. geCam is merely a camera backend. For a front-end you should adapt camera.jpg from eCam, or write something similar.

Requires:

* Perl
* DBI
* MySQL
* Gtk-Perl
* Imlib2_Perl
* Video::Capture::V4l
* Date::Format
* ObjGTK (provided)

Files:

* geCam: Perl/GTK Client
* ObjGTK.pm: A Gtk-Perl convienence wrapper
* geCam.dump: DB dump for the images table