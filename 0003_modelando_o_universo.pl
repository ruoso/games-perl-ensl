#!/usr/bin/perl
use strict;
use warnings;
use 5.10.0;
use SDL;
use SDL::Video;
use SDLx::Surface;
use SDL::Event;
use SDL::Events;

use threads;
use threads::shared;

# Inicializa uma tela de 640x480 usando memória da placa de vídeo
# com double-buffering (normalmente o mais rápido para 2D).
my $tela = SDLx::Surface::display( 
    width => 640,
    height => 480,
    flags => SDL_HWSURFACE | SDL_DOUBLEBUF,
);

# Modelagem dos dados.
#  Bola: Hash compartilhado entre as threads
#        com chaves x e y marcando o centro.
#        Para fins de simplificação, vamos assumir
#        raio constante.
use constant RAIO => 10;
my %bola :shared;
# inicializo os valores.
$bola{x} = 100;
$bola{y} = 100;

# Por questões de performance, a SDL reutiliza o objeto de evento.
# Vamos fazer um loop que espera uma flag para sair, e processa cada evento
my $e = SDL::Event->new();
my $continue = 1;
while ($continue) {

    # esse método vai bloquear enquanto não chegar um evento novo.
    SDL::Events::wait_event($e);

    # dado o tipo de evento...
    given ($e->type) {
        when (SDL_QUIT) {
            $continue = 0;
        }
        when (SDL_KEYDOWN) {
            given ($e->key_sym) {
                when (SDLK_ESCAPE) {
                    $continue = 0;
                }
            }
        }
    }
}


