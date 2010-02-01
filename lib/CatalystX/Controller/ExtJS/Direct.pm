package CatalystX::Controller::ExtJS::Direct;

use Moose::Role;

has is_direct => ( is => 'ro', isa => 'Bool', default => 1 );


1;