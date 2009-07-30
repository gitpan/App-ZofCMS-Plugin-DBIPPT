package App::ZofCMS::Plugin::DBIPPT;

use warnings;
use strict;

our $VERSION = '0.0101';
use base 'App::ZofCMS::Plugin::Base';
use HTML::Entities;

sub _key { 'plug_dbippt' }

sub _defaults {
    cell    => 't',
    key     => 'dbi',
    n       => undef,
    t       => 'time',
}

sub _do {
    my ( $self, $conf, $t, $q, $config ) = @_;

    $conf->{key} = $conf->{key}->( $t, $q, $config )
        if ref $conf->{key} eq 'CODE';

    $conf->{n} = $conf->{n}->( $t, $q, $config )
        if ref $conf->{n} eq 'CODE';

    $conf->{t} = $conf->{t}->( $t, $q, $config )
        if ref $conf->{t} eq 'CODE';

    return
        unless defined $conf->{key}
            and ( defined $conf->{n}
                or defined $conf->{t}
            );

    $conf->{key} = [ $conf->{key} ]
        if not ref $conf->{key}
            and defined $conf->{key};

    $conf->{t} = [ $conf->{t} ]
        if not ref $conf->{t}
            and defined $conf->{t};

    $conf->{n} = [ $conf->{n} ]
        if not ref $conf->{n}
            and defined $conf->{n};


    for ( @{ $conf->{key} } ) {
        _process_key( $t, $conf, $_ );
    }

    1;
}

sub _process_key {
    my ( $t, $conf, $key ) = @_;

    my $ref  = $t->{ $conf->{cell} }{ $key };
    return
        unless defined $ref
            and ref $ref eq 'ARRAY'
            and @$ref;

    my $is_hash = ref $ref->[0] eq 'HASH';

    my @t = @{ $conf->{t} };
    my @n = @{ $conf->{n} };

    for ( @$ref ) {
        if ( $is_hash ) {
            for ( @$_{ @n } ) {
                encode_entities $_;
                s/\r?\n/<br>/g;
            }
            for ( @$_{ @t } ) {
                $_ = localtime $_;
            }
        }
        else {
            for ( @$_[ @n ] ) {
                encode_entities $_;
                s/\r?\n/<br>/g;
            }
            for ( @$_[ @t ] ) {
                $_ = localtime $_;
            }
        }
    }
}

1;
__END__

=head1 NAME

App::ZofCMS::Plugin::DBIPPT - simple post-processor for results of DBI plugin queries

=head1 SYNOPSIS

In your ZofCMS Template or Main Config file:

    plugins => [
        { DBI => 2000 },  # use of DBI plugin in this example is optional
        { DBIPPT => 3000 },
    ],

    dbi => {
        # ..connection options are skipped for brevity

        dbi_get => {
            name => 'comments',
            sql  => [
                'SELECT `comment`, `time` FROM `forum_comments`',
                { Slice => {} },
            ],
        },
    },

    plug_dbippt => {
        key => 'comments',
        n   => 'comment',
        # t => 'time' <---- by default, so we don't need to specify it
    }

=head1 DESCRIPTION

The module is a plugin for L<App::ZofCMS> that provides 
means to automatically post-process some most common (at least for me)
post-processing needs when using L<App::ZofCMS::Plugin::DBI>; namely,
converting numerical output of C<time()> with C<localtime()> as well
as changing new lines in regular text data into C<br>s while escaping
HTML Entities.

This documentation assumes you've read L<App::ZofCMS>, 
L<App::ZofCMS::Config> and L<App::ZofCMS::Template>

=head1 DO I HAVE TO USE DBI PLUGIN?

No, you don't have to use L<App::ZofCMS::Plugin::DBI>, 
C<App::ZofCMS::Plugin::DBIPPT> can be run on any piece of data
that fits the description of C<< <tmpl_loop> >>. The reason for the
name and use of L<App::ZofCMS::Plugin::DBI> in my examples here is because
I only required doing such post-processing as this plugin when I used
the DBI plugin.

=head1 WTF IS PPT?

Ok, the name C<DBIPPT> isn't the most clear choice for the name of
the plugin, but when I first wrote out the full name I realized that
the name alone defeats the purpose of the plugin - saving keystrokes -
so I shortened it from C<DBIPostProcessLargeText> to C<DBIPPT> (the C<L>
was lost in "translation" as well). If you're suffering from memory
problems, I guess one way to remember the name is "B<P>lease B<Process>
B<This>".

=head1 FIRST-LEVEL ZofCMS TEMPLATE AND MAIN CONFIG FILE KEYS

=head2 C<plugins>

    plugins => [
        { DBI => 2000 },  # example plugin that generates original data
        { DBIPPT => 3000 }, # higher run level (priority)
    ],

You need to include the plugin in the list of plugins to run. Make
sure to set the priority right so C<DBIPPT> would be run after
any other plugins generate data for processing.

=head2 C<plug_dbippt>

    # run with all the defaults
    plug_dbippt => {},

    # all arguments specified (shown are default values)
    plug_dbippt => {
        cell    => 't',
        key     => 'dbi',
        n       => undef,
        t       => 'time',
    }

B<Mandatory>. Takes a hashref as a value. To run with all the defaults,
use an empty hashref. The keys/values are as follows:

=head3 C<cell>

    plug_dbippt => {
        cell => 't',
    }

B<Optional>. Specifies the first-level ZofCMS Template hashref key
under which to look for data to convert. B<Defaults to:> C<t>

=head3 C<key>

    plug_dbippt => {
        key => 'dbi',
    }

    # or
    plug_dbippt => {
        key => [ qw/dbi dbi2 dbi3 etc/ ],
    }
    
    # or
    plug_dbippt => {
        key => sub {
            my ( $t, $q, $config ) = @_;
            return
                unless $q->{single};

            return $q->{single} == 1
            ? 'dbi' : [ qw/dbi dbi2 dbi3 etc/ ];
        }
    }

B<Optional>. Takes either
a string, subref or an arrayref as a value. If the value is a subref,
that subref will be executed and its return value will be assigned
to C<key> as if it was already there. The C<@_> will contain
(in that order) ZofCMS Template hashref, query parameters hashref and
L<App::ZofCMS::Config> object. Passing (or returning from the sub) 
a string is the same as passing an arrayref with just that string in it.

Each element of the arrayref specifies the second-level key(s) inside 
C<cell> first-level key value of which is an arrayref of either hashrefs
or arrayrefs (i.e. typical output of L<App::ZofCMS::Plugin::DBI>).
B<Defaults to:> C<dbi>

=head3 C<n>

    plug_dbippt => {
        n => 'comments',
    }
    
    # or
    plug_dbippt => {
        n => [ 'comments', 'posts', 'messages' ],
    }

    # or
    plug_dbippt => {
        n => sub {
            my ( $t, $q, $config ) = @_;
            return
                unless $q->{single};

            return $q->{single} == 1
            ? 'comments' : [ qw/comments posts etc/ ];
        }
    }

B<Optional>. Pneumonic: B<n>ew lines. Keys/indexes specified in
C<n> argument will have HTML entities escaped and new lines converted
to C<< <br> >> HTML elements.

Takes either a string, subref or an arrayref as a value. If the value is a subref,
that subref will be executed and its return value will be assigned
to C<n> as if it was already there. The C<@_> will contain
(in that order) ZofCMS Template hashref, query parameters hashref and
L<App::ZofCMS::Config> object. Passing (or returning from the sub) 
a string is the same as passing an arrayref with just that string in it.
If set to C<undef> no processing will be done for new lines.

Each element of the arrayref specifies either the B<keys> of the hashrefs
(for DBI plugin that would be when second element of C<sql> arrayref
is set to C<< { Slice => {} } >>) or B<indexes> of the arrayrefs
(if they are arrayrefs). 
B<Defaults to:> C<undef>

=head3 C<t>

    plug_dbippt => {
        t => undef, # no processing, as the default value is "time"
    }

    # or
    plug_dbippt => {
        t => [ qw/time post_time other_time/ ],
    }

    # or
    plug_dbippt => {
        t => sub {
            my ( $t, $q, $config ) = @_;
            return
                unless $q->{single};

            return $q->{single} == 1
            ? 'time' : [ qw/time post_time other_time/ ];
        }
    }

B<Optional>. Pneumonic: B<t>ime. Keys/indexes specified in
C<t> argument are expected to point to values of C<time()> output
and what will be done is C<scalar localtime($v)> (where C<$v>) is 
the original value) run on them and the return is assigned back to
the original. In other words, they will be converted from C<time> to 
C<localtime>.

Takes either a string, subref or an arrayref as a value. If the value is a subref,
that subref will be executed and its return value will be assigned
to C<t> as if it was already there. The C<@_> will contain
(in that order) ZofCMS Template hashref, query parameters hashref and
L<App::ZofCMS::Config> object. Passing (or returning from the sub) 
a string is the same as passing an arrayref with just that string in it.
If set to C<undef> no processing will be done.

Each element of the arrayref specifies either the B<keys> of the hashrefs
(for DBI plugin that would be when second element of C<sql> arrayref
is set to C<< { Slice => {} } >>) or B<indexes> of the arrayrefs
(if they are arrayrefs).
B<Defaults to:> C<time>

=head1 AUTHOR

'Zoffix, C<< <'zoffix at cpan.org'> >>
(L<http://haslayout.net/>, L<http://zoffix.com/>, L<http://zofdesign.com/>)

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-zofcms-plugin-dbippt at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-ZofCMS-Plugin-DBIPPT>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::ZofCMS::Plugin::DBIPPT

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-ZofCMS-Plugin-DBIPPT>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-ZofCMS-Plugin-DBIPPT>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-ZofCMS-Plugin-DBIPPT>

=item * Search CPAN

L<http://search.cpan.org/dist/App-ZofCMS-Plugin-DBIPPT/>

=back



=head1 COPYRIGHT & LICENSE

Copyright 2009 'Zoffix, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

