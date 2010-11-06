#!perl

use strict;
use warnings;

use Config::Pit 'pit_get';
use AnyEvent::Twitter;
use AnyEvent::Twitter::Stream;

binmode STDOUT, ":utf8";

my $track = 'kansai.pm,kansaipm';

my $config = pit_get('twitter.kansai.pm', require => {
    consumer_key    => 'consumer key',
    consumer_secret => 'consumer secret',
    token           => 'token',
    token_secret    => 'token secret',
});

warn "start tracking '$track'\n";

my $cv = AnyEvent->condvar;

my $twitty = AnyEvent::Twitter->new(%$config);
my $streamer = AnyEvent::Twitter::Stream->new(
    %$config,
    method => 'filter',
    track => $track,
    timeout => 45,
    on_tweet => sub {
        my $tweet = shift;
        if( $tweet->{user}{screen_name} ne 'kansaipm'
        and $tweet->{user}{screen_name} ne 'perlism'
        ) {
            warn "$tweet->{user}{screen_name}: $tweet->{text} [$tweet->{id}]\n";
            $twitty->request(
                api    => "statuses/retweet/$tweet->{id}",
                method => 'POST',
                sub {
                },
            );
        }
    },
    on_error => sub {
        my $error = shift;
        warn "ERROR: $error";
        $cv->send;
    },
    on_keepalive => sub {
        #warn "ping\n";
    },
    on_eof   => sub {
        warn "eof\n";
        $cv->send;
    },
);

$cv->recv;

