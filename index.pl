#!/usr/bin/env perl

use strict;
use warnings;

use DBI;
use YAML::XS qw/LoadFile/;

use Mojolicious::Lite;

my $config = LoadFile('config.yaml');
my $db_cfg = $config->{mysql};
my $dbh = DBI->connect("dbi:mysql:$db_cfg->{database}",
    $db_cfg->{username},
    $db_cfg->{password},
    { mysql_auto_reconnect => 1 }
) or die $DBI::errstr;

sub splits {
    return $dbh->selectall_arrayref(q{
        SELECT * FROM split
    }, { Slice => {} });
}

sub standings {
    my $split_id = shift;
    my $splits = splits;
    my $standings;
    
    # Filter by split if provided and valid
    my ($extra_clause, @params) = ('');
    $split_id = 0 unless (defined $split_id and (grep {$_->{id} == $split_id} @$splits));
    if ($split_id != 0) {
        $extra_clause = 'AND split = ?';
        push @params, $split_id;
    }

    $standings = $dbh->selectall_arrayref(qq{
        SELECT s.id, s.name, COUNT(DISTINCT split) splits,
            SUM(IF ((r1.score > r2.score AND summoner1 = s.id) OR (r2.score > r1.score AND summoner2 = s.id), 1, 0)) won,
            SUM(IF  (r1.score = r2.score, 1, 0)) tied,
            SUM(IF ((r1.score > r2.score AND summoner2 = s.id) OR (r2.score > r1.score AND summoner1 = s.id), 1, 0)) lost,
            SUM(IF (summoner1 = s.id, r1.score, r2.score)) pf,
            SUM(IF (summoner1 = s.id, r2.score, r1.score)) pa
        FROM summoner s
            JOIN matchup m on s.id = summoner1 OR s.id = summoner2
            JOIN result r1 using (split, week)
            JOIN result r2 using (split, week)
        WHERE s.id in (summoner1, summoner2)
            AND r1.summoner = m.summoner1
            AND r2.summoner = m.summoner2
            $extra_clause
        GROUP BY s.id
    }, { Slice => {} }, @params);

    for my $summoner (@$standings) {
        # Calculate the points difference per summoner
        $summoner->{pd} = $summoner->{pf} - $summoner->{pa};
        # Get the number of split wins per summoner
        $summoner->{splits} = scalar grep {$_->{winner} == $summoner->{id}} @$splits;
        # Convert strings to numbers for table sorting
        $summoner->{$_} += 0.0 for qw/splits won tied lost pf pa pd/;
    }

    return $standings;
}

# Set up routes
get '/standings/'           => sub { my $c = shift; $c->stash(page => 'standings', split => 0); $c->render(template => 'standings') };
get '/standings/*split'     => sub { my $c = shift; $c->stash(page => 'standings'); $c->render(template => 'standings') };

get '/charts/pf/'           => sub { my $c = shift; $c->stash(page => 'charts/pf', split => 0); $c->render(template => 'chart-pf') };
get '/charts/pf/:split'     => sub { my $c = shift; $c->stash(page => 'charts/pf'); $c->render(template => 'chart-pf') };

get '/charts/pa/'           => sub { my $c = shift; $c->stash(page => 'charts/pa', split => 0); $c->render(template => 'standings') };
get '/charts/pa/:split'     => sub { my $c = shift; $c->stash(page => 'charts/pa'); $c->render(template => 'standings') };

get '/charts/pd/'           => sub { my $c = shift; $c->stash(page => 'charts/pd', split => 0); $c->render(template => 'standings') };
get '/charts/pd/:split'     => sub { my $c = shift; $c->stash(page => 'charts/pd'); $c->render(template => 'standings') };

get '/api/standings'        => sub { my $c = shift; $c->render(json => standings()) };
get '/api/standings/:split' => sub { my $c = shift; $c->render(json => standings($c->param('split'))) };

get '/'                     => sub { my $c = shift; $c->redirect_to('standings') };

app->secrets($config->{secrets});
app->start;

