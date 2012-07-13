# ABSTRACT: Block till one or more events fire
package AnyEvent::Collect;
use strict;
use warnings;
use AnyEvent;
use Event::Wrappable;
use Sub::Exporter -setup => {
    exports => [qw( collect collect_all collect_any event )],
    groups => { default => [qw( collect collect_all collect_any event )] },
    };

use constant COLLECT_TYPE => 0;
use constant COLLECT_CV   => 1;

my @cvs;

sub collect_all(&) {
    my( $todo ) = @_;
    unshift @cvs, [all=>AE::cv];
    Event::Wrappable->add_event_wrapper( \&__collect_event );
    $todo->();
    Event::Wrappable->remove_event_wrapper( \&__collect_event );
    my $cv = shift @cvs;
    $cv->[COLLECT_CV]->recv;
}
*collect = *collect_all;

sub collect_any(&) {
    my( $todo ) = @_;
    unshift @cvs, [any=>AE::cv];
    Event::Wrappable->add_event_wrapper( \&__collect_event );
    $todo->();
    Event::Wrappable->remove_event_wrapper( \&__collect_event );
    my $cv = shift @cvs;
    $cv->[COLLECT_CV]->recv;
}

sub __collect_event(&) {
    my $todo = shift;
    my $cv = $cvs[0];
    if ( $cv->[COLLECT_TYPE] eq 'all' ) {
        $cv->[COLLECT_CV]->begin;
        my $ended;
        return sub { $todo->(); unless ($ended++) { $cv->[COLLECT_CV]->end } };
    }
    else {
        return sub { $todo->(); $cv->[COLLECT_CV]->send };
    }
}

1;
