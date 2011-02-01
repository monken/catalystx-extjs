package CatalystX::Action::ExtJS::REST;
# ABSTRACT: Mark an action as REST endpoint
use Moose;
extends 'Catalyst::Action';

1;

__END__

=head1 DESCRIPTION

The purpose of this action class is to mark an action as REST endpoint. 
Actions with this action will become a L<CatalystX::Controller::ExtJS::Direct::Route::REST> route.