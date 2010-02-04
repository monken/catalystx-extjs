package CatalystX::Controller::ExtJS::Direct;
# ABSTRACT: Enable Ext.Direct in Catalyst controllers

use Moose::Role;

has is_direct => ( is => 'ro', isa => 'Bool', default => 1 );


1;

__END__

=head1 SYNOPSIS

  package MyApp::Controller::Calculator;
  
  use Moose;
  BEGIN { extends 'Catalyst::Controller' };
  with 'CatalystX::Controller::ExtJS::Direct';
  
  sub sum : Local : Direct {
      my ($self, $c) = @_;
      $c->res->body( $c->req->param('a') + $c->req->param('b') );
  }
  
  1;

=head1 DESCRIPTION

Apply this role to any Catalyst controller to enable Ext.Direct actions.

=head1 ATTRIBUTES

=head2 is_direct

This attribute is for duck typing only and is always C<1>.