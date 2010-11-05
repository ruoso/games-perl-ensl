#!/usr/bin/perl
use strict;
use warnings;
use 5.10.0;
use SDL;
use SDL::Time;
use SDL::Video;
use SDLx::Surface;
use SDL::Event;
use SDL::Events;
use threads;
use threads::shared;
use constant RAIO => 10;
use constant VELOCIDADE => 0.1;
use constant PI => 3.14159;

# as variáveis globais do ambiente.
my $tela;
my $continue :shared = 1;
my @threads;
# Modelagem dos dados.
#  Bola: Hash compartilhado entre as threads
#        com chaves x e y marcando o centro.
#        Para fins de simplificação, vamos assumir
#        diametro constante.
my %bola :shared;
# o estado das teclas;
my %keystate :shared;

inicializa_tela();
inicializa_dados();
laco_de_interacao();
laco_de_renderizacao();
laco_de_eventos();

# espera as outras threads terminarem...
$_->join for @threads;
# sair...
exit;

sub inicializa_tela {
    # Inicializa uma tela de 640x480 usando memória da placa de vídeo
    # com double-buffering (normalmente o mais rápido para 2D).
    $tela = SDLx::Surface::display( 
        width => 640,
        height => 480,
        flags => SDL_HWSURFACE | SDL_DOUBLEBUF,
    );
}


sub inicializa_dados {
    # inicializo os valores.
    $bola{x} = 100;
    $bola{y} = 100;
}

sub laco_de_renderizacao {
    # o laco de renderizacao acontece em uma outra thread...
    push @threads, async {
        # esse rect será reutilizado muitas vezes...
        my $telatoda = SDL::Rect->new(0,0,640,480);
        while ($continue) {
            # pinta a tela toda de preto
            # (esse não é o jeito certo, mas é o mais simples)
            $tela->draw_rect($telatoda, 0);

            $tela->draw_circle_filled([ $bola{x}, $bola{y} ],
                                      RAIO,
                                      [ 0xFF, 0, 0, 0xFF ]);

            # diz para a placa de video que terminamos com esse frame.
            $tela->flip;

            # nao vamos fazer mais do que 100 FPS
            SDL::delay(10);
        }
    };
}

sub laco_de_interacao {
    # o laco de interacao tambem acontece em outra thread...
    push @threads, async {
        while ($continue) {
            state $last_ticks = SDL::get_ticks;
            my $this_ticks = SDL::get_ticks;
            my $elapsed = $this_ticks - $last_ticks;
            my $movement = $elapsed * VELOCIDADE;

            my $direction;
            if ($keystate{up}) {
                if ($keystate{right}) {
                    $direction = PI / 4;      # up + right
                } elsif ($keystate{left}) {
                    $direction = 3 * PI / 4;  # up + left
                } else {
                    $direction = PI / 2;      # up
                }
            } elsif ($keystate{down}) {
                if ($keystate{right}) {
                    $direction = 7 * PI / 4;  # down + right
                } elsif ($keystate{left}) {
                    $direction = 5 * PI / 4;  # down + left
                } else {
                    $direction = 3 * PI / 2;  # down
                }
            } else {
                if ($keystate{right}) {
                    $direction = 0;           # right
                } elsif ($keystate{left}) {
                    $direction = PI;          # left
                } else {
                    $direction = $movement = 0;
                }
            }

            my $change_x = $movement * cos($direction);
            my $change_y = $movement * sin($direction) * (0-1); # coordenada y é invertida

            $bola{x} += $change_x;
            $bola{y} += $change_y;

            $last_ticks = SDL::get_ticks;
            # nao vamos fazer mais do que 100 calculos por segundo
            SDL::delay(10);
        }
    };
}

sub laco_de_eventos {
    # Por questões de performance, a SDL reutiliza o objeto de evento.
    # Vamos fazer um loop que espera uma flag para sair, e processa cada evento
    my $e = SDL::Event->new();
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
                    when (SDLK_LEFT)  { $keystate{left} = 1 };
                    when (SDLK_RIGHT) { $keystate{right} = 1 };
                    when (SDLK_UP)    { $keystate{up} = 1 };
                    when (SDLK_DOWN)  { $keystate{down} = 1 };
                }
            }
            when (SDL_KEYUP) {
                given ($e->key_sym) {
                    when (SDLK_LEFT)  { $keystate{left} = 0 };
                    when (SDLK_RIGHT) { $keystate{right} = 0 };
                    when (SDLK_UP)    { $keystate{up} = 0 };
                    when (SDLK_DOWN)  { $keystate{down} = 0 };
                }
            }
        }
    }
}
