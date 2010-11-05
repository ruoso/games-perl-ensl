#!/usr/bin/perl
use strict;
use warnings;
use SDL;
use SDL::Video;
use SDLx::Surface;

# Inicializa uma tela de 640x480 usando memória da placa de vídeo
# com double-buffering (normalmente o mais rápido para 2D).
my $tela = SDLx::Surface::display( 
    width => 640,
    height => 480,
    flags => SDL_HWSURFACE | SDL_DOUBLEBUF,
);

# espera 10 segundos
sleep 10;
