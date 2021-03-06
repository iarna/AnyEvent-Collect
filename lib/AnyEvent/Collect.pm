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

=helper sub event( CodeRef $todo )

See L<Event::Wrappable> for details.

=cut

=helper sub collect( CodeRef $todo )

=helper sub collect_all( CodeRef $todo )

Will return after all of the events declared inside the collect block have
been emitted at least once.

=cut

sub collect_all(&) {
    my( $todo ) = @_;
    my $cv = AE::cv;
    Event::Wrappable->wrap_events( $todo, sub {
        my( $listener ) = @_;
        $cv->begin;
        my $ended = 0;
        return sub { $listener->(@_); $cv->end unless $ended++ };
    } );
    $cv->recv;
}
*collect = *collect_all;

=helper sub collect_any( CodeRef $todo )

Will return after any of the events declared inside the collect block have
been emitted at least once.  Note that it doesn't actually cancel the
unemitted events-- you'll have to do that yourself, if that's what you want.

=cut
sub collect_any(&) {
    my( $todo ) = @_;
    my $cv = AE::cv;
    Event::Wrappable->wrap_events( $todo, sub {
        my( $listener ) = @_;
        return sub { $listener->(@_); $cv->send };
    } );
    $cv->recv;
}

1;
=head1 SYNOPSIS

    use AnyEvent;
    use AnyEvent::Collect;

    # Wait for all of a collection of events to trigger once:
    my( $w1, $w2 );
    collect {
        $w1 = AE::timer 2, 0, event { say "two" };
        $w2 = AE::timer 3, 0, event { say "three" };
    }; # Returns after 3 seconds having printed "two" and "three"

    # Wait for any of a collection of events to trigger:
    my( $w3, $w4 );
    collect_any {
        $w3 = AE::timer 2, 0, event { say "two" };
        $w4 = AE::timer 3, 0, event { say "three" };
    };
    # Returns after 2 seconds, having printed 2.  Note however that
    # the other event will still be emitted in another second.  If
    # you were to then execute the sleep below, it would print three.


    # Or using L<ONE>
    use ONE::Timer;
    use AnyEvent::Collect;
    collect {
        ONE::Timer->after( 2 => event { say "two" } );
        ONE::Timer->after( 3 => event { say "three" } );
    }; # As above, returns after three seconds having printed "two" and
       # "three"

    # And because L<ONE> is based on L<MooseX::Event> and L<MooseX::Event>
    # is integrated with L<Event::Wrappable>, you can just pass in raw subs
    # rather then using the event helper:

    collect_any {
        ONE::Timer->after( 2 => sub { say "two" } );
        ONE::Timer->after( 3 => sub { say "three" } );
    }; # Returns after 2 seconds having printed "two"


=for test_synopsis
use 5.10.0;

=head1 DESCRIPTION

This allows you to reduce a group of unrelated events into a single event.
Either when the first event is emitted, or after all events have been
emitted at least once.

For your convenience this re-exports the event helper from
L<Event::Wrappable>.  Only event listeners created with it or via a class
that integrates with Event::Wrappable (eg, L<MooseX::Event>) will be
captured.

=head1 SEE ALSO

Event::Wrappable
