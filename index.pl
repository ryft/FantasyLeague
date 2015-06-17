#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dump qw/dump/;
use DBI;
use List::MoreUtils qw/first_index/;
use List::Util qw/sum/;
use Readonly;
use YAML::XS qw/LoadFile/;

use Mojolicious::Lite;

Readonly my $CONFIG => 'config.yaml';
Readonly my $DEFAULT_METRIC => 'won';
Readonly my %METRICS => {
    won     => 'Matches Won',
    tied    => 'Matches Tied',
    lost    => 'Matches Lost',
    pf      => 'Points For',
    pa      => 'Points Against',
    pd      => 'Points Difference',
};

my $config = LoadFile($CONFIG);
my $db_cfg = $config->{mysql};
my $dbh = DBI->connect("dbi:mysql:$db_cfg->{database}",
    $db_cfg->{username},
    $db_cfg->{password},
    { mysql_auto_reconnect => 1 }
) or die $DBI::errstr;

sub metric {
    my $metric = shift;
    return $METRICS{$metric} ? $metric : $DEFAULT_METRIC;
}

sub metric_name { return $METRICS{metric(shift)} }

sub default_params {
    my $metric = shift;
    if (can_normalise($metric)) {
        return (
            aggregation    => 'raw',
            normalise      => 'true',
            moving_average => 1,
        );
    } else {
        return (
            aggregation    => 'cumulative',
            normalise      => 'false',
            moving_average => 1,
        );
    }
}

sub can_normalise { shift =~ /pf|pa|pd/ }

sub get_splits {
    return $dbh->selectall_arrayref(q{
        SELECT * FROM split
    }, { Slice => {} });
}

# Filter by split if provided and valid
# Returns (where clause, params)
sub filter_split_clause {
    my $split = shift;
    my $splits = get_splits;
    my ($sql, @params) = ('1');
    if ($split and (grep {$_->{id} == $split} @$splits)) {
        $sql = 'split = ?';
        push @params, $split;
    }
    return ($sql, @params);
}

sub get_standings {
    my ($split_clause, @params) = filter_split_clause shift;
    return $dbh->selectall_arrayref(qq{
        SELECT s.id, s.name, COUNT(DISTINCT split) splits,
            SUM(IF ((r1.score > r2.score AND summoner1 = s.id) OR (r2.score > r1.score AND summoner2 = s.id), 1, 0)) won,
            SUM(IF  (r1.score = r2.score, 1, 0)) tied,
            SUM(IF ((r1.score > r2.score AND summoner2 = s.id) OR (r2.score > r1.score AND summoner1 = s.id), 1, 0)) lost,
            SUM(IF (summoner1 = s.id, r1.score, r2.score)) pf,
            SUM(IF (summoner1 = s.id, r2.score, r1.score)) pa
        FROM summoner s
            JOIN matchup m ON s.id IN (summoner1, summoner2)
            JOIN result r1 USING (split, week)
            JOIN result r2 USING (split, week)
        WHERE $split_clause
            AND r1.summoner = m.summoner1
            AND r2.summoner = m.summoner2
        GROUP BY s.id
    }, { Slice => {} }, @params);
}

sub standings {
    my $splits    = get_splits;
    my $standings = get_standings shift;

    for my $summoner (@$standings) {
        # Calculate the points difference per summoner
        $summoner->{pd} = $summoner->{pf} - $summoner->{pa};
        # Get the number of split wins per summoner
        $summoner->{splits} = scalar grep {$_->{winner} == $summoner->{id}} @$splits;
        # Convert strings to numbers for table sorting
        $summoner->{$_} += 0.0 for qw/splits won tied lost pf pa pd/;
    }
    return [ sort {
        $b->{splits} <=> $a->{splits}
     || $b->{won}    <=> $a->{won}
     || $b->{tied}   <=> $a->{tied}
     || $b->{pf}     <=> $a->{pf}
     || $b->{pa}     <=> $a->{pa}
    } @$standings ];
}

sub get_results {
    my ($split, $entities) = @_;
    my ($split_clause, @params) = filter_split_clause $split;

    # Filter by matches between given summoners if provided
    $entities ||= '';
    my $placeholders = $entities =~ s/\d+/?/gr;
    my @entity_array = split ',', $entities;
    $split_clause .= qq{
            AND (summoner1 IN ($placeholders) AND summoner2 IN ($placeholders))
    } if (@entity_array);
    push @params, (@entity_array, @entity_array);

    return $dbh->selectall_arrayref(qq{
        SELECT split, week, s1.id entity1, s2.id entity2, s1.name summoner1, s2.name summoner2, t1.name team1, t2.name team2, r1.score points1, r2.score points2
        FROM matchup m
            JOIN summoner s1 ON s1.id = summoner1
            JOIN summoner s2 ON s2.id = summoner2
            JOIN team t1 USING (split)
            JOIN team t2 USING (split)
            JOIN result r1 USING (split, week)
            JOIN result r2 USING (split, week)
        WHERE $split_clause
            AND t1.summoner = summoner1
            AND t2.summoner = summoner2
            AND r1.summoner = summoner1
            AND r2.summoner = summoner2
        ORDER BY split, week
    }, { Slice => {} }, @params);
}

sub results {
    my ($split, %params) = @_;
    my $results = get_results $split, $params{entities};

    for my $result (@$results) {
        # Convert strings to numbers for table sorting
        $result->{$_} += 0.0 for qw/split week points1 points2/;
    }
    return $results;
}

sub get_summoners {
    my ($split_clause, @params) = filter_split_clause shift;
    return $dbh->selectall_arrayref(qq{
        SELECT DISTINCT s.id, name
        FROM summoner s
            JOIN matchup m ON s.id IN (summoner1, summoner2)
            JOIN result r USING (split, week)
        WHERE $split_clause
        ORDER BY s.id ASC
    }, { Slice => {} }, @params);
}

sub get_teams {
    my ($split_clause, @params) = filter_split_clause shift;
    return $dbh->selectall_arrayref(qq{
        SELECT DISTINCT id, t.name
        FROM team t
            JOIN summoner s ON id = summoner
        WHERE $split_clause
        ORDER BY id ASC
    }, { Slice => {} }, @params);
}

sub entities {
    my ($split, %params) = @_;

    my @filter = ();
    push (@filter, split ',', $params{entities}) if ($params{entities});

    if ($split > 0) {
        return get_teams($split, @filter);
    } else {
        return get_summoners($split, @filter);
    }
}

# Given a hash of summoner->stats, order summoners by rank
sub calculate_ranking {
    my %summoners = @_;
    return sort {
        $summoners{$b}->{won}  <=> $summoners{$a}->{won}
     || $summoners{$b}->{tied} <=> $summoners{$a}->{tied}
     || $summoners{$b}->{pf}   <=> $summoners{$a}->{pf}
     || $summoners{$b}->{pa}   <=> $summoners{$a}->{pa}
    } keys(%summoners);
}

sub summoner {
    # We want:
    # win ratio
    # current rank
    # rank over time
    # (wins, losses, ties, p.d.) for all others
    my ($summoner, $split) = @_;
    my $results = get_results $split;

    my %seen_weeks = ();
    my %res_by_week = ();
    my %head_to_heads = ();

    for my $result (@$results) {
        my ($s1, $p1, $s2, $p2) = (
            $result->{entity1}, $result->{points1},
            $result->{entity2}, $result->{points2},
        );
        #warn "s1 is $s1";
        #warn "s2 is $s2";

        # Store results for head to head matchups
        if ($s1 == $summoner) {
            $head_to_heads{$s2}->{id}   = $result->{entity2};
            $head_to_heads{$s2}->{name} = $result->{summoner2};
            $head_to_heads{$s2}->{pd}  += $p1 - $p2;
            $head_to_heads{$s2}->{won}++  if ($p1 > $p2);
            $head_to_heads{$s2}->{lost}++ if ($p1 < $p2);
            $head_to_heads{$s2}->{tied}++ if ($p1 == $p2);
        } elsif ($s2 == $summoner) {
            $head_to_heads{$s1}->{id}   = $result->{entity1};
            $head_to_heads{$s1}->{name} = $result->{summoner1};
            $head_to_heads{$s1}->{pd} += $p2 - $p1;
            $head_to_heads{$s1}->{won}++  if ($p2 > $p1);
            $head_to_heads{$s1}->{lost}++ if ($p2 < $p1);
            $head_to_heads{$s1}->{tied}++ if ($p2 == $p1);
        }

        # Store results for all matchups for rank over time calculations
        my ($split, $week) = ($result->{split}, $result->{week});

        $res_by_week{$split}->{$week} ||= {};
        $res_by_week{$split}->{$week}->{$s1} ||= {map { $_ => 0 } qw/won lost tied pf pa/};
        $res_by_week{$split}->{$week}->{$s2} ||= {map { $_ => 0 } qw/won lost tied pf pa/};
        $res_by_week{$split}->{$week}->{$s1}->{pf} += $p1;
        $res_by_week{$split}->{$week}->{$s1}->{pa} += $p2;
        $res_by_week{$split}->{$week}->{$s2}->{pf} += $p2;
        $res_by_week{$split}->{$week}->{$s2}->{pa} += $p1;
        if ($p1 > $p2) {
            $res_by_week{$split}->{$week}->{$s1}->{won}++;
            $res_by_week{$split}->{$week}->{$s2}->{lost}++;
        } elsif ($p1 < $p2) {
            $res_by_week{$split}->{$week}->{$s1}->{lost}++;
            $res_by_week{$split}->{$week}->{$s2}->{won}++;
        } else {
            $res_by_week{$split}->{$week}->{$s1}->{tied}++;
            $res_by_week{$split}->{$week}->{$s2}->{tied}++;
        }
    use Data::Dump qw/dump/;
    #die "first result: " . dump(\%res_by_week);

        #push (@ranks, [calculate_ranking(%by_summoner)])
        #    unless ($seen_weeks{$result->{split}}->{$result->{week}}++);

    }
    use Data::Dump qw/dump/;
    #die "results: " . dump(\%res_by_week);
    # Iterate over results, and calculate rank after each week
    my @ranks = ();

    my %accumulated  = ();
    my $current_rank = 0;
    for my $split_id (sort {$a<=>$b} keys %res_by_week) {
        my $split = $res_by_week{$split_id};
        for my $week_id (sort {$a<=>$b} keys %$split) {
            my $week = $split->{$week_id};
            for my $summ_id (keys %$week) {
                my $matchup = $week->{$summ_id};
                $accumulated{$summ_id}->{$_} += $matchup->{$_} for (keys %$matchup);
            }
            my @ranking   = calculate_ranking(%accumulated);
            $current_rank = 1 + first_index { $_ == $summoner } @ranking;
            push @ranks, @ranking - $current_rank;
        }
    }

    my ($total_won, $total_lost) = (0, 0);
    for my $matchup (values %head_to_heads) {
        $total_won  += $matchup->{won}  || 0;
        $total_lost += $matchup->{lost} || 0;
    }

    return {
        ranks => \@ranks,
        labels => [map {''} @ranks],
        win_ratio => $total_won / ($total_won + $total_lost) * 100,
        final_rank => $current_rank,
        head_to_heads => [values %head_to_heads],
    };

}

sub get_weeks {
    my ($split_clause, @params) = filter_split_clause shift;
    return $dbh->selectcol_arrayref(qq{
        SELECT DISTINCT CONCAT("S", split, " W", week)
        FROM result
        WHERE $split_clause
        GROUP BY split, week
        ORDER BY split, week
    }, {}, @params);
}

sub data_series {
    my ($metric, $split_id, %params) = @_;
    my $splits = get_splits;

    # Data configuration
    $params{aggregation}    ||= 'cumulative';
    $params{moving_average} ||= 4;
    $params{normalise}      ||= 'false';

    # Ensure metric is valid
    $METRICS{$metric} or $metric = $DEFAULT_METRIC;

    my ($split_clause, @params) = filter_split_clause $split_id;
    my $data = $dbh->selectall_hashref(qq{
        SELECT s.id, s.name, split, week, games,
            IF ((r1.score > r2.score AND summoner1 = s.id) OR (r2.score > r1.score AND summoner2 = s.id), 1, 0) won,
            IF  (r1.score = r2.score, 1, 0) tied,
            IF ((r1.score > r2.score AND summoner2 = s.id) OR (r2.score > r1.score AND summoner1 = s.id), 1, 0) lost,
            IF (summoner1 = s.id, r1.score, r2.score) pf,
            IF (summoner1 = s.id, r2.score, r1.score) pa
        FROM summoner s
            JOIN matchup m ON s.id IN (summoner1, summoner2)
            JOIN matches n USING (split, week)
            JOIN result r1 USING (split, week)
            JOIN result r2 USING (split, week)
        WHERE $split_clause
            AND r1.summoner = m.summoner1
            AND r2.summoner = m.summoner2
        ORDER BY id, split, week
    }, [qw/split week id/], {}, @params);

    my $weeks       = get_weeks $split_id;
    my $summoners   = get_summoners $split_id;
    
    # Initialise results hash
    my %results     = ();
    $results{$_}    = [(0) x @$weeks] for (map {$_->{id}} @$summoners);
    my @week_means  = ();
    my $week_index  = 0;

    for (sort {$a <=> $b} keys %$data) {
        my $split   = $data->{$_};

        for (sort {$a <=> $b} keys %$split) {
            my $week = $split->{$_};

            # Perform some pre-processing for this week's results
            for my $summoner (values %$week) {

                # Generate points difference metrics
                $summoner->{pd} = $summoner->{pf} - $summoner->{pa};

                # Normalise values before taking the mean
                $summoner->{$metric} /= $summoner->{games}
                    if ($params{normalise} eq 'true' and can_normalise($metric));
            }

            # Calculate mean and store it for the cumulative mean
            push @week_means, sum( map { $_->{$metric} } values(%$week) ) / values(%$week);
            shift @week_means if (@week_means > $params{moving_average});
            my $accumulated_mean = sum(@week_means) / @week_means;

            for my $summoner (values %$week) {
                my $result   = $results{$summoner->{id}};

                # Calculate value for this week based on given parameters
                if ($params{aggregation} eq 'deviation') {
                    $result->[$week_index] = $summoner->{$metric} - $accumulated_mean;

                } elsif ($params{aggregation} eq 'cumulative') {
                    $result->[$week_index] = $summoner->{$metric};
                    $result->[$week_index] += $result->[$week_index - 1] if ($week_index > 0);

                } else {
                    $result->[$week_index] = $summoner->{$metric};
                }
            }
            $week_index++;
        }
    }

    # Format the results into a 2D array for graphing
    my @output = map {$results{$_}} (sort keys %results);

    return {
        labels => $weeks,
        series => [ map {$_->{name}} @$summoners ],
        data   => \@output,
    };
}

# Prepare UI routes
get '/' => sub { my $c = shift; $c->redirect_to('standings/0') };
get '/summoner/:summoner/:split'    => sub { my $c = shift; $c->stash(page => 'summoner/' . $c->param('summoner'));  $c->render(template => 'summoner') };
get '/standings/:split'             => sub { my $c = shift; $c->stash(page => 'standings'); $c->render(template => 'standings') };
get '/results/:split'               => sub { my $c = shift; $c->stash(page => 'results');   $c->render(template => 'results') };
get '/graph/:metric/:split'         => sub {
    my $c = shift;
    my $metric = metric($c->param('metric'));
    $c->stash(
        page    => "graph/$metric",
        title   => metric_name($metric),
        default_params($metric),
    );
    $c->render(template => 'graph');
};

# Prepare API routes
get '/api/entities/:split'  => sub { my $c = shift; $c->render(json => entities($c->param('split'))) };
get '/api/summoner/:summoner/:split' => sub { my $c = shift; $c->render(json => summoner($c->param('summoner'), $c->param('split'))) };
get '/api/standings/:split' => sub { my $c = shift; $c->render(json => standings($c->param('split'))) };
get '/api/results/:split'   => sub {
    my $c = shift;
    $c->render(json => results(
        $c->param('split'),
        entities => $c->param('e'),
    ));
};
get '/api/:metric/:split'   => sub {
    my $c = shift;
    $c->render(json => data_series(
        $c->param('metric'),
        $c->param('split'),
        aggregation    => $c->param('a'),
        normalise      => $c->param('n'),
        moving_average => $c->param('m'),
    ));
};

app->secrets($config->{secrets});
app->start;

