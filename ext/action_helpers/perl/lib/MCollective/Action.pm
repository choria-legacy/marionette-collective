package MCollective::Action;
use strict;
use warnings;
use JSON;

=head1 NAME

MCollective::Action - helper class for writing mcollective actions in perl

=head1 SYNOPSIS


In your mcollective agent

    action "echo" do
        validate :message, String

        implemented by "/tmp/echo.perl"
    end

And C</tmp/echo.perl>

    #!/usr/bin/env perl
    use strict;
    use MCollective::Action;

    my $mc = MCollective::Action->new;
    $mc->reply->{message}   = $mc->request->{message};
    $mc->reply->{timestamp} = time;
    $mc->info("some text to log on the server");


=head1 DESCRIPTION

mcollective version 1.X introduced a mechanism for writing agent actions as
external commands. This module provides a convenient api for writing them in
perl which performs some of the boilerplate for you.

=head2 METHODS

=over

=item new

create a new MCollection::Action helper object

=cut

sub new {
    my $class = shift;
    my $self = bless {
        request  => {},
        reply    => {},
    }, $class;
    $self->_load;
    return $self;
}

=item request

returns a hash reference containing the request

=cut


sub request { $_[0]->{request} }


=item reply

returns a hash reference you should populate with your reply

=cut

sub reply { $_[0]->{reply} }


sub _load {
    my $self = shift;
    my $file = $ENV{MCOLLECTIVE_REQUEST_FILE};
    open my $fh, "<$file"
      or die "Can't open '$file': $!";
    my $json = do { local $/; <$fh> };
    $self->{request} = JSON->new->decode( $json );
    delete $self->request->{data}{process_results};
}

sub DESTROY {
    my $self = shift;
    $self->_save;
}

sub _save {
    my $self = shift;
    my $file = $ENV{MCOLLECTIVE_REPLY_FILE};
    open my $fh, ">$file"
      or die "Can't open '$file': $!";
    print $fh JSON->new->encode( $self->reply );
}

=item info($message)

report a message into the server log

=cut

sub info {
    my ($self, $message) = @_;
    print STDOUT $message, "\n";
}

=item error($message)

report an error into the server log

=cut


sub error {
    my ($self, $message) = @_;
    print STDERR $message, "\n";
}

=item fail

reports an error and exits immediately

=cut

sub fail {
    my ($self, $message) = @_;
    $self->error( $message );
    exit 1;
}

1;

__END__

=back

=head1 AUTHOR

Richard Clamp <richardc@unixbeard.net>

=head1 COPYRIGHT

Copyright 2011, Richard Clamp.  All Rights Reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

http://docs.puppetlabs.com/mcollective/

=cut

