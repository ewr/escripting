eMp3 is last year's attempt at an mp3 player. I don't quite know why it never made it here, so I'm posting it now. The architecture is somewhat interesting, but the whole shared memory/signal message passing bit scares me. I remember just how freaky it was trying to write all that. Uggh.

Anyway... I'm planning on re-writing all this to use sockets and communicate via a sane IPC. Once I get the architecture down I really am going to write a Perl/GTK gui.

Requires:

* xaudio
* IPC::Shareable
* DBI
* MPEG::MP3Info

Files:

* server: talks to clients and spawns players.
* client: CLI client
* player: controls rxaudio