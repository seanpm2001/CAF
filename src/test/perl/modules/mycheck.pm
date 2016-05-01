package mycheck;

use strict;
use warnings;

use CAF::Object qw (SUCCESS);

use parent qw(CAF::Object CAF::Check);

sub _initialize {
    my ($self, %opts) = @_;
    $self->{log} = $opts{log};
    return SUCCESS;
};

1;
