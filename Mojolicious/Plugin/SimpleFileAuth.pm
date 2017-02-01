package Mojolicious::Plugin::SimpleFileAuth;

use strict;
use warnings;

use Mojo::Base 'Mojolicious::Plugin';

use Digest::SHA qw/sha256_hex/;
use Readonly;
use YAML::XS qw/LoadFile/;

Readonly my $USER_CONFIG => 'auth.yaml';

sub register {
    my ($self, $app) = @_;
    my $users = LoadFile($USER_CONFIG);

    $app->helper(validate_file_user => sub {
        my ($app, $username, $password, $hash) = @_;
        return undef unless $username and $password;

        $app->session(expiration => 604800);
        for my $user (@$users) {
            if ($user->{username} eq $username and
                $user->{password} eq sha256_hex($password)) {
                warn "login: $user->{username}";
                return $user->{id};
            }
        }
    });

    $app->helper(load_file_user => sub {
        my ($app, $id) = @_;
        for my $user (grep { $_->{id} == $id } @$users) {
            return {
                id => $id,
                username => $user->{username},
            };
        }
    });
}

1;

